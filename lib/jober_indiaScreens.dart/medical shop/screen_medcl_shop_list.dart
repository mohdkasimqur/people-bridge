import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:url_launcher/url_launcher.dart';


// ============================================================
// MEDICAL SHOP CATEGORY SCREEN
//
// Flow:
//
// Medical Shop
//      ↓
// Category names only
//      ↓
// User selects ONE category
//      ↓
// MedicalShopNearbyScreen
// ============================================================

class MedicalShopCategoryScreen extends StatelessWidget {
  const MedicalShopCategoryScreen({super.key});

  static const List<String> builtInCategories = [
    'Modern Allopathic medical shops',
    'Ayurvedic medical shops',
    'Homeopathic Medical shops',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xFF12652F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Medical Shop',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('medicalShops')
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load medical shop categories.',
              ),
            );
          }

          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF12652F),
              ),
            );
          }

          final shopDocuments =
              snapshot.data?.docs ?? [];

          // Store category names and their counts.
          final Map<String, int> categoryCounts = {};

          // Preserve the display spelling of category names.
          final Map<String, String> categoryNames = {};

          // Add built-in categories first.
          for (final category in builtInCategories) {
            final normalized = category.trim().toLowerCase();

            categoryNames[normalized] = category;
            categoryCounts[normalized] = 0;
          }

          // Count registered shops.
          for (final shopDocument in shopDocuments) {
            final shopData = shopDocument.data();

            final dynamic rawCategories =
                shopData['categories'];

            if (rawCategories is! List) continue;

            // A set ensures one shop is counted only once
            // for a category, even if duplicate values exist.
            final Set<String> shopCategories = {};

            for (final rawCategory in rawCategories) {
              if (rawCategory is! String) continue;

              final category = rawCategory.trim();

              if (category.isEmpty) continue;

              shopCategories.add(category.toLowerCase());

              categoryNames.putIfAbsent(
                category.toLowerCase(),
                () => category,
              );
            }

            for (final normalized in shopCategories) {
              categoryCounts[normalized] =
                  (categoryCounts[normalized] ?? 0) + 1;
            }
          }

          // Built-in categories remain first.
          // Custom categories are sorted alphabetically.
          final customCategoryKeys = categoryNames.keys
              .where(
                (key) => !builtInCategories.any(
                  (builtIn) =>
                      builtIn.toLowerCase() == key,
                ),
              )
              .toList()
            ..sort(
              (a, b) => categoryNames[a]!
                  .compareTo(categoryNames[b]!),
            );

          final List<String> displayCategories = [
            ...builtInCategories,
            ...customCategoryKeys.map(
              (key) => categoryNames[key]!,
            ),
          ];

          if (displayCategories.isEmpty) {
            return const Center(
              child: Text('No categories available.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),

            itemCount: displayCategories.length,

            separatorBuilder: (_, __) =>
                const SizedBox(height: 10),

            itemBuilder: (context, index) {
              final category = displayCategories[index];

              final normalized =
                  category.trim().toLowerCase();

              final count =
                  categoryCounts[normalized] ?? 0;

              final isBuiltIn =
                  builtInCategories.any(
                (builtIn) =>
                    builtIn.toLowerCase() == normalized,
              );

              return InkWell(
                borderRadius: BorderRadius.circular(14),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MedicalShopNearbyScreen(
                        selectedCategory: category,
                      ),
                    ),
                  );
                },

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEAEAEA),
                    ),
                  ),

                  child: Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7EF),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_pharmacy,
                          color: Color(0xFF138808),
                          size: 25,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              isBuiltIn
                                  ? 'Medical shop category'
                                  : 'Custom category',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF138808)
                              .withValues(alpha: 0.10),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),

                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Color(0xFF138808),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 15,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// MEDICAL SHOP NEARBY SCREEN
//
// Receives ONE selected category.
//
// Features:
// • Gets user's current location
// • Requests location permission
// • Searches Firestore for the selected category
// • Shows only shops within 50 KM
// • Calculates exact distance
// • Sorts shops from nearest to farthest
// • Pull-to-refresh
// • Opens MedicalShopProfileScreen when a shop is selected
// ============================================================

// class MedicalShopNearbyScreen extends StatefulWidget {
//   final String selectedCategory;

//   const MedicalShopNearbyScreen({
//     super.key,
//     required this.selectedCategory,
//   });

//   @override
//   State<MedicalShopNearbyScreen> createState() =>
//       _MedicalShopNearbyScreenState();
// }

// class _MedicalShopNearbyScreenState
//     extends State<MedicalShopNearbyScreen> {

//   // FIRESTORE
//   final FirebaseFirestore _firestore =
//       FirebaseFirestore.instance;

//   // Maximum search distance
//   static const double maximumDistanceKm = 50.0;

//   // Loading states
//   bool isLoading = true;
//   bool isLocationLoading = false;

//   // Error
//   String? errorMessage;

//   // User location
//   Position? userPosition;

//   // Nearby shops
//   List<Map<String, dynamic>> nearbyShops = [];

// // ==========================================================
// // SUBSCRIPTION
// // ==========================================================

// static const double freeDistanceKm = 1.0;

// static const int pageSize = 20;

// double paidDistance = 1.0;

// DateTime? paymentExpiry;

// // ==========================================================
// // PAGINATION
// // ==========================================================

// final ScrollController _scrollController =
//     ScrollController();

// List<Map<String, dynamic>> visibleNearbyShops = [];

// bool isLoadingMore = false;

// bool hasMore = false;

//   // @override
//   // void initState() {
//   //   super.initState();

//   //   _loadNearbyMedicalShops();
//   // }
//   @override
// void initState() {
//   super.initState();

//   _scrollController.addListener(_onScroll);

//   _initializePage();
// }

// Future<void> _initializePage() async {

//   await loadPaymentData();

//   if (!mounted) return;

//   await _loadNearbyMedicalShops();
// }

// @override
// void dispose() {

//   _scrollController.removeListener(_onScroll);

//   _scrollController.dispose();

//   super.dispose();
// }

// // ==========================================================
// // SUBSCRIPTION VALIDITY
// // ==========================================================

// bool get hasActiveSubscription {

//   return paymentExpiry != null &&
//       DateTime.now().isBefore(paymentExpiry!);
// }

// // ==========================================================
// // LOAD SUBSCRIPTION FROM HOME PAGE
// // ==========================================================

// Future<void> loadPaymentData() async {

//   final box = Hive.box('settings');

//   final savedDistance =
//       box.get('activeDistance');

//   final savedExpiry =
//       box.get('subscriptionExpiry');

//   double distance = 1.0;

//   DateTime? expiry;

//   if (savedDistance is num) {
//     distance = savedDistance.toDouble();
//   }

//   if (savedExpiry != null) {

//     expiry = DateTime.tryParse(
//       savedExpiry.toString(),
//     );
//   }

//   // CHECK EXPIRY

//   if (expiry == null ||
//       !DateTime.now().isBefore(expiry)) {

//     distance = 1.0;

//     expiry = null;

//     await box.delete('activeDistance');
//     await box.delete('subscriptionStart');
//     await box.delete('subscriptionExpiry');
//     await box.delete('subscriptionDuration');
//     await box.delete('subscriptionPaidAmount');
//     await box.delete('subscriptionActive');
//   }

//   paidDistance = distance;

//   paymentExpiry = expiry;

//   if (mounted) {
//     setState(() {});
//   }
// }

// // ==========================================================
// // OPEN MEDICAL SHOP PROFILE
// // ==========================================================

// void _handleMedicalShopTap(
//   Map<String, dynamic> shop,
// ) {

//   final distanceKm =
//       (shop['distanceKm'] as num).toDouble();

//   if (!_canOpenMedicalShop(distanceKm)) {

//     _showSubscriptionRequiredDialog(distanceKm);

//     return;
//   }

//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (_) => MedicalShopProfileScreen(
//         shop: shop,
//       ),
//     ),
//   );
// }

// // ==========================================================
// // SUBSCRIPTION REQUIRED DIALOG
// // ==========================================================

// void _showSubscriptionRequiredDialog(
//   double distanceKm,
// ) {

//   showDialog<void>(
//     context: context,

//     builder: (dialogContext) {

//       return AlertDialog(

//         title: const Text(
//           'Distance access required',
//         ),

//         content: Text(
//           'This medical shop is '
//           '${_formatDistance(distanceKm)} away.\n\n'
//           'Your current access is '
//           '${hasActiveSubscription ? paidDistance.round() : 1} KM.\n\n'
//           'Unlock a larger distance to open this medical shop profile.',
//         ),

//         actions: [

//           TextButton(
//             onPressed: () {

//               Navigator.pop(dialogContext);
//             },

//             child: const Text('Close'),
//           ),
//         ],
//       );
//     },
//   );
// }
// // ==========================================================
// // CHECK MEDICAL SHOP PROFILE ACCESS
// // ==========================================================

// bool _canOpenMedicalShop(double distanceKm) {

//   // FREE 1 KM

//   if (distanceKm <= freeDistanceKm) {
//     return true;
//   }

//   // SUBSCRIPTION MUST BE ACTIVE

//   if (!hasActiveSubscription) {
//     return false;
//   }

//   // CHECK PURCHASED DISTANCE

//   return distanceKm <= paidDistance;
// }

//   // ============================================================
//   // REQUEST LOCATION PERMISSION
//   // ============================================================

//   Future<bool> _requestLocationPermission() async {

//     // Check whether GPS/location service is ON
//     final bool serviceEnabled =
//         await Geolocator.isLocationServiceEnabled();

//     if (!serviceEnabled) {

