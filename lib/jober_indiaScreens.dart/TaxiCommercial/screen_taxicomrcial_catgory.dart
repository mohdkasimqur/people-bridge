import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/TaxiCommercial/Commercial/screen_comrcil_drvrs.dart';
import 'package:jober_india/jober_indiaScreens.dart/TaxiCommercial/Taxi/taxi_passenger_flow.dart';

import 'package:jober_india/jober_indiaScreens.dart/TaxiCommercial/screen_taxicommercial_data.dart';

class ScreenTaxiCommercialCategories extends StatefulWidget {
  final String initialType;

  const ScreenTaxiCommercialCategories({
    super.key,
    this.initialType = 'Taxi',
  });

  @override
  State<ScreenTaxiCommercialCategories> createState() =>
      _ScreenTaxiCommercialCategoriesState();
}

class _ScreenTaxiCommercialCategoriesState
    extends State<ScreenTaxiCommercialCategories> {

  late String selectedType;

  bool loadingCategories = true;

  List<TaxiCommercialVehicleCategory> categories = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      liveLocationSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    categoriesSubscription;

  Map<String, int> categoryCounts = {};

  // @override
  // void initState() {
  //   super.initState();

  //   selectedType =
  //       widget.initialType == 'Commercial'
  //           ? 'Commercial'
  //           : 'Taxi';

  //   _loadCategories();

  //  // _listenToLiveDrivers();
  //  _listenToTaxiCommercialCounts();
  // }
  @override
void initState() {
  super.initState();

  selectedType =
      widget.initialType == 'Commercial' ? 'Commercial' : 'Taxi';

  _listenToCategories();
  _listenToTaxiCommercialCounts();
}

  @override
void dispose() {
  categoriesSubscription?.cancel();
  liveLocationSubscription?.cancel();
  super.dispose();
}

  // ==========================================================
  // LOAD CATEGORIES
  // ==========================================================
  void _listenToCategories() {
  categoriesSubscription?.cancel();

  final String typeToLoad = selectedType;

  setState(() {
    loadingCategories = true;
  });

  categoriesSubscription = FirebaseFirestore.instance
      .collection('taxi_vehicle_categories')
      .where('vehicleType', isEqualTo: typeToLoad)
      .snapshots()
      .listen(
    (snapshot) {
      if (!mounted || selectedType != typeToLoad) return;

      final List<TaxiCommercialVehicleCategory> customCategories = [];
      final Set<String> seenNames = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final String name = (data['name'] ?? '').toString().trim();

        if (name.isEmpty) continue;

        // Avoid duplicate category names.
        if (!seenNames.add(name.toLowerCase())) continue;

        customCategories.add(
          TaxiCommercialVehicleCategory(
            name: name,
            image: '',
            imageUrl: (data['imageUrl'] ?? '').toString(),
            type: typeToLoad,
            isCustom: data['isCustom'] == true,
          ),
        );
      }

      // Add built-in categories without duplicating custom names.
      final List<TaxiCommercialVehicleCategory> builtInCategories =
          getPredefinedVehicleCategories(typeToLoad);

      final List<TaxiCommercialVehicleCategory> allCategories = [
        ...customCategories,
      ];

      for (final vehicle in builtInCategories) {
        if (seenNames.add(vehicle.name.trim().toLowerCase())) {
          allCategories.add(vehicle);
        }
      }

      if (!mounted || selectedType != typeToLoad) return;

      setState(() {
        categories = allCategories;
        loadingCategories = false;
      });
    },
    onError: (Object error, StackTrace stackTrace) {
      debugPrint('Homepage vehicle category listener error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted || selectedType != typeToLoad) return;

      setState(() {
        categories = getPredefinedVehicleCategories(typeToLoad);
        loadingCategories = false;
      });
    },
  );
}

  Future<void> _loadCategories() async {
    if (mounted) {
      setState(() {
        loadingCategories = true;
      });
    }

    try {
      final List<TaxiCommercialVehicleCategory> result =
          await loadAllTaxiCommercialCategories(
        selectedType,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        categories = result;
        loadingCategories = false;
      });
    } catch (e) {
      debugPrint(
        'Error loading taxi/commercial categories: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        categories = getPredefinedVehicleCategories(
          selectedType,
        );

        loadingCategories = false;
      });
    }
  }

