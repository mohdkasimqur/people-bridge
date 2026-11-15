// import 'dart:math' as math;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:hive/hive.dart';
// import 'package:jober_india/jober_indiaScreens.dart/spareparts/screen_spare_parts_profile.dart';

// class ScreenAutoSparePartsShopList extends StatefulWidget {
//   final String selectedCategory;

//   const ScreenAutoSparePartsShopList({
//     super.key,
//     required this.selectedCategory,
//   });

//   @override
//   State<ScreenAutoSparePartsShopList> createState() =>
//       _ScreenAutoSparePartsShopListState();
// }

// class _ScreenAutoSparePartsShopListState
//     extends State<ScreenAutoSparePartsShopList> {
//   // ============================================================
//   // COLORS
//   // ============================================================

//   static const Color green =
//      // Color(0xFF198B35);
//       Color(0xFF138808);

//   // static const Color darkGreen =
//   //     Color(0xFF12652F);

//   // ============================================================
//   // FIRESTORE
//   // ============================================================

//   final FirebaseFirestore _firestore =
//       FirebaseFirestore.instance;

//   // ============================================================
//   // LOCATION
//   // ============================================================

//   Position? userPosition;

//   bool loadingLocation = true;

//   String? locationError;

// // ============================================================
// // PAGINATION
// // ============================================================

// static const int pageSize = 20;
// static const double maximumSearchRadius = 50.0;

// int currentPage = 0;

// DocumentSnapshot<Map<String, dynamic>>? lastDocument;

// bool hasMore = true;

// List<Map<String, dynamic>> get paginatedShops {
//   final startIndex = currentPage * pageSize;

//   if (startIndex >= nearbyShops.length) {
//     return [];
//   }

//   final endIndex = math.min(
//     startIndex + pageSize,
//     nearbyShops.length,
//   );

//   return nearbyShops.sublist(startIndex, endIndex);
// }
// // ============================================================
// // SUBSCRIPTION — SAME AS LABORATORY PAGE
// // ============================================================

// double paidRadius = 1.0;
// DateTime? subscriptionExpiry;
// bool subscriptionIsActive = false;
// bool loadingPayment = true;

// double get availableDistance {
//   if (!subscriptionIsActive ||
//       subscriptionExpiry == null ||
//       !DateTime.now().isBefore(subscriptionExpiry!)) {
//     return 1.0;
//   }

//   return paidRadius < 1.0 ? 1.0 : paidRadius;
// }

// bool canOpenShop(double distance) {
//   return distance <= availableDistance;
// }

//   // ============================================================
//   // SHOP DATA
//   // ============================================================

//   List<Map<String, dynamic>> allShops = [];

//   List<Map<String, dynamic>> nearbyShops = [];

//   bool loadingShops = true;

//   String? shopsError;

//   // ============================================================
//   // SEARCH RADIUS
//   // ============================================================

//   double selectedRadius = 10;

//   final List<double> radiusOptions = [
//     5,
//     10,
//     20,
//     30,
//     50,
//   ];

//   // ============================================================
//   // INIT
//   // ============================================================

//   @override
//   void initState() {
//     super.initState();

//     _initializePage();
//   }

// // ============================================================
// // LOAD SUBSCRIPTION
// // ============================================================
// Future<void> loadPaymentData() async {
//   try {
//     if (!Hive.isBoxOpen('settings')) {
//       await Hive.openBox('settings');
//     }

//     final box = Hive.box('settings');

//     final savedDistance = box.get('activeDistance');
//     final savedExpiry = box.get('subscriptionExpiry');

//     DateTime? expiry;

//     if (savedExpiry is DateTime) {
//       expiry = savedExpiry;
//     } else if (savedExpiry != null) {
//       expiry = DateTime.tryParse(savedExpiry.toString());
//     }

//     final validSubscription =
//         expiry != null &&
//         savedDistance is num &&
//         DateTime.now().isBefore(expiry);

//     if (validSubscription) {
//       paidRadius = savedDistance.toDouble();
//       subscriptionExpiry = expiry;
//       subscriptionIsActive = true;
//     } else {
//       paidRadius = 1.0;
//       subscriptionExpiry = null;
//       subscriptionIsActive = false;

//       // Clear expired subscription information.
//       if (expiry != null &&
//           !DateTime.now().isBefore(expiry)) {
//         await box.delete('activeDistance');
//         await box.delete('subscriptionStart');
//         await box.delete('subscriptionExpiry');
//         await box.delete('subscriptionDuration');
//         await box.delete('subscriptionPaidAmount');
//         await box.delete('subscriptionActive');
//       }
//     }
//   } catch (e) {
//     debugPrint('Spare parts subscription loading error: $e');

//     paidRadius = 1.0;
//     subscriptionExpiry = null;
//     subscriptionIsActive = false;
//   }

//   if (mounted) {
//     setState(() {
//       loadingPayment = false;
//     });
//   }
// }

// bool _isInsidePaidRadius(double distance) {
//   // First 1 km is always free.
//   if (distance <= 1.0) {
//     return true;
//   }

//   // Beyond 1 km requires an active subscription.
//   if (!subscriptionIsActive ||
//       subscriptionExpiry == null ||
//       !DateTime.now().isBefore(subscriptionExpiry!)) {
//     return false;
//   }

//   return distance <= paidRadius;
// }

// Future<void> expireSubscription() async {
//   final box = Hive.box('settings');

//   await box.delete('activeDistance');
//   await box.delete('subscriptionStart');
//   await box.delete('subscriptionExpiry');
//   await box.delete('subscriptionDuration');
//   await box.delete('subscriptionPaidAmount');
//   await box.delete('subscriptionActive');

//   paidRadius = 1.0;
//   subscriptionExpiry = null;
//   subscriptionIsActive = false;
// }

// // ============================================================
// // NEXT PAGE
// // ============================================================

// void _nextPage() {
//   if ((currentPage + 1) * pageSize >= nearbyShops.length) {
//     return;
//   }

//   setState(() {
//     currentPage++;
//   });
// }

// // ============================================================
// // PREVIOUS PAGE
// // ============================================================

// void _previousPage() {
//   if (currentPage <= 0) return;

//   setState(() {
//     currentPage--;
//   });
// }

// Future<void> _refresh() async {
//   await loadPaymentData();

//   if (!mounted) return;

//   await _getUserLocation();

//   if (!mounted || userPosition == null) return;

//   await _loadShops(reset: true);
// }
//   // ============================================================
//   // INITIALIZE
//   // ============================================================
// Future<void> _initializePage() async {
//   await loadPaymentData();

//   if (!mounted) return;

//   await _getUserLocation();

//   if (!mounted || userPosition == null) return;

//   await _loadShops(reset: true);
// }

//   // ============================================================
//   // GET USER LOCATION
//   // ============================================================

//   Future<void> _getUserLocation() async {
//     if (!mounted) return;

//     setState(() {
//       loadingLocation = true;
//       locationError = null;
//     });

//     try {
//       final bool serviceEnabled =
//           await Geolocator.isLocationServiceEnabled();

//       if (!serviceEnabled) {
//         if (!mounted) return;

//         setState(() {
//           loadingLocation = false;

//           locationError =
//               'Location service is turned off.';
//         });

//         return;
//       }

//       LocationPermission permission =
//           await Geolocator.checkPermission();

//       if (permission ==
//           LocationPermission.denied) {
//         permission =
//             await Geolocator.requestPermission();
//       }

//       if (permission ==
//           LocationPermission.denied) {
//         if (!mounted) return;

//         setState(() {
//           loadingLocation = false;

//           locationError =
//               'Location permission was denied.';
//         });

//         return;
//       }

//       if (permission ==
//           LocationPermission.deniedForever) {
//         if (!mounted) return;

//         setState(() {
//           loadingLocation = false;

//           locationError =
//               'Location permission is permanently denied.';
//         });

//         return;
//       }

//       final Position position =
//           await Geolocator.getCurrentPosition(
//         locationSettings:
//             const LocationSettings(
//           accuracy:
//               LocationAccuracy.high,
//         ),
//       );

//       if (!mounted) return;

//       setState(() {
//         userPosition = position;

//         loadingLocation = false;
//       });
//     } catch (_) {
//       if (!mounted) return;

//       setState(() {
//         loadingLocation = false;

//         locationError =
//             'Unable to get your current location.';
//       });
//     }
//   }

// // ============================================================
// // LOAD SHOPS FROM FIRESTORE
// // ============================================================
// Future<void> _loadShops({
//   required bool reset,
// }) async {
//   bool fetchingShops = false;
//   if (userPosition == null) return;

//   if (!reset || loadingShops == false) {
//     // A fresh search is allowed when reset is true.
//   }
//   if (userPosition == null || fetchingShops) return;

// fetchingShops = true;

//   if (reset) {
//     if (loadingShops && allShops.isNotEmpty) return;

//     setState(() {
//       loadingShops = true;
//       shopsError = null;

//       allShops.clear();
//       nearbyShops.clear();

//       lastDocument = null;
//       hasMore = true;
//       currentPage = 0;
//     });
//   }

//   try {
//     final List<Map<String, dynamic>> results = [];

//     // Fetch all matching records in Firestore cursor batches.
//     while (hasMore) {
//       Query<Map<String, dynamic>> query = _firestore
//           .collection('auto_spare_parts_shops')
//           .where('active', isEqualTo: true);

//       if (widget.selectedCategory != 'All Auto Spare Parts') {
//         query = query.where(
//           'categories',
//           arrayContains: widget.selectedCategory,
//         );
//       }

//       query = query.limit(pageSize);

//       if (lastDocument != null) {
//         query = query.startAfterDocument(lastDocument!);
//       }

//       final snapshot = await query.get();

//       if (snapshot.docs.isEmpty) {
//         hasMore = false;
//         break;
//       }

//       lastDocument = snapshot.docs.last;

//       if (snapshot.docs.length < pageSize) {
//         hasMore = false;
//       }

//       for (final document in snapshot.docs) {
//         final data = document.data();

//         double? latitude;
//         double? longitude;

//         // Read the registered GeoPoint first.
//         final location = data['location'];

//         if (location is GeoPoint) {
//           latitude = location.latitude;
//           longitude = location.longitude;
//         }

//         // Fallback to separate coordinate fields.
//         latitude ??= _toDouble(data['latitude']);
//         longitude ??= _toDouble(data['longitude']);

//         if (latitude == null || longitude == null) {
//           continue;
//         }

//         // Validate coordinates.
//         if (latitude < -90 ||
//             latitude > 90 ||
//             longitude < -180 ||
//             longitude > 180) {
//           continue;
//         }

//         final distanceInMeters = Geolocator.distanceBetween(
//           userPosition!.latitude,
//           userPosition!.longitude,
//           latitude,
//           longitude,
//         );

//         final distanceInKm = distanceInMeters / 1000;

//         // Only discover shops within 50 km.
//         if (distanceInKm > maximumSearchRadius) {
//           continue;
//         }

//         final shop = Map<String, dynamic>.from(data);

//         shop['documentId'] = document.id;
//         shop['uid'] = data['uid']?.toString() ?? document.id;
//         shop['latitude'] = latitude;
//         shop['longitude'] = longitude;
//         shop['distance'] = distanceInKm;

//         results.add(shop);
//       }
//     }

//     // Sort the COMPLETE discovered result set.
//     results.sort((a, b) {
//       final distanceA = _toDouble(a['distance']) ?? 999999;
//       final distanceB = _toDouble(b['distance']) ?? 999999;

//       return distanceA.compareTo(distanceB);
//     });

//     if (!mounted) return;

//     setState(() {
//       allShops = results;
//       currentPage = 0;
//     });

//     _filterByRadius();

//     if (!mounted) return;

//     setState(() {
//       loadingShops = false;
//     });
//   } catch (e) {
//     debugPrint('Auto spare parts loading error: $e');

//     if (!mounted) return;

//     setState(() {
//       loadingShops = false;
//       shopsError = 'Unable to load nearby spare parts shops.';
//     });
//   }
// }

//   // ============================================================
//   // CONVERT VALUE TO DOUBLE
//   // ============================================================

//   double? _toDouble(
//     dynamic value,
//   ) {
//     if (value == null) {
//       return null;
//     }

//     if (value is double) {
//       return value;
//     }

//     if (value is int) {
//       return value.toDouble();
//     }

//     return double.tryParse(
//       value.toString(),
//     );
//   }
//   // ============================================================
//   // FILTER SHOPS BY RADIUS
//   // ============================================================
// void _filterByRadius() {
//   final filtered = allShops.where((shop) {
//     final distance = _toDouble(shop['distance']) ?? 0;
//     return distance <= selectedRadius;
//   }).toList();

//   if (!mounted) return;

//   setState(() {
//     nearbyShops = filtered;
//     currentPage = 0;
//   });
// }

//   // ============================================================
//   // CHANGE SEARCH RADIUS
//   // ============================================================

//   void _changeRadius(
//     double radius,
//   ) {
//     setState(() {
//       selectedRadius = radius;
//     });

//     _filterByRadius();
//   }

//   // ============================================================
//   // SHOW RADIUS DIALOG
//   // ============================================================

//   Future<void> _showRadiusDialog() async {
//     double temporaryRadius =
//         selectedRadius;

//     await showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder:
//               (
//             context,
//             setDialogState,
//           ) {
//             return AlertDialog(
//               shape:
//                   RoundedRectangleBorder(
//                 borderRadius:
//                     BorderRadius.circular(
//                   20,
//                 ),
//               ),

//               title: const Row(
//                 children: [
//                   Icon(
//                     Icons
//                         .location_searching_rounded,
//                     color: green,
//                   ),

//                   SizedBox(
//                     width: 10,
//                   ),

//                   Text(
//                     'Search Radius',
//                   ),
//                 ],
//               ),

