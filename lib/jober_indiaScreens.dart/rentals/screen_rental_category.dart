import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/rentals/screen_rentals_nearby.dart';


class RentalCategoryScreen extends StatefulWidget {
  const RentalCategoryScreen({super.key});

  @override
  State<RentalCategoryScreen> createState() =>
      _RentalCategoryScreenState();
}

class _RentalCategoryScreenState
    extends State<RentalCategoryScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _loading = true;
// ============================================================
// DEFAULT RENTAL CATEGORIES
// Keep these identical to the registration categories.
// ============================================================

final List<String> _defaultCategories = [
  'Premium Car Rent',
  'Car Rent',
  'Bike Rent',
  'Car & Bike Rent',
  'Flat',
  'House',
  'Shops',
  'Tools',
  'Dress',
];

List<String> _categories = [];

Map<String, int> _categoryCounts = {};
StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _rentalSubscription;

@override
void initState() {
  super.initState();
  _loadCategories();
}

// ============================================================
// REAL-TIME RENTAL CATEGORIES AND COUNTS
// ============================================================

void _loadCategories() {
  _rentalSubscription?.cancel();

  setState(() {
    _loading = true;
  });

  _rentalSubscription = _firestore
      .collection('rentals')
      .snapshots()
      .listen(
    (snapshot) {
      final Map<String, String> categoryNames = {};
      final Map<String, int> counts = {};

      // --------------------------------------------------------
      // 1. ADD BUILT-IN CATEGORIES
      // --------------------------------------------------------

      for (final category in _defaultCategories) {
        final key = category.trim().toLowerCase();

        categoryNames[key] = category.trim();
        counts[key] = 0;
      }

      // --------------------------------------------------------
      // 2. READ ACTIVE AND REGISTERED RENTAL PROFILES
      // --------------------------------------------------------

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Ignore logged-out or inactive profiles.
        if (data['isActive'] != true ||
            data['isRegistered'] != true) {
          continue;
        }

        final Set<String> documentCategories = {};

        final dynamic categories = data['categories'];

        if (categories is List) {
          for (final item in categories) {
            final category = item.toString().trim();

            if (category.isNotEmpty) {
              documentCategories.add(category);
            }
          }
        } else if (categories is String) {
          final category = categories.trim();

          if (category.isNotEmpty) {
            documentCategories.add(category);
          }
        }

        // Support older documents using a single category field.
        final dynamic singleCategory = data['category'];

        if (singleCategory is String &&
            singleCategory.trim().isNotEmpty) {
          documentCategories.add(singleCategory.trim());
        }

        // ------------------------------------------------------
        // 3. COUNT EACH RENTAL PROFILE ONCE PER CATEGORY
        // ------------------------------------------------------

        for (final category in documentCategories) {
          final key = category.toLowerCase();

          categoryNames.putIfAbsent(
            key,
            () => category,
          );

          counts[key] = (counts[key] ?? 0) + 1;
        }
      }

      // --------------------------------------------------------
      // 4. KEEP BUILT-IN CATEGORIES FIRST
      // --------------------------------------------------------

      final List<String> customCategories =
          categoryNames.entries
              .where((entry) {
                return !_defaultCategories.any(
                  (defaultCategory) =>
                      defaultCategory.toLowerCase() == entry.key,
                );
              })
              .map((entry) => entry.value)
              .toList();

      customCategories.sort(
        (a, b) => a.toLowerCase().compareTo(
          b.toLowerCase(),
        ),
      );

      final List<String> finalCategories = [
        ..._defaultCategories,
        ...customCategories,
      ];

      if (!mounted) return;

      setState(() {
        _categories = finalCategories;
        _categoryCounts = counts;
        _loading = false;
      });
    },
    onError: (error) {
      debugPrint('Rental category listener error: $error');

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    },
  );
}

