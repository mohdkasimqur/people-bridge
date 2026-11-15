import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/IndividualSellers/screen_selfbusiness_nearby.dart';


// ===============================================================
// SCREEN SELF BUSINESS CATEGORIES
// ===============================================================

class ScreenIndividualSellerCategories
    extends StatefulWidget {

  const ScreenIndividualSellerCategories({
    super.key,
  });

  @override
  State<ScreenIndividualSellerCategories>
      createState() =>
          _ScreenIndividualSellerCategoriesState();
}


// ===============================================================
// STATE
// ===============================================================

class _ScreenIndividualSellerCategoriesState
    extends State<ScreenIndividualSellerCategories> {

  // =============================================================
  // COLORS
  // =============================================================

  static const Color darkGreen =
      Color(0xFF12652F);

  static const Color green =
      Color(0xFF138808);

  static const Color background =
      Color(0xFFF7F8F7);

  static const Color borderColor =
      Color(0xFFE0E0E0);


  // =============================================================
  // SEARCH CONTROLLER
  // =============================================================

  final TextEditingController
      searchController =
      TextEditingController();


  // =============================================================
  // CATEGORY LIST
  // =============================================================

  final List<String>
      businessCategories = [

    // -----------------------------------------------------------
    // FOOD BUSINESS
    // -----------------------------------------------------------

    'Pickle Business',

    'Homemade Food',

    'Catering Service',

    'Bakery',

    'Cake Business',

    'Tea Shop',

    'Coffee Shop',

    'Juice Shop',

    'Restaurant',

    'Fast Food',


    // -----------------------------------------------------------
    // DAILY NEEDS
    // -----------------------------------------------------------

    'Grocery Shop',

    'Vegetable Seller',

    'Fruit Seller',

    'Fish Seller',

    'Meat Shop',

    'Chicken Shop',

    'Milk Products',

    'Dairy Products',


    // -----------------------------------------------------------
    // CLOTHING & BEAUTY
    // -----------------------------------------------------------

    'Clothing Business',

    'Tailoring',

    'Beauty Parlour',

    'Hair Salon',


    // -----------------------------------------------------------
    // ELECTRONICS
    // -----------------------------------------------------------

    'Mobile Shop',

    'Mobile Repair',

    'Computer Repair',

    'Electronics Repair',


    // -----------------------------------------------------------
    // VEHICLE
    // -----------------------------------------------------------

    'Car Repair',

    'Bike Repair',

    'Auto Spare Parts',


    // -----------------------------------------------------------
    // SERVICES
    // -----------------------------------------------------------

    'Construction Service',

    'Cleaning Service',

    'Photography',

    'Printing Service',

    'Event Decoration',

    'Flower Shop',

    'Furniture Business',

    'Home Service',

    'Delivery Service',

    'Online Business',
  ];


  // =============================================================
  // FILTERED CATEGORY LIST
  // =============================================================

  List<String> filteredCategories = [];


  // =============================================================
  // INIT STATE
  // =============================================================

  @override
  void initState() {

    super.initState();


    // -----------------------------------------------------------
    // INITIALIZE ALL CATEGORIES
    // -----------------------------------------------------------

    filteredCategories =
        List<String>.from(
      businessCategories,
    );


    // -----------------------------------------------------------
    // LISTEN TO SEARCH
    // -----------------------------------------------------------

    searchController.addListener(
      filterCategories,
    );
  }


  // =============================================================
  // FILTER CATEGORIES
  // =============================================================

  void filterCategories() {

    final String query =
        searchController.text
            .trim()
            .toLowerCase();


    if (!mounted) {
      return;
    }


    setState(() {

      if (query.isEmpty) {

        filteredCategories =
            List<String>.from(
          businessCategories,
        );

      } else {

        filteredCategories =
            businessCategories
                .where(
                  (String category) {

            return category
                .toLowerCase()
                .contains(query);

          },
        ).toList();
      }
    });
  }


  IconData getCategoryIcon(
    String category,
  ) {

    switch (category) {

      // ---------------------------------------------------------
      // FOOD
      // ---------------------------------------------------------

      case 'Pickle Business':
        return Icons
            .local_dining_rounded;

      case 'Homemade Food':
        return Icons
            .home_filled;

      case 'Catering Service':
        return Icons
            .restaurant_menu;

      case 'Bakery':
        return Icons
            .bakery_dining;

      case 'Cake Business':
        return Icons
            .cake;

      case 'Tea Shop':
        return Icons
            .emoji_food_beverage;

      case 'Coffee Shop':
        return Icons
            .coffee;

      case 'Juice Shop':
        return Icons
            .local_drink;

      case 'Restaurant':
        return Icons
            .restaurant;

      case 'Fast Food':
        return Icons
            .fastfood;


      // ---------------------------------------------------------
      // DAILY NEEDS
      // ---------------------------------------------------------

      case 'Grocery Shop':
        return Icons
            .shopping_cart;

      case 'Vegetable Seller':
        return Icons
            .eco;

      case 'Fish Seller':
        return Icons
            .set_meal;

      case 'Meat Shop':
        return Icons
            .restaurant;

      case 'Chicken Shop':
        return Icons
            .egg;

      case 'Milk Products':
        return Icons
            .local_drink;

      case 'Dairy Products':
        return Icons
            .local_drink;


      // ---------------------------------------------------------
      // CLOTHING & BEAUTY
      // ---------------------------------------------------------

      case 'Clothing Business':
        return Icons
            .checkroom;

      case 'Tailoring':
        return Icons
            .content_cut;

      case 'Beauty Parlour':
        return Icons
            .face_retouching_natural;

      case 'Hair Salon':
        return Icons
            .content_cut;


      // ---------------------------------------------------------
      // ELECTRONICS
      // ---------------------------------------------------------

      case 'Mobile Shop':
        return Icons
            .phone_android;

      case 'Mobile Repair':
        return Icons
            .build;

      case 'Computer Repair':
        return Icons
            .computer;

      case 'Electronics Repair':
        return Icons
            .electrical_services;


      // ---------------------------------------------------------
      // VEHICLES
      // ---------------------------------------------------------

      case 'Car Repair':
        return Icons
            .directions_car;

      case 'Bike Repair':
        return Icons
            .two_wheeler;

      case 'Auto Spare Parts':
        return Icons
            .settings;


      // ---------------------------------------------------------
      // SERVICES
      // ---------------------------------------------------------

      case 'Construction Service':
        return Icons
            .construction;

      case 'Cleaning Service':
        return Icons
            .cleaning_services;

      case 'Photography':
        return Icons
            .camera_alt;

      case 'Printing Service':
        return Icons
            .print;

      case 'Event Decoration':
        return Icons
            .celebration;

      case 'Flower Shop':
        return Icons
            .local_florist;

      case 'Furniture Business':
        return Icons
            .chair;

      case 'Home Service':
        return Icons
            .home_repair_service;

      case 'Delivery Service':
        return Icons
            .delivery_dining;

      case 'Online Business':
        return Icons
            .language;

      default:
        return Icons
            .business;
    }
  }


 // =============================================================
// SELECT CATEGORY
// =============================================================

void selectCategory(
  String category,
) {

  Navigator.push(

    context,

    MaterialPageRoute(

      builder:
          (context) =>
              ScreenNearbySelfBusiness(

        category:
            category,
      ),
    ),
  );
}


  // =============================================================
  // CLEAR SEARCH
  // =============================================================

  void clearSearch() {

    searchController.clear();

    FocusScope.of(context).unfocus();
  }


  // =============================================================
  // CATEGORY CARD
  // =============================================================

  Widget buildCategoryCard(
    String category,
  ) {

    final IconData icon =
        getCategoryIcon(category);

    return Material(

      color:
          Colors.transparent,

      child:
          InkWell(

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        onTap:
            () {

          selectCategory(
            category,
          );
        },

        child:
            Ink(

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
                  borderColor,
            ),

            boxShadow: [

              BoxShadow(

                color:
                    Colors.black
                        .withValues(
                  alpha: 0.04,
                ),

                blurRadius:
                    10,

                offset:
                    const Offset(
                  0,
                  3,
                ),
              ),
            ],
          ),

          child:
              Padding(

            padding:
                const EdgeInsets.all(
              14,
            ),

            child:
                Row(

              children: [

                // =================================================
                // ICON
                // =================================================

                Container(

                  width:
                      52,

                  height:
                      52,

                  decoration:
                      BoxDecoration(

                    color:
                        green.withValues(
                      alpha:
                          0.10,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),

                  child:
                      Icon(

                    icon,

                    color:
                        green,

                    size:
                        27,
                  ),
                ),

                const SizedBox(
                  width:
                      14,
                ),


                // =================================================
                // CATEGORY NAME
                // =================================================

                Expanded(

                  child:
                      Column(

                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      Text(

                        category,

                        style:
                            const TextStyle(

                          fontSize:
                              16,

                          fontWeight:
                              FontWeight.w700,

                          color:
                              darkGreen,
                        ),
                      ),

                      const SizedBox(
                        height:
                            4,
                      ),

                      const Text(

                        'Find businesses near you',

                        style:
                            TextStyle(

                          fontSize:
                              12,

                          color:
                              Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),


                // =================================================
                // ARROW
                // =================================================

                const Icon(

                  Icons
                      .arrow_forward_ios_rounded,

                  size:
                      17,

                  color:
                      Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // =============================================================
  // EMPTY SEARCH RESULT
  // =============================================================

  Widget buildEmptyResult() {

    return Center(

      child:
          Padding(

        padding:
            const EdgeInsets.symmetric(
          horizontal:
              30,
          vertical:
              60,
        ),

        child:
            Column(

          mainAxisSize:
              MainAxisSize.min,

          children: [

            Icon(

              Icons
                  .search_off_rounded,

              size:
                  65,

              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(
              height:
                  16,
            ),

            const Text(

              'No category found',

              style:
                  TextStyle(

                fontSize:
                    18,

                fontWeight:
                    FontWeight.w700,

                color:
                    darkGreen,
              ),
            ),

            const SizedBox(
              height:
                  8,
            ),

            const Text(

              'Try searching with another category name',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(

                color:
                    Colors.grey,
              ),
            ),

            const SizedBox(
              height:
                  20,
            ),

            OutlinedButton.icon(

              onPressed:
                  clearSearch,

              icon:
                  const Icon(
                Icons.refresh,
              ),

              label:
                  const Text(
                'SHOW ALL CATEGORIES',
              ),

              style:
                  OutlinedButton.styleFrom(

                foregroundColor:
                    green,

                side:
                    const BorderSide(
                  color:
                      green,
                ),

                shape:
                    RoundedRectangleBorder(

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {

    searchController.dispose();

    super.dispose();
  }


 // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      backgroundColor:
          background,


      // =========================================================
      // APP BAR
      // =========================================================

      appBar:
          AppBar(

        elevation:
            0,

        backgroundColor:
            Colors.white,

        foregroundColor:
            darkGreen,

        centerTitle:
            false,

        title:
            const Text(

          'Individual Sellers',

          style:
              TextStyle(

            fontSize:
                20,

            fontWeight:
                FontWeight.w800,

            color:
                darkGreen,
          ),
        ),
      ),


      // =========================================================
      // BODY
      // =========================================================

      body:
          SafeArea(

        child:
            Column(

          children: [

            // ===================================================
            // HEADER
            // ===================================================

            Container(

              width:
                  double.infinity,

              color:
                  Colors.white,

              padding:
                  const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20,
              ),

              child:
                  Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(

                    'Choose a Business Category',

                    style:
                        TextStyle(

                      fontSize:
                          22,

                      fontWeight:
                          FontWeight.w800,

                      color:
                          darkGreen,
                    ),
                  ),

                  const SizedBox(
                    height:
                        6,
                  ),

                  const Text(

                    'Select a category to find businesses near you',

                    style:
                        TextStyle(

                      fontSize:
                          14,

                      color:
                          Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height:
                        20,
                  ),


                  // =============================================
                  // SEARCH BAR
                  // =============================================

                  TextField(

                    controller:
                        searchController,

                    textInputAction:
                        TextInputAction.search,

                    decoration:
                        InputDecoration(

                      hintText:
                          'Search business category',

                      hintStyle:
                          const TextStyle(
                        color:
                            Colors.grey,
                      ),

                      prefixIcon:
                          const Icon(

                        Icons.search_rounded,

                        color:
                            green,
                      ),

                      suffixIcon:

                          searchController.text
                                  .isNotEmpty

                              ? IconButton(

                                  onPressed:
                                      clearSearch,

                                  icon:
                                      const Icon(
                                    Icons.close,
                                  ),
                                )

                              : null,

                      filled:
                          true,

                      fillColor:
                          background,

                      contentPadding:
                          const EdgeInsets.symmetric(
                        vertical:
                            16,
                      ),

                      border:
                          OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),

                        borderSide:
                            BorderSide(
                          color:
                              borderColor,
                        ),
                      ),

                      enabledBorder:
                          OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),

                        borderSide:
                            BorderSide(
                          color:
                              borderColor,
                        ),
                      ),

                      focusedBorder:
                          OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),

                        borderSide:
                            const BorderSide(

                          color:
                              green,

                          width:
                              1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),


            // ===================================================
            // CATEGORY COUNT
            // ===================================================

            Padding(

              padding:
                  const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                10,
              ),

              child:
                  Row(

                children: [

                  Text(

                    '${filteredCategories.length} Categories',

                    style:
                        const TextStyle(

                      fontSize:
                          14,

                      fontWeight:
                          FontWeight.w700,

                      color:
                          darkGreen,
                    ),
                  ),

                  const Spacer(),

                  const Icon(

                    Icons
                        .location_searching_outlined,

                    size:
                        18,

                    color:
                        green,
                  ),

                  const SizedBox(
                    width:
                        5,
                  ),

                  const Text(

                    'Nearby',

                    style:
                        TextStyle(

                      fontSize:
                          13,

                      color:
                          Colors.grey,
                    ),
                  ),
                ],
              ),
            ),


            // ===================================================
            // CATEGORY LIST
            // ===================================================

            Expanded(

              child:

                  filteredCategories.isEmpty

                      ? buildEmptyResult()

                      : ListView.separated(

                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior
                                  .onDrag,

                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            4,
                            16,
                            30,
                          ),

                          itemCount:
                              filteredCategories
                                  .length,

                          separatorBuilder:
                              (
                                context,
                                index,
                              ) {

                            return const SizedBox(
                              height:
                                  10,
                            );
                          },

                          itemBuilder:
                              (
                                context,
                                index,
                              ) {

                            final String category =
                                filteredCategories[
                                    index];

                            return buildCategoryCard(
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
}