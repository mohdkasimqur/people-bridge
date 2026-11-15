import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/CorierService/corrier_nearby.dart';

// class CourierVehicleCategory {
//   final String id;
//   final String name;
//   final String iconType;
//   final bool isCustom;

//   const CourierVehicleCategory({
//     required this.id,
//     required this.name,
//     required this.iconType,
//     this.isCustom = false,
//   });

//   factory CourierVehicleCategory.fromMap(
//     String id,
//     Map<String, dynamic> map,
//   ) {
//     return CourierVehicleCategory(
//       id: id,
//       name: (map['name'] ?? '').toString(),
//       iconType: (map['iconType'] ?? 'default').toString(),
//       isCustom: map['isCustom'] == true,
//     );
//   }
// }

// class ScreenCourierCategories extends StatefulWidget {
//   const ScreenCourierCategories({
//     super.key,
//   });

//   @override
//   State<ScreenCourierCategories> createState() =>
//       _ScreenCourierCategoriesState();
// }

// class _ScreenCourierCategoriesState
//     extends State<ScreenCourierCategories> {
//   final FirebaseFirestore _firestore =
//       FirebaseFirestore.instance;

//   final TextEditingController searchController =
//       TextEditingController();

//   List<CourierVehicleCategory> allCategories = [];

//   List<CourierVehicleCategory> filteredCategories = [];

//   bool isLoading = true;

//   bool hasError = false;

//   @override
//   void initState() {
//     super.initState();

//     searchController.addListener(
//       _filterCategories,
//     );

//     _loadCategories();
//   }

//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }

//   // ============================================================
//   // DEFAULT CATEGORIES
//   // ============================================================

//   final List<CourierVehicleCategory>
//       defaultCategories = const [
//     CourierVehicleCategory(
//       id: 'bike',
//       name: 'Bike',
//       iconType: 'bike',
//     ),
//     CourierVehicleCategory(
//       id: 'auto',
//       name: 'Auto',
//       iconType: 'auto',
//     ),
//     CourierVehicleCategory(
//       id: 'car',
//       name: 'Car',
//       iconType: 'car',
//     ),
//     CourierVehicleCategory(
//       id: 'van',
//       name: 'Van',
//       iconType: 'van',
//     ),
//     CourierVehicleCategory(
//       id: 'mini_truck',
//       name: 'Mini Truck',
//       iconType: 'mini_truck',
//     ),
//     CourierVehicleCategory(
//       id: 'truck',
//       name: 'Truck',
//       iconType: 'truck',
//     ),
//     CourierVehicleCategory(
//       id: 'cycle',
//       name: 'Cycle',
//       iconType: 'cycle',
//     ),
//   ];

//   // ============================================================
//   // LOAD CATEGORIES
//   // ============================================================

//   Future<void> _loadCategories() async {
//     if (!mounted) {
//       return;
//     }

//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });

//     try {
//       final snapshot = await _firestore
//           .collection('courierVehicleCategories')
//           .orderBy('name')
//         //  .limit(100)
//           .get();

//       final List<CourierVehicleCategory>
//           categories = [];

//       categories.addAll(defaultCategories);

//       for (final doc in snapshot.docs) {
//         final data = doc.data();

//         final name =
//             (data['name'] ?? '')
//                 .toString()
//                 .trim();

//         if (name.isEmpty) {
//           continue;
//         }

//         final category =
//             CourierVehicleCategory.fromMap(
//           doc.id,
//           data,
//         );

//         final duplicate =
//             categories.any(
//           (item) =>
//               item.name.toLowerCase() ==
//               category.name.toLowerCase(),
//         );

//         if (!duplicate) {
//           categories.add(category);
//         }
//       }

//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         allCategories = categories;
//         filteredCategories =
//             List.from(categories);
//         isLoading = false;
//       });
//     } catch (e) {
//       debugPrint(
//         'Courier category error: $e',
//       );

//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         allCategories =
//             List.from(defaultCategories);

//         filteredCategories =
//             List.from(defaultCategories);

//         hasError = true;
//         isLoading = false;
//       });
//     }
//   }

//   // ============================================================
//   // SEARCH
//   // ============================================================

//   void _filterCategories() {
//     final query =
//         searchController.text
//             .trim()
//             .toLowerCase();

//     if (!mounted) {
//       return;
//     }

//     if (query.isEmpty) {
//       setState(() {
//         filteredCategories =
//             List.from(allCategories);
//       });

//       return;
//     }

