import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import 'package:jober_india/jober_indiaScreens.dart/workers/worker_profile.dart';
import 'package:latlong2/latlong.dart' as osm;

class ScreenWorkerNearby extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ScreenWorkerNearby({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ScreenWorkerNearby> createState() =>
      _ScreenWorkerNearbyState();
}
enum WorkerSection { live, registered }

class _ScreenWorkerNearbyState extends State<ScreenWorkerNearby> {
  // ============================================================
  // FIRESTORE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // MAP
  // ============================================================

final fm.MapController _mapController = fm.MapController();

bool _mapReady = false;
Timer? _subscriptionExpiryTimer;

  // ============================================================
  // LOCATION
  // ============================================================

  Position? _userPosition;

  bool _locationLoading = true;
  bool _locationPermissionDenied = false;

  // ============================================================
  // DISCOVERY SETTINGS
  // ============================================================
  // This is NOT the user's paid radius.
  //
  // Paid radius will be checked when the user tries to open
  // a worker profile.
  static const double _discoveryRadiusKm = 50.0;

 
  // ============================================================
  // final Map<String, Map<String, dynamic>>
  //     _liveLocations = <String, Map<String, dynamic>>{};
  // ============================================================
// TWO WORKER SECTIONS
// ============================================================


// Current section displayed on screen.
WorkerSection _selectedSection = WorkerSection.live;

// ============================================================
// REGISTERED WORKERS — ALL MATCHING RESULTS
// ============================================================

final List<Map<String, dynamic>> _allRegisteredWorkers = [];

// DocumentSnapshot<Map<String, dynamic>>?
//     _lastWorkerDocument;

bool _hasMoreWorkers = false;
bool _isLoadingWorkers = false;
bool _isLoadingMore = false;
bool _paginationInProgress = false;

// ============================================================
// LIVE WORKERS — ALL MATCHING RESULTS
// ============================================================

final List<Map<String, dynamic>> _allLiveWorkers = [];

// ============================================================
// CURRENTLY DISPLAYED WORKERS
// ============================================================

final List<Map<String, dynamic>> _workers = [];

static const int _workersPerPage = 20;

int _visibleWorkerCount = 0;

// Cache whether each section has already been loaded.
bool _registeredWorkersLoaded = false;
bool _liveWorkersLoaded = false;

// ============================================================
// LIVE LOCATION DATA
// ============================================================

final Map<String, Map<String, dynamic>> _liveLocations = {};

double _paidDistanceKm = 1.0;
  // ============================================================
  // SCROLL CONTROLLER
  // ============================================================

  final ScrollController _scrollController =
      ScrollController();

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadPaidDistance();

    _scrollController.addListener(
      _handlePagination,
    );

    _initializePage();
  }

  // ============================================================
  // PAGE INITIALIZATION
  // ============================================================

  Future<void> _initializePage() async {
    await _getUserLocation();

    if (!mounted) return;

    if (_userPosition == null) {
      setState(() {
        _locationLoading = false;
      });

      return;
    }

    await _loadWorkers(
      reset: true,
    );

    if (!mounted) return;

    setState(() {
      _locationLoading = false;
    });
  }

// ============================================================
// LOAD SHARED HOME-PAGE SUBSCRIPTION
// ============================================================

Future<void> _loadPaidDistance() async {
  double accessDistanceKm = 1.0;
  DateTime? validExpiry;

  try {
    final Box settingsBox = Hive.box('settings');

    final dynamic savedDistance =
        settingsBox.get('activeDistance');

    final dynamic savedExpiry =
        settingsBox.get('subscriptionExpiry');

    final double? distance = _toDouble(savedDistance);

    final DateTime? expiry = savedExpiry == null
        ? null
        : DateTime.tryParse(savedExpiry.toString());

    final bool subscriptionIsValid =
        distance != null &&
        distance >= 1.0 &&
        expiry != null &&
        DateTime.now().isBefore(expiry);

    if (subscriptionIsValid) {
      accessDistanceKm =
          distance.clamp(1.0, 300.0).toDouble();

      validExpiry = expiry;
    }
  } catch (e) {
    debugPrint('Unable to load subscription: $e');
  }

  // Schedule the automatic expiry update.
  _scheduleSubscriptionExpiry(validExpiry);

  if (!mounted) return;

  setState(() {
    _paidDistanceKm = accessDistanceKm;
  });
}

// ============================================================
// AUTOMATIC SUBSCRIPTION EXPIRY
// ============================================================

void _scheduleSubscriptionExpiry(DateTime? expiry) {
  _subscriptionExpiryTimer?.cancel();
  _subscriptionExpiryTimer = null;

  if (expiry == null || !expiry.isAfter(DateTime.now())) {
    return;
  }

  final Duration remaining = expiry.difference(DateTime.now());

  _subscriptionExpiryTimer = Timer(remaining, () async {
    if (!mounted) return;

    // Reload the saved subscription. If it has expired,
    // _loadPaidDistance() will restore the free 1 km access.
    await _loadPaidDistance();

    if (!mounted) return;

    // Rebuild the page so the access display is refreshed.
    setState(() {});
  });
}

  // ============================================================
  // GET USER LOCATION
  // ============================================================

  Future<void> _getUserLocation() async {
    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationPermissionDenied = true;
          });
        }

        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationPermissionDenied = true;
          });
        }

        return;
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
        _locationPermissionDenied = false;
      });

      // Move map to user's position if map is already ready.
      _moveMapToUser();
    } catch (e) {
      debugPrint(
        'Worker nearby location error: $e',
      );
    }
  }

  // ============================================================
  // MOVE MAP TO USER
  // ============================================================

void _moveMapToUser() {
  final position = _userPosition;

  if (!mounted || !_mapReady || position == null) {
    return;
  }

  try {
    _mapController.move(
      osm.LatLng(
        position.latitude,
        position.longitude,
      ),
      11.5,
    );
  } catch (e) {
    debugPrint('OpenStreetMap camera movement failed: $e');
  }
}

// ============================================================
// PAGINATION LISTENER
// ============================================================

void _handlePagination() {
  if (!_scrollController.hasClients ||
      _isLoadingWorkers ||
      _isLoadingMore ||
      _paginationInProgress) {
    return;
  }

  final position = _scrollController.position;

  if (position.pixels >= position.maxScrollExtent - 500) {
    _loadNextPage();
  }
}

// ============================================================
// CURRENT SECTION'S COMPLETE SORTED LIST
// ============================================================

