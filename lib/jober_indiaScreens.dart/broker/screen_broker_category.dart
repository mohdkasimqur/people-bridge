
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/broker/screen_broker_nearby.dart';

class ScreenBrokerCategories extends StatefulWidget {
  const ScreenBrokerCategories({super.key});

  @override
  State<ScreenBrokerCategories> createState() =>
      _ScreenBrokerCategoriesState();
}

class _ScreenBrokerCategoriesState
    extends State<ScreenBrokerCategories> {

  final TextEditingController searchController =
      TextEditingController();

  String searchText = '';

  // ==========================================================
  // BUILT-IN BROKER CATEGORIES
  // ==========================================================

  final List<String> brokerCategories = const [
    'Real Estate',
    'Vehicles',
    'Marriage',
  ];

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        searchText =
            searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // OPEN SELECTED CATEGORY
  // ==========================================================

  void openCategory(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenBrokerNearby(
          selectedCategory: category,
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD ALL BROKER CATEGORIES
  // BUILT-IN + CUSTOM CATEGORIES
  // ==========================================================

  List<String> buildAllCategories(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final Map<String, String> uniqueCategories = {};

    // 1. Add built-in categories.
    for (final category in brokerCategories) {
      uniqueCategories[category.toLowerCase()] = category;
    }

    // 2. Add categories saved by active brokers.
    for (final document in documents) {
      final data = document.data();

      if (data['isActive'] != true) continue;

      final dynamic savedCategories = data['categories'];

      if (savedCategories is List) {
        for (final item in savedCategories) {
          final category = item.toString().trim();

          if (category.isEmpty) continue;

          uniqueCategories.putIfAbsent(
            category.toLowerCase(),
            () => category,
          );
        }
      }

      // Support older broker documents.
      final dynamic oldCategory = data['category'];

      if (oldCategory is String) {
        for (final item in oldCategory.split(',')) {
          final category = item.trim();

          if (category.isEmpty) continue;

          uniqueCategories.putIfAbsent(
            category.toLowerCase(),
            () => category,
          );
        }
      } else if (oldCategory is List) {
        for (final item in oldCategory) {
          final category = item.toString().trim();

          if (category.isEmpty) continue;

          uniqueCategories.putIfAbsent(
            category.toLowerCase(),
            () => category,
          );
        }
      }
    }

    final result = uniqueCategories.values.toList();

    result.sort(
      (a, b) => a.toLowerCase().compareTo(
        b.toLowerCase(),
      ),
    );

    return result;
  }

  // ==========================================================
  // BUILD BROKER CATEGORY COUNTS
  // ONE BROKER COUNTS ONCE PER CATEGORY
  // ==========================================================

  Map<String, int> buildCategoryCounts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final Map<String, int> counts = {};

    for (final document in documents) {
      final data = document.data();

      if (data['isActive'] != true) continue;

      final Set<String> uniqueCategories = {};

      final dynamic savedCategories = data['categories'];

      if (savedCategories is List) {
        for (final item in savedCategories) {
          final category = item.toString().trim();

          if (category.isNotEmpty) {
            uniqueCategories.add(category.toLowerCase());
          }
        }
      }

      // Support older broker documents.
      final dynamic oldCategory = data['category'];

      if (oldCategory is String) {
        for (final item in oldCategory.split(',')) {
          final category = item.trim();

          if (category.isNotEmpty) {
            uniqueCategories.add(category.toLowerCase());
          }
        }
      } else if (oldCategory is List) {
        for (final item in oldCategory) {
          final category = item.toString().trim();

          if (category.isNotEmpty) {
            uniqueCategories.add(category.toLowerCase());
          }
        }
      }

      // Count one broker only once per category.
      for (final category in uniqueCategories) {
        counts[category] = (counts[category] ?? 0) + 1;
      }
    }

    return counts;
  }

  // ==========================================================
  // SEARCH FIELD
  // ==========================================================

  Widget _searchField() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search broker category',
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF16803C),
            size: 25,
          ),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Colors.grey,
                  ),
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
    );
  }

  // ==========================================================
  // BROKER CATEGORY CARD
  // ==========================================================

  Widget _categoryCard(String category, int count) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          openCategory(category);
        },
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
              // CATEGORY ICON
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.handshake_outlined,
                  color: Color(0xFF16803C),
                  size: 27,
                ),
              ),

              const SizedBox(width: 14),

              // CATEGORY NAME
              Expanded(
                child: Text(
                  category,
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

              // BROKER COUNT
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8EF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Color(0xFF16803C),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ARROW
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7F4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF16803C),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY SEARCH RESULT
  // ==========================================================

  Widget _emptySearchResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8EF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.search_off,
              color: Color(0xFF16803C),
              size: 38,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'No category found',
            style: TextStyle(
              color: Color(0xFF202124),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Try searching with another name.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 30,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Broker ',
                style: TextStyle(
                  color: Color(0xFF08744F),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'Categories',
                style: TextStyle(
                  color: Color(0xFFE87516),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find a broker near you',
                style: TextStyle(
                  color: Color(0xFF202124),
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Select a broker category to find nearby brokers.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              _searchField(),

              const SizedBox(height: 18),

              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('brokers')
                      .where(
                        'isActive',
                        isEqualTo: true,
                      )
                      .snapshots(),

                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Unable to load broker categories.',
                        ),
                      );
                    }

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF16803C),
                        ),
                      );
                    }

                    final documents =
                        snapshot.data?.docs ?? [];

                    final allCategories =
                        buildAllCategories(documents);

                    final categoryCounts =
                        buildCategoryCounts(documents);

                    final filtered = allCategories.where(
                      (category) {
                        return category.toLowerCase().contains(
                          searchText,
                        );
                      },
                    ).toList();

                    if (filtered.isEmpty) {
                      return _emptySearchResult();
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),

                      itemCount: filtered.length,

                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),

                      itemBuilder: (context, index) {
                        final category = filtered[index];

                        final count =
                            categoryCounts[
                                category.toLowerCase()] ??
                            0;

                        return _categoryCard(
                          category,
                          count,
                        );
                      },
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

// Map<String, int> buildCategoryCounts(
// List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
// ) {
// final Map<String, int> counts = {};

// for (final document in documents) {
//   final data = document.data();

//   if (data['isActive'] != true) continue;

//   final categories = data['categories'];

//   if (categories is! List) continue;

//   final Set<String> uniqueCategories = {};

//   for (final item in categories) {
//     final category = item.toString().trim();

//     if (category.isNotEmpty) {
//       uniqueCategories.add(category.toLowerCase());
//     }
//   }

//   for (final category in uniqueCategories) {
//     counts[category] = (counts[category] ?? 0) + 1;
//   }
// }

// return counts;

// }