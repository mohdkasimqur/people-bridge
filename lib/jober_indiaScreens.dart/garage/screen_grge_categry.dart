// import 'package:flutter/material.dart';
// import 'package:jober_india/jober_indiaScreens.dart/garage/screen_garage_categories.dart';

// import 'screen_garage_list.dart';

// class ScreenGarageCategory extends StatefulWidget {
//   const ScreenGarageCategory({super.key});

//   @override
//   State<ScreenGarageCategory> createState() => _ScreenGarageCategoryState();
// }

// class _ScreenGarageCategoryState extends State<ScreenGarageCategory> {
//   final TextEditingController searchController =
//       TextEditingController();

//   List<String> filteredCategories = [];

//   @override
//   void initState() {
//     super.initState();

//     filteredCategories = List<String>.from(garageCategories);

//     searchController.addListener(_filterCategories);
//   }

//   void _filterCategories() {
//     final query = searchController.text.trim().toLowerCase();

//     setState(() {
//       if (query.isEmpty) {
//         filteredCategories = List<String>.from(garageCategories);
//       } else {
//         filteredCategories = garageCategories
//             .where(
//               (category) =>
//                   category.toLowerCase().contains(query),
//             )
//             .toList();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     searchController.removeListener(_filterCategories);
//     searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Garage Services'),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(
//               16,
//               12,
//               16,
//               8,
//             ),
//             child: TextField(
//               controller: searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search garage service',
//                 prefixIcon: const Icon(Icons.search),
//                 suffixIcon: searchController.text.isNotEmpty
//                     ? IconButton(
//                         icon: const Icon(Icons.clear),
//                         onPressed: () {
//                           searchController.clear();
//                         },
//                       )
//                     : null,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ),

//           Expanded(
//             child: filteredCategories.isEmpty
//                 ? const Center(
//                     child: Text(
//                       'No garage service found',
//                     ),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.all(12),
//                     itemCount: filteredCategories.length,
//                     itemBuilder: (context, index) {
//                       final category =
//                           filteredCategories[index];

//                       return Card(
//                         margin: const EdgeInsets.only(
//                           bottom: 8,
//                         ),
//                         child: ListTile(
//                           leading: const CircleAvatar(
//                             child: Icon(
//                               Icons.car_repair,
//                             ),
//                           ),
//                           title: Text(
//                             category,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           trailing: const Icon(
//                             Icons.chevron_right,
//                           ),
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) =>
//                                     ScreenGarageList(
//                                   category: category,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/garage/screen_garage_categories.dart';
import 'package:jober_india/jober_indiaScreens.dart/garage/screen_garage_list.dart';

// class ScreenGarageCategory extends StatefulWidget {
//   const ScreenGarageCategory({super.key});

//   @override
//   State<ScreenGarageCategory> createState() =>
//       _ScreenGarageCategoryState();
// }

// class _ScreenGarageCategoryState
//     extends State<ScreenGarageCategory> {

//   final FirebaseFirestore _firestore =
//       FirebaseFirestore.instance;

//   final TextEditingController searchController =
//       TextEditingController();

//   String searchQuery = '';

//   // ----------------------------------------------------------
//   // REAL-TIME GARAGE PROFILES
//   // ----------------------------------------------------------

//   Stream<QuerySnapshot<Map<String, dynamic>>>
//       get garageStream {
//     return _firestore
//         .collection('garageOwners')
//         .where('isActive', isEqualTo: true)
//         .snapshots();
//   }

//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }

//   // ----------------------------------------------------------
//   // BUILD CATEGORY LIST AND COUNTS
//   // ----------------------------------------------------------

//   Widget buildGarageCategories(
//     QuerySnapshot<Map<String, dynamic>> snapshot,
//   ) {

//     final Map<String, int> categoryCounts = {};

//     final Map<String, String> categoryNames = {};

//     // First add all built-in categories.
//     for (final category in garageCategories) {
//       categoryNames[category.toLowerCase()] = category;
//       categoryCounts[category.toLowerCase()] = 0;
//     }

