// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:jober_india/jober_indiaScreens.dart/spareparts/screen_spare_parts_shoplist.dart';

// class ScreenAutoSparePartsCategory extends StatefulWidget {
//   const ScreenAutoSparePartsCategory({
//     super.key,
//   });

//   @override
//   State<ScreenAutoSparePartsCategory> createState() =>
//       _ScreenAutoSparePartsCategoryState();
// }

// class _ScreenAutoSparePartsCategoryState
//     extends State<ScreenAutoSparePartsCategory> {
//   // ============================================================
//   // COLORS
//   // ============================================================

//   static const Color green =
//      // Color(0xFF198B35);
//       Color(0xFF138808);

//   static const Color darkGreen =
//       Color(0xFF12652F);

//   // ============================================================
//   // CATEGORIES
//   // ============================================================

//   final List<Map<String, dynamic>> categories = [
//     {
//       'name': 'All Auto Spare Parts',
//       'icon': Icons.build_circle_outlined,
//     },
//     {
//       'name': '4 Wheeler Spare Parts',
//       'icon': Icons.directions_car_outlined,
//     },
//     {
//       'name': '3 Wheeler Spare Parts',
//       'icon': Icons.electric_rickshaw_outlined,
//     },
//     {
//       'name': '2 Wheeler Spare Parts',
//       'icon': Icons.two_wheeler_outlined,
//     },
//     {
//       'name': '6 Wheeler Spare Parts',
//       'icon': Icons.local_shipping_outlined,
//     },
//     {
//       'name': 'JCB Spare Parts',
//       'icon': Icons.construction_outlined,
//     },
//   ];

//   // ============================================================
//   // SELECTED CATEGORY
//   // ============================================================

// final FirebaseFirestore _firestore =
//     FirebaseFirestore.instance;

// String? selectedCategory;

// final List<Map<String, dynamic>> defaultCategories = [
//   {
//     'name': 'All Auto Spare Parts',
//     'icon': Icons.build_circle_outlined,
//   },
//   {
//     'name': '4 Wheeler Spare Parts',
//     'icon': Icons.directions_car_outlined,
//   },
//   {
//     'name': '3 Wheeler Spare Parts',
//     'icon': Icons.electric_rickshaw_outlined,
//   },
//   {
//     'name': '2 Wheeler Spare Parts',
//     'icon': Icons.two_wheeler_outlined,
//   },
//   {
//     'name': '6 Wheeler Spare Parts',
//     'icon': Icons.local_shipping_outlined,
//   },
//   {
//     'name': 'JCB Spare Parts',
//     'icon': Icons.construction_outlined,
//   },
// ];
//   // ============================================================
//   // OPEN SHOP LIST
//   // ============================================================

