import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/Groceries/grocery_nearby.dart';

class ScreenGroceryCategories extends StatefulWidget {
  const ScreenGroceryCategories({
    super.key,
  });

  @override
  State<ScreenGroceryCategories> createState() =>
      _ScreenGroceryCategoriesState();
}

class _ScreenGroceryCategoriesState
    extends State<ScreenGroceryCategories> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController searchController =
      TextEditingController();

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color darkGreen =
     // Color(0xFF12652F);
      Color(0xFF138808);

  // static const Color green =
  //     Color(0xFF198B35);

  static const Color orange =
      Color(0xFFED801D);

  static const Color background =
      Color(0xFFF7F8F7);

  // ==========================================================
  // GROCERY CATEGORIES
  // ==========================================================

  final List<String> groceryCategories = [
    'Supermarket',
    'Grocery Store',
    'Provision Store',
    'Organic Grocery',
    'Fruits & Vegetables',
    'Bakery',
    'Dairy Products',
    'Meat & Poultry',
    'Fish & Seafood',
    'Spices & Dry Fruits',
    'Rice & Grains',
    'Wholesale Grocery',
    'Frozen Foods',
    'Beverages',
    'Snacks & Packaged Foods',
    'Baby Food & Products',
    'Health & Nutrition Foods',
    'Imported Foods',
    'Home Essentials',
    'Other Grocery',
  ];

  // ==========================================================
  // FILTERED CATEGORIES
  // ==========================================================

  List<String> get filteredCategories {
    final search =
        searchController.text.trim().toLowerCase();

    if (search.isEmpty) {
      return groceryCategories;
    }

    return groceryCategories
        .where(
          (category) =>
              category.toLowerCase().contains(search),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

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
                text: 'Choose ',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'Grocery',
                style: TextStyle(
                  color: orange,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' Category',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [

            const SizedBox(height: 10),

            // ==================================================
            // DESCRIPTION
            // ==================================================

            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Find grocery shops and stores near you',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // SEARCH BOX
            // ==================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                  ),
                ),
                child: TextField(
                  controller: searchController,
                  textInputAction:
                      TextInputAction.search,

                  decoration: InputDecoration(
                    hintText:
                        'Search grocery category',

                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),

                    prefixIcon: const Icon(
                      Icons.search,
                      color: darkGreen,
                      size: 25,
                    ),

                    suffixIcon:
                        searchController.text.isNotEmpty
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

                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 17,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // CATEGORY LIST
            // ==================================================

            Expanded(
              child: filteredCategories.isEmpty
                  ? _emptySearchResult()
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        25,
                      ),

                      itemCount:
                          filteredCategories.length,

                      itemBuilder:
                          (context, index) {
                        final category =
                            filteredCategories[index];

                        return _categoryButton(
                          category,
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
  // CATEGORY BUTTON
  // ==========================================================

  Widget _categoryButton(String category) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScreenNearbyGrocery(
                  selectedCategory: category,
                ),
              ),
            );
          },

          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
              ),
            ),

            child: Row(
              children: [

                // ==================================================
                // ICON
                // ==================================================

                Container(
                  width: 48,
                  height: 48,

                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6ED),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),

                  child: const Icon(
                    Icons.local_grocery_store_outlined,
                    color: Color(0xFF12652F),
                    size: 27,
                  ),
                ),

                const SizedBox(width: 15),

                // ==================================================
                // CATEGORY NAME
                // ==================================================

                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // ==================================================
                // ARROW
                // ==================================================

                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF12652F),
                  size: 18,
                ),
              ],
            ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Container(
              width: 80,
              height: 80,

              decoration: BoxDecoration(
                color: const Color(0xFFEAF6ED),
                borderRadius:
                    BorderRadius.circular(25),
              ),

              child: const Icon(
                Icons.search_off,
                color: Color(0xFF12652F),
                size: 40,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No category found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Try searching with another grocery category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // CLEAR SEARCH BUTTON
            // ==================================================

            SizedBox(
              height: 48,

              child: ElevatedButton(
                onPressed: () {
                  searchController.clear();
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF12652F),
                  foregroundColor: Colors.white,

                  elevation: 0,

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),

                child: const Text(
                  'Clear Search',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}