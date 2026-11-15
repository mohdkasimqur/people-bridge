import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:url_launcher/url_launcher.dart';

class ScreenTaxiCommercialProfile
    extends StatefulWidget {
  final Map<String, dynamic> driver;

  const ScreenTaxiCommercialProfile({
    super.key,
    required this.driver,
  });

  @override
  State<ScreenTaxiCommercialProfile>
      createState() =>
          _ScreenTaxiCommercialProfileState();
}

class _ScreenTaxiCommercialProfileState
    extends State<ScreenTaxiCommercialProfile> {

  // ==========================================================
  // DRIVER VALUES
  // ==========================================================

  String get driverName =>
      widget.driver['name']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? widget.driver['name']
              .toString()
              .trim()
          : 'Driver';

  String get vehicle =>
      widget.driver['vehicle']
          ?.toString()
          .trim() ??
      '';

  String get vehicleName =>
      widget.driver['vehicleName']
          ?.toString()
          .trim() ??
      '';

  String get vehicleNumber =>
      widget.driver['vehicleNumber']
          ?.toString()
          .trim() ??
      '';

  String get profilePhotoUrl =>
      widget.driver['profilePhotoUrl']
          ?.toString()
          .trim() ??
      '';

  String get secondaryPhone =>
      widget.driver['secondaryPhone']
          ?.toString()
          .trim() ??
      '';

  String get uid =>
      widget.driver['uid']
          ?.toString()
          .trim() ??
      '';

  double? get distanceKm {
    final dynamic value =
        widget.driver['distanceKm'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  // ==========================================================
  // CALL
  // ==========================================================

  Future<void> _callDriver() async {
    String phone =
        secondaryPhone;

    // --------------------------------------------------------
    // If secondary phone is empty, use primary mobile
    // --------------------------------------------------------

    if (phone.isEmpty) {
      phone =
          widget.driver['mobile']
                  ?.toString()
                  .trim() ??
              '';
    }

    if (phone.isEmpty) {
      _showMessage(
        'No phone number is available for this driver.',
      );
      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final bool launched =
          await launchUrl(uri);

      if (!launched) {
        _showMessage(
          'Could not open the phone app.',
        );
      }
    } catch (e) {
      debugPrint(
        'Call error: $e',
      );

      _showMessage(
        'Could not make the call.',
      );
    }
  }

  // ==========================================================
  // CHAT
  // ==========================================================

  void _openChat() {
    if (uid.isEmpty) {
      _showMessage(
        'Driver information is unavailable.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenMessage(
          chatUser: {
            'uid': uid,
            'name': driverName,
            'workerName': driverName,
            'providerType':
                'taxi_commercial',
            'role':
                'taxi_commercial',
          },
        ),
      ),
    );
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black,
        elevation: 0,

        title: const Text(
          'Driver Profile',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            30,
          ),

          child: Column(
            children: [

              // =================================================
              // PROFILE PHOTO
              // =================================================

              _buildProfilePhoto(),

              const SizedBox(height: 14),

              // =================================================
              // NAME
              // =================================================

              Text(
                driverName,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              // =================================================
              // VEHICLE
              // =================================================

              if (vehicle.isNotEmpty)
                Text(
                  vehicle,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

              const SizedBox(height: 8),

              // =================================================
              // LIVE / DISTANCE
              // =================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [

                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        const BoxDecoration(
                      color: Colors.green,
                      shape:
                          BoxShape.circle,
                    ),
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  const Text(
                    'LIVE',
                    style:
                        TextStyle(
                      color:
                          Colors.green,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  if (distanceKm !=
                      null) ...[
                    const SizedBox(
                      width: 12,
                    ),
                    const Text(
                      '•',style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      '${distanceKm!.toStringAsFixed(1)} km away',
                      style:
                          TextStyle(
                        fontSize: 12,
                        color: Colors
                            .grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 22),

              // =================================================
              // DETAILS CARD
              // =================================================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(16),

                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),

                child: Column(
                  children: [

                    if (vehicle.isNotEmpty)
                      _detailRow(
                        icon:
                            Icons.local_taxi_outlined,
                        title:
                            'Vehicle Category',
                        value: vehicle,
                      ),

                    if (vehicleName.isNotEmpty)
                      _detailRow(
                        icon:
                            Icons.directions_car_outlined,
                        title:
                            'Vehicle',
                        value:
                            vehicleName,
                      ),

                    if (vehicleNumber
                        .isNotEmpty)
                      _detailRow(
                        icon:
                            Icons.confirmation_number_outlined,
                        title:
                            'Vehicle Number',
                        value:
                            vehicleNumber,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // CHAT + CALL
              // =================================================

              Row(
                children: [

                  Expanded(
                    child:
                        SizedBox(
                      height: 52,

                      child:
                          OutlinedButton.icon(
                        onPressed:
                            _openChat,

                        icon:
                            const Icon(
                          Icons
                              .chat_bubble_outline,
                        ),

                        label:
                            const Text(
                          'Chat',
                        ),

                        style:
                            OutlinedButton
                                .styleFrom(
                          foregroundColor:
                              Colors.red,
                          side:
                              const BorderSide(
                            color:
                                Colors.red,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                        SizedBox(
                      height: 52,

                      child:
                          ElevatedButton.icon(
                        onPressed:
                            _callDriver,

                        icon:
                            const Icon(
                          Icons.call_outlined,
                        ),

                        label:
                            const Text(
                          'Call',
                        ),

                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              Colors.red,
                          foregroundColor:
                              Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                        ),
                      ),
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

  // ==========================================================
  // PROFILE PHOTO
  // ==========================================================

  Widget _buildProfilePhoto() {
    if (profilePhotoUrl.isEmpty) {
      return Container(
        width: 115,
        height: 115,

        decoration:
            BoxDecoration(
          color: Colors.red
              .withValues(alpha:  0.08),
          shape:
              BoxShape.circle,
        ),

        child: const Icon(
          Icons.person_outline,
          size: 58,
          color: Colors.red,
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        profilePhotoUrl,

        width: 115,
        height: 115,

        fit: BoxFit.cover,

        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            width: 115,
            height: 115,
            color: Colors.red
                .withValues(alpha: 0.08),
            child: const Icon(
              Icons.person_outline,
              size: 58,
              color: Colors.red,
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // DETAIL ROW
  // ==========================================================

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 15,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(
            width: 38,
            height: 38,

            decoration:
                BoxDecoration(
              color: Colors.red
                  .withValues(alpha: 0.08),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),

            child: Icon(
              icon,
              color: Colors.red,
              size: 20,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors
                        .grey.shade600,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}