// import 'package:flutter/material.dart';
// import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ScreenLaboratoryProfile extends StatefulWidget {
//   final Map<String, dynamic> laboratory;

//   const ScreenLaboratoryProfile({
//     super.key,
//     required this.laboratory,
//   });

//   @override
//   State<ScreenLaboratoryProfile> createState() =>
//       _ScreenLaboratoryProfileState();
// }

// class _ScreenLaboratoryProfileState
//     extends State<ScreenLaboratoryProfile> {

//   late Map<String, dynamic> laboratory;

//   @override
//   void initState() {
//     super.initState();

//     laboratory =
//         Map<String, dynamic>.from(
//       widget.laboratory,
//     );
//   }

//   String get laboratoryName {
//     final displayName =
//         laboratory['displayName']
//             ?.toString()
//             .trim();

//     if (displayName != null &&
//         displayName.isNotEmpty) {
//       return displayName;
//     }

//     final name =
//         laboratory['laboratoryName']
//             ?.toString()
//             .trim();

//     if (name != null && name.isNotEmpty) {
//       return name;
//     }

//     return 'Laboratory';
//   }

//   String get categoriesText {
//     final categories =
//         laboratory['categories'];

//     if (categories is List) {
//       final values = categories
//           .map(
//             (category) =>
//                 category.toString().trim(),
//           )
//           .where(
//             (category) =>
//                 category.isNotEmpty,
//           )
//           .toList();

//       if (values.isNotEmpty) {
//         return values.join(', ');
//       }
//     }

//     final category =
//         laboratory['category']
//             ?.toString()
//             .trim();

//     if (category != null &&
//         category.isNotEmpty) {
//       return category;
//     }

//     return 'Laboratory';
//   }

//   String get openingTime {
//     final value =
//         laboratory['openingTime']
//             ?.toString()
//             .trim();

//     if (value == null || value.isEmpty) {
//       return '--';
//     }

//     return value;
//   }

//   String get closingTime {
//     final value =
//         laboratory['closingTime']
//             ?.toString()
//             .trim();

//     if (value == null || value.isEmpty) {
//       return '--';
//     }

//     return value;
//   }

//   double? _readDouble(dynamic value) {
//     if (value is num) {
//       return value.toDouble();
//     }

//     if (value is String) {
//       return double.tryParse(value);
//     }

//     return null;
//   }

//   double? get latitude {
//     return _readDouble(
//       laboratory['latitude'],
//     );
//   }

//   double? get longitude {
//     return _readDouble(
//       laboratory['longitude'],
//     );
//   }

//   double? get distanceKm {
//     return _readDouble(
//       laboratory['distanceKm'],
//     );
//   }

//   String? get phoneNumber {
//     final mobile =
//         laboratory['mobile']
//             ?.toString()
//             .trim();

//     if (mobile == null || mobile.isEmpty) {
//       return null;
//     }

//     return mobile;
//   }

//   String? get photoUrl {
//     final value =
//         laboratory['photoUrl']
//             ?.toString()
//             .trim();

//     if (value == null || value.isEmpty) {
//       return null;
//     }

//     return value;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor:
//           const Color(0xFFF7F8F7),

//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,

//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back,
//             color: Colors.black,
//             size: 30,
//           ),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),

//         title: RichText(
//           text: const TextSpan(
//             children: [
//               TextSpan(
//                 text: 'Laboratory ',
//                 style: TextStyle(
//                   color: Color(0xFF08744F),
//                   fontSize: 23,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               TextSpan(
//                 text: 'Profile',
//                 style: TextStyle(
//                   color: Color(0xFFE87516),
//                   fontSize: 23,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),

//       body: SafeArea(
//         child: SingleChildScrollView(
//           physics:
//               const BouncingScrollPhysics(),

//           child: Column(
//             children: [
//               _photoSection(),

