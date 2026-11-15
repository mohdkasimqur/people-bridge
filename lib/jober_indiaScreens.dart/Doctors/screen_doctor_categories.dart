import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jober_india/jober_indiaScreens.dart/Doctors/screen_doctor_specialized.dart';

// ============================================================
// SCREEN DOCTOR CATEGORIES
// ============================================================

class ScreenDoctorCategories extends StatefulWidget {
  const ScreenDoctorCategories({
    super.key,
  });

  @override
  State<ScreenDoctorCategories> createState() =>
      _ScreenDoctorCategoriesState();
}

class _ScreenDoctorCategoriesState
    extends State<ScreenDoctorCategories> {

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController searchController =
      TextEditingController();

  final FocusNode searchFocusNode =
      FocusNode();

  bool isLoading = false;

  List<String> doctorCategories = [
    'Allopathy',
    'Ayurvedic',
    'Homeopathy',
    'Unani',
  ];
  // Built-in categories must always remain available.
final List<String> _builtInDoctorCategories = [
  'Allopathy',
  'Ayurvedic',
  'Homeopathy',
  'Unani',
];

// Categories found in the shared collection.
final Set<String> _sharedDoctorCategories = {};

// Categories explicitly added by users.
final Set<String> _userAddedDoctorCategories = {};
// Categories found in existing doctor profiles.
final Set<String> _profileDoctorCategories = {};

// Real-time subscriptions.
StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _sharedCategoriesSubscription;

StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _doctorProfilesCategoriesSubscription;

  List<String> get filteredCategories {

    final search =
        searchController.text
            .trim()
            .toLowerCase();

    if (search.isEmpty) {
      return doctorCategories;
    }

    return doctorCategories
        .where(
          (category) =>
              category
                  .toLowerCase()
                  .contains(search),
        )
        .toList();
  }

  // ==========================================================
  // INIT STATE
  // ==========================================================

  @override
void initState() {
  super.initState();

  searchController.addListener(_onSearchChanged);

  loadDoctorCategories();

  _listenToDoctorCategoryCounts();
}

  // ==========================================================
  // SEARCH CHANGED
  // ==========================================================

  void _onSearchChanged() {

    if (!mounted) return;

    setState(() {});
  }

  // ==========================================================
  // LOAD DOCTOR CATEGORIES
  // ==================
void loadDoctorCategories() {
  if (mounted) {
    setState(() {
      isLoading = true;
    });
  }

  // Listen to the shared custom-category collection.
  _sharedCategoriesSubscription?.cancel();

  _sharedCategoriesSubscription = firestore
      .collection('doctorCategories')
      .snapshots()
      .listen(
   
    (snapshot) {
  _sharedDoctorCategories.clear();
  _userAddedDoctorCategories.clear();

  for (final document in snapshot.docs) {
    final data = document.data();
    final name = data['name'];

    if (name is! String || name.trim().isEmpty) {
      continue;
    }

    final category = name.trim();

    _sharedDoctorCategories.add(category);

    if (data['isUserAdded'] == true &&
        !_builtInDoctorCategories.any(
          (item) =>
              item.toLowerCase() == category.toLowerCase(),
        )) {
      _userAddedDoctorCategories.add(category);
    }
  }

  _rebuildDoctorCategories();
},
    onError: (Object error) {
      debugPrint('Shared doctor categories error: $error');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    },
  );

  // Also discover categories saved in existing doctor profiles.
  // No .limit() is used.
  _doctorProfilesCategoriesSubscription?.cancel();

  _doctorProfilesCategoriesSubscription = firestore
      .collection('doctors')
      .snapshots()
      .listen(
    (snapshot) {
      _profileDoctorCategories.clear();

      for (final document in snapshot.docs) {
        final data = document.data();
        final categories = data['categories'];

        if (categories is List) {
          for (final item in categories) {
            if (item is String && item.trim().isNotEmpty) {
              _profileDoctorCategories.add(item.trim());
            }
          }
        }
      }

      _rebuildDoctorCategories();
    },
    onError: (Object error) {
      debugPrint('Doctor profile categories error: $error');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    },
  );
}

void _rebuildDoctorCategories() {
  final Map<String, String> uniqueCategories = {};

  void addCategory(String value) {
    final category = value.trim();

    if (category.isNotEmpty) {
      uniqueCategories.putIfAbsent(
        category.toLowerCase(),
        () => category,
      );
    }
  }

  for (final category in _builtInDoctorCategories) {
    addCategory(category);
  }

  for (final category in _sharedDoctorCategories) {
    addCategory(category);
  }

  for (final category in _profileDoctorCategories) {
    addCategory(category);
  }

  final updatedCategories = uniqueCategories.values.toList()
    ..sort(
      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );

  if (!mounted) return;

  setState(() {
    doctorCategories = updatedCategories;
    isLoading = false;
  });
}
  // ==========================================================
  // SELECT CATEGORY
  // ==========================================================

  void selectCategory(
    String category,
  ) {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ScreenDoctorSpecializations(
          selectedCategory:
              category,
        ),
      ),
    );
  }

  // ==========================================================
  // CLEAR SEARCH
  // ==========================================================

  void clearSearch() {

    searchController.clear();

    searchFocusNode.requestFocus();
  }

  // ==========================================================
  // SHOW MESSAGE
  // ==========================================================

  void showMessage(
    String message,
  ) {

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ==========================================================
  // CATEGORY ICON
  // ==========================================================

  IconData categoryIcon(
    String category,
  ) {

    final value =
        category.toLowerCase();

    if (value.contains('allopath')) {
      return Icons.medical_services_outlined;
    }

    if (value.contains('ayur')) {
      return Icons.spa_outlined;
    }

    if (value.contains('homeo')) {
      return Icons.health_and_safety_outlined;
    }

    if (value.contains('unani')) {
      return Icons.local_hospital_outlined;
    }

    return Icons.medical_services_outlined;
  }

  // ==========================================================
  // CATEGORY DESCRIPTION
  // ==========================================================

  String categoryDescription(
    String category,
  ) {

    final value =
        category.toLowerCase();

    if (value.contains('allopath')) {
      return 'Modern medical treatment';
    }

    if (value.contains('ayur')) {
      return 'Traditional Ayurvedic medicine';
    }

    if (value.contains('homeo')) {
      return 'Homeopathic medical treatment';
    }

    if (value.contains('unani')) {
      return 'Traditional Unani medicine';
    }

    return 'Find doctors in this category';
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

@override
void dispose() {
  _sharedCategoriesSubscription?.cancel();
  _doctorProfilesCategoriesSubscription?.cancel();
  _doctorCategorySubscription?.cancel();

  searchController.removeListener(_onSearchChanged);
  searchController.dispose();
  searchFocusNode.dispose();

  super.dispose();
}
  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5EE),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        elevation: 0,

        centerTitle: false,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },

          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 27,
          ),
        ),

        title: const Text(
          'Doctor Categories',
          style: TextStyle(
            color: Color(0xFF252525),
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Column(
          children: [

            // ==================================================
            // TOP CONTENT
            // ==================================================

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  30,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    // ==========================================
                    // HEADING
                    // ==========================================

                    const Text(
                      'Find a Doctor',
                      style: TextStyle(
                        color:
                            Color(0xFF064C38),
                        fontSize: 27,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    const Text(
                      'Select a doctor category to continue',
                      style: TextStyle(
                        color:
                            Color(0xFF777777),
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    // ==========================================
                    // SEARCH BOX
                    // ==========================================

                    Container(
                      width:
                          double.infinity,

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),

                        border:
                            Border.all(
                          color:
                              const Color(
                            0xFFE0E0E0,
                          ),
                        ),

                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black
                                    .withValues(alpha: 
                              0.04,
                            ),

                            blurRadius:
                                8,

                            offset:
                                const Offset(
                              0,
                              3,
                            ),
                          ),
                        ],
                      ),

                      child: TextField(
                        controller:
                            searchController,

                        focusNode:
                            searchFocusNode,

                        textInputAction:
                            TextInputAction.search,

                        decoration:
                            InputDecoration(
                          hintText:
                              'Search doctor category...',

                          hintStyle:
                              const TextStyle(
                            color:
                                Color(
                              0xFF999999,
                            ),

                            fontSize:
                                15,
                          ),

                          prefixIcon:
                              const Icon(
                            Icons.search,
                            color:
                                Color(
                              0xFF176B43,
                            ),
                            size: 25,
                          ),

                          suffixIcon:
                              searchController
                                      .text
                                      .isNotEmpty
                                  ? IconButton(
                                      onPressed:
                                          clearSearch,

                                      icon:
                                          const Icon(
                                        Icons.clear,
                                        color:
                                            Colors.grey,
                                      ),
                                    )
                                  : null,

                          border:
                              InputBorder.none,

                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                16,
                            vertical:
                                17,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // ==========================================
                    // RESULT TITLE
                    // ==========================================

                    Row(
                      children: [

                        const Text(
                          'Doctor Categories',
                          style: TextStyle(
                            color:
                                Color(
                              0xFF252525,
                            ),

                            fontSize:
                                18,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const Spacer(),

                        if (!isLoading)
                          Text(
                            '${filteredCategories.length} found',
                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF777777,
                              ),

                              fontSize:
                                  13,

                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==========================================
                    // LOADING
                    // ==========================================

                    if (isLoading &&
                        doctorCategories.isEmpty)

                      const Padding(
                        padding:
                            EdgeInsets.only(
                          top: 60,
                        ),

                        child: Center(
                          child:
                              CircularProgressIndicator(
                            color:
                                Color(
                              0xFF176B43,
                            ),
                          ),
                        ),
                      )

                    // ==========================================
                    // NO RESULTS
                    // ==========================================

                    else if (
                      filteredCategories.isEmpty
                    )

                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 45,
                          horizontal: 20,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,

                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),

                          border:
                              Border.all(
                            color:
                                const Color(
                              0xFFE0E0E0,
                            ),
                          ),
                        ),

                        child: Column(
                          children: [

                            const Icon(
                              Icons
                                  .search_off,
                              size: 50,
                              color:
                                  Colors.grey,
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            const Text(
                              'No category found',
                              style:
                                  TextStyle(
                                fontSize:
                                    17,
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    Color(
                                  0xFF333333,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 7,
                            ),

                            Text(
                              searchController
                                      .text
                                      .trim()
                                      .isEmpty
                                  ? 'No doctor categories are available.'
                                  : 'Try searching with a different category name.',

                              textAlign:
                                  TextAlign.center,

                              style:
                                  const TextStyle(
                                color:
                                    Colors.grey,
                                fontSize:
                                    14,
                              ),
                            ),

                            if (searchController
                                .text
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(
                                height: 15,
                              ),

                              TextButton(
                                onPressed:
                                    clearSearch,

                                child:
                                    const Text(
                                  'Clear Search',
                                  style:
                                      TextStyle(
                                    color:
                                        Color(
                                      0xFF176B43,
                                    ),
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )

                    // ==========================================
                    // CATEGORY LIST
                    // ==========================================

                    else

                      ListView.builder(
                        shrinkWrap:
                            true,

                        physics:
                            const NeverScrollableScrollPhysics(),

                        itemCount:
                            filteredCategories.length,

                        itemBuilder:
                            (context, index) {

                          final category =
                              filteredCategories[
                                  index];

                          return _categoryCard(
                            category,
                          );
                        },
                      ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ==========================================
                    // INFORMATION
                    // ==========================================

                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets.all(
                        15,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFEFF7F1,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),

                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          const Icon(
                            Icons
                                .info_outline,
                            color:
                                Color(
                              0xFF176B43,
                            ),
                            size: 21,
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child:
                                const Text(
                              'After selecting a doctor category, you can choose a specialization and then view available doctors.',
                              style:
                                  TextStyle(
                                color:
                                    Color(
                                  0xFF555555,
                                ),
                                fontSize:
                                    13,
                                height:
                                    1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 // ============================================================
// LISTEN TO ONLINE DOCTOR-SPECIALIZATION COUNTS BY CATEGORY
// ============================================================

// void _listenToDoctorCategoryCounts() {
//   _doctorCategorySubscription?.cancel();

//   _doctorCategorySubscription = firestore
//       .collection('doctors')
//       .where('isOnline', isEqualTo: true)
//       .snapshots()
//       .listen(
//     (snapshot) {
//       if (!mounted) return;

//       final Map<String, int> counts = {};

//       for (final document in snapshot.docs) {
//         final data = document.data();

//         final categories = data['categories'];
//         final specializations = data['specializations'];

//         if (categories is! List ||
//             specializations is! List) {
//           continue;
//         }

//         // Remove duplicate categories from this doctor.
//         final uniqueCategories = <String>{};

//         for (final item in categories) {
//           if (item is String &&
//               item.trim().isNotEmpty) {
//             uniqueCategories.add(item.trim());
//           }
//         }

//         // Remove duplicate specializations from this doctor.
//         final uniqueSpecializations = <String>{};

//         for (final item in specializations) {
//           if (item is String &&
//               item.trim().isNotEmpty) {
//             uniqueSpecializations.add(
//               item.trim().toLowerCase(),
//             );
//           }
//         }

//         // Count each specialization for every category
//         // selected by this online doctor.
//         for (final category in uniqueCategories) {
//           counts.update(
//             category,
//             (currentCount) =>
//                 currentCount + uniqueSpecializations.length,
//             ifAbsent: () =>
//                 uniqueSpecializations.length,
//           );
//         }
//       }

//       if (!mounted) return;

//       setState(() {
//         _doctorCountsByCategory
//           ..clear()
//           ..addAll(counts);
//       });
//     },
//     onError: (Object error) {
//       debugPrint(
//         'Doctor category count listener error: $error',
//       );
//     },
//   );
// }
void _listenToDoctorCategoryCounts() {
  _doctorCategorySubscription?.cancel();

  _doctorCategorySubscription = firestore
      .collection('doctors')
      .where('isOnline', isEqualTo: true)
      .snapshots()
      .listen(
    (snapshot) {
      if (!mounted) return;

      final Map<String, int> counts = {};

      for (final document in snapshot.docs) {
        final data = document.data();

        final categories = data['categories'];
        final mapping = data['specializationsByCategory'];

        if (categories is! List) continue;

        // Process each unique category for this doctor.
        final uniqueCategories = <String>{};

        for (final item in categories) {
          if (item is String && item.trim().isNotEmpty) {
            uniqueCategories.add(item.trim());
          }
        }

        for (final category in uniqueCategories) {
          // Get specializations belonging to this category.
          final rawSpecializations = mapping is Map
              ? mapping[category]
              : null;

          dynamic categorySpecializations = rawSpecializations;

          // Handle category keys stored with different casing.
          if (categorySpecializations == null && mapping is Map) {
            for (final entry in mapping.entries) {
              if (entry.key.toString().trim().toLowerCase() ==
                  category.toLowerCase()) {
                categorySpecializations = entry.value;
                break;
              }
            }
          }

          // Remove duplicate specializations for this category.
          final uniqueSpecializations = <String>{};

          if (categorySpecializations is List) {
            for (final specialization in categorySpecializations) {
              final name = specialization.toString().trim();

              if (name.isNotEmpty) {
                uniqueSpecializations.add(name.toLowerCase());
              }
            }
          }

          // Add this doctor's specialization count to this category.
          counts.update(
            category,
            (current) => current + uniqueSpecializations.length,
            ifAbsent: () => uniqueSpecializations.length,
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _doctorCountsByCategory
          ..clear()
          ..addAll(counts);
      });
    },
    onError: (Object error) {
      debugPrint(
        'Doctor category count listener error: $error',
      );
    },
  );
}

// ============================================================
// LIVE DOCTOR COUNTS BY CATEGORY
// ============================================================

StreamSubscription<
    QuerySnapshot<Map<String, dynamic>>>?
    _doctorCategorySubscription;

final Map<String, int> _doctorCountsByCategory = {};
  // ============================================================
  // CATEGORY CARD
  // ============================================================

  Widget _categoryCard(
    String category,
  ) {
    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 13,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFE0E0E0,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withValues(alpha: 
              0.035,
            ),

            blurRadius:
                7,

            offset:
                const Offset(
              0,
              3,
            ),
          ),
        ],
      ),

      child: Material(
        color:
            Colors.transparent,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        child: InkWell(
          borderRadius:
              BorderRadius.circular(
            18,
          ),

          onTap: () {
            selectCategory(
              category,
            );
          },

          child: Padding(
            padding:
                const EdgeInsets.all(
              17,
            ),

            child: 
            
            Row(
  children: [
   
  
    Builder(
  builder: (context) {
    final count =
        _doctorCountsByCategory[category] ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(
            categoryIcon(category),
            color: const Color(0xFF16803C),
            size: 27,
          ),
        ),

        if (count > 0)
          Positioned(
            top: -7,
            right: -7,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
              ),
              decoration: BoxDecoration(
                color: Color(0xFF138808),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  },
),

    const SizedBox(width: 15),

   
    Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF252525),
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 5),

      Text(
        categoryDescription(category),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF777777),
          fontSize: 13,
          height: 1.3,
        ),
      ),

      if (_userAddedDoctorCategories.any(
        (item) =>
            item.toLowerCase() == category.toLowerCase(),
      )) ...[
        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'User added',
            style: TextStyle(
              color: Color(0xFF16803C),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ],
  ),
),

const SizedBox(width: 8),

// ARROW ICON — NO COUNT BADGE
Container(
  width: 35,
  height: 35,
  decoration: const BoxDecoration(
    color: Color(0xFFF4F7F4),
    shape: BoxShape.circle,
  ),
  child: const Icon(
    Icons.arrow_forward_ios,
    color: Color(0xFF176B43),
    size: 16,
  ),
),

],
)
          ),
        ),
      ),
    );
  }
}


 // CATEGORY NAME AND DESCRIPTION
    // Expanded(
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Text(
    //         category,
    //         maxLines: 1,
    //         overflow: TextOverflow.ellipsis,
    //         style: const TextStyle(
    //           color: Color(0xFF252525),
    //           fontSize: 17,
    //           fontWeight: FontWeight.bold,
    //         ),
    //       ),
    //       const SizedBox(height: 5),
    //       Text(
    //         categoryDescription(category),
    //         maxLines: 2,
    //         overflow: TextOverflow.ellipsis,
    //         style: const TextStyle(
    //           color: Color(0xFF777777),
    //           fontSize: 13,
    //           height: 1.3,
    //         ),
    //       ),
    //     ],
    //   ),
    // ),


  // @override
  // void initState() {
  //   super.initState();

  //   searchController.addListener(
  //     _onSearchChanged,
  //   );

  //   loadDoctorCategories();
  // }

   // (snapshot) {
    //   _sharedDoctorCategories.clear();

    //   for (final document in snapshot.docs) {
    //     final data = document.data();
    //     final name = data['name'];

    //     if (name is String && name.trim().isNotEmpty) {
    //       _sharedDoctorCategories.add(name.trim());
    //     }
    //   }

    //   _rebuildDoctorCategories();
    // },========================================

//   Future<void> loadDoctorCategories() async {
//   if (isLoading) return;

//   setState(() {
//     isLoading = true;
//   });

//   try {
//     final snapshot =
//         await firestore.collection('doctors').limit(1000).get();

//     final Set<String> firestoreCategories = {};

//     for (final document in snapshot.docs) {
//       final data = document.data();

//       final categories = data['categories'];

//       if (categories is List) {
//         for (final category in categories) {
//           if (category is String) {
//             final value = category.trim();

//             if (value.isNotEmpty) {
//               firestoreCategories.add(value);
//             }
//           }
//         }
//       }
//     }

//     // Add custom categories saved by doctors.
//     for (final category in firestoreCategories) {
//       if (!doctorCategories.contains(category)) {
//         doctorCategories.add(category);
//       }
//     }

//     doctorCategories.sort(
//       (a, b) => a.toLowerCase().compareTo(
//             b.toLowerCase(),
//           ),
//     );
//   } catch (e) {
//     debugPrint(
//       'Error loading doctor categories: $e',
//     );
//   } finally {
//     if (!mounted) {

//     setState(() {
//       isLoading = false;
//     });
//     }
//   }
// }