//       if (mounted) {
//         setState(() {
//           errorMessage =
//               'Please turn on Location/GPS.';
//         });
//       }

//       await Geolocator.openLocationSettings();

//       return false;
//     }

//     // Check current permission
//     LocationPermission permission =
//         await Geolocator.checkPermission();

//     // Ask permission if not already granted
//     if (permission == LocationPermission.denied) {

//       permission =
//           await Geolocator.requestPermission();
//     }

//     // User denied permission
//     if (permission == LocationPermission.denied) {

//       if (mounted) {
//         setState(() {
//           errorMessage =
//               'Location permission is required '
//               'to find medical shops within 50 km.';
//         });
//       }

//       return false;
//     }

//     // User permanently denied permission
//     if (permission ==
//         LocationPermission.deniedForever) {

//       if (mounted) {
//         setState(() {
//           errorMessage =
//               'Location permission was permanently denied. '
//               'Please enable it from App Settings.';
//         });
//       }

//       return false;
//     }

//     return true;
//   }

//   // ============================================================
//   // GET USER CURRENT LOCATION
//   // ============================================================

//   Future<Position?> _getUserLocation() async {

//     final bool allowed =
//         await _requestLocationPermission();

//     if (!allowed) {
//       return null;
//     }

//     try {

//       if (mounted) {
//         setState(() {
//           isLocationLoading = true;
//         });
//       }

//       final Position position =
//           await Geolocator.getCurrentPosition(
//         locationSettings:
//             const LocationSettings(
//           accuracy: LocationAccuracy.high,
//         ),
//       );

//       return position;

//     } catch (e) {

//       debugPrint(
//         'Get user location error: $e',
//       );

//       if (mounted) {
//         setState(() {
//           errorMessage =
//               'Unable to get your current location.';
//         });
//       }

//       return null;

//     } finally {

//       if (mounted) {
//         setState(() {
//           isLocationLoading = false;
//         });
//       }
//     }
//   }

//   // ============================================================
//   // LOAD NEARBY MEDICAL SHOPS
//   // ============================================================

//   Future<void> _loadNearbyMedicalShops() async {

//     if (mounted) {
//       setState(() {
//         isLoading = true;
//         errorMessage = null;
//       });
//     }

//     // ----------------------------------------------------------
//     // GET USER LOCATION
//     // ----------------------------------------------------------

//     final Position? position =
//         await _getUserLocation();

//     if (position == null) {

//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }

//       return;
//     }

//     userPosition = position;

//     try {

//       // --------------------------------------------------------
//       // GET SHOPS FROM FIRESTORE
//       //
//       // The medical shop registration stores categories as:
//       //
//       // medicalShopCategories: [...]
//       //
//       // Therefore arrayContains is used.
//       // --------------------------------------------------------

//       final QuerySnapshot<
//           Map<String, dynamic>> snapshot =
//           await _firestore
//               .collection('medicalShops')
//               .where(
//                 'medicalShopCategories',
//                 arrayContains:
//                     widget.selectedCategory,
//               )
//               .get();

//       final List<Map<String, dynamic>> shops =
//           [];

//       // --------------------------------------------------------
//       // CHECK EVERY SHOP
//       // --------------------------------------------------------

//       for (final document
//           in snapshot.docs) {

//         final Map<String, dynamic> data =
//             document.data();

//         // ------------------------------------------------------
//         // GET CURRENT LOCATION
//         // ------------------------------------------------------

//         final dynamic locationData =
//             data['currentLocation'];

//         if (locationData == null) {
//           continue;
//         }

//         if (locationData is! Map) {
//           continue;
//         }

//         final Map<String, dynamic> location =
//             Map<String, dynamic>.from(
//           locationData,
//         );

//         // ------------------------------------------------------
//         // GET LATITUDE
//         // ------------------------------------------------------

//         final double? shopLatitude =
//             _convertToDouble(
//           location['latitude'],
//         );

//         // ------------------------------------------------------
//         // GET LONGITUDE
//         // ------------------------------------------------------

//         final double? shopLongitude =
//             _convertToDouble(
//           location['longitude'],
//         );

//         // Ignore shop if location is incomplete
//         if (shopLatitude == null ||
//             shopLongitude == null) {
//           continue;
//         }

//         // ------------------------------------------------------
//         // CALCULATE DISTANCE
//         // ------------------------------------------------------

//         final double distanceInMeters =
//             Geolocator.distanceBetween(
//           position.latitude,
//           position.longitude,
//           shopLatitude,
//           shopLongitude,
//         );

//         final double distanceInKm =
//             distanceInMeters / 1000.0;

//         // ------------------------------------------------------
//         // ONLY SHOPS WITHIN 50 KM
//         // ------------------------------------------------------

//         if (distanceInKm <=
//             maximumDistanceKm) {

//           shops.add({
//   'id': document.id,
//   ...data,
//   'distanceKm': distanceInKm,
// });
//         }
//       }

//       // --------------------------------------------------------
//       // SORT BY DISTANCE
//       //
//       // Nearest shop appears first.
//       // --------------------------------------------------------

//       shops.sort(
//         (a, b) {

//           final double distanceA =
//               (a['distanceKm'] as num)
//                   .toDouble();

//           final double distanceB =
//               (b['distanceKm'] as num)
//                   .toDouble();

//           return distanceA.compareTo(
//             distanceB,
//           );
//         },
//       );

//       if (!mounted) return;

// setState(() {

//   nearbyShops = shops;

//   visibleNearbyShops = [];

//   isLoading = false;

//   _appendNextPage();

//   errorMessage = null;
// });

//     } catch (e) {

//       debugPrint(
//         'Medical shop loading error: $e',
//       );

//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         isLoading = false;
//         errorMessage =
//             'Unable to load medical shops.';
//       });
//     }
//   }

// // ==========================================================
// // APPEND NEXT PAGE
// // ==========================================================

// void _appendNextPage() {

//   final currentCount =
//       visibleNearbyShops.length;

//   if (currentCount >= nearbyShops.length) {

//     hasMore = false;

//     return;
//   }

//   final end = (currentCount + pageSize)
//       .clamp(0, nearbyShops.length);

//   visibleNearbyShops.addAll(
//     nearbyShops.sublist(
//       currentCount,
//       end,
//     ),
//   );

//   hasMore = end < nearbyShops.length;
// }

// // ==========================================================
// // SCROLL LISTENER
// // ==========================================================

// void _onScroll() {

//   if (!_scrollController.hasClients) return;

//   if (_scrollController.position.pixels >=
//       _scrollController.position.maxScrollExtent - 250) {

//     _loadMore();
//   }
// }

// // ==========================================================
// // LOAD MORE
// // ==========================================================

// Future<void> _loadMore() async {

//   if (isLoadingMore || !hasMore) return;

//   setState(() {
//     isLoadingMore = true;
//   });

//   await Future<void>.delayed(Duration.zero);

//   if (!mounted) return;

//   setState(() {

//     _appendNextPage();

//     isLoadingMore = false;
//   });
// }
//   // ============================================================
//   // CONVERT FIRESTORE VALUE TO DOUBLE
//   // ============================================================

//   double? _convertToDouble(
//     dynamic value,
//   ) {

//     if (value == null) {
//       return null;
//     }

//     if (value is num) {
//       return value.toDouble();
//     }

//     if (value is String) {
//       return double.tryParse(value);
//     }

//     return null;
//   }

//   // ============================================================
//   // FORMAT DISTANCE
//   // ============================================================

//   String _formatDistance(
//     double distanceKm,
//   ) {

//     if (distanceKm < 1) {

//       final int meters =
//           (distanceKm * 1000).round();

//       return '$meters m';
//     }

//     return '${distanceKm.toStringAsFixed(1)} km';
//   }

//   // ============================================================
//   // GET FIRST LETTER OF SHOP NAME
//   // ============================================================

//   String _getShopInitial(
//     String shopName,
//   ) {

//     final String name =
//         shopName.trim();

//     if (name.isEmpty) {
//       return 'M';
//     }

//     return name
//         .substring(0, 1)
//         .toUpperCase();
//   }

//   // ============================================================
//   // SHOP AVATAR
//   // ============================================================

//   Widget _buildShopAvatar(
//     Map<String, dynamic> shop,
//   ) {

//     final dynamic imageValue =
//         shop['imageUrl'];

//     // If shop image exists
//     if (imageValue is String &&
//         imageValue.trim().isNotEmpty) {

//       return CircleAvatar(
//         radius: 28,

//         backgroundImage:
//             NetworkImage(
//           imageValue.trim(),
//         ),
//       );
//     }

//     // Otherwise show first letter
//     final String shopName =
//         shop['shopName']
//                 ?.toString() ??
//             'Medical Shop';

//     return CircleAvatar(
//       radius: 28,

//       backgroundColor:
//           const Color(0xFFE8F5E9),

//       child: Text(
//         _getShopInitial(
//           shopName,
//         ),

//         style: const TextStyle(
//           color: Color(0xFF12652F),
//           fontSize: 22,
//           fontWeight:
//               FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD SHOP ROW
//   // ============================================================

//   Widget _buildShopRow(
//     Map<String, dynamic> shop,
//   ) {

//     final String shopName =
//         shop['shopName']
//                     ?.toString()
//                     .trim()
//                     .isNotEmpty ==
//                 true
//             ? shop['shopName']
//                 .toString()
//                 .trim()
//             : 'Medical Shop';

//     final double distanceKm =
//         (shop['distanceKm'] as num)
//             .toDouble();

//     // Get place name
//     final String placeName =
//         shop['currentLocation'] is Map
//             ? shop['currentLocation']
//                     ['placeName']
//                 ?.toString() ??
//                 ''
//             : '';

