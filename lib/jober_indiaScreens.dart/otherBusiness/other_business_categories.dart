import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/otherBusiness/categories.dart';
import 'package:jober_india/jober_indiaScreens.dart/otherBusiness/other_business_list.dart';


class ScreenOtherBusinessCategories extends StatefulWidget {
  const ScreenOtherBusinessCategories({super.key});

  @override
  State<ScreenOtherBusinessCategories> createState() =>
      _ScreenOtherBusinessCategoriesState();
}

class _ScreenOtherBusinessCategoriesState
    extends State<ScreenOtherBusinessCategories> {

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController searchController =
      TextEditingController();

  String searchText = '';

  bool loading = true;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _businessSubscription;
  StreamSubscription<
    QuerySnapshot<Map<String, dynamic>>>?
    _categorySubscription;

  final Map<String, OtherBusinessCategory> categories = {};

  Map<String, int> categoryCounts = {};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    searchController.addListener(_onSearchChanged);

    loadCategories();

    listenToOtherBusinesses();
  }

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {
      searchText = searchController.text.trim().toLowerCase();
    });
  }

  @override
void dispose() {
  _businessSubscription?.cancel();
  _categorySubscription?.cancel();

  searchController.removeListener(_onSearchChanged);
  searchController.dispose();

  super.dispose();
}

  // ============================================================
// LOAD BUILT-IN + CUSTOM CATEGORIES IN REAL TIME
// ============================================================

void loadCategories() {
  final Map<String, OtherBusinessCategory> builtIns = {};

  for (final item in defaultOtherBusinessCategories) {
    final key = categoryKey(item.name).toLowerCase();

    builtIns[key] = OtherBusinessCategory(
      name: item.name,
      key: key,
      isShopType: item.isShopType,
    );
  }

  if (!mounted) return;

  setState(() {
    categories
      ..clear()
      ..addAll(builtIns);

    loading = false;
  });
}

void listenToOtherBusinesses() {
  _businessSubscription?.cancel();

  _businessSubscription = firestore
      .collection('otherBusinesses')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .listen(
    (snapshot) {
      final Map<String, int> counts = {};
      final Map<String, OtherBusinessCategory> discovered = {};

      // Always include built-in categories.
      for (final item in defaultOtherBusinessCategories) {
        final key = categoryKey(item.name).toLowerCase();

        discovered[key] = OtherBusinessCategory(
          name: item.name,
          key: key,
          isShopType: item.isShopType,
        );

        counts[key] = 0;
      }

      // Read every active business document.
      for (final document in snapshot.docs) {
        final data = document.data();

        final Set<String> businessCategoryKeys = {};

        final dynamic savedCategories = data['categories'];

        if (savedCategories is List) {
          for (final value in savedCategories) {
            if (value is! String) continue;

            final name = value.trim();
            if (name.isEmpty) continue;

            final key = categoryKey(name).toLowerCase();

            businessCategoryKeys.add(key);

            final defaultMatch =
                defaultOtherBusinessCategories.where(
              (item) =>
                  categoryKey(item.name).toLowerCase() == key,
            );

            discovered[key] = OtherBusinessCategory(
              name: defaultMatch.isNotEmpty
                  ? defaultMatch.first.name
                  : name,
              key: key,
              isShopType: defaultMatch.isNotEmpty
                  ? defaultMatch.first.isShopType
                  : false,
            );
          }
        }

        // Support older documents that only have category.
        if (businessCategoryKeys.isEmpty) {
          final oldCategory =
              data['category']?.toString().trim() ?? '';

          if (oldCategory.isNotEmpty) {
            final key = categoryKey(oldCategory).toLowerCase();

            businessCategoryKeys.add(key);

            discovered.putIfAbsent(
              key,
              () => OtherBusinessCategory(
                name: oldCategory,
                key: key,
                isShopType: false,
              ),
            );
          }
        }

        // Count this business once per category.
        for (final key in businessCategoryKeys) {
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }

      if (!mounted) return;

      setState(() {
        categories
          ..clear()
          ..addAll(discovered);

        categoryCounts = counts;
        loading = false;
      });

      debugPrint('ACTIVE OTHER BUSINESSES: ${snapshot.docs.length}');
      debugPrint('DISPLAYED CATEGORY NAMES: '
          '${discovered.values.map((e) => e.name).toList()}');
      debugPrint('OTHER BUSINESS CATEGORY COUNTS: $counts');
    },
    onError: (error) {
      debugPrint('Other Business listener error: $error');

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    },
  );
}

  // ============================================================
  // OPEN CATEGORY
  // ============================================================

  void openCategory(OtherBusinessCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenOtherBusinessList(
          category: category.name,
          categoryKey: category.key,
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY CARD
  // ============================================================

  Widget categoryCard(
    OtherBusinessCategory category,
    int count,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openCategory(category),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE1E1E1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  category.isShopType
                      ? Icons.storefront
                      : Icons.business,
                  color: const Color(0xFF138808),
                  size: 27,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF202124),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Color(0xFF138808),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF138808),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY SEARCH RESULT
  // ============================================================

  Widget emptySearchResult() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            color: Colors.grey,
            size: 55,
          ),
          SizedBox(height: 12),
          Text(
            'No category found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try searching with another name.',
            style: TextStyle(
              color: Colors.grey,
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
    final allCategories = categories.values.toList();

    allCategories.sort(
      (a, b) => a.name.toLowerCase().compareTo(
        b.name.toLowerCase(),
      ),
    );

    final filtered = allCategories.where((category) {
      return category.name.toLowerCase().contains(searchText);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Other Business',
          style: TextStyle(
            color: Color(0xFF08744F),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find other businesses near you',
                style: TextStyle(
                  color: Color(0xFF202124),
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Select a business category to find nearby businesses.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                  ),
                ),
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search business category',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF16803C),
                      size: 25,
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 17,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF16803C),
                        ),
                      )
                    : filtered.isEmpty
                        ? emptySearchResult()
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final category = filtered[index];

                              final count = categoryCounts[
                                    category.key.toLowerCase()
                                  ] ??
                                  0;

                              return categoryCard(
                                category,
                                count,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
