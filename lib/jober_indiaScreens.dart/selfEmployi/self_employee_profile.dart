// ===============================================================
// SCREEN SELF EMPLOYEES PROFILE
// PART 1 OF 3
// ===============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:url_launcher/url_launcher.dart';

class ScreenSelfEmployeesProfile extends StatefulWidget {
  final Map<String, dynamic> employee;

  const ScreenSelfEmployeesProfile({
    super.key,
    required this.employee,
  });

  @override
  State<ScreenSelfEmployeesProfile> createState() =>
      _ScreenSelfEmployeesProfileState();
}

class _ScreenSelfEmployeesProfileState
    extends State<ScreenSelfEmployeesProfile> {
  bool _isCalling = false;
  bool _isOpeningMap = false;
  bool _isOpeningChat = false;

  // =============================================================
  // READ STRING SAFELY
  // =============================================================

  String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  // =============================================================
  // READ DOUBLE SAFELY
  // =============================================================

  double? _readDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim());
    }

    return null;
  }

  // =============================================================
  // EMPLOYEE NAME
  // =============================================================

  String get employeeName {
    return _readString(
      widget.employee['name'],
      fallback: 'SELF EMPLOYEE',
    );
  }

  // =============================================================
  // CATEGORY
  // =============================================================

  String get employeeCategory {
    return _readString(
      widget.employee['category'],
      fallback: 'SELF EMPLOYEE',
    );
  }

  // =============================================================
  // DISTANCE
  // =============================================================

  double? get employeeDistance {
    return _readDouble(
      widget.employee['distanceKm'],
    );
  }

  // =============================================================
  // PHONE NUMBER
  // =============================================================
  //
  // The number is intentionally NOT displayed on this page.
  // It is only used when the user presses CALL.
  //
  // =============================================================

  String get employeeMobile {
    return _readString(
      widget.employee['mobile'],
    );
  }

  // =============================================================
  // LATITUDE
  // =============================================================

  double? get employeeLatitude {
    double? latitude = _readDouble(
      widget.employee['latitude'],
    );

    // -------------------------------------------------------------
    // Fallback to GeoPoint if latitude field is unavailable.
    // -------------------------------------------------------------

    if (latitude == null) {
      final dynamic location =
          widget.employee['location'];

      try {
        if (location != null) {
          final dynamic value =
              (location as dynamic).latitude;

          latitude = _readDouble(value);
        }
      } catch (_) {
        // Ignore invalid location data.
      }
    }

    return latitude;
  }

  // =============================================================
  // LONGITUDE
  // =============================================================

  double? get employeeLongitude {
    double? longitude = _readDouble(
      widget.employee['longitude'],
    );

    // -------------------------------------------------------------
    // Fallback to GeoPoint if longitude field is unavailable.
    // -------------------------------------------------------------

    if (longitude == null) {
      final dynamic location =
          widget.employee['location'];

      try {
        if (location != null) {
          final dynamic value =
              (location as dynamic).longitude;

          longitude = _readDouble(value);
        }
      } catch (_) {
        // Ignore invalid location data.
      }
    }

    return longitude;
  }

  // =============================================================
  // VALID COORDINATE CHECK
  // =============================================================

  bool get hasValidLocation {
    final double? latitude =
        employeeLatitude;

    final double? longitude =
        employeeLongitude;

    if (latitude == null ||
        longitude == null) {
      return false;
    }

    if (latitude < -90 ||
        latitude > 90) {
      return false;
    }

    if (longitude < -180 ||
        longitude > 180) {
      return false;
    }

    return true;
  }

  // =============================================================
  // SHOW MESSAGE
  // =============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // =============================================================
  // CALL EMPLOYEE
  // =============================================================

  Future<void> _callEmployee() async {
    if (_isCalling) return;

    final String mobile =
        employeeMobile.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    if (mobile.isEmpty) {
      _showMessage(
        'Phone number is not available.',
      );
      return;
    }

    setState(() {
      _isCalling = true;
    });

    try {
      String phoneNumber = mobile;

      // ----------------------------------------------------------
      // Convert a 10-digit Indian number to +91 format.
      // ----------------------------------------------------------

      if (RegExp(r'^\d{10}$')
          .hasMatch(phoneNumber)) {
        phoneNumber = '+91$phoneNumber';
      }

      final Uri phoneUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );

      final bool canCall =
          await canLaunchUrl(phoneUri);

      if (!canCall) {
        _showMessage(
          'Calling is not available on this device.',
        );
        return;
      }

      await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      _showMessage(
        'Unable to open the phone app.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCalling = false;
        });
      }
    }
  }

  // =============================================================
  // OPEN LOCATION
  // =============================================================

  Future<void> _openEmployeeLocation() async {
    if (_isOpeningMap) return;

    final double? latitude =
        employeeLatitude;

    final double? longitude =
        employeeLongitude;

    if (latitude == null ||
        longitude == null ||
        !hasValidLocation) {
      _showMessage(
        'Employee location is not available.',
      );
      return;
    }

    setState(() {
      _isOpeningMap = true;
    });

    try {
      final Uri googleMapsUri = Uri.parse(
        'https://www.google.com/maps/search/'
        '?api=1'
        '&query=$latitude,$longitude',
      );

      final bool canOpen =
          await canLaunchUrl(googleMapsUri);

      if (!canOpen) {
        _showMessage(
          'Google Maps could not be opened.',
        );
        return;
      }

      await launchUrl(
        googleMapsUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      _showMessage(
        'Unable to open employee location.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningMap = false;
        });
      }
    }
  }

  // =============================================================
  // OPEN CHAT
  // =============================================================

  Future<void> _openChat() async {
    if (_isOpeningChat) return;

    setState(() {
      _isOpeningChat = true;
    });

    try {
      final Map<String, dynamic> chatEmployee =
          Map<String, dynamic>.from(
        widget.employee,
      );

      // ----------------------------------------------------------
      // Make sure ScreenMessage receives the employee name.
      // ----------------------------------------------------------

      chatEmployee['name'] = employeeName;

      // ----------------------------------------------------------
      // Keep the employee ID available for the chat system.
      // ----------------------------------------------------------

      if (!chatEmployee.containsKey('employeeId') &&
          chatEmployee.containsKey('id')) {
        chatEmployee['employeeId'] =
            chatEmployee['id'];
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScreenMessage(
            chatUser: chatEmployee,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to open chat.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningChat = false;
        });
      }
    }
  }
  // =============================================================
  // PROFILE AVATAR
  // =============================================================

  Widget _buildProfileAvatar() {
    final String imageUrl =
        _readString(
      widget.employee['imageUrl'],
    );

    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE8F5E9),
        border: Border.all(
          color: const Color(0xFF198B35),
          width: 3,
        ),
      ),

      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,

                fit: BoxFit.cover,

                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Icon(
                    Icons.person,
                    size: 55,
                    color: Color(0xFF198B35),
                  );
                },

                loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF198B35),
                      ),
                    ),
                  );
                },
              )
            : const Icon(
                Icons.person,
                size: 55,
                color: Color(0xFF198B35),
              ),
      ),
    );
  }


  // =============================================================
  // PROFILE HEADER
  // =============================================================

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(
        20,
        25,
        20,
        25,
      ),

      decoration: const BoxDecoration(
        color: Colors.white,
      ),

      child: Column(
        children: [

          // -------------------------------------------------------
          // PROFILE IMAGE
          // -------------------------------------------------------

          _buildProfileAvatar(),

          const SizedBox(
            height: 16,
          ),


          // -------------------------------------------------------
          // NAME
          // -------------------------------------------------------

          Text(
            employeeName,

            textAlign: TextAlign.center,

            maxLines: 2,

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),

          const SizedBox(
            height: 10,
          ),


          // -------------------------------------------------------
          // CATEGORY TAG
          // -------------------------------------------------------

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),

            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),

              borderRadius:
                  BorderRadius.circular(20),
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Icon(
                  Icons.work_outline,
                  size: 17,
                  color: Color(0xFF198B35),
                ),

                const SizedBox(
                  width: 6,
                ),

                Flexible(
                  child: Text(
                    employeeCategory,

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: Color(0xFF198B35),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              ],
            ),
          ),


          // -------------------------------------------------------
          // DISTANCE
          // -------------------------------------------------------

          if (employeeDistance != null) ...[

            const SizedBox(
              height: 13,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [

                const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: Color(0xFF198B35),
                ),

                const SizedBox(
                  width: 5,
                ),

                Text(
                  '${employeeDistance!.toStringAsFixed(1)} KM Away',

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),

              ],
            ),

          ],

        ],
      ),
    );
  }


  // =============================================================
  // SECTION TITLE
  // =============================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 18,
        right: 18,
        top: 20,
        bottom: 10,
      ),

      child: Align(
        alignment: Alignment.centerLeft,

        child: Text(
          title,

          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF222222),
          ),
        ),
      ),
    );
  }


  // =============================================================
  // DESCRIPTION SECTION
  // =============================================================

  Widget _buildDescriptionSection() {
    final String description =
        _readString(
      widget.employee['description'],
    );

    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.symmetric(
        horizontal: 16,
      ),

      padding: const EdgeInsets.all(
        16,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Row(
            children: [

              Icon(
                Icons.description_outlined,
                color: Color(0xFF198B35),
              ),

              SizedBox(
                width: 8,
              ),

              Text(
                'About',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            description,

            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),

        ],
      ),
    );
  }


  // =============================================================
  // ACTION BUTTON
  // =============================================================

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
    required Color backgroundColor,
  }) {
    return Expanded(
      child: SizedBox(
        height: 58,

        child: ElevatedButton(
          onPressed:
              isLoading ? null : onPressed,

          style: ElevatedButton.styleFrom(
            elevation: 0,

            backgroundColor:
                backgroundColor,

            foregroundColor:
                Colors.white,

            disabledBackgroundColor:
                backgroundColor
                    .withValues(alpha: 0.65),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(14),
            ),

            padding:
                const EdgeInsets.symmetric(
              horizontal: 5,
            ),
          ),

          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [

                    Icon(
                      icon,
                      size: 22,
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      label,

                      maxLines: 1,

                      overflow:
                          TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                  ],
                ),
        ),
      ),
    );
  }


  // =============================================================
  // ACTION BUTTONS
  // =============================================================

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        22,
        16,
        24,
      ),

      child: Row(
        children: [

          // -------------------------------------------------------
          // CALL
          // -------------------------------------------------------

          _buildActionButton(
            icon: Icons.call_outlined,

            label: 'CALL',

            onPressed: _callEmployee,

            isLoading: _isCalling,

            backgroundColor:
                const Color(0xFF198B35),
          ),


          const SizedBox(
            width: 10,
          ),


          // -------------------------------------------------------
          // LOCATION
          // -------------------------------------------------------

          _buildActionButton(
            icon: Icons.location_on_outlined,

            label: 'LOCATION',

            onPressed: _openEmployeeLocation,

            isLoading: _isOpeningMap,

            backgroundColor:
                const Color(0xFFED801D),
          ),


          const SizedBox(
            width: 10,
          ),


          // -------------------------------------------------------
          // CHAT
          // -------------------------------------------------------

          _buildActionButton(
            icon: Icons.chat_bubble_outline,

            label: 'CHAT',

            onPressed: _openChat,

            isLoading: _isOpeningChat,

            backgroundColor:
                const Color(0xFF12652F),
          ),

        ],
      ),
    );
  }

