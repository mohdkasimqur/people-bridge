import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';


// ============================================================
// TEA SHOP PROFILE SCREEN
// ============================================================

class ScreenTeaShopProfile
    extends StatefulWidget {

  final Map<String, dynamic>
      shopData;

  final double?
      userLatitude;

  final double?
      userLongitude;


  const ScreenTeaShopProfile({
    super.key,
    required this.shopData,
    this.userLatitude,
    this.userLongitude,
  });


  @override
  State<ScreenTeaShopProfile>
      createState() =>
          _ScreenTeaShopProfileState();
}


// ============================================================
// STATE
// ============================================================

class _ScreenTeaShopProfileState
    extends State<ScreenTeaShopProfile> {

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
      Color(0xFFF7F7F7);


  bool isLoading = false;

  bool isCalling = false;

  bool isOpeningLocation = false;


  // ==========================================================
  // SHOP DATA
  // ==========================================================

  late Map<String, dynamic>
      shopData;


  // ==========================================================
  // SHOP DETAILS
  // ==========================================================

  String shopId = '';

  String username = '';

  String shopName = '';

  String category = '';

  String mobileNumber = '';

  double? latitude;

  double? longitude;

  double? distanceInKm;


  // ==========================================================
  // SHOP STATUS
  // ==========================================================

  bool isActive = true;

  bool locationAvailable = false;


  // ==========================================================
  // INIT STATE
  // ==========================================================

  @override
  void initState() {
    super.initState();

    shopData =
        Map<String, dynamic>.from(
      widget.shopData,
    );

    readShopData();
  }


  // ==========================================================
  // READ SHOP DATA
  // ==========================================================

  void readShopData() {

    // --------------------------------------------------------
    // SHOP ID
    // --------------------------------------------------------

    shopId =
        (shopData['shopId'] ??
                shopData['id'] ??
                shopData['uid'] ??
                '')
            .toString();


    // --------------------------------------------------------
    // USERNAME
    // --------------------------------------------------------

    username =
        (shopData['username'] ??
                shopData['ownerName'] ??
                '')
            .toString();


    // --------------------------------------------------------
    // SHOP NAME
    // --------------------------------------------------------

    shopName =
        (shopData['shopName'] ??
                shopData['name'] ??
                'Tea Shop')
            .toString();


    // --------------------------------------------------------
    // CATEGORY
    // --------------------------------------------------------

    category =
        (shopData['category'] ??
                'Tea Shops')
            .toString();


    // --------------------------------------------------------
    // MOBILE NUMBER
    //
    // IMPORTANT:
    // We use this internally for the Call button.
    // It will NOT be displayed on the screen.
    // --------------------------------------------------------

   // Use the secondary number provided during registration.
mobileNumber =
    (shopData['secondaryMobile'] ??
            shopData['secondaryPhone'] ??
            '')
        .toString()
        .trim();

    // --------------------------------------------------------
    // ACTIVE STATUS
    // --------------------------------------------------------

    final activeValue =
        shopData['isActive'];

    if (activeValue is bool) {

      isActive =
          activeValue;

    } else {

      isActive = true;
    }


    // --------------------------------------------------------
    // LOCATION
    // --------------------------------------------------------

    readLocationData();


    // --------------------------------------------------------
    // CALCULATE DISTANCE
    // --------------------------------------------------------

    calculateDistance();
  }


  // ==========================================================
  // READ LOCATION DATA
  // ==========================================================

  void readLocationData() {

    final location =
        shopData['location'];


    // --------------------------------------------------------
    // FIRESTORE GEOPOINT
    // --------------------------------------------------------

    if (location is GeoPoint) {

      latitude =
          location.latitude;

      longitude =
          location.longitude;

      locationAvailable =
          true;

      return;
    }


    // --------------------------------------------------------
    // LOCATION MAP
    // --------------------------------------------------------

    if (location is Map) {

      final map =
          Map<String, dynamic>.from(
        location,
      );


      final lat =
          map['latitude'] ??
              map['lat'];


      final lng =
          map['longitude'] ??
              map['lng'];


      if (lat != null &&
          lng != null) {

        latitude =
            (lat as num)
                .toDouble();

        longitude =
            (lng as num)
                .toDouble();

        locationAvailable =
            true;

        return;
      }
    }


    // --------------------------------------------------------
    // DIRECT LATITUDE / LONGITUDE
    // --------------------------------------------------------

    final lat =
        shopData['latitude'];

    final lng =
        shopData['longitude'];


    if (lat != null &&
        lng != null) {

      latitude =
          (lat as num)
              .toDouble();

      longitude =
          (lng as num)
              .toDouble();

      locationAvailable =
          true;

    } else {

      locationAvailable =
          false;
    }
  }


  // ==========================================================
  // CALCULATE DISTANCE
  // ==========================================================

  void calculateDistance() {

    if (widget.userLatitude == null ||
        widget.userLongitude == null ||
        latitude == null ||
        longitude == null) {

      distanceInKm = null;

      return;
    }


    final distanceInMeters =
        Geolocator.distanceBetween(

      widget.userLatitude!,
      widget.userLongitude!,

      latitude!,
      longitude!,
    );


    distanceInKm =
        distanceInMeters / 1000;
  }


  // ==========================================================
  // FORMAT DISTANCE
  // ==========================================================

  String get formattedDistance {

    if (distanceInKm == null) {
      return 'Distance unavailable';
    }


    if (distanceInKm! < 1) {

      final meters =
          (distanceInKm! * 1000)
              .round();

      return '$meters m away';
    }


    return '${distanceInKm!.toStringAsFixed(1)} km away';
  }


  // ==========================================================
  // CALL SHOP
  //
  // Phone number is NOT shown.
  // Only the Call button uses it.
  // ==========================================================

  Future<void> callShop() async {

    if (mobileNumber.trim().isEmpty) {

      showMessage(
        'Phone number is not available.',
      );

      return;
    }


    if (isCalling) {
      return;
    }


    setState(() {
      isCalling = true;
    });


    try {

      String phone =
          mobileNumber.trim();


      if (!phone.startsWith('+')) {

        if (phone.length == 10) {

          phone =
              '+91$phone';
        }
      }


      final Uri phoneUri =
          Uri(
        scheme: 'tel',
        path: phone,
      );


      final launched =
          await launchUrl(
        phoneUri,
        mode:
            LaunchMode.externalApplication,
      );


      if (!launched &&
          mounted) {

        showMessage(
          'Unable to open the phone application.',
        );
      }

    } catch (e) {

      debugPrint(
        'Call error: $e',
      );


      if (mounted) {

        showMessage(
          'Unable to make the call.',
        );
      }

    } finally {

      if (mounted) {

        setState(() {
          isCalling = false;
        });
      }
    }
  }


  // ==========================================================
  // PART 2 CONTINUES
  // ==========================================================
  // ==========================================================
  // OPEN SHOP LOCATION IN GOOGLE MAPS
  // ==========================================================

  Future<void> openShopLocation() async {

    if (!locationAvailable ||
        latitude == null ||
        longitude == null) {

      showMessage(
        'Shop location is not available.',
      );

      return;
    }


    if (isOpeningLocation) {
      return;
    }


    setState(() {
      isOpeningLocation = true;
    });


    try {

      // --------------------------------------------------------
      // GOOGLE MAPS NAVIGATION URL
      // --------------------------------------------------------

      final Uri googleMapsUri =
          Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$latitude,$longitude'
        '&travelmode=driving',
      );


      final launched =
          await launchUrl(
        googleMapsUri,
        mode:
            LaunchMode.externalApplication,
      );


      if (!launched &&
          mounted) {

        showMessage(
          'Unable to open Google Maps.',
        );
      }

    } catch (e) {

      debugPrint(
        'Google Maps error: $e',
      );


      if (mounted) {

        showMessage(
          'Unable to open the location.',
        );
      }

    } finally {

      if (mounted) {

        setState(() {
          isOpeningLocation = false;
        });
      }
    }
  }


  // ==========================================================
  // OPEN CHAT
  // ==========================================================

 // ==========================================================
