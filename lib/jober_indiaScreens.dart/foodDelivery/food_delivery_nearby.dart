import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jober_india/jober_indiaScreens.dart/foodDelivery/food_delivery_profiile.dart';
import 'package:latlong2/latlong.dart' as osm;

class ScreenFoodDeliveryNearbyList extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  //final double userLatitude;
 // final double userLongitude;

  const ScreenFoodDeliveryNearbyList({
    super.key,
    required this.categoryId,
    required this.categoryName,
   // required this.userLatitude,
   // required this.userLongitude,
  });

  @override
  State<ScreenFoodDeliveryNearbyList> createState() =>
      _ScreenFoodDeliveryNearbyListState();
}

class _FoodDeliveryNearbyProvider {
  final String uid;
  final String username;
  final String vehicleNumber;
  final String? photoUrl;
  final List<String> categories;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final bool isLive;

  _FoodDeliveryNearbyProvider({
    required this.uid,
    required this.username,
    required this.vehicleNumber,
    required this.photoUrl,
    required this.categories,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.isLive,
  });
}
enum FoodDeliveryNearbySection {
  live,
  loggedIn,
}
class _ScreenFoodDeliveryNearbyListState
    extends State<ScreenFoodDeliveryNearbyList> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;

  // ============================================================
// LOCATION AND MAP
// ============================================================

Position? _userPosition;

bool _locationLoading = true;
bool _locationPermissionDenied = false;

final fm.MapController _mapController = fm.MapController();

bool _mapReady = false;

//static const double _discoveryRadiusKm = 50.0;

  final List<_FoodDeliveryNearbyProvider> providers = [];

  FoodDeliveryNearbySection _selectedSection =
    FoodDeliveryNearbySection.live;

int _visibleCount = 20;

static const int pageSize = 20;

List<_FoodDeliveryNearbyProvider> _allProviders = [];

  DocumentSnapshot? lastLocationDocument;

 // static const int pageSize = 20;

  // Prevent multiple provider taps while payment/access
  // checking is running.
  bool _openingProvider = false;

  // @override
  // void initState() {
  //   super.initState();
  //   _loadProviders();
  // }
  @override
void initState() {
  super.initState();
  _initializePage();
}

Future<void> _initializePage() async {
  await _getUserLocation();

  if (!mounted) return;

  if (_userPosition != null) {
    await _loadProviders();
  }

  if (!mounted) return;

  setState(() {
    _locationLoading = false;
  });
}

// ============================================================
// GET USER LOCATION
// ============================================================

Future<void> _getUserLocation() async {
  try {
    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _locationPermissionDenied = true;
      return;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _locationPermissionDenied = true;
      return;
    }

    final Position position =
        await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    if (!mounted) return;

    setState(() {
      _userPosition = position;
      _locationPermissionDenied = false;
    });

    _moveMapToUser();
  } catch (e) {
    debugPrint('Food delivery location error: $e');

    if (mounted) {
      setState(() {
        _locationPermissionDenied = true;
      });
    }
  }
}

// ============================================================
// MOVE MAP TO USER
// ============================================================

void _moveMapToUser() {
  final Position? position = _userPosition;

  if (!mounted || !_mapReady || position == null) {
    return;
  }

  try {
    _mapController.move(
      osm.LatLng(
        position.latitude,
        position.longitude,
      ),
      11.5,
    );
  } catch (e) {
    debugPrint('Food delivery map movement error: $e');
  }
}

  // ============================================================
  // LOAD PROVIDERS
  // ============================================================