//               content: SizedBox(
//                 width:
//                     double.maxFinite,

//                 child: Column(
//                   mainAxisSize:
//                       MainAxisSize.min,

//                   children: [
//                     Text(
//                       'Find shops within ${temporaryRadius.toStringAsFixed(0)} km',

//                       style:
//                           const TextStyle(
//                         fontSize: 16,

//                         fontWeight:
//                             FontWeight
//                                 .w600,
//                       ),
//                     ),

//                     const SizedBox(
//                       height: 20,
//                     ),

//                     Wrap(
//                       spacing: 10,
//                       runSpacing: 10,

//                       children:
//                           radiusOptions.map(
//                         (radius) {
//                           final bool selected =
//                               temporaryRadius ==
//                                   radius;

//                           return ChoiceChip(
//                             label: Text(
//                               '${radius.toStringAsFixed(0)} km',
//                             ),

//                             selected:
//                                 selected,

//                             selectedColor:
//                                 green
//                                     .withValues(alpha: 
//                               0.20,
//                             ),

//                             labelStyle:
//                                 TextStyle(
//                               color:
//                                   selected
//                                       ? green
//                                       : Colors
//                                           .black87,

//                               fontWeight:
//                                   selected
//                                       ? FontWeight
//                                           .w700
//                                       : FontWeight
//                                           .w500,
//                             ),

//                             onSelected:
//                                 (_) {
//                               setDialogState(
//                                 () {
//                                   temporaryRadius =
//                                       radius;
//                                 },
//                               );
//                             },
//                           );
//                         },
//                       ).toList(),
//                     ),
//                   ],
//                 ),
//               ),

//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(
//                       dialogContext,
//                     );
//                   },

//                   child:
//                       const Text(
//                     'Cancel',
//                   ),
//                 ),

//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(
//                       dialogContext,
//                     );

//                     _changeRadius(
//                       temporaryRadius,
//                     );
//                   },

//                   style:
//                       ElevatedButton.styleFrom(
//                     backgroundColor:
//                         green,

//                     foregroundColor:
//                         Colors.white,
//                   ),

//                   child:
//                       const Text(
//                     'Apply',
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   // ============================================================
//   // SHOW INCREASE RADIUS DIALOG
//   // ============================================================

//   void _showIncreaseRadiusDialog() {
//     double? nextRadius;

//     for (final double radius
//         in radiusOptions) {
//       if (radius >
//           selectedRadius) {
//         nextRadius = radius;
//         break;
//       }
//     }

//     if (nextRadius == null) {
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           shape:
//               RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(
//               20,
//             ),
//           ),

//           title: const Row(
//             children: [
//               Icon(
//                 Icons
//                     .location_searching_rounded,
//                 color: green,
//               ),

//               SizedBox(
//                 width: 10,
//               ),

//               Expanded(
//                 child: Text(
//                   'No Shops Nearby',
//                 ),
//               ),
//             ],
//           ),

//           content: Text(
//             allShops.isEmpty
//                 ? 'No shops are available in this category.'
// : 'No shops were found within ${selectedRadius.toStringAsFixed(0)} km. Would you like to increase your search radius to ${(nextRadius ?? selectedRadius).toStringAsFixed(0)} km?',          ),

//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(
//                   dialogContext,
//                 );
//               },

//               child:
//                   const Text(
//                 'Cancel',
//               ),
//             ),

//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(
//                   dialogContext,
//                 );

//                 _changeRadius(
//                   nextRadius!,
//                 );
//               },

//               style:
//                   ElevatedButton.styleFrom(
//                 backgroundColor:
//                     green,

//                 foregroundColor:
//                     Colors.white,
//               ),

//               child:
//                   const Text(
//                 'Increase',
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // ============================================================
//   // OPEN SHOP PROFILE
//   // ============================================================

// Future<void> _openShopProfile(
//   Map<String, dynamic> shop,
// ) async {
//   final distance = _toDouble(shop['distance']);

//   if (distance == null || userPosition == null) {
//     return;
//   }

//   // Read the latest subscription purchased from Home page.
//   await loadPaymentData();

//   if (!mounted) return;

//   if (_isInsidePaidRadius(distance)) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ScreenAutoSparePartsShopProfile(
//           shop: shop,
//           userLatitude: userPosition!.latitude,
//           userLongitude: userPosition!.longitude,
//         ),
//       ),
//     );

//     return;
//   }

//   _showSubscriptionPopup(distance);
// }
// // SUBSCRIPTION REQUIRED — SAME ACCESS LOGIC AS LABORATORY
// // ============================================================

// void _showSubscriptionPopup(double distance) {
//   showDialog(
//     context: context,
//     builder: (dialogContext) => AlertDialog(
//       title: const Text('Subscription Required'),
//       content: Text(
//         'This shop is ${distance.toStringAsFixed(1)} KM away.\n\n'
//         'Your free access is 1 KM. '
//         'Your current subscription allows access up to '
//         '${availableDistance.toStringAsFixed(0)} KM.\n\n'
//         'Please purchase or update your distance subscription '
//         'from the Home page to access this shop.',
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             Navigator.pop(dialogContext);
//           },
//           child: const Text('OK'),
//         ),
//       ],
//     ),
//   );
// }

//   // ============================================================
//   // SHOP CARD
//   // ============================================================

// Widget _buildShopCard(
//   Map<String, dynamic> shop,
// ) {
//   final String shopName =
//       (shop['shopName'] ?? 'Auto Spare Parts Shop').toString();

//   final String category =
//       (shop['categories'] is List &&
//               (shop['categories'] as List).isNotEmpty)
//           ? (shop['categories'] as List).join(', ')
//           : (shop['category'] ?? '').toString();

//   final String experience =
//       (shop['experience'] ?? '').toString();

//   // Calculate distance first.
//   final double distance =
//       _toDouble(shop['distance']) ?? 0;

//   // Then check subscription access.
//   final bool profileUnlocked =
//     _isInsidePaidRadius(distance);

//   return InkWell(
//     borderRadius: BorderRadius.circular(20),
//     onTap: () {
//       _openShopProfile(shop);
//     },
//     child: Container(
//       width: double.infinity,
//       margin: const EdgeInsets.only(bottom: 14),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 62,
//             height: 62,
//             decoration: BoxDecoration(
//               color: green.withValues(alpha: 0.10),
//               borderRadius: BorderRadius.circular(18),
//             ),
//             child: const Icon(
//               Icons.storefront_rounded,
//               color: green,
//               size: 32,
//             ),
//           ),

//           const SizedBox(width: 14),

//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   shopName,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),

//                 const SizedBox(height: 5),

//                 Text(
//                   category,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: Colors.grey.shade700,
//                     fontSize: 13,
//                   ),
//                 ),

//                 if (experience.isNotEmpty) ...[
//                   const SizedBox(height: 4),
//                   Text(
//                     experience,
//                     style: TextStyle(
//                       color: Colors.grey.shade500,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],

//                 const SizedBox(height: 8),

//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.location_on_rounded,
//                       size: 17,
//                       color: green,
//                     ),
//                     const SizedBox(width: 4),
//                     Expanded(
//                       child: Text(
//                         '${distance.toStringAsFixed(1)} km from your location',
//                         style: const TextStyle(
//                           color: green,
//                           fontSize: 13,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 5),

//                 Row(
//                   children: [
//                     Icon(
//                       profileUnlocked
//                           ? Icons.lock_open_rounded
//                           : Icons.lock_outline_rounded,
//                       size: 15,
//                       color: profileUnlocked
//                           ? green
//                           : Colors.orange.shade800,
//                     ),
//                     const SizedBox(width: 5),
//                     Expanded(
//                       child: Text(
//                         profileUnlocked
//                             ? 'Profile access available'
//                             : 'Unlock ${distance.ceil()} KM to open profile',
//                         style: TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                           color: profileUnlocked
//                               ? green
//                               : Colors.orange.shade800,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(width: 8),

//           const Icon(
//             Icons.arrow_forward_ios_rounded,
//             size: 18,
//             color: green,
//           ),
//         ],
//       ),
//     ),
//   );
// }

//   // ============================================================
//   // RADIUS HEADER
//   // ============================================================

//   Widget _buildRadiusHeader() {
//     return Container(
//       width:
//           double.infinity,

//       padding:
//           const EdgeInsets.all(
//         14,
//       ),

//       decoration:
//           BoxDecoration(
//         color:
//             green.withValues(alpha: 
//           0.08,
//         ),

//         borderRadius:
//             BorderRadius.circular(
//           16,
//         ),
//       ),

//       child: Row(
//         children: [
//           Container(
//             width: 46,
//             height: 46,

//             decoration:
//                 BoxDecoration(
//               color:
//                   Colors.white,

//               borderRadius:
//                   BorderRadius.circular(
//                 14,
//               ),
//             ),

//             child:
//                 const Icon(
//               Icons
//                   .location_searching_rounded,

//               color:
//                   green,
//             ),
//           ),

//           const SizedBox(
//             width: 12,
//           ),

//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment
//                       .start,

//               children: [
//                 const Text(
//                   'Search Radius',

//                   style:
//                       TextStyle(
//                     fontWeight:
//                         FontWeight.w700,
//                   ),
//                 ),

//                 const SizedBox(
//                   height: 3,
//                 ),

//                 Text(
//                   'Showing shops within ${selectedRadius.toStringAsFixed(0)} km',

//                   style:
//                       TextStyle(
//                     color:
//                         Colors.grey.shade700,

//                     fontSize:
//                         12,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           TextButton(
//             onPressed:
//                 _showRadiusDialog,

//             child:
//                 const Text(
//               'Change',
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   // ============================================================
//   // RETRY
//   // ============================================================

//   Future<void> _retry() async {
//     await _initializePage();
//   }

//   // ============================================================
//   // BUILD LOADING
//   // ============================================================

//   Widget _buildLoadingScreen(
//     String message,
//   ) {
//     return Center(
//       child: Column(
//         mainAxisSize:
//             MainAxisSize.min,

//         children: [
//           const CircularProgressIndicator(
//             color: green,
//           ),

//           const SizedBox(
//             height: 18,
//           ),

//           Text(
//             message,

//             style:
//                 TextStyle(
//               color:
//                   Colors.grey.shade700,

//               fontWeight:
//                   FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD ERROR
//   // ============================================================

//   Widget _buildErrorScreen(
//     String message,
//   ) {
//     return Center(
//       child: Padding(
//         padding:
//             const EdgeInsets.all(
//           25,
//         ),

//         child: Column(
//           mainAxisSize:
//               MainAxisSize.min,

//           children: [
//             Icon(
//               Icons.location_off_rounded,

//               size: 65,

//               color:
//                   Colors.grey.shade400,
//             ),

//             const SizedBox(
//               height: 18,
//             ),

//             Text(
//               message,

//               textAlign:
//                   TextAlign.center,

//               style:
//                   TextStyle(
//                 fontSize:
//                     15,

//                 color:
//                     Colors.grey.shade700,
//               ),
//             ),

//             const SizedBox(
//               height: 22,
//             ),

//             ElevatedButton.icon(
//               onPressed:
//                   _retry,

//               style:
//                   ElevatedButton.styleFrom(
//                 backgroundColor:
//                     green,

//                 foregroundColor:
//                     Colors.white,

//                 shape:
//                     RoundedRectangleBorder(
//                   borderRadius:
//                       BorderRadius.circular(
//                     12,
//                   ),
//                 ),
//               ),

//               icon:
//                   const Icon(
//                 Icons.refresh_rounded,
//               ),

//               label:
//                   const Text(
//                 'Try Again',
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // NO SHOPS
//   // ============================================================

//   Widget _buildNoShops() {
//     final bool hasMoreRadius =
//         radiusOptions.any(
//       (radius) =>
//           radius > selectedRadius,
//     );

//     return Center(
//       child: Padding(
//         padding:
//             const EdgeInsets.all(
//           25,
//         ),

//         child: Column(
//           mainAxisSize:
//               MainAxisSize.min,

//           children: [
//             Container(
//               width: 90,
//               height: 90,

//               decoration:
//                   BoxDecoration(
//                 color:
//                     green.withValues(alpha: 
//                   0.08,
//                 ),

//                 shape:
//                     BoxShape.circle,
//               ),

//               child:
//                   const Icon(
//                 Icons
//                     .storefront_outlined,

//                 size: 48,

//                 color:
//                     green,
//               ),
//             ),

//             const SizedBox(
//               height: 20,
//             ),

//             Text(
//               allShops.isEmpty
//                   ? 'No Shops Found'
//                   : 'No Shops Within ${selectedRadius.toStringAsFixed(0)} km',

//               textAlign:
//                   TextAlign.center,

//               style:
//                   const TextStyle(
//                 fontSize: 19,

//                 fontWeight:
//                     FontWeight.w800,
//               ),
//             ),

//             const SizedBox(
//               height: 10,
//             ),

//             Text(
//               allShops.isEmpty
//                   ? 'There are currently no shops available in this category.'
//                   : 'There are shops farther away. Increase your search radius to find more shops.',

//               textAlign:
//                   TextAlign.center,

//               style:
//                   TextStyle(
//                 color:
//                     Colors.grey.shade600,

//                 fontSize:
//                     14,
//               ),
//             ),

//             const SizedBox(
//               height: 22,
//             ),

//             if (allShops.isNotEmpty &&
//                 hasMoreRadius)
//               ElevatedButton.icon(
//                 onPressed:
//                     _showIncreaseRadiusDialog,

//                 style:
//                     ElevatedButton.styleFrom(
//                   backgroundColor:
//                       green,

//                   foregroundColor:
//                       Colors.white,

//                   padding:
//                       const EdgeInsets.symmetric(
//                     horizontal:
//                         22,

//                     vertical:
//                         14,
//                   ),

