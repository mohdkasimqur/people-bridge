import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// IMPORTANT:
// Change this import to the exact location of your message screen.
// Example:
// import 'package:jober_india/.../screen_message.dart';

class ScreenAutoSparePartsShopProfile extends StatefulWidget {
  final Map<String, dynamic> shop;

  final double userLatitude;

  final double userLongitude;

  const ScreenAutoSparePartsShopProfile({
    super.key,
    required this.shop,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  State<ScreenAutoSparePartsShopProfile> createState() =>
      _ScreenAutoSparePartsShopProfileState();
}

class _ScreenAutoSparePartsShopProfileState
    extends State<ScreenAutoSparePartsShopProfile> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color green =
     //      Color(0xFF138808);
 Color(0xFF198B35);

  static const Color darkGreen =
      Color(0xFF12652F);

  // ============================================================
  // LOADING
  // ============================================================

  bool calling = false;

  bool openingLocation = false;

  // ============================================================
  // GET SHOP DATA
  // ============================================================

  String get shopName {
    return (widget.shop['shopName'] ??
            'Auto Spare Parts Shop')
        .toString();
  }

  String get category {
    return (widget.shop['category'] ?? '')
        .toString();
  }

  String get experience {
    return (widget.shop['experience'] ?? '')
        .toString();
  }

  String get mobile {
    return (widget.shop['mobile'] ?? '')
        .toString();
  }

  double get distance {
    final dynamic value =
        widget.shop['distance'];

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double get latitude {
    final dynamic value =
        widget.shop['latitude'];

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double get longitude {
    final dynamic value =
        widget.shop['longitude'];

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // CALL SHOP
  // ============================================================

  Future<void> _callShop() async {
    if (calling) return;

    if (mobile.isEmpty) {
      _showMessage(
        'Shop phone number is not available.',
      );
      return;
    }

    setState(() {
      calling = true;
    });

    try {
      final Uri phoneUri =
          Uri(
        scheme: 'tel',
        path: mobile,
      );

      final bool launched =
          await launchUrl(
        phoneUri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!launched) {
        _showMessage(
          'Unable to open the phone application.',
        );
      }
    } catch (_) {
      _showMessage(
        'Unable to call this shop.',
      );
    } finally {
      if (mounted) {
        setState(() {
          calling = false;
        });
      }
    }
  }

  // ============================================================
  // OPEN SHOP LOCATION
  // ============================================================

  Future<void> _openLocation() async {
    if (openingLocation) return;

    if (latitude == 0 ||
        longitude == 0) {
      _showMessage(
        'Shop location is not available.',
      );
      return;
    }

    setState(() {
      openingLocation = true;
    });

    try {
      // Google Maps destination navigation.
      final Uri googleMapsUri =
          Uri.parse(
        'https://www.google.com/maps/dir/'
        '${widget.userLatitude},${widget.userLongitude}/'
        '$latitude,$longitude',
      );

      final bool launched =
          await launchUrl(
        googleMapsUri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!launched) {
        _showMessage(
          'Unable to open Google Maps.',
        );
      }
    } catch (_) {
      _showMessage(
        'Unable to open shop location.',
      );
    } finally {
      if (mounted) {
        setState(() {
          openingLocation = false;
        });
      }
    }
  }
  // ============================================================
  // OPEN CHAT
  // ============================================================

  void _openChat() {
    /*
    ============================================================

    CONNECT YOUR MESSAGE SCREEN HERE

    Example:

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenMessage(
          receiverId:
              widget.shop['uid'].toString(),

          receiverName:
              shopName,
        ),
      ),
    );

    ============================================================

    Your existing ScreenMessage constructor may have different
    parameters.

    The important values you need to pass are:

    receiver/shop UID:
    widget.shop['uid']

    Shop Name:
    shopName

    ============================================================
    */

    _showMessage(
      'Connect your ScreenMessage page here.',
    );
  }

  // ============================================================
  // PROFILE DETAIL CARD
  // ============================================================

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(
        16,
      ),

      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

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
              Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,

            decoration:
                BoxDecoration(
              color:
                  green.withValues(alpha: 
                0.10,
              ),

              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),

            child:
                Icon(
              icon,

              color:
                  green,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  title,

                  style:
                      TextStyle(
                    color:
                        Colors.grey.shade600,

                    fontSize:
                        12,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  value,

                  style:
                      const TextStyle(
                    fontSize:
                        15,

                    fontWeight:
                        FontWeight
                            .w700,
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
  // ACTION BUTTON
  // ============================================================

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return Expanded(
      child: SizedBox(
        height: 54,

        child:
            ElevatedButton(
          onPressed:
              loading
                  ? null
                  : onPressed,

          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.white,

            foregroundColor:
                green,

            elevation:
                0,

            side:
                BorderSide(
              color:
                  green.withValues(alpha: 
                0.35,
              ),
            ),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),
          ),

          child:
              loading
                  ? const SizedBox(
                      width:
                          20,

                      height:
                          20,

                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2,

                        color:
                            green,
                      ),
                    )
                  : Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [
                        Icon(
                          icon,

                          size:
                              21,
                        ),

                        const SizedBox(
                          height:
                              3,
                        ),

                        Text(
                          label,

                          style:
                              const TextStyle(
                            fontSize:
                                12,

                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  // ============================================================
  // SHOP HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(
        22,
      ),

      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,

          colors: [
            green,
            darkGreen,
          ],
        ),

        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),

      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,

            decoration:
                const BoxDecoration(
              color:
                  Colors.white,

              shape:
                  BoxShape.circle,
            ),

            child:
                const Icon(
              Icons
                  .storefront_rounded,

              size:
                  48,

              color:
                  green,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            shopName,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color:
                  Colors.white,

              fontSize:
                  22,

              fontWeight:
                  FontWeight
                      .w800,
            ),
          ),

          if (category.isNotEmpty) ...[
            const SizedBox(
              height:
                  6,
            ),

            Text(
              category,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                color:
                    Colors.white70,

                fontSize:
                    14,

                fontWeight:
                    FontWeight
                        .w500,
              ),
            ),
          ],

          const SizedBox(
            height:
                14,
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  14,

              vertical:
                  7,
            ),

            decoration:
                BoxDecoration(
              color:
                  Colors.white.withValues(alpha: 
                0.16,
              ),

              borderRadius:
                  BorderRadius.circular(
                30,
              ),
            ),

            child:
                Row(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                const Icon(
                  Icons
                      .location_on_rounded,

                  color:
                      Colors.white,

                  size:
                      17,
                ),

                const SizedBox(
                  width:
                      5,
                ),

                Text(
                  '${distance.toStringAsFixed(1)} km away',

                  style:
                      const TextStyle(
                    color:
                        Colors.white,

                    fontSize:
                        13,

                    fontWeight:
                        FontWeight
                            .w700,
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        foregroundColor:
            Colors.black,

        elevation:
            0,

        centerTitle:
            true,

        title:
            const Text(
          'Shop Profile',

          style:
              TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            16,
            18,
            30,
          ),

          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              // ================================================
              // HEADER
              // ================================================

              _buildHeader(),

              const SizedBox(
                height:
                    24,
              ),

              // ================================================
              // SHOP INFORMATION
              // ================================================

              const Text(
                'Shop Information',

                style:
                    TextStyle(
                  fontSize:
                      18,

                  fontWeight:
                      FontWeight
                          .w800,
                ),
              ),

              const SizedBox(
                height:
                    14,
              ),

              // CATEGORY

              if (category.isNotEmpty)
                _buildDetailCard(
                  icon:
                      Icons
                          .category_rounded,

                  title:
                      'Spare Parts Category',

                  value:
                      category,
                ),

              // EXPERIENCE

              if (experience.isNotEmpty)
                _buildDetailCard(
                  icon:
                      Icons
                          .history_rounded,

                  title:
                      'Shop Experience',

                  value:
                      experience,
                ),

              // DISTANCE

              _buildDetailCard(
                icon:
                    Icons
                        .location_on_rounded,

                title:
                    'Distance From You',

                value:
                    '${distance.toStringAsFixed(1)} km',
              ),

              const SizedBox(
                height:
                    12,
              ),

              // ================================================
              // CONTACT SHOP
              // ================================================

              const Text(
                'Contact Shop',

                style:
                    TextStyle(
                  fontSize:
                      18,

                  fontWeight:
                      FontWeight
                          .w800,
                ),
              ),

              const SizedBox(
                height:
                    14,
              ),

              Row(
                children: [
                  // ============================================
                  // CALL
                  // ============================================

                  _buildActionButton(
                    icon:
                        Icons
                            .call_rounded,

                    label:
                        'Call',

                    loading:
                        calling,

                    onPressed:
                        _callShop,
                  ),

                  const SizedBox(
                    width:
                        10,
                  ),

                  // ============================================
                  // CHAT
                  // ============================================

                  _buildActionButton(
                    icon:
                        Icons
                            .chat_bubble_rounded,

                    label:
                        'Chat',

                    onPressed:
                        _openChat,
                  ),

                  const SizedBox(
                    width:
                        10,
                  ),

                  // ============================================
                  // LOCATION
                  // ============================================

                  _buildActionButton(
                    icon:
                        Icons
                            .directions_rounded,

                    label:
                        'Location',

                    loading:
                        openingLocation,

                    onPressed:
                        _openLocation,
                  ),
                ],
              ),

              const SizedBox(
                height:
                    28,
              ),

              // ================================================
              // LOCATION INFORMATION
              // ================================================

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
                      green.withValues(alpha: 
                    0.07,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),

                child:
                    Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    const Icon(
                      Icons
                          .info_outline_rounded,

                      color:
                          green,
                    ),

                    const SizedBox(
                      width:
                          12,
                    ),

                    Expanded(
                      child:
                          Text(
                        'Use the Location button to open directions and navigate to this spare parts shop.',

                        style:
                            TextStyle(
                          color:
                              Colors.grey.shade800,

                          height:
                              1.4,

                          fontSize:
                              13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height:
                    18,
              ),

              // ================================================
              // PRIVACY MESSAGE
              // ================================================

              Center(
                child:
                    Text(
                  'The shop mobile number is kept private.',

                  style:
                      TextStyle(
                    color:
                        Colors.grey.shade500,

                    fontSize:
                        12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}