Future<void> _loadProviders({
  bool loadMore = false,
}) async {
  final Position? userPosition = _userPosition;

if (userPosition == null) {
  return;
}
  if (loadMore) {
    if (isLoadingMore || !hasMore) return;

    setState(() {
      isLoadingMore = true;
    });

    // Show the next 20 already-sorted riders.
    await Future<void>.delayed(Duration.zero);

    if (!mounted) return;

    setState(() {
      _visibleCount = math.min(
        _visibleCount + pageSize,
        _allProviders.length,
      );

      providers
        ..clear()
        ..addAll(_allProviders.take(_visibleCount));

      hasMore = _visibleCount < _allProviders.length;
      isLoadingMore = false;
    });

    return;
  }

  if (isLoading) return;

  setState(() {
    isLoading = true;
    isLoadingMore = false;
    hasMore = false;
    _visibleCount = pageSize;
    providers.clear();
    _allProviders.clear();
  });

  try {
    final List<_FoodDeliveryNearbyProvider> results = [];

    if (_selectedSection == FoodDeliveryNearbySection.live) {
      // ------------------------------------------------------
      // LIVE RIDERS: read only active live-location records.
      // ------------------------------------------------------

      // final QuerySnapshot<Map<String, dynamic>> liveSnapshot =
      //     await _firestore
      //         .collection('liveLocations')
      //         .where('role', isEqualTo: 'food_delivery')
      //         .where('isLive', isEqualTo: true)
      //         .where(
      //           'expiresAt',
      //           isGreaterThan: Timestamp.now(),
      //         )
      //         .get();
     final QuerySnapshot<Map<String, dynamic>> liveSnapshot =
    await _firestore
        .collection('liveLocations')
        .where('role', isEqualTo: 'food_delivery')
        .where('isLive', isEqualTo: true)
        .where(
          'expiresAt',
          isGreaterThan: Timestamp.now(),
        )
        .get();

      for (final locationDoc in liveSnapshot.docs) {
        final locationData = locationDoc.data();

        final String uid =
            locationData['uid']?.toString() ?? locationDoc.id;

        final double? latitude = _toDouble(
          locationData['latitude'] ?? locationData['lat'],
        );

        final double? longitude = _toDouble(
          locationData['longitude'] ?? locationData['lng'],
        );

        if (latitude == null || longitude == null) continue;

        // final double distanceMeters = Geolocator.distanceBetween(
        //   widget.userLatitude,
        //   widget.userLongitude,
        //   latitude,
        //   longitude,
        // );
        final double distanceMeters = Geolocator.distanceBetween(
  userPosition.latitude,
  userPosition.longitude,
  latitude,
  longitude,
);

        if (distanceMeters > 50000) continue;

        final profileSnapshot = await _firestore
            .collection('foodDeliveryGuys')
            .doc(uid)
            .get();

        if (!profileSnapshot.exists) continue;

        final Map<String, dynamic>? profileData =
            profileSnapshot.data();

        if (profileData == null ||
            profileData['isActive'] == false) {
          continue;
        }

        final List<String> categories =
            _stringList(profileData['categories']);

        if (!categories.contains(widget.categoryId)) continue;

        results.add(
          _FoodDeliveryNearbyProvider(
            uid: uid,
            username:
                profileData['username']?.toString() ??
                'Food Delivery Rider',
            vehicleNumber:
                (profileData['vehicleNumberDisplay'] ??
                        profileData['vehicleNumber'] ??
                        '')
                    .toString(),
            photoUrl:
                profileData['profilePhotoUrl']?.toString(),
            categories: categories,
            latitude: latitude,
            longitude: longitude,
            distanceMeters: distanceMeters,
            isLive: true,
          ),
        );
      }
    } else {
      // ------------------------------------------------------
      // LOGGED-IN RIDERS: use registration-time coordinates.
      // `isOnline` must be maintained by your login/logout code.
      // ------------------------------------------------------

      // final QuerySnapshot<Map<String, dynamic>> profileSnapshot =
      //     await _firestore
      //         .collection('foodDeliveryGuys')
      //         .where('isActive', isEqualTo: true)
      //         .where('isOnline', isEqualTo: true)
      //         .where(
      //           'categories',
      //           arrayContains: widget.categoryId,
      //         )
      //         .get();
    //   final QuerySnapshot<Map<String, dynamic>> profileSnapshot =
    // await _firestore
    //     .collection('foodDeliveryGuys')
    //     .where('isActive', isEqualTo: true)
    //     .where(
    //       'categories',
    //       arrayContains: widget.categoryId,
    //     )
    //     .get();
    final QuerySnapshot<Map<String, dynamic>> profileSnapshot =
    await _firestore
        .collection('foodDeliveryGuys')
        .where('isActive', isEqualTo: true)
        .where('isOnline', isEqualTo: true)
        .where(
          'categories',
          arrayContains: widget.categoryId,
        )
        .get();

      for (final profileDoc in profileSnapshot.docs) {
        final Map<String, dynamic> profileData =
            profileDoc.data();

        final String uid =
            profileData['uid']?.toString() ?? profileDoc.id;

        // Prefer the location captured at registration.
        final Map<String, dynamic> currentLocation =
            profileData['currentLocation'] is Map
                ? Map<String, dynamic>.from(
                    profileData['currentLocation'] as Map,
                  )
                : <String, dynamic>{};

        final double? latitude = _toDouble(
          profileData['currentLocationLatitude'] ??
              currentLocation['latitude'] ??
              profileData['latitude'],
        );

        final double? longitude = _toDouble(
          profileData['currentLocationLongitude'] ??
              currentLocation['longitude'] ??
              profileData['longitude'],
        );

        if (latitude == null || longitude == null) continue;

      final double distanceMeters = Geolocator.distanceBetween(
  userPosition.latitude,
  userPosition.longitude,
  latitude,
  longitude,
);

        if (distanceMeters > 50000) continue;

        final List<String> categories =
            _stringList(profileData['categories']);

        if (!categories.contains(widget.categoryId)) continue;

        results.add(
          _FoodDeliveryNearbyProvider(
            uid: uid,
            username:
                profileData['username']?.toString() ??
                'Food Delivery Rider',
            vehicleNumber:
                (profileData['vehicleNumberDisplay'] ??
                        profileData['vehicleNumber'] ??
                        '')
                    .toString(),
            photoUrl:
                profileData['profilePhotoUrl']?.toString(),
            categories: categories,
            latitude: latitude,
            longitude: longitude,
            distanceMeters: distanceMeters,
            isLive: false,
          ),
        );
      }
    }

    // Sort every matching rider before applying pagination.
    results.sort(
      (a, b) => a.distanceMeters.compareTo(b.distanceMeters),
    );

    if (!mounted) return;

    setState(() {
      _allProviders = results;
      _visibleCount = math.min(pageSize, results.length);

      providers
        ..clear()
        ..addAll(results.take(_visibleCount));

      hasMore = _visibleCount < results.length;
    });
  } catch (e, stackTrace) {
    debugPrint('Food delivery nearby error: $e');
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to load nearby Food Delivery riders.',
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }
}


  Future<void> _openProvider(
  _FoodDeliveryNearbyProvider provider,
) async {
  if (_openingProvider) return;

  _openingProvider = true;

  try {
    final double distanceKm = provider.distanceMeters / 1000.0;

    final Box settingsBox = await Hive.openBox('settings');

    final dynamic savedDistance = settingsBox.get('activeDistance');
    final dynamic savedExpiry = settingsBox.get('subscriptionExpiry');

    final DateTime? expiry = _parseDateTime(savedExpiry);

    double paidDistance = 1.0;

    final bool subscriptionActive =
        savedDistance is num &&
        expiry != null &&
        expiry.isAfter(DateTime.now());

    if (subscriptionActive) {
      paidDistance = savedDistance.toDouble();
    } else {
      // Expired or missing subscription means only 1 km is free.
      paidDistance = 1.0;

      if (savedDistance != null || savedExpiry != null) {
        await settingsBox.delete('activeDistance');
        await settingsBox.delete('subscriptionStart');
        await settingsBox.delete('subscriptionExpiry');
        await settingsBox.delete('subscriptionDuration');
        await settingsBox.delete('subscriptionPaidAmount');
        await settingsBox.delete('subscriptionActive');
      }
    }

    // Allow the profile only if the distance is covered.
    if (distanceKm <= paidDistance) {
      if (!mounted) return;
      _navigateToProfile(provider);
      return;
    }

    if (!mounted) return;

    // Do not unlock anything simply because the user taps Pay.
    // Connect this action to your real subscription/payment flow.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Distance limit reached'),
          content: Text(
            'This rider is ${_formatDistance(distanceKm)} away.\n\n'
            'Your current access limit is '
            '${paidDistance.round()} km.\n\n'
            'Choose a subscription covering at least '
            '${distanceKm.ceil()} km to open this profile.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to check your subscription.'),
      ),
    );
  } finally {
    _openingProvider = false;
  }
}

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _navigateToProfile(
    _FoodDeliveryNearbyProvider provider,
  ) {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ScreenFoodDeliveryProfile(
          uid: provider.uid,
          categoryId: widget.categoryId,
          categoryName:
              widget.categoryName,
          // userLatitude:
          //     widget.userLatitude,
          // userLongitude:
          //     widget.userLongitude,
        ),
      ),
    );
  }

  // ============================================================
  // DISTANCE FORMAT
  // ============================================================

  String _formatDistance(
    double distanceKm,
  ) {
    if (distanceKm < 1) {
      final meters =
          (distanceKm * 1000).round();

      return '$meters m';
    }

    if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    }

    return '${distanceKm.round()} km';
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  DateTime? _parseDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  List<String> _stringList(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    return value
        .map(
          (item) => item.toString(),
        )
        .where(
          (item) => item.isNotEmpty,
        )
        .toList();
  }

  // ============================================================
  // PROVIDER CARD
  // ============================================================

  Widget _providerCard(
    _FoodDeliveryNearbyProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),
        onTap: () => _openProvider(provider),
        child: Padding(
          padding:
              const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // PHOTO
              // ------------------------------------------------

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child:
                      provider.photoUrl != null &&
                              provider.photoUrl!
                                  .isNotEmpty
                          ? Image.network(
                              provider.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return _defaultPhoto();
                              },
                            )
                          : _defaultPhoto(),
                ),
              ),

              const SizedBox(width: 12),

              // ------------------------------------------------
              // DETAILS
              // ------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.username,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      widget.categoryName,
                      style: const TextStyle(
                        color:
                            Color(0xFF138808),
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),

                    if (provider
                        .vehicleNumber
                        .isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        provider.vehicleNumber,
                        style:
                            const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 17,
                          color:
                              Color(0xFF138808),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatDistance(
                            provider
                                    .distanceMeters /
                                1000.0,
                          ),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),

                        if (provider.isLive)
  Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 7,
      vertical: 3,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'LIVE',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF138808),
      ),
    ),
  )
