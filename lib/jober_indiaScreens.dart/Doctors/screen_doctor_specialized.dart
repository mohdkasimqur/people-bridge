import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jober_india/jober_indiaScreens.dart/Doctors/screen_doctor_result.dart';

class ScreenDoctorSpecializations extends StatefulWidget {
  final String selectedCategory;

  const ScreenDoctorSpecializations({
    super.key,
    required this.selectedCategory,
  });

  @override
  State<ScreenDoctorSpecializations> createState() =>
      _ScreenDoctorSpecializationsState();
}

class _ScreenDoctorSpecializationsState
    extends State<ScreenDoctorSpecializations> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController searchController =
      TextEditingController();

  final FocusNode searchFocusNode =
      FocusNode();

  bool isLoading = false;
  // ============================================================
// LIVE ONLINE DOCTOR COUNTS BY SPECIALIZATION
// ============================================================

StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _doctorSpecializationSubscription;

final Map<String, int> _doctorCountsBySpecialization = {};

 
// ============================================================
// BUILT-IN SPECIALIZATIONS BY CATEGORY
// ============================================================

final Map<String, List<String>> _builtInSpecializationsByCategory = {
  'Allopathy': [
    'Cardiology',
    'Neurology',
    'Nephrology',
    'Dermatology',
    'Pediatrics',
    'Gynecology',
    'Obstetrics',
    'Orthopedics',
  ],

  'Ayurvedic': [
    'Kayachikitsa (General Medicine)',
    'Panchakarma',
    'Shalya Tantra (Surgery)',
    'Shalakya Tantra (ENT and Eye Care)',
    'Prasuti Tantra (Obstetrics)',
    'Stri Roga (Women’s Health)',
    'Kaumarabhritya (Pediatrics)',
    'Agada Tantra (Toxicology)',
  ],

  'Homeopathy': [
    'General Homeopathy',
    'Acute Disease Care',
    'Chronic Disease Care',
    'Pediatrics',
    'Women’s Health',
    'Skin and Hair Disorders',
    'Digestive Disorders',
    'Respiratory Disorders',
  ],

  'Unani': [
    'General Unani Medicine',
    'Kulliyat (Basic Principles)',
    'Ilaj-bid-Dawa (Pharmacotherapy)',
    'Ilaj-bil-Ghiza (Dietotherapy)',
    'Ilaj-bit-Tadbeer (Regimenal Therapy)',
    'Jarahat (Surgery)',
    'Amraz-e-Jild (Skin Disorders)',
  ],
};

// Currently displayed specializations.
List<String> specializations = [];

// Shared custom specializations, grouped by category.
final Map<String, Set<String>> _sharedSpecializationsByCategory = {};

// User-added specializations, grouped by category.
final Map<String, Set<String>> _userAddedSpecializationsByCategory = {};

// Specializations found in existing doctor profiles, grouped by category.
final Map<String, Set<String>> _profileSpecializationsByCategory = {};

// Firestore subscriptions.
StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _sharedSpecializationsSubscription;

StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _doctorProfilesSpecializationsSubscription;

// ============================================================
// LOAD SPECIALIZATIONS FOR EACH CATEGORY
// ============================================================