//=============================================
// REAL-TIME TAXI / COMMERCIAL CATEGORY COUNTS
// No live-location dependency and no driver list.
// ============================================================

void _listenToTaxiCommercialCounts() {
  liveLocationSubscription?.cancel();

  liveLocationSubscription = FirebaseFirestore.instance
      .collection('taxi_commercial')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .listen(
    (snapshot) {
      if (!mounted) return;

      final Map<String, int> counts = {};

      for (final document in snapshot.docs) {
        final data = document.data();

        final vehicleType =
            data['vehicleType']?.toString().trim() ?? '';

        final vehicle =
            data['vehicle']?.toString().trim() ?? '';

        // Only count the currently selected Taxi or Commercial type.
        if (vehicleType.toLowerCase() !=
            selectedType.toLowerCase()) {
          continue;
        }

        if (vehicle.isEmpty) continue;

        final key = vehicle.toLowerCase();

        counts[key] = (counts[key] ?? 0) + 1;
      }

      setState(() {
        categoryCounts = counts;
      });
    },
    onError: (Object error) {
      debugPrint(
        'Taxi category count listener error: $error',
      );
    },
  );
}

  // ==========================================================
  // GET COUNT
  // ==========================================================

  int _getCategoryCount(
    String categoryName,
  ) {
    return categoryCounts[
          categoryName.trim().toLowerCase()
        ] ??
        0;
  }

  // ==========================================================
  // CHANGE TAXI / COMMERCIAL
  // ==========================================================
 
//   void _changeType(String type) {
//   if (selectedType == type) return;

//   setState(() {
//     selectedType = type;
//     categories = [];
//     categoryCounts = {};
//     loadingCategories = true;
//   });

