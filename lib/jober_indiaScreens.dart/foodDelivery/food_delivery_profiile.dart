import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ScreenFoodDeliveryProfile
    extends StatefulWidget {
  final String uid;
  final String categoryId;
  final String categoryName;
  // final double userLatitude;
  // final double userLongitude;

  const ScreenFoodDeliveryProfile({
    super.key,
    required this.uid,
    required this.categoryId,
    required this.categoryName,
    // required this.userLatitude,
    // required this.userLongitude,
  });

  @override
  State<ScreenFoodDeliveryProfile>
      createState() =>
          _ScreenFoodDeliveryProfileState();
}

class _ScreenFoodDeliveryProfileState
    extends State<ScreenFoodDeliveryProfile> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool isLoading = true;

  Map<String, dynamic>? profileData;
  Map<String, dynamic>? liveData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

//  Future<void> _loadProfile() async {
//   try {
//     final profileFuture = _firestore
//         .collection('foodDeliveryGuys')
//         .doc(widget.uid)
//         .get();

//     final liveFuture = _firestore
//         .collection('liveLocations')
//         .doc(widget.uid)
//         .get();

//     final profileSnapshot = await profileFuture;
//     final liveSnapshot = await liveFuture;

//     if (!mounted) return;

//     setState(() {
//       profileData = profileSnapshot.data();
//       liveData = liveSnapshot.data();
//       isLoading = false;
//     });
//   } catch (e) {
//     if (!mounted) return;

//     setState(() {
//       isLoading = false;
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(
//           'Unable to load profile.',
//         ),
//       ),
//     );
//   }
// }
Future<void> _loadProfile() async {
  try {
    final snapshot = await _firestore
        .collection('foodDeliveryGuys')
        .doc(widget.uid)
        .get();

    if (!mounted) return;

    setState(() {
      profileData = snapshot.data();
      isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to load profile.'),
      ),
    );
  }
}

Future<void> _callNumber(String number) async {
  final cleanedNumber = number.trim();

  if (cleanedNumber.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Secondary mobile number is unavailable.'),
      ),
    );
    return;
  }

  final uri = Uri(
    scheme: 'tel',
    path: cleanedNumber,
  );

  try {
    final launched = await launchUrl(uri);

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the phone app.'),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to make the call.'),
      ),
    );
  }
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value == null) return null;

  return double.tryParse(value.toString());
}

