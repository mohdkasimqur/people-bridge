import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/selfEmployi/self_employee_nearby.dart';

// ===============================================================
// SCREEN SELF EMPLOYEES CATEGORIES
// ===============================================================

class ScreenSelfEmployeesCategories
    extends StatefulWidget {

  const ScreenSelfEmployeesCategories({
    super.key,
  });

  @override
  State<ScreenSelfEmployeesCategories>
      createState() =>
          _ScreenSelfEmployeesCategoriesState();
}


// ===============================================================
// STATE
// ===============================================================

class _ScreenSelfEmployeesCategoriesState
    extends State<ScreenSelfEmployeesCategories> {


  // =============================================================
  // SEARCH CONTROLLER
  // =============================================================

  final TextEditingController
      searchController =
          TextEditingController();


  // =============================================================
  // SEARCH FOCUS
  // =============================================================

  final FocusNode searchFocusNode =
      FocusNode();


  // =============================================================
  // LOADING CATEGORY
  //
  // Prevents multiple taps/navigation.
  // =============================================================

  String? openingCategory;

StreamSubscription<
    QuerySnapshot<Map<String, dynamic>>>?
    _selfEmployeeProfilesSubscription;

final Map<String, int> _selfEmployeeCategoryCounts = {};
final Set<String> _customSelfEmployeeCategories = {};

bool _loadingSelfEmployeeCategories = true;
  // =============================================================
  // CATEGORY LIST
  //
  // This list is local and lightweight.
  // No Firestore query happens on this screen.
  // =============================================================

  final List<String> categories = [

    // -----------------------------------------------------------
    // MAIN SELF EMPLOYEE CATEGORIES
    // -----------------------------------------------------------

    'Artist',

    'Designers',

    'Professionals',

    'Govt Retired',


    // -----------------------------------------------------------
    // CREATIVE
    // -----------------------------------------------------------

    'Photographer',

    'Videographer',

    'Graphic Designer',

    'Web Designer',

    'Interior Designer',

    'Fashion Designer',

    'Makeup Artist',

    'Musician',

    'Singer',

    'Painter',

    'Writer',

    'Content Creator',


    // -----------------------------------------------------------
    // PROFESSIONAL
    // -----------------------------------------------------------

    'Freelancer',

    'Consultant',

    'Business Consultant',

    'Marketing Professional',

    'Sales Professional',

    'Accountant',

    'Legal Consultant',

    'Architect',

    'Engineer',

    'Social Media Manager',


    // -----------------------------------------------------------
    // EDUCATION
    // -----------------------------------------------------------

    'Teacher',

    'Tutor',

    'Trainer',


    // -----------------------------------------------------------
    // SERVICES
    // -----------------------------------------------------------

    'Event Planner',

    'Beautician',

    'Craft Worker',

  ];


  // =============================================================
  // FILTERED CATEGORIES
  // =============================================================

  List<String> get filteredCategories {
  final searchText =
      searchController.text.trim().toLowerCase();

  // Combine built-in and registered custom categories.
  final Map<String, String> uniqueCategories = {};

  for (final category in [
    ...categories,
    ..._customSelfEmployeeCategories,
  ]) {
    final cleanName = category.trim();

    if (cleanName.isNotEmpty) {
      uniqueCategories.putIfAbsent(
        cleanName.toLowerCase(),
        () => cleanName,
      );
    }
  }

  return uniqueCategories.values
      .where(
        (category) =>
            searchText.isEmpty ||
            category.toLowerCase().contains(searchText),
      )
      .toList();
}

void _listenToSelfEmployeeCategories() {
  _selfEmployeeProfilesSubscription?.cancel();

  _selfEmployeeProfilesSubscription = FirebaseFirestore.instance
      .collection('selfEmployees')
      .snapshots()
      .listen(
    (snapshot) {
      final Map<String, int> counts = {};
      final Map<String, String> customCategories = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final Set<String> personCategories = {};

        // Read all categories selected by this person.
        final rawCategories = data['categories'];

        if (rawCategories is List) {
          for (final value in rawCategories) {
            if (value is String && value.trim().isNotEmpty) {
              personCategories.add(value.trim());
            }
          }
        }

        // Support older profiles that contain only "category".
        final String primary =
            data['category']?.toString().trim() ?? '';

        if (primary.isNotEmpty) {
          personCategories.add(primary);
        }

        // Discover custom categories from ALL remaining profiles,
        // including profiles that are currently offline.
        for (final name in personCategories) {
          final key = name.toLowerCase();

          final bool isBuiltIn = categories.any(
            (item) => item.trim().toLowerCase() == key,
          );

          if (!isBuiltIn) {
            customCategories.putIfAbsent(key, () => name);
          }
        }

        // Counts should include online profiles only.
        if (data['isOnline'] != true) {
          continue;
        }

        for (final name in personCategories) {
          final key = name.toLowerCase();
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }

      if (!mounted) return;

      setState(() {
        _selfEmployeeCategoryCounts
          ..clear()
          ..addAll(counts);

        _customSelfEmployeeCategories
          ..clear()
          ..addAll(customCategories.values);

        _loadingSelfEmployeeCategories = false;
      });

      debugPrint('SELF EMPLOYEE CATEGORY COUNTS: $counts');
      debugPrint(
        'SELF EMPLOYEE CUSTOM CATEGORIES: '
        '${customCategories.values.toList()}',
      );
    },
    onError: (Object error) {
      debugPrint('Self employee listener failed: $error');

      if (!mounted) return;

      setState(() {
        _loadingSelfEmployeeCategories = false;
      });
    },
  );
}
  // =============================================================
  // INIT STATE
  // =============================================================

  @override
  void initState() {

    super.initState();

_listenToSelfEmployeeCategories();
    // -----------------------------------------------------------
    // REFRESH UI WHILE SEARCHING
    // -----------------------------------------------------------

    searchController.addListener(
      _onSearchChanged,
    );

  }


  // =============================================================
  // SEARCH CHANGED
  // =============================================================

  void _onSearchChanged() {

    if (!mounted) return;


    setState(() {});

  }


  // =============================================================
  // CLEAR SEARCH
  // =============================================================

  void clearSearch() {

    searchController.clear();


    searchFocusNode.unfocus();

  }


  // =============================================================
  // DISPOSE
  // =============================================================

@override
void dispose() {
  _selfEmployeeProfilesSubscription?.cancel();

  searchController.removeListener(_onSearchChanged);
  searchController.dispose();
  searchFocusNode.dispose();

  super.dispose();
}
// =============================================================
  // OPEN SELECTED CATEGORY
  // =============================================================

  Future<void> openCategory(
    String category,
  ) async {

    // -----------------------------------------------------------
    // PREVENT MULTIPLE TAPS / MULTIPLE PAGE OPENS
    // -----------------------------------------------------------

    if (openingCategory != null) {
      return;
    }


    // -----------------------------------------------------------
    // SET LOADING CATEGORY
    // -----------------------------------------------------------

    if (mounted) {

      setState(() {

        openingCategory = category;

      });

    }


    try {

      // ---------------------------------------------------------
      // HIDE KEYBOARD
      // ---------------------------------------------------------

      FocusScope.of(context).unfocus();


      // ---------------------------------------------------------
      // NAVIGATE TO NEARBY SELF EMPLOYEES
      // ---------------------------------------------------------
      //
      // The next page will:
      //
      // 1. Get user's current location
      // 2. Search SELF EMPLOYEES by selected category
      // 3. Show employees within maximum 50 KM
      // 4. Sort nearest to farthest
      // 5. Use pagination for heavy users
      // 6. Apply paid-radius profile access rules
      // ---------------------------------------------------------

      await Navigator.of(context).push(

        MaterialPageRoute(

          builder: (context) =>
              ScreenNearbySelfEmployees(

            selectedCategory:
                category,

          ),

        ),

      );

    } catch (error) {

      // ---------------------------------------------------------
      // SAFE ERROR HANDLING
      // ---------------------------------------------------------

      if (!mounted) {
        return;
      }


      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();


      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          content:
              const Text(
            'Unable to open this category. Please try again.',
          ),

          backgroundColor:
              Colors.red,

          behavior:
              SnackBarBehavior.floating,

        ),

      );

    } finally {

      // ---------------------------------------------------------
      // RESET LOADING STATE
      // ---------------------------------------------------------

      if (mounted) {

        setState(() {

          openingCategory = null;

        });

      }

    }

  }


  // =============================================================
  // GET CATEGORY ICON
  // =============================================================

  IconData getCategoryIcon(
    String category,
  ) {

    switch (category) {


      // ---------------------------------------------------------
      // MAIN CATEGORIES
      // ---------------------------------------------------------

      case 'Artist':
        return Icons.palette_outlined;

      case 'Designers':
        return Icons.design_services_outlined;

      case 'Professionals':
        return Icons.work_outline;

      case 'Govt Retired':
        return Icons.account_balance_outlined;


      // ---------------------------------------------------------
      // CREATIVE
      // ---------------------------------------------------------

      case 'Photographer':
        return Icons.camera_alt_outlined;

      case 'Videographer':
        return Icons.videocam_outlined;

      case 'Graphic Designer':
        return Icons.brush_outlined;

      case 'Web Designer':
        return Icons.web_outlined;

      case 'Interior Designer':
        return Icons.chair_outlined;

      case 'Fashion Designer':
        return Icons.checkroom_outlined;

      case 'Makeup Artist':
        return Icons.face_retouching_natural_outlined;

      case 'Musician':
        return Icons.music_note_outlined;

      case 'Singer':
        return Icons.mic_none_outlined;

      case 'Painter':
        return Icons.format_paint_outlined;

      case 'Writer':
        return Icons.edit_outlined;

      case 'Content Creator':
        return Icons.video_library_outlined;


      // ---------------------------------------------------------
      // PROFESSIONAL
      // ---------------------------------------------------------

      case 'Freelancer':
        return Icons.person_outline;

      case 'Consultant':
        return Icons.support_agent_outlined;

      case 'Business Consultant':
        return Icons.business_center_outlined;

      case 'Marketing Professional':
        return Icons.campaign_outlined;

      case 'Sales Professional':
        return Icons.trending_up_outlined;

      case 'Accountant':
        return Icons.calculate_outlined;

      case 'Legal Consultant':
        return Icons.gavel_outlined;

      case 'Architect':
        return Icons.architecture_outlined;

      case 'Engineer':
        return Icons.engineering_outlined;

      case 'Social Media Manager':
        return Icons.share_outlined;


      // ---------------------------------------------------------
      // EDUCATION
      // ---------------------------------------------------------

      case 'Teacher':
        return Icons.school_outlined;

      case 'Tutor':
        return Icons.menu_book_outlined;

      case 'Trainer':
        return Icons.fitness_center_outlined;


      // ---------------------------------------------------------
      // SERVICES
      // ---------------------------------------------------------

      case 'Event Planner':
        return Icons.event_outlined;

      case 'Beautician':
        return Icons.spa_outlined;

      case 'Craft Worker':
        return Icons.handyman_outlined;


      // ---------------------------------------------------------
      // DEFAULT
      // ---------------------------------------------------------

      default:
        return Icons.work_outline;

    }

  }


  // =============================================================
  // GET CATEGORY COLOR
  //
  // All categories use the same Citizen India green theme.
  // Keeping this simple also improves UI consistency.
  // =============================================================

  Color getCategoryColor(
    String category,
  ) {

    return const Color(
      0xFF198B35,
    );

  }


  // =============================================================
  // CHECK IF SEARCH HAS RESULTS
  // =============================================================

  bool get hasSearchResults {

    return filteredCategories.isNotEmpty;

  }


  // =============================================================
  // GET EMPTY SEARCH MESSAGE
  // =============================================================

  String get emptySearchMessage {

    final String searchText =
        searchController.text.trim();


    if (searchText.isEmpty) {

      return 'No categories available';

    }


    return 'No category found for "$searchText"';

  }

  String _getCategoryDescription(String category) {
  switch (category.toLowerCase()) {
    case 'artist':
      return 'Find artists near you';
    case 'designers':
      return 'Find designers near you';
    case 'professionals':
      return 'Find professionals near you';
    case 'govt retired':
      return 'Find retired government professionals near you';
    case 'photographer':
      return 'Find photographers near you';
    case 'videographer':
      return 'Find videographers near you';
    case 'graphic designer':
      return 'Find graphic designers near you';
    case 'web designer':
      return 'Find web designers near you';
    case 'interior designer':
      return 'Find interior designers near you';
    case 'fashion designer':
      return 'Find fashion designers near you';
    case 'makeup artist':
      return 'Find makeup artists near you';
    case 'musician':
      return 'Find musicians near you';
    case 'singer':
      return 'Find singers near you';
    case 'painter':
      return 'Find painters near you';
    case 'writer':
      return 'Find writers near you';
    case 'content creator':
      return 'Find content creators near you';
    case 'freelancer':
      return 'Find freelancers near you';
    case 'consultant':
      return 'Find consultants near you';
    case 'business consultant':
      return 'Find business consultants near you';
    case 'marketing professional':
      return 'Find marketing professionals near you';
    case 'sales professional':
      return 'Find sales professionals near you';
    case 'accountant':
      return 'Find accountants near you';
    case 'legal consultant':
      return 'Find legal consultants near you';
    case 'architect':
      return 'Find architects near you';
    case 'engineer':
      return 'Find engineers near you';
    case 'social media manager':
      return 'Find social media managers near you';
    case 'teacher':
      return 'Find teachers near you';
    case 'tutor':
      return 'Find tutors near you';
    case 'trainer':
      return 'Find trainers near you';
    case 'event planner':
      return 'Find event planners near you';
    case 'beautician':
      return 'Find beauticians near you';
    case 'craft worker':
      return 'Find craft workers near you';
    default:
      return 'Find $category near you';
  }
}

