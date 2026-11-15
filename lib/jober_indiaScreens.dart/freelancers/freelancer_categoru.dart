import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/freelancers/freelancer_nearby.dart';

// ===============================================================
// SCREEN FREELANCER CATEGORIES
// ===============================================================

class ScreenFreelancerCategories extends StatefulWidget {
   final double userLatitude;
  final double userLongitude;
  const ScreenFreelancerCategories({
    super.key,
     required this.userLatitude,
    required this.userLongitude,
  });

  @override
  State<ScreenFreelancerCategories> createState() =>
      _ScreenFreelancerCategoriesState();
}

class _ScreenFreelancerCategoriesState
    extends State<ScreenFreelancerCategories> {


  // =============================================================
  // COLORS
  // =============================================================

  static const Color darkGreen =
      Color(0xFF12652F);

  static const Color green =
      Color(0xFF138808);

  static const Color background =
      Color(0xFFF7F8F7);


  // =============================================================
  // SEARCH CONTROLLER
  // =============================================================

  final TextEditingController
      _searchController =
      TextEditingController();


  // =============================================================
  // SEARCH TEXT
  // =============================================================

  String _searchText = '';


  // =============================================================
  // SEARCH DEBOUNCE
  //
  // Prevents unnecessary rebuilds while the user types quickly.
  // =============================================================

  Timer? _searchDebounce;

  // =============================================================
  // BUILT-IN FREELANCER CATEGORIES
  // Keep these aligned with the registration page.
  // =============================================================
// Number of online freelancers in each category.
final Map<String, int> _availableCounts = {};

StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _freelancerCountSubscription;

  final List<String> _builtInFreelancerCategories = [
    'Photographer',
    'Videographer',
    'Video Editor',
    'Photo Editor',
    'Graphic Designer',
    'Logo Designer',
    'Web Designer',
    'Web Developer',
    'App Developer',
    'Software Developer',
    'Content Writer',
    'Copywriter',
    'Translator',
    'Social Media Manager',
    'Digital Marketer',
    'SEO Specialist',
    'YouTuber',
    'Influencer',
    'Voice Artist',
    'Singer',
    'Music Producer',
    'DJ',
    'Makeup Artist',
    'Hair Stylist',
    'Fashion Designer',
    'Model',
    'Event Planner',
    'Wedding Planner',
    'Tutor',
    'Trainer',
    'Consultant',
    'Accountant',
    'Architect',
    'Interior Designer',
    'Animator',
    'Illustrator',
    'Drone Operator',
    'Travel Guide',
  ];

  // All built-in categories plus saved custom categories.
  List<String> _freelancerCategories = [];

  // Number of currently online freelancers in each category.
  //final Map<String, int> _availableCounts = {};

  // StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
 
  // =============================================================
  // INIT STATE
  // =============================================================

 @override
void initState() {
  super.initState();

  _freelancerCategories =
      List<String>.from(_builtInFreelancerCategories);

  _listenToFreelancers();

  _searchController.addListener(_onSearchChanged);
}


  // =============================================================
  // SEARCH CHANGE
  // =============================================================

  void _onSearchChanged() {

    // Cancel the previous timer.
    _searchDebounce?.cancel();


    // Small debounce prevents rebuilding repeatedly
    // during very fast typing.
    _searchDebounce =
        Timer(
      const Duration(milliseconds: 250),
      () {

        if (!mounted) return;


        setState(() {

          _searchText =
              _searchController.text
                  .trim()
                  .toLowerCase();

        });

      },
    );

  }

  void _listenToFreelancers() {
  _freelancerCountSubscription?.cancel();

  _freelancerCountSubscription = FirebaseFirestore
      .instance
      .collection('freelancers')
      .where('isOnline', isEqualTo: true)
      .snapshots()
      .listen(
    (snapshot) {
      final Map<String, int> newCounts = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawCategories = data['categories'];

        if (rawCategories is! List) continue;

        // Prevent one freelancer being counted twice
        // in the same category.
        final Set<String> countedCategories = {};

        for (final value in rawCategories) {
          if (value is! String) continue;

          final category = value.trim();
          if (category.isEmpty) continue;

          final key = category.toLowerCase();

          if (countedCategories.add(key)) {
            newCounts[key] = (newCounts[key] ?? 0) + 1;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _availableCounts
          ..clear()
          ..addAll(newCounts);
      });
    },
    onError: (Object error) {
      debugPrint(
        'Freelancer category count error: $error',
      );
    },
  );
}
  // =============================================================
  // FILTERED CATEGORIES
  // =============================================================

  List<String>
      get _filteredCategories {

    // -----------------------------------------------------------
    // NO SEARCH
    // -----------------------------------------------------------

    if (_searchText.isEmpty) {

      return _freelancerCategories;

    }


    // -----------------------------------------------------------
    // SEARCH CATEGORY
    // -----------------------------------------------------------

    return _freelancerCategories
        .where(
      (category) {

        return category
            .toLowerCase()
            .contains(
              _searchText,
            );

      },
    )
        .toList();

  }
  // =============================================================
  // SELECT CATEGORY
  // =============================================================

  void _selectCategory(
      String category) {

    // Prevent double navigation.
    if (!mounted) return;


    // ===========================================================
    // NAVIGATE TO NEARBY FREELANCERS PAGE
    //
    // The selected category is passed to the next screen.
    //
    // Example:
    //
    // Photographer
    //       ↓
    // Show photographers within 50 KM
    // ===========================================================

    Navigator.push(

      context,

      MaterialPageRoute(

        builder:
            (_) =>

        ScreenNearbyFreelancers(
  selectedCategory: category,
  userLatitude: widget.userLatitude,
  userLongitude: widget.userLongitude,
)

      ),

    );

  }


  // =============================================================
  // CATEGORY ICON
  // =============================================================

  IconData _getCategoryIcon(
      String category) {

    switch (category) {


      case 'Photographer':
        return Icons.camera_alt_outlined;


      case 'Videographer':
        return Icons.videocam_outlined;


      case 'Video Editor':
        return Icons.movie_creation_outlined;


      case 'Photo Editor':
        return Icons.photo_outlined;


      case 'Graphic Designer':
        return Icons.palette_outlined;


      case 'Logo Designer':
        return Icons.brush_outlined;


      case 'Web Designer':
        return Icons.web_outlined;


      case 'Web Developer':
        return Icons.code;


      case 'App Developer':
        return Icons.phone_android_outlined;


      case 'Software Developer':
        return Icons.developer_mode;


      case 'Content Writer':
        return Icons.edit_note_outlined;


      case 'Copywriter':
        return Icons.description_outlined;


      case 'Translator':
        return Icons.translate;


      case 'Social Media Manager':
        return Icons.share_outlined;


      case 'Digital Marketer':
        return Icons.campaign_outlined;


      case 'SEO Specialist':
        return Icons.search_outlined;


      case 'YouTuber':
        return Icons.play_circle_outline;


      case 'Influencer':
        return Icons.person_outline;


      case 'Voice Artist':
        return Icons.mic_none_outlined;


      case 'Singer':
        return Icons.music_note_outlined;


      case 'Music Producer':
        return Icons.library_music_outlined;


      case 'DJ':
        return Icons.headphones_outlined;


      case 'Makeup Artist':
        return Icons.face_retouching_natural;


      case 'Hair Stylist':
        return Icons.content_cut;


      case 'Fashion Designer':
        return Icons.checkroom_outlined;


      case 'Model':
        return Icons.accessibility_new;


      case 'Event Planner':
        return Icons.event_outlined;


      case 'Wedding Planner':
        return Icons.favorite_border;


      case 'Tutor':
        return Icons.school_outlined;


      case 'Trainer':
        return Icons.fitness_center_outlined;


      case 'Consultant':
        return Icons.support_agent_outlined;


      case 'Accountant':
        return Icons.calculate_outlined;


      case 'Architect':
        return Icons.architecture_outlined;


      case 'Interior Designer':
        return Icons.chair_outlined;


      case 'Animator':
        return Icons.animation_outlined;


      case 'Illustrator':
        return Icons.draw_outlined;


      case 'Drone Operator':
        return Icons.flight_outlined;


      case 'Travel Guide':
        return Icons.travel_explore_outlined;


      default:
        return Icons.work_outline;

    }

  }


  // =============================================================
  // CATEGORY DESCRIPTION
  // =============================================================

  String _getCategoryDescription(
      String category) {

    switch (category) {


      case 'Photographer':
        return 'Find photographers near you';


      case 'Videographer':
        return 'Find videographers near you';


      case 'Graphic Designer':
        return 'Find graphic designers near you';


      case 'Video Editor':
        return 'Find video editors near you';


      case 'Photo Editor':
        return 'Find photo editors near you';


      case 'Web Developer':
        return 'Find web developers near you';


      case 'App Developer':
        return 'Find app developers near you';


      case 'Makeup Artist':
        return 'Find makeup artists near you';


      case 'Event Planner':
        return 'Find event planners near you';


      case 'Tutor':
        return 'Find tutors near you';


      case 'Travel Guide':
        return 'Find travel guides near you';


      default:
        return 'Find $category near you';

    }

  }


  // =============================================================
  // CLEAR SEARCH
  // =============================================================

  void _clearSearch() {

    _searchController.clear();


    if (!mounted) return;


    setState(() {

      _searchText = '';

    });


    FocusScope.of(context).unfocus();

  }


  // =============================================================
  // DISPOSE
  // =============================================================

 @override
void dispose() {

  _searchDebounce?.cancel();

  _searchController.removeListener(_onSearchChanged);
  _searchController.dispose();

  super.dispose();
}
  //===================================================
  // BUILD
  // =============================================================

  @override
  Widget build(
      BuildContext context) {

    final categories =
        _filteredCategories;


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
            true,


        title:
            const Text(

          'Freelancers',

          style:
              TextStyle(

            fontWeight:
                FontWeight.bold,

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

            Padding(

              padding:
                  const EdgeInsets.fromLTRB(
                20,
                22,
                20,
                10,
              ),

              child:
                  Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [


                  const Text(

                    'Find a Freelancer',

                    style:
                        TextStyle(

                      fontSize:
                          25,

                      fontWeight:
                          FontWeight.bold,

                      color:
                          darkGreen,

                    ),

                  ),


                  const SizedBox(
                    height: 6,
                  ),


                  Text(

                    'Choose a category to find freelancers near you',

                    style:
                        TextStyle(

                      fontSize:
                          15,

                      color:
                          Colors.grey.shade600,

                    ),

                  ),

                ],

              ),

            ),


            // ===================================================
            // SEARCH BOX
            // ===================================================

            Padding(

              padding:
                  const EdgeInsets.symmetric(
                horizontal:
                    20,
                vertical:
                    12,
              ),

              child:
                  TextField(

                controller:
                    _searchController,

                textCapitalization:
                    TextCapitalization.words,

                decoration:
                    InputDecoration(

                  hintText:
                      'Search freelancer category...',

                  prefixIcon:
                      const Icon(

                    Icons.search,

                    color:
                        green,

                    size:
                        28,

                  ),


                  suffixIcon:
                      _searchText.isNotEmpty

                          ? IconButton(

                              onPressed:
                                  _clearSearch,

                              icon:
                                  const Icon(

                                Icons.close,

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
                        18,
                  ),


                  border:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(18),

                    borderSide:
                        BorderSide.none,

                  ),


                  enabledBorder:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(18),

                    borderSide:
                        BorderSide(
                      color:
                          Colors.grey.shade300,
                    ),

                  ),


                  focusedBorder:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(18),

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

            ),


            // ===================================================
            // CATEGORY COUNT
            // ===================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20, 10, 20, 10,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${categories.length} Categories',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: darkGreen,
                  ),
                ),
              ),
            ),


            // ===================================================
            // REAL-TIME FREELANCER CATEGORY COUNTS
            // ===================================================

            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('freelancers')
                    .where('isOnline', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildEmptyState();
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

                  final documents = snapshot.data?.docs ?? [];

                  // Count each online freelancer once per category.
                  final Map<String, Set<String>>
                      freelancerIdsByCategory = {};

                  // Merge built-in and online custom categories.
                  final Map<String, String> categoryNames = {};

                  for (final category
                      in _builtInFreelancerCategories) {
                    categoryNames.putIfAbsent(
                      category.toLowerCase(),
                      () => category,
                    );
                  }

                  for (final document in documents) {
                    final data = document.data();

                    if (data['isOnline'] != true) continue;

                    final rawCategories = data['categories'];

                    if (rawCategories is! List) continue;

                    final Set<String> processed = {};

                    for (final rawCategory in rawCategories) {
                      if (rawCategory is! String) continue;

                      final name = rawCategory.trim();
                      if (name.isEmpty) continue;

                      final key = name.toLowerCase();

                      categoryNames.putIfAbsent(
                        key,
                        () => name,
                      );

                      if (!processed.add(key)) continue;

                      freelancerIdsByCategory
                          .putIfAbsent(key, () => <String>{})
                          .add(document.id);
                    }
                  }

                  final categories = categoryNames.values
                      .where(
                        (category) => category
                            .toLowerCase()
                            .contains(_searchText),
                      )
                      .toList()
                    ..sort(
                      (a, b) => a.toLowerCase().compareTo(
                            b.toLowerCase(),
                          ),
                    );

                  return categories.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            16, 5, 16, 25,
                          ),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];

                            final count =
                                freelancerIdsByCategory[
                                        category.toLowerCase()]
                                    ?.length ??
                                0;

                            return _buildCategoryCard(
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
    );
  }