//                   shape:
//                       RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius.circular(
//                       14,
//                     ),
//                   ),
//                 ),

//                 icon:
//                     const Icon(
//                   Icons
//                       .add_location_alt_rounded,
//                 ),

//                 label:
//                     const Text(
//                   'Increase Search Radius',
//                   style:
//                       TextStyle(
//                     fontWeight:
//                         FontWeight.w700,
//                   ),
//                 ),
//               ),

//             if (allShops.isNotEmpty &&
//                 !hasMoreRadius)
//               OutlinedButton(
//                 onPressed:
//                     _showRadiusDialog,

//                 child:
//                     const Text(
//                   'Change Radius',
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD SHOP LIST
//   // ============================================================

//   Widget _buildShopList() {
//     if (nearbyShops.isEmpty) {
//       return _buildNoShops();
//     }

//     return RefreshIndicator(
//       color: green,

//       onRefresh:
//           _refresh,

//       child: ListView(
//         padding:
//             const EdgeInsets.fromLTRB(
//           18,
//           14,
//           18,
//           30,
//         ),

//         children: [
//           // ==================================================
//           // RADIUS
//           // ==================================================

//           _buildRadiusHeader(),

//           const SizedBox(
//             height: 18,
//           ),

//           // ==================================================
//           // RESULT TITLE
//           // ==================================================

//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   '${nearbyShops.length} Nearby Shop${nearbyShops.length == 1 ? '' : 's'}',

//                   style:
//                       const TextStyle(
//                     fontSize: 18,

//                     fontWeight:
//                         FontWeight.w800,
//                   ),
//                 ),
//               ),

//               const Icon(
//                 Icons
//                     .sort_rounded,

//                 color:
//                     green,

//                 size:
//                     20,
//               ),

//               const SizedBox(
//                 width:
//                     5,
//               ),

//               const Text(
//                 'Nearest',

//                 style:
//                     TextStyle(
//                   color:
//                       green,

//                   fontSize:
//                       13,

//                   fontWeight:
//                       FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(
//             height: 5,
//           ),

//           Text(
//             'Shops are arranged from nearest to farthest.',

//             style:
//                 TextStyle(
//               color:
//                   Colors.grey.shade600,

//               fontSize:
//                   12,
//             ),
//           ),

//           const SizedBox(
//             height: 16,
//           ),

//           // ==================================================
// // PAGINATED SHOPS
// // ==================================================

// ...paginatedShops.map(
//   (shop) => _buildShopCard(shop),
// ),

// // ==================================================
// // PAGINATION CONTROLS
// // ==================================================

// if (nearbyShops.length > pageSize) ...[
//   const SizedBox(height: 12),

//   Row(
//     mainAxisAlignment: MainAxisAlignment.center,
//     children: [
//       IconButton(
//         onPressed: currentPage > 0
//             ? _previousPage
//             : null,
//         icon: const Icon(Icons.arrow_back_ios_rounded),
//       ),

//       Text(
//         'Page ${currentPage + 1} of '
//         '${(nearbyShops.length / pageSize).ceil()}',
//         style: const TextStyle(
//           fontWeight: FontWeight.w700,
//         ),
//       ),

//       IconButton(
//         onPressed:
//             (currentPage + 1) * pageSize < nearbyShops.length
//                 ? _nextPage
//                 : null,
//         icon: const Icon(Icons.arrow_forward_ios_rounded),
//       ),
//     ],
//   ),
// ],
//         ],
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
//           Colors.grey.shade50,

//       appBar: AppBar(
//         backgroundColor:
//             Colors.white,

//         foregroundColor:
//             Colors.black,

//         elevation:
//             0,

//         centerTitle:
//             true,

//         title:
//             Column(
//           children: [
//             const Text(
//               'Nearby Spare Parts Shops',

//               style:
//                   TextStyle(
//                 fontSize:
//                     16,

//                 fontWeight:
//                     FontWeight.w700,
//               ),
//             ),

//             Text(
//               widget.selectedCategory,

//               maxLines:
//                   1,

//               overflow:
//                   TextOverflow.ellipsis,

//               style:
//                   TextStyle(
//                 fontSize:
//                     11,

//                 color:
//                     Colors.grey.shade600,

//                 fontWeight:
//                     FontWeight.w400,
//               ),
//             ),
//           ],
//         ),
//       ),

//       body: loadingPayment
//     ? _buildLoadingScreen('Checking your subscription...')
//     : loadingLocation
//         ? _buildLoadingScreen('Getting your location...')
//         : locationError != null
//             ? _buildErrorScreen(locationError!)
//             : loadingShops
//                 ? _buildLoadingScreen('Finding nearby shops...')
//                 : shopsError != null
//                     ? _buildErrorScreen(shopsError!)
//                     : _buildShopList(),
//     );
//   }
// }

// import 'dart:math' as math;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:hive/hive.dart';
// import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
// import 'package:jober_india/jober_indiaScreens.dart/spareparts/screen_spare_parts_profile.dart';

// class ScreenAutoSparePartsShopList extends StatefulWidget {
//   final String selectedCategory;

//   const ScreenAutoSparePartsShopList({
//     super.key,
//     required this.selectedCategory,
//   });

//   @override
//   State<ScreenAutoSparePartsShopList> createState() =>
//       _ScreenAutoSparePartsShopListState();
// }

// class _ScreenAutoSparePartsShopListState
//     extends State<ScreenAutoSparePartsShopList> {
//   // ============================================================
//   // COLORS
//   // ============================================================

//   static const Color green = Color(0xFF138808);

//   // ============================================================
//   // FIRESTORE
//   // ============================================================

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // ============================================================
//   // LOCATION
//   // ============================================================

//   Position? userPosition;

//   bool loadingLocation = true;
//   String? locationError;

//   // ============================================================
//   // SEARCH SETTINGS
//   // ============================================================

//   static const double maximumSearchRadius = 50.0;
//   static const int pageSize = 20;

//   double selectedRadius = 10;

//   final List<double> radiusOptions = [
//     5,
//     10,
//     20,
//     30,
//     50,
//   ];

//   // ============================================================
//   // PAGINATION
//   // ============================================================

//   int currentPage = 0;

//   List<Map<String, dynamic>> get paginatedShops {
//     final startIndex = currentPage * pageSize;

//     if (startIndex >= nearbyShops.length) {
//       return [];
//     }

//     final endIndex = math.min(
//       startIndex + pageSize,
//       nearbyShops.length,
//     );

//     return nearbyShops.sublist(startIndex, endIndex);
//   }

//   void _nextPage() {
//     if ((currentPage + 1) * pageSize >= nearbyShops.length) {
//       return;
//     }

//     setState(() {
//       currentPage++;
//     });
//   }

//   void _previousPage() {
//     if (currentPage <= 0) return;

//     setState(() {
//       currentPage--;
//     });
//   }

//   // ============================================================
//   // SUBSCRIPTION
//   // ============================================================

//   double paidRadius = 1.0;

//   DateTime? subscriptionExpiry;

//   bool subscriptionIsActive = false;
//   bool loadingPayment = true;

//   double get availableDistance {
//     if (!subscriptionIsActive ||
//         subscriptionExpiry == null ||
//         !DateTime.now().isBefore(subscriptionExpiry!)) {
//       return 1.0;
//     }

//     return paidRadius < 1.0 ? 1.0 : paidRadius;
//   }

//   bool canOpenShop(double distance) {
//     return distance <= availableDistance;
//   }

//   // ============================================================
//   // SHOP DATA
//   // ============================================================

//   List<Map<String, dynamic>> allShops = [];
//   List<Map<String, dynamic>> nearbyShops = [];

//   bool loadingShops = true;
//   bool fetchingShops = false;

//   String? shopsError;

//   // ============================================================
//   // INIT
//   // ============================================================

//   @override
//   void initState() {
//     super.initState();
//     _initializePage();
//   }

//   // ============================================================
//   // LOAD SUBSCRIPTION
//   // ============================================================

//   Future<void> loadPaymentData() async {
//     try {
//       if (!Hive.isBoxOpen('settings')) {
//         await Hive.openBox('settings');
//       }

//       final box = Hive.box('settings');

//       final savedDistance = box.get('activeDistance');
//       final savedExpiry = box.get('subscriptionExpiry');

//       DateTime? expiry;

//       if (savedExpiry is DateTime) {
//         expiry = savedExpiry;
//       } else if (savedExpiry != null) {
//         expiry = DateTime.tryParse(savedExpiry.toString());
//       }

//       final validSubscription = expiry != null &&
//           savedDistance is num &&
//           savedDistance >= 1 &&
//           DateTime.now().isBefore(expiry);

//       if (validSubscription) {
//         paidRadius = savedDistance.toDouble();
//         subscriptionExpiry = expiry;
//         subscriptionIsActive = true;
//       } else {
//         paidRadius = 1.0;
//         subscriptionExpiry = null;
//         subscriptionIsActive = false;

//         if (expiry != null && !DateTime.now().isBefore(expiry)) {
//           await box.delete('activeDistance');
//           await box.delete('subscriptionStart');
//           await box.delete('subscriptionExpiry');
//           await box.delete('subscriptionDuration');
//           await box.delete('subscriptionPaidAmount');
//           await box.delete('subscriptionActive');
//         }
//       }
//     } catch (e) {
//       debugPrint('Spare parts subscription loading error: $e');

//       paidRadius = 1.0;
//       subscriptionExpiry = null;
//       subscriptionIsActive = false;
//     }

//     if (mounted) {
//       setState(() {
//         loadingPayment = false;
//       });
//     }
//   }

//   bool _isInsidePaidRadius(double distance) {
//     // First 1 km is permanently free.
//     if (distance <= 1.0) {
//       return true;
//     }

//     // Beyond 1 km requires an active subscription.
//     if (!subscriptionIsActive ||
//         subscriptionExpiry == null ||
//         !DateTime.now().isBefore(subscriptionExpiry!)) {
//       return false;
//     }

//     return distance <= paidRadius;
//   }

//   // ============================================================
//   // INITIALIZE
//   // ============================================================

//   Future<void> _initializePage() async {
//     await loadPaymentData();

//     if (!mounted) return;

//     await _getUserLocation();

//     if (!mounted || userPosition == null) return;

//     await _loadShops(reset: true);
//   }

//   // ============================================================
//   // GET USER LOCATION
//   // ============================================================

//   Future<void> _getUserLocation() async {
//     if (!mounted) return;

//     setState(() {
//       loadingLocation = true;
//       locationError = null;
//     });

//     try {
//       final serviceEnabled =
//           await Geolocator.isLocationServiceEnabled();

//       if (!serviceEnabled) {
//         if (!mounted) return;

//         setState(() {
//           loadingLocation = false;
//           locationError = 'Location service is turned off.';
//         });

//         return;
//       }

//       LocationPermission permission =
//           await Geolocator.checkPermission();

//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }

//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         if (!mounted) return;

//         setState(() {
//           loadingLocation = false;
//           locationError = permission == LocationPermission.deniedForever
//               ? 'Location permission is permanently denied.'
//               : 'Location permission was denied.';
//         });

//         return;
//       }

//       final position = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high,
//         ),
//       );

//       if (!mounted) return;

//       setState(() {
//         userPosition = position;
//         loadingLocation = false;
//       });
//     } catch (e) {
//       debugPrint('Location error: $e');

//       if (!mounted) return;

//       setState(() {
//         loadingLocation = false;
//         locationError = 'Unable to get your current location.';
//       });
//     }
//   }

//   // ============================================================
//   // LOAD SHOPS USING GEOHASH
//   // ============================================================

//   Future<void> _loadShops({
//     required bool reset,
//   }) async {
//     if (userPosition == null || fetchingShops) return;

//     fetchingShops = true;

//     if (reset) {
//       setState(() {
//         loadingShops = true;
//         shopsError = null;
//         allShops.clear();
//         nearbyShops.clear();
//         currentPage = 0;
//       });
//     }

//     try {
//       final center = GeoFirePoint(
//         GeoPoint(
//           userPosition!.latitude,
//           userPosition!.longitude,
//         ),
//       );

//       final collection = _firestore.collection(
//         'auto_spare_parts_shops',
//       );

//       // Fetch only shops whose geohash is within 50 km.
//       // Active and category conditions are applied in Firestore.
//       final geoCollection =
//           GeoCollectionReference<Map<String, dynamic>>(
//         collection,
//       );

//       final documents = await geoCollection.fetchWithin(
//   center: center,
//   radiusInKm: maximumSearchRadius,
//   field: 'geo',
//   // geopointFrom: (data) {
//   //   final geoData = data['geo'];

//   //   if (geoData is Map &&
//   //       geoData['geopoint'] is GeoPoint) {
//   //     return geoData['geopoint'] as GeoPoint;
//   //   }

//   //   throw Exception('Invalid shop geo data');
//   // },
//   geopointFrom: (data) {
//   final geoData = data['geo'];

//   if (geoData is Map &&
//       geoData['geopoint'] is GeoPoint) {
//     return geoData['geopoint'] as GeoPoint;
//   }

//   // Support older location format.
//   if (data['location'] is GeoPoint) {
//     return data['location'] as GeoPoint;
//   }

//   final lat = _toDouble(data['latitude']);
//   final lng = _toDouble(data['longitude']);

//   if (lat != null &&
//       lng != null &&
//       lat >= -90 &&
//       lat <= 90 &&
//       lng >= -180 &&
//       lng <= 180) {
//     return GeoPoint(lat, lng);
//   }

//   // Invalid coordinates will be excluded by the
//   // distance validation later.
//   return const GeoPoint(0, 0);
// },
//   strictMode: true,
// );

//       final List<Map<String, dynamic>> results = [];

//       for (final document in documents) {
//         final data = document.data();

//         if (data == null) continue;