else
  Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 7,
      vertical: 3,
    ),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      'LOGGED IN',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade700,
      ),
    ),
  ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultPhoto() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.person,
        size: 38,
        color: Colors.grey,
      ),
    );
  }

Widget _sectionButton({
  required String title,
  required bool selected,
  required VoidCallback onTap,
}) {
  return ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        vertical: 13,
        horizontal: 8,
      ),
      backgroundColor: selected
          ? const Color(0xFF138808)
          : Colors.grey.shade200,
      foregroundColor:
          selected ? Colors.white : Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: Text(
      title,
      textAlign: TextAlign.center,
    ),
  );
}

Future<void> _changeSection(
  FoodDeliveryNearbySection section,
) async {
  if (_selectedSection == section) return;

  setState(() {
    _selectedSection = section;
  });

  await _loadProviders();
}

// ============================================================
// FOOD DELIVERY MAP
// ============================================================

Widget _buildMap() {
  final Position? position = _userPosition;

  final osm.LatLng userPoint = position != null
      ? osm.LatLng(position.latitude, position.longitude)
      : const osm.LatLng(10.8505, 76.2711);

  final List<fm.Marker> markers = [];

  // User marker.
  if (position != null) {
    markers.add(
      fm.Marker(
        point: userPoint,
        width: 44,
        height: 44,
        child: const Icon(
          Icons.my_location,
          color: Colors.blue,
          size: 32,
        ),
      ),
    );
  }

  // Rider markers from the currently selected section.
  for (final provider in _allProviders) {
    markers.add(
      fm.Marker(
        point: osm.LatLng(
          provider.latitude,
          provider.longitude,
        ),
        width: 44,
        height: 48,
        child: GestureDetector(
          onTap: () => _showProviderFromMarker(provider),
          child: Icon(
            provider.isLive
                ? Icons.delivery_dining
                : Icons.person_pin_circle,
            color: provider.isLive
                ? const Color(0xFF138808)
                : Colors.red,
            size: 40,
          ),
        ),
      ),
    );
  }

  return SizedBox(
    height: 310,
    width: double.infinity,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: fm.FlutterMap(
        mapController: _mapController,
        options: fm.MapOptions(
          initialCenter: userPoint,
          initialZoom: 11.5,
          minZoom: 3,
          maxZoom: 18,
          onMapReady: () {
            _mapReady = true;
            _moveMapToUser();
          },
        ),
        children: [
          fm.TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'jober_india',
            maxZoom: 19,
          ),
          fm.MarkerLayer(
            markers: markers,
          ),
          const fm.RichAttributionWidget(
            attributions: [
              fm.TextSourceAttribution(
                '© OpenStreetMap contributors',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ============================================================
// MY LOCATION BUTTON
// ============================================================

Widget _buildMyLocationButton() {
  return Positioned(
    right: 12,
    bottom: 12,
    child: Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await _getUserLocation();
          _moveMapToUser();

          if (mounted && _userPosition != null) {
            await _loadProviders();
          }
        },
        child: const SizedBox(
          width: 45,
          height: 45,
          child: Icon(
            Icons.my_location,
            color: Colors.black87,
          ),
        ),
      ),
    ),
  );
}

// ============================================================
// RIDER BOTTOM SHEET FROM MAP
// ============================================================

void _showProviderFromMarker(
  _FoodDeliveryNearbyProvider provider,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.only(top: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: _providerCard(provider),
        ),
      );
    },
  );
}

  // ============================================================
  // BUILD
  // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.categoryName,
