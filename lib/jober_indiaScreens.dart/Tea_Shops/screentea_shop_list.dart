import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:jober_india/jober_indiaScreens.dart/Tea_Shops/screen_tea_shop_profile.dart';


// ============================================================
// TEA SHOP LIST SCREEN
// ============================================================

class ScreenTeaShopList
    extends StatefulWidget {

  final String selectedCategory;

  const ScreenTeaShopList({
    super.key,
    required this.selectedCategory,
  });

  @override
  State<ScreenTeaShopList>
      createState() =>
          _ScreenTeaShopListState();
}

// =========================================================
// STATE
// ========================================================

class _ScreenTeaShopListState
    extends State<ScreenTeaShopList> {

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color darkGreen =
      Color(0xFF12652F);

  static const Color green =
      Color(0xFF138808);

  static const Color orange =
      Color(0xFFED801D);

  static const Color background =
      Color(0xFFF8F8F8);


  // ==========================================================
  // FIRESTORE
  // ==========================================================

  final FirebaseFirestore
      firestore =
      FirebaseFirestore.instance;


  // ==========================================================
  // SETTINGS
  // ==========================================================
// ==========================================================
// USER DISTANCE SUBSCRIPTION
// ==========================================================

double paidDistance = 1.0;

DateTime? paymentExpiry;

bool isLoadingPayment = true;

// The subscription radius is valid only before expiry.
// Without an active subscription, the free radius is 1 KM.
double get profileRadiusKm {
  if (paymentExpiry != null &&
      DateTime.now().isBefore(paymentExpiry!)) {
    return paidDistance;
  }

  return 1.0;
}

bool get hasActiveSubscription {
  return paymentExpiry != null &&
      DateTime.now().isBefore(paymentExpiry!);
}
  // Maximum distance visible in the list

  static const double
      maximumRadiusKm = 50;


  // Number of shops loaded per Firestore request

  static const int
      shopsPerPage = 20;


  // ==========================================================
  // USER LOCATION
  // ==========================================================

  Position?
      currentPosition;

  bool isGettingLocation = false;

  bool locationPermissionDenied = false;


  // ==========================================================
  // SHOP DATA
  // ==========================================================

  List<Map<String, dynamic>>
      shops = [];


  // ==========================================================
  // LOADING STATES
  // ==========================================================

  bool isLoading = false;

  bool isLoadingMore = false;

  bool hasMoreShops = true;

  String?
      errorMessage;


  // ==========================================================
  // PAGINATION
  // ==========================================================

  DocumentSnapshot<
      Map<String, dynamic>>?
      lastShopDocument;


  // ==========================================================
  // SCROLL CONTROLLER
  // ==========================================================

  final ScrollController
      scrollController =
      ScrollController();


  // ==========================================================
  // INIT STATE
  // ==========================================================

  @override
  void initState() {

    super.initState();


    // --------------------------------------------------------
    // SCROLL LISTENER
    // --------------------------------------------------------

    scrollController.addListener(
      onScroll,
    );


    // --------------------------------------------------------
    // GET LOCATION AND LOAD SHOPS
    // --------------------------------------------------------

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {

        initializeScreen();
      },
    );
  }


  Future<void> initializeScreen() async {
  await loadPaymentData();

  if (!mounted) return;

  await getCurrentLocation();

  if (currentPosition != null && mounted) {
    await loadShops();
  }
}

// ==========================================================
// LOAD PAYMENT DATA FROM HIVE
// ==========================================================