//     setState(() {
//       filteredCategories =
//           allCategories.where(
//         (category) {
//           return category.name
//               .toLowerCase()
//               .contains(query);
//         },
//       ).toList();
//     });
//   }

//   // ============================================================
//   // ICON
//   // ============================================================

//   IconData _getIcon(
//     CourierVehicleCategory category,
//   ) {
//     switch (category.iconType) {
//       case 'bike':
//         return Icons.two_wheeler_outlined;

//       case 'auto':
//         return Icons.electric_rickshaw_outlined;

//       case 'car':
//         return Icons.directions_car_outlined;

//       case 'van':
//         return Icons.airport_shuttle_outlined;

//       case 'mini_truck':
//         return Icons.local_shipping_outlined;

//       case 'truck':
//         return Icons.local_shipping;

//       case 'cycle':
//         return Icons.pedal_bike_outlined;

//       default:
//         // Common icon for user-created categories.
//         return Icons.local_shipping_outlined;
//     }
//   }

//   // ============================================================
//   // OPEN VEHICLE LIST
//   // ============================================================

//   void _openCategory(
//     CourierVehicleCategory category,
//   ) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             ScreenCourierVehicleList(
//           categoryId: category.id,
//           categoryName: category.name,
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
//       backgroundColor:
//           const Color(0xFFF7F7F7),

//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//         centerTitle: true,
//         title: const Text(
//           'Courier Services',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),

//       body: SafeArea(
//         child: RefreshIndicator(
//           onRefresh: _loadCategories,

//           child: CustomScrollView(
//             physics:
//                 const AlwaysScrollableScrollPhysics(),

//             slivers: [

//               // =================================================
//               // SEARCH
//               // =================================================

//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding:
//                       const EdgeInsets.fromLTRB(
//                     16,
//                     16,
//                     16,
//                     10,
//                   ),

//                   child: TextField(
//                     controller:
//                         searchController,

//                     decoration:
//                         InputDecoration(
//                       hintText:
//                           'Search vehicle',

//                       prefixIcon:
//                           const Icon(
//                         Icons.search,
//                       ),

//                       filled: true,

//                       fillColor:
//                           Colors.white,

//                       border:
//                           OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius.circular(
//                           14,
//                         ),
//                         borderSide:
//                             BorderSide.none,
//                       ),

//                       enabledBorder:
//                           OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius.circular(
//                           14,
//                         ),
//                         borderSide:
//                             BorderSide.none,
//                       ),

//                       focusedBorder:
//                           OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius.circular(
//                           14,
//                         ),
//                         borderSide:
//                             const BorderSide(
//                           color:
//                               Colors.green,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),

//               // =================================================
//               // ERROR
//               // =================================================

//               if (hasError)
//                 const SliverToBoxAdapter(
//                   child: Padding(
//                     padding:
//                         EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 5,
//                     ),

//                     child: Text(
//                       'Some categories could not be loaded. Showing available categories.',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.orange,
//                       ),
//                     ),
//                   ),
//                 ),

//               // =================================================
//               // LOADING
//               // =================================================

//               if (isLoading)
//                 const SliverFillRemaining(
//                   child: Center(
//                     child:
//                         CircularProgressIndicator(),
//                   ),
//                 )

//               // =================================================
//               // EMPTY
//               // =================================================

//               else if (
//                   filteredCategories.isEmpty)
//                 const SliverFillRemaining(
//                   child: Center(
//                     child: Text(
//                       'No vehicle category found.',
//                       style: TextStyle(
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ),
//                 )

//               // =================================================
//               // GRID
//               // =================================================

//               else
//                 SliverPadding(
//                   padding:
//                       const EdgeInsets.fromLTRB(
//                     16,
//                     8,
//                     16,
//                     25,
//                   ),

//                   sliver:
//                       SliverGrid(
//                     delegate:
//                         SliverChildBuilderDelegate(
//                       (context, index) {
//                         final category =
//                             filteredCategories[
//                                 index];

//                         return _categoryCard(
//                           category,
//                         );
//                       },

//                       childCount:
//                           filteredCategories
//                               .length,
//                     ),

//                     gridDelegate:
//                         const SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 2,
//                       crossAxisSpacing: 12,
//                       mainAxisSpacing: 12,
//                       childAspectRatio: 1.15,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // CATEGORY CARD
//   // ============================================================

//   Widget _categoryCard(
//     CourierVehicleCategory category,
//   ) {
//     return Material(
//       color: Colors.white,

