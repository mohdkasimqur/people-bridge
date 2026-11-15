import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:url_launcher/url_launcher.dart';

// ===============================================================
// IMPORT MESSAGE SCREEN
// ===============================================================

// Change this import if your ScreenMessage file is in another folder.
//import 'screen_message.dart';


// ===============================================================
// SCREEN FREELANCER PROFILE
// ===============================================================

class ScreenFreelancerProfile extends StatefulWidget {

  final Map<String, dynamic> freelancer;

  final String selectedCategory;


  const ScreenFreelancerProfile({
    super.key,
    required this.freelancer,
    required this.selectedCategory,
  });


  @override
  State<ScreenFreelancerProfile> createState() =>
      _ScreenFreelancerProfileState();

}


class _ScreenFreelancerProfileState
    extends State<ScreenFreelancerProfile> {


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


  // =============================================================
  // LOADING STATES
  // =============================================================

  bool _calling = false;

  bool _openingLocation = false;

  bool _openingChat = false;


  // =============================================================
  // GET NAME
  // =============================================================

  String get _name {

    final value =
        widget.freelancer['name']
            ?.toString()
            .trim();

    if (value == null ||
        value.isEmpty) {

      return 'Freelancer';

    }

    return value;

  }


  // =============================================================
  // GET MOBILE
  //
  // IMPORTANT:
  // The number is used internally for CALL,
  // but it is NEVER displayed on the screen.
  // =============================================================

  String get _mobile {

    final value =
        widget.freelancer['mobile']
            ?.toString()
            .trim();

    return value ?? '';

  }


  // =============================================================
  // GET DISTANCE
  // =============================================================

  double get _distance {

    final value =
        widget.freelancer['distanceKm'];


    if (value is num) {

      return value.toDouble();

    }


    if (value is String) {

      return double.tryParse(value) ??
          0.0;

    }


    return 0.0;

  }


  // =============================================================
  // GET LATITUDE
  // =============================================================

  double? get _latitude {

    final value =
        widget.freelancer['latitude'];


    if (value is num) {

      return value.toDouble();

    }


    if (value is String) {

      return double.tryParse(value);

    }


    return null;

  }


  // =============================================================
  // GET LONGITUDE
  // =============================================================

  double? get _longitude {

    final value =
        widget.freelancer['longitude'];


    if (value is num) {

      return value.toDouble();

    }


    if (value is String) {

      return double.tryParse(value);

    }


    return null;

  }


  // =============================================================
  // GET PROFILE IMAGE
  // =============================================================

  String get _profileImage {

    final value =
        widget.freelancer['profileImage']
            ?.toString()
            .trim();

    return value ?? '';

  }
  // =============================================================
  // CALL FREELANCER
  //
  // The mobile number is NOT shown to the user.
  // It is only used when CALL is pressed.
  // =============================================================

  Future<void> _callFreelancer() async {

    if (_calling) return;


    if (_mobile.isEmpty) {

      _showMessage(
        'Phone number is not available',
      );

      return;

    }


    setState(() {

      _calling = true;

    });


    try {

      final Uri phoneUri =
          Uri(
        scheme: 'tel',
        path: _mobile,
      );


      final launched =
          await launchUrl(
        phoneUri,
      );


      if (!launched) {

        _showMessage(
          'Unable to open phone dialer',
        );

      }

    } catch (_) {

      _showMessage(
        'Unable to make the call',
      );

    } finally {

      if (mounted) {

        setState(() {

          _calling = false;

        });

      }

    }

  }


  // =============================================================
  // OPEN FREELANCER LOCATION
  //
  // Opens Google Maps using the freelancer coordinates.
  //
  // Example:
  //
  // https://www.google.com/maps/search/
  // ?api=1&query=latitude,longitude
  // =============================================================

  Future<void> _openLocation() async {

    if (_openingLocation) return;


    if (_latitude == null ||
        _longitude == null) {

      _showMessage(
        'Freelancer location is not available',
      );

      return;

    }


    setState(() {

      _openingLocation = true;

    });


    try {

      final Uri mapUri =
          Uri.parse(

        'https://www.google.com/maps/search/'
        '?api=1'
        '&query=$_latitude,$_longitude',

      );


      final launched =
          await launchUrl(
        mapUri,
        mode:
            LaunchMode.externalApplication,
      );


      if (!launched) {

        _showMessage(
          'Unable to open location',
        );

      }

    } catch (_) {

      _showMessage(
        'Unable to open location',
      );

    } finally {

      if (mounted) {

        setState(() {

          _openingLocation = false;

        });

      }

    }

  }


  // =============================================================
  // OPEN CHAT
  // =============================================================

  Future<void> _openChat() async {

    if (_openingChat) return;


    setState(() {

      _openingChat = true;

    });


    try {

      // =========================================================
      // SEND FREELANCER DATA TO MESSAGE SCREEN
      //
      // ScreenMessage currently uses a Map<String, dynamic>.
      // =========================================================

      await Navigator.push(

        context,

        MaterialPageRoute(

          builder:
              (_) =>
                  ScreenMessage(

            chatUser:
                widget.freelancer,

          ),

        ),

      );

    } catch (_) {

      if (mounted) {

        _showMessage(
          'Unable to open chat',
        );

      }

    } finally {

      if (mounted) {

        setState(() {

          _openingChat = false;

        });

      }

    }

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
  // GET INITIAL LETTER
  // =============================================================

  String get _initial {

    if (_name.isEmpty) {

      return 'F';

    }


    return _name
        .substring(0, 1)
        .toUpperCase();

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

        centerTitle:
            true,


        title:
            const Text(

          'Freelancer Profile',

          style:
              TextStyle(

            color:
                darkGreen,

            fontWeight:
                FontWeight.bold,

          ),

        ),

      ),


      // =========================================================
      // BODY
      // =========================================================

      body:
          SafeArea(

        child:
            SingleChildScrollView(

          padding:
              const EdgeInsets.fromLTRB(
            20,
            25,
            20,
            30,
          ),

          child:
              Column(

            children: [


              // =================================================
              // PROFILE IMAGE
              // =================================================

              _buildProfileImage(),


              const SizedBox(
                height:
                    22,
              ),


              // =================================================
              // FREELANCER NAME
              // =================================================

              Text(

                _name,

                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(

                  fontSize:
                      25,

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


              // =================================================
              // CATEGORY
              // =================================================

              Container(

                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      16,
                  vertical:
                      9,
                ),

                decoration:
                    BoxDecoration(

                  color:
                      const Color(
                    0xFFE7F4EA,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    25,
                  ),

                ),

                child:
                    Row(

                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    const Icon(

                      Icons.work_outline,

                      size:
                          18,

                      color:
                          green,

                    ),

                    const SizedBox(
                      width:
                          7,
                    ),

                    Text(

                      widget.selectedCategory,

                      style:
                          const TextStyle(

                        color:
                            darkGreen,

                        fontWeight:
                            FontWeight.w600,

                      ),

                    ),

                  ],

                ),

              ),


              const SizedBox(
                height:
                    16,
              ),


              // =================================================
              // DISTANCE
              // =================================================

              Row(

                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  const Icon(

                    Icons.location_on,

                    color:
                        orange,

                    size:
                        21,

                  ),

                  const SizedBox(
                    width:
                        5,
                  ),

                  Text(

                    '${_distance.toStringAsFixed(1)} KM Away',

                    style:
                        const TextStyle(

                      fontSize:
                          16,

                      fontWeight:
                          FontWeight.w600,

                      color:
                          Colors.black87,

                    ),

                  ),

                ],

              ),


              const SizedBox(
                height:
                    35,
              ),


              // =================================================
              // DIVIDER
              // =================================================

              Divider(
                color:
                    Colors.grey.shade300,
              ),


              const SizedBox(
                height:
                    25,
              ),


              // =================================================
              // ACTION BUTTONS
              // =================================================

              Row(

                children: [


                  // =============================================
                  // CALL
                  // =============================================

                  Expanded(

                    child:
                        _buildActionButton(

                      icon:
                          Icons.call_outlined,

                      label:
                          'CALL',

                      loading:
                          _calling,

                      onTap:
                          _callFreelancer,

                    ),

                  ),


                  const SizedBox(
                    width:
                        10,
                  ),


                  // =============================================
                  // LOCATION
                  // =============================================

                  Expanded(

                    child:
                        _buildActionButton(

                      icon:
                          Icons.location_on_outlined,

                      label:
                          'LOCATION',

                      loading:
                          _openingLocation,

                      onTap:
                          _openLocation,

                    ),

                  ),


                  const SizedBox(
                    width:
                        10,
                  ),


                  // =============================================
                  // CHAT
                  // =============================================

                  Expanded(

                    child:
                        _buildActionButton(

                      icon:
                          Icons.chat_bubble_outline,

                      label:
                          'CHAT',

                      loading:
                          _openingChat,

                      onTap:
                          _openChat,

                    ),

                  ),

                ],

              ),


              const SizedBox(
                height:
                    35,
              ),


              // =================================================
              // PRIVACY MESSAGE
              // =================================================

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

                child:
                    const Row(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Icon(

                      Icons.privacy_tip_outlined,

                      color:
                          green,

                    ),

                    SizedBox(
                      width:
                          12,
                    ),

                    Expanded(

                      child:
                          Text(

                        'Contact details are protected. You can contact this freelancer using the Call or Chat buttons.',

                        style:
                            TextStyle(

                          fontSize:
                              13,

                          color:
                              Colors.black54,

                        ),

                      ),

                    ),

                  ],

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }


  // =============================================================
  // PROFILE IMAGE
  // =============================================================

  Widget _buildProfileImage() {

    return Container(

      width:
          130,

      height:
          130,


      decoration:
          BoxDecoration(

        shape:
            BoxShape.circle,

        color:
            const Color(
          0xFFE7F4EA,
        ),

        border:
            Border.all(

          color:
              green,

          width:
              3,

        ),

      ),


      child:
          ClipOval(

        child:
            _profileImage.isNotEmpty

                ? Image.network(

                    _profileImage,

                    width:
                        130,

                    height:
                        130,

                    fit:
                        BoxFit.cover,


                    // ===========================================
                    // ERROR SAFE
                    // ===========================================

                    errorBuilder:
                        (
                          context,
                          error,
                          stackTrace,
                        ) {

                      return _buildDefaultAvatar();

                    },


                    loadingBuilder:
                        (
                          context,
                          child,
                          loadingProgress,
                        ) {

                      if (loadingProgress ==
                          null) {

                        return child;

                      }


                      return const Center(

                        child:
                            CircularProgressIndicator(
                          color:
                              green,
                        ),

                      );

                    },

                  )

                : _buildDefaultAvatar(),

      ),

    );

  }


  // =============================================================
  // DEFAULT AVATAR
  // =============================================================

  Widget _buildDefaultAvatar() {

    return Center(

      child:
          Text(

        _initial,

        style:
            const TextStyle(

          fontSize:
              52,

          fontWeight:
              FontWeight.bold,

          color:
              green,

        ),

      ),

    );

  }


  // =============================================================
  // ACTION BUTTON
  // =============================================================

  Widget _buildActionButton({

    required IconData icon,

    required String label,

    required bool loading,

    required VoidCallback onTap,

  }) {

    return Material(

      color:
          Colors.white,

      borderRadius:
          BorderRadius.circular(
        15,
      ),


      child:
          InkWell(

        borderRadius:
            BorderRadius.circular(
          15,
        ),

        onTap:
            loading
                ? null
                : onTap,


        child:
            Container(

          height:
              95,

          decoration:
              BoxDecoration(

            borderRadius:
                BorderRadius.circular(
              15,
            ),

            border:
                Border.all(

              color:
                  green.withValues(
                alpha:
                    0.35,
              ),

            ),

          ),


          child:
              Column(

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              loading

                  ? const SizedBox(

                      width:
                          25,

                      height:
                          25,

                      child:
                          CircularProgressIndicator(

                        strokeWidth:
                            2.5,

                        color:
                            green,

                      ),

                    )

                  : Icon(

                      icon,

                      color:
                          green,

                      size:
                          28,

                    ),


              const SizedBox(
                height:
                    9,
              ),


              Text(

                label,

                style:
                    const TextStyle(

                  fontSize:
                      12,

                  fontWeight:
                      FontWeight.bold,

                  color:
                      darkGreen,

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}