// // ========================================================
// // CHECK ACTIVE STATUS
// // ========================================================

// final bool hasActiveField =
//     data.containsKey('active') ||
//     data.containsKey('isActive');

// final bool isShopActive =
//     data['active'] == true ||
//     data['isActive'] == true;

// // If either active field is true, allow the shop.
// // If neither field exists, retain legacy compatibility.
// if (hasActiveField && !isShopActive) {
//   continue;
// }

// // Check both categories and customCategories.

// // ========================================================
// // CATEGORY FILTER
// // ========================================================

// if (widget.selectedCategory.trim().toLowerCase() !=
//     'all auto spare parts') {
//   final Set<String> shopCategories = {};

//   void addCategories(dynamic rawCategories) {
//     if (rawCategories is List) {
//       for (final item in rawCategories) {
//         final value = item.toString().trim().toLowerCase();

//         if (value.isNotEmpty) {
//           shopCategories.add(value);
//         }
//       }
//     } else if (rawCategories is String) {
//       for (final item in rawCategories.split(',')) {
//         final value = item.trim().toLowerCase();

//         if (value.isNotEmpty) {
//           shopCategories.add(value);
//         }
//       }
//     }
//   }

//   addCategories(data['categories']);
//   addCategories(data['customCategories']);
//   addCategories(data['category']);

//   final selected =
//       widget.selectedCategory.trim().toLowerCase();

//   if (!shopCategories.contains(selected)) {
//     continue;
//   }
// }

//         double? latitude;
//         double? longitude;

//         // Read the new geo structure first.
//         final geoData = data['geo'];

//         if (geoData is Map &&
//             geoData['geopoint'] is GeoPoint) {
//           final point = geoData['geopoint'] as GeoPoint;

//           latitude = point.latitude;
//           longitude = point.longitude;
//         }

//         // Keep compatibility with the existing coordinate fields.
//         latitude ??= _toDouble(data['latitude']);
//         longitude ??= _toDouble(data['longitude']);

//         if (latitude == null || longitude == null) {
//           continue;
//         }

//         if (latitude < -90 ||
//             latitude > 90 ||
//             longitude < -180 ||
//             longitude > 180) {
//           continue;
//         }

//         final distanceInMeters = Geolocator.distanceBetween(
//           userPosition!.latitude,
//           userPosition!.longitude,
//           latitude,
//           longitude,
//         );

//         final distanceInKm = distanceInMeters / 1000;

//         if (distanceInKm > maximumSearchRadius) {
//           continue;
//         }

//         final shop = Map<String, dynamic>.from(data);

//         shop['documentId'] = document.id;
//         shop['uid'] = data['uid']?.toString() ?? document.id;
//         shop['latitude'] = latitude;
//         shop['longitude'] = longitude;
//         shop['distance'] = distanceInKm;

//         results.add(shop);
//       }

//       // Sort all fetched shops by distance.
//       results.sort((a, b) {
//         final distanceA = _toDouble(a['distance']) ?? 999999;
//         final distanceB = _toDouble(b['distance']) ?? 999999;

//         return distanceA.compareTo(distanceB);
//       });

//       if (!mounted) return;

//       setState(() {
//         allShops = results;
//         currentPage = 0;
//         loadingShops = false;
//       });

//       _filterByRadius();
//     } catch (e) {
//       debugPrint('Auto spare parts loading error: $e');

//       if (!mounted) return;

//       setState(() {
//         loadingShops = false;
//         shopsError = 'Unable to load nearby spare parts shops.';
//       });
//     } finally {
//       fetchingShops = false;
//     }
//   }

//   // ============================================================
//   // CONVERT VALUE TO DOUBLE
//   // ============================================================

//   double? _toDouble(dynamic value) {
//     if (value == null) return null;

//     if (value is num) {
//       return value.toDouble();
//     }

//     return double.tryParse(value.toString());
//   }

//   // ============================================================
//   // FILTER SHOPS BY SELECTED RADIUS
//   // ============================================================

//   void _filterByRadius() {
//     final filtered = allShops.where((shop) {
//       final distance = _toDouble(shop['distance']) ?? 999999;
//       return distance <= selectedRadius;
//     }).toList();

//     if (!mounted) return;

//     setState(() {
//       nearbyShops = filtered;
//       currentPage = 0;
//     });
//   }

//   // ============================================================
//   // CHANGE RADIUS
//   // ============================================================

//   void _changeRadius(double radius) {
//     setState(() {
//       selectedRadius = radius;
//     });

//     _filterByRadius();
//   }

//   // ============================================================
//   // REFRESH
//   // ============================================================

//   Future<void> _refresh() async {
//     await loadPaymentData();

//     if (!mounted) return;

//     await _getUserLocation();

//     if (!mounted || userPosition == null) return;

//     await _loadShops(reset: true);
//   }

//   // ============================================================
//   // RADIUS DIALOG
//   // ============================================================

//   Future<void> _showRadiusDialog() async {
//     double temporaryRadius = selectedRadius;

//     await showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               title: const Row(
//                 children: [
//                   Icon(
//                     Icons.location_searching_rounded,
//                     color: green,
//                   ),
//                   SizedBox(width: 10),
//                   Text('Search Radius'),
//                 ],
//               ),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       'Find shops within '
//                       '${temporaryRadius.toStringAsFixed(0)} km',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Wrap(
//                       spacing: 10,
//                       runSpacing: 10,
//                       children: radiusOptions.map((radius) {
//                         final selected = temporaryRadius == radius;

//                         return ChoiceChip(
//                           label: Text(
//                             '${radius.toStringAsFixed(0)} km',
//                           ),
//                           selected: selected,
//                           selectedColor: green.withValues(alpha: 0.20),
//                           labelStyle: TextStyle(
//                             color: selected ? green : Colors.black87,
//                             fontWeight: selected
//                                 ? FontWeight.w700
//                                 : FontWeight.w500,
//                           ),
//                           onSelected: (_) {
//                             setDialogState(() {
//                               temporaryRadius = radius;
//                             });
//                           },
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(dialogContext);
//                   },
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(dialogContext);
//                     _changeRadius(temporaryRadius);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: green,
//                     foregroundColor: Colors.white,
//                   ),
//                   child: const Text('Apply'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   // ============================================================
//   // INCREASE RADIUS DIALOG
//   // ============================================================

//   void _showIncreaseRadiusDialog() {
//   double? nextRadius;

//   for (final double radius in radiusOptions) {
//     if (radius > selectedRadius) {
//       nextRadius = radius;
//       break;
//     }
//   }

//   if (nextRadius == null) {
//     return;
//   }

//   // Store the non-null value before opening the dialog.
//   final double radiusToShow = nextRadius;

//   showDialog(
//     context: context,
//     builder: (dialogContext) {
//       return AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),

//         title: const Row(
//           children: [
//             Icon(
//               Icons.location_searching_rounded,
//               color: green,
//             ),
//             SizedBox(width: 10),
//             Expanded(
//               child: Text('No Shops Nearby'),
//             ),
//           ],
//         ),

//         content: Text(
//           allShops.isEmpty
//               ? 'No shops are available in this category.'
//               : 'No shops were found within '
//                   '${selectedRadius.toStringAsFixed(0)} km. '
//                   'Would you like to increase your search radius '
//                   'to ${radiusToShow.toStringAsFixed(0)} km?',
//         ),

//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(dialogContext);
//             },
//             child: const Text('Cancel'),
//           ),

//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(dialogContext);

//               _changeRadius(radiusToShow);
//             },

//             style: ElevatedButton.styleFrom(
//               backgroundColor: green,
//               foregroundColor: Colors.white,
//             ),

//             child: const Text('Increase'),
//           ),
//         ],
//       );
//     },
//   );
// }

//   // ============================================================
//   // OPEN SHOP PROFILE
//   // ============================================================

//   Future<void> _openShopProfile(
//     Map<String, dynamic> shop,
//   ) async {
//     final distance = _toDouble(shop['distance']);

//     if (distance == null || userPosition == null) return;

//     // Read the latest subscription information.
//     await loadPaymentData();

//     if (!mounted) return;

//     if (_isInsidePaidRadius(distance)) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ScreenAutoSparePartsShopProfile(
//             shop: shop,
//             userLatitude: userPosition!.latitude,
//             userLongitude: userPosition!.longitude,
//           ),
//         ),
//       );

//       return;
//     }

//     _showSubscriptionPopup(distance);
//   }

//   // ============================================================
//   // SUBSCRIPTION REQUIRED
//   // ============================================================

//   void _showSubscriptionPopup(double distance) {
//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           title: const Text('Subscription Required'),
//           content: Text(
//             'This shop is ${distance.toStringAsFixed(1)} KM away.\n\n'
//             'Your free access is 1 KM. '
//             'Your current subscription allows access up to '
//             '${availableDistance.toStringAsFixed(0)} KM.\n\n'
//             'Please purchase or update your distance subscription '
//             'from the Home page to access this shop.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(dialogContext);
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // ============================================================
//   // SHOP OPENING HOURS
//   // ============================================================

//   String _getShopHours(Map<String, dynamic> shop) {
//     final isOpen24Hours = shop['isOpen24Hours'] == true;

//     if (isOpen24Hours) {
//       return 'Open 24 Hours';
//     }

//     final openingTime =
//         (shop['openingTime'] ?? '').toString().trim();

//     final closingTime =
//         (shop['closingTime'] ?? '').toString().trim();

//     if (openingTime.isEmpty || closingTime.isEmpty) {
//       return 'Opening hours not provided';
//     }

//     return '$openingTime - $closingTime';
//   }

//   // ============================================================
//   // SHOP CARD
//   // ============================================================

//   Widget _buildShopCard(Map<String, dynamic> shop) {
//     final shopName =
//         (shop['shopName'] ?? 'Auto Spare Parts Shop').toString();

//     final category = shop['categories'] is List &&
//             (shop['categories'] as List).isNotEmpty
//         ? (shop['categories'] as List).join(', ')
//         : (shop['category'] ?? '').toString();

//     final experience = (shop['experience'] ?? '').toString();

//     final distance = _toDouble(shop['distance']) ?? 0;

//     final profileUnlocked = _isInsidePaidRadius(distance);

//     final shopHours = _getShopHours(shop);

//     return InkWell(
//       borderRadius: BorderRadius.circular(20),
//       onTap: () {
//         _openShopProfile(shop);
//       },
//       child: Container(
//         width: double.infinity,
//         margin: const EdgeInsets.only(bottom: 14),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: Colors.grey.shade200),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.04),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 62,
//               height: 62,
//               decoration: BoxDecoration(
//                 color: green.withValues(alpha: 0.10),
//                 borderRadius: BorderRadius.circular(18),
//               ),
//               child: const Icon(
//                 Icons.storefront_rounded,
//                 color: green,
//                 size: 32,
//               ),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     shopName,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                   const SizedBox(height: 5),
//                   Text(
//                     category,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       color: Colors.grey.shade700,
//                       fontSize: 13,
//                     ),
//                   ),
//                   if (experience.isNotEmpty) ...[
//                     const SizedBox(height: 4),
//                     Text(
//                       experience,
//                       style: TextStyle(
//                         color: Colors.grey.shade500,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                   const SizedBox(height: 8),

//                   // Distance
//                   Row(
//                     children: [
//                       const Icon(
//                         Icons.location_on_rounded,
//                         size: 17,
//                         color: green,
//                       ),
//                       const SizedBox(width: 4),
//                       Expanded(
//                         child: Text(
//                           '${distance.toStringAsFixed(1)} km from your location',
//                           style: const TextStyle(
//                             color: green,
//                             fontSize: 13,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 5),

//                   // Opening hours
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.access_time_rounded,
//                         size: 16,
//                         color: Colors.grey.shade700,
//                       ),
//                       const SizedBox(width: 5),
//                       Expanded(
//                         child: Text(
//                           shopHours,
//                           style: TextStyle(
//                             color: Colors.grey.shade700,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 6),

//                   // Profile access
//                   Row(
//                     children: [
//                       Icon(
//                         profileUnlocked
//                             ? Icons.lock_open_rounded
//                             : Icons.lock_outline_rounded,
//                         size: 15,
//                         color: profileUnlocked
//                             ? green
//                             : Colors.orange.shade800,
//                       ),
//                       const SizedBox(width: 5),
//                       Expanded(
//                         child: Text(
//                           profileUnlocked
//                               ? 'Profile access available'
//                               : 'Unlock ${distance.ceil()} KM to open profile',
//                           style: TextStyle(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w600,
//                             color: profileUnlocked
//                                 ? green
//                                 : Colors.orange.shade800,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             const Icon(
//               Icons.arrow_forward_ios_rounded,
//               size: 18,
//               color: green,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // RADIUS HEADER
//   // ============================================================

//   Widget _buildRadiusHeader() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: green.withValues(alpha: 0.08),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 46,
//             height: 46,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: const Icon(
//               Icons.location_searching_rounded,
//               color: green,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Search Radius',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   'Showing shops within '
//                   '${selectedRadius.toStringAsFixed(0)} km',
//                   style: TextStyle(
//                     color: Colors.grey.shade700,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           TextButton(
//             onPressed: _showRadiusDialog,
//             child: const Text('Change'),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // LOADING SCREEN
//   // ============================================================

//   Widget _buildLoadingScreen(String message) {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const CircularProgressIndicator(
//             color: green,
//           ),
//           const SizedBox(height: 18),
//           Text(
//             message,
//             style: TextStyle(
//               color: Colors.grey.shade700,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // ERROR SCREEN
//   // ============================================================

