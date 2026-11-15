import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';


// ===============================================================
// SCREEN NEARBY FREELANCERS
// ===============================================================

class ScreenNearbyFreelancers extends StatefulWidget {
  final String selectedCategory;

  // Coordinates obtained by the homepage.
  final double? userLatitude;
  final double? userLongitude;

  const ScreenNearbyFreelancers({
    super.key,
    required this.selectedCategory,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  State<ScreenNearbyFreelancers> createState() =>
      _ScreenNearbyFreelancersState();
}


class _ScreenNearbyFreelancersState
    extends State<ScreenNearbyFreelancers> {


  // =============================================================
  // COLORS
  // =============================================================

  static const Color darkGreen =
      Color(0xFF12652F);

  static const Color green =
      Color(0xFF138808);

  static const Color orange =
      Color(0xFFED801D);

  static const Color background =
      Color(0xFFF7F8F7);


  // ============================================================
  // FIRESTORE
  // ===========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;


  // =============================================================
  // SCROLL CONTROLLER
  // =============================================================

  final ScrollController _scrollController =
      ScrollController();


 final List<Map<String, dynamic>> _liveFreelancers = [];
  final     List<Map<String, dynamic>> _loggedInFreelancers = [];

DocumentSnapshot<Map<String, dynamic>>? _lastLiveDocument;
DocumentSnapshot<Map<String, dynamic>>? _lastLoggedInDocument;

bool _hasMoreLive = true;
bool _hasMoreLoggedIn = true;

bool _loadingLive = false;
bool _loadingLoggedIn = false;

static const int _freelancerBatchSize = 20;

static const Duration _onlineFreshness = Duration(minutes: 3);

  // =============================================================
  // LOADING STATES
  // =============================================================

  bool _loadingLocation = true;

  bool _loadingFreelancers = false;

  bool _loadingMore = false;

  bool _initialLoadCompleted = false;
Timer? _subscriptionExpiryTimer;

  // =============================================================
  // ERROR MESSAGE
  // =============================================================

  String? _errorMessage;


  // =============================================================
  // SEARCH RADIUS
  //
  // Maximum visible freelancers = 50 KM
  // =============================================================

  static const double maxSearchRadius =
      50.0;

double _paidRadius = 1.0;

bool _hasActiveSubscription = false;

DateTime? _subscriptionExpiry;


  // =============================================================
  // INIT STATE
  // =============================================================

  @override
  void initState() {

    super.initState();

_startSubscriptionExpiryCheck();
    _scrollController.addListener(
      _handleScroll,
    );

    _initializePage();

  }


  // =============================================================
  // INITIALIZE PAGE
  // =============================================================
Future<void> _initializePage() async {
  try {
    await _loadPaidRadius();

    if (!mounted) return;

    // This page does not request GPS or location permission.
    if (widget.userLatitude == null ||
        widget.userLongitude == null ||
        widget.userLatitude! < -90 ||
        widget.userLatitude! > 90 ||
        widget.userLongitude! < -180 ||
        widget.userLongitude! > 180) {
      setState(() {
        _loadingLocation = false;
        _loadingFreelancers = false;
        _errorMessage =
            'The homepage location is unavailable. '
            'Please return to the homepage and try again.';
      });
      return;
    }

    setState(() {
      _loadingLocation = false;
    });

    await _loadFirstFreelancers();
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _loadingLocation = false;
      _loadingFreelancers = false;
      _errorMessage = _cleanErrorMessage(e);
    });
  }
}

double? _readCoordinate(
  Map<String, dynamic> data,
  List<String> keys,
) {
  double? toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  // 1. Coordinates saved at the top level.
  for (final key in keys) {
    final value = toDouble(data[key]);
    if (value != null) return value;
  }

  // 2. Coordinates saved inside nested location maps.
  for (final field in ['currentLocation', 'location']) {
    final nested = data[field];

    if (nested is Map) {
      for (final key in keys) {
        final value = toDouble(nested[key]);
        if (value != null) return value;
      }
    }

    // 3. Support Firestore GeoPoint stored in "location".
    if (nested is GeoPoint) {
      for (final key in keys) {
        if (key == 'latitude' || key == 'lat') {
          return nested.latitude;
        }

        if (key == 'longitude' || key == 'lng' || key == 'lon') {
          return nested.longitude;
        }
      }
    }
  }

  return null;
}

Future<void> _fetchUntilResultsOrEnd({
  required int maxBatches,
}) async {
  for (int i = 0; i < maxBatches; i++) {
    final beforeCount =
        _liveFreelancers.length + _loggedInFreelancers.length;

    final canFetchLive = _hasMoreLive && !_loadingLive;
    final canFetchLoggedIn =
        _hasMoreLoggedIn && !_loadingLoggedIn;

    if (!canFetchLive && !canFetchLoggedIn) {
      break;
    }

    if (canFetchLive) {
      await _fetchLiveFreelancerBatch();
    }

    if (canFetchLoggedIn) {
      await _fetchLoggedInFreelancerBatch();
    }

    final afterCount =
        _liveFreelancers.length + _loggedInFreelancers.length;

    // Stop once at least one eligible result has been added.
    if (afterCount > beforeCount) {
      break;
    }

    // Both queries have reached the end.
    if (!_hasMoreLive && !_hasMoreLoggedIn) {
      break;
    }
  }
}

DateTime? _readDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;

  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  return null;
}