List<Map<String, dynamic>> get _selectedWorkers {
  return _selectedSection == WorkerSection.live
      ? _allLiveWorkers
      : _allRegisteredWorkers;
}

// ============================================================
// LOAD NEXT PAGE
// ============================================================

Future<void> _loadNextPage() async {
  if (_paginationInProgress ||
      _isLoadingWorkers ||
      _visibleWorkerCount >= _selectedWorkers.length) {
    return;
  }

  _paginationInProgress = true;

  if (mounted) {
    setState(() {
      _isLoadingMore = true;
    });
  }

  try {
    await Future<void>.delayed(Duration.zero);

    if (!mounted) return;

    final int nextCount = math.min(
      _visibleWorkerCount + _workersPerPage,
      _selectedWorkers.length,
    );

    setState(() {
      _visibleWorkerCount = nextCount;

      _workers
        ..clear()
        ..addAll(_selectedWorkers.take(nextCount));
    });
  } finally {
    _paginationInProgress = false;

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }
}

// ============================================================
// LOAD WORKERS FOR THE SELECTED SECTION
// ============================================================

Future<void> _loadWorkers({
  required bool reset,
}) async {
  if (_userPosition == null || _isLoadingWorkers) {
    return;
  }

  if (mounted) {
    setState(() {
      _isLoadingWorkers = true;
    });
  }

  try {
    if (reset) {
      _registeredWorkersLoaded = false;
      _liveWorkersLoaded = false;

      _allRegisteredWorkers.clear();
      _allLiveWorkers.clear();
      _liveLocations.clear();
    }

    // Check whether the selected section is already cached.
    final bool alreadyLoaded =
        _selectedSection == WorkerSection.live
            ? _liveWorkersLoaded
            : _registeredWorkersLoaded;

    // Fetch only when this section has not been loaded.
    if (!alreadyLoaded) {
      if (_selectedSection == WorkerSection.live) {
        await _loadLiveWorkers();
      } else {
        await _loadRegisteredWorkers();
      }
    }

    if (!mounted) return;

    // Display the selected section's cached or newly loaded data.
    final List<Map<String, dynamic>> results =
        _selectedWorkers;

    setState(() {
      _visibleWorkerCount = math.min(
        _workersPerPage,
        results.length,
      );

      _workers
        ..clear()
        ..addAll(
          results.take(_visibleWorkerCount),
        );

      _hasMoreWorkers =
          _visibleWorkerCount < results.length;
    });
  } catch (e) {
    debugPrint('Worker loading error: $e');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load workers right now.',
          ),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoadingWorkers = false;
      });
    }
  }
}

// ============================================================
// DISTANCE HELPERS
// ============================================================

double? _distanceFromUser(
  double latitude,
  double longitude,
) {
  final position = _userPosition;

  if (position == null) return null;

  final double meters = Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    latitude,
    longitude,
  );

  if (meters > _discoveryRadiusKm * 1000) {
    return null;
  }

  return meters;
}

// ============================================================
// CATEGORY MATCHING
// ============================================================

// bool _matchesCategory(Iterable<dynamic>? categories) {
//   if (categories == null) return false;

//   final wanted = <String>{
//     widget.categoryId.trim().toLowerCase(),
//     widget.categoryName.trim().toLowerCase(),
//   };

//   return categories.any((value) {
//     final category = value.toString().trim().toLowerCase();
//     return wanted.contains(category);
//   });
// }

// ============================================================
// SORT NEAREST FIRST
// ============================================================

void _sortWorkersNearestFirst(
  List<Map<String, dynamic>> workers,
) {
  workers.sort((a, b) {
    final double distanceA =
        _toDouble(a['distanceMeters']) ?? double.infinity;

    final double distanceB =
        _toDouble(b['distanceMeters']) ?? double.infinity;

    return distanceA.compareTo(distanceB);
  });
}

// ============================================================
// LOAD REGISTERED WORKERS
// ============================================================

Future<void> _loadRegisteredWorkers() async {
  if (_registeredWorkersLoaded) return;

  final position = _userPosition;
  if (position == null) return;

  final bounds = _calculateBoundingBox(
    latitude: position.latitude,
    longitude: position.longitude,
    radiusKm: _discoveryRadiusKm,
  );

  // IMPORTANT:
  // Do not filter isOnline. Registered profiles must remain
  // discoverable when their owners log out.
  //
  // This query uses the category keyword stored at registration.
  final snapshot = await _firestore
      .collection('workers')
      .where(
        'searchKeywords',
        arrayContains: widget.categoryId,
      )
      .where(
        'currentLocationLatitude',
        isGreaterThanOrEqualTo: bounds['minLat'],
      )
      .where(
        'currentLocationLatitude',
        isLessThanOrEqualTo: bounds['maxLat'],
      )
      .get();

  _allRegisteredWorkers.clear();

  for (final document in snapshot.docs) {
    final data = document.data();

    final double? latitude =
        _toDouble(data['currentLocationLatitude']);

    final double? longitude =
        _toDouble(data['currentLocationLongitude']);

    if (latitude == null || longitude == null) continue;

    if (longitude < bounds['minLng']! ||
        longitude > bounds['maxLng']!) {
      continue;
    }

    final double? meters = _distanceFromUser(
      latitude,
      longitude,
    );

    if (meters == null) continue;

    _allRegisteredWorkers.add({
      ...data,
      'uid': data['uid'] ?? document.id,
      'documentId': document.id,
      'latitude': latitude,
      'longitude': longitude,
      'distanceMeters': meters,
      'distanceKm': meters / 1000,
      'categoryId': widget.categoryId,
      'categoryName': widget.categoryName,
      'locationType': 'registered',
    });
  }

  _sortWorkersNearestFirst(_allRegisteredWorkers);

  _registeredWorkersLoaded = true;
}

// ============================================================
// LOAD LIVE WORKERS
// ============================================================