Widget _buildCategoryCard(
  String category,
  int employeeCount,
) {
  const green = Color(0xFF138808);

  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: openingCategory != null
        ? null
        : () => openCategory(category),
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
          // Icon with online-count badge.
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: openingCategory == category
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: green,
                        ),
                      )
                    : Icon(
                        getCategoryIcon(category),
                        color: green,
                        size: 23,
                      ),
              ),
              if (employeeCount > 0)
                Positioned(
                  top: -7,
                  right: -7,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 21,
                      minHeight: 21,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: green,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      employeeCount > 99
                          ? '99+'
                          : employeeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 13),

          // Category title and description.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getCategoryDescription(category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

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

Widget _buildEmptyState() {
  const green = Color(0xFF138808);
  final searchText = searchController.text.trim();

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F4EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_outlined,
              size: 42,
              color: green,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            searchText.isEmpty
                ? 'No categories available'
                : 'No category found',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF12652F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchText.isEmpty
                ? 'Categories will appear here when available.'
                : 'Try searching for another category.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          if (searchText.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: clearSearch,
              icon: const Icon(Icons.refresh),
              label: const Text('Clear Search'),
              style: OutlinedButton.styleFrom(
                foregroundColor: green,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

// =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    final List<String> visibleCategories =
        filteredCategories;


    return Scaffold(

      backgroundColor:
          const Color(
        0xFFF7F8F7,
      ),


      // ===========================================================
      // APP BAR
      // ===========================================================

      appBar: AppBar(

        title:
            const Text(
          'SELF EMPLOYED',
        ),

        centerTitle:
            true,

        elevation:
            0,

        backgroundColor:
            Colors.white,

        foregroundColor:
            const Color(
          0xFF12652F,
        ),

      ),


      // ===========================================================
      // BODY
      // ===========================================================

      body:
          SafeArea(

        child:
            Column(

          children: [


            // =====================================================
            // HEADER
            // =====================================================

            Padding(

              padding:
                  const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                10,
              ),

              child:
                  Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [


                  // ------------------------------------------------
                  // TITLE
                  // ------------------------------------------------

                  const Text(

                    'Choose a Category',

                    style:
                        TextStyle(

                      fontSize:
                          22,

                      fontWeight:
                          FontWeight.bold,

                      color:
                          Color(
                        0xFF12652F,
                      ),

                    ),

                  ),


                  const SizedBox(
                    height: 5,
                  ),


                  const Text(

                    'Find SELF EMPLOYEES near your location',

                    style:
                        TextStyle(

                      fontSize:
                          14,

                      color:
                          Colors.black54,

                    ),

                  ),


                  const SizedBox(
                    height: 18,
                  ),


                  // =================================================
                  // SEARCH BAR
                  // =================================================

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
                          'Search category',

                      prefixIcon:
                          const Icon(
                        Icons.search,
                        color:
                            Color(
                          0xFF198B35,
                        ),
                      ),


                      suffixIcon:

                          searchController
                                  .text
                                  .isNotEmpty

                              ? IconButton(

                                  onPressed:
                                      clearSearch,

                                  icon:
                                      const Icon(
                                    Icons.clear,
                                  ),

                                )

                              : null,


                      filled:
                          true,

                      fillColor:
                          Colors.white,


                      border:
                          OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),

                        borderSide:
                            BorderSide.none,

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
                              Colors.grey.shade200,

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
                              Color(
                            0xFF198B35,
                          ),

                          width:
                              1.5,

                        ),

                      ),

                    ),

                  ),

                ],

              ),

            ),


            // =====================================================
            // CATEGORY COUNT
            // =====================================================

            Padding(

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),

              child:
                  Row(

                children: [
                  Text(
  _loadingSelfEmployeeCategories
      ? 'Loading categories...'
      : '${visibleCategories.length} Categories',
  style: TextStyle(
    color: Colors.grey.shade600,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  ),
),

                ],

              ),

            ),
Expanded(
  child: _loadingSelfEmployeeCategories
      ? const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF16803C),
          ),
        )
      : visibleCategories.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                5,
                16,
                25,
              ),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: visibleCategories.length,
              itemBuilder: (context, index) {
                final category = visibleCategories[index];

                final count =
                    _selfEmployeeCategoryCounts[
                            category.trim().toLowerCase()] ??
                        0;

                return _buildCategoryCard(
                  category,
                  count,
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