bool _validCoordinates(double? latitude, double? longitude) {
  return latitude != null &&
      longitude != null &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

bool _isRecentlyOnline(Map<String, dynamic> profile) {
  if (profile['isOnline'] != true) return false;

  final updatedAt = _readDateTime(profile['onlineUpdatedAt']);

  if (updatedAt == null) return false;

  final age = DateTime.now().difference(updatedAt);

  return age >= Duration.zero && age <= _onlineFreshness;
}

bool _isValidLiveLocation(Map<String, dynamic> data) {
  if (data['isLive'] != true) return false;

  final expiresAt = _readDateTime(data['expiresAt']);

  if (expiresAt == null || !expiresAt.isAfter(DateTime.now())) {
    return false;
  }

  final latitude = _readCoordinate(
    data,
    ['lat', 'latitude'],
  );

  final longitude = _readCoordinate(
    data,
    ['lng', 'longitude', 'long'],
  );

  return _validCoordinates(latitude, longitude);
}

double? _distanceTo(double latitude, double longitude) {
  if (widget.userLatitude == null ||
      widget.userLongitude == null) {
    return null;
  }

  final meters = Geolocator.distanceBetween(
    widget.userLatitude!,
    widget.userLongitude!,
    latitude,
    longitude,
  );

  return meters / 1000;
}

bool _containsFreelancer(
  List<Map<String, dynamic>> list,
  String uid,
) {
  return list.any((item) => item['uid'] == uid);
}

Future<void> _fetchLiveFreelancerBatch() async {
  if (_loadingLive ||
      !_hasMoreLive ||
      !mounted ||
      widget.userLatitude == null ||
      widget.userLongitude == null) {
    return;
  }

  _loadingLive = true;

  try {
    Query<Map<String, dynamic>> query = _firestore
        .collection('liveLocations')
        .where('isLive', isEqualTo: true)
        .where(
          'categories',
          arrayContains: widget.selectedCategory,
        )
        .orderBy('updatedAt', descending: true)
        .limit(_freelancerBatchSize);

    if (_lastLiveDocument != null) {
      query = query.startAfterDocument(_lastLiveDocument!);
    }

    final snapshot = await query.get().timeout(
      const Duration(seconds: 20),
    );

    if (!mounted) return;

    if (snapshot.docs.isEmpty) {
      setState(() => _hasMoreLive = false);
      return;
    }

    _lastLiveDocument = snapshot.docs.last;

    if (snapshot.docs.length < _freelancerBatchSize) {
      _hasMoreLive = false;
    }

    final candidates = await Future.wait(
      snapshot.docs.map((liveDoc) async {
        final liveData = liveDoc.data();

        if (!_isValidLiveLocation(liveData)) return null;

        final uid = (liveData['uid'] ?? liveDoc.id).toString();

        if (uid.isEmpty) return null;

        final profileDoc = await _firestore
            .collection('freelancers')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 10));

        if (!profileDoc.exists) return null;

        final profile = profileDoc.data();

        if (profile == null ||
            profile['isActive'] != true ||
            !_isRecentlyOnline(profile)) {
          return null;
        }

        final profileCategories = profile['categories'];

        if (profileCategories is! List ||
            !profileCategories.contains(widget.selectedCategory)) {
          return null;
        }

        final latitude = _readCoordinate(
          liveData,
          ['lat', 'latitude'],
        );

        final longitude = _readCoordinate(
          liveData,
          ['lng', 'longitude', 'long'],
        );

        if (!_validCoordinates(latitude, longitude)) return null;

        final distanceKm = _distanceTo(latitude!, longitude!);

        if (distanceKm == null || distanceKm > maxSearchRadius) {
          return null;
        }

        return <String, dynamic>{
          ...profile,
          'uid': uid,
          'documentId': uid,
          'latitude': latitude,
          'longitude': longitude,
          'distanceKm': distanceKm,
          'isLive': true,
        };
      }),
    );

    if (!mounted) return;

    setState(() {
      for (final candidate in candidates) {
        if (candidate == null) continue;

        final uid = candidate['uid'] as String;

        if (!_containsFreelancer(_liveFreelancers, uid)) {
          _liveFreelancers.add(candidate);
        }
      }

      _liveFreelancers.sort(
        (a, b) => (a['distanceKm'] as double)
            .compareTo(b['distanceKm'] as double),
      );
    });
  } catch (e) {
    debugPrint('Live freelancer batch failed: $e');
    rethrow;
  } finally {
    _loadingLive = false;
  }
}