//         ),
//       ),


//       body: Column(
//   children: [
//     Padding(
//       padding: const EdgeInsets.all(12),
//       child: Row(
//         children: [
//           Expanded(
//             child: _sectionButton(
//               title: 'Live Riders',
//               selected: _selectedSection ==
//                   FoodDeliveryNearbySection.live,
//               onTap: () => _changeSection(
//                 FoodDeliveryNearbySection.live,
//               ),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: _sectionButton(
//               title: 'Logged-in Riders',
//               selected: _selectedSection ==
//                   FoodDeliveryNearbySection.loggedIn,
//               onTap: () => _changeSection(
//                 FoodDeliveryNearbySection.loggedIn,
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),

//     Expanded(
//       child: isLoading
//           ? const Center(
//               child: CircularProgressIndicator(),
//             )
//           : providers.isEmpty
//               ? _emptyState()
//               : RefreshIndicator(
//                   onRefresh: () => _loadProviders(),
//                   child: ListView.builder(
//                     physics:
//                         const AlwaysScrollableScrollPhysics(),
//                     itemCount: providers.length +
//                         (hasMore ? 1 : 0),
//                     itemBuilder: (context, index) {
//                       if (index >= providers.length) {
//                         return _loadMoreButton();
//                       }

//                       return _providerCard(
//                         providers[index],
//                       );
//                     },
//                   ),
//                 ),
//     ),
//   ],
// ),
//     );
//   }