Future<void> _openSavedLocation() async {
  final location = profileData?['currentLocation'];

  final Map<String, dynamic> nestedLocation =
      location is Map
          ? Map<String, dynamic>.from(location)
          : <String, dynamic>{};

  final latitude = _toDouble(
    profileData?['currentLocationLatitude'] ??
        nestedLocation['latitude'] ??
        profileData?['latitude'],
  );

  final longitude = _toDouble(
    profileData?['currentLocationLongitude'] ??
        nestedLocation['longitude'] ??
        profileData?['longitude'],
  );

  if (latitude == null ||
      longitude == null ||
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'The rider has not saved a valid location.',
        ),
      ),
    );
    return;
  }

  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1'
    '&query=$latitude,$longitude',
  );

  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the map.'),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open the saved location.'),
      ),
    );
  }
}

  String _stringValue(
    String key, {
    String fallback = '',
  }) {
    return profileData?[key]
            ?.toString() ??
        fallback;
  }

  List<String> _categories() {
    final value =
        profileData?['categories'];

    if (value is! List) {
      return [];
    }

    return value
        .map(
          (e) => e.toString(),
        )
        .where(
          (e) => e.isNotEmpty,
        )
        .toList();
  }

  String _formatCategory(
    String id,
  ) {
    const names = {
      'bike': 'Bike',
      'auto': 'Auto',
      'car': 'Car',
      'van': 'Van',
      'mini_truck': 'Mini Truck',
      'truck': 'Truck',
      'cycle': 'Cycle',
    };

    if (names.containsKey(id)) {
      return names[id]!;
    }

    final cleaned = id
        .replaceFirst(
          'custom_',
          '',
        )
        .replaceAll('_', ' ');

    if (cleaned.isEmpty) {
      return id;
    }

    return cleaned
        .split(' ')
        .map(
          (word) {
            if (word.isEmpty) {
              return '';
            }

            return word[0].toUpperCase() +
                word.substring(1);
          },
        )
        .join(' ');
  }

  // Future<void> _callNumber(
  //   String number,
  // ) async {
  //   // Keep your existing url_launcher
  //   // implementation here if you already have it.
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Food Delivery Profile',
        ),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : profileData == null
              ? const Center(
                  child: Text(
                    'Profile not found.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.all(16),
                    children: [
                      _profileHeader(),

                      const SizedBox(height: 16),

                      _liveStatusCard(),

                      const SizedBox(height: 16),

                      _detailsCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _profileHeader() {
    final photoUrl =
        profileData?['profilePhotoUrl']
            ?.toString();

    final username =
        _stringValue(
      'username',
      fallback: 'Food Delivery',
    );

    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor:
              Colors.grey.shade200,
          backgroundImage:
              photoUrl != null &&
                      photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
          child:
              photoUrl == null ||
                      photoUrl.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 55,
                      color: Colors.grey,
                    )
                  : null,
        ),

        const SizedBox(height: 12),

        Text(
          username,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          widget.categoryName,
          style: const TextStyle(
            color: Color(0xFF138808),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Widget _liveStatusCard() {
  //   final isLive =
  //       liveData?['isLive'] == true;

  //   return Container(
  //     padding:
  //         const EdgeInsets.all(14),
  //     decoration: BoxDecoration(
  //       color: isLive
  //           ? const Color(0xFFE8F5E9)
  //           : Colors.grey.shade100,
  //       borderRadius:
  //           BorderRadius.circular(12),
  //       border: Border.all(
  //         color: isLive
  //             ? const Color(0xFF138808)
  //             : Colors.grey.shade300,
  //       ),
  //     ),
  //     child: Row(
  //       children: [
  //         Icon(
  //           isLive
  //               ? Icons.location_on
  //               : Icons.location_off,
  //           color: isLive
  //               ? const Color(0xFF138808)
  //               : Colors.grey,
  //         ),
  //         const SizedBox(width: 10),
  //         Expanded(
  //           child: Text(
  //             isLive
  //                 ? 'Currently LIVE'
  //                 : 'Currently offline',
  //             style: TextStyle(
  //               fontWeight:
  //                   FontWeight.w600,
  //               color: isLive
  //                   ? const Color(
  //                       0xFF138808,
  //                     )
  //                   : Colors.grey.shade700,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _liveStatusCard() {
  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: _firestore
        .collection('liveLocations')
        .doc(widget.uid)
        .snapshots(),
    builder: (context, snapshot) {
      final data = snapshot.data?.data();

      final dynamic expiryValue = data?['expiresAt'];

      final bool hasValidExpiry =
          expiryValue is Timestamp &&
          expiryValue.toDate().isAfter(DateTime.now());

      final double? latitude = _toDouble(
        data?['latitude'] ?? data?['lat'],
      );

      final double? longitude = _toDouble(
        data?['longitude'] ?? data?['lng'],
      );

      final bool isLive =
          data?['isLive'] == true &&
          hasValidExpiry &&
          latitude != null &&
          longitude != null &&
          latitude >= -90 &&
          latitude <= 90 &&
          longitude >= -180 &&
          longitude <= 180;

      if (snapshot.hasError) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Unable to check the rider location.',
            ),
          ),
        );
      }

      if (snapshot.connectionState == ConnectionState.waiting &&
          !snapshot.hasData) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }

      // ------------------------------------------------------
      // LIVE RIDER: SHOW MAP
      // ------------------------------------------------------

      if (isLive) {
        final LatLng riderPosition = LatLng(
          latitude,
          longitude,
        );

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Color(0xFF138808),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rider Live Location',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFF138808),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 280,
                child: GoogleMap(
                  key: ValueKey(
                    '${widget.uid}_live_map',
                  ),
                  initialCameraPosition: CameraPosition(
                    target: riderPosition,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('food_rider'),
                      position: riderPosition,
                      infoWindow: InfoWindow(
                        title: _stringValue(
                          'username',
                          fallback: 'Food Delivery Rider',
                        ),
                        snippet: 'Live location',
                      ),
                    ),
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Latitude: ${latitude.toStringAsFixed(6)}\n'
                  'Longitude: ${longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // ------------------------------------------------------
      // NOT LIVE: USE SAVED LOCATION WHEN LOGGED IN
      // ------------------------------------------------------

      final bool isLoggedIn =
          profileData?['isOnline'] == true ||
          profileData?['isLoggedIn'] == true;

      if (isLoggedIn) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.location_off,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rider is not sharing live location',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openSavedLocation,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF138808),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.location_off,
                color: Colors.grey,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  snapshot.connectionState ==
                          ConnectionState.waiting
                      ? 'Checking rider status...'
                      : 'Rider is currently offline.',
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _detailsCard() {
    final vehicleNumber =
        _stringValue(
      'vehicleNumberDisplay',
    ).isNotEmpty
        ? _stringValue(
            'vehicleNumberDisplay',
          )
        : _stringValue(
            'vehicleNumber',
          );

    // final primary =
    //     _stringValue(
    //   'mobileNumber',
    // );

    final secondary =
        _stringValue(
      'secondaryMobileNumber',
    );

    final categories =
        _categories();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            _detailRow(
              Icons.directions_car_outlined,
              'Vehicle Number',
              vehicleNumber.isEmpty
                  ? 'Not available'
                  : vehicleNumber,
            ),

            const Divider(),

            _detailRow(
              Icons.category_outlined,
              'Selected Category',
              widget.categoryName,
            ),

            const Divider(),

            const Text(
              'Vehicle Categories',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  categories.map(
                (category) {
                  return Chip(
                    label: Text(
                      _formatCategory(
                        category,
                      ),
                    ),
                  );
                },
              ).toList(),
            ),

            const SizedBox(height: 16),

            // const Text(
            //   'Contact',
            //   style: TextStyle(
            //     fontSize: 18,
            //     fontWeight:
            //         FontWeight.bold,
            //   ),
            // ),

            // const SizedBox(height: 10),

            // if (primary.isNotEmpty)
            //   _phoneButton(
            //     'Primary Mobile',
            //     primary,
            //   ),

            // if (secondary.isNotEmpty)
            //   _phoneButton(
            //     'Secondary Mobile',
            //     secondary,
            //   ),
            const Text(
  'Contact Rider',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 10),

SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: secondary.isEmpty
        ? null
        : () => _callNumber(secondary),
    icon: const Icon(Icons.call),
    label: const Text('Call Rider on Secondary Number'),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF138808),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
  ),
),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color:
              const Color(0xFF138808),
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
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _phoneButton(
  //   String title,
  //   String number,
  // ) {
  //   return Padding(
  //     padding:
  //         const EdgeInsets.only(
  //       bottom: 8,
  //     ),
  //     child: SizedBox(
  //       width: double.infinity,
  //       child: OutlinedButton.icon(
  //         onPressed: () =>
  //             _callNumber(number),
  //         icon: const Icon(
  //           Icons.phone_outlined,
  //         ),
  //         label: Text(
  //           '$title • $number',
  //         ),
  //       ),
  //     ),
  //   );
  // }
}