Future<void> _fetchLoggedInFreelancerBatch() async {
  if (_loadingLoggedIn ||
      !_hasMoreLoggedIn ||
      !mounted ||
      widget.userLatitude == null ||
      widget.userLongitude == null) {
    return;
  }

  _loadingLoggedIn = true;

  try {
    Query<Map<String, dynamic>> query = _firestore
        .collection('freelancers')
        .where(
          'categories',
          arrayContains: widget.selectedCategory,
        )
        .where('isOnline', isEqualTo: true)
        .orderBy('onlineUpdatedAt', descending: true)
        .limit(_freelancerBatchSize);

    if (_lastLoggedInDocument != null) {
      query = query.startAfterDocument(_lastLoggedInDocument!);
    }

    final snapshot = await query.get().timeout(
      const Duration(seconds: 20),
    );

    if (!mounted) return;

    if (snapshot.docs.isEmpty) {
      setState(() => _hasMoreLoggedIn = false);
      return;
    }

    _lastLoggedInDocument = snapshot.docs.last;

    if (snapshot.docs.length < _freelancerBatchSize) {
      _hasMoreLoggedIn = false;
    }

    final candidates = await Future.wait(
      snapshot.docs.map((profileDoc) async {
        final profile = profileDoc.data();
        final uid = profileDoc.id;

        if (profile['isActive'] != true ||
            !_isRecentlyOnline(profile)) {
          return null;
        }

        // Check whether this freelancer has a valid live location.
        final liveDoc = await _firestore
            .collection('liveLocations')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 10));

        if (liveDoc.exists) {
          final liveData = liveDoc.data();

          if (liveData != null &&
              _isValidLiveLocation(liveData)) {
            // Live freelancers belong in the Live section only.
            return null;
          }
        }

        final latitude = _readCoordinate(
          profile,
          ['latitude', 'lat'],
        );

        final longitude = _readCoordinate(
          profile,
          ['longitude', 'lng', 'long'],
        );

        if (!_validCoordinates(latitude, longitude)) return null;

        final distanceKm = _distanceTo(latitude!, longitude!);

        if (distanceKm == null || distanceKm > maxSearchRadius) {
          return null;
        }

        return <String, dynamic>{
          ...profile,
          'uid': uid,
          'documentId': uid,
          'latitude': latitude,
          'longitude': longitude,
          'distanceKm': distanceKm,
          'isLive': false,
        };
      }),
    );

    if (!mounted) return;

    setState(() {
      for (final candidate in candidates) {
        if (candidate == null) continue;

        final uid = candidate['uid'] as String;

        // Final duplicate guard against the Live section.
        if (_containsFreelancer(_liveFreelancers, uid)) continue;

        if (!_containsFreelancer(_loggedInFreelancers, uid)) {
          _loggedInFreelancers.add(candidate);
        }
      }

      _loggedInFreelancers.sort(
        (a, b) => (a['distanceKm'] as double)
            .compareTo(b['distanceKm'] as double),
      );
    });
  } catch (e) {
    debugPrint('Logged-in freelancer batch failed: $e');
    rethrow;
  } finally {
    _loadingLoggedIn = false;
  }
}



void _startSubscriptionExpiryCheck() {
  _subscriptionExpiryTimer?.cancel();

  _subscriptionExpiryTimer = Timer.periodic(
    const Duration(seconds: 30),
    (_) async {
      if (!mounted) return;

      await _loadPaidRadius();

      if (!mounted) return;

      // Refresh the lock icons and displayed access status.
      setState(() {});
    },
  );
}
 // =============================================================