//   void openShopList() {
//     if (selectedCategory == null) {
//       _showMessage(
//         'Please select a spare parts category.',
//       );
//       return;
//     }

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             ScreenAutoSparePartsShopList(
//           selectedCategory:
//               selectedCategory!,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // MESSAGE
//   // ============================================================

//   void _showMessage(
//     String message,
//   ) {
//     ScaffoldMessenger.of(context)
//         .hideCurrentSnackBar();

//     ScaffoldMessenger.of(context)
//         .showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior:
//             SnackBarBehavior.floating,
//       ),
//     );
//   }

//   List<Map<String, dynamic>> buildDynamicCategories(
//   List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
// ) {
//   final Map<String, int> counts = {};
//   final Map<String, String> categoryNames = {};

//   int totalShops = 0;

//   for (final doc in docs) {
//     final data = doc.data();

//     if (data['active'] != true) continue;

//     totalShops++;

//     final rawCategories = data['categories'];

//     if (rawCategories is! List) continue;

//     // Avoid counting the same shop twice
//     // for a category.
//     final Set<String> shopCategories = {};

//     for (final item in rawCategories) {
//       final category = item.toString().trim();

//       if (category.isEmpty) continue;

//       final normalized = category.toLowerCase();

//       if (!shopCategories.add(normalized)) {
//         continue;
//       }

//       categoryNames.putIfAbsent(
//         normalized,
//         () => category,
//       );

//       counts[normalized] =
//           (counts[normalized] ?? 0) + 1;
//     }
//   }

//   final List<Map<String, dynamic>> result = [];

//   // All Auto Spare Parts is always available.
//   result.add({
//     'name': 'All Auto Spare Parts',
//     'icon': Icons.build_circle_outlined,
//     'count': totalShops,
//   });

//   // Add default categories that have at least
//   // one active shop.
//   for (final defaultCategory in defaultCategories) {
//     final name = defaultCategory['name'] as String;

//     if (name == 'All Auto Spare Parts') continue;

//     final normalized = name.toLowerCase();
//     final count = counts[normalized] ?? 0;

//     if (count > 0) {
//       result.add({
//         'name': name,
//         'icon': defaultCategory['icon'],
//         'count': count,
//       });
//     }
//   }

//   // Add user-created categories dynamically.
//   final customNames = categoryNames.entries
//       .where((entry) {
//         return !defaultCategories.any(
//           (category) =>
//               (category['name'] as String)
//                   .toLowerCase() == entry.key,
//         );
//       })
//       .toList();

//   customNames.sort(
//     (a, b) => a.value.toLowerCase().compareTo(
//           b.value.toLowerCase(),
//         ),
//   );

//   for (final entry in customNames) {
//     result.add({
//       'name': entry.value,
//       'icon': Icons.build_outlined,
//       'count': counts[entry.key] ?? 0,
//     });
//   }

//   return result;
// }

//   // ============================================================
//   // CATEGORY CARD
//   // ============================================================

//   Widget buildCategoryCard(
//   Map<String, dynamic> category,
// ) {
//   final String categoryName =
//       category['name'] as String;

//   final IconData categoryIcon =
//       category['icon'] as IconData;

//   final int count =
//       category['count'] as int? ?? 0;

//   final bool isSelected =
//       selectedCategory == categoryName;

//   return InkWell(
//     borderRadius: BorderRadius.circular(18),
//     onTap: () {
//       setState(() {
//         selectedCategory = categoryName;
//       });
//     },
//     child: AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: isSelected
//             ? green.withValues(alpha: 0.08)
//             : Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(
//           color: isSelected
//               ? green
//               : Colors.grey.shade300,
//           width: isSelected ? 2 : 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 58,
//             height: 58,
//             decoration: BoxDecoration(
//               color: isSelected
//                   ? green
//                   : green.withValues(alpha: 0.10),
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Icon(
//               categoryIcon,
//               size: 30,
//               color: isSelected
//                   ? Colors.white
//                   : green,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   categoryName,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   '$count spare parts shops',
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Icon(
//             isSelected
//                 ? Icons.check_circle
//                 : Icons.radio_button_off,
//             color: isSelected
//                 ? green
//                 : Colors.grey.shade400,
//             size: 26,
//           ),
//         ],
//       ),
//     ),
//   );
// }

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

//         elevation: 0,

//         centerTitle: true,

//         title: const Text(
//           'Auto Spare Parts',

//           style: TextStyle(
//             fontWeight:
//                 FontWeight.w700,
//           ),
//         ),
//       ),

//       body: SafeArea(
//         child: Column(
//           children: [
//             // ==================================================
//             // HEADER
//             // ==================================================

//             Container(
//               width: double.infinity,

//               margin:
//                   const EdgeInsets.fromLTRB(
//                 18,
//                 16,
//                 18,
//                 0,
//               ),

//               padding:
//                   const EdgeInsets.all(
//                 20,
//               ),

//               decoration:
//                   BoxDecoration(
//                 gradient:
//                     const LinearGradient(
//                   begin:
//                       Alignment.topLeft,

//                   end:
//                       Alignment.bottomRight,

//                   colors: [
//                     green,
//                     darkGreen,
//                   ],
//                 ),

//                 borderRadius:
//                     BorderRadius.circular(
//                   22,
//                 ),
//               ),

//               child: const Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 29,

//                     backgroundColor:
//                         Colors.white,

//                     child: Icon(
//                       Icons
//                           .build_circle_outlined,

//                       color:
//                           green,

//                       size: 34,
//                     ),
//                   ),

//                   SizedBox(
//                     width: 15,
//                   ),

//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment:
//                           CrossAxisAlignment
//                               .start,

//                       children: [
//                         Text(
//                           'Find Auto Spare Parts',

//                           style:
//                               TextStyle(
//                             color:
//                                 Colors.white,

//                             fontSize:
//                                 19,

//                             fontWeight:
//                                 FontWeight
//                                     .w800,
//                           ),
//                         ),

//                         SizedBox(
//                           height: 5,
//                         ),

//                         Text(
//                           'Select a category to find shops near you',

//                           style:
//                               TextStyle(
//                             color:
//                                 Colors.white70,

//                             fontSize:
//                                 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(
//               height: 24,
//             ),

//             // ==================================================
//             // TITLE
//             // ==================================================

//             const Padding(
//               padding:
//                   EdgeInsets.symmetric(
//                 horizontal: 18,
//               ),

//               child: Align(
//                 alignment:
//                     Alignment.centerLeft,

//                 child: Text(
//                   'Spare Parts Categories',

//                   style: TextStyle(
//                     fontSize: 18,

//                     fontWeight:
//                         FontWeight.w800,
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(
//               height: 14,
//             ),

//             // ==================================================
//             // CATEGORY LIST
//             // ==================================================

//             Expanded(
//   child: StreamBuilder<
//       QuerySnapshot<Map<String, dynamic>>>(
//     stream: _firestore
//         .collection('auto_spare_parts_shops')
//         .where('active', isEqualTo: true)
//         .snapshots(),
//     builder: (context, snapshot) {
//       if (snapshot.hasError) {
//         return const Center(
//           child: Text(
//             'Unable to load spare parts categories.',
//           ),
//         );
//       }

//       if (snapshot.connectionState ==
//               ConnectionState.waiting &&
//           !snapshot.hasData) {
//         return const Center(
//           child: CircularProgressIndicator(
//             color: green,
//           ),
//         );
//       }

//       final docs = snapshot.data?.docs ?? [];

//       final categories =
//           buildDynamicCategories(docs);

//       return ListView.builder(
//         padding: const EdgeInsets.fromLTRB(
//           18,
//           0,
//           18,
//           15,
//         ),
//         itemCount: categories.length,
//         itemBuilder: (context, index) {
//           return buildCategoryCard(
//             categories[index],
//           );
//         },
//       );
//     },
//   ),
// ),

//             // ==================================================
//             // NEXT BUTTON
//             // ==================================================

//             Container(
//               width: double.infinity,

//               padding:
//                   const EdgeInsets.fromLTRB(
//                 18,
//                 12,
//                 18,
//                 24,
//               ),

//               color: Colors.white,

//               child: SizedBox(
//                 height: 56,

//                 child:
//                     ElevatedButton(
//                   onPressed:
//                       selectedCategory ==
//                               null
//                           ? null
//                           : openShopList,

//                   style:
//                       ElevatedButton.styleFrom(
//                     backgroundColor:
//                         green,

//                     foregroundColor:
//                         Colors.white,

//                     disabledBackgroundColor:
//                         Colors.grey.shade300,

//                     elevation: 0,

//                     shape:
//                         RoundedRectangleBorder(
//                       borderRadius:
//                           BorderRadius.circular(
//                         16,
//                       ),
//                     ),
//                   ),

//                   child:
//                       const Row(
//                     mainAxisAlignment:
//                         MainAxisAlignment
//                             .center,

//                     children: [
//                       Text(
//                         'Find Nearby Shops',

//                         style:
//                             TextStyle(
//                           fontSize: 16,

//                           fontWeight:
//                               FontWeight
//                                   .w700,
//                         ),
//                       ),

//                       SizedBox(
//                         width: 10,
//                       ),

//                       Icon(
//                         Icons
//                             .arrow_forward_rounded,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


  // static List<Map<String, dynamic>> buildDynamicCategories(
  //   List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  // ) {
  //   final Map<String, int> categoryCounts = {};

  //   final Map<String, String> categoryNames = {};

  //   int totalActiveShops = 0;

  //   // ----------------------------------------------------------
  //   // ADD BUILT-IN CATEGORIES FIRST
  //   // ----------------------------------------------------------

  //   for (final category in builtInCategories) {
  //     final String name = category['name'] as String;

  //     final String normalized = name.trim().toLowerCase();

  //     categoryNames[normalized] = name;

  //     categoryCounts[normalized] = 0;
  //   }

  //   // ----------------------------------------------------------
  //   // COUNT ACTIVE SHOPS
  //   // ----------------------------------------------------------

  //   for (final shopDocument in docs) {
  //     final shopData = shopDocument.data();

  //     // Only count active shops.
  //     if (shopData['active'] != true) continue;

  //     totalActiveShops++;

  //     final dynamic rawCategories = shopData['categories'];

  //     if (rawCategories is! List) continue;

  //     // One shop should be counted only once
  //     // for each category.
  //     final Set<String> shopCategories = {};

  //     for (final rawCategory in rawCategories) {
  //       if (rawCategory is! String) continue;

  //       final String category = rawCategory.trim();

  //       if (category.isEmpty) continue;

  //       final String normalized = category.toLowerCase();

  //       shopCategories.add(normalized);

  //       // Preserve original category spelling.
  //       categoryNames.putIfAbsent(
  //         normalized,
  //         () => category,
  //       );
  //     }

  //     for (final normalized in shopCategories) {
  //       categoryCounts[normalized] =
  //           (categoryCounts[normalized] ?? 0) + 1;
  //     }
  //   }

  //   // ----------------------------------------------------------
  //   // CREATE FINAL CATEGORY LIST
  //   // ----------------------------------------------------------

  //   final List<Map<String, dynamic>> result = [];

  //   // ----------------------------------------------------------
  //   // ALL AUTO SPARE PARTS
  //   // ----------------------------------------------------------

  //   result.add({
  //     'name': 'All Auto Spare Parts',
  //     'icon': Icons.build_circle_outlined,
  //     'count': totalActiveShops,
  //     'isBuiltIn': true,
  //   });

  //   // ----------------------------------------------------------
  //   // ADD ALL BUILT-IN CATEGORIES
  //   // EVEN IF COUNT IS ZERO
  //   // ----------------------------------------------------------

  //   for (final defaultCategory in builtInCategories) {
  //     final String name = defaultCategory['name'] as String;

  //     if (name == 'All Auto Spare Parts') continue;

  //     final String normalized = name.toLowerCase();

  //     result.add({
  //       'name': name,
  //       'icon': defaultCategory['icon'],
  //       'count': categoryCounts[normalized] ?? 0,
  //       'isBuiltIn': true,
  //     });
  //   }

  //   // ----------------------------------------------------------
  //   // FIND CUSTOM CATEGORIES
  //   // ----------------------------------------------------------

  //   final Set<String> builtInNames = builtInCategories
  //       .map(
  //         (category) =>
  //             (category['name'] as String).toLowerCase(),
  //       )
  //       .toSet();

  //   final List<MapEntry<String, String>> customCategories =
  //       categoryNames.entries
  //           .where(
  //             (entry) => !builtInNames.contains(entry.key),
  //           )
  //           .toList();

  //   // Alphabetical order.
  //   customCategories.sort(
  //     (a, b) => a.value.toLowerCase().compareTo(
  //           b.value.toLowerCase(),
  //         ),
  //   );

  //   // ----------------------------------------------------------
  //   // ADD CUSTOM CATEGORIES
  //   // ----------------------------------------------------------

  //   for (final entry in customCategories) {
  //     result.add({
  //       'name': entry.value,
  //       'icon': Icons.build_outlined,
  //       'count': categoryCounts[entry.key] ?? 0,
  //       'isBuiltIn': false,
  //     });
  //   }

  //   return result;
  // }
  
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jober_india/jober_indiaScreens.dart/spareparts/screen_spare_parts_shoplist.dart';

// class ScreenAutoSparePartsCategory extends StatelessWidget {
//   const ScreenAutoSparePartsCategory({
//     super.key,
//   });

//   // ============================================================
//   // COLORS
//   // ============================================================

//   static const Color green = Color(0xFF138808);
//   static const Color darkGreen = Color(0xFF12652F);

//   // ============================================================
//   // BUILT-IN CATEGORIES
//   // ============================================================

//   static const List<Map<String, dynamic>> builtInCategories = [
//     {
//       'name': 'All Auto Spare Parts',
//       'icon': Icons.build_circle_outlined,
//     },
//     {
//       'name': '4 Wheeler Spare Parts',
//       'icon': Icons.directions_car_outlined,
//     },
//     {
//       'name': '3 Wheeler Spare Parts',
//       'icon': Icons.electric_rickshaw_outlined,
//     },
//     {
//       'name': '2 Wheeler Spare Parts',
//       'icon': Icons.two_wheeler_outlined,
//     },
//     {
//       'name': '6 Wheeler Spare Parts',
//       'icon': Icons.local_shipping_outlined,
//     },
//     {
//       'name': 'JCB Spare Parts',
//       'icon': Icons.construction_outlined,
//     },
//   ];

//   // ============================================================
//   // FIRESTORE
//   // ============================================================

//   static final FirebaseFirestore _firestore =
//       FirebaseFirestore.instance;

//   // ============================================================
//   // OPEN SHOP LIST
//   // ============================================================

//   static void openShopList(
//     BuildContext context,
//     String category,
//   ) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ScreenAutoSparePartsShopList(
//           selectedCategory: category,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD DYNAMIC CATEGORIES
//   // // ============================================================

//   static List<Map<String, dynamic>> buildDynamicCategories(
//   List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
// ) {
//   final Map<String, int> categoryCounts = {};
//   final Map<String, String> categoryNames = {};

//   int totalActiveShops = 0;

//   // Add built-in categories first.
//   for (final category in builtInCategories) {
//     final String name = category['name'] as String;
//     final String normalized = name.trim().toLowerCase();

//     categoryNames[normalized] = name;
//     categoryCounts[normalized] = 0;
//   }

//   // Read active shops and count their categories.
//   for (final shopDocument in docs) {
//     final shopData = shopDocument.data();

//     //if (shopData['active'] != true) continue;

//     totalActiveShops++;

//     // Combine categories and customCategories.
//     final Set<String> shopCategories = {};

//     void addCategories(dynamic rawCategories) {
//       if (rawCategories is! List) return;

//       for (final rawCategory in rawCategories) {
//         if (rawCategory is! String) continue;

//         final String category = rawCategory.trim();

//         if (category.isEmpty) continue;

//         shopCategories.add(category.toLowerCase());

//         categoryNames.putIfAbsent(
//           category.toLowerCase(),
//           () => category,
//         );
//       }
//     }

//     addCategories(shopData['categories']);
//     addCategories(shopData['customCategories']);

//     // Count this shop only once for each category.
//     for (final normalized in shopCategories) {
//       categoryCounts[normalized] =
//           (categoryCounts[normalized] ?? 0) + 1;
//     }
//   }

//   final List<Map<String, dynamic>> result = [];

//   // All shops category.
//   result.add({
//     'name': 'All Auto Spare Parts',
//     'icon': Icons.build_circle_outlined,
//     'count': totalActiveShops,
//     'isBuiltIn': true,
//   });

//   // Built-in categories.
//   for (final defaultCategory in builtInCategories) {
//     final String name = defaultCategory['name'] as String;

//     if (name == 'All Auto Spare Parts') continue;

//     final String normalized = name.trim().toLowerCase();

//     result.add({
//       'name': name,
//       'icon': defaultCategory['icon'],
//       'count': categoryCounts[normalized] ?? 0,
//       'isBuiltIn': true,
//     });
//   }

//   // Find custom categories.
//   final Set<String> builtInNames = builtInCategories
//       .map(
//         (category) =>
//             (category['name'] as String).trim().toLowerCase(),
//       )
//       .toSet();

//   final List<MapEntry<String, String>> customCategories =
//       categoryNames.entries
//           .where((entry) => !builtInNames.contains(entry.key))
//           .toList();

//   customCategories.sort(
//     (a, b) => a.value.toLowerCase().compareTo(
//           b.value.toLowerCase(),
//         ),
//   );

//   // Add custom categories with their shop counts.
//   for (final entry in customCategories) {
//     result.add({
//       'name': entry.value,
//       'icon': Icons.build_outlined,
//       'count': categoryCounts[entry.key] ?? 0,
//       'isBuiltIn': false,
//     });
//   }

//   return result;
// }

//   // ============================================================
//   // CATEGORY CARD
//   // ============================================================

//   static Widget buildCategoryCard(
//     BuildContext context,
//     Map<String, dynamic> category,
//   ) {
//     final String categoryName =
//         category['name'] as String;

//     final IconData categoryIcon =
//         category['icon'] as IconData;

//     final int count =
//         category['count'] as int? ?? 0;

//     final bool isBuiltIn =
//         category['isBuiltIn'] as bool? ?? false;

//     return InkWell(
//       borderRadius: BorderRadius.circular(14),

//       onTap: () {
//         openShopList(
//           context,
//           categoryName,
//         );
//       },

//       child: Container(
//         padding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 16,
//         ),

//         decoration: BoxDecoration(
//           color: const Color(0xFFF9F9F9),

//           borderRadius: BorderRadius.circular(14),

//           border: Border.all(
//             color: const Color(0xFFEAEAEA),
//           ),
//         ),

//         child: Row(
//           children: [
//             // --------------------------------------------------
//             // ICON
//             // --------------------------------------------------

//             Container(
//               height: 44,
//               width: 44,

//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFF7EF),

//                 borderRadius: BorderRadius.circular(12),
//               ),

//               child: Icon(
//                 categoryIcon,
//                 color: green,
//                 size: 25,
//               ),
//             ),

//             const SizedBox(width: 12),

//             // --------------------------------------------------
//             // CATEGORY NAME
//             // --------------------------------------------------

//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,

//                 children: [
//                   Text(
//                     categoryName,

//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),

//                   const SizedBox(height: 4),

//                   Text(
//                     isBuiltIn
//                         ? 'Spare parts category'
//                         : 'Custom category',

//                     style: const TextStyle(
//                       fontSize: 11,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // --------------------------------------------------
//             // SHOP COUNT
//             // --------------------------------------------------

//             Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 11,
//                 vertical: 7,
//               ),

//               decoration: BoxDecoration(
//                 color: green.withValues(alpha: 0.10),

//                 borderRadius: BorderRadius.circular(20),
//               ),

//               child: Text(
//                 '$count',

//                 style: const TextStyle(
//                   color: green,
//                   fontSize: 13,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),

//             const SizedBox(width: 8),

//             // --------------------------------------------------
//             // ARROW
//             // --------------------------------------------------

//             const Icon(
//               Icons.arrow_forward_ios,
//               size: 15,
//               color: Colors.grey,
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

//       // --------------------------------------------------------
//       // APP BAR
//       // --------------------------------------------------------

//       appBar: AppBar(
//         backgroundColor: darkGreen,
//         foregroundColor: Colors.white,
//         elevation: 0,

//         title: const Text(
//           'Auto Spare Parts',

//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),

//       // --------------------------------------------------------
//       // FIRESTORE CATEGORY STREAM
//       // --------------------------------------------------------

//       body: StreamBuilder<
//           QuerySnapshot<Map<String, dynamic>>>(
//         stream: _firestore
//             .collection('auto_spare_parts_shops')
//             //.where('active', isEqualTo: true)
//             .snapshots(),

//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return const Center(
//               child: Text(
//                 'Unable to load spare parts categories.',
//               ),
//             );
//           }

//           if (snapshot.connectionState ==
//                   ConnectionState.waiting &&
//               !snapshot.hasData) {
//             return const Center(
//               child: CircularProgressIndicator(
//                 color: green,
//               ),
//             );
//           }

//           final shopDocuments =
//               snapshot.data?.docs ?? [];

//           final displayCategories =
//               buildDynamicCategories(shopDocuments);

//           if (displayCategories.isEmpty) {
//             return const Center(
//               child: Text(
//                 'No categories available.',
//               ),
//             );
//           }

//           // ----------------------------------------------------
//           // CATEGORY LIST
//           // ----------------------------------------------------

//           return ListView.separated(
//             padding: const EdgeInsets.symmetric(
//               vertical: 12,
//               horizontal: 12,
//             ),

//             itemCount: displayCategories.length,

//             separatorBuilder: (_, __) =>
//                 const SizedBox(height: 10),

//             itemBuilder: (context, index) {
//               return buildCategoryCard(
//                 context,
//                 displayCategories[index],
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

class ScreenAutoSparePartsCategory extends StatelessWidget {
  const ScreenAutoSparePartsCategory({super.key});

  static const Color green = Color(0xFF138808);
  static const Color darkGreen = Color(0xFF12652F);

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // BUILT-IN CATEGORIES

  static const List<String> builtInCategories = [
    'All Auto Spare Parts',
    '4 Wheeler Spare Parts',
    '3 Wheeler Spare Parts',
    '2 Wheeler Spare Parts',
    '6 Wheeler Spare Parts',
    'JCB Spare Parts',
  ];

  // CATEGORY ICON

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'All Auto Spare Parts':
        return Icons.build_circle_outlined;

      case '4 Wheeler Spare Parts':
        return Icons.directions_car_outlined;

      case '3 Wheeler Spare Parts':
        return Icons.electric_rickshaw_outlined;

      case '2 Wheeler Spare Parts':
        return Icons.two_wheeler_outlined;

      case '6 Wheeler Spare Parts':
        return Icons.local_shipping_outlined;

      case 'JCB Spare Parts':
        return Icons.construction_outlined;

      default:
        return Icons.build_outlined;
    }
  }

  // OPEN SHOP LIST

  static void openShopList(
    BuildContext context,
    String category,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenAutoSparePartsShopList(
          selectedCategory: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Hive.box('settings');

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Auto Spare Parts',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ValueListenableBuilder<Box>(
        valueListenable: settings.listenable(
          keys: ['autoSparePartsCustomCategories'],
        ),

        builder: (context, box, child) {

          // final List<String> localCategories =
          //     List<String>.from(
          //   box.get(
          //     'autoSparePartsCustomCategories',
          //     defaultValue: <String>[],
          //   ),?? <String>[],
          // );
          final List<String> localCategories =
    List<String>.from(
  box.get(
    'autoSparePartsCustomCategories',
    defaultValue: <String>[],
  ) ?? <String>[],
);

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('auto_spare_parts_shops')
                .snapshots(),

            builder: (context, snapshot) {

              if (snapshot.hasError) {
                debugPrint(
                  'SPARE PARTS CATEGORY ERROR: ${snapshot.error}',
                );
              }

              if (snapshot.connectionState ==
                      ConnectionState.waiting &&
                  !snapshot.hasData) {
                // Local categories can still be displayed.
                if (localCategories.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: green,
                    ),
                  );
                }
              }

              final shopDocuments =
                  snapshot.data?.docs ?? [];

              final Map<String, int> categoryCounts = {};

              final Map<String, String> categoryNames = {};

              // ADD BUILT-IN CATEGORIES

              for (final category in builtInCategories) {
                final normalized =
                    category.trim().toLowerCase();

                categoryNames[normalized] = category;
                categoryCounts[normalized] = 0;
              }

              // READ FIRESTORE CATEGORIES

              int totalShops = 0;

              for (final document in shopDocuments) {
                final shopData = document.data();

                totalShops++;

                final Set<String> shopCategories = {};

                void addCategories(dynamic rawCategories) {
                  if (rawCategories is! List) return;

                  for (final rawCategory in rawCategories) {
                    if (rawCategory is! String) continue;

                    final category = rawCategory.trim();

                    if (category.isEmpty) continue;

                    final normalized =
                        category.toLowerCase();

                    shopCategories.add(normalized);

                    categoryNames.putIfAbsent(
                      normalized,
                      () => category,
                    );
                  }
                }

                addCategories(shopData['categories']);
                addCategories(shopData['customCategories']);

                for (final normalized in shopCategories) {
                  categoryCounts[normalized] =
                      (categoryCounts[normalized] ?? 0) + 1;
                }
              }

              // ADD HIVE CUSTOM CATEGORIES

              for (final category in localCategories) {
                final name = category.trim();

                if (name.isEmpty) continue;

                final normalized = name.toLowerCase();

                categoryNames.putIfAbsent(
                  normalized,
                  () => name,
                );

                categoryCounts.putIfAbsent(
                  normalized,
                  () => 0,
                );
              }

              // BUILD DISPLAY LIST

              final List<String> customCategoryKeys =
                  categoryNames.keys
                      .where(
                        (key) => !builtInCategories.any(
                          (builtIn) =>
                              builtIn.toLowerCase() == key,
                        ),
                      )
                      .toList()
                    ..sort(
                      (a, b) => categoryNames[a]!
                          .toLowerCase()
                          .compareTo(
                            categoryNames[b]!.toLowerCase(),
                          ),
                    );

              final List<String> displayCategories = [
                ...builtInCategories,
                ...customCategoryKeys.map(
                  (key) => categoryNames[key]!,
                ),
              ];

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),

                itemCount: displayCategories.length,

                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),

                itemBuilder: (context, index) {

                  final category =
                      displayCategories[index];

                  final normalized =
                      category.trim().toLowerCase();

                  final count =
                      normalized ==
                              'all auto spare parts'
                          ? totalShops
                          : categoryCounts[normalized] ?? 0;

                  final isBuiltIn =
                      builtInCategories.any(
                    (item) =>
                        item.toLowerCase() == normalized,
                  );

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),

                    onTap: () {
                      openShopList(
                        context,
                        category,
                      );
                    },

                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),

                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFEAEAEA),
                        ),
                      ),

                      child: Row(
                        children: [

                          // ICON

                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7EF),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),

                            child: Icon(
                              getCategoryIcon(category),
                              color: green,
                              size: 25,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // CATEGORY NAME

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  isBuiltIn
                                      ? 'Spare parts category'
                                      : 'Custom category',

                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // SHOP COUNT

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),

                            decoration: BoxDecoration(
                              color: green.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),

                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: green,
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
          );
        },
      ),
    );
  }
}