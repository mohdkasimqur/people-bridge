import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jober_india/jober_indiaScreens.dart/CorierService/corrier_profile.dart';


class ScreenCourierVehicleList extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ScreenCourierVehicleList({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ScreenCourierVehicleList> createState() =>
      _ScreenCourierVehicleListState();
}

class _ScreenCourierVehicleListState
    extends State<ScreenCourierVehicleList> {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final ScrollController _scrollController =
      ScrollController();

  // ============================================================
  // PAGINATION
  // ============================================================

  static const int _pageSize = 20;

  DocumentSnapshot<Map<String, dynamic>>?
      _lastDocument;

  bool _hasMore = true;

  bool _isLoading = false;

  bool _isLoadingMore = false;

  bool _initialError = false;

  // ============================================================
  // LOCATION
  // ============================================================

  Position? _currentPosition;

  // ============================================================
  // COURIERS
  // ============================================================

  final List<Map<String, dynamic>>
      _couriers = [];

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(
      _onScroll,
    );

    _initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initialize() async {
    await _getCurrentLocation();

    if (!mounted) {
      return;
    }

    await _loadCouriers(
      firstLoad: true,
    );
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        return;
      }

      _currentPosition =
    await Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
  ),
);
    } catch (e) {
      debugPrint(
        'Courier location error: $e',
      );
    }
  }

  // ============================================================
  // LOAD COURIERS
  // ============================================================

  Future<void> _loadCouriers({
    bool firstLoad = false,
  }) async {
    if (_isLoadingMore ||
        _isLoading ||
        (!_hasMore && !firstLoad)) {
      return;
    }

    if (firstLoad) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _initialError = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingMore = true;
        });
      }
    }

    try {
      Query<Map<String, dynamic>>
          query = _firestore
              .collection('couriers')
              .where(
                'vehicleCategoryIds',
                arrayContains:
                    widget.categoryId,
              )
              .orderBy(
                'updatedAt',
                descending: true,
              )
              .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(
          _lastDocument!,
        );
      }

      final snapshot =
          await query.get();

      final newCouriers =
          snapshot.docs.map(
        (doc) {
          final data = doc.data();

          return <String, dynamic>{
            ...data,
            'uid': doc.id,
          };
        },
      ).toList();

      if (newCouriers.isNotEmpty) {
        _lastDocument =
            snapshot.docs.last;

        _couriers.addAll(
          newCouriers,
        );
      }

      if (snapshot.docs.length <
          _pageSize) {
        _hasMore = false;
      }

      _sortByDistance();

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint(
        'Courier loading error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isLoadingMore = false;

        if (firstLoad) {
          _initialError = true;
        }
      });
    }
  }

  // ============================================================
  // SORT NEAREST → FARTHEST
  // ============================================================

  void _sortByDistance() {
    if (_currentPosition == null) {
      return;
    }

    final userLat =
        _currentPosition!.latitude;

    final userLng =
        _currentPosition!.longitude;

    for (final courier in _couriers) {
      final latitude =
          _toDouble(courier['latitude']);

      final longitude =
          _toDouble(courier['longitude']);

      if (latitude == null ||
          longitude == null) {
        courier['distanceKm'] = double.infinity;
        continue;
      }

      courier['distanceKm'] =
          _calculateDistance(
        userLat,
        userLng,
        latitude,
        longitude,
      );
    }

    _couriers.sort(
      (a, b) {
        final aDistance =
            (a['distanceKm'] ?? double.infinity)
                as double;

        final bDistance =
            (b['distanceKm'] ?? double.infinity)
                as double;

        return aDistance.compareTo(
          bDistance,
        );
      },
    );
  }

  // ============================================================
  // DISTANCE
  // ============================================================

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0;

    final dLat =
        _degreesToRadians(
      lat2 - lat1,
    );

    final dLon =
        _degreesToRadians(
      lon2 - lon1,
    );

    final a =
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

    final c =
        2 *
            math.atan2(
              math.sqrt(a),
              math.sqrt(1 - a),
            );

    return earthRadius * c;
  }

  double _degreesToRadians(
    double degrees,
  ) {
    return degrees *
        (math.pi / 180);
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  // ============================================================
  // SCROLL PAGINATION
  // ============================================================

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position =
        _scrollController.position;

    if (position.pixels >=
        position.maxScrollExtent - 500) {
      _loadCouriers();
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    _lastDocument = null;
    _hasMore = true;

    _couriers.clear();

    await _getCurrentLocation();

    await _loadCouriers(
      firstLoad: true,
    );
  }

  // ============================================================
  // OPEN PROFILE
  // ============================================================

  void _openProfile(
    Map<String, dynamic> courier,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ScreenCourierProfile(
          courier: courier,
          categoryName:
              widget.categoryName,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,

        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _refresh,

        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading &&
        _couriers.isEmpty) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_initialError &&
        _couriers.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: [
          SizedBox(
            height:
                MediaQuery.of(context)
                    .size
                    .height *
                    .35,
          ),

          const Icon(
            Icons.cloud_off_outlined,
            size: 50,
            color: Colors.grey,
          ),

          const SizedBox(height: 12),

          const Center(
            child: Text(
              'Unable to load couriers.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Center(
            child: TextButton(
              onPressed: _refresh,
              child: const Text(
                'Try Again',
              ),
            ),
          ),
        ],
      );
    }

    if (_couriers.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: [
          SizedBox(
            height:
                MediaQuery.of(context)
                    .size
                    .height *
                    .35,
          ),

          const Icon(
            Icons.two_wheeler_outlined,
            size: 55,
            color: Colors.grey,
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              'No ${widget.categoryName} couriers found nearby.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,

      physics:
          const AlwaysScrollableScrollPhysics(),

      padding:
          const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        20,
      ),

      itemCount:
          _couriers.length +
              (_hasMore ? 1 : 0),

      itemBuilder:
          (context, index) {

        if (index >=
            _couriers.length) {
          return const Padding(
            padding:
                EdgeInsets.all(18),

            child: Center(
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          );
        }

        final courier =
            _couriers[index];

        return Padding(
          padding:
              const EdgeInsets.only(
            bottom: 12,
          ),

          child:
              _courierCard(courier),
        );
      },
    );
  }

  // ============================================================
  // COURIER CARD
  // ============================================================

  Widget _courierCard(
    Map<String, dynamic> courier,
  ) {
    final name =
        (courier['username'] ??
                courier['name'] ??
                'Courier')
            .toString();

    final photo =
        (courier['profilePhotoUrl'] ??
                '')
            .toString();

    final distance =
        courier['distanceKm'];

    final isLive =
        courier['isLive'] == true;

    return Material(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(16),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),

        onTap: () =>
            _openProfile(courier),

        child: Padding(
          padding:
              const EdgeInsets.all(14),

          child: Row(
            children: [

              // =================================================
              // PHOTO
              // =================================================

              Stack(
                children: [

                  CircleAvatar(
                    radius: 31,

                    backgroundColor:
                        const Color(
                      0xFFEFEFEF,
                    ),

                    backgroundImage:
                        photo.isNotEmpty
                            ? NetworkImage(
                                photo,
                              )
                            : null,

                    child:
                        photo.isEmpty
                            ? const Icon(
                                Icons
                                    .person_outline,
                                size: 30,
                                color:
                                    Colors.grey,
                              )
                            : null,
                  ),

                  if (isLive)
                    Positioned(
                      right: 0,
                      bottom: 1,

                      child: Container(
                        width: 14,
                        height: 14,

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.green,
                          shape:
                              BoxShape.circle,
                          border:
                              Border.all(
                            color:
                                Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 13),

              // =================================================
              // DETAILS
              // =================================================

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
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [

                        const Icon(
                          Icons
                              .local_shipping_outlined,
                          size: 16,
                          color:
                              Colors.black54,
                        ),

                        const SizedBox(
                          width: 5,
                        ),

                        Expanded(
                          child: Text(
                            widget.categoryName,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,

                            style:
                                const TextStyle(
                              fontSize: 13,
                              color:
                                  Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    if (distance is num &&
                        distance !=
                            double.infinity)
                      Row(
                        children: [

                          const Icon(
                            Icons
                                .location_on_outlined,
                            size: 15,
                            color:
                                Colors.red,
                          ),

                          const SizedBox(
                            width: 3,
                          ),

                          Text(
                            _formatDistance(
                              distance
                                  .toDouble(),
                            ),
                            style:
                                const TextStyle(
                              fontSize: 12,
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDistance(
    double distance,
  ) {
    if (distance < 1) {
      return '${(distance * 1000).round()} m away';
    }

    return '${distance.toStringAsFixed(1)} km away';
  }
}