//     return InkWell(

//       // onTap: () {

//       //   Navigator.push(
//       //     context,

//       //     MaterialPageRoute(
//       //       builder: (_) =>
//       //           MedicalShopProfileScreen(
//       //         shop: shop,
//       //       ),
//       //     ),
//       //   );
//       // },
//       onTap: () {
//   _handleMedicalShopTap(shop);
// },

//       child: Container(

//         padding:
//             const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 10,
//         ),

//         child: Row(

//           crossAxisAlignment:
//               CrossAxisAlignment.center,

//           children: [

//             // --------------------------------------------------
//             // SHOP IMAGE / INITIAL
//             // --------------------------------------------------

//             _buildShopAvatar(shop),

//             const SizedBox(width: 14),

//             // --------------------------------------------------
//             // SHOP INFORMATION
//             // --------------------------------------------------

//             Expanded(
//               child: Column(

//                 crossAxisAlignment:
//                     CrossAxisAlignment.start,

//                 children: [

//                   // Shop name
//                   Text(
//                     shopName,

//                     maxLines: 1,

//                     overflow:
//                         TextOverflow.ellipsis,

//                     style:
//                         const TextStyle(
//                       fontSize: 17,
//                       fontWeight:
//                           FontWeight.w600,
//                       color:
//                           Color(0xFF202020),
//                     ),
//                   ),

//                   const SizedBox(height: 4),

//                   // Place name
//                   if (placeName
//                       .trim()
//                       .isNotEmpty)

//                     Text(
//                       placeName,

//                       maxLines: 1,

//                       overflow:
//                           TextOverflow.ellipsis,

//                       style: TextStyle(
//                         fontSize: 13,
//                         color:
//                             Colors.grey
//                                 .shade600,
//                       ),
//                     )

//                   else

//                     Text(
//                       widget.selectedCategory,

//                       maxLines: 1,

//                       overflow:
//                           TextOverflow.ellipsis,

//                       style: TextStyle(
//                         fontSize: 13,
//                         color:
//                             Colors.grey
//                                 .shade600,
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//             const SizedBox(width: 8),

//             // --------------------------------------------------
//             // DISTANCE + ARROW
//             // --------------------------------------------------

//             Column(

//               mainAxisAlignment:
//                   MainAxisAlignment.center,

//               crossAxisAlignment:
//                   CrossAxisAlignment.end,

//               children: [

//                 Text(
//                   _formatDistance(
//                     distanceKm,
//                   ),

//                   style:
//                       TextStyle(
//                     fontSize: 12,
//                     color:
//                         Colors.grey.shade600,
//                   ),
//                 ),

//                 const SizedBox(height: 5),

//                 const Icon(
//                   Icons.chevron_right,
//                   size: 18,
//                   color:
//                       Color(0xFFAAAAAA),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // EMPTY SCREEN
//   // ============================================================

//   Widget _buildEmptyScreen() {

//     return RefreshIndicator(

//       onRefresh:
//           _loadNearbyMedicalShops,

//       child: ListView(

//         physics:
//             const AlwaysScrollableScrollPhysics(),

//         children: [

//           SizedBox(
//             height:
//                 MediaQuery.of(context)
//                     .size
//                     .height *
//                 0.30,
//           ),

//           Icon(
//             Icons.local_pharmacy_outlined,
//             size: 70,
//             color:
//                 Colors.grey.shade400,
//           ),

//           const SizedBox(height: 16),

//           const Text(
//             'No shops found',

//             textAlign:
//                 TextAlign.center,

//             style:
//                 TextStyle(
//               fontSize: 19,
//               fontWeight:
//                   FontWeight.w600,
//             ),
//           ),

//           const SizedBox(height: 7),

//           Padding(
//             padding:
//                 const EdgeInsets.symmetric(
//               horizontal: 35,
//             ),

//             child: Text(
//               'No ${widget.selectedCategory} '
//               'shops were found within 50 km '
//               'of your location.',

//               textAlign:
//                   TextAlign.center,

//               style: TextStyle(
//                 fontSize: 14,
//                 color:
//                     Colors.grey.shade600,
//                 height: 1.4,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // ERROR SCREEN
//   // ============================================================

//   Widget _buildErrorScreen() {

//     return Center(

//       child: Padding(

//         padding:
//             const EdgeInsets.all(25),

//         child: Column(

//           mainAxisSize:
//               MainAxisSize.min,

//           children: [

//             Icon(
//               Icons.location_off_outlined,
//               size: 65,
//               color:
//                   Colors.grey.shade400,
//             ),

//             const SizedBox(height: 16),

//             Text(
//               errorMessage ??
//                   'Something went wrong.',

//               textAlign:
//                   TextAlign.center,

//               style:
//                   const TextStyle(
//                 fontSize: 16,
//                 height: 1.4,
//               ),
//             ),

//             const SizedBox(height: 20),

//             ElevatedButton.icon(

//               onPressed:
//                   _loadNearbyMedicalShops,

//               icon:
//                   const Icon(
//                 Icons.refresh,
//               ),

//               label:
//                   const Text(
//                 'Try Again',
//               ),

//               style:
//                   ElevatedButton.styleFrom(

//                 backgroundColor:
//                     const Color(
//                   0xFF12652F,
//                 ),

//                 foregroundColor:
//                     Colors.white,

//                 padding:
//                     const EdgeInsets
//                         .symmetric(
//                   horizontal: 22,
//                   vertical: 13,
//                 ),

//                 shape:
//                     RoundedRectangleBorder(
//                   borderRadius:
//                       BorderRadius.circular(
//                     12,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(
//     BuildContext context,
//   ) {

//     return Scaffold(

//       backgroundColor:
//           Colors.white,

//       appBar: AppBar(

//         backgroundColor:
//             const Color(0xFF12652F),

//         foregroundColor:
//             Colors.white,

//         elevation: 0,

//         titleSpacing: 0,

//         title: Column(

//           crossAxisAlignment:
//               CrossAxisAlignment.start,

//           children: [

//             // Selected category
//             Text(
//               widget.selectedCategory,

//               maxLines: 1,

//               overflow:
//                   TextOverflow.ellipsis,

//               style:
//                   const TextStyle(
//                 fontSize: 18,
//                 fontWeight:
//                     FontWeight.w600,
//               ),
//             ),

//             Text(
//   isLoading
//       ? 'Finding shops...'
//       : '${nearbyShops.length} shops within 50 km',
//   style: const TextStyle(
//     fontSize: 12,
//     color: Colors.white70,
//   ),
// ),
//           ],
//         ),

//         actions: [

//           // Refresh
//           IconButton(

//             onPressed:
//                 isLoading
//                     ? null
//                     : _loadNearbyMedicalShops,

//             icon:
//                 const Icon(
//               Icons.refresh,
//             ),

//             tooltip:
//                 'Refresh',
//           ),

//           // More menu
//           IconButton(

//             onPressed: () {},

//             icon:
//                 const Icon(
//               Icons.more_vert,
//             ),
//           ),
//         ],
//       ),

//       // ========================================================
//       // BODY
//       // ========================================================

//       body:

//           // LOADING
//           isLoading

//               ? const Center(
//                   child:
//                       CircularProgressIndicator(
//                     color:
//                         Color(0xFF12652F),
//                   ),
//                 )

//               // ERROR
//               : errorMessage != null

//                   ? _buildErrorScreen()

//                   // NO SHOPS
//                   : nearbyShops.isEmpty

//                       ? _buildEmptyScreen()

//                       // SHOP LIST
//                       : RefreshIndicator(

//                           onRefresh:
//                               _loadNearbyMedicalShops,

//                           child:
                        
//                           ListView.separated(

//   controller: _scrollController,

//   physics:
//       const AlwaysScrollableScrollPhysics(),

//   itemCount:
//       visibleNearbyShops.length +
//       (isLoadingMore ? 1 : 0),

//   separatorBuilder: (context, index) {

//     return const Divider(
//       height: 1,
//       indent: 86,
//       color: Color(0xFFE5E5E5),
//     );
//   },

//   itemBuilder: (context, index) {

//     if (index >= visibleNearbyShops.length) {

//       return const Padding(
//         padding: EdgeInsets.all(20),

//         child: Center(
//           child: CircularProgressIndicator(
//             color: Color(0xFF12652F),
//           ),
//         ),
//       );
//     }

//     return _buildShopRow(
//       visibleNearbyShops[index],
//     );
//   },
// ),
//                         ),
//     );
//   }
// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:hive/hive.dart';

// Keep your existing MedicalShopProfileScreen import here.
// Example:
// import 'package:jober_india/jober_indiaScreens.dart/medical_shop/screen_medical_shop_profile.dart';

class MedicalShopNearbyScreen extends StatefulWidget {
  final String selectedCategory;

  const MedicalShopNearbyScreen({
    super.key,
    required this.selectedCategory,
  });

  @override
  State<MedicalShopNearbyScreen> createState() =>
      _MedicalShopNearbyScreenState();
}

