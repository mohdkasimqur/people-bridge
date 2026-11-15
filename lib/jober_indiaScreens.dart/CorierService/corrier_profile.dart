import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:url_launcher/url_launcher.dart';

class ScreenCourierProfile extends StatefulWidget {
  final Map<String, dynamic> courier;
  final String categoryName;

  const ScreenCourierProfile({
    super.key,
    required this.courier,
    required this.categoryName,
  });

  @override
  State<ScreenCourierProfile> createState() =>
      _ScreenCourierProfileState();
}

class _ScreenCourierProfileState
    extends State<ScreenCourierProfile> {

  // ============================================================
  // DATA
  // ============================================================

  String get courierUid {
    return (widget.courier['uid'] ?? '')
        .toString();
  }

  String get courierName {
    return (
      widget.courier['username'] ??
      widget.courier['name'] ??
      'Courier'
    ).toString();
  }

  String get profilePhotoUrl {
    return (
      widget.courier['profilePhotoUrl'] ??
      ''
    ).toString();
  }

  String get secondaryMobile {
    return (
      widget.courier['secondaryMobile'] ??
      ''
    ).toString().trim();
  }

  bool get isLive {
    return widget.courier['isLive'] == true;
  }

  // ============================================================
  // CALL
  // ============================================================

  Future<void> _callCourier() async {
    if (secondaryMobile.isEmpty) {
      _showMessage(
        'Secondary mobile number is not available.',
      );
      return;
    }

    final cleanedNumber =
        secondaryMobile.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    final Uri phoneUri =
        Uri.parse(
      'tel:$cleanedNumber',
    );

    try {
      final launched =
          await launchUrl(
        phoneUri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!launched) {
        _showMessage(
          'Unable to open phone dialer.',
        );
      }
    } catch (e) {
      debugPrint(
        'Courier call error: $e',
      );

      _showMessage(
        'Unable to make the call.',
      );
    }
  }

  // ============================================================
  // CHAT
  // ============================================================

  void _openChat() {
    if (courierUid.isEmpty) {
      _showMessage(
        'Courier information is unavailable.',
      );
      return;
    }

    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ScreenMessage(
      chatUser: {
        'uid': courierUid,
        'name': courierName,
        'role': 'Courier',
        'profilePhotoUrl': profilePhotoUrl,
        'secondaryMobile': secondaryMobile,
      },
    ),
  ),
);
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
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

        title: const Text(
          'Courier Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            30,
          ),

          child: Column(
            children: [

              // =================================================
              // PROFILE PHOTO
              // =================================================

              _profilePhoto(),

              const SizedBox(height: 16),

              // =================================================
              // NAME
              // =================================================

              Text(
                courierName,

                textAlign:
                    TextAlign.center,

                style: const TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              // =================================================
              // LIVE STATUS
              // =================================================

              if (isLive)
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFE8F5E9,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),

                  child: const Row(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [
                      Icon(
                        Icons.circle,
                        size: 9,
                        color:
                            Colors.green,
                      ),

                      SizedBox(width: 5),

                      Text(
                        'Available',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.green,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 22),

              // =================================================
              // VEHICLE INFORMATION
              // =================================================

              _infoCard(),

              const SizedBox(height: 20),

              // =================================================
              // CALL / CHAT
              // =================================================

              Row(
                children: [

                  Expanded(
                    child:
                        _actionButton(
                      icon:
                          Icons.phone_outlined,
                      label: 'Call',
                      backgroundColor:
                          const Color(
                        0xFFE53935,
                      ),
                      foregroundColor:
                          Colors.white,
                      onPressed:
                          _callCourier,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child:
                        _actionButton(
                      icon:
                          Icons.chat_bubble_outline,
                      label: 'Chat',
                      backgroundColor:
                          Colors.white,
                      foregroundColor:
                          const Color(
                        0xFFE53935,
                      ),
                      border: true,
                      onPressed:
                          _openChat,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE PHOTO
  // ============================================================

  Widget _profilePhoto() {
    return Container(
      width: 120,
      height: 120,

      decoration:
          const BoxDecoration(
        color: Color(0xFFEFEFEF),
        shape: BoxShape.circle,
      ),

      child: ClipOval(
        child: profilePhotoUrl
                .isNotEmpty
            ? Image.network(
                profilePhotoUrl,
                fit: BoxFit.cover,

                errorBuilder:
                    (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Icon(
                    Icons.person_outline,
                    size: 60,
                    color: Colors.grey,
                  );
                },
              )
            : const Icon(
                Icons.person_outline,
                size: 60,
                color: Colors.grey,
              ),
      ),
    );
  }

  // ============================================================
  // INFORMATION CARD
  // ============================================================

  Widget _infoCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: Colors.black12,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(
            'Vehicle Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          _detailRow(
            icon:
                Icons.local_shipping_outlined,
            title:
                'Vehicle Category',
            value:
                widget.categoryName,
          ),

          if (widget.courier[
                  'vehicleName'] !=
              null)
            _detailRow(
              icon:
                  Icons.directions_car_outlined,
              title: 'Vehicle',
              value:
                  widget.courier[
                          'vehicleName']
                      .toString(),
            ),

          if (widget.courier[
                  'vehicleNumber'] !=
              null)
            _detailRow(
              icon:
                  Icons.confirmation_number_outlined,
              title:
                  'Vehicle Number',
              value:
                  widget.courier[
                          'vehicleNumber']
                      .toString(),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(
            width: 38,
            height: 38,

            decoration:
                const BoxDecoration(
              color: Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),

            child: Icon(
              icon,
              size: 20,
              color:
                  Color(0xFFE53935),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 14,
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

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onPressed,
    bool border = false,
  }) {
    return SizedBox(
      height: 52,

      child: ElevatedButton.icon(
        onPressed: onPressed,

        icon: Icon(
          icon,
          color: foregroundColor,
        ),

        label: Text(
          label,
          style: TextStyle(
            color: foregroundColor,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              backgroundColor,

          elevation: 0,

          side: border
              ? const BorderSide(
                  color:
                      Color(0xFFE53935),
                )
              : null,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}