//     // Read categories from all active garages.
//     for (final doc in snapshot.docs) {

//       final data = doc.data();

//       final rawCategories = data['categories'];

//       if (rawCategories is! List) continue;

//       // Count each category only once per garage.
//       final Set<String> garageCategorySet = {};

//       for (final item in rawCategories) {

//         if (item is! String) continue;

//         final category = item.trim();

//         if (category.isEmpty) continue;

//         final key = category.toLowerCase();

//         garageCategorySet.add(key);

//         // Automatically register custom categories.
//         categoryNames.putIfAbsent(
//           key,
//           () => category,
//         );
//       }

//       for (final key in garageCategorySet) {
//         categoryCounts[key] =
//             (categoryCounts[key] ?? 0) + 1;
//       }
//     }

//     // Built-in categories first, then custom categories.
//     final List<String> allCategories = [
//       ...garageCategories,
//       ...categoryNames.entries
//           .where(
//             (entry) => !garageCategories.any(
//               (item) =>
//                   item.toLowerCase() == entry.key,
//             ),
//           )
//           .map((entry) => entry.value),
//     ];

//     // Search filtering.
//     final filteredCategories = allCategories
//         .where((category) {
//           return category
//               .toLowerCase()
//               .contains(searchQuery);
//         })
//         .toList();

//     if (filteredCategories.isEmpty) {
//       return const Center(
//         child: Text('No garage service found'),
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(12),
//       itemCount: filteredCategories.length,
//       itemBuilder: (context, index) {

//         final category = filteredCategories[index];

//         final count =
//             categoryCounts[category.toLowerCase()] ?? 0;

//         return Card(
//           margin: const EdgeInsets.only(bottom: 8),
//           child: ListTile(

//             leading: Stack(
//               clipBehavior: Clip.none,
//               children: [

//                 const CircleAvatar(
//                   child: Icon(Icons.car_repair),
//                 ),

//                 if (count > 0)
//                   Positioned(
//                     top: -9,
//                     right: -12,
//                     child: Container(
//                       constraints: const BoxConstraints(
//                         minWidth: 20,
//                         minHeight: 20,
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 5,
//                         vertical: 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.red,
//                         borderRadius:
//                             BorderRadius.circular(20),
//                         border: Border.all(
//                           color: Colors.white,
//                           width: 1.5,
//                         ),
//                       ),
//                       alignment: Alignment.center,
//                       child: Text(
//                         count > 99 ? '99+' : '$count',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),

//             title: Text(
//               category,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w600,
//               ),
//             ),

//             subtitle: Text(
//               '$count ${count == 1 ? 'Garage' : 'Garages'}',
//               style: const TextStyle(
//                 color: Colors.grey,
//                 fontSize: 12,
//               ),
//             ),

//             trailing: const Icon(
//               Icons.chevron_right,
//             ),

//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ScreenGarageList(
//                     category: category,
//                   ),
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }

//   // ----------------------------------------------------------
//   // BUILD
//   // ----------------------------------------------------------

//   @override
//   Widget build(BuildContext context) {

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Garage Services'),
//         centerTitle: true,
//       ),

//       body: Column(
//         children: [

//           Padding(
//             padding: const EdgeInsets.fromLTRB(
//               16,
//               12,
//               16,
//               8,
//             ),
//             child: TextField(
//               controller: searchController,

//               onChanged: (value) {
//                 setState(() {
//                   searchQuery = value.trim().toLowerCase();
//                 });
//               },

//               decoration: InputDecoration(
//                 hintText: 'Search garage service',
//                 prefixIcon: const Icon(Icons.search),

//                 suffixIcon:
//                     searchController.text.isNotEmpty
//                         ? IconButton(
//                             icon: const Icon(Icons.clear),
//                             onPressed: () {
//                               searchController.clear();

//                               setState(() {
//                                 searchQuery = '';
//                               });
//                             },
//                           )
//                         : null,

//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ),

//           Expanded(
//             child: StreamBuilder<
//                 QuerySnapshot<Map<String, dynamic>>>(
//               stream: garageStream,