class _MedicalShopNearbyScreenState
    extends State<MedicalShopNearbyScreen> {

  // ==========================================================
  // FIRESTORE
  // ==========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================================
  // DISTANCE SETTINGS
  // ==========================================================

  static const double maximumDistanceKm = 50.0;
  static const double freeDistanceKm = 1.0;

  // ==========================================================
  // PAGINATION SETTINGS
  // ==========================================================

  static const int pageSize = 20;

  int visibleCount = pageSize;

  bool isLoadingMore = false;
  bool isFetchingAllShops = false;

  // ==========================================================
  // LOADING STATES
  // ==========================================================

  bool isLoading = true;
  bool isLocationLoading = false;

  bool locationPermissionDenied = false;

  // ==========================================================
  // ERROR
  // ==========================================================

  String? errorMessage;

  // ==========================================================
  // USER LOCATION
  // ==========================================================

  Position? userPosition;

  // ==========================================================
  // MEDICAL SHOPS
  // ==========================================================

  final List<Map<String, dynamic>> nearbyShops = [];

  DocumentSnapshot<Map<String, dynamic>>? lastDocument;

  bool hasMore = true;

  // ==========================================================
  // SUBSCRIPTION
  // ==========================================================

  double paidDistance = 1.0;

  DateTime? paymentExpiry;

  bool subscriptionIsActive = false;

  // ==========================================================
  // SCROLL CONTROLLER
  // ==========================================================

  final ScrollController _scrollController =
      ScrollController();

  // ==========================================================
  // INIT STATE
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    _initializePage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);

    _scrollController.dispose();

    super.dispose();
  }

  // ==========================================================
  // INITIALIZE PAGE
  // ==========================================================

  Future<void> _initializePage() async {

    await _loadPaidDistance();

    if (!mounted) return;

    final locationReady =
        await _getUserLocation();

    if (!locationReady || !mounted) {
      return;
    }

    await _loadNearbyMedicalShops(
      reset: true,
    );
  }

  // ==========================================================
  // LOAD SUBSCRIPTION FROM HIVE
  // ==========================================================

  Future<void> _loadPaidDistance() async {

    try {

      if (!Hive.isBoxOpen('settings')) {
        await Hive.openBox('settings');
      }

      final box = Hive.box('settings');

      final savedDistance =
          box.get('activeDistance');

      final savedExpiry =
          box.get('subscriptionExpiry');

      DateTime? expiry;

      if (savedExpiry is DateTime) {

        expiry = savedExpiry;

      } else if (savedExpiry != null) {

        expiry = DateTime.tryParse(
          savedExpiry.toString(),
        );
      }

      final validSubscription =
          expiry != null &&
          DateTime.now().isBefore(expiry);

      if (validSubscription &&
          savedDistance is num) {

        paidDistance =
            savedDistance.toDouble();

        paymentExpiry = expiry;

        subscriptionIsActive = true;

      } else {

        paidDistance = 1.0;

        paymentExpiry = null;

        subscriptionIsActive = false;

        // Clear expired subscription.

        if (expiry != null &&
            !DateTime.now().isBefore(expiry)) {

          await box.delete('activeDistance');

          await box.delete('subscriptionStart');

          await box.delete('subscriptionExpiry');

          await box.delete('subscriptionDuration');

          await box.delete('subscriptionPaidAmount');

          await box.delete('subscriptionActive');
        }
      }

    } catch (e) {

      debugPrint(
        'Medical shop subscription error: $e',
      );

      paidDistance = 1.0;

      paymentExpiry = null;

      subscriptionIsActive = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ==========================================================
  // LOCATION PERMISSION AND GPS
  // ==========================================================

  Future<bool> _getUserLocation() async {

    if (mounted) {

      setState(() {

        isLocationLoading = true;

        locationPermissionDenied = false;

        errorMessage = null;
      });
    }

    try {

      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {

        if (!mounted) return false;

        setState(() {

          isLocationLoading = false;

          errorMessage =
              'Please turn ON your location service.';
        });

        return false;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {

        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {

        if (!mounted) return false;

        setState(() {

          isLocationLoading = false;

          locationPermissionDenied = true;

          errorMessage =
              'Location permission is required to find nearby medical shops.';
        });

        return false;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return false;

      setState(() {

        userPosition = position;

        isLocationLoading = false;
      });

      return true;

    } catch (e) {

      debugPrint(
        'Medical shop location error: $e',
      );

      if (!mounted) return false;

      setState(() {

        isLocationLoading = false;

        errorMessage =
            'Unable to get your current location.';
      });

      return false;
    }
  }

  // ==========================================================
  // CONVERT VALUE TO DOUBLE
  // ==========================================================

  double? _convertToDouble(dynamic value) {

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim());
    }

    return null;
  }

  // ==========================================================
  // LOAD ALL NEARBY MEDICAL SHOPS
  // ==========================================================

  Future<void> _loadNearbyMedicalShops({
    required bool reset,
  }) async {

    if (userPosition == null ||
        isFetchingAllShops) {
      return;
    }

    if (!reset) return;

    isFetchingAllShops = true;

    if (mounted) {

      setState(() {

        isLoading = true;

        isLoadingMore = false;

        errorMessage = null;

        nearbyShops.clear();

        visibleCount = pageSize;

        lastDocument = null;

        hasMore = true;
      });
    }

    try {

      final List<Map<String, dynamic>> allResults = [];

      // ========================================================
      // FETCH EVERY MATCHING FIRESTORE DOCUMENT
      // ========================================================

      while (hasMore) {

        Query<Map<String, dynamic>> query =
            _firestore
                .collection('medicalShops')
                .where(
                  'categories',
                  arrayContains: widget.selectedCategory,
                )
                .limit(pageSize);

        if (lastDocument != null) {

          query = query.startAfterDocument(
            lastDocument!,
          );
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) {

          hasMore = false;

          break;
        }

        lastDocument = snapshot.docs.last;

        if (snapshot.docs.length < pageSize) {

          hasMore = false;
        }

        // ======================================================
        // CHECK EVERY MEDICAL SHOP
        // ======================================================

        for (final document in snapshot.docs) {

          final data = document.data();

          double? latitude;
          double? longitude;

          // ----------------------------------------------------
          // READ LOCATION
          // Supports GeoPoint and Map.
          // ----------------------------------------------------

          final dynamic locationData =
              data['currentLocation'];

          if (locationData is GeoPoint) {

            latitude = locationData.latitude;

            longitude = locationData.longitude;

          } else if (locationData is Map) {

            latitude = _convertToDouble(
              locationData['latitude'] ??
                  locationData['lat'],
            );

            longitude = _convertToDouble(
              locationData['longitude'] ??
                  locationData['lng'],
            );
          }

          // ----------------------------------------------------
          // FALLBACK TO SEPARATE COORDINATES
          // ----------------------------------------------------

          latitude ??=
              _convertToDouble(data['latitude']);

          longitude ??=
              _convertToDouble(data['longitude']);

          if (latitude == null ||
              longitude == null) {
            continue;
          }

          // ----------------------------------------------------
          // VALIDATE COORDINATES
          // ----------------------------------------------------

          if (latitude < -90 ||
              latitude > 90 ||
              longitude < -180 ||
              longitude > 180) {
            continue;
          }

          // ----------------------------------------------------
          // CALCULATE DISTANCE
          // ----------------------------------------------------

          final distanceInMeters =
              Geolocator.distanceBetween(
            userPosition!.latitude,
            userPosition!.longitude,
            latitude,
            longitude,
          );

          final distanceInKm =
              distanceInMeters / 1000.0;

          // ----------------------------------------------------
          // KEEP ONLY SHOPS WITHIN 50 KM
          // ----------------------------------------------------

          if (distanceInKm > maximumDistanceKm) {
            continue;
          }

          final shop =
              Map<String, dynamic>.from(data);

          shop['id'] = document.id;

          shop['documentId'] = document.id;

          shop['uid'] =
              data['uid']?.toString() ?? document.id;

          shop['latitude'] = latitude;

          shop['longitude'] = longitude;

          shop['distanceKm'] = distanceInKm;

          allResults.add(shop);
        }
      }

      // ========================================================
      // SORT COMPLETE RESULT BY DISTANCE
      // ========================================================

      allResults.sort((a, b) {

        final distanceA =
            _convertToDouble(a['distanceKm']) ??
                double.infinity;

        final distanceB =
            _convertToDouble(b['distanceKm']) ??
                double.infinity;

        return distanceA.compareTo(distanceB);
      });

      if (!mounted) return;

      setState(() {

        nearbyShops
          ..clear()
          ..addAll(allResults);

        // Initially show nearest 20 shops.

        visibleCount =
            nearbyShops.length < pageSize
                ? nearbyShops.length
                : pageSize;

        isLoading = false;

        isLoadingMore = false;

        errorMessage = null;
      });

    } catch (e) {

      debugPrint(
        'Medical shop loading error: $e',
      );

      if (mounted) {

        setState(() {

          isLoading = false;

          isLoadingMore = false;

          errorMessage =
              'Unable to load nearby medical shops.';
        });
      }

    } finally {

      isFetchingAllShops = false;
    }
  }

  // ==========================================================
  // DISPLAYED SHOP COUNT
  // ==========================================================

  int get displayedShopCount {

    return visibleCount < nearbyShops.length
        ? visibleCount
        : nearbyShops.length;
  }

  // ==========================================================
  // SCROLL LISTENER
  // ==========================================================

  void _onScroll() {

    if (!_scrollController.hasClients ||
        isLoadingMore ||
        isLoading) {
      return;
    }

    final position =
        _scrollController.position;

    if (position.pixels >=
        position.maxScrollExtent - 300 &&
        visibleCount < nearbyShops.length) {

      setState(() {

        isLoadingMore = true;

        visibleCount =
            (visibleCount + pageSize >
                    nearbyShops.length)
                ? nearbyShops.length
                : visibleCount + pageSize;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {

        if (mounted) {

          setState(() {
            isLoadingMore = false;
          });
        }
      });
    }
  }

  // ==========================================================
  // SUBSCRIPTION VALIDITY
  // ==========================================================

  bool get hasActiveSubscription {

    return subscriptionIsActive &&
        paymentExpiry != null &&
        DateTime.now().isBefore(paymentExpiry!);
  }

  // ==========================================================
  // CHECK MEDICAL SHOP PROFILE ACCESS
  // ==========================================================

  bool _canOpenMedicalShop(double distanceKm) {

    // First 1 KM is always free.

    if (distanceKm <= freeDistanceKm) {
      return true;
    }

    // Beyond 1 KM requires an active subscription.

    if (!hasActiveSubscription) {
      return false;
    }

    return distanceKm <= paidDistance;
  }

  // ==========================================================
  // HANDLE MEDICAL SHOP TAP
  // ==========================================================

  Future<void> _handleMedicalShopTap(
    Map<String, dynamic> shop,
  ) async {

    final distanceKm =
        _convertToDouble(shop['distanceKm']);

    if (distanceKm == null) {
      return;
    }

    // Always read latest subscription from Hive.

    await _loadPaidDistance();

    if (!mounted) return;

    if (_canOpenMedicalShop(distanceKm)) {

      _goToMedicalShopProfile(shop);

      return;
    }

    _showSubscriptionRequiredDialog(
      distanceKm,
    );
  }

  // ==========================================================
  // OPEN MEDICAL SHOP PROFILE
  // ==========================================================

  void _goToMedicalShopProfile(
    Map<String, dynamic> shop,
  ) {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicalShopProfileScreen(
          shop: shop,
        ),
      ),
    );
  }

  // ==========================================================
  // SUBSCRIPTION REQUIRED DIALOG
  // ==========================================================

  void _showSubscriptionRequiredDialog(
    double distanceKm,
  ) {

    showDialog<void>(
      context: context,
      builder: (dialogContext) {

        return AlertDialog(

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),

          title: const Text(
            'Profile Access',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF202124),
            ),
          ),

          content: Text(
            'This medical shop is '
            '${distanceKm.toStringAsFixed(1)} km away.\n\n'
            'Your current access radius is '
            '${paidDistance.toStringAsFixed(0)} km.\n\n'
            'Unlock a larger radius to open this medical shop profile.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {

                Navigator.pop(dialogContext);

                _showRadiusInformation(
                  distanceKm.ceil(),
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF159B16),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),

              child: const Text(
                'VIEW OPTIONS',
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // DISTANCE INFORMATION
  // ==========================================================

  void _showRadiusInformation(
    int requiredRadius,
  ) {

    showDialog<void>(
      context: context,
      builder: (dialogContext) {

        return AlertDialog(

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),

          title: const Text(
            'Distance Access',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Text(
            'This medical shop is approximately '
            '$requiredRadius km away.\n\n'
            'Your existing distance-unlock/payment '
            'flow can be connected here.',
            style: const TextStyle(
              height: 1.5,
            ),
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // REFRESH
  // ==========================================================

  Future<void> _refresh() async {

    await _loadPaidDistance();

    if (!mounted) return;

    final locationReady =
        await _getUserLocation();

    if (!locationReady || !mounted) {
      return;
    }

    await _loadNearbyMedicalShops(
      reset: true,
    );
  }

  // ==========================================================
  // FORMAT DISTANCE
  // ==========================================================

  String _formatDistance(double distanceKm) {

    if (distanceKm < 1) {

      final meters =
          (distanceKm * 1000).round();

      return '$meters m away';
    }

    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  // ==========================================================
  // GET SHOP NAME
  // ==========================================================

  String _getShopName(
    Map<String, dynamic> shop,
  ) {

    final shopName =
        shop['shopName']?.toString().trim();

    if (shopName != null &&
        shopName.isNotEmpty) {
      return shopName;
    }

    return 'Medical Shop';
  }

  // ==========================================================
  // GET SHOP PLACE
  // ==========================================================

  String _getPlaceName(
    Map<String, dynamic> shop,
  ) {

    final location =
        shop['currentLocation'];

    if (location is Map) {

      final placeName =
          location['placeName']?.toString().trim();

      if (placeName != null &&
          placeName.isNotEmpty) {
        return placeName;
      }
    }

    final town =
        shop['nearestTown']?.toString().trim();

    if (town != null && town.isNotEmpty) {
      return town;
    }

    return widget.selectedCategory;
  }

  // ==========================================================
  // GET SHOP INITIAL
  // ==========================================================

  String _getShopInitial(
    String shopName,
  ) {

    final name = shopName.trim();

    if (name.isEmpty) {
      return 'M';
    }

    return name.substring(0, 1).toUpperCase();
  }

  // ==========================================================
  // GET SHOP TIMING
  // ==========================================================

  String _getTimingText(
    Map<String, dynamic> shop,
  ) {

    final isOpen24Hours =
        shop['isOpen24Hours'] == true;

    if (isOpen24Hours) {
      return 'Open 24 Hours';
    }

    final openingTime =
        shop['openingTime']?.toString().trim() ?? '';

    final closingTime =
        shop['closingTime']?.toString().trim() ?? '';

    if (openingTime.isNotEmpty &&
        closingTime.isNotEmpty) {

      return '$openingTime - $closingTime';
    }

    return 'Timing not available';
  }

  // ==========================================================
  // SHOP AVATAR
  // ==========================================================

  Widget _buildShopAvatar(
    Map<String, dynamic> shop,
  ) {

    final photoUrl =
        (shop['profilePhotoUrl'] ??
                shop['imageUrl'] ??
                shop['photoUrl'])
            ?.toString()
            .trim();

    if (photoUrl != null &&
        photoUrl.isNotEmpty) {

      return ClipRRect(
        borderRadius: BorderRadius.circular(15),

        child: Image.network(
          photoUrl,
          width: 72,
          height: 72,
          fit: BoxFit.cover,

          errorBuilder: (_, _, _) {
            return _defaultShopAvatar(
              _getShopName(shop),
            );
          },
        ),
      );
    }

    return _defaultShopAvatar(
      _getShopName(shop),
    );
  }

  // ==========================================================
  // DEFAULT SHOP AVATAR
  // ==========================================================

  Widget _defaultShopAvatar(
    String shopName,
  ) {

    return Container(

      width: 72,
      height: 72,

      decoration: BoxDecoration(
        color: const Color(0xFFEFF8EF),
        borderRadius: BorderRadius.circular(15),
      ),

      child: Center(
        child: Text(
          _getShopInitial(shopName),

          style: const TextStyle(
            color: Color(0xFF12652F),
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // MEDICAL SHOP CARD
  // ==========================================================

  Widget _buildShopCard(
    Map<String, dynamic> shop,
  ) {

    final shopName =
        _getShopName(shop);

    final distanceKm =
        _convertToDouble(shop['distanceKm']) ?? 0.0;

    final placeName =
        _getPlaceName(shop);

    final timingText =
        _getTimingText(shop);

    final canOpen =
        _canOpenMedicalShop(distanceKm);

    final isOpen24Hours =
        shop['isOpen24Hours'] == true;

    return Material(

      color: Colors.white,

      borderRadius: BorderRadius.circular(20),

      child: InkWell(

        borderRadius: BorderRadius.circular(20),

        onTap: () {
          _handleMedicalShopTap(shop);
        },

        child: Container(

          padding: const EdgeInsets.all(15),

          decoration: BoxDecoration(

            color: Colors.white,

            borderRadius: BorderRadius.circular(20),

            border: Border.all(
              color: const Color(0xFFE1E1E1),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Row(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              // SHOP IMAGE

              _buildShopAvatar(shop),

              const SizedBox(width: 13),

              // SHOP INFORMATION

              Expanded(
                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    // SHOP NAME

                    Text(
                      shopName,

                      maxLines: 2,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: Color(0xFF202124),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // CATEGORY

                    Text(
                      widget.selectedCategory,

                      maxLines: 2,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: Color(0xFF16803C),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 9),

                    // DISTANCE

                    Row(
                      children: [

                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFE87516),
                          size: 18,
                        ),

                        const SizedBox(width: 4),

                        Expanded(
                          child: Text(
                            _formatDistance(distanceKm),

                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    // PLACE NAME

                    Row(
                      children: [

                        const Icon(
                          Icons.place_outlined,
                          color: Colors.grey,
                          size: 17,
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            placeName,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    // SHOP TIMING

                    Row(
                      children: [

                        Icon(
                          Icons.access_time,
                          color: isOpen24Hours
                              ? const Color(0xFF16803C)
                              : Colors.grey,
                          size: 17,
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            timingText,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              color: isOpen24Hours
                                  ? const Color(0xFF16803C)
                                  : Colors.grey,
                              fontSize: 12,
                              fontWeight: isOpen24Hours
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              // PROFILE ACCESS INDICATOR

              Column(
                children: [

                  Icon(
                    canOpen
                        ? Icons.arrow_forward_ios
                        : Icons.lock_outline,

                    color: canOpen
                        ? const Color(0xFF16803C)
                        : Colors.grey,

                    size: 18,
                  ),

                  const SizedBox(height: 8),

                  if (!canOpen)
                    const Text(
                      'Locked',

                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
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
  // TOP SECTION
  // ==========================================================

  Widget _buildTopSection() {

    return Padding(

      padding: const EdgeInsets.fromLTRB(
        20,
        15,
        20,
        18,
      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(
            'Selected Category',

            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            widget.selectedCategory,

            style: const TextStyle(
              color: Color(0xFF202124),
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Medical shops within 50 km from your current location',

            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 12),

          Container(

            width: double.infinity,

            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),

            decoration: BoxDecoration(
              color: const Color(0xFFEFF8EF),
              borderRadius: BorderRadius.circular(14),
            ),

            child: Row(

              children: [

                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF16803C),
                  size: 21,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    '${nearbyShops.length} '
                    'medical shop${nearbyShops.length == 1 ? '' : 's'} found',

                    style: const TextStyle(
                      color: Color(0xFF16803C),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Icon(
                  Icons.sort,
                  color: Color(0xFF16803C),
                  size: 20,
                ),

                const SizedBox(width: 4),

                const Text(
                  'Nearest first',

                  style: TextStyle(
                    color: Color(0xFF16803C),
                    fontSize: 13,
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

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState() {

    return Center(

      child: Padding(

        padding: const EdgeInsets.all(30),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Container(

              width: 82,
              height: 82,

              decoration: BoxDecoration(
                color: const Color(0xFFEFF8EF),
                borderRadius: BorderRadius.circular(24),
              ),

              child: const Icon(
                Icons.local_pharmacy_outlined,
                color: Color(0xFF16803C),
                size: 42,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No nearby medical shops',

              textAlign: TextAlign.center,

              style: TextStyle(
                color: Color(0xFF202124),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'No ${widget.selectedCategory} shops '
              'were found within 50 km.',

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(

              onPressed: _refresh,

              icon: const Icon(Icons.refresh),

              label: const Text('SEARCH AGAIN'),

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF159B16),
                foregroundColor: Colors.white,
                minimumSize: const Size(170, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // LOCATION ERROR
  // ==========================================================

  Widget _buildLocationError() {

    return Center(

      child: Padding(

        padding: const EdgeInsets.all(30),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Container(

              width: 82,
              height: 82,

              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E8),
                borderRadius: BorderRadius.circular(24),
              ),

              child: const Icon(
                Icons.location_off_outlined,
                color: Color(0xFFE87516),
                size: 42,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Location Required',

              style: TextStyle(
                color: Color(0xFF202124),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              errorMessage ??
                  'Turn on location to find nearby medical shops.',

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(

              onPressed: _refresh,

              icon: const Icon(Icons.location_on),

              label: const Text('ENABLE LOCATION'),

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF159B16),
                foregroundColor: Colors.white,
                minimumSize: const Size(190, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD BODY
  // ==========================================================

  Widget _buildBody() {

    if (isLocationLoading) {

      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF159B16),
        ),
      );
    }

    if (locationPermissionDenied ||
        errorMessage != null) {

      return _buildLocationError();
    }

    return RefreshIndicator(

      color: const Color(0xFF159B16),

      onRefresh: _refresh,

      child: CustomScrollView(

        controller: _scrollController,

        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),

        slivers: [

          // TOP SECTION

          SliverToBoxAdapter(
            child: _buildTopSection(),
          ),

          // LOADING

          if (isLoading)

            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF159B16),
                ),
              ),
            )

          // EMPTY

          else if (nearbyShops.isEmpty)

            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )

          // SHOP LIST

          else

            SliverPadding(

              padding: const EdgeInsets.fromLTRB(
                18,
                0,
                18,
                25,
              ),

              sliver: SliverList.builder(

                itemCount:
                    displayedShopCount +
                    (isLoadingMore ? 1 : 0),

                itemBuilder: (context, index) {

                  // LOADING MORE INDICATOR

                  if (index >= displayedShopCount) {

                    return const Padding(

                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                      ),

                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF159B16),
                        ),
                      ),
                    );
                  }

                  // MEDICAL SHOP CARD

                  return Padding(

                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),

                    child: _buildShopCard(
                      nearbyShops[index],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // MAIN BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF7F8F7),

      appBar: AppBar(

        backgroundColor: Colors.white,

        elevation: 0,

        leading: IconButton(

          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 30,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: RichText(

          text: const TextSpan(

            children: [

              TextSpan(
                text: 'Nearby ',
                style: TextStyle(
                  color: Color(0xFF08744F),
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              TextSpan(
                text: 'Medical Shops',
                style: TextStyle(
                  color: Color(0xFFE87516),
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        actions: [

          IconButton(

            onPressed: isLoading
                ? null
                : _refresh,

            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF16803C),
            ),

            tooltip: 'Refresh',
          ),
        ],
      ),

      body: _buildBody(),
    );
  }
}
// ============================================================
// MEDICAL SHOP PROFILE SCREEN
//
// Shows:
// • Medical shop name
// • Category
// • Owner name
// • Shop age
// • Location
//
// Actions:
// • Call Medical Shop
// • Open Directions
// • Chat with Medical Shop
//
// NOTE:
// Mobile number is NOT displayed directly.
// It is only used when the user presses "Call Medical Shop".
// ============================================================

// class MedicalShopProfileScreen
//     extends StatelessWidget {

//   final Map<String, dynamic> shop;

//   const MedicalShopProfileScreen({
//     super.key,
//     required this.shop,
//   });

//   // ============================================================
//   // CALL MEDICAL SHOP
//   // ============================================================

//   Future<void> _callMedicalShop(
//     BuildContext context,
//   ) async {

//     final String mobileNumber =
//         shop['mobileNumber']
//                 ?.toString()
//                 .trim() ??
//             '';

//     if (mobileNumber.isEmpty) {

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Mobile number is not available.',
//           ),
//         ),
//       );

//       return;
//     }

//     final Uri phoneUri = Uri(
//       scheme: 'tel',
//       path: mobileNumber,
//     );

//     try {

//       if (await canLaunchUrl(phoneUri)) {

//         await launchUrl(
//           phoneUri,
//           mode:
//               LaunchMode.externalApplication,
//         );

//       } else {

//         if (!context.mounted) return;

//         ScaffoldMessenger.of(context)
//             .showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Unable to open phone app.',
//             ),
//           ),
//         );
//       }

//     } catch (e) {

//       debugPrint(
//         'Call medical shop error: $e',
//       );

//       if (!context.mounted) return;

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Unable to make the call.',
//           ),
//         ),
//       );
//     }
//   }

//   // ============================================================
//   // OPEN MEDICAL SHOP LOCATION
//   // ============================================================

//   Future<void> _openMedicalShopLocation(
//     BuildContext context,
//   ) async {

//     final dynamic locationData =
//         shop['currentLocation'];

//     if (locationData is! Map) {

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Location is not available.',
//           ),
//         ),
//       );

//       return;
//     }

//     final Map<String, dynamic> location =
//         Map<String, dynamic>.from(
//       locationData,
//     );

//     final double? latitude =
//         _convertToDouble(
//       location['latitude'],
//     );

//     final double? longitude =
//         _convertToDouble(
//       location['longitude'],
//     );

//     if (latitude == null ||
//         longitude == null) {

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Medical shop location is not available.',
//           ),
//         ),
//       );

//       return;
//     }

//     // Google Maps directions URL
//     final Uri mapsUri = Uri.parse(
//       'https://www.google.com/maps/dir/'
//       '?api=1'
//       '&destination=$latitude,$longitude',
//     );

//     try {

//       if (await canLaunchUrl(mapsUri)) {

//         await launchUrl(
//           mapsUri,
//           mode:
//               LaunchMode.externalApplication,
//         );

//       } else {

//         if (!context.mounted) return;

//         ScaffoldMessenger.of(context)
//             .showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Unable to open Google Maps.',
//             ),
//           ),
//         );
//       }

//     } catch (e) {

//       debugPrint(
//         'Open medical shop location error: $e',
//       );

//       if (!context.mounted) return;

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Unable to open location.',
//           ),
//         ),
//       );
//     }
//   }

//   // ============================================================
//   // OPEN CHAT
//   //
//   // This currently prepares the shop information for your
//   // messaging flow.
//   //
//   // If your existing MessageScreen has a specific constructor,
//   // connect it here without changing the shop data structure.
//   // ============================================================

//   void _openMedicalShopChat(
//     BuildContext context,
//   ) {

//     final String shopName =
//         shop['shopName']
//                 ?.toString()
//                 .trim()
//                 .isNotEmpty ==
//             true
//             ? shop['shopName']
//                 .toString()
//                 .trim()
//             : 'Medical Shop';

//     ScaffoldMessenger.of(context)
//         .showSnackBar(
//       SnackBar(
//         content: Text(
//           'Chat with $shopName',
//         ),
//       ),
//     );

//     // ----------------------------------------------------------
//     // IMPORTANT:
//     //
//     // Your actual MessageScreen constructor was not provided
//     // here, so I am NOT inventing one.
//     //
//     // When connecting your existing MessageScreen, pass:
//     //
//     // shopName
//     // mobileNumber
//     // shop id / uid
//     // location
//     //
//     // to your existing chat screen.
//     // ----------------------------------------------------------
//   }

//   // ============================================================
//   // CONVERT VALUE TO DOUBLE
//   // ============================================================

//   double? _convertToDouble(
//     dynamic value,
//   ) {

//     if (value == null) {
//       return null;
//     }

//     if (value is num) {
//       return value.toDouble();
//     }

//     if (value is String) {
//       return double.tryParse(value);
//     }

//     return null;
//   }

//   // ============================================================
//   // DETAIL ROW
//   // ============================================================

//   Widget _detailRow({
//     required IconData icon,
//     required String title,
//     required String value,
//   }) {

//     return Container(

//       margin:
//           const EdgeInsets.only(
//         bottom: 12,
//       ),

//       padding:
//           const EdgeInsets.all(15),

//       decoration:
//           BoxDecoration(
//         color:
//             const Color(0xFFF8F8F8),

//         borderRadius:
//             BorderRadius.circular(15),

//         border: Border.all(
//           color:
//               const Color(0xFFE5E5E5),
//         ),
//       ),

//       child: Row(

//         crossAxisAlignment:
//             CrossAxisAlignment.start,

//         children: [

//           Icon(
//             icon,
//             color:
//                 const Color(0xFF12652F),
//           ),

//           const SizedBox(width: 13),

//           Expanded(
//             child: Column(

//               crossAxisAlignment:
//                   CrossAxisAlignment.start,

//               children: [

//                 Text(
//                   title,

//                   style:
//                       TextStyle(
//                     fontSize: 12,
//                     color:
//                         Colors.grey.shade600,
//                   ),
//                 ),

//                 const SizedBox(height: 3),

//                 Text(
//                   value,

//                   style:
//                       const TextStyle(
//                     fontSize: 15,
//                     fontWeight:
//                         FontWeight.w500,
//                     color:
//                         Color(0xFF222222),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // ACTION ROW
//   // ============================================================

//   Widget _actionRow({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {

//     return Container(

//       margin:
//           const EdgeInsets.only(
//         bottom: 12,
//       ),

//       decoration:
//           BoxDecoration(
//         color:
//             const Color(0xFFE8F5E9),

//         borderRadius:
//             BorderRadius.circular(15),

//         border: Border.all(
//           color:
//               const Color(0xFFD2EBD5),
//         ),
//       ),

//       child: Material(
//         color: Colors.transparent,

//         child: InkWell(

//           borderRadius:
//               BorderRadius.circular(15),

//           onTap: onTap,

//           child: Padding(

//             padding:
//                 const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 16,
//             ),

//             child: Row(

//               children: [

//                 Icon(
//                   icon,

//                   color:
//                       const Color(0xFF12652F),

//                   size: 25,
//                 ),

//                 const SizedBox(width: 14),

//                 Expanded(
//                   child: Text(
//                     title,

//                     style:
//                         const TextStyle(
//                       fontSize: 15,
//                       fontWeight:
//                           FontWeight.w600,
//                       color:
//                           Color(0xFF222222),
//                     ),
//                   ),
//                 ),

//                 const Icon(
//                   Icons.arrow_forward_ios,
//                   size: 16,
//                   color:
//                       Color(0xFF777777),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // CHAT BUTTON
//   // ============================================================

//   Widget _chatButton(
//     BuildContext context,
//   ) {

//     return SizedBox(
//       width: double.infinity,

//       child: ElevatedButton.icon(

//         onPressed: () {
//           _openMedicalShopChat(
//             context,
//           );
//         },

//         icon: const Icon(
//           Icons.chat_bubble_outline,
//         ),

//         label: const Text(
//           'Chat with Medical Shop',
//         ),

//         style:
//             ElevatedButton.styleFrom(

//           backgroundColor:
//               const Color(0xFF12652F),

//           foregroundColor:
//               Colors.white,

//           minimumSize:
//               const Size(
//             double.infinity,
//             52,
//           ),

//           elevation: 0,

//           shape:
//               RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(
//               15,
//             ),
//           ),

//           textStyle:
//               const TextStyle(
//             fontSize: 16,
//             fontWeight:
//                 FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD PROFILE SCREEN
//   // ============================================================

//   @override
//   Widget build(
//     BuildContext context,
//   ) {

//     // ----------------------------------------------------------
//     // SHOP NAME
//     // ----------------------------------------------------------

//     final String shopName =
//         shop['shopName']
//                 ?.toString()
//                 .trim()
//                 .isNotEmpty ==
//             true
//             ? shop['shopName']
//                 .toString()
//                 .trim()
//             : 'Medical Shop';

//     // ----------------------------------------------------------
//     // OWNER NAME
//     // ----------------------------------------------------------

//     final String ownerName =
//         shop['name']
//                 ?.toString()
//                 .trim() ??
//             '';

//     // ----------------------------------------------------------
//     // SHOP AGE
//     // ----------------------------------------------------------

//     final String shopAge =
//         shop['shopAge']
//                 ?.toString()
//                 .trim() ??
//             '';

//     // ----------------------------------------------------------
//     // CATEGORIES
//     // ----------------------------------------------------------

//     final List<String> categories =
//         shop['medicalShopCategories']
//                 is List
//             ? List<String>.from(
//                 shop[
//                     'medicalShopCategories'],
//               )
//             : <String>[];

//     // ----------------------------------------------------------
//     // LOCATION
//     // ----------------------------------------------------------

//     final Map<String, dynamic> location =
//         shop['currentLocation']
//                 is Map
//             ? Map<String, dynamic>.from(
//                 shop['currentLocation'],
//               )
//             : <String, dynamic>{};

//     final String placeName =
//         location['placeName']
//                 ?.toString()
//                 .trim() ??
//             '';

//     // ----------------------------------------------------------
//     // SCREEN
//     // ----------------------------------------------------------

//     return Scaffold(

//       backgroundColor:
//           Colors.white,

//       appBar: AppBar(

//         backgroundColor:
//             const Color(0xFF12652F),

//         foregroundColor:
//             Colors.white,

//         elevation: 0,

//         title:
//             const Text(
//           'Medical Shop',
//           style:
//               TextStyle(
//             fontWeight:
//                 FontWeight.bold,
//           ),
//         ),
//       ),

//       body: ListView(

//         padding:
//             const EdgeInsets.all(20),

//         children: [

//           // ====================================================
//           // SHOP ICON
//           // ====================================================

//           Center(

//             child: CircleAvatar(

//               radius: 48,

//               backgroundColor:
//                   const Color(0xFFE8F5E9),

//               child:
//                   const Icon(
//                 Icons.local_pharmacy,
//                 size: 50,
//                 color:
//                     Color(0xFF12652F),
//               ),
//             ),
//           ),

//           const SizedBox(height: 16),

//           // ====================================================
//           // SHOP NAME
//           // ====================================================

//           Text(
//             shopName,

//             textAlign:
//                 TextAlign.center,

//             style:
//                 const TextStyle(
//               fontSize: 24,
//               fontWeight:
//                   FontWeight.bold,
//               color:
//                   Color(0xFF222222),
//             ),
//           ),

//           const SizedBox(height: 25),

//           // ====================================================
//           // CATEGORY
//           // ====================================================

//           _detailRow(

//             icon:
//                 Icons.category_outlined,

//             title:
//                 'Category',

//             value:
//                 categories.isEmpty
//                     ? 'Medical Shop'
//                     : categories.join(
//                         ', ',
//                       ),
//           ),

//           // ====================================================
//           // OWNER
//           // ====================================================

//           if (ownerName
//               .trim()
//               .isNotEmpty)

//             _detailRow(

//               icon:
//                   Icons.person_outline,

//               title:
//                   'Owner',

//               value:
//                   ownerName,
//             ),

//           // ====================================================
//           // SHOP AGE
//           // ====================================================

//           if (shopAge
//               .trim()
//               .isNotEmpty)

//             _detailRow(

//               icon:
//                   Icons.calendar_month_outlined,

//               title:
//                   'Shop Age',

//               value:
//                   shopAge,
//             ),

//           // ====================================================
//           // LOCATION
//           // ====================================================

//           if (placeName
//               .trim()
//               .isNotEmpty)

//             _actionRow(

//               icon:
//                   Icons.location_on_outlined,

//               title:
//                   'Open Directions',

//               onTap: () {
//                 _openMedicalShopLocation(
//                   context,
//                 );
//               },
//             ),

//           // ====================================================
//           // CALL
//           // ====================================================

//           _actionRow(

//             icon:
//                 Icons.phone_outlined,

//             title:
//                 'Call Medical Shop',

//             onTap: () {
//               _callMedicalShop(
//                 context,
//               );
//             },
//           ),

//           const SizedBox(height: 8),

//           // ====================================================
//           // CHAT
//           // ====================================================

//           _chatButton(
//             context,
//           ),

//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }
// }

class MedicalShopProfileScreen extends StatefulWidget {
  final Map<String, dynamic> shop;
  final double? userLatitude;
  final double? userLongitude;
  final String? selectedCategory;

  const MedicalShopProfileScreen({
    super.key,
    required this.shop,
    this.userLatitude,
    this.userLongitude,
    this.selectedCategory,
  });

  @override
  State<MedicalShopProfileScreen> createState() =>
      _MedicalShopProfileScreenState();
}

class _MedicalShopProfileScreenState
    extends State<MedicalShopProfileScreen> {

  static const Color green = Color(0xFF16803C);
  static const Color darkGreen = Color(0xFF12652F);
  static const Color orange = Color(0xFFED801D);
  static const Color background = Color(0xFFF7F7F7);

  late Map<String, dynamic> shop;

  String shopId = '';
  String ownerName = '';
  String shopName = 'Medical Shop';
  String category = '';
  String phoneNumber = '';
  String stateName = '';
  String district = '';
  String nearestTown = '';
  String openingTime = '';
  String closingTime = '';

  List<String> categories = [];

  double? latitude;
  double? longitude;
  double? distanceInKm;

  bool isActive = true;
  bool isOpen24Hours = false;
  bool isCalling = false;
  bool isOpeningLocation = false;

  @override
  void initState() {
    super.initState();

    shop = Map<String, dynamic>.from(widget.shop);

    _readShopData();
  }

  // ==========================================================
  // READ SHOP DATA
  // ==========================================================

  void _readShopData() {

    shopId = (shop['uid'] ??
            shop['shopId'] ??
            shop['id'] ??
            '')
        .toString();

    ownerName = (shop['name'] ?? '')
        .toString()
        .trim();

    shopName = (shop['shopName'] ??
            shop['name'] ??
            'Medical Shop')
        .toString()
        .trim();

    if (shopName.isEmpty) {
      shopName = 'Medical Shop';
    }

    final rawCategories = shop['categories'] ??
        shop['medicalShopCategories'];

    if (rawCategories is List) {
      categories = rawCategories
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
    }

    category = widget.selectedCategory?.trim().isNotEmpty == true
        ? widget.selectedCategory!.trim()
        : categories.isNotEmpty
            ? categories.first
            : 'Medical Shop';

    // IMPORTANT:
    // Use SECONDARY number for calling.
    // Do not use mobileNumber here.

    phoneNumber = (shop['secondaryMobileNumber'] ??
            shop['secondaryPhone'] ??
            shop['secondaryMobile'] ??
            '')
        .toString()
        .trim();

    stateName = (shop['state'] ?? '').toString().trim();

    district = (shop['district'] ?? '').toString().trim();

    nearestTown = (shop['nearestTown'] ?? '').toString().trim();

    openingTime = (shop['openingTime'] ?? '').toString().trim();

    closingTime = (shop['closingTime'] ?? '').toString().trim();

    isOpen24Hours = shop['isOpen24Hours'] == true;

    final activeValue = shop['isActive'];

    isActive = activeValue is bool ? activeValue : true;

    _readLocation();

    _calculateDistance();
  }

  // ==========================================================
  // CONVERT TO DOUBLE
  // ==========================================================

  double? _toDouble(dynamic value) {

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  // ==========================================================
  // READ LOCATION
  // ==========================================================

  void _readLocation() {

    latitude = null;
    longitude = null;

    final candidates = [
      shop['currentLocation'],
      shop['locationAddress'],
      shop['location'],
      shop,
    ];

    for (final candidate in candidates) {

      if (candidate is GeoPoint) {
        latitude = candidate.latitude;
        longitude = candidate.longitude;
        break;
      }

      if (candidate is! Map) continue;

      final lat = _toDouble(
        candidate['latitude'] ?? candidate['lat'],
      );

      final lng = _toDouble(
        candidate['longitude'] ??
            candidate['lng'] ??
            candidate['lon'],
      );

      if (lat != null &&
          lng != null &&
          lat >= -90 &&
          lat <= 90 &&
          lng >= -180 &&
          lng <= 180) {

        latitude = lat;
        longitude = lng;
        break;
      }

      final point = candidate['geoPoint'] ??
          candidate['coordinates'];

      if (point is GeoPoint) {
        latitude = point.latitude;
        longitude = point.longitude;
        break;
      }
    }
  }

  // ==========================================================
  // CALCULATE DISTANCE
  // ==========================================================

  void _calculateDistance() {

    if (widget.userLatitude == null ||
        widget.userLongitude == null ||
        latitude == null ||
        longitude == null) {

      distanceInKm = null;
      return;
    }

    distanceInKm = Geolocator.distanceBetween(
          widget.userLatitude!,
          widget.userLongitude!,
          latitude!,
          longitude!,
        ) /
        1000;
  }

  String get formattedDistance {

    if (distanceInKm == null) {
      return 'Distance unavailable';
    }

    if (distanceInKm! < 1) {
      return '${(distanceInKm! * 1000).round()} m away';
    }

    return '${distanceInKm!.toStringAsFixed(1)} km away';
  }

  String get statusText =>
      isActive ? 'Active' : 'Currently unavailable';

  Color get statusColor =>
      isActive ? green : Colors.grey;

  String get locationDescription {

    final parts = [
      nearestTown,
      district,
      stateName,
    ].where((item) => item.trim().isNotEmpty).toList();

    return parts.isEmpty
        ? 'Location details unavailable'
        : parts.join(', ');
  }

  // ==========================================================
  // SNACKBAR
  // ==========================================================

  void _showMessage(String message) {

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // CALL MEDICAL SHOP
  // SECONDARY MOBILE NUMBER ONLY
  // ==========================================================

  Future<void> callMedicalShop() async {

    if (phoneNumber.isEmpty) {
      _showMessage(
        'Medical shop contact number is not available.',
      );
      return;
    }

    if (isCalling) return;

    setState(() => isCalling = true);

    try {

      var phone = phoneNumber.replaceAll(
        RegExp(r'\s+'),
        '',
      );

      if (!phone.startsWith('+') &&
          phone.length == 10) {
        phone = '+91$phone';
      }

      final uri = Uri(
        scheme: 'tel',
        path: phone,
      );

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage(
          'Unable to open the phone application.',
        );
      }

    } catch (e) {

      debugPrint('Medical shop call error: $e');

      _showMessage(
        'Unable to open the phone application.',
      );

    } finally {

      if (mounted) {
        setState(() => isCalling = false);
      }
    }
  }

  // ==========================================================
  // OPEN LOCATION
  // ==========================================================

  Future<void> openShopLocation() async {

    if (latitude == null || longitude == null) {
      _showMessage(
        'Medical shop location is not available.',
      );
      return;
    }

    if (isOpeningLocation) return;

    setState(() => isOpeningLocation = true);

    try {

      final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$latitude,$longitude'
        '&travelmode=driving',
      );

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage('Unable to open Google Maps.');
      }

    } catch (e) {

      debugPrint('Medical shop map error: $e');

      _showMessage(
        'Unable to open the medical shop location.',
      );

    } finally {

      if (mounted) {
        setState(() => isOpeningLocation = false);
      }
    }
  }

  // ==========================================================
  // OPEN CHAT
  // ==========================================================

  void openChat() {

    if (shopId.isEmpty) {
      _showMessage(
        'Medical shop account information is unavailable.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenMessage(
          chatUser: {
            'uid': shopId,
            'name': shopName,
            'location': formattedDistance,
            'type': 'medicalShop',
          },
        ),
      ),
    );
  }

  // ==========================================================
  // PROFILE HEADER
  // ==========================================================

  Widget _profileHeader() {

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(
        16, 12, 16, 28,
      ),

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [darkGreen, green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),

      child: SafeArea(
        bottom: false,

        child: Column(
          children: [

            Row(
              children: [

                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),

                const Spacer(),

                if (category.isNotEmpty)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Text(
                        category,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              width: 92,
              height: 92,

              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.local_pharmacy,
                color: green,
                size: 49,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              shopName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            if (categories.length > 1) ...[

              const SizedBox(height: 8),

              Text(
                categories.join(' • '),
                textAlign: TextAlign.center,

                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Row(
                mainAxisSize: MainAxisSize.min,

                children: [

                  Container(
                    width: 9,
                    height: 9,

                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    statusText,

                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // INFORMATION CARD
  // ==========================================================

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    Color iconColor = green,
  }) {

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
        ),
      ),

      child: Row(
        children: [

          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),

            child: Icon(
              icon,
              color: iconColor,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTION BUTTON
  // ==========================================================

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool loading = false,
  }) {

    return Expanded(
      child: ElevatedButton(

        onPressed: loading ? null : onPressed,

        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          foregroundColor: Colors.white,

          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 4,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),

        child: loading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,

                children: [

                  Icon(icon, size: 23),

                  const SizedBox(height: 5),

                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ==========================================================
  // ACTION SECTION
  // ==========================================================

  Widget _actionSection() {

    return Row(
      children: [

        _actionButton(
          icon: Icons.call,
          label: 'Call',
          color: green,
          loading: isCalling,
          onPressed: callMedicalShop,
        ),

        const SizedBox(width: 9),

        _actionButton(
          icon: Icons.location_on_outlined,
          label: 'Location',
          color: orange,
          loading: isOpeningLocation,
          onPressed: openShopLocation,
        ),

        const SizedBox(width: 9),

        _actionButton(
          icon: Icons.chat_bubble_outline,
          label: 'Chat',
          color: darkGreen,
          onPressed: openChat,
        ),
      ],
    );
  }

  // ==========================================================
  // OPENING HOURS
  // ==========================================================

  Widget _openingHoursCard() {

    final value = isOpen24Hours
        ? 'Open 24 hours'
        : openingTime.isNotEmpty &&
                closingTime.isNotEmpty
            ? '$openingTime – $closingTime'
            : 'Opening hours not provided';

    return _infoCard(
      icon: Icons.access_time,
      title: 'Opening Hours',
      value: value,
      iconColor: orange,
    );
  }

  // ==========================================================
  // ABOUT SECTION
  // ==========================================================

  Widget _aboutSection() {

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Row(
            children: [

              Icon(
                Icons.info_outline,
                color: green,
              ),

              SizedBox(width: 9),

              Text(
                'About this Medical Shop',

                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Welcome to $shopName.'
            '${category.isNotEmpty ? ' Category: $category.' : ''} '
            'Use the buttons above to call the medical shop, '
            'get directions, or start a chat.',

            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        top: false,

        child: Column(
          children: [

            _profileHeader(),

            Expanded(
              child: SingleChildScrollView(

                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    _actionSection(),

                    const SizedBox(height: 23),

                    const Text(
                      'Medical Shop Information',

                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 13),

                    _infoCard(
                      icon: Icons.category_outlined,
                      title: 'Medical Shop Categories',
                      value: categories.isEmpty
                          ? category
                          : categories.join(', '),
                    ),

                    const SizedBox(height: 11),

                    _infoCard(
                      icon: Icons.location_on_outlined,
                      title: 'Distance from you',
                      value: formattedDistance,
                      iconColor: orange,
                    ),

                    const SizedBox(height: 11),

                    _infoCard(
                      icon: Icons.map_outlined,
                      title: 'Shop Area',
                      value: locationDescription,
                      iconColor: darkGreen,
                    ),

                    if (ownerName.isNotEmpty) ...[

                      const SizedBox(height: 11),

                      _infoCard(
                        icon: Icons.person_outline,
                        title: 'Shop Owner',
                        value: ownerName,
                      ),
                    ],

                    const SizedBox(height: 11),

                    _openingHoursCard(),

                    const SizedBox(height: 22),

                    _aboutSection(),

                    const SizedBox(height: 22),

                    Center(
                      child: Text(
                        'Contact the medical shop using the Call button',

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