Widget _buildCategoryCard(
  String category,
  int freelancerCount,
) {
  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () => _selectCategory(category),
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
          // CATEGORY ICON WITH COUNT BADGE ABOVE IT
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
                child: Icon(
                  _getCategoryIcon(category),
                  color: green,
                  size: 23,
                ),
              ),

              if (freelancerCount > 0)
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
                      freelancerCount > 99
                          ? '99+'
                          : freelancerCount.toString(),
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

          // CATEGORY NAME AND DESCRIPTION
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
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

          // ARROW
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

  // =============================================================
  // EMPTY SEARCH STATE
  // =============================================================

  Widget _buildEmptyState() {

    return Center(

      child:
          Padding(

        padding:
            const EdgeInsets.all(
          30,
        ),

        child:
            Column(

          mainAxisSize:
              MainAxisSize.min,

          children: [


            Container(

              width:
                  85,

              height:
                  85,

              decoration:
                  const BoxDecoration(

                color:
                    Color(0xFFE7F4EA),

                shape:
                    BoxShape.circle,

              ),

              child:
                  const Icon(

                Icons.search_off_outlined,

                size:
                    42,

                color:
                    green,

              ),

            ),


            const SizedBox(
              height:
                  18,
            ),


            const Text(

              'No category found',

              style:
                  TextStyle(

                fontSize:
                    19,

                fontWeight:
                    FontWeight.bold,

                color:
                    darkGreen,

              ),

            ),


            const SizedBox(
              height:
                  8,
            ),


            Text(

              'Try searching for another freelancer category',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(

                color:
                    Colors.grey.shade600,

              ),

            ),

          ],

        ),

      ),

    );

  }

}
