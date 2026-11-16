import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jober_india/jober_indiaScreens.dart/spareparts/screen_spare_parts_shoplist.dart';

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

                separatorBuilder: (_, _) =>
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