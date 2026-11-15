
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/companies/company_list.dart';

class ScreenCompanyCategory extends StatefulWidget {
  const ScreenCompanyCategory({
    super.key,
  });

  @override
  State<ScreenCompanyCategory> createState() =>
      _ScreenCompanyCategoryState();
}

class _ScreenCompanyCategoryState
    extends State<ScreenCompanyCategory> {

  // ==============================================================
  // COLORS
  // ==============================================================

  static const Color darkGreen =
      Color(0xFF12652F);

  static const Color green =
      Color(0xFF138808);

  static const Color orange =
      Color(0xFFED801D);

  static const Color background =
      Color(0xFFF8F5EE);
  
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _companySubscription;

Map<String, String> _savedCategoryNames = {};

  // ==============================================================
  // FIRESTORE
  // ==============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==============================================================
  // SEARCH CONTROLLER
  // ==============================================================

  final TextEditingController _searchController =
      TextEditingController();

  // ==============================================================
  // SEARCH TEXT
  // ==============================================================

  String _searchText = '';

  // ==============================================================
  // LOADING
  // ==============================================================

  bool _loading = true;

  String? _errorMessage;

  // ==============================================================
  // DEFAULT COMPANY CATEGORIES
  // ==============================================================

  final List<String> _defaultCategories = [
    'Manufacturing Company',
    'Packing Company',
  ];

  // ==============================================================
  // ALL CATEGORIES
  // ==============================================================

  List<String> _allCategories = [];

  // ==============================================================
  // FILTERED CATEGORIES
  // ==============================================================

  List<String> _filteredCategories = [];
// Company count for each category.
Map<String, int> _categoryCounts = {};
  // ==============================================================
  // INIT STATE
  // ==============================================================

  @override
  void initState() {
    super.initState();

    _loadCategories();

    _searchController.addListener(
      _filterCategories,
    );
  }

Future<void> _loadCategories() async {
  if (!mounted) return;

  setState(() {
    _loading = true;
    _errorMessage = null;
  });

  await _companySubscription?.cancel();

  try {
    // Start with the built-in categories.
    final Map<String, String> categoryNames = {
      for (final category in _defaultCategories)
        category.toLowerCase(): category,
    };

    // Load saved custom category information.
    final categorySnapshot = await _firestore
        .collection('company_categories')
        .get();

    for (final doc in categorySnapshot.docs) {
      final data = doc.data();

      final String name =
          data['name']?.toString().trim() ?? '';

      if (name.isEmpty) continue;

      final List<dynamic> owners =
          data['companyUids'] is List
              ? data['companyUids'] as List
              : [];

      if (data['isCustom'] == true && owners.isEmpty) {
        continue;
      }

      categoryNames.putIfAbsent(
        name.toLowerCase(),
        () => name,
      );
    }

    _savedCategoryNames = categoryNames;

    // Listen for company registrations and category changes.
    _companySubscription = _firestore
        .collection('companies')
        .snapshots()
        .listen(
      (snapshot) {
        _updateCompanyCategories(snapshot.docs);
      },
      onError: (error) {
        debugPrint('Company category stream error: $error');

        if (!mounted) return;

        setState(() {
          _loading = false;
          _errorMessage =
              'Unable to load company categories.';
        });
      },
    );
  } catch (e, stackTrace) {
    debugPrint('Loading company categories failed: $e');
    debugPrint('$stackTrace');

    if (!mounted) return;

    setState(() {
      _loading = false;
      _errorMessage =
          'Some company categories could not be loaded.';
    });
  }
}

  // ==============================================================
  // FILTER CATEGORIES
  // ==============================================================

  void _filterCategories() {
    final String query =
        _searchController.text
            .trim()
            .toLowerCase();

    if (!mounted) return;

    setState(() {
      _searchText = query;

      if (query.isEmpty) {
        _filteredCategories =
            List<String>.from(
          _allCategories,
        );
      } else {
        _filteredCategories =
            _allCategories.where(
          (category) {
            return category
                .toLowerCase()
                .contains(query);
          },
        ).toList();
      }
    });
  }

  void _updateCompanyCategories(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
) {
  final Map<String, String> categoryNames = {
    ..._savedCategoryNames,
  };

  final Map<String, int> counts = {};

  for (final document in documents) {
    final data = document.data();

    // Ignore inactive companies.
    if (data['isActive'] == false) continue;

    final Set<String> uniqueCategories = {};

    // Current registration format.
    final dynamic savedCategories = data['categories'];

    if (savedCategories is List) {
      for (final item in savedCategories) {
        final String name = item.toString().trim();

        if (name.isNotEmpty) {
          uniqueCategories.add(name.toLowerCase());

          categoryNames.putIfAbsent(
            name.toLowerCase(),
            () => name,
          );
        }
      }
    }

    // Support older registration format.
    if (uniqueCategories.isEmpty) {
      final dynamic oldCategory = data['category'];

      if (oldCategory is String) {
        for (final item in oldCategory.split(',')) {
          final String name = item.trim();

          if (name.isNotEmpty) {
            uniqueCategories.add(name.toLowerCase());

            categoryNames.putIfAbsent(
              name.toLowerCase(),
              () => name,
            );
          }
        }
      } else if (oldCategory is List) {
        for (final item in oldCategory) {
          final String name = item.toString().trim();

          if (name.isNotEmpty) {
            uniqueCategories.add(name.toLowerCase());

            categoryNames.putIfAbsent(
              name.toLowerCase(),
              () => name,
            );
          }
        }
      }
    }

    // Count this company once in each category.
    for (final category in uniqueCategories) {
      counts[category] = (counts[category] ?? 0) + 1;
    }
  }

  final List<String> categoryList =
      categoryNames.values.toList()
        ..sort(
          (a, b) => a.toLowerCase().compareTo(
                b.toLowerCase(),
              ),
        );

  if (!mounted) return;

  setState(() {
    _allCategories = categoryList;
    _categoryCounts = counts;
    _loading = false;
    _errorMessage = null;

    // Preserve the current search.
    if (_searchText.isEmpty) {
      _filteredCategories =
          List<String>.from(categoryList);
    } else {
      _filteredCategories = categoryList
          .where(
            (category) => category
                .toLowerCase()
                .contains(_searchText),
          )
          .toList();
    }
  });
}
  // ==============================================================
  // DISPOSE
  // ==============================================================
@override
void dispose() {
  _companySubscription?.cancel();
  _searchController.dispose();

  super.dispose();
}

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [

            // ------------------------------------------------------
            // HEADER
            // ------------------------------------------------------

            _buildHeader(),

            // ------------------------------------------------------
            // SEARCH
            // ------------------------------------------------------

            _buildSearchBar(),

            const SizedBox(height: 8),

            // ------------------------------------------------------
            // CATEGORY CONTENT
            // ------------------------------------------------------

            Expanded(
              child: _loading
                  ? _buildLoading()
                  : _buildCategoryContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // HEADER
  // ==============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [

          // --------------------------------------------------------
          // BACK BUTTON
          // --------------------------------------------------------

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: darkGreen,
                  size: 24,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // --------------------------------------------------------
          // TITLE
          // --------------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Companies',
                  style: TextStyle(
                    color: darkGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Choose a company category',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // --------------------------------------------------------
          // COMPANY ICON
          // --------------------------------------------------------

          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.business,
              color: green,
              size: 27,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // SEARCH BAR
  // ==============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: green.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search company categories',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: green,
            ),
            suffixIcon: _searchText.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.grey,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // LOADING
  // ==============================================================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: green,
      ),
    );
  }

  // ==============================================================
  // CATEGORY CONTENT
  // ==============================================================

 Widget _buildCategoryContent() {
  if (_errorMessage != null &&
      _errorMessage!.isNotEmpty) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            8,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: orange.withValues(
                alpha: 0.30,
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: orange,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: darkGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              IconButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                icon: const Icon(
                  Icons.close,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _buildCategoryList(),
        ),
      ],
    );
  }

  return _buildCategoryList();
}
  Widget _buildCategoryList() {
  if (_filteredCategories.isEmpty) {
    return _buildEmptyState();
  }

  return RefreshIndicator(
    color: green,
    onRefresh: _loadCategories,
    child: ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        30,
      ),
      itemCount: _filteredCategories.length,
      itemBuilder: (
        context,
        index,
      ) {
        final String category =
            _filteredCategories[index];

        return _buildCategoryCard(
          category,
          index,
        );
      },
    ),
  );
}
  // ==============================================================
  // EMPTY STATE
  // ==============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: orange.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                color: orange,
                size: 42,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No category found',
              style: TextStyle(
                color: darkGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Try searching for another company category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
              },
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Clear Search',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: green,
                side: const BorderSide(
                  color: green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ==============================================================
  // CATEGORY CARD
  // ==============================================================

  Widget _buildCategoryCard(
    String category,
    int index,
  ) {
    final int count =_categoryCounts[category.toLowerCase()] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _openCompanyList(
              category,
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: green.withValues(
                  alpha: 0.12,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.045,
                  ),
                  blurRadius: 10,
                  offset: const Offset(
                    0,
                    4,
                  ),
                ),
              ],
            ),
            child: Row(
              children: [

                // --------------------------------------------------
                // CATEGORY ICON
                // --------------------------------------------------

                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(
                      index,
                    ).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Icon(
                    _getCategoryIcon(
                      category,
                    ),
                    color: _getCategoryColor(
                      index,
                    ),
                    size: 28,
                  ),
                ),

                const SizedBox(width: 15),

                // --------------------------------------------------
                // CATEGORY NAME
                // --------------------------------------------------

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkGreen,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 5),

                   Text(
  '${count > 99 ? '99+' : count} '
  '${count == 1 ? 'company' : 'companies'}',
  style: TextStyle(
    color: Colors.grey.shade600,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  ),
),
                    ],
                  ),
                ),

                // --------------------------------------------------
                // ARROW
                // --------------------------------------------------

                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: green.withValues(
                      alpha: 0.08,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: green,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // CATEGORY ICON
  // ==============================================================

  IconData _getCategoryIcon(
    String category,
  ) {
    final String text =
        category.toLowerCase();

    if (text.contains('manufactur')) {
      return Icons.factory_outlined;
    }

    if (text.contains('pack')) {
      return Icons.inventory_2_outlined;
    }

    if (text.contains('construction')) {
      return Icons.construction_outlined;
    }

    if (text.contains('technology') ||
        text.contains('software') ||
        text.contains('it')) {
      return Icons.computer_outlined;
    }

    if (text.contains('food')) {
      return Icons.restaurant_outlined;
    }

    if (text.contains('textile') ||
        text.contains('clothing')) {
      return Icons.checkroom_outlined;
    }

    if (text.contains('transport') ||
        text.contains('logistic')) {
      return Icons.local_shipping_outlined;
    }

    return Icons.business_outlined;
  }

  // ==============================================================
  // CATEGORY COLOR
  // ==============================================================

  Color _getCategoryColor(
    int index,
  ) {
    const List<Color> colors = [
      green,
      orange,
      Color(0xFF1565C0),
      Color(0xFF7B1FA2),
      Color(0xFF00838F),
      Color(0xFF6D4C41),
    ];

    return colors[
        index % colors.length];
  }

  // ==============================================================
  // OPEN COMPANY LIST
  // ==============================================================

  void _openCompanyList(
    String category,
  ) {
    // ============================================================
    // NEXT STEP
    //
    // This will open the Company List Screen.
    //
    // The Company List Screen will:
    //
    // 1. Load only companies from this category.
    // 2. Get the user's current location.
    // 3. Calculate the distance to every company.
    // 4. Sort nearest to farthest.
    // 5. Check the user's KM radius.
    // 6. Ask for payment if radius extension is required.
    // ============================================================

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyListScreen(
          selectedCategory: category,
        ),
      ),
    );
  }
}