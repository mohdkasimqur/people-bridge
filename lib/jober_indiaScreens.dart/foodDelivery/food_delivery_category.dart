import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/foodDelivery/food_delivery_nearby.dart';


class ScreenFoodDeliveryCategories
    extends StatefulWidget {
  final double userLatitude;
  final double userLongitude;

  const ScreenFoodDeliveryCategories({
    super.key,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  State<ScreenFoodDeliveryCategories>
      createState() =>
          _ScreenFoodDeliveryCategoriesState();
}

class _ScreenFoodDeliveryCategoriesState
    extends State<ScreenFoodDeliveryCategories> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final searchController =
      TextEditingController();

  bool isLoading = true;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _foodDeliverySubscription;

StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _categorySubscription;

  final defaultCategories = const [
    {
      'id': 'bike',
      'name': 'Bike',
      'iconType': 'bike',
    },
    {
      'id': 'auto',
      'name': 'Auto',
      'iconType': 'auto',
    },
    {
      'id': 'car',
      'name': 'Car',
      'iconType': 'car',
    },
    {
      'id': 'van',
      'name': 'Van',
      'iconType': 'van',
    },
    {
      'id': 'mini_truck',
      'name': 'Mini Truck',
      'iconType': 'mini_truck',
    },
    {
      'id': 'truck',
      'name': 'Truck',
      'iconType': 'truck',
    },
    {
      'id': 'cycle',
      'name': 'Cycle',
      'iconType': 'cycle',
    },
  ];

  List<Map<String, dynamic>>
      customCategories = [];

  Map<String, int> liveCounts = {};

  @override
void initState() {
  super.initState();

  searchController.addListener(() {
    if (mounted) setState(() {});
  });

  _listenToFoodDeliveryCounts();
  _listenToFoodDeliveryCategories();
}

  
  @override
void dispose() {
  searchController.dispose();
  _foodDeliverySubscription?.cancel();
  _categorySubscription?.cancel();
  super.dispose();
}

  // ==========================================================
// REAL-TIME COUNTS PER FOOD DELIVERY CATEGORY
// ==========================================================
void _listenToFoodDeliveryCounts() {
  _foodDeliverySubscription?.cancel();

  _foodDeliverySubscription = _firestore
      .collection('foodDeliveryGuys')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .listen(
    (snapshot) {
      final Map<String, int> counts = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final rawCategories = data['categories'];

        if (rawCategories is! List) continue;

        // Count each registered driver once per category.
        final categories = rawCategories
            .whereType<String>()
            .toSet();

        for (final id in categories) {
          counts[id] = (counts[id] ?? 0) + 1;
        }
      }

      if (!mounted) return;

      setState(() {
        liveCounts = counts;
        isLoading = false;
      });
    },
    onError: (Object error) {
      debugPrint('Food delivery count error: $error');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    },
  );
}

// ==========================================================
// REAL-TIME DEFAULT + CUSTOM CATEGORY DEFINITIONS
// ==========================================================

void _listenToFoodDeliveryCategories() {
  _categorySubscription?.cancel();

  _categorySubscription = _firestore
      .collection('foodDeliveryVehicleCategories')
      .snapshots()
      .listen(
    (snapshot) {
      final categories = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        categories.add({
          ...data,
          'id': doc.id,
          'name': data['name']?.toString() ?? doc.id,
          'iconType': data['iconType']?.toString() ?? 'custom',
        });
      }

      if (!mounted) return;

      setState(() {
        customCategories = categories;
      });
    },
    onError: (Object error) {
      debugPrint('Food delivery categories error: $error');
    },
  );
}

  Future<void> _loadCategories() async {
    try {
      final snapshot = await _firestore
          .collection(
            'foodDeliveryVehicleCategories',
          )
          .orderBy('name')
         // .limit(100)
          .get();

      customCategories = snapshot.docs
          .map((doc) => doc.data())
          .toList();

      await _loadLiveCounts();
    } catch (_) {
      await _loadLiveCounts();
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadLiveCounts() async {
    final snapshot = await _firestore
        .collection('liveLocations')
        .where(
          'role',
          isEqualTo: 'food_delivery',
        )
        .where(
          'isLive',
          isEqualTo: true,
        )
        .where(
          'expiresAt',
          isGreaterThan:
              Timestamp.now(),
        )
        .get();

    final counts = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final categories =
          List<String>.from(
        data['categories'] ?? const [],
      );

      for (final category in categories) {
        counts[category] =
            (counts[category] ?? 0) + 1;
      }
    }

    liveCounts = counts;
  }

  List<Map<String, dynamic>>
      get allCategories {
    final map =
        <String, Map<String, dynamic>>{};

    for (final category
        in defaultCategories) {
      map[category['id'] as String] =
          category;
    }

    for (final category
        in customCategories) {
      final id =
          category['id']?.toString();

      if (id != null &&
          id.isNotEmpty) {
        map[id] = {
          'id': id,
          'name':
              category['name']?.toString() ??
                  id,
          'iconType':
              category['iconType'] ??
                  'custom',
        };
      }
    }

    return map.values.toList();
  }

  List<Map<String, dynamic>>
      get filteredCategories {
    final query =
        searchController.text
            .trim()
            .toLowerCase();

    if (query.isEmpty) {
      return allCategories;
    }

    return allCategories.where((item) {
      return item['name']
          .toString()
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  IconData _iconFor(String iconType) {
    switch (iconType) {
      case 'bike':
        return Icons.two_wheeler;
      case 'auto':
        return Icons.electric_rickshaw;
      case 'car':
        return Icons.directions_car_outlined;
      case 'van':
        return Icons.airport_shuttle_outlined;
      case 'mini_truck':
        return Icons.local_shipping_outlined;
      case 'truck':
        return Icons.fire_truck_outlined;
      case 'cycle':
        return Icons.pedal_bike_outlined;
      default:
        return Icons.delivery_dining_outlined;
    }
  }

  String _countText(int count) {
    if (count > 99) {
      return '99+';
    }

    return count.toString();
  }

  Future<void> _openCategory(
    Map<String, dynamic> category,
  ) async {
    final id = category['id'].toString();
    final name = category['name'].toString();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ScreenFoodDeliveryNearbyList(
          categoryId: id,
          categoryName: name,
          // userLatitude:
          //     widget.userLatitude,
          // userLongitude:
          //     widget.userLongitude,
        ),
      ),
    );

    if (mounted) {
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        filteredCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Food Delivery',
        ),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadCategories,
              child: ListView(
                padding:
                    const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller:
                        searchController,
                    decoration:
                        InputDecoration(
                      hintText:
                          'Search vehicle category',
                      prefixIcon:
                          const Icon(
                        Icons.search,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  for (final category
                      in categories)
                    _categoryCard(
                      category,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _categoryCard(
    Map<String, dynamic> category,
  ) {
    final id = category['id'].toString();

    final count =
        liveCounts[id] ?? 0;

    return Card(
      margin:
          const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: () =>
            _openCategory(category),
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                child: Icon(
                  _iconFor(
                    category['iconType']
                        .toString(),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['name']
                          .toString(),
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      count == 0
    ? 'No registered drivers'
    : '$count registered Food Delivery Guys',
                      style:
                          TextStyle(
                        color: count > 0
                            ? Colors.green
                            : Colors.grey,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              if (count > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.red,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    _countText(count),
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(width: 6),

              const Icon(
                Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}