import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';


class AmbulanceNearbyPage extends StatefulWidget {
  final String ambulanceCategory;

  const AmbulanceNearbyPage({
    super.key,
    required this.ambulanceCategory,
  });

  @override
  State<AmbulanceNearbyPage> createState() =>
      _AmbulanceNearbyPageState();
}

class _AmbulanceNearbyPageState
    extends State<AmbulanceNearbyPage> {
  // ============================================================
  // SETTINGS
  // ============================================================

  static const int _pageSize = 20;

  // Search radius.
  // You can change this later.
  static const double _searchRadiusKm = 50;

  // ============================================================
  // FIRESTORE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // DATA
  // ============================================================

  final List<AmbulanceNearbyData> _ambulances = [];

  DocumentSnapshot? _lastDocument;

  Position? _userPosition;

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _locationError = false;

  String? _errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadFirstPage();
  }

  // ============================================================
  // GET USER LOCATION
  // ============================================================

  Future<Position?> _getUserLocation() async {
    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationError = true;
            _errorMessage =
                'Please turn on location services.';
          });
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
          permission ==
              LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationError = true;
            _errorMessage =
                'Location permission is required to find nearby ambulances.';
          });
        }

        return null;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return position;
    } catch (e) {
      debugPrint(
        'Ambulance location error: $e',
      );

      if (mounted) {
        setState(() {
          _locationError = true;
          _errorMessage =
              'Unable to get your current location.';
        });
      }

      return null;
    }
  }

  // ============================================================
  // LOAD FIRST PAGE
  // ============================================================

  Future<void> _loadFirstPage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _lastDocument = null;
      _ambulances.clear();
      _locationError = false;
      _errorMessage = null;
    });

    final Position? position =
        await _getUserLocation();

    if (!mounted) return;

    if (position == null) {
      setState(() {
        _isLoading = false;
      });

      return;
    }

    _userPosition = position;

    await _loadPage(
      firstPage: true,
    );
  }

  // ============================================================
  // LOAD MORE
  // ============================================================

  Future<void> _loadMore() async {
    if (_isLoadingMore ||
        _isLoading ||
        !_hasMore) {
      return;
    }

    await _loadPage(
      firstPage: false,
    );
  }

  // ============================================================
  // FIRESTORE PAGINATION
  // ============================================================

  Future<void> _loadPage({
    required bool firstPage,
  }) async {
    final Position? userPosition =
        _userPosition;

    if (userPosition == null) {
      return;
    }

    if (!firstPage && _lastDocument == null) {
      return;
    }

    if (!firstPage && !_hasMore) {
      return;
    }

    if (mounted) {
      setState(() {
        if (firstPage) {
          _isLoading = true;
        } else {
          _isLoadingMore = true;
        }
      });
    }

    try {
      final GeoBounds bounds =
          _calculateBounds(
        userPosition.latitude,
        userPosition.longitude,
        _searchRadiusKm,
      );

      /*
       * Firestore query:
       *
       * We use latitude range here.
       *
       * We also filter ambulanceCategory.
       *
       * orderBy latitude is important for pagination.
       */

      // Query<Map<String, dynamic>> query =
      //     _firestore
      //         .collection('ambulances')
      //         .where(
      //           'ambulanceCategory',
      //           isEqualTo:
      //               widget.ambulanceCategory,
      //         )
      //         .where(
      //           'latitude',
      //           isGreaterThanOrEqualTo:
      //               bounds.minLat,
      //         )
      //         .where(
      //           'latitude',
      //           isLessThanOrEqualTo:
      //               bounds.maxLat,
      //         )
      //         .orderBy('latitude')
      //         .limit(_pageSize);
      Query<Map<String, dynamic>> query =
    _firestore
        .collection('ambulances')
        .where(
          'latitude',
          isGreaterThanOrEqualTo: bounds.minLat,
        )
        .where(
          'latitude',
          isLessThanOrEqualTo: bounds.maxLat,
        )
        .orderBy('latitude')
        .limit(_pageSize);

      if (!firstPage &&
          _lastDocument != null) {
        query = query.startAfterDocument(
          _lastDocument!,
        );
      }

      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await query.get();

      if (!mounted) return;

      // ========================================================
      // PAGINATION STATE
      // ========================================================

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
          _isLoadingMore = false;
        });

        return;
      }

      _lastDocument = snapshot.docs.last;

      if (snapshot.docs.length <
          _pageSize) {
        _hasMore = false;
      }

      // ========================================================
      // CONVERT DOCUMENTS
      // ========================================================

      final List<AmbulanceNearbyData>
          newAmbulances = [];

      for (final doc
          in snapshot.docs) {
        final data = doc.data();

        final double? latitude =
            _readDouble(data['latitude']);

        final double? longitude =
            _readDouble(data['longitude']);

        if (latitude == null ||
            longitude == null) {
          continue;
        }

        final double distanceMeters =
            Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          latitude,
          longitude,
        );

        // ======================================================
        // DISTANCE FILTER
        // ======================================================

        if (distanceMeters >
            _searchRadiusKm * 1000) {
          continue;
        }

        newAmbulances.add(
          AmbulanceNearbyData.fromFirestore(
            id: doc.id,
            data: data,
            distanceMeters:
                distanceMeters,
          ),
        );
      }

      // ========================================================
      // ADD RESULTS
      // ========================================================

      _ambulances.addAll(
        newAmbulances,
      );

      // ========================================================
      // SORT ALL LOADED RESULTS
      // ========================================================

      _ambulances.sort(
        (a, b) => a.distanceMeters.compareTo(
          b.distanceMeters,
        ),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } on FirebaseException catch (e) {
      debugPrint(
        'Ambulance Firestore error: ${e.code}',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isLoadingMore = false;

        _errorMessage =
            e.message ??
            'Unable to load nearby ambulances.';
      });
    } catch (e) {
      debugPrint(
        'Ambulance pagination error: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isLoadingMore = false;

        _errorMessage =
            'Unable to load nearby ambulances.';
      });
    }
  }

  // ============================================================
  // READ DOUBLE SAFELY
  // ============================================================

  double? _readDouble(
    dynamic value,
  ) {
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
  // CALCULATE GEO BOUNDS
  // ============================================================

  GeoBounds _calculateBounds(
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    const double earthRadiusKm =
        6371.0;

    final double latDelta =
        radiusKm / earthRadiusKm;

    final double longitudeCos =
        math.cos(
          latitude *
              math.pi /
              180,
        );

    final double safeCos =
        longitudeCos.abs() < 0.000001
            ? 0.000001
            : longitudeCos;

    final double lonDelta =
        radiusKm /
        (earthRadiusKm * safeCos);

    final double minLat =
        latitude -
        latDelta * 180 / math.pi;

    final double maxLat =
        latitude +
        latDelta * 180 / math.pi;

    final double minLon =
        longitude -
        lonDelta * 180 / math.pi;

    final double maxLon =
        longitude +
        lonDelta * 180 / math.pi;

    return GeoBounds(
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
    );
  }

  // ============================================================
  // CALL AMBULANCE
  // ============================================================

  // Future<void> _callAmbulance(
  //   String phone,
  // ) async {
  //   if (phone.trim().isEmpty) {
  //     _showMessage(
  //       'No secondary mobile number available.',
  //       error: true,
  //     );

  //     return;
  //   }

  //   final String cleanNumber =
  //       phone.replaceAll(
  //     RegExp(r'\D'),
  //     '',
  //   );

  //   final String number =
  //       cleanNumber.length == 10
  //           ? '+91$cleanNumber'
  //           : cleanNumber;

  //   final Uri uri = Uri(
  //     scheme: 'tel',
  //     path: number,
  //   );

  //   try {
  //     if (await canLaunchUrl(uri)) {
  //       await launchUrl(uri);
  //     } else {
  //       _showMessage(
  //         'Unable to make the call.',
  //         error: true,
  //       );
  //     }
  //   } catch (e) {
  //     _showMessage(
  //       'Unable to make the call.',
  //       error: true,
  //     );
  //   }
  // }
  Future<void> _callAmbulance(String phone) async {
  try {
    // Remove spaces, brackets, hyphens and other characters.
    final String cleanNumber = phone.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    if (cleanNumber.isEmpty) {
      _showMessage(
        'Ambulance secondary mobile number is unavailable.',
        error: true,
      );
      return;
    }

    // Add India's country code if necessary.
    String finalNumber = cleanNumber;

    if (!finalNumber.startsWith('+')) {
      if (finalNumber.length == 10) {
        finalNumber = '+91$finalNumber';
      } else {
        _showMessage(
          'Invalid ambulance mobile number.',
          error: true,
        );
        return;
      }
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: finalNumber,
    );

    // Open the phone dialer directly.
    // Do not depend on canLaunchUrl().
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      _showMessage(
        'Unable to open the phone dialer.',
        error: true,
      );
    }
  } catch (e) {
    debugPrint('Ambulance calling error: $e');

    _showMessage(
      'Unable to make the call. Please try again.',
      error: true,
    );
  }
}

  // ============================================================
  // OPEN AMBULANCE PROFILE
  // ============================================================

  void _openAmbulanceProfile(
  AmbulanceNearbyData ambulance,
) {
  // We will connect this to the
  // Ambulance Profile page next.
}

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error
              ? Colors.red
              : const Color(0xFF176B32),
          behavior:
              SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // DISTANCE TEXT
  // ============================================================

  // String _distanceText(
  //   double distanceMeters,
  // ) {
  //   if (distanceMeters < 1000) {
  //     return '${distanceMeters.round()} m away';
  //   }

  //   final double km =
  //       distanceMeters / 1000;

  //   if (km < 10) {
  //     return '${km.toStringAsFixed(1)} km away';
  //   }

  //   return '${km.toStringAsFixed(0)} km away';
  // }
  String _distanceText(double distanceMeters) {
  if (distanceMeters < 1000) {
    return '${distanceMeters.round()} meters away';
  }

  final double km = distanceMeters / 1000;

  if (km == km.roundToDouble()) {
    return '${km.toStringAsFixed(0)} km away';
  }

  return '${km.toStringAsFixed(2).replaceFirst(
    RegExp(r'0+$'),
    '',
  ).replaceFirst(
    RegExp(r'\.$'),
    '',
  )} km away';
}

  // ============================================================
  // AMBULANCE CARD
  // ============================================================

  Widget _buildAmbulanceCard(
    AmbulanceNearbyData ambulance,
  ) {
    // final bool hasImage =
    //     ambulance.profilePhotoUrl
    //             .trim()
    //             .isNotEmpty;

    return GestureDetector(
      onTap: () {
        _openAmbulanceProfile(
          ambulance,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 14,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE1E1E1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.05),
              blurRadius: 9,
              offset:
                  const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // IMAGE
            // ==================================================

            // ClipRRect(
            //   borderRadius:
            //       BorderRadius.circular(16),
            //   child: Container(
            //     width: 105,
            //     height: 105,
            //     color:
            //         const Color(0xFFF4F4F4),
            //     child: hasImage
            //         ? Image.network(
            //             ambulance
            //                 .profilePhotoUrl,
            //             fit: BoxFit.cover,
            //             errorBuilder:
            //                 (
            //               context,
            //               error,
            //               stackTrace,
            //             ) {
            //               return _defaultImage();
            //             },
            //           )
            //         : _defaultImage(),
            //   ),
            // ),
            ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: Container(
    width: 85,
    height: 85,
    color: const Color(0xFFEAF7EE),
    child: const Center(
      child: Icon(
        Icons.local_hospital_outlined,
        size: 45,
        color: Color(0xFF16803C),
      ),
    ),
  ),
),

            const SizedBox(width: 13),

            // ==================================================
            // DETAILS
            // ==================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    ambulance.name
                            .trim()
                            .isEmpty
                        ? 'Ambulance'
                        : ambulance.name,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          Color(0xFF202124),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    ambulance
                        .ambulanceCategory,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color:
                          Color(0xFF666666),
                    ),
                  ),

                  const SizedBox(height: 7),

                  // ==================================================
                  // DISTANCE
                  // ==================================================

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .location_on_outlined,
                        size: 18,
                        color:
                            Color(0xFF16803C),
                      ),

                      const SizedBox(
                        width: 4,
                      ),

                      Expanded(
                        child: Text(
                          _distanceText(
                            ambulance
                                .distanceMeters,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                Color(0xFF16803C),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // VEHICLE NUMBER
                  // ==================================================

                  if (ambulance
                      .vehicleNumber
                      .trim()
                      .isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFFFD928,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          6,
                        ),
                        border:
                            Border.all(
                          color:
                              Colors.black26,
                        ),
                      ),
                      child: Text(
                        ambulance
                            .vehicleNumber,
                        style:
                            const TextStyle(
                          color:
                              Colors.black,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing:
                              0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ==================================================
            // CALL
            // ==================================================

            const SizedBox(width: 5),

            IconButton(
              onPressed:
                  ambulance.secondaryMobile
                          .trim()
                          .isEmpty
                      ? null
                      : () {
                          _callAmbulance(
                            ambulance
                                .secondaryMobile,
                          );
                        },
              tooltip: 'Call',
              icon: const Icon(
                Icons.call,
                color:
                    Color(0xFF16803C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _defaultImage() {
  //   return const Center(
  //     child: Icon(
  //       Icons.local_hospital_outlined,
  //       size: 52,
  //       color: Color(0xFF16803C),
  //     ),
  //   );
  // }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        titleSpacing: 0,

        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              widget.ambulanceCategory,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const Text(
              'Nearby ambulances',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: _isLoading
                ? null
                : _loadFirstPage,
            icon: const Icon(
              Icons.refresh,
              color:
                  Color(0xFF16803C),
            ),
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF16803C),
        ),
      );
    }

    if (_locationError) {
      return _buildLocationError();
    }

    if (_errorMessage != null &&
        _ambulances.isEmpty) {
      return _buildError();
    }

    if (_ambulances.isEmpty) {
      return _buildNoAmbulances();
    }

    return RefreshIndicator(
      color: const Color(0xFF16803C),

      onRefresh: _loadFirstPage,

      child: ListView.builder(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          30,
        ),

        itemCount:
            _ambulances.length +
            (_hasMore ? 1 : 0),

        itemBuilder:
            (context, index) {
          // ====================================================
          // LOAD MORE
          // ====================================================

          if (index ==
              _ambulances.length) {
            return _buildLoadMore();
          }

          return _buildAmbulanceCard(
            _ambulances[index],
          );
        },
      ),
    );
  }

  // ============================================================
  // LOAD MORE BUTTON
  // ============================================================

  Widget _buildLoadMore() {
    if (_isLoadingMore) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical: 22,
        ),
        child: Center(
          child:
              CircularProgressIndicator(
            strokeWidth: 2.5,
            color:
                Color(0xFF16803C),
          ),
        ),
      );
    }

    return Padding(
      padding:
          const EdgeInsets.only(
        top: 5,
        bottom: 15,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: _loadMore,
          style:
              OutlinedButton.styleFrom(
            foregroundColor:
                const Color(
              0xFF16803C,
            ),
            side:
                const BorderSide(
              color:
                  Color(0xFF16803C),
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),
          ),
          child: const Text(
            'Load More',
            style: TextStyle(
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION ERROR
  // ============================================================

  Widget _buildLocationError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 55,
              color: Colors.red,
            ),

            const SizedBox(height: 15),

            Text(
              _errorMessage ??
                  'Location is required.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed:
                  _loadFirstPage,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF16803C,
                ),
                foregroundColor:
                    Colors.white,
                elevation: 0,
              ),
              child:
                  const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 55,
              color: Colors.red,
            ),

            const SizedBox(height: 15),

            Text(
              _errorMessage ??
                  'Unable to load ambulances.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed:
                  _loadFirstPage,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF16803C,
                ),
                foregroundColor:
                    Colors.white,
                elevation: 0,
              ),
              child:
                  const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NO AMBULANCES
  // ============================================================

  Widget _buildNoAmbulances() {
    return RefreshIndicator(
      color:
          const Color(0xFF16803C),

      onRefresh:
          _loadFirstPage,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: [
          SizedBox(
            height:
                MediaQuery.of(context)
                        .size
                        .height *
                    0.30,
          ),

          const Icon(
            Icons.local_hospital_outlined,
            size: 65,
            color:
                Color(0xFFBDBDBD),
          ),

          const SizedBox(height: 15),

          const Center(
            child: Text(
              'No nearby ambulances found.',
              style:
                  TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(0xFF555555),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Center(
            child: Text(
              'No ${widget.ambulanceCategory} vehicles are available within $_searchRadiusKm km.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    Color(0xFF888888),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// GEO BOUNDS
// ==================================================================

class GeoBounds {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const GeoBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });
}

// ==================================================================
// AMBULANCE DATA
// ==================================================================

class AmbulanceNearbyData {
  final String id;

  final String name;
  final String mobile;
  final String secondaryMobile;

  final String ambulanceCategory;

  final String vehicleName;
  final String vehicleNumber;

  final String profilePhotoUrl;

  final String placeName;

  final double latitude;
  final double longitude;

  final double distanceMeters;

  AmbulanceNearbyData({
    required this.id,
    required this.name,
    required this.mobile,
    required this.secondaryMobile,
    required this.ambulanceCategory,
    required this.vehicleName,
    required this.vehicleNumber,
    required this.profilePhotoUrl,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
  });

  factory AmbulanceNearbyData.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
    required double distanceMeters,
  }) {
    final dynamic location =
        data['location'];

    String placeName =
        (data['placeName'] ?? '')
            .toString();

    double? latitude =
        _readDoubleStatic(
          data['latitude'],
        );

    double? longitude =
        _readDoubleStatic(
          data['longitude'],
        );

    // ==========================================================
    // FALLBACK TO location MAP
    // ==========================================================

    if (location is Map) {
      if (placeName.isEmpty) {
        placeName =
            (location['placeName'] ?? '')
                .toString();
      }

      latitude ??=
          _readDoubleStatic(
        location['latitude'],
      );

      longitude ??=
          _readDoubleStatic(
        location['longitude'],
      );
    }

    return AmbulanceNearbyData(
      id: id,

      name:
          (data['name'] ?? '')
              .toString(),

      mobile:
          (data['mobile'] ?? '')
              .toString(),

      secondaryMobile:
          (data['secondaryMobile'] ?? '')
              .toString(),

      ambulanceCategory:
          (data['ambulanceCategory'] ??
                  '')
              .toString(),

      vehicleName:
          (data['vehicleName'] ?? '')
              .toString(),

      vehicleNumber:
          (data['vehicleNumber'] ?? '')
              .toString(),

      profilePhotoUrl:
          (data['profilePhotoUrl'] ??
                  '')
              .toString(),

      placeName: placeName,

      latitude:
          latitude ?? 0,

      longitude:
          longitude ?? 0,

      distanceMeters:
          distanceMeters,
    );
  }

  static double? _readDoubleStatic(
    dynamic value,
  ) {
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
}