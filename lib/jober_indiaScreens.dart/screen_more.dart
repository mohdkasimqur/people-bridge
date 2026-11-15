import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/CorierService/corrier_categories.dart';
import 'package:jober_india/jober_indiaScreens.dart/FishFruit%20Delivery/fish_delivery_category.dart';

import 'package:jober_india/jober_indiaScreens.dart/Laboratory/screen_laboratory_catagory.dart';
import 'package:jober_india/jober_indiaScreens.dart/broker/screen_broker_category.dart';
import 'package:jober_india/jober_indiaScreens.dart/companies/company_catagory.dart';
import 'package:jober_india/jober_indiaScreens.dart/garage/screen_grge_categry.dart';
import 'package:jober_india/jober_indiaScreens.dart/Groceries/screen_grocery_category.dart';
import 'package:jober_india/jober_indiaScreens.dart/rentals/screen_rental_category.dart';
import 'package:jober_india/jober_indiaScreens.dart/spareparts/screen_spare_parts_category.dart';

import 'IndividualSellers/screen_self_business_catagory.dart';
import 'otherBusiness/other_business_categories.dart';

// ================================================================
// SCREEN MORE
// ================================================================

class ScreenMore extends StatefulWidget {
  const ScreenMore({super.key});

  @override
  State<ScreenMore> createState() => _ScreenMoreState();
}

class _ScreenMoreState extends State<ScreenMore> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

 

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _laboratorySubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
_sparePartsSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _brokerSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _companySubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _garageSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _courierSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _otherBusinessSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _rentalSubscription;

int _totalRentals = 0;

int _totalOtherBusinesses = 0;

int _totalCouriers = 0;

int _totalCompanies = 0;

int _totalGarages = 0;

int _totalBrokers = 0;

int _totalSpareParts = 0;

int _totalLaboratories = 0;




@override
void initState() {
  super.initState();

  _listenToLaboratoryCount();
  _listenToSparePartsCount();
  _listenToBrokerCount();
  _listenToCompanyCount();
  _listenToGarageCount();
  _listenToCourierCount();
  _listenToRentalCount();

  // NEW
  _listenToOtherBusinessCount();
}

// ============================================================
// REAL-TIME TOTAL ACTIVE RENTAL COUNT
// ============================================================

void _listenToRentalCount() {
  _rentalSubscription = _firestore
      .collection('rentals')
      .where('isActive', isEqualTo: true)
      .where('isRegistered', isEqualTo: true)
      .snapshots()
      .listen(
    (snapshot) {
      if (!mounted) return;

      setState(() {
        _totalRentals = snapshot.docs.length;
      });

      debugPrint(
        'TOTAL ACTIVE RENTALS: $_totalRentals',
      );
    },
    onError: (error) {
      debugPrint(
        'Rental count error: $error',
      );
    },
  );
}

// ============================================================
// REAL-TIME TOTAL ACTIVE OTHER BUSINESS COUNT
// ============================================================

void _listenToOtherBusinessCount() {
  _otherBusinessSubscription = _firestore
      .collection('otherBusinesses')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .listen(
    (snapshot) {
      if (!mounted) return;

      setState(() {
        _totalOtherBusinesses = snapshot.docs.length;
      });

      debugPrint(
        'TOTAL ACTIVE OTHER BUSINESSES: '
        '$_totalOtherBusinesses',
      );
    },
    onError: (error) {
      debugPrint(
        'Other Business count error: $error',
      );
    },
  );
}

// ============================================================
// REAL-TIME TOTAL ACTIVE COURIER COUNT
// ============================================================

void _listenToCourierCount() {
  _courierSubscription = _firestore
      .collection('couriers')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .listen(
    (snapshot) {
      if (!mounted) return;

      setState(() {
        _totalCouriers = snapshot.docs.length;
      });

      debugPrint(
        'TOTAL ACTIVE COURIERS: $_totalCouriers',
      );
    },
    onError: (error) {
      debugPrint('Courier count error: $error');
    },
  );
}

// ============================================================
// REAL-TIME TOTAL ACTIVE GARAGE COUNT
// ============================================================

void _listenToGarageCount() {

  _garageSubscription = _firestore
      .collection('garageOwners')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .listen(
    (snapshot) {

      if (!mounted) return;

      setState(() {
        _totalGarages = snapshot.docs.length;
      });

    },
    onError: (error) {
      debugPrint('Garage count error: $error');
    },
  );
}

// ============================================================
// REAL-TIME TOTAL ACTIVE COMPANY COUNT
// ============================================================