void _listenToDoctorSpecializations() {
  // ----------------------------------------------------------
  // SHARED CUSTOM SPECIALIZATIONS
  // ----------------------------------------------------------

  _sharedSpecializationsSubscription?.cancel();

  _sharedSpecializationsSubscription = firestore
      .collection('doctorSpecializations')
      .snapshots()
      .listen(
    (snapshot) {
      _sharedSpecializationsByCategory.clear();
      _userAddedSpecializationsByCategory.clear();

      for (final document in snapshot.docs) {
        final data = document.data();

        final name = (data['name'] ?? '').toString().trim();
        final category =
            (data['categoryName'] ?? '').toString().trim();

        // Ignore old records without categoryName.
        if (name.isEmpty || category.isEmpty) continue;

        final categoryKey = category.toLowerCase();

        _sharedSpecializationsByCategory
            .putIfAbsent(categoryKey, () => <String>{})
            .add(name);

        if (data['isUserAdded'] == true) {
          _userAddedSpecializationsByCategory
              .putIfAbsent(categoryKey, () => <String>{})
              .add(name);
        }
      }

      _rebuildDoctorSpecializations();
    },
    onError: (Object error) {
      debugPrint('Shared specializations error: $error');
    },
  );

  // ----------------------------------------------------------
  // SPECIALIZATIONS SAVED IN DOCTOR PROFILES
  // ----------------------------------------------------------

  _doctorProfilesSpecializationsSubscription?.cancel();

  _doctorProfilesSpecializationsSubscription = firestore
      .collection('doctors')
      .snapshots()
      .listen(
    (snapshot) {
      _profileSpecializationsByCategory.clear();

      for (final document in snapshot.docs) {
        final data = document.data();

        final rawMapping = data['specializationsByCategory'];

        // Preferred format: category-specific specialization lists.
        if (rawMapping is Map) {
          rawMapping.forEach((key, value) {
            final categoryKey = key.toString().trim().toLowerCase();

            if (categoryKey.isEmpty || value is! List) return;

            for (final item in value) {
              if (item is! String || item.trim().isEmpty) continue;

              _profileSpecializationsByCategory
                  .putIfAbsent(categoryKey, () => <String>{})
                  .add(item.trim());
            }
          });

          continue;
        }

        // Legacy fallback:
        // If the profile has only one category, its flat
        // specialization list can safely belong to that category.
        final categories = data['categories'];
        final values = data['specializations'];

        if (categories is List &&
            categories.length == 1 &&
            values is List) {
          final category = categories.first;

          if (category is! String || category.trim().isEmpty) {
            continue;
          }

          final categoryKey = category.trim().toLowerCase();

          for (final item in values) {
            if (item is! String || item.trim().isEmpty) continue;

            _profileSpecializationsByCategory
                .putIfAbsent(categoryKey, () => <String>{})
                .add(item.trim());
          }
        }
      }

      _rebuildDoctorSpecializations();
    },
    onError: (Object error) {
      debugPrint('Doctor profile specializations error: $error');
    },
  );
}

// ============================================================
// REBUILD THE SELECTED CATEGORY'S SPECIALIZATION LIST
// ============================================================

void _rebuildDoctorSpecializations() {
  final categoryKey = widget.selectedCategory.trim().toLowerCase();

  final Map<String, String> unique = {};

  void addSpecialization(String name) {
    final value = name.trim();

    if (value.isNotEmpty) {
      unique.putIfAbsent(value.toLowerCase(), () => value);
    }
  }

  // 1. Add built-in specializations ONLY for built-in categories.
final builtInEntry =
    _builtInSpecializationsByCategory.entries.where(
  (entry) =>
      entry.key.trim().toLowerCase() == categoryKey,
);

if (builtInEntry.isNotEmpty) {
  for (final name in builtInEntry.first.value) {
    addSpecialization(name);
  }
}

// 2. Add custom specializations belonging to this category only.
for (final name
    in _sharedSpecializationsByCategory[categoryKey] ??
        <String>{}) {
  addSpecialization(name);
}

// 3. Add profile specializations mapped to this category only.
for (final name
    in _profileSpecializationsByCategory[categoryKey] ??
        <String>{}) {
  addSpecialization(name);
}

  final updated = unique.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  if (!mounted) return;

  setState(() {
    specializations = updated;
    isLoading = false;
  });
}
  // ============================================================
  // FILTER SPECIALIZATIONS
  // ============================================================

  List<String> get filteredSpecializations {
    final search =
        searchController.text.trim().toLowerCase();

    if (search.isEmpty) {
      return specializations;
    }

    return specializations
        .where(
          (specialization) => specialization
              .toLowerCase()
              .contains(search),
        )
        .toList();
  }

@override
void initState() {
  super.initState();

  // Immediately display the built-in items for the selected category.
  specializations = List<String>.from(
    _builtInSpecializationsByCategory.entries
        .where(
          (entry) =>
              entry.key.toLowerCase() ==
              widget.selectedCategory.trim().toLowerCase(),
        )
        .expand((entry) => entry.value),
  );

  searchController.addListener(_onSearchChanged);

  _listenToDoctorSpecializations();
  _listenToDoctorSpecializationCounts();
}

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {});
  }

