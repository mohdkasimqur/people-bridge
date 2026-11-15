import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:url_launcher/url_launcher.dart';

// class ScreenOtherBusinessProfile
//     extends StatelessWidget {
//   final OtherBusinessData business;

//   const ScreenOtherBusinessProfile({
//     super.key,
//     required this.business,
//   });

//   Future<void> callBusiness(
//     BuildContext context,
//   ) async {
//     final number =
//         business.secondaryMobile.trim();

//     if (number.isEmpty) {
//       ScaffoldMessenger.of(context)
//         .showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Secondary number is not available.',
//             ),
//           ),
//         );

//       return;
//     }

//     final uri = Uri.parse(
//       'tel:$number',
//     );

//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     }
//   }

// Future<void> openLocation(
//   BuildContext context,
// ) async {
//   final location = business.location;

//   if (location == null) {
//     if (!context.mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(
//           'Location has not been shared by this business.',
//         ),
//       ),
//     );

//     return;
//   }

//   if (location.latitude == null ||
//       location.longitude == null) {
//     if (!context.mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(
//           'This business has provided a location name, but no map coordinates.',
//         ),
//       ),
//     );

//     return;
//   }

//   final double lat = location.latitude!;
//   final double lng = location.longitude!;

//   final Uri uri = Uri.parse(
//     'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
//   );

//   final bool canOpen = await canLaunchUrl(uri);

//   // IMPORTANT: context is used after await,
//   // so check mounted first.
//   if (!context.mounted) return;

//   if (canOpen) {
//     await launchUrl(
//       uri,
//       mode: LaunchMode.externalApplication,
//     );
//   } else {
//     if (!context.mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(
//           'Unable to open Google Maps.',
//         ),
//       ),
//     );
//   }
// }

//   void openChat(BuildContext context) {
//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (_) => ScreenMessage(
//         chatUser: {
//           'uid': business.uid,
//           'name': business.name,
//           'profilePhotoUrl':
//               business.profilePhotoUrl ?? '',
//           'phone': business.secondaryMobile,
//           'role': 'other_business',
//         },
//       ),
//     ),
//   );
// }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Business Profile',
//         ),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(20),
//         children: [
//           const SizedBox(height: 10),

//           Center(
//             child: CircleAvatar(
//               radius: 60,
//               backgroundImage:
//                   business.profilePhotoUrl !=
//                               null &&
//                           business.profilePhotoUrl!
//                               .isNotEmpty
//                       ? NetworkImage(
//                           business.profilePhotoUrl!,
//                         )
//                       : null,
//               child:
//                   business.profilePhotoUrl ==
//                               null ||
//                           business.profilePhotoUrl!
//                               .isEmpty
//                       ? const Icon(
//                           Icons.business,
//                           size: 55,
//                         )
//                       : null,
//             ),
//           ),

//           const SizedBox(height: 20),

//           Center(
//             child: Text(
//               business.name,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),

//           const SizedBox(height: 12),

//           Wrap(
//             alignment:
//                 WrapAlignment.center,
//             spacing: 8,
//             runSpacing: 8,
//             children: business.categories
//                 .map(
//                   (category) => Chip(
//                     label: Text(category),
//                   ),
//                 )
//                 .toList(),
//           ),

//           const SizedBox(height: 30),

//           // ------------------------------------------------------
//           // CALL
//           // ------------------------------------------------------

//           SizedBox(
//             height: 52,
//             child: ElevatedButton.icon(
//               onPressed: () =>
//                   callBusiness(context),
//               icon: const Icon(
//                 Icons.call_outlined,
//               ),
//               label: const Text(
//                 'Call',
//               ),
//             ),
//           ),

//           const SizedBox(height: 12),

//           // ------------------------------------------------------
//           // CHAT
//           // ------------------------------------------------------

//           SizedBox(
//             height: 52,
//             child: OutlinedButton.icon(
//               onPressed: () =>
//                   openChat(context),
//               icon: const Icon(
//                 Icons.chat_bubble_outline,
//               ),
//               label: const Text(
//                 'Chat',
//               ),
//             ),
//           ),

//           const SizedBox(height: 12),

//           // ------------------------------------------------------
//           // LOCATION
//           // ------------------------------------------------------

//           SizedBox(
//             height: 52,
//             child: OutlinedButton.icon(
//               onPressed: () =>
//                   openLocation(context),
//               icon: const Icon(
//                 Icons.location_on_outlined,
//               ),
//               label: const Text(
//                 'Location',
//               ),
//             ),
//           ),

//           if (business.location == null)
//             const Padding(
//               padding:
//                   EdgeInsets.only(top: 12),
//               child: Text(
//                 'This business has not shared its current location.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: Colors.grey,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

class ScreenOtherBusinessProfile extends StatefulWidget {
  final Map<String, dynamic> business;

  const ScreenOtherBusinessProfile({
    super.key,
    required this.business,
  });

  @override
  State<ScreenOtherBusinessProfile> createState() =>
      _ScreenOtherBusinessProfileState();
}