//       borderRadius:
//           BorderRadius.circular(16),

//       child: InkWell(
//         borderRadius:
//             BorderRadius.circular(16),

//         onTap: () =>
//             _openCategory(category),

//         child: Padding(
//           padding:
//               const EdgeInsets.all(14),

//           child: Column(
//             mainAxisAlignment:
//                 MainAxisAlignment.center,

//             children: [

//               Container(
//                 width: 55,
//                 height: 55,

//                 decoration:
//                     const BoxDecoration(
//                   color:
//                       Color(0xFFFFEBEE),
//                   shape: BoxShape.circle,
//                 ),

//                 child: Icon(
//                   _getIcon(category),
//                   size: 30,
//                   color:
//                       Colors.green,
//                 ),
//               ),

//               const SizedBox(height: 12),

//               Text(
//                 category.name,
//                 maxLines: 2,
//                 overflow:
//                     TextOverflow.ellipsis,
//                 textAlign:
//                     TextAlign.center,

//                 style: const TextStyle(
//                   fontSize: 15,
//                   fontWeight:
//                       FontWeight.w700,
//                 ),
//               ),

//               if (category.isCustom) ...[
//                 const SizedBox(height: 3),
//                 const Text(
//                   'Custom',
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// ============================================================
// COURIER CATEGORY MODEL
// ============================================================

class CourierCategoryItem {
  final String id;
  final String name;
  final String iconType;
  final bool isCustom;

  const CourierCategoryItem({
    required this.id,
    required this.name,
    required this.iconType,
    this.isCustom = false,
  });
}

// ============================================================
// COURIER CATEGORIES SCREEN
// ============================================================

class ScreenCourierCategories extends StatelessWidget {
  ScreenCourierCategories({super.key});

  static const Color green = Color(0xFF138808);
  static const Color lightBackground = Color(0xFFF7F7F7);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // DEFAULT VEHICLE CATEGORIES
  // ============================================================

  static const List<CourierCategoryItem> defaultCategories = [
    CourierCategoryItem(
      id: 'bike',
      name: 'Bike',
      iconType: 'bike',
    ),
    CourierCategoryItem(
      id: 'auto',
      name: 'Auto',
      iconType: 'auto',
    ),
    CourierCategoryItem(
      id: 'car',
      name: 'Car',
      iconType: 'car',
    ),
    CourierCategoryItem(
      id: 'van',
      name: 'Van',
      iconType: 'van',
    ),
    CourierCategoryItem(
      id: 'mini_truck',
      name: 'Mini Truck',
      iconType: 'mini_truck',
    ),
    CourierCategoryItem(
      id: 'truck',
      name: 'Truck',
      iconType: 'truck',
    ),
    CourierCategoryItem(
      id: 'cycle',
      name: 'Cycle',
      iconType: 'cycle',
    ),
  ];

  // ============================================================
  // VEHICLE ICON
  // ============================================================

  IconData _vehicleIcon(String iconType) {
    switch (iconType) {
      case 'bike':
        return Icons.two_wheeler_outlined;

      case 'auto':
        return Icons.electric_rickshaw_outlined;

      case 'car':
        return Icons.directions_car_outlined;

      case 'van':
        return Icons.airport_shuttle_outlined;

      case 'mini_truck':
        return Icons.local_shipping_outlined;

      case 'truck':
        return Icons.local_shipping;

      case 'cycle':
        return Icons.pedal_bike_outlined;

      default:
        return Icons.local_shipping_outlined;
    }
  }

  // ============================================================
  // BUILD CATEGORY LIST
  //
  // Built-in categories are always displayed.
  // Custom categories are displayed only when used by
  // at least one active courier.
  // ============================================================

