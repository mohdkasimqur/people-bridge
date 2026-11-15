import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jober_india/jober_indiaScreens.dart/selfEmployi/self_employee_profile.dart';

// ===============================================================
// SCREEN NEARBY SELF EMPLOYEES
// ===============================================================

class ScreenNearbySelfEmployees
    extends StatefulWidget {

  final String selectedCategory;

  const ScreenNearbySelfEmployees({
    super.key,
    required this.selectedCategory,
  });

  @override
  State<ScreenNearbySelfEmployees>
      createState() =>
          _ScreenNearbySelfEmployeesState();
}


// ===============================================================
// STATE
// ===============================================================

class _ScreenNearbySelfEmployeesState
    extends State<ScreenNearbySelfEmployees> {


  // =============================================================
  // FIRESTORE
  // =============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;


  // =============================================================
  // SCROLL CONTROLLER
  // =============================================================

  final ScrollController _scrollController =
      ScrollController();


static const int _pageSize = 20;

DocumentSnapshot<Map<String, dynamic>>? _lastRegisteredDocument;
DocumentSnapshot<Map<String, dynamic>>? _lastLiveDocument;

bool _hasMoreRegistered = true;
bool _hasMoreLive = true;

bool _isLoading = false;
bool _isLoadingMoreRegistered = false;
bool _isLoadingMoreLive = false;

bool _isLoadingRegistered = false;
bool _isLoadingLive = false;

// =============================================================
// RESULTS — TWO SEPARATE SECTIONS
// =============================================================

final List<Map<String, dynamic>> _registeredEmployees = [];
final List<Map<String, dynamic>> _liveEmployees = [];

final Set<String> _loadedRegisteredIds = <String>{};
final Set<String> _loadedLiveIds = <String>{};

static const double _maximumRadiusKm = 50.0;

// Free access: 1 km.
double _paidRadiusKm = 1.0;

String? _openingEmployeeId;
// =============================================================
// SELECTED NEARBY SECTION
// =============================================================

bool _showLiveEmployees = true;
  // =============================================================
  // LOCATION
  // =============================================================

  Position? _userPosition;

  bool _isGettingLocation = true;

  String? _locationError;

  // =============================================================
  // INIT STATE
  // =============================================================

  @override
  void initState() {

    super.initState();


    // -----------------------------------------------------------
    // SCROLL PAGINATION
    // -----------------------------------------------------------

    _scrollController.addListener(
      _onScroll,
    );


    // -----------------------------------------------------------
    // START PAGE
    // -----------------------------------------------------------

    _initializePage();

  }


  Future<void> _initializePage() async {
  await _loadPaidRadius();

  final bool locationSuccess = await _getUserLocation();

  if (!locationSuccess || !mounted) return;

  await Future.wait([
    _loadRegisteredEmployees(reset: true),
    _loadLiveEmployees(reset: true),
  ]);
}


  // =============================================================
  // LOAD PAID RADIUS
  // =============================================================

  Future<void> _loadPaidRadius() async {
  double radius = 1.0;

  try {
    final Box<dynamic> settingsBox =
        Hive.box<dynamic>('settings');

    final dynamic expiryValue =
        settingsBox.get('subscriptionExpiry');

    final dynamic savedRadius =
        settingsBox.get('activeDistance');

    DateTime? expiry;

    if (expiryValue is DateTime) {
      expiry = expiryValue;
    } else if (expiryValue is Timestamp) {
      expiry = expiryValue.toDate();
    } else if (expiryValue is String) {
      expiry = DateTime.tryParse(expiryValue);
    }

    // Only grant the paid radius if the subscription
    // has a valid future expiry.
    if (expiry != null && DateTime.now().isBefore(expiry)) {
      if (savedRadius is num) {
        radius = savedRadius.toDouble();
      } else if (savedRadius is String) {
        radius = double.tryParse(savedRadius) ?? 1.0;
      }
    }
  } catch (_) {
    radius = 1.0;
  }

  radius = radius.clamp(1.0, _maximumRadiusKm);

  if (!mounted) return;

  setState(() {
    _paidRadiusKm = radius;
  });
}


  // =============================================================
  // GET USER LOCATION
  // =============================================================

  Future<bool> _getUserLocation() async {

    if (!mounted) {
      return false;
    }


    setState(() {

      _isGettingLocation = true;

      _locationError = null;

    });


    try {

      // ---------------------------------------------------------
      // LOCATION SERVICE
      // ---------------------------------------------------------

      final bool serviceEnabled =
          await Geolocator
              .isLocationServiceEnabled();


      if (!serviceEnabled) {

        if (!mounted) {
          return false;
        }


        setState(() {

          _isGettingLocation = false;

          _locationError =
              'Location service is turned off.';

        });


        return false;
      }


      // ---------------------------------------------------------
      // LOCATION PERMISSION
      // ---------------------------------------------------------

      LocationPermission permission =
          await Geolocator
              .checkPermission();


      if (permission ==
          LocationPermission.denied) {

        permission =
            await Geolocator
                .requestPermission();

      }


      // ---------------------------------------------------------
      // PERMISSION DENIED
      // ---------------------------------------------------------

      if (permission ==
          LocationPermission.denied) {

        if (!mounted) {
          return false;
        }


        setState(() {

          _isGettingLocation = false;

          _locationError =
              'Location permission is required to find nearby SELF EMPLOYEES.';

        });


        return false;
      }


      // ---------------------------------------------------------
      // PERMISSION DENIED FOREVER
      // ---------------------------------------------------------

      if (permission ==
          LocationPermission.deniedForever) {

        if (!mounted) {
          return false;
        }


        setState(() {

          _isGettingLocation = false;

          _locationError =
              'Location permission is permanently denied. Please enable it from Settings.';

        });


        return false;
      }


      // ---------------------------------------------------------
      // GET CURRENT POSITION
      // ---------------------------------------------------------

      final Position position =
          await Geolocator
              .getCurrentPosition(

        locationSettings:
            const LocationSettings(

          accuracy:
              LocationAccuracy.high,

        ),

      );


      if (!mounted) {
        return false;
      }


      setState(() {

        _userPosition = position;

        _isGettingLocation = false;

        _locationError = null;

      });


      return true;

    } catch (_) {

      if (!mounted) {
        return false;
      }


      setState(() {

        _isGettingLocation = false;

        _locationError =
            'Unable to get your current location. Please try again.';

      });


      return false;

    }

  }


  // =============================================================
  // RETRY LOCATION
  // =============================================================

  Future<void> _retryLocation() async {
  final bool success = await _getUserLocation();

  if (!success || !mounted) return;

  await Future.wait([
    _loadLiveEmployees(reset: true),
    _loadRegisteredEmployees(reset: true),
  ]);
}

// =============================================================
  // SCROLL LISTENER
  // ======

void _onScroll() {
  if (!_scrollController.hasClients) return;

  final position = _scrollController.position;

  if (position.pixels < position.maxScrollExtent - 500) {
    return;
  }

  // Load more records only for the visible section.
  if (_showLiveEmployees) {
    if (_hasMoreLive &&
        !_isLoadingLive &&
        !_isLoadingMoreLive) {
      _loadLiveEmployees(reset: false);
    }
  } else {
    if (_hasMoreRegistered &&
        !_isLoadingRegistered &&
        !_isLoadingMoreRegistered) {
      _loadRegisteredEmployees(reset: false);
    }
  }
}

  // =============================================================
  // READ DOUBLE SAFELY
  // =============================================================

  double? _readDouble(
    dynamic value,
  ) {

    if (value is num) {

      return value.toDouble();

    }


    if (value is String) {

      return double.tryParse(
        value,
      );

    }
    return null;
  }

  bool _matchesSelectedCategory(Map<String, dynamic> data) {
  final String selected =
      widget.selectedCategory.trim().toLowerCase();

  final dynamic categoriesValue = data['categories'];

  if (categoriesValue is List) {
    for (final item in categoriesValue) {
      if (item.toString().trim().toLowerCase() == selected) {
        return true;
      }
    }
  }

  // Older documents may have only the singular category.
  return (data['category'] ?? '')
          .toString()
          .trim()
          .toLowerCase() ==
      selected;
}

double? _readFirstCoordinate(
  Map<String, dynamic> data,
  List<String> keys,
) {
  for (final key in keys) {
    final value = _readDouble(data[key]);

    if (value != null) return value;
  }

  return null;
}

double? _registrationLatitude(Map<String, dynamic> data) {
  final double? direct = _readFirstCoordinate(data, [
    'currentLocationLatitude',
    'latitude',
  ]);

  if (direct != null) return direct;

  final location = data['currentLocation'];

  if (location is Map) {
    return _readDouble(location['latitude']);
  }

  return null;
}

double? _registrationLongitude(Map<String, dynamic> data) {
  final double? direct = _readFirstCoordinate(data, [
    'currentLocationLongitude',
    'longitude',
  ]);

  if (direct != null) return direct;

  final location = data['currentLocation'];

  if (location is Map) {
    return _readDouble(location['longitude']);
  }

  return null;
}

Map<String, dynamic>? _buildNearbyEmployee({
  required String id,
  required Map<String, dynamic> data,
  required double latitude,
  required double longitude,
  required String locationType,
}) {
  if (data['isActive'] != true) return null;
  if (!_matchesSelectedCategory(data)) return null;

  if (latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180) {
    return null;
  }

  final double distanceKm = _calculateDistanceKm(
    _userPosition!.latitude,
    _userPosition!.longitude,
    latitude,
    longitude,
  );

  if (distanceKm > _maximumRadiusKm) return null;

  final employee = Map<String, dynamic>.from(data);

  employee['id'] = id;
  employee['distanceKm'] = distanceKm;
  employee['locationType'] = locationType;

  return employee;
}

Future<void> _loadRegisteredEmployees({
  required bool reset,
}) async {
  if (_userPosition == null) return;

  if (reset) {
    if (_isLoadingRegistered) return;

    setState(() {
      _isLoadingRegistered = true;
      _isLoadingMoreRegistered = false;
      _hasMoreRegistered = true;
      _lastRegisteredDocument = null;
      _registeredEmployees.clear();
      _loadedRegisteredIds.clear();
    });
  } else {
    if (_isLoadingMoreRegistered || !_hasMoreRegistered) return;

    setState(() {
      _isLoadingMoreRegistered = true;
    });
  }

  try {
    Query<Map<String, dynamic>> query = _firestore
        .collection('selfEmployees')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(_pageSize);

    if (!reset && _lastRegisteredDocument != null) {
      query = query.startAfterDocument(_lastRegisteredDocument!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastRegisteredDocument = snapshot.docs.last;
    }

    if (snapshot.docs.length < _pageSize) {
      _hasMoreRegistered = false;
    }

    final List<Map<String, dynamic>> page = [];

    for (final document in snapshot.docs) {
      if (_loadedRegisteredIds.contains(document.id)) continue;

      final data = document.data();

      if (!_matchesSelectedCategory(data)) continue;

      final latitude = _registrationLatitude(data);
      final longitude = _registrationLongitude(data);

      if (latitude == null || longitude == null) continue;

      final employee = _buildNearbyEmployee(
        id: document.id,
        data: data,
        latitude: latitude,
        longitude: longitude,
        locationType: 'registered',
      );

      if (employee == null) continue;

      page.add(employee);
      _loadedRegisteredIds.add(document.id);
    }

    if (!mounted) return;

    setState(() {
      _registeredEmployees.addAll(page);

      _registeredEmployees.sort((a, b) =>
          (a['distanceKm'] as double)
              .compareTo(b['distanceKm'] as double));
    });

    // Continue scanning if the page had no nearby matches.
    if (snapshot.docs.length == _pageSize &&
        page.isEmpty &&
        _hasMoreRegistered) {
      setState(() {
        _isLoadingMoreRegistered = false;
      });

      await _loadRegisteredEmployees(reset: false);
      return;
    }
  } catch (error) {
    debugPrint('Registered self-employed load error: $error');
  } finally {
    if (mounted) {
      setState(() {
        _isLoadingRegistered = false;
        _isLoadingMoreRegistered = false;
      });
    }
  }
}

Future<void> _loadLiveEmployees({
  required bool reset,
}) async {
  if (_userPosition == null) return;

  if (reset) {
    if (_isLoadingLive) return;

    setState(() {
      _isLoadingLive = true;
      _isLoadingMoreLive = false;
      _hasMoreLive = true;
      _lastLiveDocument = null;
      _liveEmployees.clear();
      _loadedLiveIds.clear();
    });
  } else {
    if (_isLoadingMoreLive || !_hasMoreLive) return;

    setState(() {
      _isLoadingMoreLive = true;
    });
  }

  try {
    Query<Map<String, dynamic>> query = _firestore
        .collection('liveLocations')
        .where('serviceType', isEqualTo: 'self_employee')
        .where('isLive', isEqualTo: true)
        .where(
          'expiresAt',
          isGreaterThan: Timestamp.now(),
        )
        .orderBy('expiresAt')
        .limit(_pageSize);

    if (!reset && _lastLiveDocument != null) {
      query = query.startAfterDocument(_lastLiveDocument!);
    }

    final snapshot = await query.get();

    
debugPrint(
  'LIVE SELF EMPLOYEES: '
  'Firestore returned ${snapshot.docs.length} documents.',
);

for (final doc in snapshot.docs) {
  final data = doc.data();

  debugPrint(
    'LIVE DOCUMENT: UID=${doc.id}, '
    'serviceType=${data['serviceType']}, '
    'role=${data['role']}, '
    'isLive=${data['isLive']}, '
    'categories=${data['categories']}, '
    'latitude=${data['latitude']}, '
    'longitude=${data['longitude']}, '
    'expiresAt=${data['expiresAt']}',
  );
}


    if (snapshot.docs.isNotEmpty) {
      _lastLiveDocument = snapshot.docs.last;
    }

    if (snapshot.docs.length < _pageSize) {
      _hasMoreLive = false;
    }

    final List<Map<String, dynamic>> page = [];

    for (final document in snapshot.docs) {
      if (_loadedLiveIds.contains(document.id)) continue;

      final liveData = document.data();

      if (liveData['isLive'] != true) continue;

      final expiry = liveData['expiresAt'];

      if (expiry is! Timestamp ||
          !expiry.toDate().isAfter(DateTime.now())) {
        continue;
      }

final latitude = _readDouble(liveData['latitude']);
final longitude = _readDouble(liveData['longitude']);

if (latitude == null || longitude == null) {
  debugPrint('LIVE SELF EMPLOYEE: Missing coordinates: ${document.id}');
  continue;
}

// Fetch the actual registered profile using the same UID.
final profileSnapshot = await _firestore
    .collection('selfEmployees')
    .doc(document.id)
    .get();

if (!profileSnapshot.exists) {
  debugPrint('LIVE SELF EMPLOYEE: Profile not found: ${document.id}');
  continue;
}

final profileData = profileSnapshot.data();

if (profileData == null) continue;

// The registered profile is the authority for category matching.
if (profileData['isActive'] != true) {
  debugPrint('LIVE SELF EMPLOYEE: Profile is inactive: ${document.id}');
  continue;
}

if (!_matchesSelectedCategory(profileData)) {
  debugPrint(
    'LIVE SELF EMPLOYEE: Category does not match. '
    'Selected: ${widget.selectedCategory}, '
    'Profile categories: ${profileData['categories']}',
  );
  continue;
}

final mergedData = <String, dynamic>{
  ...profileData,
  'liveLatitude': latitude,
  'liveLongitude': longitude,
};

final employee = _buildNearbyEmployee(
  id: document.id,
  data: mergedData,
  latitude: latitude,
  longitude: longitude,
  locationType: 'live',
);

if (employee == null) continue;

page.add(employee);
_loadedLiveIds.add(document.id);

debugPrint(
  'LIVE SELF EMPLOYEE FOUND: '
  '${profileData['name']} | UID: ${document.id}',
);
    }

    if (!mounted) return;

    setState(() {
      _liveEmployees.addAll(page);

      _liveEmployees.sort((a, b) =>
          (a['distanceKm'] as double)
              .compareTo(b['distanceKm'] as double));
    });

    if (snapshot.docs.length == _pageSize &&
        page.isEmpty &&
        _hasMoreLive) {
      setState(() {
        _isLoadingMoreLive = false;
      });

      await _loadLiveEmployees(reset: false);
      return;
    }
  } catch (error) {
    debugPrint('Live self-employed load error: $error');
  } finally {
    if (mounted) {
      setState(() {
        _isLoadingLive = false;
        _isLoadingMoreLive = false;
      });
    }
  }
  
}

  double _calculateDistanceKm(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {

    const double earthRadiusKm =
        6371.0;


    final double lat1 =
        _degreesToRadians(
      latitude1,
    );


    final double lat2 =
        _degreesToRadians(
      latitude2,
    );


    final double differenceLatitude =
        _degreesToRadians(
      latitude2 - latitude1,
    );


    final double differenceLongitude =
        _degreesToRadians(
      longitude2 - longitude1,
    );


    final double a =
        pow(
          sin(
            differenceLatitude / 2,
          ),
          2,
        ).toDouble() +
        cos(lat1) *
            cos(lat2) *
            pow(
              sin(
                differenceLongitude / 2,
              ),
              2,
            ).toDouble();


    final double c =
        2 *
        atan2(
          sqrt(a),
          sqrt(
            1 - a,
          ),
        );


    return earthRadiusKm * c;

  }


  // =============================================================
  // DEGREES TO RADIANS
  // =============================================================

  double _degreesToRadians(
    double degrees,
  ) {

    return degrees *
        pi /
        180.0;

  }


  // =============================================================
  // SORT NEAREST → FARTHEST
  // =============================================================

  Future<void> _refreshEmployees() async {
  if (_isLoading) return;

  setState(() {
    _isLoading = true;
  });

  try {
    await _loadPaidRadius();

    final bool success = await _getUserLocation();

    if (!success || !mounted) return;

    await Future.wait([
      _loadLiveEmployees(reset: true),
      _loadRegisteredEmployees(reset: true),
    ]);
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// ===============================================================
// PART 3 — UI, PROFILE ACCESS, PAYMENT/RADIUS DIALOG
// ===============================================================

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ===============================================================
  // OPEN SELF EMPLOYEE PROFILE
  // ===============================================================

  Future<void> _openEmployeeProfile(
  Map<String, dynamic> employee,
) async {
  if (_openingEmployeeId != null) return;

  // Recheck expiry before granting access.
  await _loadPaidRadius();

  if (!mounted) return;

  final String employeeId =
      employee['id']?.toString() ?? '';

  final double distanceKm =
      _readDouble(employee['distanceKm']) ?? double.infinity;

  if (distanceKm <= _paidRadiusKm) {
    setState(() {
      _openingEmployeeId = employeeId;
    });

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScreenSelfEmployeesProfile(
            employee: employee,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingEmployeeId = null;
        });
      }
    }

    return;
  }

  await _showRadiusPaymentDialog(
    employee: employee,
    distanceKm: distanceKm,
  );
}

  // ===============================================================
  // PAYMENT / EXTRA DISTANCE DIALOG
  // ===============================================================

  Future<void> _showRadiusPaymentDialog({
    required Map<String, dynamic> employee,
    required double distanceKm,
  }) async {
    if (!mounted) return;

    final double requiredRadius =
        distanceKm.clamp(1.0, _maximumRadiusKm);

    final double extraDistance =
        (requiredRadius - _paidRadiusKm).clamp(
      0.0,
      _maximumRadiusKm,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: Colors.orange,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Distance Limit',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                employee['name']?.toString() ??
                    'SELF EMPLOYEE',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                '${distanceKm.toStringAsFixed(1)} km away',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Your current paid radius is '
                '${_paidRadiusKm.toStringAsFixed(0)} km.',
              ),

              const SizedBox(height: 12),

              Text(
                'You need access up to '
                '${requiredRadius.toStringAsFixed(1)} km '
                'to open this profile.',
              ),

              if (extraDistance > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Additional distance needed: '
                  '${extraDistance.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],

              const SizedBox(height: 15),

              const Text(
                'Please increase your paid search radius '
                'to view this SELF EMPLOYEE profile.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'CANCEL',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _startRadiusUpgrade();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF198B35),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'INCREASE RADIUS',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startRadiusUpgrade() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Increase Search Radius',
          ),
          content: const Text(
            'Connect your distance payment screen here. '
            'After successful payment, the new paid radius '
            'should be saved in the settings box.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF198B35),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'OK',
              ),
            ),
          ],
        );
      },
    );
  }

  // ===============================================================
  // EMPLOYEE CARD
  // ===============================================================

  Widget _employeeCard(
    Map<String, dynamic> employee,
  ) {
    final String employeeId =
        employee['id']?.toString() ?? '';

    final String name =
        employee['name']?.toString().trim().isNotEmpty == true
            ? employee['name'].toString()
            : 'SELF EMPLOYEE';

    final String category =
        employee['category']?.toString().trim().isNotEmpty == true
            ? employee['category'].toString()
            : widget.selectedCategory;

    final double distanceKm =
        _readDouble(employee['distanceKm']) ?? 0.0;

    final bool profileAllowed =
        distanceKm <= _paidRadiusKm;

    final bool isOpening =
        _openingEmployeeId == employeeId;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 7,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isOpening
            ? null
            : () => _openEmployeeProfile(employee),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ---------------------------------------------------
              // PROFILE ICON
              // ---------------------------------------------------

              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person,
                  size: 30,
                  color: Color(0xFF198B35),
                ),
              ),

              const SizedBox(width: 13),

              // ---------------------------------------------------
              // EMPLOYEE INFORMATION
              // ---------------------------------------------------

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
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.work_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            category,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: profileAllowed
                              ? const Color(
                                  0xFF198B35,
                                )
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${distanceKm.toStringAsFixed(1)} km away',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w600,
                            color: profileAllowed
                                ? const Color(
                                    0xFF198B35,
                                  )
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ---------------------------------------------------
              // OPEN / LOCK ICON
              // ---------------------------------------------------

              if (isOpening)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                  ),
                )
              else if (profileAllowed)
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 28,
                )
              else
                Container(
                  padding:
                      const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFFF3E0,
                    ),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: Colors.orange,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeSection({
  required String title,
  required IconData icon,
  required List<Map<String, dynamic>> employees,
  required bool loading,
  required bool loadingMore,
  required bool hasMore,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF16803C)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${employees.length}',
              style: const TextStyle(
                color: Color(0xFF16803C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      if (loading && employees.isEmpty)
        const Padding(
          padding: EdgeInsets.all(18),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        )
      else if (employees.isEmpty)
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Text(
            'No matching providers found within 50 km.',
            style: TextStyle(color: Colors.grey),
          ),
        )
      else
        ...employees.map(_employeeCard),
      if (loadingMore)
        const Padding(
          padding: EdgeInsets.all(14),
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      else if (hasMore)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Center(
            child: TextButton(
              onPressed: () {
                if (title == 'Live Self Employed') {
                  _loadLiveEmployees(reset: false);
                } else {
                  _loadRegisteredEmployees(reset: false);
                }
              },
              child: const Text('LOAD MORE'),
            ),
          ),
        ),
    ],
  );
}

  // ===============================================================
  // LOCATION ERROR VIEW
  // ===============================================================

  Widget _locationErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 64,
              color: Colors.grey,
            ),

            const SizedBox(height: 16),

            const Text(
              'Location Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _locationError ??
                  'Unable to get your location.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _retryLocation,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'TRY AGAIN',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF198B35),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildSectionSelector() {
  return Container(
    margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0xFFEEEEEE),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        // LIVE SELF EMPLOYED
        Expanded(
          child: _buildSectionButton(
            title: 'Live Self Employed',
            icon: Icons.my_location,
            isSelected: _showLiveEmployees,
            onTap: () {
              if (_showLiveEmployees) return;

              setState(() {
                _showLiveEmployees = true;
              });

              if (_liveEmployees.isEmpty &&
                  !_isLoadingLive &&
                  _hasMoreLive) {
                _loadLiveEmployees(reset: false);
              }
            },
          ),
        ),

        // LOGGED-IN SELF EMPLOYED
        Expanded(
          child: _buildSectionButton(
            title: 'Logged-in Self Employed',
            icon: Icons.people_outline,
            isSelected: !_showLiveEmployees,
            onTap: () {
              if (!_showLiveEmployees) return;

              setState(() {
                _showLiveEmployees = false;
              });

              if (_registeredEmployees.isEmpty &&
                  !_isLoadingRegistered &&
                  _hasMoreRegistered) {
                _loadRegisteredEmployees(reset: false);
              }
            },
          ),
        ),
      ],
    ),
  );
}

