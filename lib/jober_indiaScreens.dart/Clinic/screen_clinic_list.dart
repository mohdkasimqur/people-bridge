import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:jober_india/jober_indiaScreens.dart/Clinic/screen_clinic_profile.dart';
import 'package:url_launcher/url_launcher.dart';

class ScreenClinicsNearby extends StatefulWidget {
  final String selectedCategory;

  const ScreenClinicsNearby({
    super.key,
    required this.selectedCategory,
  });

  @override
  State<ScreenClinicsNearby> createState() =>
      _ScreenClinicsNearbyState();
}

class _ScreenClinicsNearbyState
    extends State<ScreenClinicsNearby> {
  static const Color primaryGreen = Color(0xFF16803C);
  static const Color darkGreen = Color(0xFF12652F);
  static const Color lightBackground = Color(0xFFF9F9F9);

  static const int pageSize = 20;
  static const double freeDistanceKm = 1.0;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final ScrollController _scrollController =
      ScrollController();

  List<Map<String, dynamic>> _allClinics = [];
  List<Map<String, dynamic>> _visibleClinics = [];

  Position? _userPosition;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;

  String? _errorMessage;

  double paidDistance = 1.0;
  double selectedDistance = 1.0;
  DateTime? paymentExpiry;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    _initializePage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  Future<void> _initializePage() async {
    await loadPaymentData();

    if (!mounted) return;

    await _getUserLocation();
  }

  // ==========================================================
  // SUBSCRIPTION
  // ==========================================================

  bool get hasActiveSubscription {
    return paymentExpiry != null &&
        DateTime.now().isBefore(paymentExpiry!);
  }

  bool get hasValidPayment {
    return hasActiveSubscription &&
        paidDistance >= selectedDistance;
  }
Future<void> loadPaymentData() async {
  final box = Hive.box('settings');

  final savedDistance = box.get('activeDistance');
  final savedExpiry = box.get('subscriptionExpiry');

  double distance = 1.0;

  DateTime? expiry;

  if (savedDistance is num) {
    distance = savedDistance.toDouble();
  }

  if (savedExpiry != null) {
    expiry = DateTime.tryParse(
      savedExpiry.toString(),
    );
  }

  // Check subscription validity.
  if (expiry == null ||
      !DateTime.now().isBefore(expiry)) {

    distance = 1.0;
    expiry = null;

    // Remove expired subscription data.
    await box.delete('activeDistance');
    await box.delete('subscriptionStart');
    await box.delete('subscriptionExpiry');
    await box.delete('subscriptionDuration');
    await box.delete('subscriptionPaidAmount');
    await box.delete('subscriptionActive');
  }

  paidDistance = distance;
  paymentExpiry = expiry;

  selectedDistance = 1.0;

  if (mounted) {
    setState(() {});
  }
}

  double get effectiveDistanceKm {
    if (!hasActiveSubscription) {
      return freeDistanceKm;
    }

    return paidDistance < freeDistanceKm
        ? freeDistanceKm
        : paidDistance;
  }

  // bool _canOpenClinic(double distanceKm) {
  //   if (distanceKm <= freeDistanceKm) {
  //     return true;
  //   }

  //   return hasActiveSubscription &&
  //       distanceKm <= paidDistance;
  // }
  bool _canOpenClinic(double distanceKm) {

  // Free access within 1 KM.
  if (distanceKm <= 1.0) {
    return true;
  }

  // Subscription must be valid.
  if (paymentExpiry == null ||
      !DateTime.now().isBefore(paymentExpiry!)) {
    return false;
  }

  // Only allow profiles within purchased distance.
  return distanceKm <= paidDistance;
}

  // ==========================================================
  // GET USER GPS LOCATION
  // ==========================================================

  Future<void> _getUserLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Please turn on your phone location and try again.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is required to find nearby clinics.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      _userPosition = position;

      await _loadClinics();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // ==========================================================
  // LOAD CLINICS FOR SELECTED CATEGORY
  // ==========================================================

  Future<void> _loadClinics() async {
    final userPosition = _userPosition;

    if (userPosition == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final category = widget.selectedCategory.trim();

      // Query both modern categories[] and legacy category fields.
      // These are one-time reads, not permanent listeners.
      final results = await Future.wait([
        _firestore
            .collection('clinics')
            .where('isActive', isEqualTo: true)
            .where('categories', arrayContains: category)
            .get(),

        _firestore
            .collection('clinics')
            .where('isActive', isEqualTo: true)
            .where('category', isEqualTo: category)
            .get(),
      ]);

      final Map<String, Map<String, dynamic>> unique =
          {};

      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          unique[doc.id] = {
            ...doc.data(),
            '_documentId': doc.id,
          };
        }
      }

      final List<Map<String, dynamic>> nearby = [];

      for (final clinic in unique.values) {
        final coordinates = _getClinicCoordinates(clinic);

        // Without coordinates, exact distance and navigation
        // cannot be guaranteed.
        if (coordinates == null) continue;

        final distanceKm = Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              coordinates.latitude,
              coordinates.longitude,
            ) /
            1000.0;

        // // Show clinics only within the currently unlocked radius.
        // if (distanceKm > effectiveDistanceKm) continue;
        // Always display clinics within 50 KM.
// Subscription controls profile access, not visibility.

if (distanceKm > 50.0) continue;

        clinic['distanceKm'] = distanceKm;
        clinic['_clinicLatitude'] = coordinates.latitude;
        clinic['_clinicLongitude'] = coordinates.longitude;

        nearby.add(clinic);
      }

      // Nearest first.
      nearby.sort((a, b) =>
          (a['distanceKm'] as double).compareTo(
            b['distanceKm'] as double,
          ));

      if (!mounted) return;

      setState(() {
        _allClinics = nearby;
        _visibleClinics = [];
        _isLoading = false;

        _appendNextPage();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load clinics. Please try again.';
      });

      debugPrint('Load nearby clinics error: $e');
    }
  }

  // ==========================================================
  // READ COORDINATES FROM COMPATIBLE LOCATION FIELDS
  // ==========================================================

  _ClinicCoordinates? _getClinicCoordinates(
    Map<String, dynamic> clinic,
  ) {
    final candidates = [
      clinic['locationAddress'],
      clinic['currentLocation'],
      clinic['location'],
      clinic,
    ];

    for (final candidate in candidates) {
      if (candidate is GeoPoint) {
        return _ClinicCoordinates(
          candidate.latitude,
          candidate.longitude,
        );
      }

      if (candidate is! Map) continue;

      final latitude = _toDouble(
        candidate['latitude'] ?? candidate['lat'],
      );

      final longitude = _toDouble(
        candidate['longitude'] ?? candidate['lng'],
      );

      if (latitude != null && longitude != null) {
        if (latitude >= -90 &&
            latitude <= 90 &&
            longitude >= -180 &&
            longitude <= 180) {
          return _ClinicCoordinates(
            latitude,
            longitude,
          );
        }
      }
    }

    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // ==========================================================
  // LOCAL PAGINATION
  // ==========================================================

  void _appendNextPage() {
    final currentCount = _visibleClinics.length;

    if (currentCount >= _allClinics.length) {
      _hasMore = false;
      return;
    }

    final end = (currentCount + pageSize)
        .clamp(0, _allClinics.length);

    _visibleClinics.addAll(
      _allClinics.sublist(currentCount, end),
    );

    _hasMore = end < _allClinics.length;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Future<void>.delayed(Duration.zero);

    if (!mounted) return;

    setState(() {
      _appendNextPage();
      _isLoadingMore = false;
    });
  }

  // ==========================================================
  // DISTANCE TEXT
  // ==========================================================

  String _getDistanceText(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m away';
    }

    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  // ==========================================================
  // CLINIC LOCATION BUTTON
  // ==========================================================

  Future<void> _openClinicLocation(
    Map<String, dynamic> clinic,
  ) async {
    final latitude =
        _toDouble(clinic['_clinicLatitude']);
    final longitude =
        _toDouble(clinic['_clinicLongitude']);

    if (latitude == null || longitude == null) {
      _showMessage(
        'This clinic has no valid saved map coordinates.',
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=$latitude,$longitude',
    );

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        _showMessage('Unable to open Google Maps.');
      }
    } catch (e) {
      debugPrint('Open clinic location error: $e');
      _showMessage('Unable to open the clinic location.');
    }
  }

  // ==========================================================
  // PROFILE ACCESS PLACEHOLDER
  // ==========================================================

  // void _handleClinicTap(
  //   Map<String, dynamic> clinic,
  // ) {
  //   final distanceKm =
  //       (clinic['distanceKm'] as num).toDouble();

  //   if (!_canOpenClinic(distanceKm)) {
  //     _showSubscriptionRequiredDialog(distanceKm);
  //     return;
  //   }

  //   // We will connect this to the clinic profile screen
  //   // after that page is created.
  //   _showMessage(
  //     'Clinic profile page will be connected next.',
  //   );
  // }
  void _handleClinicTap(Map<String, dynamic> clinic) {
  final distanceKm =
      (clinic['distanceKm'] as num).toDouble();

  if (!_canOpenClinic(distanceKm)) {
    _showSubscriptionRequiredDialog(distanceKm);
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ScreenClinicProfile(
        clinicData: clinic,
        userLatitude: _userPosition?.latitude,
        userLongitude: _userPosition?.longitude,
        selectedCategory: widget.selectedCategory,
      ),
    ),
  );
}

  void _showSubscriptionRequiredDialog(
    double distanceKm,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Distance access required'),
          content: Text(
            'This clinic is ${_getDistanceText(distanceKm)}. '
            'Your current access is ${effectiveDistanceKm.round()} km. '
            'Unlock a larger distance to open this clinic profile.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ==========================================================
  // CLINIC NAME / CATEGORY
  // ==========================================================

  String _clinicName(Map<String, dynamic> clinic) {
    final name = (clinic['clinicName'] ??
            clinic['name'] ??
            clinic['username'] ??
            'Clinic')
        .toString()
        .trim();

    return name.isEmpty ? 'Clinic' : name;
  }

  String _clinicAddress(Map<String, dynamic> clinic) {
    final candidates = [
      clinic['locationAddress'],
      clinic['currentLocation'],
      clinic['location'],
    ];

    for (final candidate in candidates) {
      if (candidate is Map) {
        final name = (candidate['placeName'] ??
                candidate['address'] ??
                '')
            .toString()
            .trim();

        if (name.isNotEmpty) return name;
      }
    }

    return 'Clinic location attached';
  }
  // ==========================================================
  // SUBSCRIPTION STATUS CARD
  // ==========================================================

  Widget _subscriptionCard() {
    final active = hasActiveSubscription;

    String subtitle;

    if (active && paymentExpiry != null) {
      final remaining =
          paymentExpiry!.difference(DateTime.now());

      subtitle =
          'Expires in ${remaining.inHours}h '
          '${remaining.inMinutes % 60}m';
    } else {
      subtitle = 'Clinics within 1 km are free';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFE8F5E9)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? primaryGreen
              : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            active
                ? Icons.verified_outlined
                : Icons.lock_open_outlined,
            color: primaryGreen,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active
                      ? '${paidDistance.round()} km unlocked'
                      : 'Free nearby access',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh clinics',
            onPressed: _isLoading
                ? null
                : () async {
                    await loadPaymentData();

                    if (!mounted) return;

                    await _getUserLocation();
                  },
            icon: const Icon(
              Icons.refresh,
              color: primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CLINIC CARD
  // ==========================================================

  Widget _clinicCard(
    Map<String, dynamic> clinic,
    int index,
  ) {
    final distanceKm =
        (clinic['distanceKm'] as num).toDouble();

    final canOpen = _canOpenClinic(distanceKm);

    final address = _clinicAddress(clinic);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE5E5E5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleClinicTap(clinic),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_hospital_outlined,
                      color: primaryGreen,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _clinicName(clinic),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.selectedCategory,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.near_me_outlined,
                              size: 16,
                              color: primaryGreen,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _getDistanceText(distanceKm),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: darkGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    canOpen
                        ? Icons.lock_open_outlined
                        : Icons.lock_outline,
                    color: canOpen
                        ? primaryGreen
                        : Colors.orange.shade800,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF777777),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openClinicLocation(clinic),
                      icon: const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                      ),
                      label: const Text('Location'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryGreen,
                        side: const BorderSide(
                          color: primaryGreen,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _handleClinicTap(clinic),
                      icon: Icon(
                        canOpen
                            ? Icons.person_outline
                            : Icons.lock_outline,
                        size: 18,
                      ),
                      label: Text(
                        canOpen ? 'View Profile' : 'Locked',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 50,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_searching,
              size: 58,
              color: Color(0xFF9E9E9E),
            ),
            const SizedBox(height: 14),
            const Text(
              'No nearby clinics found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No clinics in "${widget.selectedCategory}" '
              'were found within your current access radius.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () async {
                await loadPaymentData();

                if (!mounted) return;

                await _getUserLocation();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: const BorderSide(
                  color: primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PAGE UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Nearby Clinics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.selectedCategory,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Clinics sorted from nearest to farthest',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _subscriptionCard(),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: primaryGreen,
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_off_outlined,
                                  size: 48,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton(
                                  onPressed: _getUserLocation,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryGreen,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _visibleClinics.isEmpty
                          ? _emptyState()
                          : RefreshIndicator(
                              color: primaryGreen,
                              onRefresh: () async {
                                await loadPaymentData();

                                if (!mounted) return;

                                await _getUserLocation();
                              },
                              child: ListView.builder(
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  20,
                                ),
                                itemCount:
                                    _visibleClinics.length +
                                        (_isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >=
                                      _visibleClinics.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child:
                                            CircularProgressIndicator(
                                          color: primaryGreen,
                                        ),
                                      ),
                                    );
                                  }

                                  return _clinicCard(
                                    _visibleClinics[index],
                                    index,
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CLINIC COORDINATES
// ============================================================

class _ClinicCoordinates {
  final double latitude;
  final double longitude;

  const _ClinicCoordinates(
    this.latitude,
    this.longitude,
  );
}