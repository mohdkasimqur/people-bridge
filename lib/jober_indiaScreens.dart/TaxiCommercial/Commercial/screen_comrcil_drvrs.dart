import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:jober_india/jober_indiaScreens.dart/TaxiCommercial/Commercial/commercial_profile.dart';
import 'package:latlong2/latlong.dart' as osm;

enum CommercialDriverSection {
  live,
  registered,
}

class ScreenCommercialDrivers extends StatefulWidget {
  final String vehicleCategory;

  const ScreenCommercialDrivers({
    super.key,
    required this.vehicleCategory,
  });

  @override
  State<ScreenCommercialDrivers> createState() =>
      _ScreenCommercialDriversState();
}

class _ScreenCommercialDriversState
    extends State<ScreenCommercialDrivers> {
  // ==========================================================
  // SETTINGS
  // ==========================================================

  static const double maximumDiscoveryKm = 50.0;
  static const double freeDistanceKm = 1.0;
  static const int driversPerPage = 20;

  static const Color appGreen = Color(0xFF138808);
  static const Color liveMarkerGreen = Color(0xFF16803C);
  static const Color registeredMarkerRed = Colors.red;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final fm.MapController _mapController =
      fm.MapController();

  final ScrollController _scrollController =
      ScrollController();

  Timer? _subscriptionExpiryTimer;

  // ==========================================================
  // PAGE STATE
  // ==========================================================

  Position? currentPosition;

  bool isLoading = true;
  bool isLoadingMore = false;
  bool mapReady = false;
  bool locationPermissionDenied = false;

  String? error;

  CommercialDriverSection selectedSection =
      CommercialDriverSection.live;

  // ==========================================================
  // DRIVER DATA
  // ==========================================================

  final List<Map<String, dynamic>> liveDrivers = [];
  final List<Map<String, dynamic>> loggedInDrivers = [];
  final List<Map<String, dynamic>> _visibleDrivers = [];

  final Map<String, Map<String, dynamic>> _liveLocations = {};

  bool _liveDriversLoaded = false;
  bool _registeredDriversLoaded = false;
  bool _paginationInProgress = false;

  int _visibleDriverCount = 0;

  // ==========================================================
  // SUBSCRIPTION
  // ==========================================================

  double paidDistance = freeDistanceKm;
  DateTime? paymentExpiry;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handlePagination);

    loadDrivers();
  }

  @override
  void didUpdateWidget(covariant ScreenCommercialDrivers oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.vehicleCategory != widget.vehicleCategory) {
      selectedSection = CommercialDriverSection.live;
      loadDrivers(reset: true);
    }
  }

  List<Map<String, dynamic>> get _selectedDrivers {
    return selectedSection == CommercialDriverSection.live
        ? liveDrivers
        : loggedInDrivers;
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(value.trim());
    }

    return null;
  }

  String _normalize(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s-]+'), '_');
  }

  bool _validCoordinates(double lat, double lng) {
    return lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  bool _matchesVehicle(Map<String, dynamic> data) {
    final String role = _normalize(data['role']);
    final String type = _normalize(data['vehicleType']);
    final String vehicle = (data['vehicle'] ?? '')
        .toString()
        .trim();

    return role == 'taxi_commercial' &&
        type == 'commercial' &&
        vehicle.toLowerCase() ==
            widget.vehicleCategory.trim().toLowerCase();
  }

  String _driverName(Map<String, dynamic> driver) {
    for (final String key in [
      'name',
      'username',
      'fullName',
      'userName',
    ]) {
      final String value =
          (driver[key] ?? '').toString().trim();

      if (value.isNotEmpty) return value;
    }

    return 'Commercial Driver';
  }

  String _driverPhoto(Map<String, dynamic> driver) {
    for (final String key in [
      'profilePhotoUrl',
      'profilePhoto',
      'photoUrl',
    ]) {
      final String value =
          (driver[key] ?? '').toString().trim();

      if (value.isNotEmpty) return value;
    }

    return '';
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }

    return '${distance.toStringAsFixed(1)} km';
  }

  String _formatExpiry(DateTime date) {
    final DateTime local = date.toLocal();

    String twoDigits(int value) =>
        value.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/'
        '${twoDigits(local.month)}/'
        '${local.year} '
        '${twoDigits(local.hour)}:'
        '${twoDigits(local.minute)}';
  }

  DateTime _startOfToday() {
    final DateTime now = DateTime.now();

    return DateTime(now.year, now.month, now.day);
  }

  // ==========================================================
  // SUBSCRIPTION ACCESS
  // ==========================================================

  Future<void> loadPaymentAccess() async {
    double distance = freeDistanceKm;
    DateTime? expiry;

    try {
      final Box settingsBox = await Hive.openBox('settings');

      final double? savedDistance =
          _readDouble(settingsBox.get('paidDistance'));

      expiry = _readDateTime(
        settingsBox.get('paymentExpiry'),
      );

      final bool validSubscription =
          savedDistance != null &&
          savedDistance >= freeDistanceKm &&
          expiry != null &&
          expiry.isAfter(DateTime.now());

      if (validSubscription) {
        distance = savedDistance
            .clamp(freeDistanceKm, 300.0)
            .toDouble();
      } else {
        expiry = null;
      }
    } catch (e) {
      debugPrint('Commercial subscription loading error: $e');
    }

    _scheduleSubscriptionExpiry(expiry);

    if (!mounted) return;

    setState(() {
      paidDistance = distance;
      paymentExpiry = expiry;
    });
  }

  void _scheduleSubscriptionExpiry(DateTime? expiry) {
    _subscriptionExpiryTimer?.cancel();
    _subscriptionExpiryTimer = null;

    if (expiry == null ||
        !expiry.isAfter(DateTime.now())) {
      return;
    }

    _subscriptionExpiryTimer = Timer(
      expiry.difference(DateTime.now()),
      () async {
        if (!mounted) return;

        await loadPaymentAccess();
      },
    );
  }

  bool hasDistanceAccess(double distance) {
    if (distance <= freeDistanceKm) return true;

    return paymentExpiry != null &&
        paymentExpiry!.isAfter(DateTime.now()) &&
        paidDistance >= distance;
  }

  // ==========================================================
  // CURRENT LOCATION
  // ==========================================================

  Future<Position> getCurrentPosition() async {
    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Please turn on your GPS location.');
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is required to find nearby drivers.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // ==========================================================
  // REGISTERED LOCATION HELPERS
  // ==========================================================

  double? _registrationLatitude(Map<String, dynamic> data) {
    return _readDouble(data['parkedLatitude']) ??
        _readDouble(data['locationLatitude']) ??
        _readDouble(data['latitude']);
  }

  double? _registrationLongitude(Map<String, dynamic> data) {
    return _readDouble(data['parkedLongitude']) ??
        _readDouble(data['locationLongitude']) ??
        _readDouble(data['longitude']);
  }

  String _registrationLocationName(
    Map<String, dynamic> data,
  ) {
    for (final String key in [
      'parkedLocation',
      'locationName',
      'nearestTown',
      'district',
      'state',
    ]) {
      final String value =
          (data[key] ?? '').toString().trim();

      if (value.isNotEmpty) return value;
    }

    return 'Registered location';
  }

  double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(
          lat1,
          lon1,
          lat2,
          lon2,
        ) /
        1000.0;
  }

  // ==========================================================
  // LOAD BOTH SECTIONS
  // ==========================================================

  Future<void> loadDrivers({bool reset = true}) async {
    if (mounted) {
      setState(() {
        isLoading = true;
        error = null;
      });
    }

    try {
      await loadPaymentAccess();

      final Position position = await getCurrentPosition();

      if (!mounted) return;

      currentPosition = position;
      locationPermissionDenied = false;

      if (reset) {
        liveDrivers.clear();
        loggedInDrivers.clear();
        _visibleDrivers.clear();
        _liveLocations.clear();

        _liveDriversLoaded = false;
        _registeredDriversLoaded = false;
        _visibleDriverCount = 0;
      }

      if (!_registeredDriversLoaded) {
        await _loadRegisteredDrivers(position);
      }

      if (!mounted) return;

      if (!_liveDriversLoaded) {
        await _loadLiveDrivers(position);
      }

      if (!mounted) return;

      _updateVisibleDrivers();

      setState(() {
        isLoading = false;
      });

      _moveMapToUser();
    } catch (e, stackTrace) {
      debugPrint('Commercial drivers loading error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      final String message = e.toString().replaceFirst(
            'Exception: ',
            '',
          );

      setState(() {
        isLoading = false;
        error = message;
        locationPermissionDenied =
            message.toLowerCase().contains('location') ||
            message.toLowerCase().contains('gps');
      });
    }
  }

  // ==========================================================
  // REGISTERED COMMERCIAL DRIVERS
  // Collection: taxi_commercial
  // ==========================================================

  Future<void> _loadRegisteredDrivers(
    Position position,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _firestore
            .collection('taxi_commercial')
            .get();

    final List<Map<String, dynamic>> results = [];

    for (final QueryDocumentSnapshot<Map<String, dynamic>>
        document in snapshot.docs) {
      final Map<String, dynamic> data = document.data();

      if (!_matchesVehicle(data)) continue;

      final String uid =
          (data['uid'] ?? document.id).toString().trim();

      if (uid.isEmpty) continue;

      final double? latitude = _registrationLatitude(data);
      final double? longitude = _registrationLongitude(data);

      if (latitude == null || longitude == null) continue;

      if (!_validCoordinates(latitude, longitude)) continue;

      final double distance = _distanceKm(
        position.latitude,
        position.longitude,
        latitude,
        longitude,
      );

      if (distance > maximumDiscoveryKm) continue;

      results.add({
        ...data,
        'uid': uid,
        'documentId': document.id,
        'latitude': latitude,
        'longitude': longitude,
        'distance': distance,
        'driverLocationType': 'registered',
        'isLiveDriver': false,
        'registrationLocationName':
            _registrationLocationName(data),
      });
    }

    results.sort(
      (a, b) => (a['distance'] as double).compareTo(
        b['distance'] as double,
      ),
    );

    loggedInDrivers
      ..clear()
      ..addAll(results);

    _registeredDriversLoaded = true;
  }

  // ==========================================================
  // LIVE COMMERCIAL DRIVERS
  // Preserves the original updatedAt/today condition.
  // ==========================================================

  Future<void> _loadLiveDrivers(Position position) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _firestore
            .collection('liveLocations')
            .where('isLive', isEqualTo: true)
            .get();

    final DateTime startOfToday = _startOfToday();

    final Map<String, Map<String, dynamic>> registeredByUid = {
      for (final Map<String, dynamic> driver in loggedInDrivers)
        (driver['uid'] ?? '').toString(): driver,
    };

    final Map<String, Map<String, dynamic>> resultsByUid = {};

    _liveLocations.clear();

    for (final QueryDocumentSnapshot<Map<String, dynamic>>
        document in snapshot.docs) {
      final Map<String, dynamic> liveData = document.data();

      if (!_matchesVehicle(liveData)) continue;

      final DateTime? updatedAt =
          _readDateTime(liveData['updatedAt']);

      if (updatedAt == null ||
          updatedAt.isBefore(startOfToday)) {
        continue;
      }

      final String uid =
          (liveData['uid'] ?? document.id).toString().trim();

      if (uid.isEmpty) continue;

      final double? latitude = _readDouble(liveData['latitude']);
      final double? longitude = _readDouble(liveData['longitude']);

      if (latitude == null || longitude == null) continue;

      if (!_validCoordinates(latitude, longitude)) continue;

      final double distance = _distanceKm(
        position.latitude,
        position.longitude,
        latitude,
        longitude,
      );

      if (distance > maximumDiscoveryKm) continue;

      final Map<String, dynamic> registered =
          registeredByUid[uid] ?? <String, dynamic>{};

      // Registered profile details are used where available.
      // Live coordinates and live distance take priority.
      final Map<String, dynamic> combined = {
        ...liveData,
        ...registered,
        ...liveData,
        'uid': uid,
        'latitude': latitude,
        'longitude': longitude,
        'distance': distance,
        'updatedAt': updatedAt,
        'driverLocationType': 'live',
        'isLiveDriver': true,
        'name': registered['name'] ??
            registered['username'] ??
            liveData['name'] ??
            liveData['username'] ??
            'Commercial Driver',
        'profilePhotoUrl': registered['profilePhotoUrl'] ??
            registered['profilePhoto'] ??
            liveData['profilePhotoUrl'] ??
            liveData['profilePhoto'] ??
            '',
        'mobile': registered['mobile'] ?? liveData['mobile'] ?? '',
        'secondaryPhone': registered['secondaryPhone'] ??
            registered['secondaryMobile'] ??
            liveData['secondaryPhone'] ??
            liveData['secondaryMobile'] ??
            '',
        'vehicle': liveData['vehicle'] ?? registered['vehicle'],
        'vehicleType':
            liveData['vehicleType'] ?? registered['vehicleType'],
        'vehicleName':
            registered['vehicleName'] ?? liveData['vehicleName'] ?? '',
        'vehicleNumber':
            registered['vehicleNumber'] ?? liveData['vehicleNumber'] ?? '',
        'registrationLocationName':
            _registrationLocationName(registered),
      };

      resultsByUid[uid] = combined;

      _liveLocations[uid] = {
        ...liveData,
        'uid': uid,
        'latitude': latitude,
        'longitude': longitude,
        'isLive': true,
        'updatedAt': updatedAt,
      };
    }

    final List<Map<String, dynamic>> results =
        resultsByUid.values.toList();

    results.sort(
      (a, b) => (a['distance'] as double).compareTo(
        b['distance'] as double,
      ),
    );

    liveDrivers
      ..clear()
      ..addAll(results);

    _liveDriversLoaded = true;
  }

  // ==========================================================
  // REFRESH AND SECTION SWITCHING
  // ==========================================================

  Future<void> _refreshDrivers() async {
    await loadDrivers(reset: true);
  }

  void _switchSection(CommercialDriverSection section) {
    if (selectedSection == section || isLoading) return;

    setState(() {
      selectedSection = section;
    });

    _updateVisibleDrivers();

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  // ==========================================================
  // AUTOMATIC PAGINATION
  // ==========================================================

  void _updateVisibleDrivers() {
    final List<Map<String, dynamic>> results = _selectedDrivers;

    _visibleDriverCount = math.min(
      driversPerPage,
      results.length,
    );

    _visibleDrivers
      ..clear()
      ..addAll(results.take(_visibleDriverCount));
  }

  void _handlePagination() {
    if (!_scrollController.hasClients ||
        isLoading ||
        isLoadingMore ||
        _paginationInProgress) {
      return;
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_paginationInProgress ||
        isLoading ||
        _visibleDriverCount >= _selectedDrivers.length) {
      return;
    }

    _paginationInProgress = true;

    if (mounted) {
      setState(() {
        isLoadingMore = true;
      });
    }

    try {
      await Future<void>.delayed(Duration.zero);

      if (!mounted) return;

      final int nextCount = math.min(
        _visibleDriverCount + driversPerPage,
        _selectedDrivers.length,
      );

      setState(() {
        _visibleDriverCount = nextCount;

        _visibleDrivers
          ..clear()
          ..addAll(_selectedDrivers.take(nextCount));
      });
    } finally {
      _paginationInProgress = false;

      if (mounted) {
        setState(() {
          isLoadingMore = false;
        });
      }
    }
  }

  bool get _hasMoreDrivers =>
      _visibleDriverCount < _selectedDrivers.length;

  // ==========================================================
  // LIVE STATUS
  // ==========================================================

  bool _isDriverLive(Map<String, dynamic> driver) {
    final String uid = (driver['uid'] ?? '').toString().trim();

    if (uid.isEmpty) return false;

    final Map<String, dynamic>? liveData = _liveLocations[uid];

    if (liveData == null || liveData['isLive'] != true) {
      return false;
    }

    final DateTime? updatedAt =
        _readDateTime(liveData['updatedAt']);

    return updatedAt != null &&
        !updatedAt.isBefore(_startOfToday());
  }

  // ==========================================================
  // PROFILE ACCESS
  // ==========================================================

  void _openDriverProfile(Map<String, dynamic> driver) {
    final double distance =
        _readDouble(driver['distance']) ?? double.infinity;

    if (!hasDistanceAccess(distance)) {
      _showLockedMessage(distance);
      return;
    }

    final Map<String, dynamic> profileData =
        Map<String, dynamic>.from(driver);

    profileData['uid'] = driver['uid'];
    profileData['distanceKm'] = distance;

    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ScreenCommercialDriverProfile(
      driver: driver,
      distance: distance,
    ),
  ),
);
  }

  void _showLockedMessage(double distance) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Distance Limit',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'This driver is ${_formatDistance(distance)} away.\n\n'
            'Your current profile access distance is '
            '${paidDistance.toStringAsFixed(paidDistance % 1 == 0 ? 0 : 1)} km.\n\n'
            'The first 1 km is free. Subscribe or renew your '
            'distance access to open profiles farther away.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // MAP
  // ==========================================================

  void _moveMapToUser() {
    final Position? position = currentPosition;

    if (!mounted || !mapReady || position == null) return;

    try {
      _mapController.move(
        osm.LatLng(position.latitude, position.longitude),
        11.5,
      );
    } catch (e) {
      debugPrint('Commercial map movement error: $e');
    }
  }

  Widget _buildMap() {
    final Position? position = currentPosition;

    final osm.LatLng initialCenter = position != null
        ? osm.LatLng(position.latitude, position.longitude)
        : const osm.LatLng(10.8505, 76.2711);

    final List<fm.Marker> markers = [];

    if (position != null) {
      markers.add(
        fm.Marker(
          point: osm.LatLng(
            position.latitude,
            position.longitude,
          ),
          width: 44,
          height: 44,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (final Map<String, dynamic> driver in _visibleDrivers) {
      final double? latitude = _readDouble(driver['latitude']);
      final double? longitude = _readDouble(driver['longitude']);

      if (latitude == null || longitude == null) continue;

      final bool liveSection =
          selectedSection == CommercialDriverSection.live;

      if (liveSection && !_isDriverLive(driver)) continue;

      markers.add(
        fm.Marker(
          point: osm.LatLng(latitude, longitude),
          width: 44,
          height: 48,
          child: GestureDetector(
            onTap: () => _showDriverFromMarker(driver),
            child: Icon(
              Icons.local_shipping,
              color: liveSection
                  ? liveMarkerGreen
                  : registeredMarkerRed,
              size: 35,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 310,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: fm.FlutterMap(
          mapController: _mapController,
          options: fm.MapOptions(
            initialCenter: initialCenter,
            initialZoom: 11.5,
            minZoom: 3,
            maxZoom: 18,
            onMapReady: () {
              mapReady = true;
              _moveMapToUser();
            },
          ),
          children: [
            fm.TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'jober_india',
              maxZoom: 19,
            ),
            fm.MarkerLayer(markers: markers),
            const fm.RichAttributionWidget(
              attributions: [
                fm.TextSourceAttribution(
                  '© OpenStreetMap contributors',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDriverFromMarker(Map<String, dynamic> driver) {
    final double distance =
        _readDouble(driver['distance']) ?? 0.0;

    final bool liveSection =
        selectedSection == CommercialDriverSection.live;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: Icon(
                        Icons.local_shipping,
                        color: liveSection
                            ? liveMarkerGreen
                            : registeredMarkerRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _driverName(driver),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            liveSection
                                ? 'Live ${widget.vehicleCategory} driver'
                                : 'Registered ${widget.vehicleCategory} driver',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (liveSection)
                      const Chip(
                        label: Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: liveMarkerGreen,
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${_formatDistance(distance)} away',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _openDriverProfile(driver);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'VIEW PROFILE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // SUBSCRIPTION CARD
  // ==========================================================

  Widget _subscriptionCard() {
    final bool active = paymentExpiry != null &&
        paymentExpiry!.isAfter(DateTime.now()) &&
        paidDistance > freeDistanceKm;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appGreen),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: appGreen, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active
                      ? '${paidDistance.toStringAsFixed(paidDistance % 1 == 0 ? 0 : 1)} km unlocked'
                      : '1 km free profile access',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: appGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  active
                      ? 'Valid until ${_formatExpiry(paymentExpiry!)}'
                      : 'Subscribe to open profiles beyond 1 km.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SECTION SELECTOR
  // ==========================================================

  Widget _sectionButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? appGreen : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 5,
          ),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _sectionButton(
              title: 'Live Drivers',
              selected:
                  selectedSection == CommercialDriverSection.live,
              onTap: () => _switchSection(
                CommercialDriverSection.live,
              ),
            ),
          ),
          Expanded(
            child: _sectionButton(
              title: 'Logged-in Drivers',
              selected: selectedSection ==
                  CommercialDriverSection.registered,
              onTap: () => _switchSection(
                CommercialDriverSection.registered,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SECTION INFORMATION
  // ==========================================================

  Widget _sectionInformation() {
    final bool liveSection =
        selectedSection == CommercialDriverSection.live;

    final Color sectionColor =
        liveSection ? liveMarkerGreen : registeredMarkerRed;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                liveSection
                    ? 'Live ${widget.vehicleCategory} Drivers Near You'
                    : 'Registered ${widget.vehicleCategory} Drivers Near You',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                liveSection
                    ? 'Currently live within 50 km'
                    : 'Registered locations within 50 km',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: sectionColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                '${paidDistance.toStringAsFixed(paidDistance % 1 == 0 ? 0 : 1)} km',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: sectionColor,
                ),
              ),
              Text(
                'Access',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // DRIVER CARD
  // ==========================================================

  Widget _driverCard(Map<String, dynamic> driver) {
    final double distance =
        _readDouble(driver['distance']) ?? 0.0;

    final bool unlocked = hasDistanceAccess(distance);

    final bool liveSection =
        selectedSection == CommercialDriverSection.live;

    final String photo = _driverPhoto(driver);

    final String locationName = liveSection
        ? 'Current live location'
        : (driver['registrationLocationName'] ??
                'Registered location')
            .toString();

    final Color sectionColor =
        liveSection ? liveMarkerGreen : registeredMarkerRed;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDriverProfile(driver),
        child: Container(
          margin: const EdgeInsets.only(bottom: 11),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5E5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8F5E9),
                ),
                child: photo.isNotEmpty
                    ? Image.network(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.local_shipping,
                          color: sectionColor,
                          size: 30,
                        ),
                      )
                    : Icon(
                        Icons.local_shipping,
                        color: sectionColor,
                        size: 30,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _driverName(driver),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (liveSection)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: liveMarkerGreen,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      [
                        (driver['vehicle'] ?? widget.vehicleCategory)
                            .toString(),
                        (driver['vehicleName'] ?? '')
                            .toString()
                            .trim(),
                      ].where((value) => value.isNotEmpty).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: sectionColor,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${_formatDistance(distance)} away',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sectionColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      unlocked
                          ? 'Tap to view profile'
                          : 'Profile locked - subscription required',
                      style: TextStyle(
                        fontSize: 11,
                        color: unlocked ? appGreen : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Icon(
                unlocked
                    ? Icons.arrow_forward_ios
                    : Icons.lock_outline,
                size: 17,
                color: unlocked ? appGreen : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY SECTION
  // ==========================================================

  Widget _emptySection() {
    final bool liveSection =
        selectedSection == CommercialDriverSection.live;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        children: [
          Icon(
            liveSection
                ? Icons.gps_off
                : Icons.local_shipping_outlined,
            size: 45,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            liveSection
                ? 'No live ${widget.vehicleCategory} drivers found'
                : 'No registered ${widget.vehicleCategory} drivers found',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            liveSection
                ? 'No matching drivers have a valid live location within 50 km.'
                : 'No matching registered drivers with saved coordinates were found within 50 km.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MY LOCATION BUTTON
  // ==========================================================

  Widget _myLocationButton() {
    return Positioned(
      right: 12,
      bottom: 12,
      child: Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            try {
              final Position position = await getCurrentPosition();

              if (!mounted) return;

              setState(() {
                currentPosition = position;
                locationPermissionDenied = false;
              });

              await loadDrivers(reset: true);

              _moveMapToUser();
            } catch (e) {
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    e.toString().replaceFirst('Exception: ', ''),
                  ),
                ),
              );
            }
          },
          child: const SizedBox(
            width: 45,
            height: 45,
            child: Icon(
              Icons.my_location,
              color: Colors.black87,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ERROR VIEW
  // ==========================================================

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              locationPermissionDenied
                  ? Icons.location_off
                  : Icons.cloud_off,
              size: 45,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              error ?? 'Unable to load commercial drivers.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _refreshDrivers,
              style: ElevatedButton.styleFrom(
                backgroundColor: appGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: appGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${widget.vehicleCategory} Drivers',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : _refreshDrivers,
            tooltip: 'Refresh drivers',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: appGreen),
            )
          : error != null
              ? _errorView()
              : currentPosition == null
                  ? _errorView()
                  : RefreshIndicator(
                      color: appGreen,
                      onRefresh: _refreshDrivers,
                      child: ListView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          14,
                          14,
                          14,
                          28,
                        ),
                        children: [
                          _subscriptionCard(),
                          _sectionSelector(),
                          const SizedBox(height: 14),
                          Stack(
                            children: [
                              _buildMap(),
                              _myLocationButton(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _sectionInformation(),
                          const SizedBox(height: 14),
                          if (_visibleDrivers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 10,
                              ),
                              child: Text(
                                '${_visibleDrivers.length} of ${_selectedDrivers.length} drivers loaded',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          if (_visibleDrivers.isEmpty)
                            _emptySection(),
                          ..._visibleDrivers.map(_driverCard),
                          if (isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: appGreen,
                                ),
                              ),
                            ),
                          if (!_hasMoreDrivers &&
                              _visibleDrivers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 12,
                              ),
                              child: Center(
                                child: Text(
                                  'You have reached the end of the list.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _subscriptionExpiryTimer?.cancel();

    _scrollController.removeListener(_handlePagination);
    _scrollController.dispose();

    super.dispose();
  }
}