// LOAD SUBSCRIPTION FROM HIVE
//
// Canonical keys used by activateSubscription():
// activeDistance
// subscriptionExpiry
// subscriptionActive
// =============================================================
Future<void> _loadPaidRadius() async {
  final box = Hive.box('settings');

  try {
    final dynamic savedDistance = box.get('activeDistance');
    final dynamic savedExpiry = box.get('subscriptionExpiry');
    final dynamic savedActive = box.get('subscriptionActive');

    DateTime? expiry;

    if (savedExpiry != null) {
      expiry = DateTime.tryParse(savedExpiry.toString());
    }

    double? distance;

    if (savedDistance is num) {
      distance = savedDistance.toDouble();
    } else if (savedDistance is String) {
      distance = double.tryParse(savedDistance);
    }

    final bool validSubscription =
        savedActive == true &&
        distance != null &&
        distance > 1 &&
        distance <= 50 &&
        expiry != null &&
        expiry.isAfter(DateTime.now());

    if (!validSubscription) {
      // Expired or invalid subscriptions must not grant paid access.
      if (expiry != null &&
          !expiry.isAfter(DateTime.now())) {
        await box.delete('activeDistance');
        await box.delete('subscriptionStart');
        await box.delete('subscriptionExpiry');
        await box.delete('subscriptionDuration');
        await box.delete('subscriptionPaidAmount');
        await box.delete('subscriptionActive');
      }

      if (!mounted) return;

      setState(() {
        _hasActiveSubscription = false;
        _paidRadius = 1.0;
        _subscriptionExpiry = null;
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      _hasActiveSubscription = true;
      _paidRadius = distance!;
      _subscriptionExpiry = expiry;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _hasActiveSubscription = false;
      _paidRadius = 1.0;
      _subscriptionExpiry = null;
    });
  }
}

  // =============================================================
  // SCROLL PAGINATION
  // =============================================================

  void _handleScroll() {

    if (!_scrollController.hasClients) {
      return;
    }


    final position =
        _scrollController.position;


    if (position.pixels >=
        position.maxScrollExtent - 300) {

      _loadMoreFreelancers();

    }

  }
  // =============================================================
  // LOAD FIRST FREELANCERS
  // ================================================

Future<void> _loadFirstFreelancers() async {
  if (!mounted) return;

  setState(() {
    _loadingFreelancers = true;
    _loadingMore = false;
    _initialLoadCompleted = false;
    _errorMessage = null;

    _liveFreelancers.clear();
    _loggedInFreelancers.clear();

    _lastLiveDocument = null;
    _lastLoggedInDocument = null;

    _hasMoreLive = true;
    _hasMoreLoggedIn = true;
  });

  try {
    // Load batches until results are found or the sources end.
    await _fetchUntilResultsOrEnd(maxBatches: 5);

    if (!mounted) return;

    setState(() {
      _initialLoadCompleted = true;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _errorMessage = _cleanErrorMessage(e);
    });
  } finally {
    if (mounted) {
      setState(() {
        _loadingFreelancers = false;
        _loadingMore = false;
      });
    }
  }
}

Future<void> _loadMoreFreelancers() async {
  if (!mounted ||
      _loadingFreelancers ||
      _loadingMore ||
      (!_hasMoreLive && !_hasMoreLoggedIn)) {
    return;
  }

  setState(() => _loadingMore = true);

  try {
    // Continue fetching if a batch has no eligible results.
    await _fetchUntilResultsOrEnd(maxBatches: 5);
  } catch (e) {
    debugPrint('Loading more freelancers failed: $e');
  } finally {
    if (mounted) {
      setState(() => _loadingMore = false);
    }
  }
}

  // =============================================================
  // RETRY
  // =============================================================

Future<void> _retry() async {
  if (!mounted) return;

  setState(() {
    _errorMessage = null;
    _loadingLocation = false;
    _loadingFreelancers = true;
    _loadingMore = false;
    _initialLoadCompleted = false;
  });

  await _loadPaidRadius();

  if (!mounted) return;

  await _loadFirstFreelancers();
}

Widget _buildFreelancerSections() {
  final hasLive = _liveFreelancers.isNotEmpty;
  final hasLoggedIn = _loggedInFreelancers.isNotEmpty;

  return ListView(
    controller: _scrollController,
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.only(bottom: 24),
    children: [
      if (hasLive) ...[
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.circle, color: Colors.green, size: 10),
              SizedBox(width: 8),
              Text(
                'Live Freelancers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        for (final freelancer in _liveFreelancers)
          _buildFreelancerCard(freelancer),
      ],

      if (hasLoggedIn) ...[
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            'Logged-in Freelancers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (final freelancer in _loggedInFreelancers)
          _buildFreelancerCard(freelancer),
      ],

      if (!hasLive && !hasLoggedIn && !_loadingFreelancers)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No eligible freelancers found within 50 km.',
              textAlign: TextAlign.center,
            ),
          ),
        ),

      if (_loadingMore)
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),

      if (!_hasMoreLive && !_hasMoreLoggedIn &&
          (hasLive || hasLoggedIn))
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('You have reached the end of the list.'),
          ),
        ),
    ],
  );
}


  // =============================================================
  // FETCH FREELANCER BATCH
  //
  // Firestore:
  //
  // categories arrayContains selectedCategory
  // isActive == true
  //
  // Pagination prevents loading all users at once.
  // =============================================================

