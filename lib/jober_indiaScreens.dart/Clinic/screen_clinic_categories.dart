import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/Clinic/screen_clinic_list.dart';

class ClinicCategories {
  final String name;
  final IconData icon;
  final int count;

  const ClinicCategories({
    required this.name,
    required this.icon,
    this.count = 0,
  });
}

String clinicCategoryDocumentIdForList(String category) {
  return category
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

class ScreenClinicCategories extends StatefulWidget {
  const ScreenClinicCategories({super.key});

  @override
  State<ScreenClinicCategories> createState() =>
      _ScreenClinicCategoriesState();
}

class _ScreenClinicCategoriesState
    extends State<ScreenClinicCategories> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController =
      TextEditingController();

  static const Color green = Color(0xFF16803C);
  static const Color darkGreen = Color(0xFF12652F);

  final List<ClinicCategories> _builtInCategories = const [
    ClinicCategories(
      name: 'General Physician Clinic',
      icon: Icons.medical_services_outlined,
    ),
    ClinicCategories(
      name: 'Family Medicine Clinic',
      icon: Icons.family_restroom_outlined,
    ),
    ClinicCategories(
      name: 'Pediatric Clinic — children',
      icon: Icons.child_care_outlined,
    ),
    ClinicCategories(
      name: 'Gynecology Clinic — women\'s health',
      icon: Icons.woman_outlined,
    ),
    ClinicCategories(
      name: 'Obstetrics & Pregnancy Clinic',
      icon: Icons.pregnant_woman_outlined,
    ),
    ClinicCategories(
      name: 'Cardiology Clinic — heart',
      icon: Icons.favorite_border,
    ),
    ClinicCategories(
      name: 'Neurology Clinic — brain & nerves',
      icon: Icons.psychology_outlined,
    ),
    ClinicCategories(
      name: 'Dermatology Clinic — skin, hair & nails',
      icon: Icons.face_retouching_natural_outlined,
    ),
    ClinicCategories(
      name: 'ENT Clinic — ear, nose & throat',
      icon: Icons.hearing_outlined,
    ),
    ClinicCategories(
      name: 'Dental Clinic',
      icon: Icons.medical_services_outlined,
    ),
    ClinicCategories(
      name: 'Homeopathy Clinic',
      icon: Icons.local_pharmacy_outlined,
    ),
    ClinicCategories(
      name: 'Ayurveda Clinic',
      icon: Icons.spa_outlined,
    ),
    ClinicCategories(
      name: 'Siddha Clinic',
      icon: Icons.self_improvement_outlined,
    ),
    ClinicCategories(
      name: 'Unani Clinic',
      icon: Icons.local_hospital_outlined,
    ),
    ClinicCategories(
      name: 'Naturopathy & Yoga Clinic',
      icon: Icons.self_improvement_outlined,
    ),
    ClinicCategories(
      name: 'Sowa-Rigpa Clinic',
      icon: Icons.health_and_safety_outlined,
    ),
    ClinicCategories(
      name: 'Multi-Specialty Clinic',
      icon: Icons.local_hospital_outlined,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _customCategoryIcon() => Icons.local_hospital_outlined;
void _openCategory(ClinicCategories category) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ScreenClinicsNearby(
        selectedCategory: category.name,
      ),
    ),
  );
}

List<ClinicCategories> _buildCategories(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  final Map<String, int> counts = {};
  final Map<String, String> customNames = {};

  // --------------------------------------------------
  // READ ALL CLINIC PROFILES
  // --------------------------------------------------

  for (final doc in docs) {
    final data = doc.data();

    final rawCategories = data['categories'];

    if (rawCategories is! List) continue;

    // One clinic should count only once per category.
    final Set<String> clinicCategories = {};

    for (final value in rawCategories) {
      final name = value.toString().trim();

      if (name.isEmpty) continue;

      final key = name.toLowerCase();

      if (!clinicCategories.add(key)) continue;

      // Increase category count.
      counts[key] = (counts[key] ?? 0) + 1;

      // Check whether this is a built-in category.
      final isBuiltIn = _builtInCategories.any(
        (item) =>
            item.name.trim().toLowerCase() == key,
      );

      // Collect custom categories automatically.
      if (!isBuiltIn) {
        customNames.putIfAbsent(
          key,
          () => name,
        );
      }
    }
  }

  // --------------------------------------------------
  // ADD BUILT-IN CATEGORIES
  // --------------------------------------------------

  final List<ClinicCategories> result = [];

  for (final category in _builtInCategories) {
    final key = category.name.trim().toLowerCase();

    result.add(
      ClinicCategories(
        name: category.name,
        icon: category.icon,
        count: counts[key] ?? 0,
      ),
    );
  }

  // --------------------------------------------------
  // ADD CUSTOM CATEGORIES
  // --------------------------------------------------

  for (final entry in customNames.entries) {
    result.add(
      ClinicCategories(
        name: entry.value,
        icon: _customCategoryIcon(),
        count: counts[entry.key] ?? 0,
      ),
    );
  }

  // --------------------------------------------------
  // SEARCH FILTER
  // --------------------------------------------------

  final query =
      _searchController.text.trim().toLowerCase();

  if (query.isEmpty) return result;

  return result.where((category) {
    return category.name.toLowerCase().contains(query);
  }).toList();
}

  Widget _buildCategoryCard(ClinicCategories category) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openCategory(category),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                category.icon,
                color: green,
                size: 23,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 30),
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                category.count > 99 ? '99+' : '${category.count}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: darkGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'No clinic categories found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Try another clinic category name.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Clinic Categories',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search clinic category',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: green,
                    size: 21,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF9F9F9),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: green,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 5, 15, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select a clinic category',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: firestore
    .collection('clinics')
    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Unable to load clinic categories. Please try again.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: green,
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final categories = _buildCategories(docs);

                  if (categories.isEmpty) {
                    return _buildNoResults();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 3, 14, 20),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return _buildCategoryCard(categories[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}