Widget _buildSectionButton({
  required String title,
  required IconData icon,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return Material(
    color: isSelected ? Colors.white : Colors.transparent,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(
          minHeight: 66,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 21,
              color: isSelected
                  ? const Color(0xFF16803C)
                  : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF16803C)
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // ===============================================================
  // TOP INFORMATION BAR
  // ===============================================================

  Widget _radiusInformationBar() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        14,
        10,
        14,
        4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD7EBDD),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_searching,
            color: Color(0xFF198B35),
            size: 21,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              'Showing '
'${_showLiveEmployees ? _liveEmployees.length : _registeredEmployees.length} '
'nearby ${widget.selectedCategory}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Text(
            '${_paidRadiusKm.toStringAsFixed(0)} km paid',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF198B35),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8F7),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            const Color(0xFF198B35),
        foregroundColor: Colors.white,

        title: Text(
          widget.selectedCategory,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading
                ? null
                : _refreshEmployees,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: _isGettingLocation
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 14),
                  Text(
                    'Finding nearby SELF EMPLOYEES...',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )

          : _locationError != null
              ? _locationErrorView()

              : Column(
                  children: [
                  

                    _buildSectionSelector(),
                    _radiusInformationBar(),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshEmployees,
                        child: ListView(
                          controller: _scrollController,
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: [
                            if (_showLiveEmployees)
                              _buildEmployeeSection(
                                title: 'Live Self Employed',
                                icon: Icons.my_location,
                                employees: _liveEmployees,
                                loading: _isLoadingLive,
                                loadingMore: _isLoadingMoreLive,
                                hasMore: _hasMoreLive,
                              )
                            else
                              _buildEmployeeSection(
                                title: 'Logged-in Self Employed',
                                icon: Icons.people_outline,
                                employees: _registeredEmployees,
                                loading: _isLoadingRegistered,
                                loadingMore:
                                    _isLoadingMoreRegistered,
                                hasMore: _hasMoreRegistered,
                              ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
