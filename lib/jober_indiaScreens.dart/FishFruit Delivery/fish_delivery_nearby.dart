import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:jober_india/jober_indiaScreens.dart/FishFruit%20Delivery/fish_delivery_profile.dart';
import 'package:latlong2/latlong.dart';

enum FishDeliverySection {
  live,
  registered,
}

class ScreenFishDeliveryNearby extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ScreenFishDeliveryNearby({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ScreenFishDeliveryNearby> createState() =>
      _ScreenFishDeliveryNearbyState();
}

class _ScreenFishDeliveryNearbyState
    extends State<ScreenFishDeliveryNearby> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final MapController _mapController = MapController();

  static const double _discoveryRadiusKm = 50.0;
  static const double _freeDistanceKm = 1.0;
  static const int _pageSize = 20;

  FishDeliverySection _selectedSection = FishDeliverySection.live;

  Position? _userPosition;

  List<Map<String, dynamic>> _allLiveProfiles = [];
  List<Map<String, dynamic>> _allRegisteredProfiles = [];
  List<Map<String, dynamic>> _visibleProfiles = [];

  int _currentPage = 0;

  double _activeDistanceKm = _freeDistanceKm;
  DateTime? _subscriptionExpiry;

  bool _loading = true;
  bool _loadingMore = false;
  bool _locationLoading = true;
  bool _hasMore = false;

  String? _errorMessage;

  Timer? _subscriptionTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSubscription();
    await _getUserLocation();
    await _loadProfiles();
  }

  // ============================================================
  // SUBSCRIPTION
  // ============================================================

  Future<void> _loadSubscription() async {
    _subscriptionTimer?.cancel();

    double distance = _freeDistanceKm;
    DateTime? expiry;

    try {
      final box = Hive.box('settings');

      final dynamic savedDistance = box.get('activeDistance');
      final dynamic savedExpiry = box.get('subscriptionExpiry');

      if (savedDistance is num) {
        distance = savedDistance.toDouble();
      } else if (savedDistance is String) {
        distance = double.tryParse(savedDistance) ?? _freeDistanceKm;
      }

      if (savedExpiry is DateTime) {
        expiry = savedExpiry;
      } else if (savedExpiry is String) {
        expiry = DateTime.tryParse(savedExpiry);
      } else if (savedExpiry is int) {
        expiry = DateTime.fromMillisecondsSinceEpoch(savedExpiry);
      }

      final bool validSubscription =
          distance > _freeDistanceKm &&
          expiry != null &&
          expiry.isAfter(DateTime.now());

      if (!validSubscription) {
        distance = _freeDistanceKm;
        expiry = null;
      }

      if (validSubscription && expiry != null) {
        final Duration remaining = expiry.difference(DateTime.now());

        _subscriptionTimer = Timer(remaining, () async {
          if (!mounted) return;

          await _loadSubscription();

          if (mounted) {
            setState(() {});
          }
        });
      }
    } catch (e) {
      debugPrint('Fish delivery subscription error: $e');
      distance = _freeDistanceKm;
      expiry = null;
    }

    if (!mounted) return;

    setState(() {
      _activeDistanceKm = distance;
      _subscriptionExpiry = expiry;
    });
  }

  bool get _hasActiveSubscription {
    return _subscriptionExpiry != null &&
        _subscriptionExpiry!.isAfter(DateTime.now()) &&
        _activeDistanceKm > _freeDistanceKm;
  }

  double get _allowedProfileDistanceKm {
    return _hasActiveSubscription
        ? _activeDistanceKm
        : _freeDistanceKm;
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> _getUserLocation() async {
    if (mounted) {
      setState(() {
        _locationLoading = true;
      });
    }

    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Please enable your device location.');
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required.');
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _userPosition = position;
        _locationLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _mapController.move(
          LatLng(position.latitude, position.longitude),
          12,
        );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _locationLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // DISTANCE AND CATEGORY HELPERS
  // ============================================================

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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
        1000;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
  }

  bool _matchesCategory(Map<String, dynamic> profile) {
    final String wantedId = _normalize(widget.categoryId);
    final String wantedName = _normalize(widget.categoryName);

    final List<dynamic> searchTerms = [
      if (profile['specializations'] is List)
        ...(profile['specializations'] as List),
      if (profile['specializationSearch'] is List)
        ...(profile['specializationSearch'] as List),
      if (profile['selectedItemList'] is List)
        ...(profile['selectedItemList'] as List),
    ];

    for (final dynamic item in searchTerms) {
      final String term = _normalize(item.toString());

      if (term == wantedId || term == wantedName) {
        return true;
      }
    }

    return false;
  }

  bool _isWithinDiscoveryRadius(
    double latitude,
    double longitude,
  ) {
    if (_userPosition == null) return false;

    return _distanceKm(
          _userPosition!.latitude,
          _userPosition!.longitude,
          latitude,
          longitude,
        ) <=
        _discoveryRadiusKm;
  }

  // ============================================================
  // FIRESTORE LOADING
  // ============================================================

  Future<void> _loadProfiles() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    if (_userPosition == null) {
      setState(() {
        _loading = false;
        _visibleProfiles = [];
      });
      return;
    }

    try {
      final results = await Future.wait([
        _db.collection('fishDeliveryGuys').get(),
        _db.collection('liveLocations')
            .where('isLive', isEqualTo: true)
            .get(),
      ]);

      final profileSnapshot = results[0];

final liveSnapshot = results[1];

      final Map<String, Map<String, dynamic>> registeredByUid = {};

      for (final doc in profileSnapshot.docs) {
        final Map<String, dynamic> profile = doc.data();

        if (profile['isActive'] == false ||
            profile['profileCompleted'] == false) {
          continue;
        }

        if (!_matchesCategory(profile)) continue;

        final double? latitude = _toDouble(
          profile['currentLocationLatitude'] ??
              profile['latitude'],
        );

        final double? longitude = _toDouble(
          profile['currentLocationLongitude'] ??
              profile['longitude'],
        );

        if (latitude == null || longitude == null) continue;

        if (!_isWithinDiscoveryRadius(latitude, longitude)) {
          continue;
        }

        final double distance = _distanceKm(
          _userPosition!.latitude,
          _userPosition!.longitude,
          latitude,
          longitude,
        );

        registeredByUid[doc.id] = {
          ...profile,
          'uid': profile['uid'] ?? doc.id,
          'latitude': latitude,
          'longitude': longitude,
          'distanceKm': distance,
          'locationType': 'registered',
        };
      }

      final List<Map<String, dynamic>> liveProfiles = [];

      for (final liveDoc in liveSnapshot.docs) {
        final Map<String, dynamic> live = liveDoc.data();

        final String role = _normalize(
          (live['role'] ?? live['serviceType'] ?? '').toString(),
        );

        if (role != 'fish_delivery' &&
            role != 'fish delivery') {
          continue;
        }

        final dynamic expiryValue = live['expiresAt'];
        DateTime? expiry;

        if (expiryValue is Timestamp) {
          expiry = expiryValue.toDate();
        } else if (expiryValue is DateTime) {
          expiry = expiryValue;
        } else if (expiryValue is String) {
          expiry = DateTime.tryParse(expiryValue);
        }

        if (expiry == null || !expiry.isAfter(DateTime.now())) {
          continue;
        }

        final double? latitude = _toDouble(live['latitude']);
        final double? longitude = _toDouble(live['longitude']);

        if (latitude == null || longitude == null) continue;

        if (!_isWithinDiscoveryRadius(latitude, longitude)) {
          continue;
        }

        final String uid =
            (live['uid'] ?? liveDoc.id).toString();

        final Map<String, dynamic>? registered =
            registeredByUid[uid];

        if (registered == null) continue;

        final Map<String, dynamic> combined = {
          ...registered,
          ...live,
          'uid': uid,
          'latitude': latitude,
          'longitude': longitude,
          'distanceKm': _distanceKm(
            _userPosition!.latitude,
            _userPosition!.longitude,
            latitude,
            longitude,
          ),
          'locationType': 'live',
          'isLive': true,
        };

        // Live GPS must override the registered profile's coordinates.
        combined['latitude'] = latitude;
        combined['longitude'] = longitude;

        liveProfiles.add(combined);
      }

      liveProfiles.sort(
        (a, b) => (a['distanceKm'] as double)
            .compareTo(b['distanceKm'] as double),
      );

      final List<Map<String, dynamic>> registeredProfiles =
          registeredByUid.values.toList();

      registeredProfiles.sort(
        (a, b) => (a['distanceKm'] as double)
            .compareTo(b['distanceKm'] as double),
      );

      if (!mounted) return;

      setState(() {
        _allLiveProfiles = liveProfiles;
        _allRegisteredProfiles = registeredProfiles;
        _loading = false;
      });

      _applyPagination(reset: true);
    } catch (e) {
      debugPrint('Fish delivery nearby error: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = 'Could not load fish delivery profiles.';
      });
    }
  }

  // ============================================================
  // LIVE / REGISTERED AND PAGINATION
  // ============================================================

  List<Map<String, dynamic>> get _selectedProfiles {
    return _selectedSection == FishDeliverySection.live
        ? _allLiveProfiles
        : _allRegisteredProfiles;
  }

  void _applyPagination({required bool reset}) {
    final List<Map<String, dynamic>> source = _selectedProfiles;

    if (reset) {
      _currentPage = 0;
      _visibleProfiles = [];
    }

    final int start = _currentPage * _pageSize;
    final int end = math.min(start + _pageSize, source.length);

    if (start < source.length) {
      _visibleProfiles.addAll(source.sublist(start, end));
      _currentPage++;
    }

    _hasMore = end < source.length;

    if (mounted) setState(() {});
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;

    setState(() {
      _loadingMore = true;
    });

    _applyPagination(reset: false);

    if (mounted) {
      setState(() {
        _loadingMore = false;
      });
    }
  }

  void _changeSection(FishDeliverySection section) {
    setState(() {
      _selectedSection = section;
      _visibleProfiles = [];
      _currentPage = 0;
    });

    _applyPagination(reset: true);
  }

  Future<void> _refresh() async {
    await _loadSubscription();
    await _getUserLocation();
    await _loadProfiles();
  }

  // ============================================================
  // PROFILE ACCESS
  // ============================================================

  String _profileName(Map<String, dynamic> profile) {
    for (final key in [
      'username',
      'name',
      'fullName',
      'userName',
    ]) {
      final dynamic value = profile[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return 'Fish Delivery Rider';
  }

  Future<void> _openProfile(
    Map<String, dynamic> profile,
  ) async {
    final double distance =
        _toDouble(profile['distanceKm']) ?? double.infinity;

    if (distance > _allowedProfileDistanceKm) {
      _showDistanceMessage(distance);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenFishDeliveryProfile(
          profile: profile,
          selectedCategoryId: widget.categoryId,
          selectedCategoryName: widget.categoryName,
        ),
      ),
    );
  }

  void _showDistanceMessage(double distance) {
    final String message = _hasActiveSubscription
        ? 'This rider is ${distance.toStringAsFixed(1)} km away. '
            'Your access distance is '
            '${_activeDistanceKm.toStringAsFixed(0)} km.'
        : 'This rider is ${distance.toStringAsFixed(1)} km away. '
            'Free profile access is limited to 1 km. '
            'Subscribe to unlock a larger distance.';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Distance limit'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAP
  // ============================================================

  Widget _buildMap() {
    final Position? position = _userPosition;

    if (position == null) {
      return Container(
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: const Text('Your location is unavailable.'),
      );
    }

    final List<Marker> markers = [
      Marker(
        point: LatLng(position.latitude, position.longitude),
        width: 48,
        height: 48,
        child: const Icon(
          Icons.my_location,
          size: 34,
          color: Colors.blue,
        ),
      ),
      ..._selectedProfiles.map((profile) {
        final double? latitude = _toDouble(profile['latitude']);
        final double? longitude = _toDouble(profile['longitude']);

        if (latitude == null || longitude == null) {
          return null;
        }

        final bool live = profile['locationType'] == 'live';

        return Marker(
          point: LatLng(latitude, longitude),
          width: 46,
          height: 46,
          child: GestureDetector(
            onTap: () => _openProfile(profile),
            child: Icon(
  live
      ? Icons.delivery_dining
      : Icons.person_pin_circle,
  size: 36,
  color: live
      ? Colors.green.shade700
      : Colors.orange.shade800,
),
          ),
        );
      }).whereType<Marker>(),
    ];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          position.latitude,
          position.longitude,
        ),
        initialZoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.jober_india',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _buildProfileCard(
    Map<String, dynamic> profile,
  ) {
    final double distance =
        _toDouble(profile['distanceKm']) ?? 0;

    final bool live = profile['locationType'] == 'live';

    final dynamic photoValue = profile['profilePhotoUrl'];
    final String photoUrl =
        photoValue is String ? photoValue : '';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 27,
          backgroundColor: Colors.teal.shade50,
          backgroundImage: photoUrl.startsWith('http')
              ? NetworkImage(photoUrl)
              : null,
          child: photoUrl.startsWith('http')
              ? null
              : const Icon(
                  Icons.delivery_dining,
                  color: Colors.teal,
                  size: 30,
                ),
        ),
        title: Text(
          _profileName(profile),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${distance.toStringAsFixed(1)} km away',
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: live ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    live ? 'Live now' : 'Registered',
                    style: TextStyle(
                      color: live ? Colors.green.shade700 : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openProfile(profile),
      ),
    );
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final int count = _selectedProfiles.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryName} Nearby'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_open, color: Colors.teal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _hasActiveSubscription
                            ? 'Profile access: ${_activeDistanceKm.toStringAsFixed(0)} km'
                            : 'Free profile access: 1 km',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Discovery: 50 km',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _sectionButton(
                      title: 'Live (${_allLiveProfiles.length})',
                      selected:
                          _selectedSection == FishDeliverySection.live,
                      onTap: () =>
                          _changeSection(FishDeliverySection.live),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _sectionButton(
                      title:
                          'Registered (${_allRegisteredProfiles.length})',
                      selected:
                          _selectedSection == FishDeliverySection.registered,
                      onTap: () =>
                          _changeSection(FishDeliverySection.registered),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 300,
              child: _locationLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _buildMap(),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                _selectedSection == FishDeliverySection.live
                    ? 'Live Fish Delivery Riders'
                    : 'Registered Fish Delivery Riders',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (count == 0)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: Text(
                    'No matching fish delivery riders found within 50 km.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              ..._visibleProfiles.map(_buildProfileCard),

              if (_hasMore)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _loadingMore ? null : _loadMore,
                      child: _loadingMore
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Load more'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.teal : Colors.grey.shade200,
        foregroundColor: selected ? Colors.white : Colors.black87,
        elevation: selected ? 2 : 0,
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
      child: Text(title),
    );
  }

  @override
  void dispose() {
    _subscriptionTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }
}