// ============================================================
// SUBSCRIPTION ACCESS BADGE
// ============================================================

Widget _accessDistanceBadge() {
  return FutureBuilder<Box>(
    future: Hive.openBox('settings'),
    builder: (context, snapshot) {
      final Box? box = snapshot.data;
      final dynamic savedDistance =
          box?.get('activeDistance');
      final dynamic savedExpiry =
          box?.get('subscriptionExpiry');

      final DateTime? expiry = savedExpiry is Timestamp
          ? savedExpiry.toDate()
          : savedExpiry is DateTime
              ? savedExpiry
              : DateTime.tryParse(
                  savedExpiry?.toString() ?? '',
                );

      final bool validSubscription =
          savedDistance is num &&
          expiry != null &&
          expiry.isAfter(DateTime.now());

      final double distance = validSubscription
          ? savedDistance.toDouble()
          : 1.0;

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '${distance.toStringAsFixed(0)} km',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Access',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ============================================================
// REFRESH
// ============================================================

Future<void> _refreshProviders() async {
  await _getUserLocation();

  if (!mounted || _userPosition == null) return;

  await _loadProviders();
}

// ============================================================
// LOCATION UNAVAILABLE
// ============================================================

Widget _buildLocationUnavailable() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_off,
            size: 60,
            color: Colors.red,
          ),
          const SizedBox(height: 14),
          const Text(
            'Location Required',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enable location services and grant location permission '
            'to find nearby food delivery riders.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _locationLoading = true;
                _locationPermissionDenied = false;
              });

              await _getUserLocation();

              if (!mounted) return;

              if (_userPosition != null) {
                await _loadProviders();
              }

              if (!mounted) return;

              setState(() {
                _locationLoading = false;
              });
            },
            child: const Text('TRY AGAIN'),
          ),
        ],
      ),
    ),
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: Text(widget.categoryName),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refreshProviders,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: _locationLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _locationPermissionDenied ||
                  _userPosition == null
              ? _buildLocationUnavailable()
              : RefreshIndicator(
                  onRefresh: _refreshProviders,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      12, 8, 12, 20,
                    ),
                    children: [
                      // SECTION BUTTONS
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F5F2),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _sectionButton(
                                title: 'Live Riders',
                                selected: _selectedSection ==
                                    FoodDeliveryNearbySection.live,
                                onTap: () => _changeSection(
                                  FoodDeliveryNearbySection.live,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _sectionButton(
                                title: 'Logged-in Riders',
                                selected: _selectedSection ==
                                    FoodDeliveryNearbySection.loggedIn,
                                onTap: () => _changeSection(
                                  FoodDeliveryNearbySection.loggedIn,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // MAP AND MY LOCATION BUTTON
                      Stack(
                        children: [
                          _buildMap(),
                          _buildMyLocationButton(),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // HEADING AND ACCESS DISTANCE
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedSection ==
                                          FoodDeliveryNearbySection.live
                                      ? 'Live ${widget.categoryName} Riders Near You'
                                      : 'Logged-in ${widget.categoryName} Riders Near You',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Showing riders within 50 km',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _accessDistanceBadge(),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // if (!_isLoadingProviders &&
                      //     providers.isNotEmpty)
                      if (!isLoading && providers.isNotEmpty)
                        Text(
                          '${providers.length} riders loaded',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),

                      if (isLoading && providers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(30),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),

                      if (!isLoading && providers.isEmpty)
                        _emptyState(),

                      ...providers.map(_providerCard),

                      if (isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.all(18),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),

                      if (hasMore && !isLoadingMore)
                        Center(
                          child: _loadMoreButton(),
                        ),

                      if (!hasMore && providers.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'You have reached the end of the list.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    ),
  );
}

  Widget _loadMoreButton() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      child: Center(
        child: isLoadingMore
            ? const CircularProgressIndicator()
            : OutlinedButton(
                onPressed: hasMore
                    ? () => _loadProviders(
                          loadMore: true,
                        )
                    : null,
                child: const Text(
                  'Load More',
                ),
              ),
      ),
    );
  }

  Widget _emptyState() {
    return RefreshIndicator(
      onRefresh: () => _loadProviders(),
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 150),
          Icon(
            Icons.delivery_dining,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 15),
          Center(
            child:
            //  Text(
            //   'No Food Delivery providers are LIVE nearby.',
            //   textAlign: TextAlign.center,
            //   style: TextStyle(
            //     fontSize: 16,
            //     color: Colors.grey,
            //   ),
            // ),
            Text(
  _selectedSection == FoodDeliveryNearbySection.live
      ? 'No LIVE Food Delivery riders found within 50 km.'
      : 'No logged-in Food Delivery riders found within 50 km.',
  textAlign: TextAlign.center,
  style: const TextStyle(
    fontSize: 16,
    color: Colors.grey,
  ),
),
          ),
        ],
      ),
    );
  }
}