@override
void dispose() {
  _rentalSubscription?.cancel();
  super.dispose();
}

  // ============================================================
  // CATEGORY ICON
  // ============================================================

  IconData _getCategoryIcon(
    String category,
  ) {
    final String value =
        category.toLowerCase();

    if (value.contains('car')) {
      return Icons.directions_car;
    }

    if (value.contains('van')) {
      return Icons.airport_shuttle;
    }

    if (value.contains('bike') ||
        value.contains('motorcycle')) {
      return Icons.two_wheeler;
    }

    if (value.contains('auto')) {
      return Icons.electric_rickshaw;
    }

    if (value.contains('lorry') ||
        value.contains('truck')) {
      return Icons.local_shipping;
    }

    if (value.contains('tipper')) {
      return Icons.local_shipping_outlined;
    }

    if (value.contains('jcb') ||
        value.contains('excavat')) {
      return Icons.construction;
    }

    if (value.contains('tractor')) {
      return Icons.agriculture;
    }

    if (value.contains('machine') ||
        value.contains('machinery')) {
      return Icons.precision_manufacturing;
    }

    if (value.contains('house') ||
        value.contains('home')) {
      return Icons.home_work_outlined;
    }

    if (value.contains('shop')) {
      return Icons.storefront;
    }

    if (value.contains('office')) {
      return Icons.business;
    }

    if (value.contains('camera') ||
        value.contains('photo')) {
      return Icons.camera_alt;
    }

    if (value.contains('tent')) {
      return Icons.cabin;
    }

    if (value.contains('generator')) {
      return Icons.power;
    }

    if (value.contains('sound') ||
        value.contains('speaker')) {
      return Icons.speaker;
    }

    if (value.contains('event')) {
      return Icons.event;
    }

    return Icons.category;
  }

  // ============================================================
  // OPEN CATEGORY
  // ============================================================

  void _openCategory(
    String category,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RentalNearbyScreen(
          category: category,
        ),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            const Color(0xFF078A18),
        foregroundColor: Colors.white,
        title: const Text(
          'Rentals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                22,
                20,
                22,
              ),
              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFF078A18),
                borderRadius:
                    BorderRadius.only(
                  bottomLeft:
                      Radius.circular(28),
                  bottomRight:
                      Radius.circular(28),
                ),
              ),
              child: const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find a Rental',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Choose a rental category',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _buildCategoryBody(),
            ),
          ],
        ),
      ),
    );
  }
  
Widget _buildCategoryBody() {
  if (_loading) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF078A18),
      ),
    );
  }

  if (_categories.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.category_outlined,
            size: 65,
            color: Colors.grey,
          ),
          const SizedBox(height: 15),
          const Text(
            'No rental categories found.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _loadCategories,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF078A18),
              foregroundColor: Colors.white,
            ),
            child: const Text('TRY AGAIN'),
          ),
        ],
      ),
    );
  }

  return RefreshIndicator(
  color: const Color(0xFF078A18),
  
  onRefresh: () async {
  _loadCategories();
  await Future<void>.delayed(
    const Duration(milliseconds: 500),
  );
},
  child: GridView.builder(
    // Keep your existing GridView settings here.
      padding: const EdgeInsets.fromLTRB(
        16, 4, 16, 25,
      ),
      itemCount: _categories.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 13,
        mainAxisSpacing: 13,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final category = _categories[index];

        return _buildCategoryCard(category);
      },
    ),
  );
}

// ============================================================
// CATEGORY CARD WITH RENTAL COUNT
// ============================================================