class _ScreenOtherBusinessProfileState
    extends State<ScreenOtherBusinessProfile> {
  static const Color primaryGreen = Color(0xFF16803C);
  static const Color darkGreen = Color(0xFF12652F);
  static const Color backgroundColor = Color(0xFFF7F7F7);

  double? _distanceKm;
  bool _loadingDistance = false;

  Map<String, dynamic> get business => widget.business;

  // ============================================================
  // BUSINESS DETAILS
  // ============================================================

  String get businessName {
    return (business['name'] ?? 'Business').toString();
  }

  String get ownerName {
    return (business['username'] ?? '').toString();
  }

  String get secondaryMobile {
    return (business['secondaryMobile'] ?? '')
        .toString()
        .trim();
  }

  String get primaryMobile {
    return (business['primaryMobile'] ?? '')
        .toString()
        .trim();
  }

  String get photoUrl {
    return (business['profilePhotoUrl'] ?? '')
        .toString()
        .trim();
  }

  String get locationAddress {
    final town = (business['nearestTown'] ?? '').toString().trim();
    final district = (business['district'] ?? '').toString().trim();
    final state = (business['state'] ?? '').toString().trim();

    return [
      town,
      district,
      state,
    ].where((e) => e.isNotEmpty).join(', ');
  }

  String get categoriesText {
    final categories = business['categories'];

    if (categories is List) {
      return categories
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .join(', ');
    }

    return (business['category'] ?? 'Other Business').toString();
  }

  String get openingHours {
    if (business['isOpen24Hours'] == true) {
      return 'Open 24 Hours';
    }

    final opening =
        (business['openingTime'] ?? '').toString().trim();

    final closing =
        (business['closingTime'] ?? '').toString().trim();

    if (opening.isEmpty && closing.isEmpty) {
      return 'Not specified';
    }

    if (opening.isEmpty || closing.isEmpty) {
      return opening.isNotEmpty ? opening : closing;
    }

    return '$opening - $closing';
  }

  // ============================================================
  // LOCATION COORDINATES
  // ============================================================

  double? _readDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  Map? get savedLocation {
    final value = business['location'];

    if (value is Map) {
      return value;
    }

    return null;
  }

  double? get latitude {
    final location = business['location'];

    if (location is GeoPoint) {
      return location.latitude;
    }

    if (location is Map) {
      return _readDouble(
        location['latitude'] ?? location['lat'],
      );
    }

    return _readDouble(
      business['latitude'] ?? business['lat'],
    );
  }

  double? get longitude {
    final location = business['location'];

    if (location is GeoPoint) {
      return location.longitude;
    }

    if (location is Map) {
      return _readDouble(
        location['longitude'] ?? location['lng'],
      );
    }

    return _readDouble(
      business['longitude'] ?? business['lng'],
    );
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadDistance();
  }

  // ============================================================
  // CALCULATE DISTANCE
  // ============================================================

  Future<void> _loadDistance() async {
    final businessLat = latitude;
    final businessLng = longitude;

    if (businessLat == null || businessLng == null) {
      return;
    }

    if (!mounted) return;

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

      final position =
          await Geolocator.getCurrentPosition();

      final distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        businessLat,
        businessLng,
      );

      if (!mounted) return;

      setState(() {
        _distanceKm = distanceInMeters / 1000;
      });
    } catch (e) {
      debugPrint('Other Business distance error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingDistance = false;
        });
      }
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

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
  // CALL BUSINESS - SECONDARY MOBILE
  // ============================================================

  Future<void> _callBusiness() async {
    if (secondaryMobile.isEmpty) {
      _showMessage(
        'Secondary mobile number is not available.',
      );
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
      debugPrint('Other Business call error: $e');
      _showMessage('Unable to make the call.');
    }
  }

  // ============================================================
  // OPEN GOOGLE MAPS
  // ============================================================

  Future<void> _openLocation() async {
    final businessLat = latitude;
    final businessLng = longitude;

    String destination;

    if (businessLat != null && businessLng != null) {
      destination = '$businessLat,$businessLng';
    } else if (locationAddress.isNotEmpty) {
      destination = locationAddress;
    } else {
      _showMessage('Business location is not available.');
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
      debugPrint('Other Business location error: $e');
      _showMessage('Unable to open the location.');
    }
  }

  // ============================================================
  // OPEN CHAT
  // ============================================================

  void _openChat() {
    final chatData = {
      'uid': business['uid'] ?? '',
      'name': businessName,
      'workerName': ownerName,
      'businessName': businessName,
      'displayName': businessName,
      'mobile': primaryMobile,
      'phone': secondaryMobile,
      'secondaryMobile': secondaryMobile,
      'role': 'other_business',
      'categories': business['categories'] ?? [],
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
                          Icons.business,
                          color: primaryGreen,
                          size: 55,
                        );
                      },
                    )
                  : const Icon(
                      Icons.business,
                      color: primaryGreen,
                      size: 55,
                    ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            businessName,
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
  // BUSINESS DETAILS CARD
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
            icon: Icons.store_outlined,
            title: 'Business Categories',
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
            icon: Icons.phone_outlined,
            title: 'Primary Mobile',
            value: primaryMobile,
          ),
          const Divider(height: 1),

          _infoRow(
            icon: Icons.phone_in_talk_outlined,
            title: 'Secondary Mobile',
            value: secondaryMobile,
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
  // ABOUT BUSINESS
  // ============================================================

  Widget _buildAboutSection() {
    final about = (business['description'] ?? '')
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
            'About Business',
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
          'Business Profile',
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
              padding: const EdgeInsets.fromLTRB(
                16,
                20,
                16,
                25,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ACTION BUTTONS

                  Row(
                    children: [
                      _actionButton(
                        icon: Icons.call,
                        title: 'Call',
                        onTap: _callBusiness,
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
                    'Business Information',
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