//               builder: (context, snapshot) {

//                 if (snapshot.hasError) {
//                   return const Center(
//                     child: Text(
//                       'Unable to load garage categories.',
//                     ),
//                   );
//                 }

//                 if (snapshot.connectionState ==
//                     ConnectionState.waiting) {
//                   return const Center(
//                     child: CircularProgressIndicator(),
//                   );
//                 }

//                 return buildGarageCategories(
//                   snapshot.data!,
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
class ScreenGarageCategory extends StatefulWidget {
  const ScreenGarageCategory({super.key});

  @override
  State<ScreenGarageCategory> createState() =>
      _ScreenGarageCategoryState();
}

class _ScreenGarageCategoryState
    extends State<ScreenGarageCategory> {
  final TextEditingController searchController =
      TextEditingController();

  String searchText = '';

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
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

  // ============================================================
  // OPEN GARAGE CATEGORY
  // ============================================================

  void openCategory(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenGarageList(
          category: category,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD DYNAMIC GARAGE CATEGORY COUNTS
  // ============================================================

  Map<String, int> buildCategoryCounts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        documents,
  ) {
    final Map<String, int> counts = {};

    for (final document in documents) {
      final data = document.data();

      if (data['isActive'] != true) continue;

      final List<dynamic> categories =
          data['categories'] is List
              ? data['categories']
              : [];

      // Count each garage only once per category.
      final Set<String> uniqueCategories = {};

      for (final item in categories) {
        if (item is! String) continue;

        final category = item.trim();

        if (category.isNotEmpty) {
          uniqueCategories.add(category.toLowerCase());
        }
      }

      for (final category in uniqueCategories) {
        counts[category] =
            (counts[category] ?? 0) + 1;
      }
    }

    return counts;
  }

  // ============================================================
  // BUILT-IN + CUSTOM GARAGE CATEGORIES
  // ============================================================

  List<String> buildAllCategories(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        documents,
  ) {
    final Map<String, String> uniqueCategories = {};

    // 1. Keep all existing built-in categories.
    for (final category in garageCategories) {
      uniqueCategories[category.toLowerCase()] =
          category;
    }

    // 2. Add categories saved by registered garages.
    for (final document in documents) {
      final data = document.data();

      if (data['isActive'] != true) continue;

      final List<dynamic> categories =
          data['categories'] is List
              ? data['categories']
              : [];

      for (final item in categories) {
        if (item is! String) continue;

        final category = item.trim();

        if (category.isEmpty) continue;

        uniqueCategories.putIfAbsent(
          category.toLowerCase(),
          () => category,
        );
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

  // ============================================================
  // SEARCH FIELD
  // ============================================================

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
          hintText: 'Search garage category',
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF16803C),
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
            horizontal: 18,
            vertical: 17,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GARAGE CATEGORY CARD
  // ============================================================

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
              // GARAGE ICON
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8EF),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.car_repair,
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

              // GARAGE COUNT
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8EF),
                  borderRadius:
                      BorderRadius.circular(10),
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
                  borderRadius:
                      BorderRadius.circular(10),
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

  // ============================================================
  // EMPTY SEARCH RESULT
  // ============================================================

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
              borderRadius:
                  BorderRadius.circular(22),
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

  // ============================================================
  // BUILD
  // ============================================================

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
                text: 'Garage ',
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Find a garage near you',
                style: TextStyle(
                  color: Color(0xFF202124),
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Select a garage category to find nearby garages.',
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
                    QuerySnapshot<
                        Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('garageOwners')
                      .where(
                        'isActive',
                        isEqualTo: true,
                      )
                      .snapshots(),

                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Unable to load garage categories.',
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

                    final filtered =
                        allCategories.where((category) {
                      return category
                          .toLowerCase()
                          .contains(searchText);
                    }).toList();

                    if (filtered.isEmpty) {
                      return _emptySearchResult();
                    }

                    return ListView.separated(
                      physics:
                          const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final category =
                            filtered[index];

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