Widget _buildCategoryCard(String category) {
  final int count =
      _categoryCounts[category.trim().toLowerCase()] ?? 0;

  return Material(
    color: Colors.white,
    elevation: 2,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        _openCategory(category);
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                _getCategoryIcon(category),
                size: 31,
                color: const Color(0xFF078A18),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              category,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202124),
              ),
            ),

            const SizedBox(height: 5),

            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$count ${count == 1 ? 'Rental' : 'Rentals'} Available',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: count > 0
                      ? const Color(0xFF078A18)
                      : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}


     // child: Column(
        //   mainAxisAlignment:
        //       MainAxisAlignment.center,
        //   children: [
        //     const Icon(
        //       Icons.category_outlined,
        //       size: 65,
        //       color: Colors.grey,
        //     ),
        //     const SizedBox(height: 15),
        //     const Text(
        //       'No rental categories found.',
        //       style: TextStyle(
        //         fontSize: 18,
        //         fontWeight: FontWeight.bold,
        //       ),
        //     ),
        //     const SizedBox(height: 15),
        //     ElevatedButton(
        //       onPressed: _loadCategories,
        //       style:
        //           ElevatedButton.styleFrom(
        //         backgroundColor:
        //             const Color(0xFF078A18),
        //         foregroundColor:
        //             Colors.white,
        //       ),
        //       child:
        //           const Text('TRY AGAIN'),
        //     ),
        //   ],
        // ),

//   Widget _buildCategoryBody() {
//     if (_loading) {
//       return const Center(
//         child: CircularProgressIndicator(
//           color: Color(0xFF078A18),
//         ),
//       );
//     }

//     if (_categories.isEmpty) {
//       return Center(
   
