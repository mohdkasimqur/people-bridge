import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import 'screen_rental_profile.dart';

class RentalNearbyScreen extends StatefulWidget {
  final String category;

  const RentalNearbyScreen({
    super.key,
    required this.category,
  });

  @override
  State<RentalNearbyScreen> createState() =>
      _RentalNearbyScreenState();
}

class _RentalNearbyScreenState
    extends State<RentalNearbyScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const double maximumSearchRadiusKm = 50.0;

  bool _loading = true;
  bool _locationError = false;

 // Position? _userPosition;

  // double _paidRadiusKm = 5.0;

  // List<_RentalResult> _rentals = [];
  // ============================================================
// SUBSCRIPTION AND PAGINATION
// ============================================================

static const double freeRadiusKm = 1.0;

static const int rentalsPerPage = 10;

double _paidRadiusKm = freeRadiusKm;

List<_RentalResult> _rentals = [];

int _currentPage = 0;

int get _totalPages =>
    (_rentals.length / rentalsPerPage).ceil();

List<_RentalResult> get _currentPageRentals {
  final start = _currentPage * rentalsPerPage;

  final end = math.min(
    start + rentalsPerPage,
    _rentals.length,
  );

  return _rentals.sublist(start, end);
}

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  // ============================================================
  // LOAD RENTALS
  // ============================================================

  Future<void> _loadRentals() async {
    setState(() {
      _loading = true;
      _locationError = false;
    });

    try {
      final position = await _getUserLocation();

      if (position == null) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _locationError = true;
        });

        return;
      }

     // _userPosition = position;

      // --------------------------------------------------------
      // IMPORTANT:
      //
      // Replace this function later with your existing paid-radius
      // storage if its Hive/SharedPreferences key is different.
      // --------------------------------------------------------

      _paidRadiusKm = await _getPaidRadiusKm();

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection('rentals')
              .get();

      final List<_RentalResult> results = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (!_categoryMatches(data)) {
          continue;
        }

        final coordinates = _getCoordinates(data);

        if (coordinates == null) {
          continue;
        }

        final double distanceKm = _calculateDistanceKm(
          position.latitude,
          position.longitude,
          coordinates.latitude,
          coordinates.longitude,
        );

        // Only rentals within 50 km are shown.
        if (distanceKm > maximumSearchRadiusKm) {
          continue;
        }

        results.add(
          _RentalResult(
            documentId: doc.id,
            data: data,
            distanceKm: distanceKm,
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
          ),
        );
      }

      // --------------------------------------------------------
      // NEAREST FIRST
      // --------------------------------------------------------

      results.sort(
        (a, b) =>
            a.distanceKm.compareTo(b.distanceKm),
      );

      if (!mounted) return;

    setState(() {
  _rentals = results;
  _currentPage = 0;
  _loading = false;
});
    } catch (e) {
      debugPrint(
        'Rental loading error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _locationError = true;
      });
    }
  }

  // ============================================================
  // USER LOCATION
  // ============================================================

  Future<Position?> _getUserLocation() async {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (mounted) {
        _showLocationDialog(
          'Location is turned off',
          'Please turn on location services to find nearby rentals.',
        );
      }

      return null;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showLocationDialog(
          'Location permission required',
          'Please allow location permission to find rentals near you.',
        );
      }

      return null;
    }

    return Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
  ),
);
  }

  // ============================================================
  // CATEGORY MATCHING
  // ============================================================

  bool _categoryMatches(
    Map<String, dynamic> data,
  ) {
    final String selected =
        widget.category.trim().toLowerCase();

    // ----------------------------------------------------------
    // categories can be:
    //
    // categories: ["Car Rentals", "Vehicle"]
    //
    // OR
    //
    // categories: "Car Rentals"
    // ----------------------------------------------------------

    final dynamic categories =
        data['categories'];

    if (categories is List) {
      for (final item in categories) {
        if (item
            .toString()
            .trim()
            .toLowerCase() ==
            selected) {
          return true;
        }
      }

      // Also allow partial matching.
      for (final item in categories) {
        final String value = item
            .toString()
            .trim()
            .toLowerCase();

        if (value.contains(selected) ||
            selected.contains(value)) {
          return true;
        }
      }
    }

    if (categories is String) {
      final String value =
          categories.trim().toLowerCase();

      if (value == selected ||
          value.contains(selected) ||
          selected.contains(value)) {
        return true;
      }
    }

    // ----------------------------------------------------------
    // Also check a single "category" field if your rental
    // registration saves it there.
    // ----------------------------------------------------------

    final dynamic category =
        data['category'];

    if (category is String) {
      final String value =
          category.trim().toLowerCase();

      if (value == selected ||
          value.contains(selected) ||
          selected.contains(value)) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // GET COORDINATES
  // ============================================================

  _Coordinates? _getCoordinates(
    Map<String, dynamic> data,
  ) {
    // ----------------------------------------------------------
    // 1. Direct latitude / longitude
    // ----------------------------------------------------------

    final double? directLatitude =
        _toDouble(data['latitude']);

    final double? directLongitude =
        _toDouble(data['longitude']);

    if (directLatitude != null &&
        directLongitude != null) {
      return _Coordinates(
        directLatitude,
        directLongitude,
      );
    }

    // ----------------------------------------------------------
    // 2. currentLocation
    // ----------------------------------------------------------

    final dynamic currentLocation =
        data['currentLocation'];

    final _Coordinates? current =
        _readLocationMap(currentLocation);

    if (current != null) {
      return current;
    }

    // ----------------------------------------------------------
    // 3. location
    // ----------------------------------------------------------

    final dynamic location =
        data['location'];

    final _Coordinates? saved =
        _readLocationMap(location);

    if (saved != null) {
      return saved;
    }

    return null;
  }

  _Coordinates? _readLocationMap(
    dynamic value,
  ) {
    if (value is! Map) {
      return null;
    }

    final double? latitude =
        _toDouble(
      value['latitude'] ??
          value['lat'],
    );

    final double? longitude =
        _toDouble(
      value['longitude'] ??
          value['lng'] ??
          value['lon'],
    );

    if (latitude == null ||
        longitude == null) {
      return null;
    }

    return _Coordinates(
      latitude,
      longitude,
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  // ============================================================
  // PAID RADIUS
  // ============================================================

  // Future<double> _getPaidRadiusKm() async {
  //   /*
  //    * ----------------------------------------------------------
  //    * IMPORTANT
  //    *
  //    * Your app already has a paid-radius system.
  //    *
  //    * Put your existing Hive/SharedPreferences reading code here.
  //    *
  //    * For now this returns 5 km.
  //    *
  //    * This means:
  //    *
  //    * 0 - 5 km  = accessible
  //    * 5 - 50 km = asks for extra distance payment
  //    *
  //    * Change ONLY this function when connecting your existing
  //    * payment storage.
  //    * ----------------------------------------------------------
  //    */

  //   return 5.0;
  // }
  Future<double> _getPaidRadiusKm() async {
  final box = Hive.box('settings');

  final savedDistance = box.get('activeDistance');
  final savedExpiry = box.get('subscriptionExpiry');
  final savedActive = box.get('subscriptionActive');

  // ----------------------------------------------------------
  // DEFAULT FREE DISTANCE
  // ----------------------------------------------------------

  double unlockedDistance = freeRadiusKm;

  if (savedDistance == null || savedExpiry == null) {
    _paidRadiusKm = freeRadiusKm;
    return freeRadiusKm;
  }

  final expiry = DateTime.tryParse(
    savedExpiry.toString(),
  );

  // ----------------------------------------------------------
  // INVALID OR EXPIRED SUBSCRIPTION
  // ----------------------------------------------------------

  if (expiry == null ||
      !DateTime.now().isBefore(expiry) ||
      savedActive != true) {
    await box.delete('activeDistance');
    await box.delete('subscriptionStart');
    await box.delete('subscriptionExpiry');
    await box.delete('subscriptionDuration');
    await box.delete('subscriptionPaidAmount');
    await box.delete('subscriptionActive');

    _paidRadiusKm = freeRadiusKm;

    return freeRadiusKm;
  }

  // ----------------------------------------------------------
  // ACTIVE SUBSCRIPTION
  // ----------------------------------------------------------

  if (savedDistance is num) {
    unlockedDistance = savedDistance.toDouble();
  }

  // Never allow a subscription to reduce the free 1 km.
  unlockedDistance = math.max(
    freeRadiusKm,
    unlockedDistance,
  );

  // Maximum discovery distance is 50 km.
  unlockedDistance = math.min(
    maximumSearchRadiusKm,
    unlockedDistance,
  );

  _paidRadiusKm = unlockedDistance;

  return unlockedDistance;
}

  // ============================================================
  // RENTAL TAP
  // ============================================================

  void _onRentalPressed(
    _RentalResult rental,
  ) {
    final bool insidePaidRadius =
        rental.distanceKm <= _paidRadiusKm;

    if (!insidePaidRadius) {
      _showExtraDistanceDialog(
        rental,
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RentalProfileScreen(
          rentalId: rental.documentId,
          username:
              _stringValue(
            rental.data['username'],
          ),
          companyName:
              _stringValue(
            rental.data['companyName'],
          ),
          phoneNumber:
              _stringValue(
            rental.data['phoneNumber'],
          ),
          categories:
              _readCategories(
            rental.data['categories'],
          ),
          latitude: rental.latitude,
          longitude: rental.longitude,
          distanceKm: rental.distanceKm,
        ),
      ),
    );
  }

  // ============================================================
  // EXTRA DISTANCE POPUP
  // ============================================================

  void _showExtraDistanceDialog(
    _RentalResult rental,
  ) {
    final double extraDistance =
        rental.distanceKm - _paidRadiusKm;

    final int extraKm =
        math.max(
          1,
          extraDistance.ceil(),
        );

    final int estimatedCharge =
        _calculateExtraCharge(
      extraKm,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: Color(0xFF078A18),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Extra Distance Required',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                '${_displayRentalName(rental.data)} is '
                '${rental.distanceKm.toStringAsFixed(1)} km away.',
              ),
              const SizedBox(height: 12),
              Text(
                'Your current paid radius is '
                '${_paidRadiusKm.toStringAsFixed(0)} km.',
              ),
              const SizedBox(height: 8),
              Text(
                'Additional distance required: '
                '$extraKm km.',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFE8F5E9),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Text(
                  'Estimated extra charge: ₹$estimatedCharge',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        Color(0xFF078A18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pay for the additional distance to access this rental.',
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                _startExtraDistancePayment(
                  rental,
                  extraKm,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF078A18),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'PAY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EXTRA DISTANCE PRICE
  // ============================================================

  int _calculateExtraCharge(
    int extraKm,
  ) {
    /*
     * Your earlier pricing structure:
     *
     * 1 - 5 km  = free
     * 6 km onward = ₹5/km
     *
     * This function calculates the additional distance portion.
     */

    if (extraKm <= 0) {
      return 0;
    }

    return extraKm * 5;
  }

  // ============================================================
  // PAYMENT BUTTON
  // ============================================================

  void _startExtraDistancePayment(
    _RentalResult rental,
    int extraKm,
  ) {
    /*
     * ----------------------------------------------------------
     * CONNECT YOUR EXISTING PAYMENT SYSTEM HERE.
     *
     * After successful payment, update the user's paid radius
     * and reload this page.
     *
     * Example:
     *
     * await yourPaymentFunction();
     *
     * await _saveNewPaidRadius(...);
     *
     * await _loadRentals();
     * ----------------------------------------------------------
     */

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Payment for $extraKm km will be processed here.',
        ),
        duration:
            const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // RENTAL NAME
  // ============================================================

  String _displayRentalName(
    Map<String, dynamic> data,
  ) {
    final String? company =
        _stringValue(
      data['companyName'],
    );

    if (company != null &&
        company.isNotEmpty) {
      return company;
    }

    final String? username =
        _stringValue(
      data['username'],
    );

    if (username != null &&
        username.isNotEmpty) {
      return username;
    }

    return 'This rental';
  }

  String? _stringValue(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final String result =
        value.toString().trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }

  List<String>? _readCategories(
    dynamic value,
  ) {
    if (value is List) {
      return value
          .map(
            (e) => e.toString(),
          )
          .toList();
    }

    if (value is String &&
        value.trim().isNotEmpty) {
      return [value.trim()];
    }

    return null;
  }

  // ============================================================
  // DISTANCE CALCULATION
  // ============================================================

  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm =
        6371.0;

    final double dLat =
        _degreesToRadians(
      lat2 - lat1,
    );

    final double dLon =
        _degreesToRadians(
      lon2 - lon1,
    );

    final double a =
        math.sin(dLat / 2) *
                math.sin(dLat / 2) +
            math.cos(
                  _degreesToRadians(lat1),
                ) *
                math.cos(
                  _degreesToRadians(lat2),
                ) *
                math.sin(dLon / 2) *
                math.sin(dLon / 2);

    final double c =
        2 *
            math.atan2(
              math.sqrt(a),
              math.sqrt(
                1 - a,
              ),
            );

    return earthRadiusKm * c;
  }

  double _degreesToRadians(
    double degrees,
  ) {
    return degrees *
        math.pi /
        180.0;
  }

  // ============================================================
  // LOCATION ERROR DIALOG
  // ============================================================

  void _showLocationDialog(
    String title,
    String message,
  ) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _loadRentals();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF078A18),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.category,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildPaginationControls() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 0
              ? () {
                  setState(() {
                    _currentPage--;
                  });
                }
              : null,
          icon: const Icon(Icons.chevron_left),
        ),

        Text(
          'Page ${_currentPage + 1} of $_totalPages',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        IconButton(
          onPressed: _currentPage < _totalPages - 1
              ? () {
                  setState(() {
                    _currentPage++;
                  });
                }
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );
}

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF078A18),
        ),
      );
    }

    if (_locationError) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_off,
                size: 60,
                color: Colors.grey,
              ),
              const SizedBox(height: 15),
              const Text(
                'Unable to get your location',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Turn on location permission and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _refresh,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF078A18),
                  foregroundColor:
                      Colors.white,
                ),
                child:
                    const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      );
    }

    if (_rentals.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF078A18),
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 170),
            Icon(
              Icons.search_off,
              size: 65,
              color: Colors.grey,
            ),
            SizedBox(height: 15),
            Center(
              child: Text(
                'No rentals found within 50 km.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Try another rental category.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFF078A18),
      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          14,
          16,
          14,
          25,
        ),
        children: [
          _buildInformationHeader(),
          const SizedBox(height: 14),

          // ...List.generate(
          //   _rentals.length,
          //   (index) {
          //     final rental =
          //         _rentals[index];

          //     return Padding(
          //       padding:
          //           const EdgeInsets.only(
          //         bottom: 12,
          //       ),
          //       child:
          //           _buildRentalCard(
          //         rental,
          //         index,
          //       ),
          //     );
          //   },
          // ),
          ..._currentPageRentals.map((rental) {
  return Padding(
    padding: const EdgeInsets.only(
      bottom: 12,
    ),
    child: _buildRentalCard(
      rental,
      _rentals.indexOf(rental),
    ),
  );
}),

if (_totalPages > 1)
  _buildPaginationControls(),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION HEADER
  // ============================================================

  Widget _buildInformationHeader() {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 
              0.05,
            ),
            blurRadius: 8,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFE8F5E9),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: const Icon(
              Icons.location_on,
              color:
                  Color(0xFF078A18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${_rentals.length} ${widget.category}',
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Within 50 km • Nearest first',
                  style:
                      const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RENTAL CARD
  // ============================================================

  Widget _buildRentalCard(
    _RentalResult rental,
    int index,
  ) {
    final bool unlocked =
        rental.distanceKm <=
            _paidRadiusKm;

    final String name =
        _displayRentalName(
      rental.data,
    );

    final String? phone =
        _stringValue(
      rental.data['phoneNumber'],
    );

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: () {
          _onRentalPressed(
            rental,
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: unlocked
                          ? const Color(
                              0xFFE8F5E9,
                            )
                          : const Color(
                              0xFFFFF3E0,
                            ),
                      borderRadius:
                          BorderRadius.circular(
                        17,
                      ),
                    ),
                    child: Icon(
                      _categoryIcon(
                        widget.category,
                      ),
                      color: unlocked
                          ? const Color(
                              0xFF078A18,
                            )
                          : Colors.orange,
                      size: 31,
                    ),
                  ),
                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color:
                                  Colors.redAccent,
                            ),
                            const SizedBox(
                              width: 4,
                            ),
                            Text(
                              '${rental.distanceKm.toStringAsFixed(1)} km away',
                              style:
                                  const TextStyle(
                                fontSize: 13,
                                color:
                                    Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 9,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: unlocked
                          ? const Color(
                              0xFFE8F5E9,
                            )
                          : const Color(
                              0xFFFFF3E0,
                            ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Icon(
                      unlocked
                          ? Icons
                              .arrow_forward_ios
                          : Icons.lock_outline,
                      size: 17,
                      color: unlocked
                          ? const Color(
                              0xFF078A18,
                            )
                          : Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 13),

              const Divider(
                height: 1,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          unlocked
                              ? Icons.check_circle
                              : Icons.lock,
                          size: 17,
                          color: unlocked
                              ? const Color(
                                  0xFF078A18,
                                )
                              : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          unlocked
                              ? 'Available in your radius'
                              : 'Outside paid radius',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600,
                            color: unlocked
                                ? const Color(
                                    0xFF078A18,
                                  )
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (phone != null)
                    Text(
                      phone,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Colors.black54,
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

  IconData _categoryIcon(
    String category,
  ) {
    final String value =
        category.toLowerCase();

    if (value.contains('car')) {
      return Icons.directions_car;
    }

    if (value.contains('van')) {
      return Icons.airport_shuttle;
    }

    if (value.contains('bike')) {
      return Icons.two_wheeler;
    }

    if (value.contains('auto')) {
      return Icons.electric_rickshaw;
    }

    if (value.contains('lorry')) {
      return Icons.local_shipping;
    }

    if (value.contains('tipper')) {
      return Icons.local_shipping_outlined;
    }

    if (value.contains('jcb')) {
      return Icons.construction;
    }

    if (value.contains('tractor')) {
      return Icons.agriculture;
    }

    if (value.contains('house')) {
      return Icons.home_work_outlined;
    }

    if (value.contains('shop')) {
      return Icons.storefront;
    }

    if (value.contains('office')) {
      return Icons.business;
    }

    return Icons.car_rental;
  }
}

// ================================================================
// RENTAL RESULT MODEL
// ================================================================

class _RentalResult {
  final String documentId;
  final Map<String, dynamic> data;
  final double distanceKm;
  final double latitude;
  final double longitude;

  const _RentalResult({
    required this.documentId,
    required this.data,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
  });
}

// ================================================================
// COORDINATES MODEL
// ================================================================

class _Coordinates {
  final double latitude;
  final double longitude;

  const _Coordinates(
    this.latitude,
    this.longitude,
  );
}