  List<CourierCategoryItem> buildAllCategories({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        categoryDocuments,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        courierDocuments,
  }) {
    final List<CourierCategoryItem> categories = [
      ...defaultCategories,
    ];

    // Collect category IDs currently used by active couriers.
    final Set<String> usedCategoryIds = {};

    for (final courierDoc in courierDocuments) {
      final data = courierDoc.data();

      final List<dynamic> vehicleIds =
          data['vehicleCategoryIds'] is List
              ? data['vehicleCategoryIds'] as List
              : [];

      for (final id in vehicleIds) {
        final categoryId = id.toString().trim();

        if (categoryId.isNotEmpty) {
          usedCategoryIds.add(categoryId);
        }
      }
    }

    // Add custom categories only if an active courier uses them.
    for (final doc in categoryDocuments) {
      final data = doc.data();

      if (data['isCustom'] != true) {
        continue;
      }

      if (!usedCategoryIds.contains(doc.id)) {
        continue;
      }

      final name = (data['name'] ?? '').toString().trim();

      if (name.isEmpty) {
        continue;
      }

      final alreadyExists = categories.any(
        (item) =>
            item.id == doc.id ||
            item.name.toLowerCase() == name.toLowerCase(),
      );

      if (!alreadyExists) {
        categories.add(
          CourierCategoryItem(
            id: doc.id,
            name: name,
            iconType: (data['iconType'] ?? 'default').toString(),
            isCustom: true,
          ),
        );
      }
    }

    return categories;
  }

  // ============================================================
  // BUILD CATEGORY COUNTS
  //
  // Each active courier is counted only once per category.
  // ============================================================

  Map<String, int> buildCategoryCounts({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        courierDocuments,
  }) {
    final Map<String, int> counts = {};

    for (final courierDoc in courierDocuments) {
      final data = courierDoc.data();

      final List<dynamic> vehicleIds =
          data['vehicleCategoryIds'] is List
              ? data['vehicleCategoryIds'] as List
              : [];

      // Avoid counting duplicate IDs in one courier profile.
      final Set<String> uniqueIds = vehicleIds
          .map((id) => id.toString().trim())
          .where((id) => id.isNotEmpty)
          .toSet();

      for (final categoryId in uniqueIds) {
        counts[categoryId] = (counts[categoryId] ?? 0) + 1;
      }
    }

    return counts;
  }

  // ============================================================
  // CATEGORY CARD
  // ============================================================

  Widget _categoryCard(
    BuildContext context, {
    required CourierCategoryItem category,
    required int count,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScreenCourierVehicleList(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // VEHICLE ICON
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5E9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _vehicleIcon(category.iconType),
                size: 30,
                color: green,
              ),
            ),

            const SizedBox(height: 12),

            // CATEGORY NAME
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),

            const SizedBox(height: 9),

            // ACTIVE COURIER COUNT
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: count > 0
                    ? const Color(0xFFEAF5E9)
                    : const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count ${count == 1 ? 'Courier' : 'Couriers'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: count > 0
                      ? green
                      : Colors.grey.shade600,
                ),
              ),
            ),

            if (category.isCustom) ...[
              const SizedBox(height: 6),
              const Text(
                'Custom',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,

      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Courier Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('courierVehicleCategories')
            .snapshots(),

        builder: (context, categorySnapshot) {
          if (categorySnapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load vehicle categories.',
              ),
            );
          }

          if (categorySnapshot.connectionState ==
                  ConnectionState.waiting &&
              !categorySnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: green,
              ),
            );
          }

          final categoryDocuments =
              categorySnapshot.data?.docs ?? [];

          // ======================================================
          // ACTIVE COURIERS STREAM
          // ======================================================

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('couriers')
                .where(
                  'isActive',
                  isEqualTo: true,
                )
                .snapshots(),

            builder: (context, courierSnapshot) {
              if (courierSnapshot.hasError) {
                return const Center(
                  child: Text(
                    'Unable to load courier details.',
                  ),
                );
              }

              if (courierSnapshot.connectionState ==
                      ConnectionState.waiting &&
                  !courierSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: green,
                  ),
                );
              }

              final courierDocuments =
                  courierSnapshot.data?.docs ?? [];

              // Build categories and counts from active couriers.
              final categories = buildAllCategories(
                categoryDocuments: categoryDocuments,
                courierDocuments: courierDocuments,
              );

              final counts = buildCategoryCounts(
                courierDocuments: courierDocuments,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      18,
                      16,
                      14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Find Courier Services',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF222222),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'Choose a vehicle category to find nearby couriers.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            const Icon(
                              Icons.people_alt_outlined,
                              size: 18,
                              color: green,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              '${courierDocuments.length} active ${courierDocuments.length == 1 ? 'courier' : 'couriers'}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // CATEGORY GRID
                  // ==================================================

                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        20,
                      ),
                      itemCount: categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 13,
                        mainAxisSpacing: 13,
                        childAspectRatio: 1.12,
                      ),
                      itemBuilder: (context, index) {
                        final category = categories[index];

                        final count =
                            counts[category.id] ?? 0;

                        return _categoryCard(
                          context,
                          category: category,
                          count: count,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}