//   Widget _buildErrorScreen(String message) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(25),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.location_off_rounded,
//               size: 65,
//               color: Colors.grey.shade400,
//             ),
//             const SizedBox(height: 18),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 15,
//                 color: Colors.grey.shade700,
//               ),
//             ),
//             const SizedBox(height: 22),
//             ElevatedButton.icon(
//               onPressed: _initializePage,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: green,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               icon: const Icon(Icons.refresh_rounded),
//               label: const Text('Try Again'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // NO SHOPS
//   // ============================================================

//   Widget _buildNoShops() {
//     final hasMoreRadius = radiusOptions.any(
//       (radius) => radius > selectedRadius,
//     );

//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(25),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 90,
//               height: 90,
//               decoration: BoxDecoration(
//                 color: green.withValues(alpha: 0.08),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.storefront_outlined,
//                 size: 48,
//                 color: green,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               allShops.isEmpty
//                   ? 'No Shops Found'
//                   : 'No Shops Within '
//                       '${selectedRadius.toStringAsFixed(0)} km',
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 19,
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               allShops.isEmpty
//                   ? 'There are currently no shops available in this category.'
//                   : 'There are shops farther away. Increase your search radius to find more shops.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 14,
//               ),
//             ),
//             const SizedBox(height: 22),
//             if (allShops.isNotEmpty && hasMoreRadius)
//               ElevatedButton.icon(
//                 onPressed: _showIncreaseRadiusDialog,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: green,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 22,
//                     vertical: 14,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                 ),
//                 icon: const Icon(
//                   Icons.add_location_alt_rounded,
//                 ),
//                 label: const Text(
//                   'Increase Search Radius',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ),
//             if (allShops.isNotEmpty && !hasMoreRadius)
//               OutlinedButton(
//                 onPressed: _showRadiusDialog,
//                 child: const Text('Change Radius'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // SHOP LIST
//   // ============================================================

//   Widget _buildShopList() {
//     if (nearbyShops.isEmpty) {
//       return RefreshIndicator(
//         color: green,
//         onRefresh: _refresh,
//         child: ListView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           children: [
//             SizedBox(
//               height: MediaQuery.of(context).size.height * 0.65,
//               child: _buildNoShops(),
//             ),
//           ],
//         ),
//       );
//     }

//     return RefreshIndicator(
//       color: green,
//       onRefresh: _refresh,
//       child: ListView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
//         children: [
//           _buildRadiusHeader(),

//           const SizedBox(height: 18),

//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   '${nearbyShops.length} Nearby Shop'
//                   '${nearbyShops.length == 1 ? '' : 's'}',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//               ),
//               const Icon(
//                 Icons.sort_rounded,
//                 color: green,
//                 size: 20,
//               ),
//               const SizedBox(width: 5),
//               const Text(
//                 'Nearest',
//                 style: TextStyle(
//                   color: green,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 5),

//           Text(
//             'Shops are arranged from nearest to farthest.',
//             style: TextStyle(
//               color: Colors.grey.shade600,
//               fontSize: 12,
//             ),
//           ),

//           const SizedBox(height: 16),

//           ...paginatedShops.map(_buildShopCard),

//           if (nearbyShops.length > pageSize) ...[
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 IconButton(
//                   onPressed:
//                       currentPage > 0 ? _previousPage : null,
//                   icon: const Icon(
//                     Icons.arrow_back_ios_rounded,
//                   ),
//                 ),
//                 Text(
//                   'Page ${currentPage + 1} of '
//                   '${(nearbyShops.length / pageSize).ceil()}',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 IconButton(
//                   onPressed:
//                       (currentPage + 1) * pageSize <
//                               nearbyShops.length
//                           ? _nextPage
//                           : null,
//                   icon: const Icon(
//                     Icons.arrow_forward_ios_rounded,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//         centerTitle: true,
//         title: Column(
//           children: [
//             const Text(
//               'Nearby Spare Parts Shops',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             Text(
//               widget.selectedCategory,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 fontSize: 11,
//                 color: Colors.grey.shade600,
//                 fontWeight: FontWeight.w400,
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: loadingPayment
//           ? _buildLoadingScreen('Checking your subscription...')
//           : loadingLocation
//               ? _buildLoadingScreen('Getting your location...')
//               : locationError != null
//                   ? _buildErrorScreen(locationError!)
//                   : loadingShops
//                       ? _buildLoadingScreen('Finding nearby shops...')
//                       : shopsError != null
//                           ? _buildErrorScreen(shopsError!)
//                           : _buildShopList(),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:jober_india/jober_indiaScreens.dart/spareparts/screen_spare_parts_profile.dart';

// class ScreenAutoSparePartsShopList extends StatefulWidget {
//   final String selectedCategory;

//   const ScreenAutoSparePartsShopList({
//     super.key,
//     required this.selectedCategory,
//   });

//   @override
//   State<ScreenAutoSparePartsShopList> createState() =>
//       _ScreenAutoSparePartsShopListState();
// }

// class _ScreenAutoSparePartsShopListState
//     extends State<ScreenAutoSparePartsShopList> {

//   // ============================================================
//   // COLORS
//   // ============================================================

//   //static const Color green = Color(0xFF138808);
//   static const Color darkGreen = Color(0xFF138808);
//   //Color(0xFF12652F);

//   // ============================================================
//   // FIRESTORE
//   // ============================================================

//   final FirebaseFirestore _firestore =
//       FirebaseFirestore.instance;

//   // ============================================================
//   // SEARCH SETTINGS
//   // ============================================================

//   static const double maximumSearchRadius = 50.0;
//   static const int pageSize = 20;

//   // ============================================================
//   // LOCATION
//   // ============================================================

//   Position? userPosition;

//   bool isLocationLoading = false;

//   // ============================================================
//   // LOADING AND ERROR
//   // ============================================================

//   bool isLoading = true;
//   bool isLoadingMore = false;

//   String? errorMessage;

//   // ============================================================
//   // SHOP DATA
//   // ============================================================

//   List<Map<String, dynamic>> nearbyShops = [];

//   List<Map<String, dynamic>> visibleNearbyShops = [];

//   bool hasMore = false;

//   bool fetchingShops = false;

//   // ============================================================
//   // PAGINATION
//   // ============================================================

//   final ScrollController _scrollController =
//       ScrollController();

//   // ============================================================
//   // SUBSCRIPTION
//   // ============================================================

//   static const double freeDistanceKm = 1.0;

//   double paidDistance = 1.0;

//   DateTime? paymentExpiry;

//   bool get hasActiveSubscription {
//     return paymentExpiry != null &&
//         DateTime.now().isBefore(paymentExpiry!);
//   }

//   // ============================================================
//   // INIT
//   // ============================================================

//   @override
//   void initState() {
//     super.initState();

//     _scrollController.addListener(_onScroll);

//     _initializePage();
//   }

//   // ============================================================
//   // DISPOSE
//   // ============================================================

//   @override
//   void dispose() {
//     _scrollController.removeListener(_onScroll);

//     _scrollController.dispose();

//     super.dispose();
//   }

//   // ============================================================
//   // INITIALIZE PAGE
//   // ============================================================

//   Future<void> _initializePage() async {
//     await loadPaymentData();

//     if (!mounted) return;

//     await _loadNearbyShops();
//   }

//   // ============================================================
//   // LOAD SUBSCRIPTION DATA
//   // ============================================================

//   Future<void> loadPaymentData() async {
//     try {
//       if (!Hive.isBoxOpen('settings')) {
//         await Hive.openBox('settings');
//       }

//       final box = Hive.box('settings');

//       final savedDistance = box.get('activeDistance');

//       final savedExpiry = box.get('subscriptionExpiry');

//       double distance = 1.0;

//       DateTime? expiry;

//       if (savedDistance is num) {
//         distance = savedDistance.toDouble();
//       }

//       if (savedExpiry is DateTime) {
//         expiry = savedExpiry;
//       } else if (savedExpiry != null) {
//         expiry = DateTime.tryParse(
//           savedExpiry.toString(),
//         );
//       }

//       // CHECK SUBSCRIPTION EXPIRY

//       if (expiry == null ||
//           !DateTime.now().isBefore(expiry)) {

//         distance = 1.0;

//         expiry = null;

//         await box.delete('activeDistance');
//         await box.delete('subscriptionStart');
//         await box.delete('subscriptionExpiry');
//         await box.delete('subscriptionDuration');
//         await box.delete('subscriptionPaidAmount');
//         await box.delete('subscriptionActive');
//       }

//       paidDistance = distance;

//       paymentExpiry = expiry;

//     } catch (e) {
//       debugPrint(
//         'Spare parts subscription error: $e',
//       );

//       paidDistance = 1.0;

//       paymentExpiry = null;
//     }

//     if (mounted) {
//       setState(() {});
//     }
//   }

//   // ============================================================
//   // CHECK PROFILE ACCESS
//   // ============================================================

//   bool _canOpenShop(double distanceKm) {

//     // FIRST 1 KM IS FREE

//     if (distanceKm <= freeDistanceKm) {
//       return true;
//     }

//     // SUBSCRIPTION MUST BE ACTIVE

//     if (!hasActiveSubscription) {
//       return false;
//     }

//     // CHECK PURCHASED DISTANCE

//     return distanceKm <= paidDistance;
//   }

//   // ============================================================
//   // REQUEST LOCATION PERMISSION
//   // ============================================================

//   Future<bool> _requestLocationPermission() async {

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

//     LocationPermission permission =
//         await Geolocator.checkPermission();

//     if (permission == LocationPermission.denied) {
//       permission =
//           await Geolocator.requestPermission();
//     }

//     if (permission == LocationPermission.denied) {
//       if (mounted) {
//         setState(() {
//           errorMessage =
//               'Location permission is required '
//               'to find spare parts shops within 50 km.';
//         });
//       }

//       return false;
//     }

//     if (permission == LocationPermission.deniedForever) {
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
//   // GET USER LOCATION
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
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high,
//         ),
//       );

//       userPosition = position;

//       return position;

//     } catch (e) {
//       debugPrint(
//         'Spare parts location error: $e',
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
//   // LOAD NEARBY SHOPS
//   // ============================================================

// Future<void> _loadNearbyShops() async {
//   if (fetchingShops) return;

//   fetchingShops = true;

//   if (mounted) {
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });
//   }

//   try {
//     // GET USER LOCATION
//     final Position? position = await _getUserLocation();

//     if (position == null) {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//       return;
//     }

//     userPosition = position;

//     // FETCH REGISTERED SPARE PARTS SHOPS
//     final snapshot = await _firestore
//         .collection('auto_spare_parts_shops')
//         .get();

//     final List<Map<String, dynamic>> shops = [];

//     final String selectedCategory =
//         widget.selectedCategory.trim().toLowerCase();

//     // CHECK EACH SHOP
//     for (final document in snapshot.docs) {
//       final Map<String, dynamic> data = document.data();

//       // CATEGORY FILTER
//       final Set<String> shopCategories = {};
//       final Map<String, String> categoryNames = {};

//       // void addCategories(dynamic rawCategories) {
//       //   if (rawCategories is List) {
//       //     for (final item in rawCategories) {
//       //       if (item is String && item.trim().isNotEmpty) {
//       //         shopCategories.add(item.trim().toLowerCase());
//       //       }
//       //     }
//       //   } else if (rawCategories is String) {
//       //     for (final item in rawCategories.split(',')) {
//       //       if (item.trim().isNotEmpty) {
//       //         shopCategories.add(item.trim().toLowerCase());
//       //       }
//       //     }
//       //   }
//       // }
//       void addCategories(dynamic rawCategories) {
//   if (rawCategories is List) {
//     for (final rawCategory in rawCategories) {
//       if (rawCategory is! String) continue;

//       final category = rawCategory.trim();
//       if (category.isEmpty) continue;

//       final normalized = category.toLowerCase();

//       shopCategories.add(normalized);

//       categoryNames.putIfAbsent(
//         normalized,
//         () => category,
//       );
//     }
//   } else if (rawCategories is String) {
//     for (final rawCategory in rawCategories.split(',')) {
//       final category = rawCategory.trim();
//       if (category.isEmpty) continue;

//       final normalized = category.toLowerCase();

//       shopCategories.add(normalized);

//       categoryNames.putIfAbsent(
//         normalized,
//         () => category,
//       );
//     }
//   }
// }

//       addCategories(data['categories']);
//       addCategories(data['customCategories']);
//       addCategories(data['category']);

//       // "ALL AUTO SPARE PARTS" SHOWS EVERY REGISTERED SHOP.
//       if (selectedCategory != 'all auto spare parts' &&
//           !shopCategories.contains(selectedCategory)) {
//         continue;
//       }

//       // GET SHOP COORDINATES
//       double? shopLatitude;
//       double? shopLongitude;

//       // GeoFire structure
//       final dynamic geoData = data['geo'];

//       if (geoData is Map && geoData['geopoint'] is GeoPoint) {
//         final GeoPoint point = geoData['geopoint'];

//         shopLatitude = point.latitude;
//         shopLongitude = point.longitude;
//       }

//       // GeoPoint location structure
//       if (shopLatitude == null || shopLongitude == null) {
//         final dynamic locationData = data['location'];

//         if (locationData is GeoPoint) {
//           shopLatitude = locationData.latitude;
//           shopLongitude = locationData.longitude;
//         }
//       }

//       // Direct latitude / longitude fields
//       shopLatitude ??= _toDouble(data['latitude']);
//       shopLongitude ??= _toDouble(data['longitude']);

//       // Also support currentLocation Map, like Medical Shops
//       if (shopLatitude == null || shopLongitude == null) {
//         final dynamic currentLocation = data['currentLocation'];

//         if (currentLocation is Map) {
//           shopLatitude ??= _toDouble(
//             currentLocation['latitude'],
//           );

//           shopLongitude ??= _toDouble(
//             currentLocation['longitude'],
//           );
//         }
//       }