// =============================================================
  // BUILD PROFILE BODY
  // =============================================================

  Widget _buildProfileBody() {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics:
            const BouncingScrollPhysics(),

        padding:
            const EdgeInsets.only(
          bottom: 30,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // =====================================================
            // PROFILE HEADER
            // =====================================================

            _buildProfileHeader(),


            // =====================================================
            // DIVIDER / SPACE
            // =====================================================

            const SizedBox(
              height: 8,
            ),


            // =====================================================
            // ABOUT SECTION
            // =====================================================

            if (_readString(
                  widget.employee['description'],
                ).isNotEmpty) ...[

              _buildSectionTitle(
                'About SELF EMPLOYEE',
              ),

              _buildDescriptionSection(),

            ] else ...[

              // ---------------------------------------------------
              // DEFAULT ABOUT SECTION
              //
              // Shown if the employee has not added a description.
              // ---------------------------------------------------

              _buildSectionTitle(
                'About SELF EMPLOYEE',
              ),

              Container(
                width: double.infinity,

                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
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
                      Icons.person_outline,
                      color:
                          Color(
                        0xFF198B35,
                      ),
                    ),

                    SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child:
                          Text(

                        'This SELF EMPLOYEE has not added a description yet.',

                        style:
                            TextStyle(

                          fontSize:
                              15,

                          height:
                              1.5,

                          color:
                              Colors.black54,

                        ),

                      ),
                    ),

                  ],

                ),

              ),

            ],


            // =====================================================
            // LOCATION INFORMATION
            //
            // Does NOT display exact coordinates.
            // =====================================================

            const SizedBox(
              height: 20,
            ),


            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
              ),

              child:
                  Container(

                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  14,
                ),

                decoration:
                    BoxDecoration(

                  color:
                      const Color(
                    0xFFF1F8F3,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),

                  border:
                      Border.all(

                    color:
                        const Color(
                      0xFFD7EBDD,
                    ),

                  ),

                ),

                child:
                    Row(

                  children: [

                    Container(

                      width:
                          42,

                      height:
                          42,

                      decoration:
                          const BoxDecoration(

                        color:
                            Color(
                          0xFFE8F5E9,
                        ),

                        shape:
                            BoxShape.circle,

                      ),

                      child:
                          Icon(

                        hasValidLocation

                            ? Icons.location_on

                            : Icons.location_off_outlined,

                        color:
                            hasValidLocation

                                ? const Color(
                                    0xFF198B35,
                                  )

                                : Colors.grey,

                      ),

                    ),


                    const SizedBox(
                      width: 12,
                    ),


                    Expanded(

                      child:
                          Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          const Text(

                            'Employee Location',

                            style:
                                TextStyle(

                              fontSize:
                                  15,

                              fontWeight:
                                  FontWeight.bold,

                            ),

                          ),


                          const SizedBox(
                            height: 4,
                          ),


                          Text(

                            hasValidLocation

                                ? 'Location is available. Tap LOCATION to view it on the map.'

                                : 'Employee location is currently unavailable.',

                            style:
                                const TextStyle(

                              fontSize:
                                  13,

                              color:
                                  Colors.black54,

                              height:
                                  1.3,

                            ),

                          ),

                        ],

                      ),

                    ),

                  ],

                ),

              ),

            ),


            // =====================================================
            // ACTION BUTTONS
            // =====================================================

            _buildActionButtons(),


            // =====================================================
            // PRIVACY NOTE
            // =====================================================

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 24,
              ),

              child:
                  Center(

                child:
                    Text(

                  'The mobile number is kept private. You can contact this SELF EMPLOYEE using the CALL or CHAT buttons.',

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(

                    fontSize:
                        12,

                    color:
                        Colors.grey,

                    height:
                        1.4,

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
  // BUILD
  // =============================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      backgroundColor:
          const Color(
        0xFFF7F8F7,
      ),


      // ===========================================================
      // APP BAR
      // ===========================================================

      appBar:
          AppBar(

        elevation:
            0,

        centerTitle:
            true,

        backgroundColor:
            Colors.white,

        foregroundColor:
            const Color(
          0xFF12652F,
        ),


        title:
            const Text(

          'SELF EMPLOYEE PROFILE',

          style:
              TextStyle(

            fontSize:
                17,

            fontWeight:
                FontWeight.bold,

          ),

        ),


        // ---------------------------------------------------------
        // BACK BUTTON
        // ---------------------------------------------------------

        leading:
            IconButton(

          icon:
              const Icon(
            Icons.arrow_back,
          ),

          onPressed:
              () {

            Navigator.of(context).pop();

          },

        ),

      ),


      // ===========================================================
      // BODY
      // ===========================================================

      body:
          _buildProfileBody(),

    );

  }

}