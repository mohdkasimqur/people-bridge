import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:jober_india/jober_indiaScreens.dart/workers/screen_workers_nearby.dart';

// ============================================================
// WORKER CATEGORY MODEL
// ============================================================

class WorkerCategory {
  final String name;
  final IconData icon;

  const WorkerCategory({
    required this.name,
    required this.icon,
  });
}

// ============================================================
// WORKER CATEGORIES SCREEN
// ============================================================

class ScreenWorkerCategories extends StatefulWidget {
  const ScreenWorkerCategories({super.key});

  @override
  State<ScreenWorkerCategories> createState() =>
      _ScreenWorkerCategoriesState();
}

class _ScreenWorkerCategoriesState
    extends State<ScreenWorkerCategories> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  // Standard categories always remain visible.
  final List<String> _standardCategoryNames = [
    'AC Technician',
    'Aluminium Worker',
    'Appliance Repair',
    'Baker',
    'Beautician',
    'Bike Mechanic',
    'Car Mechanic',
    'Carpenter',
    'Care Taker',
    'CCTV Technician',
    'Chef',
    'Computer Technician',
    'Construction Worker',
    'Cook',
    'Delivery Worker',
    'Driver',
    'Electrician',
    'Electrician Helper',
    'Fabricator',
    'Flooring Worker',
    'Glass Worker',
    'Gardener',
    'Hairdresser',
    'House Cleaner',
    'Interior Worker',
    'Laundry Worker',
    'Maid',
    'Mason',
    'Mechanic',
    'Mobile Repair Technician',
    'Network Technician',
    'Nurse',
    'Office Cleaner',
    'Painter',
    'Pest Control Technician',
    'Physiotherapist',
    'Plaster Worker',
    'Plumber',
    'Plumber Helper',
    'Refrigerator Technician',
    'Roofer',
    'RO Water Purifier Technician',
    'Security Guard',
    'Solar Technician',
    'Tailor',
    'Tile Worker',
    'TV Technician',
    'Watchman',
    'Welder',
  ];

  // ==========================================================
  // CATEGORY ICONS
  // Known categories keep suitable icons.
  // Custom categories receive a default worker icon.
  // ==========================================================

  IconData _getCategoryIcon(String name) {
    switch (name.trim().toLowerCase()) {
      case 'electrician':
      case 'electrical worker':
        return Icons.electrical_services_outlined;

      case 'electrician helper':
      case 'plumber helper':
        return Icons.handyman_outlined;

      case 'plumber':
        return Icons.plumbing_outlined;

      case 'carpenter':
        return Icons.carpenter_outlined;

      case 'mason':
      case 'construction worker':
        return Icons.construction_outlined;

      case 'painter':
        return Icons.format_paint_outlined;

      case 'welder':
      case 'fabricator':
        return Icons.hardware_outlined;

      case 'mechanic':
      case 'car mechanic':
      case 'bike mechanic':
        return Icons.car_repair_outlined;

      case 'ac technician':
        return Icons.ac_unit_outlined;

      case 'refrigerator technician':
      case 'appliance repair':
        return Icons.kitchen_outlined;

      case 'tv technician':
        return Icons.tv_outlined;

      case 'mobile repair technician':
        return Icons.phone_android_outlined;

      case 'computer technician':
        return Icons.computer_outlined;

      case 'network technician':
        return Icons.wifi_outlined;

      case 'cctv technician':
        return Icons.videocam_outlined;

      case 'solar technician':
        return Icons.solar_power_outlined;

      case 'ro water purifier technician':
        return Icons.water_drop_outlined;

      case 'driver':
        return Icons.drive_eta_outlined;

      case 'delivery worker':
        return Icons.delivery_dining_outlined;

      case 'cook':
        return Icons.restaurant_outlined;

      case 'chef':
        return Icons.restaurant_menu_outlined;

      case 'baker':
        return Icons.bakery_dining_outlined;

      case 'maid':
      case 'house cleaner':
      case 'office cleaner':
        return Icons.cleaning_services_outlined;

      case 'gardener':
        return Icons.grass_outlined;

      case 'security guard':
        return Icons.security_outlined;

      case 'watchman':
        return Icons.visibility_outlined;

      case 'care taker':
        return Icons.volunteer_activism_outlined;

      case 'nurse':
        return Icons.local_hospital_outlined;

      case 'physiotherapist':
        return Icons.accessibility_new_outlined;

      case 'beautician':
        return Icons.face_retouching_natural_outlined;

      case 'hairdresser':
        return Icons.content_cut_outlined;

      case 'tailor':
        return Icons.design_services_outlined;

      case 'laundry worker':
        return Icons.local_laundry_service_outlined;

      case 'pest control worker':
      case 'pest control technician':
        return Icons.pest_control_outlined;

      case 'tile worker':
        return Icons.grid_4x4_outlined;

      case 'flooring worker':
        return Icons.layers_outlined;

      case 'roofer':
        return Icons.roofing_outlined;

      case 'glass worker':
        return Icons.window_outlined;

      case 'aluminium worker':
        return Icons.domain_outlined;

      case 'plaster worker':
        return Icons.format_shapes_outlined;

      case 'interior worker':
        return Icons.weekend_outlined;

      default:
        return Icons.engineering_outlined;
    }
  }

  // ==========================================================
  // OPEN SELECTED CATEGORY
  // ==========================================================

  void _openCategory(WorkerCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenWorkerNearby(
          categoryId: category.name,
          categoryName: category.name,
        ),
      ),
    );
  }

  // ==========================================================
  // CATEGORY CARD
  // ==========================================================

  Widget _buildCategoryCard(
    WorkerCategory category,
    int workerCount,
  ) {
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
          border: Border.all(
            color: Colors.grey.shade200,
          ),
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
                color: const Color(0xFF16803C)
                    .withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                category.icon,
                color: const Color(0xFF16803C),
                size: 23,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            if (workerCount > 0)
  Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 9,
      vertical: 5,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFF16803C)
          .withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.notifications_active_outlined,
          color: Color(0xFF16803C),
          size: 15,
        ),
        const SizedBox(width: 4),
        Text(
          '$workerCount',
          style: const TextStyle(
            color: Color(0xFF16803C),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  ),

const SizedBox(width: 5),
            const SizedBox(width: 5),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade500,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // NO RESULTS
  // ==========================================================

  Widget _buildNoResults(String message) {
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Categories appear when workers are online.',
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

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Worker Categories',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SEARCH
            Padding(
              padding: const EdgeInsets.fromLTRB(
                14, 12, 14, 8,
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search worker category',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 21,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
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
                      color: Color(0xFF16803C),
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
                  'Available worker categories',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            // REAL-TIME WORKER CATEGORIES
 
  Expanded(
  child: StreamBuilder<
      QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('workerCategories')
        .snapshots(),
    builder: (context, categorySnapshot) {
      if (categorySnapshot.hasError) {
        return _buildNoResults(
          'Unable to load worker categories.',
        );
      }

      if (categorySnapshot.connectionState ==
              ConnectionState.waiting &&
          !categorySnapshot.hasData) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF16803C),
          ),
        );
      }

      // Read registered custom categories.
      final Map<String, WorkerCategory> categoryByKey = {};

      void addCategory(String name) {
        final cleanName = name.trim();
        if (cleanName.isEmpty) return;

        final key = cleanName.toLowerCase();

        categoryByKey.putIfAbsent(
          key,
          () => WorkerCategory(
            name: cleanName,
            icon: _getCategoryIcon(cleanName),
          ),
        );
      }

      // 1. Always include standard categories.
      for (final name in _standardCategoryNames) {
        addCategory(name);
      }

      // 2. Include categories saved in the registry.
      for (final document
          in categorySnapshot.data?.docs ?? []) {
        final data = document.data();

        final name = data['name']?.toString().trim();

        if (name != null && name.isNotEmpty) {
          addCategory(name);
        }
      }

      // 3. Get real-time online worker counts.
      return StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('workers')
            .where('isOnline', isEqualTo: true)
            .snapshots(),
        builder: (context, workerSnapshot) {
          if (workerSnapshot.hasError) {
            return _buildNoResults(
              'Unable to load online worker counts.',
            );
          }

          if (workerSnapshot.connectionState ==
                  ConnectionState.waiting &&
              !workerSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF16803C),
              ),
            );
          }

          final workerDocuments =
              workerSnapshot.data?.docs ?? [];

          // Each worker is counted only once per category.
          final Map<String, Set<String>>
              workerIdsByCategory = {};

          for (final document in workerDocuments) {
            final data = document.data();

            if (data['isOnline'] != true) continue;

            final rawCategories = data['categories'];

            if (rawCategories is! List) continue;

            final Set<String> processedCategories = {};

            for (final rawCategory in rawCategories) {
              if (rawCategory is! String) continue;

              final name = rawCategory.trim();
              if (name.isEmpty) continue;

              final key = name.toLowerCase();

              // Include online categories even if they
              // have not yet been added to the registry.
              addCategory(name);

              if (!processedCategories.add(key)) {
                continue;
              }

              workerIdsByCategory
                  .putIfAbsent(key, () => <String>{})
                  .add(document.id);
            }
          }

          // Count distinct online worker documents.
          final int totalOnlineWorkers =
              workerDocuments
                  .map((doc) => doc.id)
                  .toSet()
                  .length;

          final categories = categoryByKey.entries
              .where((entry) {
                return entry.value.name
                    .toLowerCase()
                    .contains(_searchQuery);
              })
              .map((entry) => entry.value)
              .toList()
            ..sort(
              (a, b) => a.name
                  .toLowerCase()
                  .compareTo(
                    b.name.toLowerCase(),
                  ),
            );

          return Column(
            children: [
              // TOTAL ONLINE WORKERS
              Container(
                margin: const EdgeInsets.fromLTRB(
                  14, 0, 14, 12,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.groups_outlined,
                      color: Color(0xFF16803C),
                      size: 27,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Workers online',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      '$totalOnlineWorkers',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16803C),
                      ),
                    ),
                  ],
                ),
              ),

              // CATEGORY LIST
              Expanded(
                child: categories.isEmpty
                    ? _buildNoResults(
                        'No matching worker categories found.',
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(
                          14, 3, 14, 20,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category =
                              categories[index];

                          final key =
                              category.name.toLowerCase();

                          final count =
                              workerIdsByCategory[key]
                                      ?.length ??
                                  0;

                          return _buildCategoryCard(
                            category,
                            count,
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
),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}