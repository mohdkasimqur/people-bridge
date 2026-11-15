import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screen_grocery_profile.dart';

class ScreenNearbyGrocery extends StatefulWidget {
  final String selectedCategory;

  const ScreenNearbyGrocery({
    super.key,
    required this.selectedCategory,
  });

  @override
  State<ScreenNearbyGrocery> createState() =>
      _ScreenNearbyGroceryState();
}

class _ScreenNearbyGroceryState
    extends State<ScreenNearbyGrocery> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final ScrollController _scrollController =
      ScrollController();

  // ==========================================================
  // FIRESTORE
  // ==========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  DocumentSnapshot? _lastDocument;

  // ==========================================================
  // DATA
  // ==========================================================

  final List<Map<String, dynamic>> groceries = [];

  // ==========================================================
  // LOCATION
  // ==========================================================

  Position? _currentPosition;

  // ==========================================================
  // PAGINATION
  // ==========================================================

  static const int pageSize = 20;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  // ==========================================================
  // DISTANCE
  // ==========================================================

  static const double maxSearchDistanceKm = 50.0;

  double paidDistance = 5.0;

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color darkGreen =
      Color(0xFF138808);

  static const Color orange =
      Color(0xFFED801D);

  static const Color background =
      Color(0xFFF7F8F7);

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(
      _scrollListener,
    );

    _initializePage();
  }

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  Future<void> _initializePage() async {
    await _loadPaidDistance();

    await _getCurrentLocation();

    if (_currentPosition != null) {
      await _loadGroceries(
        firstLoad: true,
      );
    }
  }

  // ==========================================================
  // LOAD PAID DISTANCE
  // ==========================================================

  Future<void> _loadPaidDistance() async {
    try {
      final box =
          await Hive.openBox('settings');

      final savedDistance =
          box.get('paidDistance');

      if (savedDistance != null) {
        paidDistance =
            double.tryParse(
                  savedDistance.toString(),
                ) ??
                5.0;
      }
    } catch (_) {
      paidDistance = 5.0;
    }
  }

  // ==========================================================
  // GET CURRENT LOCATION
  // ==========================================================

  Future<void> _getCurrentLocation() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        await _showLocationMessage(
          'Location is turned off. Please turn on location to find grocery shops near you.',
        );
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
        await _showLocationMessage(
          'Location permission is required to find nearby grocery shops.',
        );
        return;
      }

    final position = await Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
  ),
);

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      await _showLocationMessage(
        'Unable to get your current location.',
      );
    } finally {
      if (!mounted) {
      setState(() {
        _isLoading = false;
      });}
    }
  }

  // ==========================================================
  // LOCATION MESSAGE
  // ==========================================================

  Future<void> _showLocationMessage(
    String message,
  ) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Location Required',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: darkGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // SCROLL LISTENER
  // ==========================================================

  void _scrollListener() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent -
            300) {
      if (!_isLoadingMore &&
          !_isLoading &&
          _hasMore) {
        _loadGroceries();
      }
    }
  }
  // ==========================================================
  // LOAD GROCERY SHOPS
  // ==========================================================

  Future<void> _loadGroceries({
    bool firstLoad = false,
  }) async {
    if (_currentPosition == null) {
      return;
    }

    if (_isLoadingMore || _isLoading) {
      if (!firstLoad) return;
    }

    if (!_hasMore && !firstLoad) {
      return;
    }

    if (mounted) {
      setState(() {
        if (firstLoad) {
          _isLoading = true;
        } else {
          _isLoadingMore = true;
        }
      });
    }

    try {
      if (firstLoad) {
        _lastDocument = null;
        _hasMore = true;
        groceries.clear();
      }

      Query<Map<String, dynamic>> query = _firestore
          .collection('groceries')
          .where(
            'categories',
            arrayContains: widget.selectedCategory,
          )
          .limit(pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(
          _lastDocument!,
        );
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _hasMore = false;
          });
        }
        return;
      }

      _lastDocument = snapshot.docs.last;

      if (snapshot.docs.length < pageSize) {
        _hasMore = false;
      }

      final currentLatitude =
          _currentPosition!.latitude;

      final currentLongitude =
          _currentPosition!.longitude;

      final List<Map<String, dynamic>>
          newGroceries = [];

      for (final document in snapshot.docs) {
        final data =
            Map<String, dynamic>.from(
          document.data(),
        );

        // ------------------------------------------------------
        // DOCUMENT ID
        // ------------------------------------------------------

        data['documentId'] = document.id;

        // ------------------------------------------------------
        // LATITUDE / LONGITUDE
        // ------------------------------------------------------

        double? latitude;
        double? longitude;

        final rawLatitude =
            data['latitude'];

        final rawLongitude =
            data['longitude'];

        if (rawLatitude is num) {
          latitude =
              rawLatitude.toDouble();
        } else if (rawLatitude != null) {
          latitude = double.tryParse(
            rawLatitude.toString(),
          );
        }

        if (rawLongitude is num) {
          longitude =
              rawLongitude.toDouble();
        } else if (rawLongitude != null) {
          longitude = double.tryParse(
            rawLongitude.toString(),
          );
        }

        // ------------------------------------------------------
        // FALLBACK TO GEOPOINT
        // ------------------------------------------------------

        if ((latitude == null ||
                longitude == null) &&
            data['location'] is GeoPoint) {
          final geoPoint =
              data['location'] as GeoPoint;

          latitude = geoPoint.latitude;
          longitude = geoPoint.longitude;
        }

        if (latitude == null ||
            longitude == null) {
          continue;
        }

        // ------------------------------------------------------
        // EXACT DISTANCE
        // ------------------------------------------------------

        final distanceInMeters =
            Geolocator.distanceBetween(
          currentLatitude,
          currentLongitude,
          latitude,
          longitude,
        );

        final distanceInKm =
            distanceInMeters / 1000;

        // ------------------------------------------------------
        // ONLY SHOW WITHIN 50 KM
        // ------------------------------------------------------

        if (distanceInKm >
            maxSearchDistanceKm) {
          continue;
        }

        data['latitude'] = latitude;
        data['longitude'] = longitude;
        data['distanceKm'] = distanceInKm;

        newGroceries.add(data);
      }

      // --------------------------------------------------------
      // ADD NEW RESULTS
      // --------------------------------------------------------

      groceries.addAll(newGroceries);

      // --------------------------------------------------------
      // SORT NEAREST → FARTHEST
      // --------------------------------------------------------

      groceries.sort(
        (a, b) {
          final distanceA =
              (a['distanceKm'] as num?)
                      ?.toDouble() ??
                  double.infinity;

          final distanceB =
              (b['distanceKm'] as num?)
                      ?.toDouble() ??
                  double.infinity;

          return distanceA.compareTo(
            distanceB,
          );
        },
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to load grocery shops. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (!mounted) {

      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });}
    }
  }

  // ==========================================================
  // REFRESH
  // ==========================================================

  Future<void> _refreshGroceries() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }

    if (_currentPosition == null) {
      return;
    }

    await _loadGroceries(
      firstLoad: true,
    );
  }

  // ==========================================================
  // FORMAT DISTANCE
  // ==========================================================

  String _formatDistance(
    double distanceKm,
  ) {
    if (distanceKm < 1) {
      final meters =
          (distanceKm * 1000).round();

      return '$meters m Away';
    }

    return '${distanceKm.toStringAsFixed(1)} KM Away';
  }

  // ==========================================================
  // CHECK PAYMENT / PAID RADIUS
  // ==========================================================

  Future<bool> _canOpenProfile(
    Map<String, dynamic> grocery,
  ) async {
    final distanceKm =
        (grocery['distanceKm'] as num?)
                ?.toDouble() ??
            0.0;

    // --------------------------------------------------------
    // INSIDE PAID RADIUS
    // --------------------------------------------------------

    if (distanceKm <= paidDistance) {
      return true;
    }

    // --------------------------------------------------------
    // CHECK PAYMENT EXPIRY
    // --------------------------------------------------------

    try {
      final settingsBox =
          await Hive.openBox('settings');

      final expiry =
          settingsBox.get('paymentExpiry');

      if (expiry != null) {
        DateTime? expiryDate;

        if (expiry is DateTime) {
          expiryDate = expiry;
        } else {
          expiryDate = DateTime.tryParse(
            expiry.toString(),
          );
        }

        if (expiryDate != null &&
            expiryDate.isAfter(
              DateTime.now(),
            )) {
          return true;
        }
      }
    } catch (_) {
      // Continue to payment dialog.
    }

    // --------------------------------------------------------
    // PAYMENT REQUIRED
    // --------------------------------------------------------

    if (!mounted) {
      return false;
    }

    await _showPaymentDialog(
      distanceKm,
    );

    return false;
  }

  // ==========================================================
  // PAYMENT DIALOG
  // ==========================================================

  Future<void> _showPaymentDialog(
    double distanceKm,
  ) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),

          title: const Text(
            'Unlock More Distance',
            style: TextStyle(
              color: darkGreen,
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Text(
            'This grocery shop is ${distanceKm.toStringAsFixed(1)} km away.\n\n'
            'Your current access radius is '
            '${paidDistance.toStringAsFixed(0)} km.\n\n'
            'Unlock a larger search radius to view this grocery profile.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                // ------------------------------------------------
                // CONNECT YOUR EXISTING DISTANCE PAYMENT PAGE HERE
                // ------------------------------------------------

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Distance payment options will be available here.',
                    ),
                  ),
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                elevation: 0,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),

              child: const Text(
                'VIEW OPTIONS',
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

  // ==========================================================
  // OPEN GROCERY PROFILE
  // ==========================================================

  Future<void> _openGroceryProfile(
    Map<String, dynamic> grocery,
  ) async {
    final canOpen =
        await _canOpenProfile(grocery);

    if (!canOpen || !mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenGroceryProfile(
          grocery: grocery,
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
      backgroundColor: background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 30,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Nearby ',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(
                text: 'Grocery',
                style: TextStyle(
                  color: orange,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh,
              color: darkGreen,
              size: 27,
            ),
            onPressed: _isLoading
                ? null
                : _refreshGroceries,
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

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    // ----------------------------------------------------------
    // INITIAL LOADING
    // ----------------------------------------------------------

    if (_isLoading && groceries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: darkGreen,
        ),
      );
    }

    // ----------------------------------------------------------
    // NO LOCATION
    // ----------------------------------------------------------

    if (_currentPosition == null) {
      return _locationRequiredWidget();
    }

    // ----------------------------------------------------------
    // NO GROCERY SHOPS
    // ----------------------------------------------------------

    if (groceries.isEmpty) {
      return _emptyGroceryWidget();
    }

    // ----------------------------------------------------------
    // GROCERY LIST
    // ----------------------------------------------------------

    return RefreshIndicator(
      color: darkGreen,
      onRefresh: _refreshGroceries,

      child: ListView.builder(
        controller: _scrollController,

        physics:
            const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          30,
        ),

        itemCount:
            groceries.length +
            (_isLoadingMore ? 1 : 0),

        itemBuilder: (context, index) {
          // ----------------------------------------------------
          // LOAD MORE INDICATOR
          // ----------------------------------------------------

          if (index >= groceries.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 20,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: darkGreen,
                ),
              ),
            );
          }

          final grocery =
              groceries[index];

          return _groceryCard(
            grocery,
          );
        },
      ),
    );
  }

  // ==========================================================
  // GROCERY CARD
  // ==========================================================

  Widget _groceryCard(
    Map<String, dynamic> grocery,
  ) {
    final shopName =
        (grocery['displayName'] ??
                grocery['shopName'] ??
                'Grocery Store')
            .toString();

    final categories =
        grocery['categories'] is List
            ? List<String>.from(
                grocery['categories']
                    .map(
                      (e) => e.toString(),
                    ),
              )
            : <String>[];

    final distance =
        (grocery['distanceKm'] as num?)
                ?.toDouble() ??
            0.0;

    final openingTime =
        (grocery['openingTime'] ??
                '')
            .toString();

    final closingTime =
        (grocery['closingTime'] ??
                '')
            .toString();

    final photoUrl =
        (grocery['photoUrl'] ?? '')
            .toString();

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 15,
      ),

      child: Material(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        child: InkWell(
          borderRadius:
              BorderRadius.circular(20),

          onTap: () {
            _openGroceryProfile(
              grocery,
            );
          },

          child: Container(
            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(20),

              border: Border.all(
                color:
                    const Color(0xFFE0E0E0),
              ),

              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 7,
                  offset: Offset(0, 2),
                ),
              ],
            ),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // =================================================
                // SHOP IMAGE
                // =================================================

                _groceryImage(
                  photoUrl,
                ),

                const SizedBox(
                  width: 14,
                ),

                // =================================================
                // SHOP INFORMATION
                // =================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      // -------------------------------------------
                      // SHOP NAME
                      // -------------------------------------------

                      Text(
                        shopName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            const TextStyle(
                          color: Colors.black87,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      // -------------------------------------------
                      // CATEGORY
                      // -------------------------------------------

                      if (categories.isNotEmpty)
                        Text(
                          categories.join(
                            ', ',
                          ),
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              const TextStyle(
                            color: darkGreen,
                            fontSize: 13.5,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),

                      const SizedBox(
                        height: 8,
                      ),

                      // -------------------------------------------
                      // DISTANCE
                      // -------------------------------------------

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: orange,
                            size: 18,
                          ),

                          const SizedBox(
                            width: 4,
                          ),

                          Text(
                            _formatDistance(
                              distance,
                            ),
                            style:
                                const TextStyle(
                              color: Colors.black54,
                              fontSize: 13.5,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // -------------------------------------------
                      // OPENING / CLOSING
                      // -------------------------------------------

                      if (openingTime
                              .isNotEmpty ||
                          closingTime
                              .isNotEmpty) ...[
                        const SizedBox(
                          height: 7,
                        ),

                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: darkGreen,
                              size: 17,
                            ),

                            const SizedBox(
                              width: 5,
                            ),

                            Expanded(
                              child: Text(
                                '${openingTime.isNotEmpty ? openingTime : '--'}'
                                ' - '
                                '${closingTime.isNotEmpty ? closingTime : '--'}',

                                style:
                                    const TextStyle(
                                  color:
                                      Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // =================================================
                // ARROW
                // =================================================

                const Padding(
                  padding: EdgeInsets.only(
                    top: 5,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: darkGreen,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // GROCERY IMAGE
  // ==========================================================

  Widget _groceryImage(
    String photoUrl,
  ) {
    if (photoUrl.isEmpty) {
      return Container(
        width: 82,
        height: 82,

        decoration: BoxDecoration(
          color: const Color(0xFFEAF6ED),

          borderRadius:
              BorderRadius.circular(16),
        ),

        child: const Icon(
          Icons.local_grocery_store_outlined,
          color: darkGreen,
          size: 40,
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(16),

      child: Image.network(
        photoUrl,

        width: 82,
        height: 82,

        fit: BoxFit.cover,

        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            width: 82,
            height: 82,

            decoration: BoxDecoration(
              color:
                  const Color(0xFFEAF6ED),

              borderRadius:
                  BorderRadius.circular(16),
            ),

            child: const Icon(
              Icons.local_grocery_store_outlined,
              color: darkGreen,
              size: 40,
            ),
          );
        },

        loadingBuilder:
            (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Container(
            width: 82,
            height: 82,

            decoration: BoxDecoration(
              color:
                  const Color(0xFFF1F4F1),

              borderRadius:
                  BorderRadius.circular(16),
            ),

            child: const Center(
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color: darkGreen,
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // LOCATION REQUIRED
  // ==========================================================

  Widget _locationRequiredWidget() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 30,
        ),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Container(
              width: 85,
              height: 85,

              decoration: BoxDecoration(
                color:
                    const Color(0xFFEAF6ED),

                borderRadius:
                    BorderRadius.circular(28),
              ),

              child: const Icon(
                Icons.location_off_outlined,
                color: darkGreen,
                size: 43,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'Location Required',
              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.black87,
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Turn on your location to find grocery shops near you.',
              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed:
                  _initializePage,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                foregroundColor: Colors.white,
                elevation: 0,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 13,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),

              child: const Text(
                'TRY AGAIN',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY GROCERY RESULT
  // ==========================================================

  Widget _emptyGroceryWidget() {
    return RefreshIndicator(
      color: darkGreen,

      onRefresh:
          _refreshGroceries,

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

          Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 30,
              ),

              child: Column(
                children: [

                  Container(
                    width: 85,
                    height: 85,

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFEAF6ED,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        28,
                      ),
                    ),

                    child: const Icon(
                      Icons
                          .local_grocery_store_outlined,
                      color: darkGreen,
                      size: 43,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  const Text(
                    'No Grocery Shops Found',
                    textAlign:
                        TextAlign.center,

                    style: TextStyle(
                      color:
                          Colors.black87,
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    'No ${widget.selectedCategory} shops were found within 50 km of your location.',
                    textAlign:
                        TextAlign.center,

                    style:
                        const TextStyle(
                      color:
                          Colors.black54,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  const Text(
                    'Pull down to refresh.',
                    style: TextStyle(
                      color:
                          Colors.black45,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}