void _listenToDoctorSpecializationCounts() {
  _doctorSpecializationSubscription?.cancel();

  _doctorSpecializationSubscription = firestore
      .collection('doctors')
      .where('isOnline', isEqualTo: true)
      .snapshots()
      .listen(
    (snapshot) {
      if (!mounted) return;

      final Map<String, int> counts = {};

      final selectedCategory =
          widget.selectedCategory.trim().toLowerCase();

      for (final document in snapshot.docs) {
        final data = document.data();
        final categories = data['categories'];

        if (categories is! List) continue;

        final belongsToCategory = categories.any(
          (item) =>
              item is String &&
              item.trim().toLowerCase() == selectedCategory,
        );

        if (!belongsToCategory) continue;

        List<dynamic> categorySpecializations = [];

        final rawMapping = data['specializationsByCategory'];

        if (rawMapping is Map) {
          // Use only the selected category's specialization list.
          for (final entry in rawMapping.entries) {
            if (entry.key.toString().trim().toLowerCase() ==
                selectedCategory) {
              if (entry.value is List) {
                categorySpecializations = entry.value as List;
              }

              break;
            }
          }
        } else if (categories.length == 1) {
          // Safe fallback for old profiles with one category.
          final values = data['specializations'];

          if (values is List) {
            categorySpecializations = values;
          }
        }

        final uniqueSpecializations = <String>{};

        for (final item in categorySpecializations) {
          if (item is String && item.trim().isNotEmpty) {
            uniqueSpecializations.add(item.trim().toLowerCase());
          }
        }

        for (final specialization in uniqueSpecializations) {
          counts.update(
            specialization,
            (currentCount) => currentCount + 1,
            ifAbsent: () => 1,
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _doctorCountsBySpecialization
          ..clear()
          ..addAll(counts);
      });
    },
    onError: (Object error) {
      debugPrint(
        'Doctor specialization count listener error: $error',
      );
    },
  );
}
  // ============================================================
  // SPECIALIZATION ICON
  // ============================================================

  IconData specializationIcon(
    String specialization,
  ) {
    final value =
        specialization.toLowerCase();

    if (value.contains('cardio')) {
      return Icons.favorite_outline;
    }

    if (value.contains('dermat')) {
      return Icons.face_outlined;
    }

    if (value.contains('pediatric')) {
      return Icons.child_care_outlined;
    }

    if (value.contains('gynec')) {
      return Icons.pregnant_woman_outlined;
    }

    if (value.contains('obstetric')) {
      return Icons.pregnant_woman_outlined;
    }

    if (value.contains('orthopedic')) {
      return Icons.accessibility_new_outlined;
    }

    if (value.contains('neurolog')) {
      return Icons.psychology_outlined;
    }

    if (value.contains('psychiatr')) {
      return Icons.psychology_outlined;
    }

    if (value.contains('psycholog')) {
      return Icons.psychology_outlined;
    }

    if (value.contains('dent')) {
      return Icons.medical_services_outlined;
    }

    if (value.contains('ophthalm')) {
      return Icons.visibility_outlined;
    }

    if (value == 'ent') {
      return Icons.hearing_outlined;
    }

    if (value.contains('urolog')) {
      return Icons.water_drop_outlined;
    }

    if (value.contains('gastro')) {
      return Icons.restaurant_outlined;
    }

    if (value.contains('pulmon')) {
      return Icons.air_outlined;
    }

    if (value.contains('endocrin')) {
      return Icons.monitor_heart_outlined;
    }

    if (value.contains('oncolog')) {
      return Icons.health_and_safety_outlined;
    }

    if (value.contains('radiolog')) {
      return Icons.image_outlined;
    }

    if (value.contains('patholog')) {
      return Icons.biotech_outlined;
    }

    if (value.contains('anesthes')) {
      return Icons.medical_services_outlined;
    }

    if (value.contains('plastic')) {
      return Icons.face_retouching_natural_outlined;
    }

    if (value.contains('neurosurg')) {
      return Icons.psychology_outlined;
    }

    if (value.contains('cardiac')) {
      return Icons.favorite_outline;
    }

    if (value.contains('diabet')) {
      return Icons.bloodtype_outlined;
    }

    if (value.contains('general')) {
      return Icons.medical_services_outlined;
    }

    return Icons.local_hospital_outlined;
  }

  // ============================================================
  // SPECIALIZATION DESCRIPTION
  // ============================================================

  String specializationDescription(
    String specialization,
  ) {
    final value =
        specialization.toLowerCase();

    if (value.contains('cardio')) {
      return 'Heart and cardiovascular care';
    }

    if (value.contains('neurolog')) {
      return 'Brain and nervous system care';
    }

    if (value.contains('nephrolog')) {
      return 'Kidney and renal care';
    }

    if (value.contains('dermat')) {
      return 'Skin and hair care';
    }

    if (value.contains('pediatric')) {
      return 'Children’s healthcare';
    }

    if (value.contains('gynec')) {
      return 'Women’s health care';
    }

    if (value.contains('obstetric')) {
      return 'Pregnancy and childbirth care';
    }

    if (value.contains('orthopedic')) {
      return 'Bones, joints and muscles';
    }

    if (value.contains('psychiatr')) {
      return 'Mental health care';
    }

    if (value.contains('psycholog')) {
      return 'Psychological and emotional care';
    }

    if (value == 'ent') {
      return 'Ear, nose and throat care';
    }

    if (value.contains('ophthalm')) {
      return 'Eye care and treatment';
    }

    if (value.contains('dent')) {
      return 'Dental and oral care';
    }

    if (value.contains('urolog')) {
      return 'Urinary and reproductive health';
    }

    if (value.contains('gastro')) {
      return 'Digestive system care';
    }

    if (value.contains('pulmon')) {
      return 'Lung and respiratory care';
    }

    if (value.contains('endocrin')) {
      return 'Hormones and endocrine care';
    }

    if (value.contains('oncolog')) {
      return 'Cancer diagnosis and treatment';
    }

    if (value.contains('radiolog')) {
      return 'Medical imaging and diagnosis';
    }

    if (value.contains('patholog')) {
      return 'Laboratory diagnosis and testing';
    }

    if (value.contains('anesthes')) {
      return 'Anesthesia and perioperative care';
    }

    if (value.contains('general surgery')) {
      return 'General surgical care';
    }

    if (value.contains('plastic')) {
      return 'Reconstructive and cosmetic surgery';
    }

    if (value.contains('neurosurg')) {
      return 'Brain and spinal surgery';
    }

    if (value.contains('cardiac')) {
      return 'Heart surgery and treatment';
    }

    if (value.contains('diabet')) {
      return 'Diabetes and metabolic care';
    }

    return 'Medical specialist';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filtered =
        filteredSpecializations;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8F7),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Doctor Specializations',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                8,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a Specialization',
                    style: TextStyle(
                      color:
                          Color(0xFF12652F),
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    widget.selectedCategory,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // SEARCH BOX
                  // ==================================================

                  Container(
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      border: Border.all(
                        color:
                            Colors.grey.shade300,
                      ),
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
                            'Search specialization',

                        hintStyle:
                            const TextStyle(
                          color: Colors.grey,
                        ),

                        prefixIcon:
                            const Icon(
                          Icons.search,
                          color:
                              Color(0xFF12652F),
                        ),

                        suffixIcon:
                            searchController
                                    .text
                                    .isNotEmpty
                                ? IconButton(
                                    icon:
                                        const Icon(
                                      Icons.clear,
                                    ),
                                    onPressed: () {
                                      searchController
                                          .clear();

                                      searchFocusNode
                                          .requestFocus();
                                    },
                                  )
                                : null,

                        border:
                            InputBorder.none,

                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '${filtered.length} specialization${filtered.length == 1 ? '' : 's'} available',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ======================================================
            // SPECIALIZATION LIST
            // ======================================================

            Expanded(
              child: isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            Color(0xFF12652F),
                      ),
                    )
                  : filtered.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            16,
                            8,
                            16,
                            24,
                          ),

                          itemCount:
                              filtered.length,

                          itemBuilder:
                              (context, index) {
                            final specialization =
                                filtered[index];

                            return _specializationCard(
                              specialization,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SPECIALIZATION CARD
  // ============================================================

  Widget _specializationCard(
    String specialization,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color: Colors.grey.shade200,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 5,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius:
              BorderRadius.circular(14),

          onTap: () {
            selectSpecialization(
              specialization,
            );
          },

          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),

            child: Row(
              children: [
                // ==================================================
                // ICON
                // ==================================================


                // ==================================================
// SPECIALIZATION ICON WITH GREEN COUNT BADGE
// ==================================================

Builder(
  builder: (context) {
    final count =
        _doctorCountsBySpecialization[
              specialization.trim().toLowerCase()
            ] ??
            0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF12652F).withValues(
              alpha: 0.09,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            specializationIcon(specialization),
            color: const Color(0xFF12652F),
            size: 25,
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
                color: const Color(0xFF16803C),
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

                const SizedBox(width: 13),

                // ==================================================
                // TEXT
                // ==================================================

                Expanded(
                  child: 
                 
                  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      specialization,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),

    const SizedBox(height: 4),

    Text(
      specializationDescription(specialization),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.black54,
        fontSize: 13,
      ),
    ),

    if ((_userAddedSpecializationsByCategory[
                widget.selectedCategory.trim().toLowerCase()] ??
            <String>{})
        .any(
          (item) =>
              item.toLowerCase() == specialization.toLowerCase(),
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

                const Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  size: 17,
                  color: Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.search_off_rounded,
              size: 55,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 15),

            const Text(
              'No specialization found',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Try searching with a different name.',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SELECT SPECIALIZATION
  // ============================================================

  Future<void> selectSpecialization(
    String specialization,
  ) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      // ========================================================
      // FIND DOCTORS WITH SELECTED CATEGORY
      // ========================================================

      final snapshot = await firestore
          .collection('doctors')
          .where(
            'categories',
            arrayContains:
                widget.selectedCategory,
          )
          .get();

      final matchingDoctors =
          <Map<String, dynamic>>[];

      // ========================================================
      // FILTER BY SELECTED SPECIALIZATION
      // ========================================================

      for (final document
          in snapshot.docs) {
        final data = document.data();

        final doctorSpecializations =
            data['specializations'];

        if (doctorSpecializations
            is List) {
          final matchesSpecialization =
              doctorSpecializations.any(
            (item) =>
                item is String &&
                item.trim().toLowerCase() ==
                    specialization
                        .trim()
                        .toLowerCase(),
          );

          if (matchesSpecialization) {
            final doctorData =
                Map<String, dynamic>.from(
              data,
            );

            doctorData['doctorId'] =
                document.id;

            matchingDoctors.add(
              doctorData,
            );
          }
        }
      }

      if (!mounted) return;

      // ========================================================
      // NO DOCTORS FOUND
      // ========================================================

      if (matchingDoctors.isEmpty) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'No doctor is currently available for this specialization.',
            ),
          ),
        );

        return;
      }

      // ========================================================
      // OPEN DOCTOR RESULTS
// ========================================================

await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) =>
        ScreenDoctorResults(
      selectedCategory:
          widget.selectedCategory,
      selectedSpecialization:
          specialization,
      doctors:
          matchingDoctors,
    ),
  ),
);

if (!mounted) return;

setState(() {
  isLoading = false;
});
    } catch (e) {
      debugPrint(
        'Error finding doctors: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to find doctors. Please try again.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

@override
void dispose() {
  _sharedSpecializationsSubscription?.cancel();
  _doctorProfilesSpecializationsSubscription?.cancel();
  _doctorSpecializationSubscription?.cancel();

  searchController.removeListener(_onSearchChanged);
  searchController.dispose();
  searchFocusNode.dispose();

  super.dispose();
}
}