//   Future<void> _loadProviders({
//     bool loadMore = false,
//   }) async {
//     if (loadMore) {
//       if (isLoadingMore || !hasMore) return;

//       setState(() {
//         isLoadingMore = true;
//       });
//     } else {
//       if (isLoading) return;

//       setState(() {
//         isLoading = true;
//         hasMore = true;
//         lastLocationDocument = null;
//         providers.clear();
//       });
//     }

//     try {
//       Query<Map<String, dynamic>> query =
//           _firestore
//               .collection('liveLocations')
//               .where(
//                 'role',
//                 isEqualTo: 'food_delivery',
//               )
//               .where(
//                 'isLive',
//                 isEqualTo: true,
//               )
//               .where(
//                 'categories',
//                 arrayContains: widget.categoryId,
//               )
//               .where(
//                 'expiresAt',
//                 isGreaterThan: Timestamp.now(),
//               )
//               .limit(pageSize);

//       if (lastLocationDocument != null) {
//         query = query.startAfterDocument(
//           lastLocationDocument!,
//         );
//       }

//       final snapshot = await query.get();

//       if (snapshot.docs.isEmpty) {
//         if (mounted) {
//           setState(() {
//             hasMore = false;
//           });
//         }
//         return;
//       }

//       lastLocationDocument =
//           snapshot.docs.last;

//       if (snapshot.docs.length < pageSize) {
//         hasMore = false;
//       }

//       final List<_FoodDeliveryNearbyProvider>
//           loadedProviders = [];

//       // ----------------------------------------------------------
//       // Current implementation keeps the profile read.
//       //
//       // Later, for heavy traffic, username/photo/vehicleNumber/
//       // categories can be copied into liveLocations so this
//       // additional read can be removed.
//       // ----------------------------------------------------------

//       for (final locationDoc
//           in snapshot.docs) {
//         final locationData =
//             locationDoc.data();

//         final uid =
//             locationData['uid']?.toString() ??
//             locationDoc.id;

//         final latitude = _toDouble(
//           locationData['lat'],
//         );

//         final longitude = _toDouble(
//           locationData['lng'],
//         );

//         if (latitude == null ||
//             longitude == null) {
//           continue;
//         }

//         final distanceMeters =
//             Geolocator.distanceBetween(
//           widget.userLatitude,
//           widget.userLongitude,
//           latitude,
//           longitude,
//         );

//         try {
//           final profileSnapshot =
//               await _firestore
//                   .collection(
//                     'foodDeliveryGuys',
//                   )
//                   .doc(uid)
//                   .get();

//           if (!profileSnapshot.exists) {
//             continue;
//           }

//           final profileData =
//               profileSnapshot.data();

//           if (profileData == null) {
//             continue;
//           }

//           final isActive =
//               profileData['isActive'] != false;

//           if (!isActive) {
//             continue;
//           }

//           final List<String> categories =
//               _stringList(
//             profileData['categories'],
//           );

//           // Double-check category from profile.
//           if (!categories.contains(
//             widget.categoryId,
//           )) {
//             continue;
//           }

//           loadedProviders.add(
//             _FoodDeliveryNearbyProvider(
//               uid: uid,
//               username:
//                   profileData['username']
//                           ?.toString() ??
//                       'Food Delivery',
//               vehicleNumber:
//                   profileData['vehicleNumberDisplay']
//                           ?.toString()
//                           .isNotEmpty ==
//                       true
//                   ? profileData[
//                           'vehicleNumberDisplay']
//                       .toString()
//                   : profileData[
//                               'vehicleNumber']
//                           ?.toString() ??
//                       '',
//               photoUrl:
//                   profileData['profilePhotoUrl']
//                           ?.toString(),
//               categories: categories,
//               latitude: latitude,
//               longitude: longitude,
//               distanceMeters:
//                   distanceMeters,
//             ),
//           );
//         } catch (_) {
//           // Skip a provider if its profile cannot
//           // be loaded.
//         }
//       }

//       // ----------------------------------------------------------
//       // Sort this loaded page by distance.
//       //
//       // IMPORTANT:
//       // Because Firestore is paginating liveLocations without
//       // geohash/radius ordering, this guarantees sorting inside
//       // this page only, not globally across all India.
//       // ----------------------------------------------------------

//       loadedProviders.sort(
//         (a, b) => a.distanceMeters.compareTo(
//           b.distanceMeters,
//         ),
//       );

//       if (!mounted) return;