//               Padding(
//                 padding:
//                     const EdgeInsets.fromLTRB(
//                   20,
//                   20,
//                   20,
//                   30,
//                 ),
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                   children: [
//                     _nameSection(),

//                     const SizedBox(
//                       height: 18,
//                     ),

//                     _categorySection(),

//                     const SizedBox(
//                       height: 18,
//                     ),

//                     _distanceSection(),

//                     const SizedBox(
//                       height: 18,
//                     ),

//                     _timingSection(),

//                     const SizedBox(
//                       height: 24,
//                     ),

//                     _actionButtons(),

//                     const SizedBox(
//                       height: 22,
//                     ),

//                     _locationInformation(),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _photoSection() {
//     return SizedBox(
//       width: double.infinity,
//       height: 230,
//       child: photoUrl != null
//           ? Image.network(
//               photoUrl!,
//               fit: BoxFit.cover,
//               errorBuilder:
//                   (_, _, _) {
//                 return _defaultPhoto();
//               },
//             )
//           : _defaultPhoto(),
//     );
//   }

//   Widget _defaultPhoto() {
//     return Container(
//       width: double.infinity,
//       height: 230,
//       color: const Color(0xFFEFF8EF),
//       child: const Center(
//         child: Icon(
//           Icons.biotech_outlined,
//           color: Color(0xFF16803C),
//           size: 90,
//         ),
//       ),
//     );
//   }

//   Widget _nameSection() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         Text(
//           laboratoryName,
//           style: const TextStyle(
//             color: Color(0xFF202124),
//             fontSize: 26,
//             fontWeight: FontWeight.bold,
//           ),
//         ),

//         const SizedBox(height: 7),

//         const Text(
//           'Laboratory',
//           style: TextStyle(
//             color: Color(0xFF16803C),
//             fontSize: 15,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ],
//     );
//   }
//   Widget _categorySection() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(18),
//         border: Border.all(
//           color: const Color(0xFFE1E1E1),
//         ),
//       ),
//       child: Row(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color:
//                   const Color(0xFFEFF8EF),
//               borderRadius:
//                   BorderRadius.circular(13),
//             ),
//             child: const Icon(
//               Icons.biotech_outlined,
//               color: Color(0xFF16803C),
//               size: 25,
//             ),
//           ),

//           const SizedBox(width: 13),

//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Category',
//                   style: TextStyle(
//                     color: Colors.grey,
//                     fontSize: 13,
//                   ),
//                 ),

//                 const SizedBox(height: 5),

//                 Text(
//                   categoriesText,
//                   style: const TextStyle(
//                     color:
//                         Color(0xFF202124),
//                     fontSize: 15,
//                     fontWeight:
//                         FontWeight.w600,
//                     height: 1.35,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _distanceSection() {
//     final distance = distanceKm;

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(18),
//         border: Border.all(
//           color: const Color(0xFFE1E1E1),
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color:
//                   const Color(0xFFFFF3E8),
//               borderRadius:
//                   BorderRadius.circular(13),
//             ),
//             child: const Icon(
//               Icons.location_on_outlined,
//               color: Color(0xFFE87516),
//               size: 25,
//             ),
//           ),

//           const SizedBox(width: 13),

//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Distance',
//                   style: TextStyle(
//                     color: Colors.grey,
//                     fontSize: 13,
//                   ),
//                 ),

//                 const SizedBox(height: 5),

//                 Text(
//                   distance == null
//                       ? 'Distance unavailable'
//                       : '${distance.toStringAsFixed(1)} KM Away',
//                   style: const TextStyle(
//                     color:
//                         Color(0xFF202124),
//                     fontSize: 16,
//                     fontWeight:
//                         FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _timingSection() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(18),
//         border: Border.all(
//           color: const Color(0xFFE1E1E1),
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: _timeItem(
//               icon: Icons.login_outlined,
//               title: 'Opening Time',
//               value: openingTime,
//             ),
//           ),

//           Container(
//             width: 1,
//             height: 55,
//             color:
//                 const Color(0xFFE5E5E5),
//           ),

//           Expanded(
//             child: _timeItem(
//               icon: Icons.logout_outlined,
//               title: 'Closing Time',
//               value: closingTime,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _timeItem({
//     required IconData icon,
//     required String title,
//     required String value,
//   }) {
//     return Padding(
//       padding:
//           const EdgeInsets.symmetric(
//         horizontal: 10,
//       ),
//       child: Column(
//         children: [
//           Icon(
//             icon,
//             color:
//                 const Color(0xFF16803C),
//             size: 24,
//           ),

//           const SizedBox(height: 7),

//           Text(
//             title,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               color: Colors.grey,
//               fontSize: 12,
//             ),
//           ),

//           const SizedBox(height: 4),

//           Text(
//             value,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               color:
//                   Color(0xFF202124),
//               fontSize: 14,
//               fontWeight:
//                   FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _actionButtons() {
//     return Row(
//       children: [
//         Expanded(
//           child: _actionButton(
//             icon: Icons.call_outlined,
//             label: 'CALL',
//             color:
//                 const Color(0xFF159B16),
//             onPressed: _callLaboratory,
//           ),
//         ),

//         const SizedBox(width: 10),

//         Expanded(
//           child: _actionButton(
//             icon: Icons.chat_outlined,
//             label: 'CHAT',
//             color:
//                 const Color(0xFF08744F),
//             onPressed: _openChat,
//           ),
//         ),

//         const SizedBox(width: 10),

//         Expanded(
//           child: _actionButton(
//             icon: Icons.location_on_outlined,
//             label: 'LOCATION',
//             color:
//                 const Color(0xFFE87516),
//             onPressed: _openLocation,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _actionButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onPressed,
//   }) {
//     return SizedBox(
//       height: 58,
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: color,
//           foregroundColor: Colors.white,
//           elevation: 0,
//           padding:
//               const EdgeInsets.symmetric(
//             horizontal: 5,
//           ),
//           shape:
//               RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(18),
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment:
//               MainAxisAlignment.center,
//           children: [
//             Icon(
//               icon,
//               size: 21,
//             ),
//             const SizedBox(height: 3),
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 10,
//                 fontWeight:
//                     FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//   Widget _locationInformation() {
//     final hasLocation =
//         latitude != null &&
//             longitude != null;

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(18),
//         border: Border.all(
//           color: const Color(0xFFE1E1E1),
//         ),
//       ),
//       child: Row(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,
//         children: [
//           const Icon(
//             Icons.map_outlined,
//             color: Color(0xFFE87516),
//             size: 25,
//           ),

//           const SizedBox(width: 12),

//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Laboratory Location',
//                   style: TextStyle(
//                     color:
//                         Color(0xFF202124),
//                     fontSize: 15,
//                     fontWeight:
//                         FontWeight.bold,
//                   ),
//                 ),

//                 const SizedBox(height: 5),

//                 Text(
//                   hasLocation
//                       ? 'Location saved during registration'
//                       : 'Location unavailable',
//                   style: const TextStyle(
//                     color: Colors.grey,
//                     fontSize: 13,
//                     height: 1.4,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _callLaboratory() async {
//     final mobile = phoneNumber;

//     if (mobile == null) {
//       _showMessage(
//         'Laboratory phone number is unavailable.',
//       );
//       return;
//     }

//     final cleanedNumber =
//         mobile.replaceAll(
//       RegExp(r'[^0-9+]'),
//       '',
//     );

//     final uri = Uri(
//       scheme: 'tel',
//       path: cleanedNumber,
//     );

//     try {
//       final canCall =
//           await canLaunchUrl(uri);

//       if (!canCall) {
//         _showMessage(
//           'Unable to open the phone app.',
//         );
//         return;
//       }

//       await launchUrl(uri);
//     } catch (_) {
//       _showMessage(
//         'Unable to make the call.',
//       );
//     }
//   }

//   Future<void> _openLocation() async {
//     final lat = latitude;
//     final lng = longitude;

//     if (lat == null || lng == null) {
//       _showMessage(
//         'Laboratory location is unavailable.',
//       );
//       return;
//     }

//     final uri = Uri.parse(
//       'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
//     );

//     try {
//       final canOpen =
//           await canLaunchUrl(uri);

//       if (!canOpen) {
//         _showMessage(
//           'Unable to open Google Maps.',
//         );
//         return;
//       }

//       await launchUrl(
//         uri,
//         mode:
//             LaunchMode.externalApplication,
//       );
//     } catch (_) {
//       _showMessage(
//         'Unable to open the laboratory location.',
//       );
//     }
//   }

//   void _openChat() {
//     final labUid =
//         laboratory['uid']
//             ?.toString()
//             .trim();

//     final mobile =
//         laboratory['mobile']
//             ?.toString()
//             .trim();

//     final chatData =
//         <String, dynamic>{
//       'uid': labUid ?? '',
//       'name': laboratoryName,
//       'workerName': laboratoryName,
//       'laboratoryName':
//           laboratoryName,
//       'displayName':
//           laboratoryName,
//       'mobile': mobile ?? '',
//       'role': 'laboratory',
//       'categories':
//           laboratory['categories'] ?? [],
//       'latitude':
//           laboratory['latitude'],
//       'longitude':
//           laboratory['longitude'],
//       'locationAddress':
//           laboratory['locationAddress'] ??
//               '',
//       'photoUrl':
//           laboratory['photoUrl'] ?? '',
//     };

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ScreenMessage(
//           chatUser: chatData,
//         ),
//       ),
//     );
//   }

//   void _showMessage(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context)
//         .showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior:
//             SnackBarBehavior.floating,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';

class ScreenLaboratoryProfile extends StatefulWidget {
  final Map<String, dynamic> laboratory;

  const ScreenLaboratoryProfile({
    super.key,
    required this.laboratory,
  });

  @override
  State<ScreenLaboratoryProfile> createState() =>
      _ScreenLaboratoryProfileState();
}

class _ScreenLaboratoryProfileState
    extends State<ScreenLaboratoryProfile> {
  static const Color primaryGreen = Color(0xFF16803C);
  static const Color darkGreen = Color(0xFF12652F);
  static const Color backgroundColor = Color(0xFFF7F7F7);

  double? _distanceKm;
  bool _loadingDistance = false;

  Map<String, dynamic> get laboratory => widget.laboratory;

  String get laboratoryName {
    return (laboratory['laboratoryName'] ??
            laboratory['displayName'] ??
            laboratory['name'] ??
            'Laboratory')
        .toString();
  }

  String get ownerName {
    return (laboratory['name'] ?? '').toString();
  }

  String get secondaryMobile {
    return (laboratory['secondaryMobile'] ??
            laboratory['secondaryMobileNumber'] ??
            '')
        .toString()
        .trim();
  }

  String get photoUrl {
    return (laboratory['profilePhotoUrl'] ??
            laboratory['photoUrl'] ??
            '')
        .toString();
  }

  String get locationAddress {
    return (laboratory['locationAddress'] ??
            laboratory['nearestTown'] ??
            '')
        .toString();
  }

  String get categoriesText {
    final categories = laboratory['categories'];

    if (categories is List) {
      return categories
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .join(', ');
    }

    return (laboratory['category'] ?? 'Laboratory').toString();
  }

  String get openingHours {
    if (laboratory['isOpen24Hours'] == true) {
      return 'Open 24 Hours';
    }

    final opening = laboratory['openingTime']?.toString() ?? '';
    final closing = laboratory['closingTime']?.toString() ?? '';

    if (opening.isEmpty && closing.isEmpty) {
      return 'Not specified';
    }

    return '$opening - $closing';
  }

  double? _readDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  double? get latitude {
    final currentLocation = laboratory['currentLocation'];

    if (currentLocation is GeoPoint) {
      return currentLocation.latitude;
    }

    if (currentLocation is Map) {
      return _readDouble(
        currentLocation['latitude'] ?? currentLocation['lat'],
      );
    }

    return _readDouble(laboratory['latitude'] ?? laboratory['lat']);
  }

  double? get longitude {
    final currentLocation = laboratory['currentLocation'];

    if (currentLocation is GeoPoint) {
      return currentLocation.longitude;
    }

    if (currentLocation is Map) {
      return _readDouble(
        currentLocation['longitude'] ?? currentLocation['lng'],
      );
    }

    return _readDouble(laboratory['longitude'] ?? laboratory['lng']);
  }

  @override
  void initState() {
    super.initState();

    _loadDistance();
  }

  Future<void> _loadDistance() async {
    final labLat = latitude;
    final labLng = longitude;

    if (labLat == null || labLng == null) return;

    setState(() {
      _loadingDistance = true;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) return;

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      final distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        labLat,
        labLng,
      );

      if (!mounted) return;

      setState(() {
        _distanceKm = distanceInMeters / 1000;
      });
    } catch (e) {
      debugPrint('Laboratory distance error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingDistance = false;
        });
      }
    }
  }

  // ============================================================
  // CALL LABORATORY - SECONDARY MOBILE ONLY
  // ============================================================

  Future<void> _callLaboratory() async {
    if (secondaryMobile.isEmpty) {
      _showMessage('Secondary mobile number is not available.');
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: secondaryMobile,
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showMessage('Unable to open the phone dialer.');
      }
    } catch (e) {
      debugPrint('Call error: $e');
      _showMessage('Unable to make the call.');
    }
  }

  // ============================================================
  // OPEN LOCATION
  // ============================================================

  Future<void> _openLocation() async {
    final labLat = latitude;
    final labLng = longitude;

    String destination;

    if (labLat != null && labLng != null) {
      destination = '$labLat,$labLng';
    } else if (locationAddress.isNotEmpty) {
      destination = locationAddress;
    } else {
      _showMessage('Laboratory location is not available.');
      return;
    }

    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {
        'api': '1',
        'destination': destination,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showMessage('Unable to open Google Maps.');
      }
    } catch (e) {
      debugPrint('Location error: $e');
      _showMessage('Unable to open the location.');
    }
  }

  // ============================================================
  // OPEN CHAT
  // ============================================================

  void _openChat() {
    final chatData = {
      'uid': laboratory['uid'] ?? '',
      'name': ownerName,
      'workerName': ownerName,
      'laboratoryName': laboratoryName,
      'displayName': laboratoryName,
      'mobile': laboratory['mobile'] ?? '',
      'secondaryMobile': secondaryMobile,
      'role': 'laboratory',
      'categories': laboratory['categories'] ?? [],
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'photoUrl': photoUrl,
      'profilePhotoUrl': photoUrl,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenMessage(
          chatUser: chatData,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryGreen,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not available' : value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
    required String title,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 5,
          ),
          decoration: BoxDecoration(
            color: filled ? primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: primaryGreen,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: filled ? Colors.white : primaryGreen,
                size: 23,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: filled ? Colors.white : primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 27),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryGreen,
            darkGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 112,
            width: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return const Icon(
                          Icons.biotech,
                          color: primaryGreen,
                          size: 55,
                        );
                      },
                    )
                  : const Icon(
                      Icons.biotech,
                      color: primaryGreen,
                      size: 55,
                    ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            laboratoryName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            categoriesText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE DETAILS
  // ============================================================

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.biotech,
            title: 'Laboratory Categories',
            value: categoriesText,
          ),
          const Divider(height: 1),
          _infoRow(
            icon: Icons.person_outline,
            title: 'Owner Name',
            value: ownerName,
          ),
          const Divider(height: 1),
          _infoRow(
            icon: Icons.location_on_outlined,
            title: 'Location',
            value: locationAddress,
          ),
          const Divider(height: 1),
          _infoRow(
            icon: Icons.access_time,
            title: 'Opening Hours',
            value: openingHours,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.social_distance,
                    color: primaryGreen,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distance',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _distanceKm != null
                            ? '${_distanceKm!.toStringAsFixed(1)} km away'
                            : _loadingDistance
                                ? 'Calculating distance...'
                                : 'Distance unavailable',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
  // ABOUT SECTION
  // ============================================================

  Widget _buildAboutSection() {
    final about = (laboratory['about'] ??
            laboratory['description'] ??
            '')
        .toString()
        .trim();

    if (about.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Laboratory',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            about,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade700,
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Laboratory Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ACTION BUTTONS
                  Row(
                    children: [
                      _actionButton(
                        icon: Icons.call,
                        title: 'Call',
                        onTap: _callLaboratory,
                      ),
                      const SizedBox(width: 10),
                      _actionButton(
                        icon: Icons.location_on,
                        title: 'Location',
                        onTap: _openLocation,
                      ),
                      const SizedBox(width: 10),
                      _actionButton(
                        icon: Icons.chat,
                        title: 'Chat',
                        onTap: _openChat,
                        filled: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Laboratory Information',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildDetailsCard(),

                  const SizedBox(height: 18),

                  _buildAboutSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}