// OPEN CHAT
// ==========================================================

void openChat() {

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          ScreenMessage(

        chatUser: {
          'name': shopName,
          'location': locationAvailable
              ? formattedDistance
              : 'Location unavailable',
          'type': 'tea_shop',
        },
      ),
    ),
  );
}

  // ==========================================================
  // SHOW MESSAGE
  // ==========================================================

  void showMessage(
    String message,
  ) {

    if (!mounted) {
      return;
    }


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


  // ==========================================================
  // STATUS TEXT
  // ==========================================================

  String get statusText {

    if (isActive) {
      return 'Active';
    }

    return 'Currently unavailable';
  }


  // ==========================================================
  // STATUS COLOR
  // ==========================================================

  Color get statusColor {

    if (isActive) {
      return green;
    }

    return Colors.grey;
  }


  // ==========================================================
  // PROFILE HEADER
  // ==========================================================

  Widget profileHeader() {

    return Container(

      width:
          double.infinity,

      padding:
          const EdgeInsets.fromLTRB(
        20,
        25,
        20,
        30,
      ),

      decoration:
          const BoxDecoration(

        gradient:
            LinearGradient(

          colors: [
            darkGreen,
            green,
          ],

          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.only(

          bottomLeft:
              Radius.circular(30),

          bottomRight:
              Radius.circular(30),
        ),
      ),

      child:
          SafeArea(

        bottom:
            false,

        child:
            Column(

          children: [

            // ------------------------------------------------
            // TOP ROW
            // ------------------------------------------------

            Row(

              children: [

                // --------------------------------------------
                // BACK BUTTON
                // --------------------------------------------

                IconButton(

                  onPressed:
                      () {

                    Navigator.pop(
                      context,
                    );
                  },

                  icon:
                      const Icon(
                    Icons.arrow_back,
                    color:
                        Colors.white,
                  ),
                ),


                const Spacer(),


                // --------------------------------------------
                // CATEGORY
                // --------------------------------------------

                Container(

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        12,
                    vertical:
                        7,
                  ),

                  decoration:
                      BoxDecoration(

                    color:
                        Colors.white.withValues(
                      alpha:
                          0.18,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),

                  child:
                      Text(
                    category,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),


            const SizedBox(
              height: 15,
            ),


            // ------------------------------------------------
            // SHOP ICON
            // ------------------------------------------------

            Container(

              width:
                  95,

              height:
                  95,

              decoration:
                  BoxDecoration(

                color:
                    Colors.white,

                shape:
                    BoxShape.circle,

                boxShadow: [

                  BoxShadow(

                    color:
                        Colors.black.withValues(
                      alpha:
                          0.15,
                    ),

                    blurRadius:
                        15,

                    offset:
                        const Offset(
                      0,
                      6,
                    ),
                  ),
                ],
              ),

              child:
                  const Icon(

                Icons.local_cafe,

                size:
                    48,

                color:
                    orange,
              ),
            ),


            const SizedBox(
              height: 15,
            ),


            // ------------------------------------------------
            // SHOP NAME
            // ------------------------------------------------

            Text(

              shopName,

              textAlign:
                  TextAlign.center,

              maxLines:
                  2,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(

                fontSize:
                    26,

                fontWeight:
                    FontWeight.bold,

                color:
                    Colors.white,
              ),
            ),


            const SizedBox(
              height: 8,
            ),


            // ------------------------------------------------
            // CATEGORY
            // ------------------------------------------------

            Text(

              category,

              style:
                  const TextStyle(

                color:
                    Colors.white70,

                fontSize:
                    15,
              ),
            ),


            const SizedBox(
              height: 15,
            ),


            // ------------------------------------------------
            // ACTIVE STATUS
            // ------------------------------------------------

            Container(

              padding:
                  const EdgeInsets.symmetric(
                horizontal:
                    14,
                vertical:
                    8,
              ),

              decoration:
                  BoxDecoration(

                color:
                    Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),

              child:
                  Row(

                mainAxisSize:
                    MainAxisSize.min,

                children: [

                  Container(

                    width:
                        9,

                    height:
                        9,

                    decoration:
                        BoxDecoration(

                      color:
                          statusColor,

                      shape:
                          BoxShape.circle,
                    ),
                  ),

                  const SizedBox(
                    width:
                        8,
                  ),

                  Text(

                    statusText,

                    style:
                        TextStyle(

                      color:
                          statusColor,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // INFO CARD
  // ==========================================================

  Widget infoCard({

    required IconData icon,

    required String title,

    required String value,

    Color iconColor = green,
  }) {

    return Container(

      width:
          double.infinity,

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

        boxShadow: [

          BoxShadow(

            color:
                Colors.black.withValues(
              alpha:
                  0.05,
            ),

            blurRadius:
                10,

            offset:
                const Offset(
              0,
              3,
            ),
          ),
        ],
      ),

      child:
          Row(

        children: [

          Container(

            width:
                48,

            height:
                48,

            decoration:
                BoxDecoration(

              color:
                  iconColor.withValues(
                alpha:
                    0.12,
              ),

              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),

            child:
                Icon(

              icon,

              color:
                  iconColor,
            ),
          ),


          const SizedBox(
            width:
                15,
          ),


          Expanded(

            child:
                Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(

                  title,

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
                      4,
                ),


                Text(

                  value,

                  maxLines:
                      2,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(

                    fontSize:
                        16,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // PART 3 CONTINUES
  // ==========================================================
  // ==========================================================
  // ACTION BUTTON
  // ==========================================================

  Widget actionButton({

    required IconData icon,

    required String label,

    required Color color,

    required VoidCallback? onPressed,

    bool loading = false,
  }) {

    return Expanded(

      child:
          ElevatedButton(

        onPressed:
            loading
                ? null
                : onPressed,

        style:
            ElevatedButton.styleFrom(

          elevation:
              0,

          backgroundColor:
              color,

          foregroundColor:
              Colors.white,

          padding:
              const EdgeInsets.symmetric(
            vertical:
                14,
          ),

          shape:
              RoundedRectangleBorder(

            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),

        child:
            loading

                ? const SizedBox(

                    width:
                        22,

                    height:
                        22,

                    child:
                        CircularProgressIndicator(

                      strokeWidth:
                          2,

                      color:
                          Colors.white,
                    ),
                  )

                : Column(

                    mainAxisSize:
                        MainAxisSize.min,

                    children: [

                      Icon(
                        icon,
                        size:
                            25,
                      ),

                      const SizedBox(
                        height:
                            5,
                      ),

                      Text(
                        label,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }


  // ==========================================================
  // ACTION SECTION
  // ==========================================================

  Widget actionSection() {

    return Row(

      children: [

        // ----------------------------------------------------
        // CALL BUTTON
        // ----------------------------------------------------

        actionButton(

          icon:
              Icons.call,

          label:
              'Call',

          color:
              green,

          loading:
              isCalling,

          onPressed:
              callShop,
        ),


        const SizedBox(
          width:
              10,
        ),


        // ----------------------------------------------------
        // LOCATION BUTTON
        // ----------------------------------------------------

        actionButton(

          icon:
              Icons.location_on,

          label:
              'Location',

          color:
              orange,

          loading:
              isOpeningLocation,

          onPressed:
              openShopLocation,
        ),


        const SizedBox(
          width:
              10,
        ),


        // ----------------------------------------------------
        // CHAT BUTTON
        // ----------------------------------------------------

        actionButton(

          icon:
              Icons.chat_bubble,

          label:
              'Chat',

          color:
              darkGreen,

          onPressed:
              openChat,
        ),
      ],
    );
  }


  // ==========================================================
  // LOCATION INFORMATION
  // ==========================================================

  Widget locationInformation() {

    if (!locationAvailable) {

      return infoCard(

        icon:
            Icons.location_off,

        title:
            'Location',

        value:
            'Shop location is unavailable',

        iconColor:
            Colors.grey,
      );
    }


    return infoCard(

      icon:
          Icons.location_on,

      title:
          'Distance',

      value:
          formattedDistance,

      iconColor:
          orange,
    );
  }


  // ==========================================================
  // OWNER INFORMATION
  //
  // We show the username only.
  // Mobile number is NEVER displayed.
  // ==========================================================

  Widget ownerInformation() {

    if (username.trim().isEmpty) {
      return const SizedBox();
    }


    return infoCard(

      icon:
          Icons.person_outline,

      title:
          'Shop Owner',

      value:
          username,
    );
  }


  // ==========================================================
  // CATEGORY INFORMATION
  // ==========================================================

  Widget categoryInformation() {

    return infoCard(

      icon:
          Icons.category_outlined,

      title:
          'Shop Category',

      value:
          category,

      iconColor:
          darkGreen,
    );
  }


  // ==========================================================
  // ABOUT SECTION
  // ==========================================================

  Widget aboutSection() {

    return Container(

      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        18,
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
                  0.05,
            ),

            blurRadius:
                10,

            offset:
                const Offset(
              0,
              3,
            ),
          ),
        ],
      ),

      child:
          Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Row(

            children: [

              Icon(
                Icons.info_outline,
                color:
                    green,
              ),

              SizedBox(
                width:
                    10,
              ),

              Text(

                'About this Shop',

                style:
                    TextStyle(

                  fontSize:
                      18,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),


          const SizedBox(
            height:
                12,
          ),


          Text(

            'Visit $shopName for ${category.toLowerCase()}. '
            'Use the buttons above to call the shop, '
            'get directions, or start a chat.',

            style:
                const TextStyle(

              fontSize:
                  14,

              height:
                  1.5,

              color:
                  Colors.black87,
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

      body:
          SafeArea(

        top:
            false,

        child:
            Column(

          children: [

            // ------------------------------------------------
            // HEADER
            // ------------------------------------------------

            profileHeader(),


            // ------------------------------------------------
            // SCROLLABLE CONTENT
            // ------------------------------------------------

            Expanded(

              child:
                  SingleChildScrollView(

                padding:
                    const EdgeInsets.all(
                  16,
                ),

                child:
                    Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    // ----------------------------------------
                    // ACTION BUTTONS
                    // ----------------------------------------

                    actionSection(),


                    const SizedBox(
                      height:
                          22,
                    ),


                    // ----------------------------------------
                    // SECTION TITLE
                    // ----------------------------------------

                    const Text(

                      'Shop Information',

                      style:
                          TextStyle(

                        fontSize:
                            20,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),


                    const SizedBox(
                      height:
                          14,
                    ),


                    // ----------------------------------------
                    // CATEGORY
                    // ----------------------------------------

                    categoryInformation(),


                    const SizedBox(
                      height:
                          12,
                    ),


                    // ----------------------------------------
                    // LOCATION / DISTANCE
                    // ----------------------------------------

                    locationInformation(),


                    // ----------------------------------------
                    // OWNER
                    // ----------------------------------------

                    if (username.trim().isNotEmpty) ...[

                      const SizedBox(
                        height:
                            12,
                      ),

                      ownerInformation(),
                    ],


                    const SizedBox(
                      height:
                          22,
                    ),


                    // ----------------------------------------
                    // ABOUT
                    // ----------------------------------------

                    aboutSection(),


                    const SizedBox(
                      height:
                          30,
                    ),


                    // ----------------------------------------
                    // IMPORTANT NOTE
                    //
                    // MOBILE NUMBER IS INTENTIONALLY
                    // NOT DISPLAYED ANYWHERE.
                    // ----------------------------------------

                    Center(

                      child:
                          Text(

                        'Contact the shop using the Call button',

                        textAlign:
                            TextAlign.center,

                        style:
                            TextStyle(

                          fontSize:
                              13,

                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ),


                    const SizedBox(
                      height:
                          20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {

    super.dispose();
  }
}