//       // IGNORE INVALID LOCATION
//       if (shopLatitude == null || shopLongitude == null) {
//         debugPrint(
//           'Spare parts shop skipped: ${document.id} - '
//           'Location missing',
//         );
//         continue;
//       }

//       if (shopLatitude < -90 ||
//           shopLatitude > 90 ||
//           shopLongitude < -180 ||
//           shopLongitude > 180) {
//         continue;
//       }

//       // CALCULATE DISTANCE
//       final double distanceInMeters =
//           Geolocator.distanceBetween(
//         position.latitude,
//         position.longitude,
//         shopLatitude,
//         shopLongitude,
//       );

//       final double distanceInKm = distanceInMeters / 1000.0;

//       // SHOW ONLY SHOPS WITHIN 50 KM
//       if (distanceInKm > maximumSearchRadius) {
//         continue;
//       }

//       // ADD SHOP
//       shops.add({
//         'id': document.id,
//         'documentId': document.id,
//         ...data,
//         'uid': data['uid']?.toString() ?? document.id,
//         'latitude': shopLatitude,
//         'longitude': shopLongitude,
//         'distanceKm': distanceInKm,
//       });
//     }

//     // SORT NEAREST FIRST
//     shops.sort((a, b) {
//       final double distanceA =
//           (a['distanceKm'] as num).toDouble();

//       final double distanceB =
//           (b['distanceKm'] as num).toDouble();

//       return distanceA.compareTo(distanceB);
//     });

//     if (!mounted) return;

//     setState(() {
//       nearbyShops = shops;
//       visibleNearbyShops = [];

//       isLoading = false;
//       isLoadingMore = false;
//       hasMore = false;
//       errorMessage = null;

//       _appendNextPage();
//     });

//     debugPrint(
//       'SPARE PARTS SHOPS FOUND WITHIN 50 KM: ${shops.length}',
//     );
//   } catch (e, stackTrace) {
//     debugPrint('Spare parts loading error: $e');
//     debugPrint('$stackTrace');

//     if (!mounted) return;

//     setState(() {
//       isLoading = false;
//       errorMessage =
//           'Unable to load nearby spare parts shops.';
//     });
//   } finally {
//     fetchingShops = false;
//   }
// }

//   // ============================================================
//   // APPEND NEXT PAGE
//   // ============================================================

//   void _appendNextPage() {

//     final currentCount =
//         visibleNearbyShops.length;

//     if (currentCount >= nearbyShops.length) {
//       hasMore = false;
//       return;
//     }

//     final end = (currentCount + pageSize)
//         .clamp(0, nearbyShops.length);

//     visibleNearbyShops.addAll(
//       nearbyShops.sublist(
//         currentCount,
//         end,
//       ),
//     );

//     hasMore = end < nearbyShops.length;
//   }

//   // ============================================================
//   // SCROLL LISTENER
//   // ============================================================

//   void _onScroll() {

//     if (!_scrollController.hasClients) {
//       return;
//     }

//     if (_scrollController.position.pixels >=
//         _scrollController.position.maxScrollExtent - 250) {

//       _loadMore();
//     }
//   }

//   // ============================================================
//   // LOAD MORE SHOPS
//   // ============================================================

//   Future<void> _loadMore() async {

//     if (isLoadingMore || !hasMore) {
//       return;
//     }

//     setState(() {
//       isLoadingMore = true;
//     });

//     await Future<void>.delayed(Duration.zero);

//     if (!mounted) return;

//     setState(() {

//       _appendNextPage();

//       isLoadingMore = false;
//     });
//   }

//   // ============================================================
//   // CONVERT VALUE TO DOUBLE
//   // ============================================================

//   double? _toDouble(dynamic value) {

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

//   String _formatDistance(double distanceKm) {

//     if (distanceKm < 1) {

//       final int meters =
//           (distanceKm * 1000).round();

//       return '$meters m';
//     }

//     return '${distanceKm.toStringAsFixed(1)} km';
//   }

//   // ============================================================
//   // GET SHOP INITIAL
//   // ============================================================

//   String _getShopInitial(String shopName) {

//     final name = shopName.trim();

//     if (name.isEmpty) {
//       return 'S';
//     }

//     return name.substring(0, 1).toUpperCase();
//   }

//   // ============================================================
//   // SHOP AVATAR
//   // ============================================================

//   Widget _buildShopAvatar(
//     Map<String, dynamic> shop,
//   ) {

//     final String shopName =
//         (shop['shopName'] ?? 'Spare Parts Shop')
//             .toString();

//     final dynamic imageValue =
//         shop['imageUrl'] ??
//         shop['profilePhotoUrl'] ??
//         shop['shopImageUrl'];

//     if (imageValue is String &&
//         imageValue.trim().isNotEmpty) {

//       return CircleAvatar(
//         radius: 28,

//         backgroundColor:
//             const Color(0xFFE8F5E9),

//         child: ClipOval(
//           child: Image.network(
//             imageValue.trim(),
//             width: 56,
//             height: 56,
//             fit: BoxFit.cover,

//             errorBuilder: (context, error, stackTrace) {
//               return _buildShopInitialAvatar(shopName);
//             },
//           ),
//         ),
//       );
//     }

//     return _buildShopInitialAvatar(shopName);
//   }

//   // ============================================================
//   // SHOP INITIAL AVATAR
//   // ============================================================

//   Widget _buildShopInitialAvatar(String shopName) {

//     return CircleAvatar(
//       radius: 28,

//       backgroundColor:
//           const Color(0xFFE8F5E9),

//       child: Text(
//         _getShopInitial(shopName),

//         style: const TextStyle(
//           color: darkGreen,
//           fontSize: 22,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // GET SHOP PLACE NAME
//   // ============================================================

//   String _getShopPlaceName(
//     Map<String, dynamic> shop,
//   ) {

//     final currentLocation =
//         shop['currentLocation'];

//     if (currentLocation is Map) {

//       final placeName =
//           currentLocation['placeName']
//               ?.toString()
//               .trim();

//       if (placeName != null && placeName.isNotEmpty) {
//         return placeName;
//       }
//     }

//     final nearestTown =
//         shop['nearestTown']?.toString().trim();

//     if (nearestTown != null && nearestTown.isNotEmpty) {
//       return nearestTown;
//     }

//     final district =
//         shop['district']?.toString().trim();

//     final state =
//         shop['state']?.toString().trim();

//     if (district != null &&
//         district.isNotEmpty &&
//         state != null &&
//         state.isNotEmpty) {
//       return '$district, $state';
//     }

//     if (district != null && district.isNotEmpty) {
//       return district;
//     }

//     if (state != null && state.isNotEmpty) {
//       return state;
//     }

//     return '';
//   }

//   // ============================================================
//   // GET SHOP CATEGORY
//   // ============================================================

//   String _getShopCategory(
//     Map<String, dynamic> shop,
//   ) {

//     final categories = shop['categories'];

//     if (categories is List && categories.isNotEmpty) {
//       return categories
//           .map((item) => item.toString())
//           .join(', ');
//     }

//     final customCategories =
//         shop['customCategories'];

//     if (customCategories is List &&
//         customCategories.isNotEmpty) {
//       return customCategories
//           .map((item) => item.toString())
//           .join(', ');
//     }

//     final category =
//         shop['category']?.toString().trim();

//     if (category != null && category.isNotEmpty) {
//       return category;
//     }

//     return widget.selectedCategory;
//   }

//   // ============================================================
//   // HANDLE SHOP TAP
//   // ============================================================

//   Future<void> _handleShopTap(
//     Map<String, dynamic> shop,
//   ) async {

//     final double distanceKm =
//         (shop['distanceKm'] as num).toDouble();

//     if (!_canOpenShop(distanceKm)) {

//       _showSubscriptionRequiredDialog(distanceKm);