void _listenToCompanyCount() {
  _companySubscription = _firestore
      .collection('companies')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .listen(
    (snapshot) {
      if (!mounted) return;

      setState(() {
        _totalCompanies = snapshot.docs.length;
      });
    },
    onError: (error) {
      debugPrint('Company count error: $error');
    },
  );
}

// ============================================================
// REAL-TIME TOTAL BROKER COUNT
// ============================================================

void _listenToBrokerCount() {
  _brokerSubscription = _firestore
      .collection('brokers')
      .where(
        'isActive',
        isEqualTo: true,
      )
      .snapshots()
      .listen(
    (snapshot) {
      if (!mounted) return;

      setState(() {
        _totalBrokers = snapshot.docs.length;
      });
    },
    onError: (error) {
      debugPrint('Broker count error: $error');
    },
  );
}

void _listenToSparePartsCount() {
  _sparePartsSubscription = _firestore
      .collection('auto_spare_parts_shops')
      .snapshots()
      .listen(
    (snapshot) {
      if (!mounted) return;

      setState(() {
        _totalSpareParts = snapshot.docs.length;
      });

      debugPrint(
        'TOTAL AUTO SPARE PARTS SHOPS: $_totalSpareParts',
      );
    },
    onError: (error) {
      debugPrint('Spare parts count error: $error');
    },
  );
}

// ============================================================
// REAL-TIME TOTAL LABORATORY COUNT
// ============================================================

void _listenToLaboratoryCount() {
  _laboratorySubscription = _firestore
      .collection('labs')
      .where(
        'isActive',
        isEqualTo: true,
      )
      .snapshots()
      .listen(
    (snapshot) {
      if (!mounted) return;

      setState(() {
        _totalLaboratories = snapshot.docs.length;
      });
    },
    onError: (error) {
      debugPrint(
        'Laboratory count error: $error',
      );
    },
  );
}

 @override