//       setState(() {
//         providers.addAll(
//           loadedProviders,
//         );
//       });
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         SnackBar(
//           content: Text(
//             'Unable to load Food Delivery providers.',
//           ),
//         ),
//       );
//     } finally {
//   if (mounted) {
//     setState(() {
//       isLoading = false;
//       isLoadingMore = false;
//     });
//   }
// }
  
//   }


  // ============================================================
  // OPEN PROVIDER
  // ============================================================

  // Future<void> _openProvider(
  //   _FoodDeliveryNearbyProvider provider,
  // ) async {
  //   if (_openingProvider) return;

  //   _openingProvider = true;

  //   try {
  //     final distanceKm =
  //         provider.distanceMeters / 1000.0;

  //     final settingsBox =
  //         await Hive.openBox('settings');

  //     final paidDistanceValue =
  //         settingsBox.get('paidDistance');

  //     final paymentExpiryValue =
  //         settingsBox.get('paymentExpiry');

  //     final paidDistance =
  //         _toDouble(paidDistanceValue) ?? 0.0;

  //     final paymentExpiry =
  //         _parseDateTime(
  //       paymentExpiryValue,
  //     );

  //     final now = DateTime.now();

  //     // ----------------------------------------------------------
  //     // VALID PAYMENT
  //     // ----------------------------------------------------------

  //     final hasValidPayment =
  //         paymentExpiry != null &&
  //         paymentExpiry.isAfter(now);

  //     if (hasValidPayment &&
  //         paidDistance >= distanceKm) {
  //       _navigateToProfile(provider);
  //       return;
  //     }

  //     // ----------------------------------------------------------
  //     // FREE / EXPIRED PAYMENT
  //     //
  //     // If provider is within 1 km, allow access.
  //     //
  //     // This follows the same concept as your Home distance
  //     // system where 1 km does not require payment.
  //     // ----------------------------------------------------------

  //     if (distanceKm <= 1.0) {
  //       _navigateToProfile(provider);
  //       return;
  //     }

  //     // ----------------------------------------------------------
  //     // CALCULATE REQUIRED DISTANCE
  //     // ----------------------------------------------------------

  //     double requiredDistanceKm;

  //     if (hasValidPayment && paidDistance > 0) {
  //       // Example:
  //       //
  //       // Paid = 3 km
  //       // Provider = 4 km
  //       //
  //       // Required total entitlement = 4 km
  //       requiredDistanceKm =
  //           distanceKm.ceilToDouble();

  //       // Never reduce an existing entitlement.
  //       if (requiredDistanceKm <= paidDistance) {
  //         _navigateToProfile(provider);
  //         return;
  //       }
  //     } else {
  //       // No valid payment.
  //       //
  //       // Use the provider's required distance,
  //       // rounded upward to the next whole km.
  //       requiredDistanceKm =
  //           distanceKm.ceilToDouble();

  //       if (requiredDistanceKm < 1) {
  //         requiredDistanceKm = 1;
  //       }
  //     }

  //     final extraDistanceKm =
  //         math.max(
  //       0.0,
  //       requiredDistanceKm - paidDistance,
  //     );

  //     final paymentSuccessful =
  //         await _showAdditionalDistancePaymentDialog(
  //       providerDistanceKm: distanceKm,
  //       currentPaidDistanceKm: paidDistance,
  //       requiredDistanceKm: requiredDistanceKm,
  //       extraDistanceKm: extraDistanceKm,
  //     );

  //     if (!paymentSuccessful) {
  //       return;
  //     }

  //     // ----------------------------------------------------------
  //     // PAYMENT SUCCESS
  //     //
  //     // IMPORTANT:
  //     // This currently uses the same placeholder style as your
  //     // Home payment system.
  //     //
  //     // Later Razorpay can be connected here.
  //     // ----------------------------------------------------------

  //     final expiry =
  //         DateTime.now().add(
  //       const Duration(days: 1),
  //     );

  //     await settingsBox.put(
  //       'paidDistance',
  //       requiredDistanceKm,
  //     );

  //     await settingsBox.put(
  //       'paymentExpiry',
  //       expiry.toIso8601String(),
  //     );

  //     if (!mounted) return;

  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           '${_formatDistance(distanceKm)} provider unlocked. '
  //           'Your paid distance is now '
  //           '${requiredDistanceKm.round()} km for 24 hours.',
  //         ),
  //       ),
  //     );

  //     _navigateToProfile(provider);
  //   } catch (e) {
  //     if (!mounted) return;

  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(
  //       const SnackBar(
  //         content: Text(
  //           'Unable to open this profile. Please try again.',
  //         ),
  //       ),
  //     );
  //   } finally {
  //     _openingProvider = false;
  //   }
  // }


  // ============================================================
  // PAYMENT DIALOG
  // ============================================================

  // Future<bool>
  //     _showAdditionalDistancePaymentDialog({
  //   required double providerDistanceKm,
  //   required double currentPaidDistanceKm,
  //   required double requiredDistanceKm,
  //   required double extraDistanceKm,
  // }) async {
  //   // ----------------------------------------------------------
  //   // IMPORTANT:
  //   //
  //   // I am intentionally not inventing your final payment
  //   // calculation here because your current Home paymentAmount
  //   // implementation was not included.
  //   //
  //   // For now, this is the same payment placeholder concept
  //   // used by your existing Home page.
  //   // ----------------------------------------------------------

  //   final amount =
  //       _temporaryPaymentAmount(
  //     requiredDistanceKm,
  //   );

  //   final result =
  //       await showDialog<bool>(
  //     context: context,
  //     builder: (dialogContext) {
  //       return AlertDialog(
  //         title: const Text(
  //           'Distance Payment',
  //         ),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment:
  //               CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               'This Food Delivery provider is '
  //               '${_formatDistance(providerDistanceKm)} '
  //               'away.',
  //             ),
  //             const SizedBox(height: 12),

  //             if (currentPaidDistanceKm > 0) ...[
  //               Text(
  //                 'Your paid distance: '
  //                 '${currentPaidDistanceKm.round()} km',
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 'Additional distance needed: '
  //                 '${extraDistanceKm.toStringAsFixed(1)} km',
  //               ),
  //             ] else ...[
  //               const Text(
  //                 'You do not have an active paid distance.',
  //               ),
  //             ],

  //             const SizedBox(height: 8),

  //             Text(
  //               'New paid distance: '
  //               '${requiredDistanceKm.round()} km',
  //               style: const TextStyle(
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),

  //             const SizedBox(height: 12),

  //             Text(
  //               'Payment: ₹$amount',
  //               style: const TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),

  //             const SizedBox(height: 6),

  //             const Text(
  //               'Valid for 24 hours.',
  //               style: TextStyle(
  //                 color: Colors.grey,
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(
  //                 dialogContext,
  //                 false,
  //               );
  //             },
  //             child: const Text(
  //               'Cancel',
  //               style: TextStyle(
  //                 color: Colors.red,
  //               ),
  //             ),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               Navigator.pop(
  //                 dialogContext,
  //                 true,
  //               );
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor:
  //                   const Color(0xFF138808),
  //               foregroundColor: Colors.white,
  //             ),
  //             child: Text(
  //               'Pay ₹$amount',
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   return result == true;
  // }

  // ============================================================
  // TEMPORARY PAYMENT AMOUNT
  // ============================================================

  // int _temporaryPaymentAmount(
  //   double requiredDistanceKm,
  // ) {
  //   // ----------------------------------------------------------
  //   // Replace ONLY this calculation with the exact paymentAmount
  //   // calculation from your Home page when you send it.
  //   //
  //   // I am using the distance pricing pattern previously used
  //   // in your app:
  //   //
  //   // ((distance - 5) * 5)
  //   //
  //   // but keeping it safely at zero.
  //   //
  //   // ----------------------------------------------------------

  //   final distance =
  //       requiredDistanceKm.ceil();

  //   if (distance <= 5) {
  //     return 0;
  //   }

  //   return ((distance - 5) * 5);
  // }

                        // Container(
                        //   padding:
                        //       const EdgeInsets
                        //           .symmetric(
                        //     horizontal: 7,
                        //     vertical: 3,
                        //   ),
                        //   decoration:
                        //       BoxDecoration(
                        //     color:
                        //         const Color(
                        //       0xFFE8F5E9,
                        //     ),
                        //     borderRadius:
                        //         BorderRadius
                        //             .circular(
                        //       20,
                        //     ),
                        //   ),
                        //   child: const Text(
                        //     'LIVE',
                        //     style: TextStyle(
                        //       fontSize: 11,
                        //       fontWeight:
                        //           FontWeight.bold,
                        //       color:
                        //           Color(
                        //         0xFF138808,
                        //       ),
                        //     ),
                        //   ),
                        // ),

      // body: isLoading
      //     ? const Center(
      //         child:
      //             CircularProgressIndicator(),
      //       )
      //     : providers.isEmpty
      //         ? _emptyState()
      //         : RefreshIndicator(
      //             onRefresh: () =>
      //                 _loadProviders(),
      //             child: ListView.builder(
      //               physics:
      //                   const AlwaysScrollableScrollPhysics(),
      //               itemCount:
      //                   providers.length +
      //                       (hasMore ? 1 : 0),
      //               itemBuilder:
      //                   (context, index) {
      //                 if (index >=
      //                     providers.length) {
      //                   return _loadMoreButton();
      //                 }

      //                 return _providerCard(
      //                   providers[index],
      //                 );
      //               },
      //             ),
      //           ),