//   _loadCategories();
//   _listenToTaxiCommercialCounts();
// }
void _changeType(String type) {
  if (selectedType == type) return;

  setState(() {
    selectedType = type;
    categories = [];
    categoryCounts = {};
    loadingCategories = true;
  });

  _listenToCategories();
  _listenToTaxiCommercialCounts();
}

  // ==========================================================
  // OPEN SEARCH
  // ==========================================================

  void _openCategory(
  TaxiCommercialVehicleCategory category,
) {
  // ==========================================================
  // COMMERCIAL
  // ==========================================================

  if (selectedType == 'Commercial') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenCommercialDrivers(
          vehicleCategory: category.name,
        ),
      ),
    );

    return;
  }

  // ==========================================================
  // TAXI
  // ==========================================================

  // Navigator.push(
  //   context,
  //   MaterialPageRoute(
  //     builder: (_) => ScreenCabSearch(
  //       vehicleType: 'taxi_commercial',
  //       vehicleCategory: category.name,
  //     ),
  //   ),
  // );
  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ScreenTaxiPassengerFlow(
      vehicleCategory: category.name,
    ),
  ),
);
}

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Taxi / Commercial',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: Column(
        children: [

          // ==================================================
          // TAXI / COMMERCIAL SWITCH
          // ==================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              10,
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [

                  Expanded(
                    child: _buildTypeButton(
                      title: 'Taxi',
                      icon: Icons.local_taxi_outlined,
                      selected:
                          selectedType == 'Taxi',
                      onTap: () {
                        _changeType('Taxi');
                      },
                    ),
                  ),

                  Expanded(
                    child: _buildTypeButton(
                      title: 'Commercial',
                      icon:
                          Icons.local_shipping_outlined,
                      selected:
                          selectedType == 'Commercial',
                      onTap: () {
                        _changeType('Commercial');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==================================================
          // SMALL DESCRIPTION
          // ==================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              4,
              18,
              10,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Drivers currently live today',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==================================================
          // CATEGORY LIST
          // ==================================================

          Expanded(
            child: loadingCategories
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : categories.isEmpty
                    ? const Center(
                        child: Text(
                          'No vehicle categories found',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCategories,
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            14,
                            4,
                            14,
                            24,
                          ),
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          itemCount: categories.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.92,
                          ),
                          itemBuilder:
                              (context, index) {

                            final TaxiCommercialVehicleCategory
                                category =
                                categories[index];

                            final int count =
                                _getCategoryCount(
                              category.name,
                            );

                            return _buildCategoryCard(
                              category,
                              count,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TYPE BUTTON
  // ==========================================================

  Widget _buildTypeButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: .08),
                    blurRadius: 5,
                    offset:
                        const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? Colors.red
                  : Colors.grey.shade700,
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected
                    ? Colors.red
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
// VEHICLE IMAGE: CUSTOM PHOTO, ASSET OR DEFAULT ICON
// ==========================================================

Widget _buildCategoryVehicleImage(
  TaxiCommercialVehicleCategory category,
) {
  // Custom vehicle photo uploaded to Firebase Storage.
  if (category.imageUrl.trim().isNotEmpty) {
    return Image.network(
      category.imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _buildVehicleIcon();
      },
    );
  }

  // Existing built-in vehicle asset.
  if (category.image.trim().isNotEmpty) {
    return Image.asset(
      category.image,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _buildVehicleIcon();
      },
    );
  }

  // No photo: display the common vehicle icon.
  return _buildVehicleIcon();
}

  // ==========================================================
  // CATEGORY CARD
  // ==========================================================

  Widget _buildCategoryCard(
    TaxiCommercialVehicleCategory category,
    int count,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _openCategory(category);
        },
        child: Stack(
          children: [

            // =================================================
            // CARD CONTENT
            // =================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                10,
                10,
                10,
                8,
              ),
              child: Column(
                children: [

                
                  Expanded(
  child: ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: _buildCategoryVehicleImage(category),
  ),
),

                  const SizedBox(height: 7),

                  Text(
                    category.name,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                 if (count > 0)
  Text(
    count == 1
        ? '1 driver'
        : '$count drivers',
    style: const TextStyle(
      fontSize: 11,
      color: Color(0xFF16803C),
      fontWeight: FontWeight.w600,
    ),
  ),
                ],
              ),
            ),

            // =================================================
            // RED COUNT BADGE
            // =================================================

            Positioned(
              top: 7,
              right: 7,
              child: _buildCountBadge(count),
            ),

            // =================================================
            // CUSTOM LABEL
            // =================================================

            if (category.isCustom)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius:
                        BorderRadius.circular(7),
                  ),
                  child: const Text(
                    'CUSTOM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // RED BADGE
  // ==========================================================
Widget _buildCountBadge(int count) {
  // Hide the badge when there are no drivers.
  if (count <= 0) {
    return const SizedBox.shrink();
  }

  return Container(
    constraints: const BoxConstraints(
      minWidth: 24,
      minHeight: 24,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 6,
    ),
    decoration: const BoxDecoration(
      color: Color(0xFF138808),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(
      count > 99 ? '99+' : '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

// ==========================================================
// DEFAULT ICON FOR VEHICLES WITHOUT PHOTOS
// ==========================================================

Widget _buildVehicleIcon() {
  return Container(
    width: double.infinity,
    height: double.infinity,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFF1F8F2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      selectedType == 'Taxi'
          ? Icons.local_taxi_outlined
          : Icons.local_shipping_outlined,
      size: 64,
      color: const Color(0xFF16803C),
    ),
  );
}
}


  // Widget _buildVehicleIcon() {
  //   return Container(
  //     width: double.infinity,
  //     decoration: BoxDecoration(
  //       color: Colors.grey.shade100,
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Icon(
  //       selectedType == 'Taxi'
  //           ? Icons.local_taxi_outlined
  //           : Icons.local_shipping_outlined,
  //       size: 64,
  //       color: Colors.grey.shade500,
  //     ),
  //   );
  // }

  // // ==========================================================
  // // LISTEN TO LIVE DRIVERS
  // // ==========================================================

  // void _listenToLiveDrivers() {
  //   liveLocationSubscription?.cancel();

  //   liveLocationSubscription = FirebaseFirestore.instance
  //       .collection('liveLocations')
  //       .where(
  //         'isLive',
  //         isEqualTo: true,
  //       )
  //       .snapshots()
  //       .listen(
  //     (QuerySnapshot<Map<String, dynamic>> snapshot) {
  //       _calculateLiveCounts(snapshot.docs);
  //     },
  //     onError: (Object error) {
  //       debugPrint(
  //         'Live location listener error: $error',
  //       );
  //     },
  //   );
  // }

  // // ==========================================================
  // // CALCULATE TODAY'S LIVE COUNTS
  // // ==========================================================

  // void _calculateLiveCounts(
  //   List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  // ) {
  //   final DateTime now = DateTime.now();

  //   final DateTime startOfToday = DateTime(
  //     now.year,
  //     now.month,
  //     now.day,
  //   );

  //   final Map<String, int> counts = {};

  //   for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
  //       in docs) {

  //     final Map<String, dynamic> data = doc.data();

  //     // ------------------------------------------------------
  //     // Only Taxi / Commercial
  //     // ------------------------------------------------------

  //     final String role =
  //         data['role']?.toString().trim() ?? '';

  //     if (role != 'taxi_commercial') {
  //       continue;
  //     }

  //     // ------------------------------------------------------
  //     // updatedAt
  //     // ------------------------------------------------------

  //     final dynamic updatedValue =
  //         data['updatedAt'];

  //     DateTime? updatedAt;

  //     if (updatedValue is Timestamp) {
  //       updatedAt = updatedValue.toDate();
  //     } else if (updatedValue is DateTime) {
  //       updatedAt = updatedValue;
  //     }

  //     if (updatedAt == null) {
  //       continue;
  //     }

  //     // ------------------------------------------------------
  //     // Only drivers active today
  //     // ------------------------------------------------------

  //     if (updatedAt.isBefore(startOfToday)) {
  //       continue;
  //     }

  //     // ------------------------------------------------------
  //     // Vehicle type
  //     // ------------------------------------------------------

  //     final String vehicleType =
  //         data['vehicleType']?.toString().trim() ?? '';

  //     if (vehicleType != selectedType) {
  //       continue;
  //     }

  //     // ------------------------------------------------------
  //     // Vehicle category
  //     // ------------------------------------------------------

  //     final String vehicle =
  //         data['vehicle']?.toString().trim() ?? '';

  //     if (vehicle.isEmpty) {
  //       continue;
  //     }

  //     final String key =
  //         vehicle.toLowerCase();

  //     counts[key] =
  //         (counts[key] ?? 0) + 1;
  //   }

  //   if (!mounted) {
  //     return;
  //   }

  //   setState(() {
  //     categoryCounts
  //       ..clear()
  //       ..addAll(counts);
  //   });
  // }
  // ===============

   // Expanded(
                  //   child: category.image.isNotEmpty
                  //       ? ClipRRect(
                  //           borderRadius:
                  //               BorderRadius.circular(12),
                  //           child: Image.asset(
                  //             category.image,
                  //             width: double.infinity,
                  //             fit: BoxFit.contain,
                  //             errorBuilder:
                  //                 (
                  //               context,
                  //               error,
                  //               stackTrace,
                  //             ) {
                  //               return _buildVehicleIcon();
                  //             },
                  //           ),
                  //         )
                  //       : _buildVehicleIcon(),
                  // ),

  // Future<void> _changeType(
  //   String type,
  // ) async {
  //   if (selectedType == type) {
  //     return;
  //   }

  //   setState(() {
  //     selectedType = type;
  //     loadingCategories = true;
  //     categories = [];
  //     categoryCounts.clear();
  //   });

  //   await _loadCategories();
  // }