//       return;
//     }

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ScreenAutoSparePartsShopProfile(
//           shop: shop,
//           userLatitude: userPosition!.latitude,
//           userLongitude: userPosition!.longitude,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // SUBSCRIPTION REQUIRED DIALOG
//   // ============================================================

//   void _showSubscriptionRequiredDialog(
//     double distanceKm,
//   ) {

//     showDialog<void>(
//       context: context,

//       builder: (dialogContext) {

//         return AlertDialog(

//           title: const Text(
//             'Distance access required',
//           ),

//           content: Text(
//             'This spare parts shop is '
//             '${_formatDistance(distanceKm)} away.\n\n'
//             'Your current access is '
//             '${hasActiveSubscription ? paidDistance.round() : 1} KM.\n\n'
//             'Unlock a larger distance from the Home page '
//             'to open this shop profile.',
//           ),

//           actions: [

//             TextButton(
//               onPressed: () {
//                 Navigator.pop(dialogContext);
//               },

//               child: const Text('Close'),
//             ),
//           ],
//         );
//       },
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
//             ? shop['shopName'].toString().trim()
//             : 'Auto Spare Parts Shop';

//     final double distanceKm =
//         (shop['distanceKm'] as num).toDouble();

//     final String placeName =
//         _getShopPlaceName(shop);

//     final String category =
//         _getShopCategory(shop);

//     return InkWell(

//       onTap: () {
//         _handleShopTap(shop);
//       },

//       child: Container(

//         padding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 10,
//         ),

//         child: Row(

//           crossAxisAlignment: CrossAxisAlignment.center,

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

//                 crossAxisAlignment: CrossAxisAlignment.start,

//                 children: [

//                   // SHOP NAME

//                   Text(
//                     shopName,

//                     maxLines: 1,

//                     overflow: TextOverflow.ellipsis,

//                     style: const TextStyle(
//                       fontSize: 17,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF202020),
//                     ),
//                   ),

//                   const SizedBox(height: 4),

//                   // PLACE NAME

//                   if (placeName.isNotEmpty)

//                     Text(
//                       placeName,

//                       maxLines: 1,

//                       overflow: TextOverflow.ellipsis,

//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.grey.shade600,
//                       ),
//                     )

//                   else

//                     Text(
//                       category,

//                       maxLines: 1,

//                       overflow: TextOverflow.ellipsis,

//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),

//                   // CATEGORY

//                   if (placeName.isNotEmpty &&
//                       category.isNotEmpty) ...[

//                     const SizedBox(height: 3),

//                     Text(
//                       category,

//                       maxLines: 1,

//                       overflow: TextOverflow.ellipsis,

//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey.shade500,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),

//             const SizedBox(width: 8),

//             // --------------------------------------------------
//             // DISTANCE + ARROW
//             // --------------------------------------------------

//             Column(

//               mainAxisAlignment: MainAxisAlignment.center,

//               crossAxisAlignment: CrossAxisAlignment.end,

//               children: [

//                 Text(
//                   _formatDistance(distanceKm),

//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),

//                 const SizedBox(height: 5),

//                 const Icon(
//                   Icons.chevron_right,
//                   size: 18,
//                   color: Color(0xFFAAAAAA),
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

//       color: darkGreen,

//       onRefresh: _loadNearbyShops,

//       child: ListView(

//         physics:
//             const AlwaysScrollableScrollPhysics(),

//         children: [

//           SizedBox(
//             height:
//                 MediaQuery.of(context).size.height * 0.30,
//           ),

//           Icon(
//             Icons.storefront_outlined,
//             size: 70,
//             color: Colors.grey.shade400,
//           ),

//           const SizedBox(height: 16),

//           const Text(
//             'No shops found',

//             textAlign: TextAlign.center,

//             style: TextStyle(
//               fontSize: 19,
//               fontWeight: FontWeight.w600,
//             ),
//           ),

//           const SizedBox(height: 7),

//           Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 35,
//             ),

//             child: Text(
//               widget.selectedCategory.toLowerCase() ==
//                       'all auto spare parts'
//                   ? 'No spare parts shops were found within 50 km of your location.'
//                   : 'No ${widget.selectedCategory} shops were found within 50 km of your location.',

//               textAlign: TextAlign.center,

//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey.shade600,
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

//         padding: const EdgeInsets.all(25),

//         child: Column(

//           mainAxisSize: MainAxisSize.min,

//           children: [

//             Icon(
//               Icons.location_off_outlined,
//               size: 65,
//               color: Colors.grey.shade400,
//             ),

//             const SizedBox(height: 16),

//             Text(
//               errorMessage ?? 'Something went wrong.',

//               textAlign: TextAlign.center,

//               style: const TextStyle(
//                 fontSize: 16,
//                 height: 1.4,
//               ),
//             ),

//             const SizedBox(height: 20),

//             ElevatedButton.icon(

//               onPressed: _initializePage,

//               icon: const Icon(Icons.refresh),

//               label: const Text('Try Again'),

//               style: ElevatedButton.styleFrom(
//                 backgroundColor: darkGreen,
//                 foregroundColor: Colors.white,

//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 22,
//                   vertical: 13,
//                 ),

//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
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
//   Widget build(BuildContext context) {

//     return Scaffold(

//       backgroundColor: Colors.white,

//       // ========================================================
//       // APP BAR
//       // ========================================================

//       appBar: AppBar(

//         backgroundColor: darkGreen,

//         foregroundColor: Colors.white,

//         elevation: 0,

//         titleSpacing: 0,

//         title: Column(

//           crossAxisAlignment: CrossAxisAlignment.start,

//           children: [

//             Text(
//               widget.selectedCategory,

//               maxLines: 1,

//               overflow: TextOverflow.ellipsis,

//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),

//             Text(
//               isLoading
//                   ? 'Finding shops...'
//                   : '${nearbyShops.length} shops within 50 km',

//               style: const TextStyle(
//                 fontSize: 12,
//                 color: Colors.white70,
//               ),
//             ),
//           ],
//         ),

//         actions: [

//           // REFRESH

//           IconButton(
//             onPressed: isLoading
//                 ? null
//                 : _loadNearbyShops,

//             icon: const Icon(Icons.refresh),

//             tooltip: 'Refresh',
//           ),

//           // MORE MENU

//           IconButton(
//             onPressed: () {},

//             icon: const Icon(Icons.more_vert),
//           ),
//         ],
//       ),

//       // ========================================================
//       // BODY
//       // ========================================================

//       body: isLoading

//           // LOADING

//           ? const Center(
//               child: CircularProgressIndicator(
//                 color: darkGreen,
//               ),
//             )

//           // ERROR

//           : errorMessage != null

//               ? _buildErrorScreen()

//               // EMPTY

//               : nearbyShops.isEmpty

//                   ? _buildEmptyScreen()

//                   // SHOP LIST

//                   : RefreshIndicator(

//                       color: darkGreen,

//                       onRefresh: _loadNearbyShops,

//                       child: ListView.separated(

//                         controller: _scrollController,

//                         physics:
//                             const AlwaysScrollableScrollPhysics(),

//                         itemCount:
//                             visibleNearbyShops.length +
//                             (isLoadingMore ? 1 : 0),

//                         separatorBuilder: (context, index) {

//                           return const Divider(
//                             height: 1,
//                             indent: 86,
//                             color: Color(0xFFE5E5E5),
//                           );
//                         },

//                         itemBuilder: (context, index) {

//                           // LOADING MORE INDICATOR

//                           if (index >=
//                               visibleNearbyShops.length) {

//                             return const Padding(
//                               padding: EdgeInsets.all(20),

//                               child: Center(
//                                 child: CircularProgressIndicator(
//                                   color: darkGreen,
//                                 ),
//                               ),
//                             );
//                           }

//                           // SHOP ROW

//                           return _buildShopRow(
//                             visibleNearbyShops[index],
//                           );
//                         },
//                       ),
//                     ),
//     );
//   }
// }
class ScreenAutoSparePartsShopList extends StatefulWidget {
  final String selectedCategory;

  const ScreenAutoSparePartsShopList({
    super.key,
    required this.selectedCategory,
  });

  @override
  State<ScreenAutoSparePartsShopList> createState() =>
      _ScreenAutoSparePartsShopListState();
}

class _ScreenAutoSparePartsShopListState
    extends State<ScreenAutoSparePartsShopList> {

  // ============================================================
  // FIRESTORE
  // ============================================================

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // SCROLL
  // ============================================================

  final ScrollController scrollController =
      ScrollController();

  // ============================================================
  // LOCATION
  // ============================================================

  Position? currentPosition;

  bool isLoadingLocation = true;
  bool locationPermissionDenied = false;

  // ============================================================
  // SHOP DATA
  // ============================================================

  final List<Map<String, dynamic>> shops = [];

  static const int pageSize = 20;
  static const double maximumSearchRadius = 50.0;

  int visibleCount = pageSize;

  bool isLoadingShops = false;
  bool isLoadingMore = false;
  bool isFetchingAllShops = false;

  String? errorMessage;

  DocumentSnapshot<Map<String, dynamic>>? lastDocument;

  bool hasMore = true;

  // ============================================================
  // SUBSCRIPTION
  // ============================================================

  double paidRadius = 1.0;

  DateTime? subscriptionExpiry;

  bool subscriptionIsActive = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    scrollController.addListener(_scrollListener);

    _initializePage();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // INITIALIZE PAGE
  // ============================================================

  Future<void> _initializePage() async {
    await _loadPaidRadius();

    if (!mounted) return;

    final locationReady = await _getCurrentLocation();

    if (!locationReady || !mounted) return;

    await _loadShops(reset: true);
  }

  // ============================================================
  // LOAD SUBSCRIPTION
  // ============================================================

  Future<void> _loadPaidRadius() async {
    try {
      if (!Hive.isBoxOpen('settings')) {
        await Hive.openBox('settings');
      }

      final box = Hive.box('settings');

      final savedDistance = box.get('activeDistance');
      final savedExpiry = box.get('subscriptionExpiry');

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

      if (validSubscription && savedDistance is num) {
        paidRadius = savedDistance.toDouble();

        subscriptionExpiry = expiry;

        subscriptionIsActive = true;
      } else {
        paidRadius = 1.0;

        subscriptionExpiry = null;

        subscriptionIsActive = false;

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
      debugPrint('Spare parts subscription error: $e');

      paidRadius = 1.0;
      subscriptionExpiry = null;
      subscriptionIsActive = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<bool> _getCurrentLocation() async {
    if (mounted) {
      setState(() {
        isLoadingLocation = true;
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
          isLoadingLocation = false;
          errorMessage =
              'Please turn ON your location service.';
        });

        await Geolocator.openLocationSettings();

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
          isLoadingLocation = false;
          locationPermissionDenied = true;

          errorMessage =
              'Location permission is required to find nearby spare parts shops.';
        });

        return false;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return false;

      setState(() {
        currentPosition = position;
        isLoadingLocation = false;
      });

      return true;
    } catch (e) {
      debugPrint('Spare parts location error: $e');

      if (!mounted) return false;

      setState(() {
        isLoadingLocation = false;
        errorMessage =
            'Unable to get your current location.';
      });

      return false;
    }
  }

  // ============================================================
  // LOAD SHOPS
  // ============================================================

  Future<void> _loadShops({
    required bool reset,
  }) async {
    if (currentPosition == null ||
        isFetchingAllShops) {
      return;
    }

    if (!reset) return;

    isFetchingAllShops = true;

    if (mounted) {
      setState(() {
        isLoadingShops = true;
        isLoadingMore = false;
        errorMessage = null;

        shops.clear();

        visibleCount = pageSize;

        lastDocument = null;

        hasMore = true;
      });
    }

    try {
      final List<Map<String, dynamic>> allResults = [];

      final selectedCategory =
          widget.selectedCategory.trim().toLowerCase();

      // --------------------------------------------------------
      // FETCH ALL ACTIVE SHOPS IN BATCHES OF 20
      // --------------------------------------------------------

      while (hasMore) {
        Query<Map<String, dynamic>> query = firestore
            .collection('auto_spare_parts_shops')
            // IMPORTANT:
            // Your registration saves 'active': true.
            .where('active', isEqualTo: true)
            .limit(pageSize);

        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument!);
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

        // ------------------------------------------------------
        // PROCESS EACH SHOP
        // ------------------------------------------------------

        for (final document in snapshot.docs) {
          final data = document.data();

          // ----------------------------------------------------
          // CATEGORY FILTER
          // ----------------------------------------------------

          final Set<String> shopCategories = {};

          void addCategories(dynamic rawCategories) {
            if (rawCategories is List) {
              for (final item in rawCategories) {
                final category = item.toString().trim();

                if (category.isNotEmpty) {
                  shopCategories.add(
                    category.toLowerCase(),
                  );
                }
              }
            } else if (rawCategories is String) {
              for (final item in rawCategories.split(',')) {
                final category = item.trim();

                if (category.isNotEmpty) {
                  shopCategories.add(
                    category.toLowerCase(),
                  );
                }
              }
            }
          }

          addCategories(data['categories']);
          addCategories(data['customCategories']);
          addCategories(data['category']);

          // ALL AUTO SPARE PARTS SHOWS EVERY ACTIVE SHOP.

          if (selectedCategory != 'all auto spare parts' &&
              !shopCategories.contains(selectedCategory)) {
            continue;
          }

          // ----------------------------------------------------
          // READ SHOP LOCATION
          // ----------------------------------------------------

          double? latitude;
          double? longitude;

          // 1. GEO FIRESTORE STRUCTURE

          final geoData = data['geo'];

          if (geoData is Map &&
              geoData['geopoint'] is GeoPoint) {
            final point = geoData['geopoint'] as GeoPoint;

            latitude = point.latitude;
            longitude = point.longitude;
          }

          // 2. LOCATION GEOPOINT

          if (latitude == null || longitude == null) {
            final locationData = data['location'];

            if (locationData is GeoPoint) {
              latitude = locationData.latitude;
              longitude = locationData.longitude;
            }
          }

          // 3. DIRECT LATITUDE AND LONGITUDE

          latitude ??= _readDouble(data['latitude']);

          longitude ??= _readDouble(data['longitude']);

          // 4. CURRENT LOCATION MAP

          if (latitude == null || longitude == null) {
            final currentLocation = data['currentLocation'];

            if (currentLocation is GeoPoint) {
              latitude = currentLocation.latitude;
              longitude = currentLocation.longitude;
            } else if (currentLocation is Map) {
              latitude ??= _readDouble(
                currentLocation['latitude'] ??
                    currentLocation['lat'],
              );

              longitude ??= _readDouble(
                currentLocation['longitude'] ??
                    currentLocation['lng'],
              );
            }
          }

          // ----------------------------------------------------
          // VALIDATE LOCATION
          // ----------------------------------------------------

          if (latitude == null || longitude == null) {
            debugPrint(
              'Spare parts shop skipped: ${document.id} - '
              'Location missing',
            );

            continue;
          }

          if (latitude < -90 ||
              latitude > 90 ||
              longitude < -180 ||
              longitude > 180) {
            continue;
          }

          // ----------------------------------------------------
          // CALCULATE ACTUAL DISTANCE FROM USER
          // ----------------------------------------------------

          final distanceInMeters =
              Geolocator.distanceBetween(
            currentPosition!.latitude,
            currentPosition!.longitude,
            latitude,
            longitude,
          );

          final distanceInKm =
              distanceInMeters / 1000.0;

          // ----------------------------------------------------
          // MAXIMUM SEARCH RADIUS: 50 KM
          // ----------------------------------------------------

          if (distanceInKm > maximumSearchRadius) {
            continue;
          }

          // ----------------------------------------------------
          // ADD SHOP
          // ----------------------------------------------------

          final shop =
              Map<String, dynamic>.from(data);

          shop['uid'] =
              data['uid']?.toString() ?? document.id;

          shop['documentId'] = document.id;

          shop['latitude'] = latitude;

          shop['longitude'] = longitude;

          shop['distanceKm'] = distanceInKm;

          allResults.add(shop);
        }
      }

      // --------------------------------------------------------
      // SORT COMPLETE RESULTS: NEAREST FIRST
      // --------------------------------------------------------

      allResults.sort((a, b) {
        final distanceA =
            _readDouble(a['distanceKm']) ?? double.infinity;

        final distanceB =
            _readDouble(b['distanceKm']) ?? double.infinity;

        return distanceA.compareTo(distanceB);
      });

      if (!mounted) return;

      setState(() {
        shops
          ..clear()
          ..addAll(allResults);

        // Initially display only 20 shops.

        visibleCount = shops.length < pageSize
            ? shops.length
            : pageSize;

        isLoadingShops = false;
        isLoadingMore = false;
        errorMessage = null;
      });

      debugPrint(
        'SPARE PARTS SHOPS FOUND WITHIN 50 KM: ${shops.length}',
      );
    } catch (e, stackTrace) {
      debugPrint('Spare parts loading error: $e');
      debugPrint('$stackTrace');

      if (mounted) {
        setState(() {
          isLoadingShops = false;
          isLoadingMore = false;

          errorMessage =
              'Unable to load nearby spare parts shops.';
        });
      }
    } finally {
      isFetchingAllShops = false;
    }
  }

  // ============================================================
  // CONVERT VALUE TO DOUBLE
  // ============================================================

  double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  // ============================================================
  // SCROLL LISTENER
  // ============================================================

  void _scrollListener() {
    if (!scrollController.hasClients ||
        isLoadingMore ||
        isLoadingShops) {
      return;
    }

    final position = scrollController.position;

    if (position.pixels >=
            position.maxScrollExtent - 300 &&
        visibleCount < shops.length) {
      setState(() {
        isLoadingMore = true;

        visibleCount =
            (visibleCount + pageSize > shops.length)
                ? shops.length
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

  // ============================================================
  // DISPLAYED SHOP COUNT
  // ============================================================

  int get displayedShopCount {
    return visibleCount < shops.length
        ? visibleCount
        : shops.length;
  }

  // ============================================================
  // FORMAT DISTANCE
  // ============================================================

  String _formatDistance(double distance) {
    if (distance < 1) {
      final meters = (distance * 1000).round();

      return '$meters m away';
    }

    return '${distance.toStringAsFixed(1)} km away';
  }

  // ============================================================
  // SHOP NAME
  // ============================================================

  String _shopName(Map<String, dynamic> shop) {
    final shopName =
        shop['shopName']?.toString().trim();

    if (shopName != null && shopName.isNotEmpty) {
      return shopName;
    }

    return 'Auto Spare Parts Shop';
  }

  // ============================================================
  // SHOP CATEGORIES
  // ============================================================

  String _shopCategories(
    Map<String, dynamic> shop,
  ) {
    final categories = shop['categories'];

    if (categories is List) {
      final values = categories
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();

      if (values.isNotEmpty) {
        return values.join(', ');
      }
    }

    final customCategories = shop['customCategories'];

    if (customCategories is List &&
        customCategories.isNotEmpty) {
      return customCategories
          .map((e) => e.toString())
          .join(', ');
    }

    final category = shop['category']?.toString().trim();

    if (category != null && category.isNotEmpty) {
      return category;
    }

    return widget.selectedCategory;
  }

  // ============================================================
  // SHOP PLACE
  // ============================================================

  String _shopPlace(Map<String, dynamic> shop) {
    final currentLocation = shop['currentLocation'];

    if (currentLocation is Map) {
      final placeName =
          currentLocation['placeName']?.toString().trim();

      if (placeName != null && placeName.isNotEmpty) {
        return placeName;
      }
    }

    final nearestTown =
        shop['nearestTown']?.toString().trim();

    final district =
        shop['district']?.toString().trim();

    final state =
        shop['state']?.toString().trim();

    if (nearestTown != null && nearestTown.isNotEmpty) {
      return nearestTown;
    }

    if (district != null &&
        district.isNotEmpty &&
        state != null &&
        state.isNotEmpty) {
      return '$district, $state';
    }

    if (district != null && district.isNotEmpty) {
      return district;
    }

    if (state != null && state.isNotEmpty) {
      return state;
    }

    return '';
  }

  // ============================================================
  // SHOP TIMING
  // ============================================================

  String _timingText(Map<String, dynamic> shop) {
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

  // ============================================================
  // SHOP IMAGE
  // ============================================================

  Widget _shopImage(Map<String, dynamic> shop) {
    final imageUrl =
        (shop['profilePhotoUrl'] ??
                shop['imageUrl'] ??
                shop['shopImageUrl'])
            ?.toString()
            .trim();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          imageUrl,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return _defaultShopImage();
          },
        ),
      );
    }

    return _defaultShopImage();
  }

  Widget _defaultShopImage() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8EF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.storefront_outlined,
        color: Color(0xFF16803C),
        size: 38,
      ),
    );
  }

  // ============================================================
  // CHECK PROFILE ACCESS
  // ============================================================

  bool _isInsidePaidRadius(
    Map<String, dynamic> shop,
  ) {
    final distance =
        _readDouble(shop['distanceKm']);

    if (distance == null) {
      return false;
    }

    // FIRST 1 KM IS FREE.

    if (distance <= 1.0) {
      return true;
    }

    // SUBSCRIPTION MUST BE ACTIVE.

    if (!subscriptionIsActive ||
        subscriptionExpiry == null ||
        !DateTime.now().isBefore(subscriptionExpiry!)) {
      return false;
    }

    return distance <= paidRadius;
  }

  // ============================================================
  // OPEN SHOP
  // ============================================================

  Future<void> _openShop(
    Map<String, dynamic> shop,
  ) async {
    final distance =
        _readDouble(shop['distanceKm']);

    if (distance == null) return;

    // Always check latest subscription.

    await _loadPaidRadius();

    if (!mounted) return;

    if (_isInsidePaidRadius(shop)) {
      _goToProfile(shop);
      return;
    }

    _showPaymentRequiredDialog(distance);
  }

  // ============================================================
  // GO TO SHOP PROFILE
  // ============================================================

  void _goToProfile(
    Map<String, dynamic> shop,
  ) {
    final position = currentPosition;

    if (position == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenAutoSparePartsShopProfile(
          shop: shop,
          userLatitude: position.latitude,
          userLongitude: position.longitude,
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT REQUIRED DIALOG
  // ============================================================

  void _showPaymentRequiredDialog(double distance) {
    final requiredRadius = distance.ceil();

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
            'This spare parts shop is '
            '${distance.toStringAsFixed(1)} km away.\n\n'
            'Your current access radius is '
            '${subscriptionIsActive ? paidRadius.toStringAsFixed(0) : '1'} km.\n\n'
            'Unlock a larger distance to open this shop profile.',
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

                _showRadiusInformation(requiredRadius);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF159B16),
                foregroundColor: Colors.white,
              ),
              child: const Text('VIEW OPTIONS'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DISTANCE INFORMATION
  // ============================================================

  void _showRadiusInformation(int requiredRadius) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Distance Access'),
          content: Text(
            'This spare parts shop is approximately '
            '$requiredRadius km away.\n\n'
            'Use your existing distance-unlock/payment flow '
            'to unlock a larger search radius.',
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

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _loadPaidRadius();

    if (!mounted) return;

    final locationReady = await _getCurrentLocation();

    if (!locationReady || !mounted) return;

    await _loadShops(reset: true);
  }

  // ============================================================
  // SHOP CARD
  // ============================================================

  Widget _shopCard(Map<String, dynamic> shop) {
    final name = _shopName(shop);

    final category = _shopCategories(shop);

    final place = _shopPlace(shop);

    final distance =
        _readDouble(shop['distanceKm']) ?? 0.0;

    final timing = _timingText(shop);

    final isOpen24Hours =
        shop['isOpen24Hours'] == true;

    final canOpen = _isInsidePaidRadius(shop);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _openShop(shop);
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

              _shopImage(shop),

              const SizedBox(width: 13),

              // SHOP INFORMATION

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF202124),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      category,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF16803C),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 7),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFFE87516),
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 7),

                    // ACTUAL DISTANCE FROM USER

                    Row(
                      children: [
                        const Icon(
                          Icons.near_me_outlined,
                          color: Color(0xFFE87516),
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatDistance(distance),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    // OPENING TIME

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
                            timing,
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

              // ACCESS STATUS

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

  // ============================================================
  // TOP SECTION
  // ============================================================

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 18),
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
            'Auto spare parts shops within 50 km '
            'from your current location',
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
                    '${shops.length} '
                    'shop${shops.length == 1 ? '' : 's'} found',
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

  // ============================================================
  // EMPTY STATE
  // ============================================================

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
                Icons.storefront_outlined,
                color: Color(0xFF16803C),
                size: 42,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No nearby spare parts shops',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF202124),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              widget.selectedCategory.toLowerCase() ==
                      'all auto spare parts'
                  ? 'No spare parts shops were found within 50 km.'
                  : 'No ${widget.selectedCategory} shops '
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

  // ============================================================
  // LOCATION ERROR
  // ============================================================

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
                  'Turn on location to find nearby spare parts shops.',
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

  // ============================================================
  // BUILD BODY
  // ============================================================

  Widget _buildBody() {
    if (isLoadingLocation) {
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
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _buildTopSection(),
          ),

          if (isLoadingShops)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF159B16),
                ),
              ),
            )
          else if (shops.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                18,
                0,
                18,
                25,
              ),
              sliver: SliverList.builder(
                itemCount: displayedShopCount +
                    (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
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

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: _shopCard(shops[index]),
                  );
                },
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
                text: 'Spare Parts',
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
            onPressed: isLoadingShops || isLoadingLocation
                ? null
                : _refresh,
            icon: const Icon(
              Icons.refresh,
              color: Colors.black,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: _buildBody(),
    );
  }
}


