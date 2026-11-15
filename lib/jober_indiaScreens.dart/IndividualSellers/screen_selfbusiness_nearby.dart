import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';


// ===============================================================
// SCREEN NEARBY SELF BUSINESS
// ===============================================================

class ScreenNearbySelfBusiness
    extends StatefulWidget {

  final String category;

  const ScreenNearbySelfBusiness({
    super.key,
    required this.category,
  });

  @override
  State<ScreenNearbySelfBusiness>
      createState() =>
          _ScreenNearbySelfBusinessState();
}


// ===============================================================
// STATE
// ===============================================================

class _ScreenNearbySelfBusinessState
    extends State<ScreenNearbySelfBusiness> {

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

  static const Color borderColor =
      Color(0xFFE0E0E0);


  // =============================================================
  // FIRESTORE
  // =============================================================

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final ScrollController scrollController = ScrollController();


  // =============================================================
  // USER LOCATION
  // =============================================================

  Position? userPosition;
  bool isGettingLocation = false;
  String? locationError;


  // =============================================================
  // BUSINESS LIST
  // =============================================================

  final List<Map<String, dynamic>>
      businesses = [];


  // =============================================================
  // LOADING STATES
  // =============================================================

  bool isLoading = true;

  bool isLoadingMore = false;

  bool hasMoreBusinesses = true;


  // =============================================================
  // PAGINATION
  // =============================================================

  static const int pageSize = 20;

  DocumentSnapshot? lastDocument;


  // =============================================================
  // MAXIMUM SEARCH DISTANCE
  // =============================================================

  static const double maxSearchRadiusKm =
      50.0;


  // =============================================================
  // USER PAID RADIUS
  // =============================================================
  //
  // IMPORTANT:
  //
  // This is currently set to 10 KM as an example.
  //
  // Later we will load this value from:
  //
  // Firestore
  // Hive
  // Payment system
  //
  // Example:
  //
  // User paid = 10 KM
  // User can see = 50 KM
  // User can open = only businesses within 10 KM
  //
  // =============================================================

  double paidRadiusKm = 10.0;


  // =============================================================
  // INIT STATE
  // =============================================================

  @override
  void initState() {

    super.initState();

    scrollController.addListener(
      handleScroll,
    );

    initializeScreen();
  }


  // =============================================================
  // INITIALIZE SCREEN
  // =============================================================

  Future<void> initializeScreen() async {

    await getUserCurrentLocation();

    if (userPosition == null) {

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      return;
    }


    await loadBusinesses(
      refresh: true,
    );
  }


  // =============================================================
  // HANDLE SCROLL
  // =============================================================

  void handleScroll() {

    if (!scrollController.hasClients) {
      return;
    }


    final double position =
        scrollController.position.pixels;

    final double maxPosition =
        scrollController.position.maxScrollExtent;


    // -----------------------------------------------------------
    // LOAD MORE BEFORE USER REACHES BOTTOM
    // -----------------------------------------------------------

    if (position >=
        maxPosition - 300) {

      loadMoreBusinesses();
    }
  }


  // =============================================================
  // LOAD MORE BUSINESSES
  // =============================================================

  Future<void>
      loadMoreBusinesses() async {

    if (isLoadingMore) {
      return;
    }

    if (!hasMoreBusinesses) {
      return;
    }

    if (userPosition == null) {
      return;
    }

    await loadBusinesses();
  }


  // =============================================================
  // GET USER CURRENT LOCATION
  // =============================================================

  Future<void>
      getUserCurrentLocation() async {

    if (isGettingLocation) {
      return;
    }


    if (!mounted) {
      return;
    }


    setState(() {

      isGettingLocation = true;

      locationError = null;
    });


    try {

      // ---------------------------------------------------------
      // CHECK LOCATION SERVICE
      // ---------------------------------------------------------

      final bool serviceEnabled =
          await Geolocator
              .isLocationServiceEnabled();


      if (!serviceEnabled) {

        throw Exception(
          'Please turn on your location service',
        );
      }


      // ---------------------------------------------------------
      // CHECK PERMISSION
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


      if (permission ==
          LocationPermission.denied) {

        throw Exception(
          'Location permission was denied',
        );
      }


      if (permission ==
          LocationPermission.deniedForever) {

        throw Exception(
          'Location permission is permanently denied. '
          'Please enable it from App Settings.',
        );
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
        return;
      }


      setState(() {

        userPosition =
            position;

        isGettingLocation =
            false;

        locationError =
            null;
      });


    } catch (e) {

      if (!mounted) {
        return;
      }


      setState(() {

        isGettingLocation =
            false;

        locationError =
            e.toString()
                .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }


  // =============================================================
  // LOAD BUSINESSES
  // =============================================================
  //
  // PERFORMANCE SYSTEM:
  //
  // 1. Firestore filters selected category
  //
  // 2. Only 20 documents are loaded
  //
  // 3. More documents load only while scrolling
  //
  // =============================================================

  Future<void>
      loadBusinesses({
    bool refresh = false,
  }) async {

    if (userPosition == null) {
      return;
    }


    if (refresh) {

      if (!mounted) {
        return;
      }

      setState(() {

        isLoading = true;

        isLoadingMore = false;

        hasMoreBusinesses = true;

        lastDocument = null;

        businesses.clear();
      });

    } else {

      if (!mounted) {
        return;
      }

      setState(() {
        isLoadingMore = true;
      });
    }


    try {

      // ---------------------------------------------------------
      // CATEGORY QUERY
      // ---------------------------------------------------------

      Query<Map<String, dynamic>> query =
          firestore
              .collection(
                'selfBusinesses',
              )
              .where(
                'category',
                isEqualTo:
                    widget.category,
              )
              .where(
                'isActive',
                isEqualTo:
                    true,
              )
              .orderBy(
                'createdAt',
                descending:
                    true,
              )
              .limit(
                pageSize,
              );


      // ---------------------------------------------------------
      // PAGINATION
      // ---------------------------------------------------------

      if (!refresh &&
          lastDocument != null) {

        query =
            query.startAfterDocument(
          lastDocument!,
        );
      }


      // ---------------------------------------------------------
      // GET FIRESTORE DATA
      // ---------------------------------------------------------

      final QuerySnapshot<
              Map<String, dynamic>>
          snapshot =
          await query.get();


      // ---------------------------------------------------------
      // SAVE LAST DOCUMENT
      // ---------------------------------------------------------

      if (snapshot.docs.isNotEmpty) {

        lastDocument =
            snapshot.docs.last;
      }


      // ---------------------------------------------------------
      // CHECK IF MORE DATA EXISTS
      // ---------------------------------------------------------

      if (snapshot.docs.length <
          pageSize) {

        hasMoreBusinesses =
            false;
      }


      // ---------------------------------------------------------
      // FILTER AND CALCULATE DISTANCE
      // ---------------------------------------------------------

      final List<Map<String, dynamic>>
          newBusinesses = [];


      for (final document
          in snapshot.docs) {

        final Map<String, dynamic> data =
            document.data();


        // -------------------------------------------------------
        // BUSINESS LOCATION
        // -------------------------------------------------------
        //
        // This expects the business document to contain:
        //
        // latitude
        // longitude
        //
        // OR later we can use GeoPoint.
        //
        // -------------------------------------------------------

        final dynamic latitudeValue =
            data['latitude'];

        final dynamic longitudeValue =
            data['longitude'];


        if (latitudeValue == null ||
            longitudeValue == null) {

          // Skip businesses without location.
          continue;
        }


        final double latitude =
            (latitudeValue as num)
                .toDouble();

        final double longitude =
            (longitudeValue as num)
                .toDouble();


        // -------------------------------------------------------
        // CALCULATE DISTANCE
        // -------------------------------------------------------

        final double distanceMeters =
            Geolocator.distanceBetween(

          userPosition!.latitude,

          userPosition!.longitude,

          latitude,

          longitude,
        );


        final double distanceKm =
            distanceMeters / 1000;


        // -------------------------------------------------------
        // MAXIMUM 50 KM FILTER
        // -------------------------------------------------------

        if (distanceKm >
            maxSearchRadiusKm) {

          continue;
        }


        // -------------------------------------------------------
        // ADD BUSINESS
        // -------------------------------------------------------

        newBusinesses.add({

          'id':
              document.id,

          'username':
              data['username'] ??
                  '',

          'companyName':
              data['companyName'] ??
                  '',

          'category':
              data['category'] ??
                  '',

          'mobileNumber':
              data['mobileNumber'] ??
                  '',

          'latitude':
              latitude,

          'longitude':
              longitude,

          'distanceKm':
              distanceKm,

          'isActive':
              data['isActive'] ??
                  true,
        });
      }


      // ---------------------------------------------------------
      // SORT NEAREST TO FARTHEST
      // ---------------------------------------------------------

      newBusinesses.sort(
        (
          a,
          b,
        ) {

          final double distanceA =
              a['distanceKm'] as double;

          final double distanceB =
              b['distanceKm'] as double;

          return distanceA.compareTo(
            distanceB,
          );
        },
      );


      if (!mounted) {
        return;
      }


      // ---------------------------------------------------------
      // ADD RESULTS
      // ---------------------------------------------------------

      setState(() {

        businesses.addAll(
          newBusinesses,
        );


        // -------------------------------------------------------
        // SORT COMPLETE LIST AGAIN
        // -------------------------------------------------------

        businesses.sort(
          (
            a,
            b,
          ) {

            final double distanceA =
                a['distanceKm'] as double;

            final double distanceB =
                b['distanceKm'] as double;

            return distanceA.compareTo(
              distanceB,
            );
          },
        );


        isLoading = false;

        isLoadingMore = false;
      });


    } catch (e) {

      if (!mounted) {
        return;
      }


      setState(() {

        isLoading = false;

        isLoadingMore = false;
      });


      showMessage(
        'Unable to load businesses. Please try again.',
      );
    }
  }

// =============================================================
  // HANDLE BUSINESS TAP
  // =============================================================

  void handleBusinessTap(
    Map<String, dynamic> business,
  ) {

    final double distanceKm =
        business['distanceKm'] as double;


    // -----------------------------------------------------------
    // CHECK PAID RADIUS
    // -----------------------------------------------------------

    if (distanceKm <= paidRadiusKm) {

      // ---------------------------------------------------------
      // INSIDE PAID RADIUS
      // ---------------------------------------------------------
      //
      // USER CAN OPEN PROFILE
      //
      // ---------------------------------------------------------

      openBusinessProfile(
        business,
      );

    } else {

      // ---------------------------------------------------------
      // OUTSIDE PAID RADIUS
      // ---------------------------------------------------------

      showIncreaseRadiusDialog(
        business,
      );
    }
  }


  // =============================================================
  // OPEN BUSINESS PROFILE
  // =============================================================

  void openBusinessProfile(
    Map<String, dynamic> business,
  ) {

    // -----------------------------------------------------------
    // PART OF NEXT SCREEN FLOW
    // -----------------------------------------------------------
    //
    // Later we will create:
    //
    // screen_self_business_profile.dart
    //
    // Example:
    //
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) =>
    //       ScreenSelfBusinessProfile(
    //         businessId: business['id'],
    //       ),
    //   ),
    // );
    //
    // -----------------------------------------------------------

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content:
            Text(
          'Opening ${business['username']}',
        ),

        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            green,
      ),
    );
  }


  // =============================================================
  // SHOW INCREASE RADIUS DIALOG
  // =============================================================

  void showIncreaseRadiusDialog(
    Map<String, dynamic> business,
  ) {

    final double distanceKm =
        business['distanceKm'] as double;


    showDialog(

      context: context,

      builder:
          (BuildContext dialogContext) {

        return AlertDialog(

          shape:
              RoundedRectangleBorder(

            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),


          // =====================================================
          // TITLE
          // =====================================================

          title:
              const Row(

            children: [

              Icon(

                Icons.lock_outline_rounded,

                color:
                    orange,

                size:
                    28,
              ),

              SizedBox(
                width:
                    10,
              ),

              Expanded(

                child:
                    Text(

                  'Increase Search Radius',

                  style:
                      TextStyle(

                    fontSize:
                        19,

                    fontWeight:
                        FontWeight.w800,

                    color:
                        darkGreen,
                  ),
                ),
              ),
            ],
          ),


          // =====================================================
          // CONTENT
          // =====================================================

          content:
              Column(

            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(

                'Your current access radius is '
                '${paidRadiusKm.toStringAsFixed(0)} KM.',

                style:
                    const TextStyle(

                  fontSize:
                      15,

                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height:
                    12,
              ),

              Text(

                '${business['username']} is '
                '${distanceKm.toStringAsFixed(1)} KM away.',

                style:
                    const TextStyle(
                  fontSize:
                      15,
                ),
              ),

              const SizedBox(
                height:
                    12,
              ),

              const Text(

                'Increase your search radius to continue.',

                style:
                    TextStyle(

                  color:
                      Colors.grey,

                  fontSize:
                      14,
                ),
              ),
            ],
          ),


          // =====================================================
          // BUTTONS
          // =====================================================

          actions: [

            TextButton(

              onPressed:
                  () {

                Navigator.pop(
                  dialogContext,
                );
              },

              child:
                  const Text(

                'CANCEL',

                style:
                    TextStyle(

                  color:
                      Colors.grey,

                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),


            ElevatedButton(

              onPressed:
                  () {

                Navigator.pop(
                  dialogContext,
                );

                openIncreaseRadiusScreen(
                  distanceKm,
                );
              },

              style:
                  ElevatedButton.styleFrom(

                backgroundColor:
                    orange,

                foregroundColor:
                    Colors.white,

                elevation:
                    0,

                shape:
                    RoundedRectangleBorder(

                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),

              child:
                  const Text(

                'INCREASE KM',

                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  // =============================================================
  // OPEN INCREASE RADIUS SCREEN
  // =============================================================

  void openIncreaseRadiusScreen(
    double requiredDistanceKm,
  ) {

    // -----------------------------------------------------------
    // PAYMENT SCREEN
    // -----------------------------------------------------------
    //
    // Later we can create:
    //
    // screen_increase_self_business_radius.dart
    //
    // The screen will receive:
    //
    // Current Radius
    // Required Radius
    //
    // Example:
    //
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) =>
    //       ScreenIncreaseSelfBusinessRadius(
    //         currentRadiusKm: paidRadiusKm,
    //         requiredRadiusKm:
    //             requiredDistanceKm,
    //       ),
    //   ),
    // ).then((newRadius) {
    //
    //   if (newRadius != null) {
    //
    //     setState(() {
    //       paidRadiusKm = newRadius;
    //     });
    //   }
    // });
    //
    // -----------------------------------------------------------

    showMessage(
      'Payment screen will open to increase your KM radius.',
    );
  }


  // =============================================================
  // REFRESH BUSINESSES
  // =============================================================

  Future<void>
      refreshBusinesses() async {

    await getUserCurrentLocation();

    if (userPosition == null) {
      return;
    }

    await loadBusinesses(
      refresh: true,
    );
  }


  // =============================================================
  // SHOW MESSAGE
  // =============================================================

  void showMessage(
    String message,
  ) {

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content:
            Text(
          message,
        ),

        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }


  // =============================================================
  // BUILD BUSINESS CARD
  // =============================================================

  Widget buildBusinessCard(
    Map<String, dynamic> business,
  ) {

    final double distanceKm =
        business['distanceKm'] as double;


    final bool canAccess =
        distanceKm <= paidRadiusKm;


    final String username =
        business['username']?.toString() ??
            'Individual Sellers';


    final String companyName =
        business['companyName']?.toString() ??
            '';


    return Material(

      color:
          Colors.transparent,

      child:
          InkWell(

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        onTap:
            () {

          handleBusinessTap(
            business,
          );
        },

        child:
            Ink(

          decoration:
              BoxDecoration(

            color:
                Colors.white,

            borderRadius:
                BorderRadius.circular(
              16,
            ),

            border:
                Border.all(

              color:
                  canAccess
                      ? borderColor
                      : orange.withValues(
                          alpha:
                              0.40,
                        ),
            ),
          ),

          child:
              Padding(

            padding:
                const EdgeInsets.all(
              16,
            ),

            child:
                Row(

              children: [

                // =================================================
                // BUSINESS ICON
                // =================================================

                Container(

                  width:
                      58,

                  height:
                      58,

                  decoration:
                      BoxDecoration(

                    color:
                        canAccess

                            ? green.withValues(
                                alpha:
                                    0.10,
                              )

                            : orange.withValues(
                                alpha:
                                    0.10,
                              ),

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),

                  child:
                      Icon(

                    Icons
                        .storefront_rounded,

                    color:
                        canAccess
                            ? green
                            : orange,

                    size:
                        30,
                  ),
                ),

                const SizedBox(
                  width:
                      14,
                ),


                // =================================================
                // BUSINESS INFORMATION
                // =================================================

                Expanded(

                  child:
                      Column(

                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      Text(

                        companyName.isNotEmpty
                            ? companyName
                            : username,

                        maxLines:
                            1,

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            const TextStyle(

                          fontSize:
                              17,

                          fontWeight:
                              FontWeight.w800,

                          color:
                              darkGreen,
                        ),
                      ),

                      const SizedBox(
                        height:
                            5,
                      ),

                      Text(

                        widget.category,

                        style:
                            const TextStyle(

                          fontSize:
                              13,

                          color:
                              Colors.grey,
                        ),
                      ),

                      const SizedBox(
                        height:
                            10,
                      ),


                      // =============================================
                      // DISTANCE
                      // =============================================

                      Row(

                        children: [

                          Icon(

                            Icons
                                .location_on_outlined,

                            size:
                                17,

                            color:
                                canAccess
                                    ? green
                                    : orange,
                          ),

                          const SizedBox(
                            width:
                                5,
                          ),

                          Text(

                            '${distanceKm.toStringAsFixed(1)} KM away',

                            style:
                                TextStyle(

                              fontSize:
                                  13,

                              fontWeight:
                                  FontWeight.w700,

                              color:
                                  canAccess
                                      ? darkGreen
                                      : orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),


                // =================================================
                // ACCESS STATUS
                // =================================================

                Column(

                  children: [

                    Icon(

                      canAccess

                          ? Icons
                              .lock_open_rounded

                          : Icons
                              .lock_outline_rounded,

                      color:
                          canAccess
                              ? green
                              : orange,

                      size:
                          24,
                    ),

                    const SizedBox(
                      height:
                          6,
                    ),

                    Text(

                      canAccess
                          ? 'OPEN'
                          : 'LOCKED',

                      style:
                          TextStyle(

                        fontSize:
                            10,

                        fontWeight:
                            FontWeight.w800,

                        color:
                            canAccess
                                ? green
                                : orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// =============================================================
  // BUILD LOCATION ERROR
  // =============================================================

  Widget buildLocationError() {

    return Center(

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

            Icon(

              Icons
                  .location_off_rounded,

              size:
                  70,

              color:
                  Colors.red.shade300,
            ),

            const SizedBox(
              height:
                  18,
            ),

            const Text(

              'Location Required',

              style:
                  TextStyle(

                fontSize:
                    21,

                fontWeight:
                    FontWeight.w800,

                color:
                    darkGreen,
              ),
            ),

            const SizedBox(
              height:
                  10,
            ),

            Text(

              locationError ??
                  'Unable to get your current location.',

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(

                color:
                    Colors.grey,

                fontSize:
                    14,
              ),
            ),

            const SizedBox(
              height:
                  22,
            ),

            ElevatedButton.icon(

              onPressed:
                  initializeScreen,

              icon:
                  const Icon(
                Icons.refresh,
              ),

              label:
                  const Text(
                'TRY AGAIN',
              ),

              style:
                  ElevatedButton.styleFrom(

                backgroundColor:
                    green,

                foregroundColor:
                    Colors.white,

                shape:
                    RoundedRectangleBorder(

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // =============================================================
  // BUILD EMPTY BUSINESSES
  // =============================================================

  Widget buildEmptyBusinesses() {

    return Center(

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

            Icon(

              Icons
                  .storefront_outlined,

              size:
                  70,

              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(
              height:
                  18,
            ),

            const Text(

              'No Businesses Found',

              style:
                  TextStyle(

                fontSize:
                    21,

                fontWeight:
                    FontWeight.w800,

                color:
                    darkGreen,
              ),
            ),

            const SizedBox(
              height:
                  10,
            ),

            Text(

              'No ${widget.category} businesses were found within 50 KM of your current location.',

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(

                color:
                    Colors.grey,

                fontSize:
                    14,
              ),
            ),

            const SizedBox(
              height:
                  22,
            ),

            OutlinedButton.icon(

              onPressed:
                  refreshBusinesses,

              icon:
                  const Icon(
                Icons.refresh,
              ),

              label:
                  const Text(
                'REFRESH',
              ),

              style:
                  OutlinedButton.styleFrom(

                foregroundColor:
                    green,

                side:
                    const BorderSide(
                  color:
                      green,
                ),

                shape:
                    RoundedRectangleBorder(

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // =============================================================
  // BUILD PAGINATION LOADER
  // =============================================================

  Widget buildPaginationLoader() {

    if (isLoadingMore) {

      return const Padding(

        padding:
            EdgeInsets.all(
          20,
        ),

        child:
            Center(

          child:
              Column(

            children: [

              SizedBox(

                width:
                    26,

                height:
                    26,

                child:
                    CircularProgressIndicator(

                  strokeWidth:
                      2.5,

                  color:
                      green,
                ),
              ),

              SizedBox(
                height:
                    10,
              ),

              Text(
                'Loading more businesses...',
              ),
            ],
          ),
        ),
      );
    }


    if (!hasMoreBusinesses &&
        businesses.isNotEmpty) {

      return const Padding(

        padding:
            EdgeInsets.all(
          25,
        ),

        child:
            Center(

          child:
              Text(

            'No more businesses',

            style:
                TextStyle(

              color:
                  Colors.grey,

              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),
      );
    }


    return const SizedBox(
      height:
          10,
    );
  }


  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(
    BuildContext context,
  ) {

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

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Text(

              widget.category,

              style:
                  const TextStyle(

                fontSize:
                    18,

                fontWeight:
                    FontWeight.w800,

                color:
                    darkGreen,
              ),
            ),

            Text(

              'Businesses within 50 KM',

              style:
                  TextStyle(

                fontSize:
                    12,

                color:
                    Colors.grey.shade600,
              ),
            ),
          ],
        ),


        // =======================================================
        // REFRESH BUTTON
        // =======================================================

        actions: [

          IconButton(

            onPressed:
                refreshBusinesses,

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),

            tooltip:
                'Refresh businesses',
          ),
        ],
      ),


      // =========================================================
      // BODY
      // =========================================================

      body:
          SafeArea(

        child:

            // ===================================================
            // LOCATION ERROR
            // ===================================================

            locationError != null

                ? buildLocationError()


                // =================================================
                // INITIAL LOADING
                // =================================================

                : isLoading

                    ? const Center(

                        child:
                            CircularProgressIndicator(
                          color:
                              green,
                        ),
                      )


                    // =============================================
                    // EMPTY RESULT
                    // =============================================

                    : businesses.isEmpty

                        ? buildEmptyBusinesses()


                        // =========================================
                        // BUSINESS LIST
                        // =========================================

                        : RefreshIndicator(

                            color:
                                green,

                            onRefresh:
                                refreshBusinesses,

                            child:
                                Column(

                              children: [

                                // =================================
                                // PAID RADIUS INFO
                                // =================================

                                Container(

                                  width:
                                      double.infinity,

                                  margin:
                                      const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    8,
                                  ),

                                  padding:
                                      const EdgeInsets.all(
                                    14,
                                  ),

                                  decoration:
                                      BoxDecoration(

                                    color:
                                        green.withValues(
                                      alpha:
                                          0.08,
                                    ),

                                    borderRadius:
                                        BorderRadius.circular(
                                      14,
                                    ),

                                    border:
                                        Border.all(

                                      color:
                                          green.withValues(
                                        alpha:
                                            0.25,
                                      ),
                                    ),
                                  ),

                                  child:
                                      Row(

                                    children: [

                                      const Icon(

                                        Icons
                                            .verified_user_outlined,

                                        color:
                                            green,
                                      ),

                                      const SizedBox(
                                        width:
                                            10,
                                      ),

                                      Expanded(

                                        child:
                                            Column(

                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,

                                          children: [

                                            const Text(

                                              'Your Access Radius',

                                              style:
                                                  TextStyle(

                                                fontSize:
                                                    12,

                                                color:
                                                    Colors.grey,
                                              ),
                                            ),

                                            const SizedBox(
                                              height:
                                                  3,
                                            ),

                                            Text(

                                              '${paidRadiusKm.toStringAsFixed(0)} KM',

                                              style:
                                                  const TextStyle(

                                                fontSize:
                                                    19,

                                                fontWeight:
                                                    FontWeight.w800,

                                                color:
                                                    darkGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Container(

                                        padding:
                                            const EdgeInsets.symmetric(

                                          horizontal:
                                              10,

                                          vertical:
                                              6,
                                        ),

                                        decoration:
                                            BoxDecoration(

                                          color:
                                              orange.withValues(
                                            alpha:
                                                0.12,
                                          ),

                                          borderRadius:
                                              BorderRadius.circular(
                                            20,
                                          ),
                                        ),

                                        child:
                                            const Text(

                                          'UP TO 50 KM',

                                          style:
                                              TextStyle(

                                            color:
                                                orange,

                                            fontSize:
                                                10,

                                            fontWeight:
                                                FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),


                                // =================================
                                // RESULT INFO
                                // =================================

                                Padding(

                                  padding:
                                      const EdgeInsets.fromLTRB(
                                    20,
                                    10,
                                    20,
                                    10,
                                  ),

                                  child:
                                      Row(

                                    children: [

                                      Text(

                                        '${businesses.length} businesses loaded',

                                        style:
                                            const TextStyle(

                                          fontSize:
                                              13,

                                          fontWeight:
                                              FontWeight.w600,

                                          color:
                                              darkGreen,
                                        ),
                                      ),

                                      const Spacer(),

                                      const Icon(

                                        Icons
                                            .sort_rounded,

                                        size:
                                            17,

                                        color:
                                            green,
                                      ),

                                      const SizedBox(
                                        width:
                                            5,
                                      ),

                                      const Text(

                                        'Nearest first',

                                        style:
                                            TextStyle(

                                          fontSize:
                                              12,

                                          color:
                                              Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),


                                // =================================
                                // BUSINESS LIST
                                // =================================

                                Expanded(

                                  child:
                                      ListView.builder(

                                    controller:
                                        scrollController,

                                    physics:
                                        const AlwaysScrollableScrollPhysics(),

                                    padding:
                                        const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      20,
                                    ),

                                    itemCount:
                                        businesses.length + 1,

                                    itemBuilder:
                                        (
                                          context,
                                          index,
                                        ) {

                                      // ===========================
                                      // PAGINATION LOADER
                                      // ===========================

                                      if (index ==
                                          businesses.length) {

                                        return buildPaginationLoader();
                                      }


                                      // ===========================
                                      // BUSINESS CARD
                                      // ===========================

                                      final Map<String, dynamic>
                                          business =
                                          businesses[
                                              index];


                                      return Padding(

                                        padding:
                                            const EdgeInsets.only(
                                          bottom:
                                              10,
                                        ),

                                        child:
                                            buildBusinessCard(
                                          business,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
      ),
    );
  }


  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {

    scrollController
        .removeListener(
      handleScroll,
    );

    scrollController.dispose();

    super.dispose();
  }
}