//         child: Padding(
//   padding: const EdgeInsets.all(12),
//   child: Column(
//     mainAxisAlignment: MainAxisAlignment.center,
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       Container(
//         width: 58,
//         height: 58,
//         decoration: BoxDecoration(
//           color: const Color(0xFFE8F5E9),
//           borderRadius: BorderRadius.circular(18),
//         ),
//         child: Icon(
//           _getCategoryIcon(category),
//           size: 31,
//           color: const Color(0xFF078A18),
//         ),
//       ),

//       const SizedBox(height: 10),

//       Text(
//         category,
//         textAlign: TextAlign.center,
//         maxLines: 2,
//         overflow: TextOverflow.ellipsis,
//         style: const TextStyle(
//           fontSize: 15,
//           fontWeight: FontWeight.w700,
//           color: Color(0xFF202124),
//         ),
//       ),

//       const SizedBox(height: 5),

//       FittedBox(
//         fit: BoxFit.scaleDown,
//         child: Text(
//           '$count ${count == 1 ? 'Rental' : 'Rentals'} Available',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w600,
//             color: count > 0
//                 ? const Color(0xFF078A18)
//                 : Colors.grey.shade500,
//           ),
//         ),
//       ),
//     ],
//   ),
// ),
//       );
//     }

//     return RefreshIndicator(
//       color: const Color(0xFF078A18),
//       onRefresh: _loadCategories,
//       child: GridView.builder(
//         padding:
//             const EdgeInsets.fromLTRB(
//           16,
//           4,
//           16,
//           25,
//         ),
//         itemCount: _categories.length,
//         // gridDelegate:
//         //     const SliverGridDelegateWithFixedCrossAxisCount(
//         //   crossAxisCount: 2,
//         //   crossAxisSpacing: 13,
//         //   mainAxisSpacing: 13,
//         //   childAspectRatio: 1.15,
//         // ),
//         gridDelegate:
//     const SliverGridDelegateWithFixedCrossAxisCount(
//   crossAxisCount: 2,
//   crossAxisSpacing: 13,
//   mainAxisSpacing: 13,
//   childAspectRatio: 1.0,
// ),
//         itemBuilder:
//             (context, index) {
//           final category =
//               _categories[index];

//           return _buildCategoryCard(
//             category,
//           );
//         },
//       ),
//     );
//   }


// Widget _buildCategoryCard(String category) {
//   final int count =
//       _categoryCounts[category.toLowerCase()] ?? 0;

//   return Material(
//     color: Colors.white,
//     elevation: 2,
//     borderRadius: BorderRadius.circular(20),
//     child: InkWell(
//       borderRadius: BorderRadius.circular(20),
//       onTap: () {
//         _openCategory(category);
//       },
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 58,
//               height: 58,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFE8F5E9),
//                 borderRadius: BorderRadius.circular(18),
//               ),
//               child: Icon(
//                 _getCategoryIcon(category),
//                 size: 31,
//                 color: const Color(0xFF078A18),
//               ),
//             ),

//             const SizedBox(height: 12),

//             Text(
//               category,
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w700,
//                 color: Color(0xFF202124),
//               ),
//             ),

//             const SizedBox(height: 6),

//             Text(
//               '$count ${count == 1 ? 'Rental' : 'Rentals'} Available',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: count > 0
//                     ? const Color(0xFF078A18)
//                     : Colors.grey.shade500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }


//   @override
//   void initState() {
//     super.initState();
//     _loadCategories();
//   }
// // ============================================================
// // LOAD RENTAL CATEGORIES AND COUNTS
// // ============================================================

// Future<void> _loadCategories() async {
//   try {
//     final snapshot = await _firestore
//         .collection('rentals')
//         .get();

//     final Map<String, String> categoryNames = {};
//     final Map<String, int> counts = {};

//     // --------------------------------------------------------
//     // 1. ADD BUILT-IN CATEGORIES
//     // --------------------------------------------------------

//     for (final category in _defaultCategories) {
//       final key = category.trim().toLowerCase();

//       categoryNames[key] = category.trim();
//       counts[key] = 0;
//     }

//     // --------------------------------------------------------
//     // 2. READ ALL REGISTERED RENTAL PROFILES
//     // --------------------------------------------------------

//     // for (final doc in snapshot.docs) {
//     //   final data = doc.data();

//     //   final Set<String> documentCategories = {};

// for (final doc in snapshot.docs) {
//   final data = doc.data();

//   // ========================================================
//   // IGNORE LOGGED-OUT / INACTIVE RENTAL PROFILES
//   // ========================================================

//   if (data['isActive'] != true ||
//       data['isRegistered'] != true) {
//     continue;
//   }

//   final Set<String> documentCategories = {};
//       final dynamic categories = data['categories'];

//       if (categories is List) {
//         for (final item in categories) {
//           final category = item.toString().trim();

//           if (category.isNotEmpty) {
//             documentCategories.add(category);
//           }
//         }
//       } else if (categories is String) {
//         final category = categories.trim();

//         if (category.isNotEmpty) {
//           documentCategories.add(category);
//         }
//       }

//       // Support older documents using a single category field.
//       final dynamic singleCategory = data['category'];

//       if (singleCategory is String &&
//           singleCategory.trim().isNotEmpty) {
//         documentCategories.add(singleCategory.trim());
//       }

//       // ------------------------------------------------------
//       // 3. ADD CUSTOM CATEGORIES AND INCREASE COUNTS
//       // ------------------------------------------------------

//       for (final category in documentCategories) {
//         final key = category.toLowerCase();

//         categoryNames.putIfAbsent(
//           key,
//           () => category,
//         );

//         counts[key] = (counts[key] ?? 0) + 1;
//       }
//     }

//     // --------------------------------------------------------
//     // 4. KEEP BUILT-IN CATEGORIES FIRST
//     // --------------------------------------------------------

//     final List<String> customCategories =
//         categoryNames.entries
//             .where((entry) {
//               return !_defaultCategories.any(
//                 (defaultCategory) =>
//                     defaultCategory.toLowerCase() ==
//                     entry.key,
//               );
//             })
//             .map((entry) => entry.value)
//             .toList();

//     customCategories.sort(
//       (a, b) => a.toLowerCase().compareTo(
//         b.toLowerCase(),
//       ),
//     );

//     final List<String> finalCategories = [
//       ..._defaultCategories,
//       ...customCategories,
//     ];

//     if (!mounted) return;

//     setState(() {
//       _categories = finalCategories;
//       _categoryCounts = counts;
//       _loading = false;
//     });
//   } catch (e) {
//     debugPrint('Error loading rental categories: $e');

//     if (!mounted) return;

//     setState(() {
//       _loading = false;
//     });
//   }
// }