Future<void> _openFreelancer(
  Map<String, dynamic> freelancer,
) async {
  // Re-read the saved subscription so an expired subscription
  // cannot continue granting paid profile access.
  await _loadPaidRadius();

  if (!mounted) return;

  final double distance =
      (freelancer['distanceKm'] as num?)?.toDouble()
          ?? double.infinity;

  if (distance <= 1.0) {
    _openFreelancerProfile(freelancer);
    return;
  }

  if (_hasActiveSubscription &&
      _subscriptionExpiry != null &&
      _subscriptionExpiry!.isAfter(DateTime.now()) &&
      distance <= _paidRadius) {
    _openFreelancerProfile(freelancer);
    return;
  }

  _showDistancePaywall(freelancer);
}

  // =============================================================
  // OPEN FREELANCER PROFILE
  //
  // This uses a named route so this page does not depend on the
  // profile file being created yet.
  //
  // Later register this route in main.dart:
  //
  // '/freelancerProfile'
  // =============================================================

  void _openFreelancerProfile(
      Map<String, dynamic> freelancer) {

    Navigator.pushNamed(

      context,

      '/freelancerProfile',

      arguments: {

        ...freelancer,

        'selectedCategory':
            widget.selectedCategory,

      },

    );

  }


  // =============================================================
  // DISTANCE PAYWALL
  // =============================================================

  void _showDistancePaywall(
      Map<String, dynamic> freelancer) {

    final distance =
        (freelancer['distanceKm'] as num?)
                ?.toDouble() ??
            0.0;


    final extraDistance =
        max(
      0,
      distance - _paidRadius,
    );


    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor:
          Colors.transparent,

      builder:
          (context) {

        return SafeArea(

          child:
              Container(

            padding:
                const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              28,
            ),

            decoration:
                const BoxDecoration(

              color:
                  Colors.white,

              borderRadius:
                  BorderRadius.vertical(

                top:
                    Radius.circular(28),

              ),

            ),

            child:
                Column(

              mainAxisSize:
                  MainAxisSize.min,

              children: [


                // =============================================
                // ICON
                // =============================================

                Container(

                  width:
                      70,

                  height:
                      70,

                  decoration:
                      const BoxDecoration(

                    color:
                        Color(0xFFFFF3E5),

                    shape:
                        BoxShape.circle,

                  ),

                  child:
                      const Icon(

                    Icons.lock_outline,

                    size:
                        34,

                    color:
                        orange,

                  ),

                ),


                const SizedBox(
                  height:
                      18,
                ),


                const Text(

                  'Increase Your Search Radius',

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(

                    fontSize:
                        21,

                    fontWeight:
                        FontWeight.bold,

                    color:
                        darkGreen,

                  ),

                ),


                const SizedBox(
                  height:
                      12,
                ),


                Text(

                  '${freelancer['name'] ?? 'This freelancer'} is ${distance.toStringAsFixed(1)} KM away.',

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(

                    fontSize:
                        16,

                  ),

                ),


                const SizedBox(
                  height:
                      8,
                ),


                Text(

                  'Your current paid radius is ${_paidRadius.toStringAsFixed(0)} KM.',

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(

                    color:
                        Colors.grey.shade600,

                    fontSize:
                        15,

                  ),

                ),


                const SizedBox(
                  height:
                      20,
                ),


                Container(

                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  decoration:
                      BoxDecoration(

                    color:
                        const Color(
                      0xFFFFF8F0,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                  ),

                  child:
                      Column(

                    children: [

                      Text(

                        'You need approximately ${extraDistance.toStringAsFixed(1)} KM more access to open this profile.',

                        textAlign:
                            TextAlign.center,

                        style:
                            const TextStyle(

                          fontWeight:
                              FontWeight.w600,

                        ),

                      ),

                      const SizedBox(
                        height:
                            5,
                      ),

                      Text(

                        'Increase your paid distance to continue.',

                        textAlign:
                            TextAlign.center,

                        style:
                            TextStyle(

                          color:
                              Colors.grey.shade600,

                        ),

                      ),

                    ],

                  ),

                ),


                const SizedBox(
                  height:
                      24,
                ),


                // =============================================
                // INCREASE RADIUS BUTTON
                // =============================================

                SizedBox(

                  width:
                      double.infinity,

                  height:
                      54,

                  child:
                      ElevatedButton(

                    style:
                        ElevatedButton.styleFrom(

                      backgroundColor:
                          green,

                      foregroundColor:
                          Colors.white,

                      elevation:
                          0,

                      shape:
                          RoundedRectangleBorder(

                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),

                      ),

                    ),

                    onPressed:
                        () {

                      Navigator.pop(
                        context,
                      );


                      _showIncreaseRadiusDialog(
                        requiredDistance:
                            distance,
                      );

                    },


                    child:
                        const Text(

                      'INCREASE KM RADIUS',

                      style:
                          TextStyle(

                        fontSize:
                            16,

                        fontWeight:
                            FontWeight.bold,

                      ),

                    ),

                  ),

                ),


                const SizedBox(
                  height:
                      10,
                ),


                TextButton(

                  onPressed:
                      () {

                    Navigator.pop(
                      context,
                    );

                  },

                  child:
                      const Text(
                    'NOT NOW',
                  ),

                ),

              ],

            ),

          ),

        );

      },

    );

  }

  String _formatDistance(double distanceKm) {
  final int distanceMeters = (distanceKm * 1000).round();

  if (distanceMeters < 1000) {
    return '$distanceMeters m';
  }

  return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
}
  // =============================================================
  // INCREASE RADIUS DIALOG
  //
  // This is ready to connect to your payment system later.
  // =============================================================

  void _showIncreaseRadiusDialog({
    required double requiredDistance,
  }) {

    double selectedRadius =
        requiredDistance.ceilToDouble();


    if (selectedRadius <
        _paidRadius) {

      selectedRadius =
          _paidRadius;

    }


    if (selectedRadius >
        maxSearchRadius) {

      selectedRadius =
          maxSearchRadius;

    }


    showModalBottomSheet(

      context: context,

      backgroundColor:
          Colors.white,

      isScrollControlled: true,

      shape:
          const RoundedRectangleBorder(

        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(28),
        ),

      ),

      builder:
          (bottomSheetContext) {

        return StatefulBuilder(

          builder:
              (
                context,
                setModalState,
              ) {

            return SafeArea(

              child:
                  Padding(

                padding:
                    const EdgeInsets.all(
                  24,
                ),

                child:
                    Column(

                  mainAxisSize:
                      MainAxisSize.min,

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [


                    const Text(

                      'Choose Search Radius',

                      style:
                          TextStyle(

                        fontSize:
                            22,

                        fontWeight:
                            FontWeight.bold,

                        color:
                            darkGreen,

                      ),

                    ),


                    const SizedBox(
                      height:
                          8,
                    ),


                    Text(

                      'Increase your distance to access freelancers farther away.',

                      style:
                          TextStyle(

                        color:
                            Colors.grey.shade600,

                      ),

                    ),


                    const SizedBox(
                      height:
                          25,
                    ),


                    Center(

                      child:
                          Text(

                        '${selectedRadius.toStringAsFixed(0)} KM',

                        style:
                            const TextStyle(

                          fontSize:
                              34,

                          fontWeight:
                              FontWeight.bold,

                          color:
                              green,

                        ),

                      ),

                    ),


                    Slider(

                      value:
                          selectedRadius,

                      min:
                          _paidRadius,

                      max:
                          maxSearchRadius,

                      divisions:
                          (maxSearchRadius -
                                  _paidRadius)
                              .round()
                              .clamp(
                                1,
                                49,
                              ),

                      activeColor:
                          green,

                      label:
                          '${selectedRadius.toStringAsFixed(0)} KM',

                      onChanged:
                          (
                            value,
                          ) {

                        setModalState(() {

                          selectedRadius =
                              value;

                        });

                      },

                    ),

                    const SizedBox(
                      height:
                          18,
                    ),


                    SizedBox(

                      width:
                          double.infinity,

                      height:
                          55,

                      child:
                          ElevatedButton(

                        style:
                            ElevatedButton.styleFrom(

                          backgroundColor:
                              green,

                          foregroundColor:
                              Colors.white,

                          elevation:
                              0,

                          shape:
                              RoundedRectangleBorder(

                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),

                          ),

                        ),

                        onPressed: () {
  Navigator.pop(bottomSheetContext);

  _showMessage(
    'Payment is not connected yet. '
    'Your current access remains unchanged.',
  );
},


                        child:
                            const Text(

                          'CONTINUE TO PAYMENT',

                          style:
                              TextStyle(

                            fontSize:
                                16,

                            fontWeight:
                                FontWeight.bold,

                          ),

                        ),

                      ),

                    ),


                    const SizedBox(
                      height:
                          10,
                    ),

                  ],

                ),

              ),

            );

          },

        );

      },

    );

  }

  // =============================================================
  // SHOW MESSAGE
  // =============================================================

  void _showMessage(
      String message) {

    if (!mounted) return;


    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();


    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content:
            Text(message),

        behavior:
            SnackBarBehavior.floating,

      ),

    );

  }


  // =============================================================
  // CLEAN ERROR MESSAGE
  // =============================================================

  String _cleanErrorMessage(
      dynamic error) {

    String message =
        error.toString();


    message =
        message.replaceFirst(
      'Exception: ',
      '',
    );


    if (message.contains(
      'TimeoutException',
    )) {

      return 'Connection is taking too long. Please try again.';

    }


    return message;

  }


  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {

    _scrollController.removeListener(
      _handleScroll,
    );
_subscriptionExpiryTimer?.cancel();
    _scrollController.dispose();

    super.dispose();

  }


  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      backgroundColor:
          background,


      // =========================================================
      // APP BAR
      // =========================================================

      appBar:
          AppBar(

        elevation:
            0,

        backgroundColor:
            Colors.white,

        foregroundColor:
            darkGreen,


        title:
            Column(

          children: [

            Text(

              widget.selectedCategory,

              style:
                  const TextStyle(

                fontWeight:
                    FontWeight.bold,

                color:
                    darkGreen,

              ),

            ),

            const Text(

              'Nearby Freelancers',

              style:
                  TextStyle(

                fontSize:
                    11,

                fontWeight:
                    FontWeight.normal,

              ),

            ),

          ],

        ),

      ),


      // =========================================================
      // BODY
      // =========================================================

      body:
          SafeArea(

        child:
            _buildBody(),

      ),

    );

  }


  // =============================================================
  // BUILD BODY
  // =============================================================

  Widget _buildBody() {


    // -----------------------------------------------------------
    // LOCATION LOADING
    // -----------------------------------------------------------

    if (_loadingLocation) {

      return const Center(

        child:
            Column(

          mainAxisSize:
              MainAxisSize.min,

          children: [

            CircularProgressIndicator(
              color:
                  green,
            ),

            SizedBox(
              height:
                  18,
            ),

            Text(
              'Loading nearby Freelancers...',
            ),

          ],

        ),

      );

    }


    // -----------------------------------------------------------
    // ERROR
    // -----------------------------------------------------------

    if (_errorMessage != null) {

      return Center(

        child:
            Padding(

          padding:
              const EdgeInsets.all(
            25,
          ),

          child:
              Column(

            mainAxisSize:
                MainAxisSize.min,

            children: [

              const Icon(

                Icons.location_off_outlined,

                size:
                    65,

                color:
                    orange,

              ),

              const SizedBox(
                height:
                    18,
              ),

              const Text(

                'Unable to Find Location',

                style:
                    TextStyle(

                  fontSize:
                      20,

                  fontWeight:
                      FontWeight.bold,

                  color:
                      darkGreen,

                ),

              ),

              const SizedBox(
                height:
                    10,
              ),

              Text(

                _errorMessage!,

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(

                  color:
                      Colors.grey.shade600,

                ),

              ),

              const SizedBox(
                height:
                    22,
              ),

              ElevatedButton(

                onPressed:
                    _retry,

                style:
                    ElevatedButton.styleFrom(

                  backgroundColor:
                      green,

                  foregroundColor:
                      Colors.white,

                ),

                child:
                    const Text(
                  'TRY AGAIN',
                ),

              ),

            ],

          ),

        ),

      );

    }


    // -----------------------------------------------------------
    // FIRST FIRESTORE LOADING
    // -----------------------------------------------------------

    if (_loadingFreelancers &&
        !_initialLoadCompleted) {

      return const Center(

        child:
            CircularProgressIndicator(
          color:
              green,
        ),

      );

    }


    return Column(

      children: [


        // =======================================================
        // INFORMATION HEADER
        // =======================================================

        Container(

          width:
              double.infinity,

          margin:
              const EdgeInsets.fromLTRB(
            16,
            15,
            16,
            8,
          ),

          padding:
              const EdgeInsets.all(
            16,
          ),

          decoration:
              BoxDecoration(

            color:
                Colors.white,

            borderRadius:
                BorderRadius.circular(
              18,
            ),

            border:
                Border.all(
              color:
                  const Color(
                0xFFE2E8E3,
              ),
            ),

          ),

          child:
              Row(

            children: [

              Container(

                width:
                    45,

                height:
                    45,

                decoration:
                    const BoxDecoration(

                  color:
                      Color(0xFFE7F4EA),

                  shape:
                      BoxShape.circle,

                ),

                child:
                    const Icon(

                  Icons.location_on_outlined,

                  color:
                      green,

                ),

              ),

              const SizedBox(
                width:
                    12,
              ),

              Expanded(

                child:
                    Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(

                      'Search radius: ${maxSearchRadius.toStringAsFixed(0)} KM',

                      style:
                          const TextStyle(

                        fontWeight:
                            FontWeight.bold,

                        color:
                            darkGreen,

                      ),

                    ),

                    const SizedBox(
                      height:
                          4,
                    ),

                    Text(

_hasActiveSubscription
    ? 'Unlocked radius: ${_paidRadius.toStringAsFixed(0)} KM'
    : 'Free access: 1 KM',
                      style:
                          TextStyle(

                        color:
                            Colors.grey.shade600,

                        fontSize:
                            13,

                      ),

                    ),

                  ],

                ),

              ),

              const Icon(

                Icons.lock_outline,

                color:
                    orange,

              ),

            ],

          ),

        ),


        if (_liveFreelancers.isEmpty &&
    _loggedInFreelancers.isEmpty &&
    !_loadingFreelancers)

          Expanded(

            child:
                Center(

              child:
                  Padding(

                padding:
                    const EdgeInsets.all(
                  30,
                ),

                child:
                    Column(

                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    const Icon(

                      Icons.person_search_outlined,

                      size:
                          70,

                      color:
                          green,

                    ),

                    const SizedBox(
                      height:
                          18,
                    ),

                    Text(

                      'No ${widget.selectedCategory} found nearby',

                      textAlign:
                          TextAlign.center,

                      style:
                          const TextStyle(

                        fontSize:
                            19,

                        fontWeight:
                            FontWeight.bold,

                        color:
                            darkGreen,

                      ),

                    ),

                    const SizedBox(
                      height:
                          8,
                    ),

                    Text(

                      'No freelancers were found within 50 KM of your location.',

                      textAlign:
                          TextAlign.center,

                      style:
                          TextStyle(

                        color:
                            Colors.grey.shade600,

                      ),

                    ),

                  ],

                ),

              ),

            ),

          )

       else
      

          // =====================================================
          // FREELANCER LIST
          // =====================================================

        // =======================================================
        // FREELANCER SECTIONS + EMPTY STATE + REFRESH
        // =======================================================

        Expanded(
          child: RefreshIndicator(
            color: green,
            onRefresh: _loadFirstFreelancers,
            child: _buildFreelancerSections(),
          ),
        ),

      ],

    );

  }


  // =============================================================
  // FREELANCER CARD
  // =============================================================

  Widget _buildFreelancerCard(
      Map<String, dynamic> freelancer) {

    final name =
        freelancer['name']
                ?.toString()
                .trim() ??
            'Freelancer';


    final distance =
        (freelancer['distanceKm'] as num?)
                ?.toDouble() ??
            0.0;


    final bool isUnlocked =
    distance <= 1.0 ||
    (_hasActiveSubscription &&
        distance <= _paidRadius);

    return Padding(

      padding:
          const EdgeInsets.only(
        bottom:
            12,
      ),

      child:
          Material(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),


        child:
            InkWell(

          borderRadius:
              BorderRadius.circular(
            18,
          ),

          onTap:
              () =>
                  _openFreelancer(
            freelancer,
          ),


          child:
              Container(

            padding:
                const EdgeInsets.all(
              16,
            ),

            decoration:
                BoxDecoration(

              borderRadius:
                  BorderRadius.circular(
                18,
              ),

              border:
                  Border.all(

                color:
                    isUnlocked

                        ? const Color(
                            0xFFE1EAE2,
                          )

                        : const Color(
                            0xFFF0E5D7,
                          ),

              ),

            ),

            child:
                Row(

              children: [

                // =============================================
                // PROFILE ICON
                // =============================================

                Container(

                  width:
                      58,

                  height:
                      58,

                  decoration:
                      const BoxDecoration(

                    color:
                        Color(0xFFE7F4EA),

                    shape:
                        BoxShape.circle,

                  ),

                  child:
                      const Icon(

                    Icons.person,

                    color:
                        green,

                    size:
                        30,

                  ),

                ),


                const SizedBox(
                  width:
                      14,
                ),


                // =============================================
                // NAME AND DISTANCE
                // =============================================

                Expanded(

                  child:
                      Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(

                        name,

                        maxLines:
                            1,

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            const TextStyle(

                          fontSize:
                              17,

                          fontWeight:
                              FontWeight.bold,

                          color:
                              darkGreen,

                        ),

                      ),

                      const SizedBox(
                        height:
                            5,
                      ),

                      Text(

                        widget.selectedCategory,

                        style:
                            TextStyle(

                          fontSize:
                              13,

                          color:
                              Colors.grey.shade600,

                        ),

                      ),

                      const SizedBox(
                        height:
                            7,
                      ),

                      Row(

                        children: [

                          Icon(

                            Icons.location_on,

                            size:
                                17,

                            color:
                                isUnlocked
                                    ? green
                                    : orange,

                          ),

                          const SizedBox(
                            width:
                                4,
                          ),

                          Text(

 _formatDistance(distance),
  style: const TextStyle(
    fontSize: 13,
    color: Color(0xFF12652F),
    fontWeight: FontWeight.w600,
  ),
                         

                          ),

                        ],

                      ),

                    ],

                  ),

                ),


                // =============================================
                // LOCK / ARROW
                // =============================================

                Icon(

                  isUnlocked

                      ? Icons.arrow_forward_ios

                      : Icons.lock_outline,

                  color:
                      isUnlocked
                          ? green
                          : orange,

                  size:
                      21,

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }

}
