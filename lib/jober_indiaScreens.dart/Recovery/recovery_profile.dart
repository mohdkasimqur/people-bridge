import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Message/screen_message.dart';

class ScreenRecoveryProfile
    extends StatelessWidget {
  final Map<String, dynamic> driver;
  final double distance;

  const ScreenRecoveryProfile({
    super.key,
    required this.driver,
    required this.distance,
  });

  String formatDistance(
    double distance,
  ) {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }

    return '${distance.toStringAsFixed(1)} km';
  }

  // String categoryName(
  //   String? category,
  // ) {
  //   switch (category) {
  //     case 'flatbed_recovery':
  //       return 'Flatbed Recovery';

  //     case 'tow_truck':
  //       return 'Tow Truck';

  //     default:
  //       return 'Recovery';
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final name =
        driver['username'] ??
            driver['name'] ??
            'Recovery Driver';

    final photo =
        driver['profilePhoto'];

    final vehicleNumber =
        driver['vehicleNumber'] ??
            'Not available';

    // final category =
    //     driver['category']?.toString();

    final uid =
        driver['uid']?.toString();

    return Scaffold(
      backgroundColor:
          const Color(0xFFF9F9F9),

      appBar: AppBar(
        title:
            const Text('Recovery Profile'),
        backgroundColor:
            const Color(0xFF138808),
        foregroundColor:
            Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            // ==================================================
            // PHOTO
            // ==================================================

            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    const Color(
                  0xFFE8F5E9,
                ),
              ),
              clipBehavior:
                  Clip.antiAlias,
              child:
                  photo != null &&
                          photo
                              .toString()
                              .isNotEmpty
                      ? Image.network(
                          photo.toString(),
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stack,
                          ) {
                            return const Icon(
                              Icons
                                  .person,
                              size: 55,
                              color:
                                  Color(
                                0xFF138808,
                              ),
                            );
                          },
                        )
                      : const Icon(
                          Icons.person,
                          size: 55,
                          color:
                              Color(
                            0xFF138808,
                          ),
                        ),
            ),

            const SizedBox(height: 15),

            Text(
              name.toString(),
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 23,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

          //  const SizedBox(height: 6),

            // Text(
            //  // categoryName(category),
            //   style:
            //       const TextStyle(
            //     fontSize: 15,
            //     color:
            //         Color(0xFF138808),
            //     fontWeight:
            //         FontWeight.w600,
            //   ),
            // ),

            const SizedBox(height: 22),

            // ==================================================
            // DETAILS
            // ==================================================

            // _detailCard(
            //   icon:
            //       Icons.location_on_outlined,
            //   title:
            //       'Distance',
            //   value:
            //       formatDistance(
            //     distance,
            //   ),
            // ),

            // _detailCard(
            //   icon:
            //       Icons.local_shipping_outlined,
            //   title:
            //       'Recovery Vehicle',
            //   value:
            //       categoryName(category),
            // ),

            // ==================================================
            // YELLOW VEHICLE NUMBER
            // ==================================================

            Align(
              alignment:
                  Alignment.centerLeft,
              child: const Padding(
                padding:
                    EdgeInsets.only(
                  bottom: 8,
                ),
                child: Text(
                  'Vehicle Number',
                  style:
                      TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 13,
                horizontal: 15,
              ),
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFFFD600,
                ),
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
                border: Border.all(
                  color: Colors.black87,
                ),
              ),
              child: Text(
                vehicleNumber
                    .toString()
                    .toUpperCase(),
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // CHAT
            // ==================================================

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    uid == null ||
                            uid.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ScreenMessage(
                                  chatUser: {
                                    'uid': uid,
                                    'name':
                                        name.toString(),
                                    'photo':
                                        photo,
                                    'role':
                                        'recovery',
                                  },
                                ),
                              ),
                            );
                          },
                icon: const Icon(
                  Icons.chat_bubble_outline,
                ),
                label:
                    const Text('Chat'),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF138808,
                  ),
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // CALL
            // ==================================================

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                // onPressed:
                //     uid == null ||
                //             uid.isEmpty
                //         ? null
                //         : () {
                //             Navigator.push(
                //               context,
                //               MaterialPageRoute(
                //                 builder: (_) =>
                //                     ScreenMessage(
                //                   chatUser: {
                //                     'uid': uid,
                //                     'name':
                //                         name.toString(),
                //                     'photo':
                //                         photo,
                //                     'role':
                //                         'recovery',
                //                   },
                //                 ),
                //               ),
                //             );
                //           },
                onPressed: () async {
  final String secondaryPhone =
      (driver['secondaryPhone'] ?? '').toString().trim();

  if (secondaryPhone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Secondary phone number is not available.',
        ),
      ),
    );
    return;
  }

  final Uri phoneUri = Uri(
    scheme: 'tel',
    path: secondaryPhone,
  );

  try {
    final bool launched = await launchUrl(phoneUri);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the phone dialer.'),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the phone dialer.'),
        ),
      );
    }
  }
},
                icon: const Icon(
                  Icons.call_outlined,
                ),
                label:
                    const Text('Call'),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      const Color(
                    0xFF138808,
                  ),
                  side:
                      const BorderSide(
                    color:
                        Color(0xFF138808),
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Call uses the existing Citizen India in-app calling system.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _detailCard({
  //   required IconData icon,
  //   required String title,
  //   required String value,
  // }) {
  //   return Container(
  //     width: double.infinity,
  //     margin:
  //         const EdgeInsets.only(
  //       bottom: 12,
  //     ),
  //     padding:
  //         const EdgeInsets.all(15),
  //     decoration:
  //         BoxDecoration(
  //       color: Colors.white,
  //       borderRadius:
  //           BorderRadius.circular(15),
  //       border: Border.all(
  //         color:
  //             const Color(0xFFE0E0E0),
  //       ),
  //     ),
  //     child: Row(
  //       children: [
  //         Icon(
  //           icon,
  //           color:
  //               const Color(0xFF138808),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment:
  //                 CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 title,
  //                 style:
  //                     const TextStyle(
  //                   fontSize: 12,
  //                   color:
  //                       Colors.grey,
  //                 ),
  //               ),
  //               const SizedBox(height: 3),
  //               Text(
  //                 value,
  //                 style:
  //                     const TextStyle(
  //                   fontSize: 15,
  //                   fontWeight:
  //                       FontWeight.w600,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}