void dispose() {
  _laboratorySubscription?.cancel();
  _sparePartsSubscription?.cancel();
  _brokerSubscription?.cancel();
  _companySubscription?.cancel();
  _garageSubscription?.cancel();
  _courierSubscription?.cancel();
  _otherBusinessSubscription?.cancel();
  _rentalSubscription?.cancel();

  super.dispose();
}

  // ==============================================================
  // MORE SERVICE CATEGORIES
  // ==============================================================

  List<Map<String, dynamic>> _categories() {
    return [
      // ==========================================================
      // 12. RENTALS
      // ==========================================================

      {
        'title': 'Rentals',
        'icon': Icons.key_outlined,
        'iconColor': Colors.red,
        'backgroundColor': const Color(0xFFFFF7EF),
      },

      // ==========================================================
      // 13. INDIVIDUAL SELLERS
      // ==========================================================

      {
        'title': 'Individual Sellers',
        'icon': Icons.person_search_outlined,
        'iconColor': Colors.red,
        'backgroundColor': const Color(0xFFFFF7EF),
      },

      // ==========================================================
      // 14. GROCERY
      // ==========================================================

      {
        'title': 'Grocery',
        'icon': Icons.shopping_cart,
        'iconColor': Colors.red,
        'backgroundColor': const Color(0xFFFFF7EF),
      },

      // ==========================================================
      // 15. OTHER BUSINESS
      // ==========================================================

      {
        'title': 'Other Business',
        'icon': Icons.business_center_outlined,
        'iconColor': Colors.red,
        'backgroundColor': const Color(0xFFFFF7EF),
      },

      // FISH DELIVERY
{
  'title': 'Fish Delivery',
  'icon': Icons.delivery_dining,
  'iconColor': Colors.red,
  'backgroundColor': const Color(0xFFFFF7EF),
},

      // ==========================================================
      // 16. BROKERS
      // ==========================================================

      {
        'title': 'Brokers',
        'icon': Icons.handshake_outlined,
        'iconColor': Colors.red,
        'backgroundColor': const Color(0xFFFFF7EF),
      },

      // ==========================================================
      // 17. GARAGES
      // ==========================================================

      {
        'title': 'Garages',
        'icon': Icons.car_repair,
        'iconColor': Colors.red,
        'backgroundColor': const Color(0xFFFFF7EF),
      },

      // ==========================================================
      // 18. SPARE PARTS
      // ==========================================================

      {
        'title': 'Spare Parts',
        'icon': Icons.build_circle_outlined,
        'iconColor': Colors.red,
        'backgroundColor': const Color(0xFFFFF7EF),
      },

      // ==========================================================
      // 19. COURIERS
      // ==========================================================

      {
        'title': 'Couriers',
        'icon': Icons.local_shipping_outlined,
        'iconColor': Colors.red,
        'backgroundColor': const Color(0xFFFFF7EF),
      },

      // ==========================================================
      // 20. LABS
      // ==========================================================

      {
        'title': 'Labs',
        'icon': Icons.biotech_outlined,
        'iconColor': Colors.red,
        'backgroundColor': const Color(0xFFFFF7EF),
      },

      // ==========================================================
      // 21. COMPANIES
      // ==========================================================

      {
        'title': 'Companies',
        'icon': Icons.business_outlined,
        'iconColor': Colors.red,
        'backgroundColor': const Color(0xFFFFF7EF),
      },
    ];
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final categories = _categories();

    return Scaffold(
      backgroundColor: Colors.white,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF138808),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'More Services',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'All Services',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF063B32),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Choose a service',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // 4 BUTTONS PER ROW
              // ==================================================

              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: categories.length,

                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 22,
                    childAspectRatio: 0.72,
                  ),

                  itemBuilder:
                      (context, index) {
                    final category =
                        categories[index];

                    final String title =
                        category['title']
                            as String;

                    final IconData icon =
                        category['icon']
                            as IconData;

                    final Color iconColor =
                        category['iconColor']
                            as Color;

                    final Color backgroundColor =
                        category[
                                'backgroundColor']
                            as Color;

                    return GestureDetector(
                      onTap: () {
                        _openCategory(
                          context,
                          title,
                        );
                      },

                      child: Column(
                        children: [
                          // ======================================
                          // ICON
                          // ======================================

                          Stack(
  clipBehavior: Clip.none,
  children: [
    Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 30,
        color: iconColor,
      ),
    ),



    // ==================================================
// TOTAL OTHER BUSINESS COUNT BADGE
// ==================================================

if (title == 'Other Business' &&
    _totalOtherBusinesses > 0)
  Positioned(
    top: -7,
    right: -9,
    child: Container(
      constraints: const BoxConstraints(
        minWidth: 21,
        minHeight: 21,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _totalOtherBusinesses > 99
            ? '99+'
            : '$_totalOtherBusinesses',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),

  // ==================================================
// TOTAL RENTAL COUNT BADGE
// ==================================================

if (title == 'Rentals' && _totalRentals > 0)
  Positioned(
    top: -7,
    right: -9,
    child: Container(
      constraints: const BoxConstraints(
        minWidth: 21,
        minHeight: 21,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _totalRentals > 99
            ? '99+'
            : '$_totalRentals',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
  
      // ==================================================
// TOTAL GARAGE COUNT BADGE
// ==================================================

if (title == 'Garages' && _totalGarages > 0)
  Positioned(
    top: -7,
    right: -9,
    child: Container(
      constraints: const BoxConstraints(
        minWidth: 21,
        minHeight: 21,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _totalGarages > 99
            ? '99+'
            : '$_totalGarages',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),

  // ==================================================
// TOTAL COURIER COUNT BADGE
// ==================================================

if (title == 'Couriers' && _totalCouriers > 0)
  Positioned(
    top: -7,
    right: -9,
    child: Container(
      constraints: const BoxConstraints(
        minWidth: 21,
        minHeight: 21,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _totalCouriers > 99
            ? '99+'
            : '$_totalCouriers',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),

      // ==================================================
// TOTAL COMPANY COUNT BADGE
// ==================================================

if (title == 'Companies' && _totalCompanies > 0)
  Positioned(
    top: -7,
    right: -9,
    child: Container(
      constraints: const BoxConstraints(
        minWidth: 21,
        minHeight: 21,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _totalCompanies > 99
            ? '99+'
            : '$_totalCompanies',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),

      // ==================================================
// TOTAL LABORATORY COUNT BADGE
// ==================================================

if (title == 'Labs' &&
    _totalLaboratories > 0)
  Positioned(
    top: -7,
    right: -9,
    child: Container(
      constraints: const BoxConstraints(
        minWidth: 21,
        minHeight: 21,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _totalLaboratories > 99
            ? '99+'
            : '$_totalLaboratories',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),

  // ==================================================
// TOTAL BROKER COUNT BADGE
// ==================================================

if (title == 'Brokers' && _totalBrokers > 0)
  Positioned(
    top: -7,
    right: -9,
    child: Container(
      constraints: const BoxConstraints(
        minWidth: 21,
        minHeight: 21,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _totalBrokers > 99
            ? '99+'
            : '$_totalBrokers',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),

  // ==================================================
// SPARE PARTS TOTAL COUNT BADGE
// ==================================================

if (title == 'Spare Parts' &&
    _totalSpareParts > 0)
  Positioned(
    top: -7,
    right: -9,
    child: Container(
      constraints: const BoxConstraints(
        minWidth: 21,
        minHeight: 21,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _totalSpareParts > 99
            ? '99+'
            : '$_totalSpareParts',
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

                          const SizedBox(
                            height: 8,
                          ),

                          // ======================================
                          // TITLE
                          // ======================================

                          Text(
                            title,
                            textAlign:
                                TextAlign.center,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Colors.black87,
                            ),
                          ),
                        ],
                      ),
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

  // ==============================================================
  // OPEN MORE CATEGORY
  // ==============================================================

  void _openCategory(
    BuildContext context,
    String title,
  ) {
    switch (title) {
      // ==========================================================
      // 12. RENTALS
      // ==========================================================

      case 'Rentals':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const RentalCategoryScreen(),
          ),
        );
        break;

      // ==========================================================
      // 13. INDIVIDUAL SELLERS
      // ==========================================================

      case 'Individual Sellers':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const ScreenIndividualSellerCategories(),
          ),
        );
        break;

      // ==========================================================
      // 14. GROCERY
      // ==========================================================

      case 'Grocery':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const ScreenGroceryCategories(),
          ),
        );
        break;

      // ==========================================================
      // 15. OTHER BUSINESS
      // ==========================================================

      case 'Other Business':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const ScreenOtherBusinessCategories(),
          ),
        );
        break;

      // FISH DELIVERY
case 'Fish Delivery':
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ScreenFishDeliveryCategories(
        onCategorySelected: (specialization) {
          debugPrint(
            'Selected Fish Delivery specialization: '
            '$specialization',
          );
        },
      ),
    ),
  );
  break;

      // ==========================================================
      // 16. BROKERS
      // ==========================================================

      case 'Brokers':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const ScreenBrokerCategories(),
          ),
        );
        break;

      // ==========================================================
      // 17. GARAGES
      // ==========================================================

      case 'Garages':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const ScreenGarageCategory(),
          ),
        );
        break;

      // ==========================================================
      // 18. SPARE PARTS
      // ==========================================================

      case 'Spare Parts':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const ScreenAutoSparePartsCategory(),
          ),
        );
        break;

      // ==========================================================
      // 19. COURIERS
      // ==========================================================

      case 'Couriers':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                 ScreenCourierCategories(),
          ),
        );
        break;

      // ==========================================================
      // 20. LABS
      // ==========================================================

      case 'Labs':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const ScreenLaboratoryCategories(),
          ),
        );
        break;

      // ==========================================================
      // 21. COMPANIES
      // ==========================================================

      case 'Companies':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const ScreenCompanyCategory(),
          ),
        );
        break;
    }
  }
}


  // ============================================================
  // REAL-TIME TOTAL RENTAL COUNT
  // ============================================================

  // void _listenToRentalCount() {
  //   _rentalSubscription = _firestore
  //       .collection('rentals')
  //       .snapshots()
  //       .listen(
  //     (snapshot) {
  //       int count = 0;

  //       for (final doc in snapshot.docs) {
  //         final data = doc.data();

  //         if (data['isActive'] == true &&
  //             data['isRegistered'] == true) {
  //           count++;
  //         }
  //       }

  //       if (!mounted) return;

  //       setState(() {
  //         _totalRentals = count;
  //       });
  //     },
  //     onError: (error) {
  //       debugPrint('Rental count error: $error');
  //     },
  //   );
  // }


  //   // ==================================================
  //   // RENTALS TOTAL COUNT BADGE
  //   // ==================================================

  //   if (title == 'Rentals' && _totalRentals > 0)
  //     Positioned(
  //       top: -7,
  //       right: -9,
  //       child: Container(
  //         constraints: const BoxConstraints(
  //           minWidth: 21,
  //           minHeight: 21,
  //         ),
  //         padding: const EdgeInsets.symmetric(
  //           horizontal: 5,
  //           vertical: 3,
  //         ),
  //         decoration: BoxDecoration(
  //           color: Colors.red,
  //           borderRadius: BorderRadius.circular(20),
  //           border: Border.all(
  //             color: Colors.white,
  //             width: 1.5,
  //           ),
  //         ),
  //         alignment: Alignment.center,
  //         child: Text(
  //           _totalRentals > 99
  //               ? '99+'
  //               : '$_totalRentals',
  //           style: const TextStyle(
  //             color: Colors.white,
  //             fontSize: 10,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //       ),
  //     ),


// @override
// void initState() {
//   super.initState();

//   _listenToRentalCount();
//   _listenToLaboratoryCount();
//   _listenToSparePartsCount();
//   _listenToBrokerCount();
//   _listenToCompanyCount();
//   _listenToGarageCount();
//   _listenToCourierCount();
// }

 // StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  //     _rentalSubscription;
  //       int _totalRentals = 0;
    // _listenToRentalCount();
    //  _rentalSubscription?.cancel();


