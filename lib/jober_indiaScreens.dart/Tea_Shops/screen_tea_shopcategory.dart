import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/Tea_Shops/screentea_shop_list.dart';


// ============================================================
// TEA SHOP CATEGORIES SCREEN
// ============================================================

class ScreenTeaShopCategories extends StatefulWidget {

  const ScreenTeaShopCategories({
    super.key,
  });

  @override
  State<ScreenTeaShopCategories>
      createState() =>
          _ScreenTeaShopCategoriesState();
}


// ============================================================
// STATE
// ============================================================

class _ScreenTeaShopCategoriesState
    extends State<ScreenTeaShopCategories> {

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color darkGreen =
      Color(0xFF12652F);

  static const Color green =
      Color(0xFF138808);

  static const Color orange =
      Color(0xFFED801D);

  static const Color background =
      Color(0xFFF8F8F8);


  // ==========================================================
  // SEARCH CONTROLLER
  // ==========================================================

  final TextEditingController
      searchController =
      TextEditingController();


  // ==========================================================
  // SEARCH FOCUS NODE
  // ==========================================================

  final FocusNode
      searchFocusNode =
      FocusNode();


  // ==========================================================
  // SEARCH TEXT
  // ==========================================================

  String searchText = '';


  // ==========================================================
  // TEA SHOP CATEGORIES
  // ==========================================================

  final List<Map<String, dynamic>>
      teaShopCategories = [

    {
      'name':
          'Coffee Shops',

      'icon':
          Icons.coffee,

      'description':
          'Find nearby coffee shops',
    },

    {
      'name':
          'Tea Shops',

      'icon':
          Icons.local_cafe,

      'description':
          'Find nearby tea shops',
    },

    {
      'name':
          'Hotel',

      'icon':
          Icons.hotel,

      'description':
          'Find nearby hotels',
    },

    {
      'name':
          'Restaurants',

      'icon':
          Icons.restaurant,

      'description':
          'Find nearby restaurants',
    },

    {
      'name':
          'Thattukada',

      'icon':
          Icons.fastfood,

      'description':
          'Find nearby thattukadas',
    },
  ];


  // ==========================================================
  // FILTERED CATEGORIES
  // ==========================================================

  List<Map<String, dynamic>>
      get filteredCategories {

    final query =
        searchText
            .trim()
            .toLowerCase();


    // --------------------------------------------------------
    // SHOW ALL CATEGORIES
    // --------------------------------------------------------

    if (query.isEmpty) {

      return teaShopCategories;
    }


    // --------------------------------------------------------
    // FILTER CATEGORIES
    // --------------------------------------------------------

    return teaShopCategories
        .where(
          (category) {

            final name =
                category['name']
                    .toString()
                    .toLowerCase();

            final description =
                category['description']
                    .toString()
                    .toLowerCase();


            return name.contains(query) ||
                description.contains(query);
          },
        )
        .toList();
  }


  // ==========================================================
  // INIT STATE
  // ==========================================================

  @override
  void initState() {

    super.initState();


    // --------------------------------------------------------
    // LISTEN TO SEARCH CHANGES
    // --------------------------------------------------------

    searchController.addListener(
      _onSearchChanged,
    );
  }


  // ==========================================================
  // SEARCH CHANGED
  // ==========================================================

  void _onSearchChanged() {

    if (!mounted) {
      return;
    }


    setState(() {

      searchText =
          searchController.text;
    });
  }


  // ==========================================================
  // OPEN SELECTED CATEGORY
  //
  // PART 3 WILL CONNECT THIS
  // TO THE NEARBY SHOP LIST SCREEN.
  // ==========================================================

 void openCategory(
  String categoryName,
) {

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          ScreenTeaShopList(
        selectedCategory:
            categoryName,
      ),
    ),
  );
}

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {

    searchController.dispose();

    searchFocusNode.dispose();

    super.dispose();
  }
  // ==========================================================
  // PAGE HEADER
  // ==========================================================

  Widget pageHeader() {

    return Container(

      width:
          double.infinity,

      padding:
          const EdgeInsets.fromLTRB(
        24,
        25,
        24,
        30,
      ),

      decoration:
          const BoxDecoration(

        gradient:
            LinearGradient(

          colors: [
            darkGreen,
            green,
          ],

          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.only(

          bottomLeft:
              Radius.circular(30),

          bottomRight:
              Radius.circular(30),
        ),
      ),

      child:
          SafeArea(

        bottom:
            false,

        child:
            Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ------------------------------------------------
            // ICON
            // ------------------------------------------------

            const Icon(

              Icons.local_cafe,

              size:
                  45,

              color:
                  Colors.white,
            ),


            const SizedBox(
              height:
                  12,
            ),


            // ------------------------------------------------
            // TITLE
            // ------------------------------------------------

            const Text(

              'Food & Tea Shops',

              style:
                  TextStyle(

                fontSize:
                    27,

                fontWeight:
                    FontWeight.bold,

                color:
                    Colors.white,
              ),
            ),


            const SizedBox(
              height:
                  6,
            ),


            // ------------------------------------------------
            // DESCRIPTION
            // ------------------------------------------------

            const Text(

              'Find nearby tea shops, coffee shops, '
              'restaurants and more.',

              style:
                  TextStyle(

                fontSize:
                    14,

                color:
                    Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // SEARCH SECTION
  // ==========================================================

  Widget searchSection() {

    return Container(

      padding:
          const EdgeInsets.symmetric(
        horizontal:
            20,
      ),

      child:
          TextField(

        controller:
            searchController,

        focusNode:
            searchFocusNode,

        textInputAction:
            TextInputAction.search,

        decoration:
            InputDecoration(

          hintText:
              'Search categories',

          prefixIcon:
              const Icon(

            Icons.search,

            color:
                green,
          ),


          // ----------------------------------------------
          // CLEAR BUTTON
          // ----------------------------------------------

          suffixIcon:
              searchText.isNotEmpty

                  ? IconButton(

                      onPressed:
                          () {

                        searchController
                            .clear();

                        FocusScope.of(
                          context,
                        ).unfocus();
                      },

                      icon:
                          const Icon(

                        Icons.clear,

                        color:
                            Colors.grey,
                      ),
                    )

                  : null,


          filled:
              true,

          fillColor:
              Colors.white,


          contentPadding:
              const EdgeInsets.symmetric(
            vertical:
                16,
          ),


          border:
              OutlineInputBorder(

            borderRadius:
                BorderRadius.circular(
              16,
            ),

            borderSide:
                BorderSide(
              color:
                  Colors.grey.shade300,
            ),
          ),


          enabledBorder:
              OutlineInputBorder(

            borderRadius:
                BorderRadius.circular(
              16,
            ),

            borderSide:
                BorderSide(
              color:
                  Colors.grey.shade300,
            ),
          ),


          focusedBorder:
              OutlineInputBorder(

            borderRadius:
                BorderRadius.circular(
              16,
            ),

            borderSide:
                const BorderSide(

              color:
                  green,

              width:
                  2,
            ),
          ),
        ),
      ),
    );
  }

List<String> _getShopCategoryNames(
  Map<String, dynamic> data,
) {
  final dynamic rawCategories = data['categories'];

  List<String> result = [];

  if (rawCategories is List) {
    result = rawCategories
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList();
  } else {
    final String oldCategory =
        (data['category'] ?? '').toString();

    result = oldCategory
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  // Remove duplicate categories.
  final Map<String, String> unique = {};

  for (final category in result) {
    unique.putIfAbsent(
      category.toLowerCase(),
      () => category,
    );
  }

  return unique.values.toList();
}

  Widget categoryCard(
    Map<String, dynamic> category,int count,
  ) {

    final String categoryName =
        category['name']
            .toString();

    final String description =
        category['description']
            .toString();

    final IconData icon =
        category['icon'] as IconData;


    return Container(

      margin:
          const EdgeInsets.only(
        bottom:
            14,
      ),

      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        boxShadow: [

          BoxShadow(

            color:
                Colors.black.withValues(
              alpha:
                  0.06,
            ),

            blurRadius:
                10,

            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child:
          Material(

        color:
            Colors.transparent,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        child:
            InkWell(

          borderRadius:
              BorderRadius.circular(
            18,
          ),

          onTap:
              () {

            openCategory(
              categoryName,
            );
          },

          child:
              Padding(

            padding:
                const EdgeInsets.all(
              16,
            ),

            child:
                Row(

              children: [

                // ------------------------------------------
                // CATEGORY ICON
                // ------------------------------------------

                Container(

                  width:
                      58,

                  height:
                      58,

                  decoration:
                      BoxDecoration(

                    color:
                        green.withValues(
                      alpha:
                          0.12,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),

                  child:
                      Icon(

                    icon,

                    size:
                        30,

                    color:
                        green,
                  ),
                ),


                const SizedBox(
                  width:
                      16,
                ),


                // ------------------------------------------
                // NAME + DESCRIPTION
                // ------------------------------------------

                Expanded(

                  child:
                      Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(

                        categoryName,

                        style:
                            const TextStyle(

                          fontSize:
                              17,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),


                      const SizedBox(
                        height:
                            5,
                      ),


                      Text(

                        description,

                        style:
                            const TextStyle(

                          fontSize:
                              13,

                          color:
                              Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

    // AVAILABLE SHOP COUNT
if (count > 0) ...[
  const SizedBox(width: 8),

  Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 9,
      vertical: 5,
    ),
    decoration: BoxDecoration(
      color: green,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      count > 99 ? '99+' : count.toString(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

  const SizedBox(width: 8),
],
                // ------------------------------------------
                // ARROW
                // ------------------------------------------

                const Icon(

                  Icons.arrow_forward_ios,

                  size:
                      18,

                  color:
                      orange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget categoryList() {
  return StreamBuilder<
      QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('tea_shops')
        .snapshots(),

    builder: (context, snapshot) {

      if (snapshot.hasError) {
        return const Center(
          child: Text(
            'Unable to load shop categories.',
          ),
        );
      }

      if (snapshot.connectionState ==
              ConnectionState.waiting &&
          !snapshot.hasData) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      final shops = snapshot.data?.docs ?? [];

      // --------------------------------------------------------
      // CATEGORY NAMES AND COUNTS
      // --------------------------------------------------------

      final Map<String, String> categoryNames = {};
      final Map<String, int> categoryCounts = {};

      // --------------------------------------------------------
      // ADD DEFAULT CATEGORIES FIRST
      // --------------------------------------------------------

      for (final category in teaShopCategories) {
        final name = category['name'].toString().trim();
        final normalized = name.toLowerCase();

        categoryNames[normalized] = name;
        categoryCounts[normalized] = 0;
      }

      // --------------------------------------------------------
      // READ CATEGORIES FROM EVERY REGISTERED SHOP
      // --------------------------------------------------------

      for (final shop in shops) {

        final data = shop.data();

        final shopCategories =
            _getShopCategoryNames(data);

        // One shop should count only once per category.
        final Set<String> uniqueCategories = {};

        for (final category in shopCategories) {

          final normalized =
              category.trim().toLowerCase();

          if (normalized.isEmpty) continue;

          uniqueCategories.add(normalized);

          // Add custom category automatically.
          categoryNames.putIfAbsent(
            normalized,
            () => category.trim(),
          );

          categoryCounts.putIfAbsent(
            normalized,
            () => 0,
          );
        }

        // ------------------------------------------------------
        // INCREMENT CATEGORY COUNTS
        // ------------------------------------------------------

        for (final category in uniqueCategories) {
          categoryCounts[category] =
              (categoryCounts[category] ?? 0) + 1;
        }
      }

      // --------------------------------------------------------
      // CUSTOM CATEGORIES
      // SORT ALPHABETICALLY
      // --------------------------------------------------------

      final Set<String> defaultNames =
          teaShopCategories
              .map(
                (category) => category['name']
                    .toString()
                    .trim()
                    .toLowerCase(),
              )
              .toSet();

      final customCategoryKeys =
          categoryNames.keys
              .where(
                (key) => !defaultNames.contains(key),
              )
              .toList()
            ..sort(
              (a, b) => categoryNames[a]!
                  .compareTo(categoryNames[b]!),
            );

      // --------------------------------------------------------
      // FINAL CATEGORY LIST
      // --------------------------------------------------------

      final List<Map<String, dynamic>> categories = [
        ...teaShopCategories,
        ...customCategoryKeys.map(
          (key) => {
            'name': categoryNames[key]!,
            'icon': Icons.storefront,
            'description':
                'Find ${categoryNames[key]}',
          },
        ),
      ];

      // --------------------------------------------------------
      // SEARCH FILTER
      // --------------------------------------------------------

      final String query =
          searchText.trim().toLowerCase();

      final filtered = categories.where((category) {

        final name =
            category['name'].toString().toLowerCase();

        final description =
            category['description'].toString().toLowerCase();

        return query.isEmpty ||
            name.contains(query) ||
            description.contains(query);

      }).toList();

      if (filtered.isEmpty) {
        return const Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(
            child: Text(
              'No category found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        );
      }

      // --------------------------------------------------------
      // DISPLAY CATEGORY CARDS
      // --------------------------------------------------------

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filtered.length,

        itemBuilder: (context, index) {

          final category = filtered[index];

          final String name =
              category['name'].toString();

          final int count =
              categoryCounts[name.toLowerCase()] ?? 0;

          return categoryCard(
            category,
            count,
          );
        },
      );
    },
  );
}
  // ==========================================================
  // BUILD SCREEN
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      backgroundColor:
          background,


      // ======================================================
      // APP BAR
      // ======================================================

      appBar:
          AppBar(

        backgroundColor:
            darkGreen,

        foregroundColor:
            Colors.white,

        elevation:
            0,

        centerTitle:
            true,

        title:
            const Text(

          'Tea Shops',

          style:
              TextStyle(

            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),


      // ======================================================
      // BODY
      // ======================================================

      body:
          SafeArea(

        top:
            false,

        child:
            SingleChildScrollView(

          padding:
              EdgeInsets.zero,

          child:
              Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // =============================================
              // HEADER
              // =============================================

              pageHeader(),

              const SizedBox(
                height:
                    25,
              ),


              // =============================================
              // SEARCH BAR
              // =============================================

              searchSection(),


              const SizedBox(
                height:
                    25,
              ),


              // =============================================
              // SECTION TITLE
              // =============================================

              Padding(

                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      22,
                ),

                child:
                    Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const Text(

                      'Choose a Category',

                      style:
                          TextStyle(

                        fontSize:
                            21,

                        fontWeight:
                            FontWeight.bold,

                        color:
                            darkGreen,
                      ),
                    ),


                    const SizedBox(
                      height:
                          6,
                    ),


                    Text(

                      searchText.isEmpty

                          ? 'Select a category to find '
                              'nearby shops.'

                          : '${filteredCategories.length} '
                              'categories found',

                      style:
                          const TextStyle(

                        fontSize:
                            14,

                        color:
                            Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),


              const SizedBox(
                height:
                    18,
              ),


              // =============================================
              // CATEGORY LIST
              // =============================================

              Padding(

                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      20,
                ),

                child:
                    categoryList(),
              ),


              // =============================================
              // BOTTOM SPACE
              // =============================================

              const SizedBox(
                height:
                    35,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