Future<void> _loadLiveWorkers() async {
  if (_liveWorkersLoaded) return;

  final position = _userPosition;
  if (position == null) return;

  final bounds = _calculateBoundingBox(
    latitude: position.latitude,
    longitude: position.longitude,
    radiusKm: _discoveryRadiusKm,
  );

  // final snapshot = await _firestore
  //     .collection('liveLocations')
  //     .where('isLive', isEqualTo: true)
  //     .get();
  // final snapshot = await _firestore
  //   .collection('liveLocations')
  //   .where('isLive', isEqualTo: true)
  //   .where(
  //     'latitude',
  //     isGreaterThanOrEqualTo: bounds['minLat'],
  //   )
  //   .where(
  //     'latitude',
  //     isLessThanOrEqualTo: bounds['maxLat'],
  //   )
  //   .where(
  //     'longitude',
  //     isGreaterThanOrEqualTo: bounds['minLng'],
  //   )
  //   .where(
  //     'longitude',
  //     isLessThanOrEqualTo: bounds['maxLng'],
  //   )
  //   .get();
  final snapshot = await _firestore
    .collection('liveLocations')
    .where('isLive', isEqualTo: true)
    .get();

  _allLiveWorkers.clear();
  _liveLocations.clear();

 // final DateTime now = DateTime.now();
  final Map<String, Map<String, dynamic>> liveByUid = {};

  for (final document in snapshot.docs) {
    final live = document.data();

    final String uid =
        (live['uid'] ?? document.id).toString().trim();

    if (uid.isEmpty) continue;

    // Only worker providers belong in this screen.
    final String role =
        (live['role'] ?? '').toString().trim().toLowerCase();

    final String serviceType =
        (live['serviceType'] ?? '').toString().trim().toLowerCase();

    // if (role != 'worker' && serviceType != 'worker') {
    //   continue;
    // }
    const validWorkerTypes = {
  'worker',
  'workers',
  'worker_provider',
};

if (!validWorkerTypes.contains(role) &&
    !validWorkerTypes.contains(serviceType)) {
  continue;
}

    // Match the selected category.
    // if (!_matchesCategory(
    //   live['categories'] is List
    //       ? List<dynamic>.from(live['categories'] as List)
    //       : null,
    // )) {
    //   continue;
    // }

    // Check that the live record has not expired.
    // final dynamic expiryValue = live['expiresAt'];
    // DateTime? expiry;

    // if (expiryValue is Timestamp) {
    //   expiry = expiryValue.toDate();
    // } else if (expiryValue is DateTime) {
    //   expiry = expiryValue;
    // } else if (expiryValue is String) {
    //   expiry = DateTime.tryParse(expiryValue);
    // }

    // if (expiry == null || !expiry.isAfter(now)) {
    //   continue;
    // }
    final dynamic expiryValue = live['expiresAt'];

DateTime? expiry;

if (expiryValue is Timestamp) {
  expiry = expiryValue.toDate();
} else if (expiryValue is DateTime) {
  expiry = expiryValue;
} else if (expiryValue is String) {
  expiry = DateTime.tryParse(expiryValue);
}

if (expiry == null ||
    !expiry.isAfter(DateTime.now())) {
  continue;
}

    final double? latitude = _toDouble(live['latitude']);
    final double? longitude = _toDouble(live['longitude']);

    if (latitude == null || longitude == null) continue;

    if (latitude < bounds['minLat']! ||
        latitude > bounds['maxLat']! ||
        longitude < bounds['minLng']! ||
        longitude > bounds['maxLng']!) {
      continue;
    }

    final double? meters = _distanceFromUser(
      latitude,
      longitude,
    );

    if (meters == null) continue;

    liveByUid[uid] = {
      ...live,
      'uid': uid,
      'latitude': latitude,
      'longitude': longitude,
      'distanceMeters': meters,
      'distanceKm': meters / 1000,
      'locationType': 'live',
    };
  }

  // Fetch registered profile data in batches.
  // Firestore document reads preserve the existing workers/{uid}
  // structure and do not depend on isOnline.
  final List<String> uids = liveByUid.keys.toList();

  for (int i = 0; i < uids.length; i += 10) {
    final batch = uids.skip(i).take(10).toList();

    final profiles = await Future.wait(
      batch.map(
        (uid) => _firestore.collection('workers').doc(uid).get(),
      ),
    );

    for (final profileSnapshot in profiles) {
      if (!profileSnapshot.exists) continue;

      final String uid = profileSnapshot.id;
      final profile = profileSnapshot.data();

      if (profile == null) continue;

      final live = liveByUid[uid];
      if (live == null) continue;

      // Confirm the saved worker profile belongs to this category.
      final dynamic keywords = profile['searchKeywords'];
      final dynamic categories = profile['categories'];

      final List<dynamic> categoryValues = [
        if (keywords is List) ...keywords,
        if (categories is List) ...categories,
      ];

      final bool categoryMatches = categoryValues.any((value) {
        final String category = value.toString().trim().toLowerCase();

        return category == widget.categoryId.trim().toLowerCase() ||
            category == widget.categoryName.trim().toLowerCase();
      });

      if (!categoryMatches) continue;

      final Map<String, dynamic> worker = {
        ...profile,
        ...live,
        'uid': uid,
        'documentId': uid,
        'latitude': live['latitude'],
        'longitude': live['longitude'],
        'distanceMeters': live['distanceMeters'],
        'distanceKm': live['distanceKm'],
        'categoryId': widget.categoryId,
        'categoryName': widget.categoryName,
        'locationType': 'live',
      };

      _liveLocations[uid] = live;
      _allLiveWorkers.add(worker);
    }
  }

  _sortWorkersNearestFirst(_allLiveWorkers);

  _liveWorkersLoaded = true;
}

  // ============================================================
  // DOUBLE CONVERSION HELPER
  // ============================================================

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // 50 KM BOUNDING BOX
  // ============================================================

  Map<String, double> _calculateBoundingBox({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    const double earthRadiusKm =
        6371.0;

    final double latitudeDelta =
        radiusKm / earthRadiusKm;

    final double longitudeDelta =
        radiusKm /
            (earthRadiusKm *
                math.cos(
                  latitude *
                      math.pi /
                      180.0,
                ));

    return <String, double>{
      'minLat':
          latitude -
              latitudeDelta *
                  180.0 /
                  math.pi,

      'maxLat':
          latitude +
              latitudeDelta *
                  180.0 /
                  math.pi,

      'minLng':
          longitude -
              longitudeDelta *
                  180.0 /
                  math.pi,

      'maxLng':
          longitude +
              longitudeDelta *
                  180.0 /
                  math.pi,
    };
  }

// ============================================================
// CHECK CURRENT LIVE STATUS
// ============================================================

bool _isWorkerActiveToday(
  Map<String, dynamic> worker,
) {
  final String uid =
      (worker['uid'] ?? '').toString().trim();

  if (uid.isEmpty) return false;

  final Map<String, dynamic>? liveData =
      _liveLocations[uid];

  if (liveData == null) return false;
  if (liveData['isLive'] != true) return false;

  final dynamic expiryValue = liveData['expiresAt'];
  DateTime? expiry;

  if (expiryValue is Timestamp) {
    expiry = expiryValue.toDate();
  } else if (expiryValue is DateTime) {
    expiry = expiryValue;
  } else if (expiryValue is String) {
    expiry = DateTime.tryParse(expiryValue);
  }

  return expiry != null && expiry.isAfter(DateTime.now());
}


// ============================================================
// WORKER NAME
// ============================================================

String _getWorkerName(
  Map<String, dynamic> worker,
) {
  final List<String> possibleNames = <String>[
    'name',
    'workerName',
    'username',
    'userName',
    'fullName',
  ];

  for (final String key in possibleNames) {
    final dynamic value =
        worker[key];

    if (value != null &&
        value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }

  return 'Worker';
}

// ============================================================
// FORMAT DISTANCE
// ============================================================

String _formatDistance(
  double meters,
) {
  if (meters < 1000) {
    return '${meters.round()} m away';
  }

  final double km =
      meters / 1000.0;

  if (km < 10) {
    return '${km.toStringAsFixed(1)} km away';
  }

  return '${km.toStringAsFixed(0)} km away';
}

// ============================================================
// SHOW WORKER FROM MAP MARKER
// ============================================================

void _showWorkerFromMarker(
  Map<String, dynamic> worker,
) {
  if (!mounted) {
    return;
  }

  final String workerName =
      _getWorkerName(worker);

  final double distanceMeters =
      _toDouble(
            worker['distanceMeters'],
          ) ??
          0.0;

  final bool activeToday =
      _isWorkerActiveToday(worker);

  showModalBottomSheet(
    context: context,

    backgroundColor:
        Colors.transparent,

    isScrollControlled: false,

    builder: (
      BuildContext sheetContext,
    ) {
      return SafeArea(
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            20,
          ),

          decoration:
              const BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.red.shade50,
                      shape:
                          BoxShape.circle,
                    ),

                    child: Icon(
                      Icons
                          .engineering,
                      color:
                          Colors.red.shade700,
                      size: 26,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Text(
                          workerName,

                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          widget.categoryName,

                          style:
                              TextStyle(
                            color: Colors
                                .grey
                                .shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),

                    decoration:
                        BoxDecoration(
                      color: activeToday
                          ? Colors
                              .green
                              .shade50
                          : Colors
                              .grey
                              .shade100,

                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),

                    child: Text(
                      activeToday
                          ? 'ACTIVE'
                          : 'OFFLINE',

                      style:
                          TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                        color: activeToday
                            ? Colors.green
                                .shade700
                            : Colors.grey
                                .shade600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 15,
              ),

              Row(
                children: [
                  const Icon(
                    Icons
                        .location_on_outlined,
                    size: 19,
                    color: Colors.grey,
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Text(
                    _formatDistance(
                      distanceMeters,
                    ),

                    style:
                        const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              SizedBox(
                width:
                    double.infinity,

                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      sheetContext,
                    );

                    _openWorkerProfile(
                      worker,
                    );
                  },

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.red.shade700,

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    minimumSize:
                        const Size(
                      double.infinity,
                      48,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                  ),

                  child:
                      const Text(
                    'VIEW PROFILE',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
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

// ============================================================
// OPEN WORKER PROFILE
// ============================================================

void _openWorkerProfile(
  Map<String, dynamic> worker,
) {
  final double distanceKm =
      _toDouble(
            worker['distanceKm'],
          ) ??
          double.infinity;

  // ----------------------------------------------------------
  // PAID DISTANCE CHECK
  // ----------------------------------------------------------

  if (distanceKm >
      _paidDistanceKm) {
    _showPaidDistanceMessage(
      worker,
      distanceKm,
    );

    return;
  }

  // ----------------------------------------------------------
  // PROFILE IS INSIDE PAID RADIUS
  // ----------------------------------------------------------

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          ScreenWorkerProfile(
        worker: worker,
        selectedCategoryId:
            widget.categoryId,
        selectedCategoryName:
            widget.categoryName,
      ),
    ),
  );
}

// ============================================================
// PAID DISTANCE MESSAGE
// ============================================================

void _showPaidDistanceMessage(
  Map<String, dynamic> worker,
  double distanceKm,
) {
  final String distanceText =
      distanceKm < 10
          ? '${distanceKm.toStringAsFixed(1)} km'
          : '${distanceKm.toStringAsFixed(0)} km';

  showDialog(
    context: context,

    builder: (
      BuildContext dialogContext,
    ) {
      return AlertDialog(
        title: const Text(
          'Distance Limit',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),

        content: Text(
  'This worker is $distanceText away from you.\n\n'
  'Your current profile access distance is '
  '${_paidDistanceKm.toStringAsFixed(0)} km.\n\n'
  'You can open worker profiles within this distance. '
  'The free access distance is 1 km. '
  'Purchase or renew a subscription from the Home page '
  'to access workers farther away.',
),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
              );
            },

            child: const Text(
              'CLOSE',
            ),
          ),
        ],
      );
    },
  );
}

// ============================================================
// BUILD WORKER CARD
// ============================================================

Widget _buildWorkerCard(
  Map<String, dynamic> worker,
) {
  final String workerName =
      _getWorkerName(worker);

  final double distanceMeters =
      _toDouble(
            worker['distanceMeters'],
          ) ??
          0.0;

  final bool activeToday =
      _isWorkerActiveToday(worker);

  return Material(
    color: Colors.white,

    borderRadius:
        BorderRadius.circular(15),

    child: InkWell(
      borderRadius:
          BorderRadius.circular(15),

      onTap: () {
        _openWorkerProfile(
          worker,
        );
      },

      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),

        padding:
            const EdgeInsets.all(
          14,
        ),

        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            15,
          ),

          border: Border.all(
            color:
                Colors.grey.shade200,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.04),

              blurRadius: 7,

              offset:
                  const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          children: [
            // --------------------------------------------------
            // WORKER ICON
            // --------------------------------------------------

            Container(
              width: 52,
              height: 52,

              decoration:
                  BoxDecoration(
                color:
                    Colors.red.shade50,

                shape:
                    BoxShape.circle,
              ),

              child: Icon(
                Icons.engineering,
                color:
                    Colors.red.shade700,
                size: 28,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            // --------------------------------------------------
            // WORKER INFORMATION
            // --------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    workerName,

                    maxLines: 1,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    widget.categoryName,

                    style:
                        TextStyle(
                      fontSize: 13,
                      color: Colors
                          .grey
                          .shade600,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Row(
                    children: [
                      Icon(
                        Icons
                            .location_on_outlined,
                        size: 16,
                        color: Colors
                            .grey
                            .shade600,
                      ),

                      const SizedBox(
                        width: 3,
                      ),

                      Text(
                        _formatDistance(
                          distanceMeters,
                        ),

                        style:
                            TextStyle(
                          fontSize: 13,
                          color: Colors
                              .grey
                              .shade700,
                          fontWeight:
                              FontWeight
                                  .w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            // --------------------------------------------------
            // ACTIVE STATUS
            // --------------------------------------------------

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .end,

              children: [
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),

                  decoration:
                      BoxDecoration(
                    color: activeToday
                        ? Colors
                            .green
                            .shade50
                        : Colors
                            .grey
                            .shade100,

                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),

                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [
                      Container(
                        width: 7,
                        height: 7,

                        decoration:
                            BoxDecoration(
                          color:
                              activeToday
                                  ? Colors
                                      .green
                                  : Colors
                                      .grey,

                          shape:
                              BoxShape
                                  .circle,
                        ),
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Text(
                        activeToday
                            ? 'ACTIVE TODAY'
                            : 'OFFLINE',

                        style:
                            TextStyle(
                          fontSize: 9,
                          fontWeight:
                              FontWeight
                                  .w700,

                          color:
                              activeToday
                                  ? Colors
                                      .green
                                      .shade700
                                  : Colors
                                      .grey
                                      .shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Icon(
                  Icons
                      .arrow_forward_ios,
                  size: 15,
                  color:
                      Colors.grey.shade500,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================
// MAP WIDGET
// ============================================================
Widget _buildMap() {
  final Position? userPosition = _userPosition;

  final osm.LatLng initialCenter = userPosition != null
      ? osm.LatLng(
          userPosition.latitude,
          userPosition.longitude,
        )
      : const osm.LatLng(10.8505, 76.2711);

  final List<fm.Marker> mapMarkers = <fm.Marker>[];

  // User's current location.
  if (userPosition != null) {
    mapMarkers.add(
      fm.Marker(
        point: osm.LatLng(
          userPosition.latitude,
          userPosition.longitude,
        ),
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
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

  // Show workers according to the selected section.
for (final Map<String, dynamic> worker in _workers) {

  // LIVE section: show only workers active today.
  if (_selectedSection == WorkerSection.live &&
      !_isWorkerActiveToday(worker)) {
    continue;
  }

  // REGISTERED section: show only registered-location workers.
  if (_selectedSection == WorkerSection.registered &&
      worker['locationType'] != 'registered') {
    continue;
  }

  final double? latitude = _toDouble(worker['latitude']);
  final double? longitude = _toDouble(worker['longitude']);

  if (latitude == null || longitude == null) {
    continue;
  }

  // Keep the existing marker design and tap action.
  mapMarkers.add(
    fm.Marker(
      point: osm.LatLng(latitude, longitude),
      width: 44,
      height: 48,
      child: GestureDetector(
        onTap: () => _showWorkerFromMarker(worker),
        // child: const Icon(
        //   Icons.location_on,
        //   color: Color(0xFF16803C),
        //   size: 40,
        // ),
        child: Icon(
  Icons.location_on,
  color: _selectedSection == WorkerSection.live
      ? const Color(0xFF16803C) // Green: live workers
      : Colors.red,             // Red: registered workers
  size: 40,
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
            _mapReady = true;
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
          fm.MarkerLayer(
            markers: mapMarkers,
          ),
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

// ============================================================
// LOCATION BUTTON
// ============================================================

Widget _buildMyLocationButton() {
  return Positioned(
    right: 12,
    bottom: 12,

    child: Material(
      color: Colors.white,

      elevation: 3,

      borderRadius:
          BorderRadius.circular(
        12,
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          12,
        ),

        onTap: () async {
          await _getUserLocation();
           _moveMapToUser();
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

Widget _buildEmptyWorkers() {
  final bool liveSection =
      _selectedSection == WorkerSection.live;

  return Padding(
    padding: const EdgeInsets.symmetric(
      vertical: 35,
      horizontal: 20,
    ),
    child: Column(
      children: [
        Icon(
          liveSection
              ? Icons.location_searching
              : Icons.engineering,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 12),
        Text(
          liveSection
              ? 'No live workers found'
              : 'No registered workers found',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          liveSection
              ? 'No workers currently have a valid LIVE location within 50 km.'
              : 'No registered ${widget.categoryName.toLowerCase()} workers with a saved location were found within 50 km.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    ),
  );
}
// ============================================================
// BUILD
// ============================================================

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,

    // ========================================================
    // APP BAR
    // ========================================================

    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,

      centerTitle: true,

      iconTheme: const IconThemeData(
        color: Colors.black,
      ),

      title: Text(
        widget.categoryName,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),

      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refreshWorkers,
          icon: const Icon(
            Icons.refresh,
            color: Colors.black87,
          ),
        ),
      ],
    ),

    // ========================================================
    // BODY
    // ========================================================

    body: SafeArea(
      child: _buildBody(),
    ),
  );
}

// ============================================================
// SECTION BUTTON
// ============================================================

Widget _buildSectionButton({
  required String title,
  required bool selected,
  required VoidCallback onTap,
}) {
  return Material(
    color: selected ? const Color(0xFF16803C) : Colors.transparent,
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
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    ),
  );
}

// ============================================================
// SWITCH SECTION
// ============================================================

Future<void> _switchWorkerSection(
  WorkerSection section,
) async {
  if (_selectedSection == section || _isLoadingWorkers) {
    return;
  }

  setState(() {
    _selectedSection = section;
    _workers.clear();
    _visibleWorkerCount = 0;
    _hasMoreWorkers = false;
  });

  // Reset the scroll position for the new section.
  if (_scrollController.hasClients) {
    _scrollController.jumpTo(0);
  }

  await _loadWorkers(reset: false);
}
// ============================================================
// MAIN BODY
// ============================================================

Widget _buildBody() {
  // ----------------------------------------------------------
  // LOCATION LOADING
  // ----------------------------------------------------------

  if (_locationLoading) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // ----------------------------------------------------------
  // LOCATION PERMISSION / SERVICE PROBLEM
  // ----------------------------------------------------------

  if (_locationPermissionDenied ||
      _userPosition == null) {
    return _buildLocationUnavailable();
  }

  // ----------------------------------------------------------
  // NORMAL CONTENT
  // ----------------------------------------------------------

  return RefreshIndicator(
    onRefresh: _refreshWorkers,

    child: ListView(

      controller: _scrollController,

      physics:
          const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(
        12,
        4,
        12,
        20,
      ),

      children: [

// ======================================================
// LIVE / REGISTERED SECTION SELECTOR
// ======================================================

Container(
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
    color: const Color(0xFFF2F5F2),
    borderRadius: BorderRadius.circular(14),
  ),
  child: Row(
    children: [
      Expanded(
        child: _buildSectionButton(
          title: 'Live Workers',
          selected: _selectedSection == WorkerSection.live,
          onTap: () => _switchWorkerSection(WorkerSection.live),
        ),
      ),
      Expanded(
        child: _buildSectionButton(
          title: 'Registered Workers',
          selected: _selectedSection == WorkerSection.registered,
          onTap: () => _switchWorkerSection(WorkerSection.registered),
        ),
      ),
    ],
  ),
),

const SizedBox(height: 14),
        // ======================================================
        // MAP
        // ======================================================

        Stack(
          children: [
            _buildMap(),

            _buildMyLocationButton(),
          ],
        ),

        const SizedBox(
          height: 16,
        ),

        // ======================================================
        // DISCOVERY INFORMATION
        // ======================================================

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    //'${widget.categoryName} Workers Near You',
                    _selectedSection == WorkerSection.live
    ? 'Live ${widget.categoryName} Workers Near You'
    : 'Registered ${widget.categoryName} Workers Near You',

                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                   // 'Showing active workers within 50 km',
                   _selectedSection == WorkerSection.live
    ? 'Showing currently LIVE workers within 50 km'
    : 'Showing registered workers within 50 km',

                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // PAID DISTANCE
            // --------------------------------------------------

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 7,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.grey.shade100,

                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),

              child: Column(
                children: [
                  Text(
                    '${_paidDistanceKm.toStringAsFixed(0)} km',

                    style:
                        const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  Text(
                    'Access',

                    style:
                        TextStyle(
                      fontSize: 9,
                      color: Colors
                          .grey
                          .shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 14,
        ),

        // ======================================================
        // WORKER COUNT
        // ======================================================

        if (!_isLoadingWorkers &&
            _workers.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(
              bottom: 10,
            ),

            child: Text(
              '${_workers.length} workers loaded',

              style: TextStyle(
                fontSize: 12,
                color:
                    Colors.grey.shade600,
              ),
            ),
          ),

        // ======================================================
        // INITIAL LOADING
        // ======================================================

        if (_isLoadingWorkers &&
            _workers.isEmpty)
          const Padding(
            padding:
                EdgeInsets.symmetric(
              vertical: 30,
            ),

            child: Center(
              child:
                  CircularProgressIndicator(),
            ),
          ),

        // ======================================================
        // EMPTY RESULT
        // ======================================================

        if (!_isLoadingWorkers &&
            _workers.isEmpty)
          _buildEmptyWorkers(),

        // ======================================================
        // WORKER LIST
        // ======================================================

        if (_workers.isNotEmpty)
          ..._workers.map(
            (
              Map<String, dynamic> worker,
            ) {
              return _buildWorkerCard(
                worker,
              );
            },
          ),

        // ======================================================
        // PAGINATION LOADING
        // ======================================================

        if (_isLoadingMore)
          const Padding(
            padding:
                EdgeInsets.symmetric(
              vertical: 18,
            ),

            child: Center(
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            ),
          ),

        // ======================================================
        // END OF LIST
        // ======================================================

        if (!_isLoadingMore &&
            !_hasMoreWorkers &&
            _workers.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(
              top: 8,
              bottom: 12,
            ),

            child: Center(
              child: Text(
                'You have reached the end of the list.',

                style: TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey.shade600,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

// ============================================================
// LOCATION UNAVAILABLE
// ============================================================

Widget _buildLocationUnavailable() {
  return Center(
    child: Padding(
      padding:
          const EdgeInsets.all(24),

      child: Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Container(
            width: 70,
            height: 70,

            decoration:
                BoxDecoration(
              color:
                  Colors.red.shade50,
              shape:
                  BoxShape.circle,
            ),

            child: Icon(
              Icons.location_off,
              size: 34,
              color:
                  Colors.red.shade700,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'Location Required',
            textAlign:
                TextAlign.center,

            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'Your location is needed to find '
            '${widget.categoryName.toLowerCase()} workers within 50 km of you.',

            textAlign:
                TextAlign.center,

            style: TextStyle(
              fontSize: 14,
              color:
                  Colors.grey.shade600,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          SizedBox(
            width: 180,
            height: 46,

            child:
                ElevatedButton(
              onPressed:
                  _retryLocation,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red.shade700,

                foregroundColor:
                    Colors.white,

                elevation: 0,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child: const Text(
                'TRY AGAIN',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ============================================================
// RETRY LOCATION
// ============================================================

Future<void> _retryLocation() async {
  if (!mounted) {
    return;
  }

  setState(() {
    _locationLoading = true;
    _locationPermissionDenied = false;
  });

  await _getUserLocation();

  if (!mounted) {
    return;
  }

  if (_userPosition != null) {
    await _loadWorkers(
      reset: true,
    );
  }

  if (!mounted) {
    return;
  }

  setState(() {
    _locationLoading = false;
  });
}

// ============================================================
// REFRESH WORKERS
// ============================================================

Future<void> _refreshWorkers() async {
  if (!mounted) {
    return;
  }

  // ----------------------------------------------------------
  // Refresh user's current location.
  // ----------------------------------------------------------

  await _getUserLocation();

  if (!mounted) {
    return;
  }

  if (_userPosition == null) {
    return;
  }

  // ----------------------------------------------------------
  // Reload paid distance.
  // ----------------------------------------------------------

  await _loadPaidDistance();

  if (!mounted) {
    return;
  }

  // ----------------------------------------------------------
  // Reload workers from page 1.
  // ----------------------------------------------------------

  await _loadWorkers(
    reset: true,
  );
}

// ============================================================
// DISPOSE
// ============================================================

@override
void dispose() {
  _subscriptionExpiryTimer?.cancel();
  _scrollController.removeListener(_handlePagination);
  _scrollController.dispose();

  super.dispose();
}
}


  // Only show workers with a valid active live location.
  // for (final Map<String, dynamic> worker in _workers) {
  //   if (!_isWorkerActiveToday(worker)) {
  //     continue;
  //   }

  //   final double? latitude = _toDouble(worker['latitude']);
  //   final double? longitude = _toDouble(worker['longitude']);

  //   if (latitude == null || longitude == null) {
  //     continue;
  //   }

  //   mapMarkers.add(
  //     fm.Marker(
  //       point: osm.LatLng(latitude, longitude),
  //       width: 44,
  //       height: 48,
  //       child: GestureDetector(
  //         onTap: () => _showWorkerFromMarker(worker),
  //         child: const Icon(
  //           Icons.location_on,
  //           color: Color(0xFF16803C),
  //           size: 40,
  //         ),
  //       ),
  //     ),
  //   );
  // }

    // ============================================================
// LOAD LIVE LOCATIONS
// ============================================================

// Future<void> _loadLiveLocations() async {
//   _liveLocations.clear();

//   if (_workers.isEmpty) {
//     return;
//   }

//   try {
//     // ----------------------------------------------------------
//     // Get unique worker UIDs
//     // ----------------------------------------------------------

//     final Set<String> workerIds = <String>{};

//     for (final Map<String, dynamic> worker in _workers) {
//       final String uid =
//           (worker['uid'] ?? '').toString().trim();

//       if (uid.isNotEmpty) {
//         workerIds.add(uid);
//       }
//     }

//     if (workerIds.isEmpty) {
//       return;
//     }

//     // ----------------------------------------------------------
//     // Firestore whereIn supports a limited number of values.
//     // Therefore process IDs in batches.
//     // ----------------------------------------------------------

//     final List<String> ids =
//         workerIds.toList();

//     const int batchSize = 10;

//     for (int i = 0;
//         i < ids.length;
//         i += batchSize) {
//       final int end =
//           math.min(
//         i + batchSize,
//         ids.length,
//       );

//       final List<String> batch =
//           ids.sublist(i, end);

//       final QuerySnapshot<
//           Map<String, dynamic>> snapshot =
//           await _firestore
//               .collection('liveLocations')
//               .where(
//                 FieldPath.documentId,
//                 whereIn: batch,
//               )
//               .get();

//       for (final QueryDocumentSnapshot<
//           Map<String, dynamic>> document
//           in snapshot.docs) {
//         _liveLocations[document.id] =
//             document.data();
//       }
//     }
//   } catch (e) {
//     debugPrint(
//       'Live location loading error: $e',
//     );
//   }
// }

// ============================================================
// CHECK WHETHER WORKER IS ACTIVE TODAY
// ============================================================

// bool _isWorkerActiveToday(
//   Map<String, dynamic> worker,
// ) {
//   final String uid =
//       (worker['uid'] ?? '').toString().trim();

//   if (uid.isEmpty) {
//     return false;
//   }

//   final Map<String, dynamic>? liveData =
//       _liveLocations[uid];

//   if (liveData == null) {
//     return false;
//   }

//   // ----------------------------------------------------------
//   // Worker must have live location enabled.
//   // ----------------------------------------------------------

//   final dynamic isLiveValue =
//       liveData['isLive'];

//   final bool isLive =
//       isLiveValue == true ||
//       isLiveValue.toString().toLowerCase() ==
//           'true';

//   if (!isLive) {
//     return false;
//   }

//   // ----------------------------------------------------------
//   // Check updatedAt.
//   // ----------------------------------------------------------

//   final dynamic updatedAt =
//       liveData['updatedAt'];

//   if (updatedAt == null) {
//     return false;
//   }

//   DateTime? updatedTime;

//   if (updatedAt is Timestamp) {
//     updatedTime =
//         updatedAt.toDate();
//   } else if (updatedAt is DateTime) {
//     updatedTime = updatedAt;
//   } else if (updatedAt is String) {
//     updatedTime =
//         DateTime.tryParse(updatedAt);
//   }

//   if (updatedTime == null) {
//     return false;
//   }

//   // ----------------------------------------------------------
//   // Convert to local time.
//   // ----------------------------------------------------------

//   final DateTime localUpdatedTime =
//       updatedTime.toLocal();

//   final DateTime now =
//       DateTime.now();

//   // ----------------------------------------------------------
//   // Worker must have updated the live location today.
//   // ----------------------------------------------------------

//   final bool isToday =
//       localUpdatedTime.year ==
//           now.year &&
//       localUpdatedTime.month ==
//           now.month &&
//       localUpdatedTime.day ==
//           now.day;

//   if (!isToday) {
//     return false;
//   }

//   return true;
// }

// ============================================================
// EMPTY WORKER VIEW
// ============================================================

// Widget _buildEmptyWorkers() {
//   return Padding(
//     padding:
//         const EdgeInsets.symmetric(
//       vertical: 35,
//       horizontal: 20,
//     ),

//     child: Column(
//       children: [
//         Icon(
//           Icons.location_searching,
//           size: 48,
//           color: Colors.grey.shade400,
//         ),

//         const SizedBox(
//           height: 12,
//         ),

//         const Text(
//           'No active workers found',
//           textAlign: TextAlign.center,

//           style: TextStyle(
//             fontSize: 17,
//             fontWeight:
//                 FontWeight.w600,
//           ),
//         ),

//         const SizedBox(
//           height: 6,
//         ),

//         Text(
//           'There are no active ${widget.categoryName.toLowerCase()} workers within 50 km of your location.',

//           textAlign: TextAlign.center,

//           style: TextStyle(
//             fontSize: 13,
//             color: Colors.grey.shade600,
//           ),
//         ),
//       ],
//     ),
//   );
// }

  //
      // Future<void> _moveMapToUser() async {
//   final controller = _mapController;
//   final position = _userPosition;

//   if (!mounted || controller == null || position == null) {
//     return;
//   }

//   try {
//     await controller.animateCamera(
//       CameraUpdate.newLatLngZoom(
//         LatLng(
//           position.latitude,
//           position.longitude,
//         ),
//         11.5,
//       ),
//     );
//   } catch (e) {
//     debugPrint('Map camera movement failed: $e');
//   }
// }

// void _onMapCreated(GoogleMapController controller) {
//   if (!mounted) {
//     controller.dispose();
//     return;
//   }

//   _mapController = controller;

//   // Camera failures are handled inside _moveMapToUser().
//   _moveMapToUser();
// }
      // Your existing worker system uses searchKeywords.
      //
      // Example:
      // searchKeywords:
      // [
      //   "plumber",
      //   "Plumber"
      // ]
      //
      // We query using the category ID.
      //
      // The exact 50-km distance is calculated locally below.
      // --------------------------------------------------------

      // Query<Map<String, dynamic>> query =
      //     _firestore
      //         .collection('workers')
      //         .where(
      //           'searchKeywords',
      //           arrayContains: widget.categoryId,
      //         )
      //         .where(
      //           'latitude',
      //           isGreaterThanOrEqualTo:
      //               bounds['minLat'],
      //         )
      //         .where(
      //           'latitude',
      //           isLessThanOrEqualTo:
      //               bounds['maxLat'],
      //         )
      //         .orderBy('latitude')
      //         .limit(_workersPerPage);
// ============================================================
// BUILD MAP MARKERS
// ============================================================

// void _buildWorkerMarkers() {
//   // final Set<Marker> newMarkers =
//   //     <Marker>{};

//   // ----------------------------------------------------------
//   // USER MARKER
//   // ----------------------------------------------------------

//   // if (_userPosition != null) {
//   //   newMarkers.add(
//   //     Marker(
//   //       markerId:
//   //           const MarkerId('user_location'),

//   //       position: LatLng(
//   //         _userPosition!.latitude,
//   //         _userPosition!.longitude,
//   //       ),

//   //       infoWindow:
//   //           const InfoWindow(
//   //         title: 'Your Location',
//   //       ),

//   //       icon:
//   //           BitmapDescriptor.defaultMarkerWithHue(
//   //         BitmapDescriptor.hueAzure,
//   //       ),

//   //       zIndexInt: 1000,
//   //     ),
//   //   );
//   // }

//   // ----------------------------------------------------------
//   // WORKER MARKERS
//   // ----------------------------------------------------------

//   for (final Map<String, dynamic> worker
//       in _workers) {
//     final String uid =
//         (worker['uid'] ?? '').toString().trim();

//     if (uid.isEmpty) {
//       continue;
//     }

//     final double? latitude =
//         _toDouble(
//       worker['latitude'],
//     );

//     final double? longitude =
//         _toDouble(
//       worker['longitude'],
//     );

//     if (latitude == null ||
//         longitude == null) {
//       continue;
//     }

//     final bool activeToday =
//         _isWorkerActiveToday(worker);

//     // --------------------------------------------------------
//     // Only show workers who are currently open/active.
//     // --------------------------------------------------------

//     if (!activeToday) {
//       continue;
//     }

//     // final String workerName =
//     //     _getWorkerName(worker);

//     // final double distanceMeters =
//     //     _toDouble(
//     //           worker['distanceMeters'],
//     //         ) ??
//     //         0.0;

//     // newMarkers.add(
//     //   Marker(
//     //     markerId: MarkerId(
//     //       'worker_$uid',
//     //     ),

//     //     position: LatLng(
//     //       latitude,
//     //       longitude,
//     //     ),

//     //     infoWindow: InfoWindow(
//     //       title: workerName,
//     //       snippet:
//     //           '${_formatDistance(distanceMeters)} • Active Today',
//     //     ),

//     //     icon:
//     //         BitmapDescriptor.defaultMarkerWithHue(
//     //       BitmapDescriptor.hueRed,
//     //     ),

//     //     onTap: () {
//     //       _showWorkerFromMarker(worker);
//     //     },
//     //   ),
//     // );
//   }

//   if (!mounted) {
//     return;
//   }

//   // setState(() {
//   //   _markers
//   //     ..clear()
//   //     ..addAll(newMarkers);
//   // });
// }


// Future<void> _loadPaidDistance() async {
//   double accessDistanceKm = 1.0;

//   try {
//     final Box settingsBox = Hive.box('settings');

//     // These are the SAME keys used by the Home page.
//     final dynamic savedDistance =
//         settingsBox.get('activeDistance');

//     final dynamic savedExpiry =
//         settingsBox.get('subscriptionExpiry');

//     final double? distance =
//         _toDouble(savedDistance);

//     final DateTime? expiry =
//         savedExpiry == null
//             ? null
//             : DateTime.tryParse(
//                 savedExpiry.toString(),
//               );

//     // A subscription is valid only when both its distance
//     // and its future expiry time are available.
//     final bool subscriptionIsValid =
//         distance != null &&
//         distance >= 1.0 &&
//         expiry != null &&
//         DateTime.now().isBefore(expiry);

//     if (subscriptionIsValid) {
//       accessDistanceKm = distance
//           .clamp(1.0, 300.0)
//           .toDouble();
//     } else {
//       // No subscription, missing data, or expired subscription:
//       // allow the free 1 km profile-access distance.
//       accessDistanceKm = 1.0;
//     }
//   } catch (e) {
//     debugPrint(
//       'Unable to load subscription distance: $e',
//     );

//     // Safely fall back to free access.
//     accessDistanceKm = 1.0;
//   }

//   if (!mounted) return;

//   setState(() {
//     _paidDistanceKm = accessDistanceKm;
//   });
// }


  // ============================================================
  // PAGINATION LISTENER
  // ============================================================

  // void _handlePagination() {
  //   if (!_scrollController.hasClients) {
  //     return;
  //   }

  //   if (_isLoadingWorkers ||
  //       _isLoadingMore ||
  //       !_hasMoreWorkers ||
  //       _paginationInProgress) {
  //     return;
  //   }

  //   final double currentPosition =
  //       _scrollController.position.pixels;

  //   final double maxPosition =
  //       _scrollController.position.maxScrollExtent;

  //   // Start loading the next page before the user
  //   // reaches the absolute bottom.
  //   if (currentPosition >=
  //       maxPosition - 500) {
  //     _loadNextPage();
  //   }
  // }

  // // ============================================================
  // // LOAD NEXT PAGE
  // // ============================================================

  // Future<void> _loadNextPage() async {
  //   if (_paginationInProgress ||
  //       !_hasMoreWorkers ||
  //       _lastWorkerDocument == null) {
  //     return;
  //   }

  //   _paginationInProgress = true;

  //   if (mounted) {
  //     setState(() {
  //       _isLoadingMore = true;
  //     });
  //   }

  //   try {
  //     await _loadWorkers(
  //       reset: false,
  //     );
  //   } finally {
  //     _paginationInProgress = false;

  //     if (mounted) {
  //       setState(() {
  //         _isLoadingMore = false;
  //       });
  //     }
  //   }
  // }