Future<void> loadPaymentData() async {
  try {
    final box = Hive.box('settings');

    // Use the subscription keys from activateSubscription().
    // The fallback keys support the older payForDistance().
    final savedDistance =
        box.get('activeDistance') ??
        box.get('paidDistance');

    final savedExpiry =
        box.get('subscriptionExpiry') ??
        box.get('paymentExpiry');

    final loadedDistance = savedDistance is num
        ? savedDistance.toDouble()
        : 1.0;

    final loadedExpiry = savedExpiry == null
        ? null
        : DateTime.tryParse(savedExpiry.toString());

    final isValid = loadedExpiry != null &&
        DateTime.now().isBefore(loadedExpiry) &&
        loadedDistance >= 1;

    if (isValid) {
      paidDistance = loadedDistance;
      paymentExpiry = loadedExpiry;
    } else {
      paidDistance = 1.0;
      paymentExpiry = null;

      // Clear expired or invalid subscription details.
      await box.delete('activeDistance');
      await box.delete('subscriptionStart');
      await box.delete('subscriptionExpiry');
      await box.delete('subscriptionDuration');
      await box.delete('subscriptionPaidAmount');
      await box.delete('subscriptionActive');

      // Also clear the legacy keys.
      await box.delete('paidDistance');
      await box.delete('paymentExpiry');
    }
  } catch (e) {
    debugPrint('Tea shop payment data error: $e');

    // If payment data cannot be read, use the safe free radius.
    paidDistance = 1.0;
    paymentExpiry = null;
  } finally {
    if (mounted) {
      setState(() {
        isLoadingPayment = false;
      });
    }
  }
}

  // ==========================================================
  // SCROLL
  //
  // Loads more shops when user reaches near the bottom.
  // ==========================================================

  void onScroll() {

    if (!scrollController.hasClients) {
      return;
    }


    final position =
        scrollController.position;


    if (position.pixels >=
        position.maxScrollExtent - 300) {

      if (!isLoadingMore &&
          !isLoading &&
          hasMoreShops) {

        loadShops(
          loadMore: true,
        );
      }
    }
  }


  // ==========================================================
  // GET CURRENT LOCATION
  // ==========================================================

  Future<void> getCurrentLocation() async {

    if (isGettingLocation) {
      return;
    }


    if (mounted) {

      setState(() {

        isGettingLocation = true;

        locationPermissionDenied = false;

        errorMessage = null;
      });
    }


    try {

      // ------------------------------------------------------
      // CHECK LOCATION SERVICE
      // ------------------------------------------------------

      final serviceEnabled =
          await Geolocator
              .isLocationServiceEnabled();


      if (!serviceEnabled) {

        if (mounted) {

          setState(() {

            errorMessage =
                'Please turn on your location service.';
          });
        }


        await Geolocator
            .openLocationSettings();

        return;
      }


      // ------------------------------------------------------
      // CHECK LOCATION PERMISSION
      // ------------------------------------------------------

      LocationPermission permission =
          await Geolocator
              .checkPermission();


      // ------------------------------------------------------
      // REQUEST PERMISSION
      // ------------------------------------------------------

      if (permission ==
          LocationPermission.denied) {

        permission =
            await Geolocator
                .requestPermission();
      }


      // ------------------------------------------------------
      // DENIED
      // ------------------------------------------------------

      if (permission ==
          LocationPermission.denied) {

        if (!mounted) {
          return;
        }


        setState(() {

          locationPermissionDenied =
              true;

          errorMessage =
              'Location permission is required to find nearby shops.';
        });

        return;
      }


      // ------------------------------------------------------
      // DENIED FOREVER
      // ------------------------------------------------------

      if (permission ==
          LocationPermission.deniedForever) {

        if (!mounted) {
          return;
        }


        setState(() {

          locationPermissionDenied =
              true;

          errorMessage =
              'Location permission is permanently denied. '
              'Please enable it in Settings.';
        });

        return;
      }


      // ------------------------------------------------------
      // GET LOCATION
      // ------------------------------------------------------

      final position =
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

        currentPosition =
            position;

        errorMessage =
            null;
      });

    } catch (e) {

      debugPrint(
        'Tea shop location error: $e',
      );


      if (!mounted) {
        return;
      }


      setState(() {

        errorMessage =
            'Unable to get your current location.';
      });

    } finally {

      if (mounted) {

        setState(() {

          isGettingLocation =
              false;
        });
      }
    }
  }


  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {

    scrollController.dispose();

    super.dispose();
  }

  // ==========================================================
  // LOAD SHOPS
  //
  // Loads only shops from the selected category.
  //
  // Firestore collection:
  //
  // teaShops
  //
  // Required fields:
  //
  // username
  // shopName
  // mobileNumber
  // category
  // latitude
  // longitude
  // ==========================================================

  Future<void> loadShops({
    bool loadMore = false,
  }) async {

    // --------------------------------------------------------
    // LOCATION MUST BE AVAILABLE
    // --------------------------------------------------------

    if (currentPosition == null) {
      return;
    }


    // --------------------------------------------------------
    // PREVENT MULTIPLE REQUESTS
    // --------------------------------------------------------

    if (isLoading ||
        isLoadingMore) {
      return;
    }


    // --------------------------------------------------------
    // NO MORE DATA
    // --------------------------------------------------------

    if (loadMore &&
        !hasMoreShops) {
      return;
    }


    // --------------------------------------------------------
    // LOADING STATE
    // --------------------------------------------------------

    if (mounted) {

      setState(() {

        if (loadMore) {

          isLoadingMore =
              true;

        } else {

          isLoading =
              true;

          errorMessage =
              null;

          shops = [];

          lastShopDocument =
              null;

          hasMoreShops =
              true;
        }
      });
    }


    try {

      // ------------------------------------------------------
      // FIRESTORE QUERY
      // ------------------------------------------------------

    // ======================================================
// FIRESTORE QUERY
// Use the SAME collection as the category count.
// ======================================================

Query<Map<String, dynamic>> query = firestore
    .collection('tea_shops')
    .where('isOnline', isEqualTo: true)
    .limit(shopsPerPage);

// ======================================================
// PAGINATION
// ======================================================

if (loadMore && lastShopDocument != null) {
  query = query.startAfterDocument(lastShopDocument!);
}


      // ------------------------------------------------------
      // GET FIRESTORE DATA
      // ------------------------------------------------------

      final snapshot =
          await query.get();


      // ------------------------------------------------------
      // SAVE LAST DOCUMENT
      // ------------------------------------------------------

      if (snapshot.docs.isNotEmpty) {

        lastShopDocument =
            snapshot.docs.last;
      }


      // ------------------------------------------------------
      // NO MORE DATA
      // ------------------------------------------------------

      if (snapshot.docs.length <
          shopsPerPage) {

        hasMoreShops =
            false;
      }


      // ------------------------------------------------------
      // PROCESS SHOPS
      // ------------------------------------------------------

      final List<Map<String, dynamic>>
          newShops = [];


      for (final document
          in snapshot.docs) {

        final data = document.data();

// ======================================================
// MATCH THE SELECTED CATEGORY
// Supports both `categories` List and legacy `category`.
// ======================================================

final dynamic savedCategories = data['categories'];

final List<String> shopCategories;

if (savedCategories is List) {
  shopCategories = savedCategories
      .map((value) => value.toString().trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toList();
} else {
  shopCategories = (data['category'] ?? '')
      .toString()
      .split(',')
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toList();
}

if (!shopCategories.contains(
  widget.selectedCategory.trim().toLowerCase(),
)) {
  continue;
}

        final dynamic savedLocation = data['location'];

double? latitude =
    (data['latitude'] as num?)?.toDouble();

double? longitude =
    (data['longitude'] as num?)?.toDouble();

if (savedLocation is GeoPoint) {
  latitude ??= savedLocation.latitude;
  longitude ??= savedLocation.longitude;
} else if (savedLocation is Map) {
  final dynamic savedLat =
      savedLocation['latitude'] ?? savedLocation['lat'];

  final dynamic savedLng =
      savedLocation['longitude'] ?? savedLocation['lng'];

  if (savedLat is num) {
    latitude ??= savedLat.toDouble();
  }

  if (savedLng is num) {
    longitude ??= savedLng.toDouble();
  }
}


        // ----------------------------------------------------
        // SKIP SHOPS WITHOUT LOCATION
        // ----------------------------------------------------

        if (latitude == null ||
            longitude == null) {

          continue;
        }


        // ----------------------------------------------------
        // CALCULATE DISTANCE
        // ----------------------------------------------------

        final distanceInMeters =
            Geolocator.distanceBetween(

          currentPosition!.latitude,

          currentPosition!.longitude,

          latitude,

          longitude,
        );


        final distanceInKm =
            distanceInMeters /
                1000;


        // ----------------------------------------------------
        // ONLY SHOW SHOPS WITHIN 50 KM
        // ----------------------------------------------------

        if (distanceInKm >
            maximumRadiusKm) {

          continue;
        }


        // ----------------------------------------------------
        // CREATE SHOP DATA
        // ----------------------------------------------------

        newShops.add({

          // Firestore document ID

          'id':
              document.id,


          // Shop details

          'username':
              data['username'] ??
                  '',

          'shopName':
              data['shopName'] ??
                  '',

          'category':
              data['category'] ??
                  '',


          // Location

          'latitude':
              latitude,

          'longitude':
              longitude,


          // Calculated distance

          'distanceKm':
              distanceInKm,
        });
      }


      // ------------------------------------------------------
      // ADD SHOPS
      // ------------------------------------------------------

      if (!mounted) {
        return;
      }


      setState(() {

        shops.addAll(
          newShops,
        );


        // ----------------------------------------------------
        // SORT NEAREST TO FARTHEST
        // ----------------------------------------------------

        shops.sort(
          (a, b) {

            final distanceA =
                (a['distanceKm'] as num)
                    .toDouble();

            final distanceB =
                (b['distanceKm'] as num)
                    .toDouble();


            return distanceA.compareTo(
              distanceB,
            );
          },
        );
      });

    } on FirebaseException catch (e) {

      debugPrint(
        'Firestore error: '
        '${e.code} ${e.message}',
      );


      if (!mounted) {
        return;
      }


      setState(() {

        errorMessage =
            'Unable to load nearby shops. '
            'Please try again.';
      });

    } catch (e) {

      debugPrint(
        'Tea shop loading error: $e',
      );


      if (!mounted) {
        return;
      }


      setState(() {

        errorMessage =
            'Something went wrong while loading shops.';
      });

    } finally {

      if (mounted) {

        setState(() {

          isLoading =
              false;

          isLoadingMore =
              false;
        });
      }
    }
  }


  // ==========================================================
  // REFRESH SHOPS
  // ==========================================================

  Future<void> refreshShops() async {

    await getCurrentLocation();


    if (currentPosition != null) {

      lastShopDocument =
          null;

      hasMoreShops =
          true;

      await loadShops();
    }
  }


Future<void> openShop(
  Map<String, dynamic> shop,
) async {
  final double distanceKm =
      (shop['distanceKm'] as num).toDouble();

  final double allowedRadius = profileRadiusKm;

  // Check the user's allowed distance.
  if (distanceKm > allowedRadius) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Distance limit',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            hasActiveSubscription
                ? 'Your active subscription allows you to open '
                    'shop profiles within '
                    '${allowedRadius.toStringAsFixed(0)} km. '
                    'This shop is ${distanceKm.toStringAsFixed(1)} km away.'
                : 'Your free access allows you to open shop '
                    'profiles within 1 km. This shop is '
                    '${distanceKm.toStringAsFixed(1)} km away. '
                    'Unlock a distance plan to access shops farther away.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    return;
  }

  // Open the selected Tea Shop profile.
  final String shopId =
      (shop['id'] ?? '').toString();

  if (shopId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shop ID is not available.'),
      ),
    );
    return;
  }

  try {
    // Get the complete, latest profile data from Firestore.
    final document = await firestore
        .collection('tea_shops')
        .doc(shopId)
        .get();

    if (!mounted) return;

    if (!document.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This Tea Shop profile was not found.'),
        ),
      );
      return;
    }

    final Map<String, dynamic> fullShopData =
        document.data()!;

    // Pass the Firestore document ID and complete data.
    fullShopData['id'] = document.id;
    fullShopData['shopId'] = document.id;

    // Open the profile page.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenTeaShopProfile(
          shopData: fullShopData,
          userLatitude: currentPosition?.latitude,
          userLongitude: currentPosition?.longitude,
        ),
      ),
    );
  } catch (e) {
    debugPrint('Error opening Tea Shop profile: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open this Tea Shop profile.'),
      ),
    );
  }
}


  // ==========================================================
  // FORMAT DISTANCE
  // ==========================================================

  String formatDistance(
    double distanceKm,
  ) {

    if (distanceKm < 1) {

      final meters =
          (distanceKm * 1000)
              .round();

      return '$meters m away';
    }


    return '${distanceKm.toStringAsFixed(1)} km away';
  }
  // ==========================================================
  // SHOP CARD
  // ==========================================================

  Widget shopCard(
    Map<String, dynamic> shop,
  ) {

    final String shopName =
        shop['shopName']
            .toString();

    final String category =
        shop['category']
            .toString();

    final double distanceKm =
        (shop['distanceKm'] as num)
            .toDouble();


    return Container(

      margin:
          const EdgeInsets.only(
        left:
            16,
        right:
            16,
        bottom:
            12,
      ),

      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        boxShadow: [

          BoxShadow(

            color:
                Colors.black.withValues(
              alpha:
                  0.06,
            ),

            blurRadius:
                10,

            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child:
          Material(

        color:
            Colors.transparent,

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
              () {

            openShop(
              shop,
            );
          },

          child:
              Padding(

            padding:
                const EdgeInsets.all(
              16,
            ),

            child:
                Row(

              children: [

                // ==========================================
                // SHOP ICON
                // ==========================================

                Container(

                  width:
                      60,

                  height:
                      60,

                  decoration:
                      BoxDecoration(

                    color:
                        green.withValues(
                      alpha:
                          0.12,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),

                  child:
                      const Icon(

                    Icons.storefront,

                    color:
                        green,

                    size:
                        30,
                  ),
                ),


                const SizedBox(
                  width:
                      15,
                ),


                // ==========================================
                // SHOP DETAILS
                // ==========================================

                Expanded(

                  child:
                      Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(

                        shopName.isEmpty
                            ? 'Unnamed Shop'
                            : shopName,

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
                        ),
                      ),


                      const SizedBox(
                        height:
                            5,
                      ),


                      Text(

                        category,

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
                            8,
                      ),


                      // ------------------------------------
                      // DISTANCE
                      // ------------------------------------

                      Row(

                        children: [

                          const Icon(

                            Icons.location_on,

                            size:
                                16,

                            color:
                                orange,
                          ),


                          const SizedBox(
                            width:
                                4,
                          ),


                          Text(

                            formatDistance(
                              distanceKm,
                            ),

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
                        ],
                      ),
                    ],
                  ),
                ),


                // ==========================================
                // ARROW
                // ==========================================

                const Icon(

                  Icons.arrow_forward_ios,

                  size:
                      18,

                  color:
                      orange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ==========================================================
  // LOADING SCREEN
  // ==========================================================

  Widget loadingView() {

    return const Center(

      child:
          Column(

        mainAxisAlignment:
            MainAxisAlignment.center,

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
            'Finding nearby shops...',
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // ERROR SCREEN
  // ==========================================================

  Widget errorView() {

    return Center(

      child:
          Padding(

        padding:
            const EdgeInsets.all(
          30,
        ),

        child:
            Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            const Icon(

              Icons.location_off,

              size:
                  65,

              color:
                  Colors.grey,
            ),


            const SizedBox(
              height:
                  18,
            ),


            Text(

              errorMessage ??
                  'Something went wrong.',

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(

                fontSize:
                    16,

                color:
                    Colors.grey,
              ),
            ),


            const SizedBox(
              height:
                  20,
            ),


            ElevatedButton.icon(

              onPressed:
                  () {

                if (locationPermissionDenied) {

                  Geolocator.openAppSettings();

                } else {

                  refreshShops();
                }
              },

              icon:
                  const Icon(
                Icons.refresh,
              ),

              label:
                  const Text(
                'Try Again',
              ),

              style:
                  ElevatedButton.styleFrom(

                backgroundColor:
                    green,

                foregroundColor:
                    Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // EMPTY SHOP LIST
  // ==========================================================

  Widget emptyView() {

    return Center(

      child:
          Column(

        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          const Icon(

            Icons.store_mall_directory_outlined,

            size:
                70,

            color:
                Colors.grey,
          ),


          const SizedBox(
            height:
                18,
          ),


          Text(

            'No nearby ${widget.selectedCategory} found',

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(

              fontSize:
                  17,

              fontWeight:
                  FontWeight.w600,

              color:
                  Colors.grey,
            ),
          ),


          const SizedBox(
            height:
                8,
          ),


          const Text(

            'No shops were found within 50 km.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  Colors.grey,
            ),
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      backgroundColor:
          background,


      // ======================================================
      // APP BAR
      // ======================================================

      appBar:
          AppBar(

        backgroundColor:
            darkGreen,

        foregroundColor:
            Colors.white,

        elevation:
            0,

        centerTitle:
            true,

        title:
            Text(

          widget.selectedCategory,

          style:
              const TextStyle(

            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),


      // ======================================================
      // BODY
      // ======================================================

      body:
          Builder(

        builder:
            (context) {

          // --------------------------------------------------
          // LOADING
          // --------------------------------------------------

          if (isLoading &&
              shops.isEmpty) {

            return loadingView();
          }


          // --------------------------------------------------
          // ERROR
          // --------------------------------------------------

          if (errorMessage != null &&
              shops.isEmpty) {

            return errorView();
          }


          // --------------------------------------------------
          // EMPTY
          // --------------------------------------------------

          if (!isLoading &&
              shops.isEmpty) {

            return emptyView();
          }


          // --------------------------------------------------
          // SHOP LIST
          // --------------------------------------------------

          return RefreshIndicator(

            color:
                green,

            onRefresh:
                refreshShops,

            child:
                ListView.builder(

              controller:
                  scrollController,

              padding:
                  const EdgeInsets.only(
                top:
                    18,
                bottom:
                    30,
              ),

              itemCount:

                  shops.length +

                  (isLoadingMore
                      ? 1
                      : 0),

              itemBuilder:
                  (
                    context,
                    index,
                  ) {

                // ------------------------------------------
                // LOADING MORE
                // ------------------------------------------

                if (index >=
                    shops.length) {

                  return const Padding(

                    padding:
                        EdgeInsets.all(
                      20,
                    ),

                    child:
                        Center(

                      child:
                          CircularProgressIndicator(
                        color:
                            green,
                      ),
                    ),
                  );
                }


                // ------------------------------------------
                // SHOP CARD
                // ------------------------------------------

                final shop =
                    shops[index];


                return shopCard(
                  shop,
                );
              },
            ),
          );
        },
      ),
    );
  }
}