//   Future<void> _loadNearbyShops() async {

//     if (fetchingShops) return;

//     fetchingShops = true;

//     if (mounted) {
//       setState(() {
//         isLoading = true;
//         errorMessage = null;
//       });
//     }

//     try {

//       // --------------------------------------------------------
//       // GET USER LOCATION
//       // --------------------------------------------------------

//       final Position? position =
//           await _getUserLocation();

//       if (position == null) {
//         if (mounted) {
//           setState(() {
//             isLoading = false;
//           });
//         }

//         return;
//       }

//       userPosition = position;

//       // --------------------------------------------------------
//       // GEOHASH CENTER
//       // --------------------------------------------------------

//       // final center = GeoFirePoint(
//       //   GeoPoint(
//       //     position.latitude,
//       //     position.longitude,
//       //   ),
//       // );

//       // --------------------------------------------------------
//       // FIRESTORE COLLECTION
//       // --------------------------------------------------------

//       // final collection = _firestore.collection(
//       //   'auto_spare_parts_shops',
//       // );

//       // final geoCollection =
//       //     GeoCollectionReference<Map<String, dynamic>>(
//       //   collection,
//       // );

//       // --------------------------------------------------------
//       // FETCH SHOPS WITHIN 50 KM
//       // --------------------------------------------------------

//       // final documents =
//       //     await geoCollection.fetchWithin(
//       //   center: center,
//       //   radiusInKm: maximumSearchRadius,
//       //   field: 'geo',

//       //   geopointFrom: (data) {

//       //     final geoData = data['geo'];

//       //     // NEW GEO STRUCTURE

//       //     if (geoData is Map &&
//       //         geoData['geopoint'] is GeoPoint) {
//       //       return geoData['geopoint'] as GeoPoint;
//       //     }

//       //     // OLD GEO STRUCTURE

//       //     if (data['location'] is GeoPoint) {
//       //       return data['location'] as GeoPoint;
//       //     }

//       //     // COORDINATE FIELDS

//       //     final latitude =
//       //         _toDouble(data['latitude']);

//       //     final longitude =
//       //         _toDouble(data['longitude']);

//       //     if (latitude != null &&
//       //         longitude != null &&
//       //         latitude >= -90 &&
//       //         latitude <= 90 &&
//       //         longitude >= -180 &&
//       //         longitude <= 180) {
//       //       return GeoPoint(
//       //         latitude,
//       //         longitude,
//       //       );
//       //     }

//       //     return const GeoPoint(0, 0);
//       //   },

//       //   strictMode: true,
//       // );
//       // --------------------------------------------------------
// // FIRESTORE COLLECTION
// // --------------------------------------------------------

// final collection = _firestore.collection(
//   'auto_spare_parts_shops',
// );

// // --------------------------------------------------------
// // FETCH ALL REGISTERED SHOPS
// // Supports both old and new location structures.
// // --------------------------------------------------------

// final QuerySnapshot<Map<String, dynamic>> snapshot =
//     await collection.get();

// final documents = snapshot.docs;

// debugPrint(
//   'TOTAL SPARE PARTS DOCUMENTS: ${documents.length}',
// );

//       // --------------------------------------------------------
//       // PROCESS SHOPS
//       // --------------------------------------------------------

//       final List<Map<String, dynamic>> shops = [];

//       for (final document in documents) {

//         final data = document.data();

//         if (data == null) {
//           continue;
//         }

//         // ------------------------------------------------------
//         // CHECK ACTIVE STATUS
//         // ------------------------------------------------------

//         final bool hasActiveField =
//             data.containsKey('active') ||
//             data.containsKey('isActive');

//         final bool isShopActive =
//             data['active'] == true ||
//             data['isActive'] == true;

//         // Keep legacy documents without active fields.
//         if (hasActiveField && !isShopActive) {
//           continue;
//         }

//         // ------------------------------------------------------
//         // CATEGORY FILTER
//         // ------------------------------------------------------

//         if (widget.selectedCategory
//                 .trim()
//                 .toLowerCase() !=
//             'all auto spare parts') {

//           final Set<String> shopCategories = {};

//           void addCategories(dynamic rawCategories) {

//             if (rawCategories is List) {
//               for (final item in rawCategories) {

//                 final value = item
//                     .toString()
//                     .trim()
//                     .toLowerCase();

//                 if (value.isNotEmpty) {
//                   shopCategories.add(value);
//                 }
//               }

//             } else if (rawCategories is String) {

//               for (final item in rawCategories.split(',')) {

//                 final value = item
//                     .trim()
//                     .toLowerCase();

//                 if (value.isNotEmpty) {
//                   shopCategories.add(value);
//                 }
//               }
//             }
//           }

//           addCategories(data['categories']);

//           addCategories(data['customCategories']);

//           addCategories(data['category']);

//           final selected =
//               widget.selectedCategory
//                   .trim()
//                   .toLowerCase();

//           if (!shopCategories.contains(selected)) {
//             continue;
//           }
//         }

//         // ------------------------------------------------------
//         // GET SHOP COORDINATES
//         // ------------------------------------------------------

//         double? latitude;

//         double? longitude;

//         final geoData = data['geo'];

//         if (geoData is Map &&
//             geoData['geopoint'] is GeoPoint) {

//           final point =
//               geoData['geopoint'] as GeoPoint;

//           latitude = point.latitude;

//           longitude = point.longitude;
//         }

//         // FALLBACK LOCATION

//         if (latitude == null || longitude == null) {

//           final location = data['location'];

//           if (location is GeoPoint) {
//             latitude = location.latitude;
//             longitude = location.longitude;
//           }
//         }

//         // FALLBACK COORDINATE FIELDS

//         latitude ??= _toDouble(data['latitude']);

//         longitude ??= _toDouble(data['longitude']);

//         // IGNORE INVALID COORDINATES

//         if (latitude == null || longitude == null) {
//           continue;
//         }

//         if (latitude < -90 ||
//             latitude > 90 ||
//             longitude < -180 ||
//             longitude > 180) {
//           continue;
//         }

//         // ------------------------------------------------------
//         // CALCULATE DISTANCE
//         // ------------------------------------------------------

//         final double distanceInMeters =
//             Geolocator.distanceBetween(
//           position.latitude,
//           position.longitude,
//           latitude,
//           longitude,
//         );

//         final double distanceInKm =
//             distanceInMeters / 1000.0;

//         // ------------------------------------------------------
//         // ONLY SHOPS WITHIN 50 KM
//         // ------------------------------------------------------

//         if (distanceInKm > maximumSearchRadius) {
//           continue;
//         }

//         // ------------------------------------------------------
//         // ADD SHOP
//         // ------------------------------------------------------

//         shops.add({
//           'id': document.id,
//           'documentId': document.id,
//           'uid': data['uid']?.toString() ?? document.id,
//           ...data,
//           'latitude': latitude,
//           'longitude': longitude,
//           'distanceKm': distanceInKm,
//         });
//       }

//       // --------------------------------------------------------
//       // SORT NEAREST TO FARTHEST
//       // --------------------------------------------------------

//       shops.sort((a, b) {

//         final double distanceA =
//             (a['distanceKm'] as num).toDouble();

//         final double distanceB =
//             (b['distanceKm'] as num).toDouble();

//         return distanceA.compareTo(distanceB);
//       });

//       if (!mounted) return;

//       // --------------------------------------------------------
//       // UPDATE SHOP LIST
//       // --------------------------------------------------------

//       setState(() {

//         nearbyShops = shops;

//         visibleNearbyShops = [];

//         isLoading = false;

//         hasMore = false;

//         _appendNextPage();

//         errorMessage = null;
//       });

//     } catch (e) {

//       debugPrint(
//         'Auto spare parts loading error: $e',
//       );

//       if (!mounted) return;

//       setState(() {
//         isLoading = false;

//         errorMessage =
//             'Unable to load nearby spare parts shops.';
//       });

//     } finally {
//       fetchingShops = false;
//     }
//   }