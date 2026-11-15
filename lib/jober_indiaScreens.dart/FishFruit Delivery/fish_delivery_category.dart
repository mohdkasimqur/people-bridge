import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/FishFruit%20Delivery/fish_delivery_nearby.dart';

class ScreenFishDeliveryCategories extends StatefulWidget {
  final ValueChanged<String> onCategorySelected;

  const ScreenFishDeliveryCategories({
    super.key,
    required this.onCategorySelected,
  });

  @override
  State<ScreenFishDeliveryCategories> createState() =>
      _ScreenFishDeliveryCategoriesState();
}

class _ScreenFishDeliveryCategoriesState
    extends State<ScreenFishDeliveryCategories> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';

  static const Color green = Color(0xFF138808);
  static const Color orange = Color(0xFFFF9800);

  static const List<Map<String, dynamic>> _defaultCategories = [
    {
      'name': 'Fish',
      'description': 'Fish delivery and sellers',
      'icon': Icons.set_meal,
    },
    {
      'name': 'Fruits',
      'description': 'Fresh fruits delivery',
      'icon': Icons.apple,
    },
    {
      'name': 'Vegetables',
      'description': 'Fresh vegetables delivery',
      'icon': Icons.eco,
    },
    {
      'name': 'Fruits & Vegetables',
      'description': 'Fruits and vegetables delivery',
      'icon': Icons.shopping_basket,
    },
    {
      'name': 'Foods',
      'description': 'Food delivery services',
      'icon': Icons.restaurant,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Read specializations saved by Fish Delivery profiles.
  List<String> _getSpecializations(
    Map<String, dynamic> data,
  ) {
    final dynamic saved = data['specializations'];

    if (saved is List) {
      return saved
          .map((value) => value.toString().trim().toLowerCase())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
    }

    // Compatibility with older profiles, if present.
    final dynamic oldItems = data['selectedItemList'];

    if (oldItems is List) {
      return oldItems
          .map((value) => value.toString().trim().toLowerCase())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
    }

    return [];
  }

  // A person counts once per specialization.
  // A profile is available if logged in or sharing live location.
  int _countAvailablePeople(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> profiles,
    String categoryName,
  ) {
    final String target = categoryName.trim().toLowerCase();

    return profiles.where((profile) {
      final Map<String, dynamic> data = profile.data();

      final bool isActive = data['isActive'] == true;
      final bool isOnline = data['isOnline'] == true;
      final bool isLive = data['isLive'] == true;

      if (!isActive || (!isOnline && !isLive)) {
        return false;
      }

      return _getSpecializations(data).contains(target);
    }).length;
  }

  IconData _categoryIcon(String name) {
    switch (name.trim().toLowerCase()) {
      case 'fish':
        return Icons.set_meal;
      case 'fruits':
        return Icons.apple;
      case 'vegetables':
        return Icons.eco;
      case 'fruits & vegetables':
        return Icons.shopping_basket;
      case 'foods':
        return Icons.restaurant;
      default:
        return Icons.storefront;
    }
  }

  String _categoryDescription(String name) {
    switch (name.trim().toLowerCase()) {
      case 'fish':
        return 'Fish delivery and sellers';
      case 'fruits':
        return 'Fresh fruits delivery';
      case 'vegetables':
        return 'Fresh vegetables delivery';
      case 'fruits & vegetables':
        return 'Fruits and vegetables delivery';
      case 'foods':
        return 'Food delivery services';
      default:
        return '$name delivery services';
    }
  }

  List<Map<String, dynamic>> _mergeCategories(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, Map<String, dynamic>> unique = {};

    for (final category in _defaultCategories) {
      final String name = category['name'] as String;
      unique[name.toLowerCase()] = category;
    }

    for (final doc in snapshot.docs) {
      final String name =
          (doc.data()['name'] ?? '').toString().trim();

      if (name.isEmpty) continue;

      final String key = name.toLowerCase();

      unique.putIfAbsent(
        key,
        () => {
          'name': name,
          'description': _categoryDescription(name),
          'icon': _categoryIcon(name),
        },
      );
    }

    final List<Map<String, dynamic>> result =
        unique.values.toList();

    result.sort((a, b) {
      final String aName = a['name'] as String;
      final String bName = b['name'] as String;

      final int aDefault = _defaultCategories.indexWhere(
        (item) =>
            (item['name'] as String).toLowerCase() ==
            aName.toLowerCase(),
      );

      final int bDefault = _defaultCategories.indexWhere(
        (item) =>
            (item['name'] as String).toLowerCase() ==
            bName.toLowerCase(),
      );

      if (aDefault != -1 && bDefault != -1) {
        return aDefault.compareTo(bDefault);
      }

      if (aDefault != -1) return -1;
      if (bDefault != -1) return 1;

      return aName.toLowerCase().compareTo(
            bName.toLowerCase(),
          );
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Fish Delivery Specializations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search categories.
          Container(
            color: green,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search specializations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchText.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchText = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('fishDeliverySpecializations')
                  .snapshots(),
              builder: (context, categorySnapshot) {
                if (categorySnapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Could not load specializations. Please try again.',
                    ),
                  );
                }

                if (categorySnapshot.connectionState ==
                        ConnectionState.waiting &&
                    !categorySnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: green),
                  );
                }

                final categories = _mergeCategories(
                  categorySnapshot.data ??
                      _emptyCategorySnapshot(),
                );

                final filteredCategories =
                    categories.where((category) {
                  final String name =
                      (category['name'] as String).toLowerCase();

                  return _searchText.isEmpty ||
                      name.contains(_searchText);
                }).toList();

                return StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestore
                      .collection('fishDeliveryGuys')
                      .snapshots(),
                  builder: (context, profileSnapshot) {
                    if (profileSnapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Could not load available delivery people.',
                        ),
                      );
                    }

                    if (profileSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        !profileSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: green,
                        ),
                      );
                    }

                    final profiles = profileSnapshot.data?.docs ?? [];

                    if (filteredCategories.isEmpty) {
                      return const Center(
                        child: Text('No specializations found.'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];

                        final String name =
                            category['name'] as String;

                        final int count = _countAvailablePeople(
                          profiles,
                          name,
                        );

                        return _categoryCard(
                          category: category,
                          count: count,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  QuerySnapshot<Map<String, dynamic>> _emptyCategorySnapshot() {
    throw StateError(
      'Category snapshot is not available yet.',
    );
  }

  Widget _categoryCard({
    required Map<String, dynamic> category,
    required int count,
  }) {
    final String name = category['name'] as String;
    final String description =
        category['description'] as String;
    final IconData icon = category['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
 onTap: () {
   widget.onCategorySelected(name);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ScreenFishDeliveryNearby(
        categoryId: name,
        categoryName: name,
      ),
    ),
  );
},          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
Stack(
  clipBehavior: Clip.none,
  children: [
    Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        size: 30,
        color: green,
      ),
    ),

    // Count badge at the top-right of the icon.
    if (count > 0)
      Positioned(
        top: -8,
        right: -8,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 23,
            minHeight: 23,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 3,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: orange,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: Text(
            count > 99 ? '99+' : count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
  ],
),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Hide the badge when no people are available.
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

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: orange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}