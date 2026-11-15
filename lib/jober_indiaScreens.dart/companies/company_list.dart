// ================================================================
// COMPANY LIST SCREEN
// PART 1 / 3
// ================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:jober_india/jober_indiaScreens.dart/companies/company_profile.dart';

class CompanyListScreen extends StatefulWidget {
  final String selectedCategory;

  const CompanyListScreen({
    super.key,
    required this.selectedCategory,
  });

  @override
  State<CompanyListScreen> createState() =>
      _CompanyListScreenState();
}

class _CompanyListScreenState
    extends State<CompanyListScreen> {

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

  // ==============================================================
  // FIRESTORE
  // ==============================================================

  // final FirebaseFirestore _firestore =
  //     FirebaseFirestore.instance;
// =============================================================
// PAGINATION
// =============================================================

static const int _companiesPerPage = 20;

int _currentPage = 0;

int get _totalPages =>
    (_companies.length / _companiesPerPage).ceil();

List<Map<String, dynamic>> get _currentPageCompanies {
  final int start = _currentPage * _companiesPerPage;

  if (start >= _companies.length) {
    return [];
  }

  final int end = (start + _companiesPerPage)
      .clamp(0, _companies.length);

  return _companies.sublist(start, end);
}
  // ==============================================================
  // COMPANY LIST
  // ==============================================================

  List<Map<String, dynamic>> _companies = [];

  // ==============================================================
  // LOADING
  // ==============================================================

  bool _loading = true;

  String? _errorMessage;

  // ==============================================================
  // USER LOCATION
  // ==============================================================

  Position? _userPosition;

  // ==============================================================
  // INIT STATE
  // ==============================================================

  @override
  void initState() {
    super.initState();

    _loadCompanies();
  }

  // ==============================================================
  // LOAD COMPANIES
  // ==============================================================

//   //bool _isLoading = false;
//   Future<void> _loadCompanies() async {
//   if (mounted) {
//     setState(() {
//       _loading = true;
//     });
//   }

//   try {
//     await _getUserLocation();

//     final Position? userPosition = _userPosition;

//     // Without the user's location, we cannot calculate
//     // the distance or reliably apply the 50 km limit.
//     if (userPosition == null) {
//       if (!mounted) return;

//       setState(() {
//         _companies = [];
//         _currentPage = 0;
//         _loading = false;
//       });
//       return;
//     }

//     final snapshot = await FirebaseFirestore.instance
//         .collection('companies')
//         .get();

//     final List<Map<String, dynamic>> nearbyCompanies = [];

//     for (final doc in snapshot.docs) {
//       final Map<String, dynamic> data = doc.data();

//       // Keep your existing category matching.
//       if (!_companyMatchesCategory(
//         data,
//         widget.selectedCategory,
//       )) {
//         continue;
//       }

//       // First try the saved location map.
//       Map<String, dynamic>? locationData;

//       if (data['currentLocation'] is Map) {
//         locationData = Map<String, dynamic>.from(
//           data['currentLocation'] as Map,
//         );
//       } else if (data['location'] is Map) {
//         locationData = Map<String, dynamic>.from(
//           data['location'] as Map,
//         );
//       }

//       // Fall back to root latitude/longitude fields.
//       final dynamic rawLatitude =
//           locationData?['latitude'] ?? data['latitude'];

//       final dynamic rawLongitude =
//           locationData?['longitude'] ?? data['longitude'];

//       if (rawLatitude == null || rawLongitude == null) {
//         // Companies without coordinates cannot be distance-filtered.
//         continue;
//       }

//       final double? latitude =
//           double.tryParse(rawLatitude.toString());

//       final double? longitude =
//           double.tryParse(rawLongitude.toString());

//       if (latitude == null ||
//           longitude == null ||
//           latitude < -90 ||
//           latitude > 90 ||
//           longitude < -180 ||
//           longitude > 180) {
//         continue;
//       }

//       final double distanceKm =
//           Geolocator.distanceBetween(
//             userPosition.latitude,
//             userPosition.longitude,
//             latitude,
//             longitude,
//           ) /
//           1000.0;

//       // Show only companies within 50 km.
//       if (distanceKm > 50) {
//         continue;
//       }

//       nearbyCompanies.add({
//         ...data,
//         'companyId': doc.id,
//         'latitude': latitude,
//         'longitude': longitude,
//         'distanceKm': distanceKm,
//       });
//     }

//     // Nearest companies first.
//     nearbyCompanies.sort((a, b) {
//       final double distanceA =
//           (a['distanceKm'] as num).toDouble();

//       final double distanceB =
//           (b['distanceKm'] as num).toDouble();

//       return distanceA.compareTo(distanceB);
//     });

//     if (!mounted) return;

//     setState(() {
//       _companies = nearbyCompanies;
//       _loading = false;
//     });
//   } catch (e) {
//     debugPrint('Error loading companies: $e');

//     if (!mounted) return;

//     setState(() {
//       _companies = [];
//       _loading = false;
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Unable to load nearby companies.'),
//       ),
//     );
//   }
// }

Future<void> _loadCompanies() async {
  if (!mounted) return;

  setState(() {
    _loading = true;
    _errorMessage = null;
  });

  try {
    await _getUserLocation();

    final Position? userPosition = _userPosition;

    if (userPosition == null) {
      if (!mounted) return;

      setState(() {
        _companies = [];
        _currentPage = 0;
        _loading = false;
        _errorMessage =
            'Unable to get your location. Please enable GPS and try again.';
      });
      return;
    }

    final String category =
        widget.selectedCategory.trim();

    if (category.isEmpty) {
      if (!mounted) return;

      setState(() {
        _companies = [];
        _currentPage = 0;
        _loading = false;
      });
      return;
    }

    final companiesRef =
        FirebaseFirestore.instance.collection('companies');

    // Fetch only companies matching the selected category.
    // Run both queries together to support both saved fields.
    final snapshots = await Future.wait([
      companiesRef
          .where('categories', arrayContains: category)
          .get(),

      companiesRef
          .where('category', isEqualTo: category)
          .get(),
    ]);

    // Combine results and prevent duplicate documents.
    final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>
        uniqueCompanies = {};

    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        uniqueCompanies[doc.id] = doc;
      }
    }

    final List<Map<String, dynamic>> nearbyCompanies = [];

    for (final doc in uniqueCompanies.values) {
      final Map<String, dynamic> data = doc.data();

      // Keep your existing category validation.
      if (!_companyMatchesCategory(
        data,
        category,
      )) {
        continue;
      }

      Map<String, dynamic>? locationData;

      if (data['currentLocation'] is Map) {
        locationData = Map<String, dynamic>.from(
          data['currentLocation'] as Map,
        );
      } else if (data['location'] is Map) {
        locationData = Map<String, dynamic>.from(
          data['location'] as Map,
        );
      }

      // Read coordinates from the saved location map
      // or from the root fields.
      final dynamic rawLatitude =
          locationData?['latitude'] ?? data['latitude'];

      final dynamic rawLongitude =
          locationData?['longitude'] ?? data['longitude'];

      if (rawLatitude == null || rawLongitude == null) {
        continue;
      }

      final double? latitude =
          double.tryParse(rawLatitude.toString());

      final double? longitude =
          double.tryParse(rawLongitude.toString());

      if (latitude == null ||
          longitude == null ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        continue;
      }

      final double distanceKm =
          Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            latitude,
            longitude,
          ) / 1000;

      // Maximum discovery radius remains 50 km.
      if (distanceKm > 50) {
        continue;
      }

      nearbyCompanies.add({
        ...data,
        'companyId': doc.id,
        'latitude': latitude,
        'longitude': longitude,
        'distanceKm': distanceKm,
      });
    }

    // Sort all matching companies by actual distance.
    nearbyCompanies.sort((a, b) {
      final double distanceA =
          (a['distanceKm'] as num).toDouble();

      final double distanceB =
          (b['distanceKm'] as num).toDouble();

      return distanceA.compareTo(distanceB);
    });

    if (!mounted) return;

    setState(() {
      _companies = nearbyCompanies;
      _currentPage = 0;
      _loading = false;
      _errorMessage = null;
    });
  } catch (e) {
    debugPrint('Error loading companies: $e');

    if (!mounted) return;

    setState(() {
      _companies = [];
      _currentPage = 0;
      _loading = false;
      _errorMessage = 'Unable to load nearby companies.';
    });
  }
}

Future<bool> _hasCompanyAccess(double distanceKm) async {
  // The first 1 km is free.
  if (distanceKm <= 1.0) {
    return true;
  }

  final box = Hive.box('settings');

  // Use the same keys as your Home subscription system.
  final dynamic savedDistance = box.get('activeDistance');

  final dynamic savedExpiry = box.get('subscriptionExpiry');

  final double subscribedDistance =
      savedDistance is num
          ? savedDistance.toDouble()
          : 1.0;

  final DateTime? expiry = savedExpiry == null
      ? null
      : DateTime.tryParse(savedExpiry.toString());

  if (expiry == null) {
    return false;
  }

  final bool subscriptionIsActive =
      DateTime.now().isBefore(expiry);

  if (!subscriptionIsActive) {
    return false;
  }

  // Example: a valid 7 km subscription allows access
  // to companies 1–7 km away.
  return subscribedDistance >= distanceKm;
}

Future<void> _showCompanyAccessDialog(
  double distanceKm,
) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Distance access required',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF12652F),
          ),
        ),
        content: Text(
          'This company is ${distanceKm.toStringAsFixed(1)} km away. '
          'Your current access does not cover this distance. '
          'Open Home to check your subscription options.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16803C),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // Close the pop-up and return to the root screen,
              // which should be Home in your existing app flow.
              Navigator.pop(dialogContext);

              Navigator.of(context).popUntil(
                (route) => route.isFirst,
              );
            },
            child: const Text('Go to Home'),
          ),
        ],
      );
    },
  );
}
  // ==============================================================
  // GET USER LOCATION
  // ==============================================================

  // Future<void> _getUserLocation() async {
  //   try {
  //     final bool serviceEnabled =
  //         await Geolocator.isLocationServiceEnabled();

  //     if (!serviceEnabled) {
  //       return;
  //     }

  //     LocationPermission permission =
  //         await Geolocator.checkPermission();

  //     if (permission ==
  //         LocationPermission.denied) {
  //       permission =
  //           await Geolocator.requestPermission();
  //     }

  //     if (permission ==
  //             LocationPermission.denied ||
  //         permission ==
  //             LocationPermission.deniedForever) {
  //       return;
  //     }

  //     _userPosition =
  //         await Geolocator.getCurrentPosition(
  //       locationSettings:
  //           const LocationSettings(
  //         accuracy: LocationAccuracy.medium,
  //       ),
  //     );
  //   } catch (_) {
  //     // The screen can still load companies even when
  //     // the user's location is unavailable.
  //     _userPosition = null;
  //   }
  // }
  Future<void> _getUserLocation() async {
  try {
    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _userPosition = null;
      return;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _userPosition = null;
      return;
    }

    // First try cached location for faster loading.
    final Position? lastKnown =
        await Geolocator.getLastKnownPosition();

    if (lastKnown != null) {
      _userPosition = lastKnown;
      return;
    }

    // Request current location only when cached location
    // is unavailable.
    _userPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
  } catch (e) {
    debugPrint('User location error: $e');
    _userPosition = null;
  }
}

  // ==============================================================
  // CHECK COMPANY CATEGORY
  // ==============================================================

  bool _companyMatchesCategory(
  Map<String, dynamic> data,
  String selectedCategory,
) {
  final String target =
      selectedCategory.trim().toLowerCase();

  if (target.isEmpty) return false;

  bool matches(dynamic value) {
    if (value == null) return false;

    if (value is String) {
      return value.trim().toLowerCase() == target;
    }

    if (value is List) {
      return value.any(
        (item) =>
            item.toString().trim().toLowerCase() == target,
      );
    }

    return false;
  }

  return matches(data['category']) ||
      matches(data['categories']);
}

  // ==============================================================
  // GET COMPANY NAME
  // ==============================================================

  String _getCompanyName(
    Map<String, dynamic> company,
  ) {
    final String companyName =
        (company['companyName'] ?? '')
            .toString()
            .trim();

    if (companyName.isNotEmpty) {
      return companyName;
    }

    final String name =
        (company['name'] ??
                company['username'] ??
                '')
            .toString()
            .trim();

    if (name.isNotEmpty) {
      return name;
    }

    return 'Company';
  }

  // ==============================================================
  // GET COMPANY CATEGORY
  // ==============================================================

  String _getCompanyCategory(
  Map<String, dynamic> company,
) {
  return widget.selectedCategory;
}

  // ==============================================================
  // GET EXPERIENCE
  // ==============================================================

  String _getExperience(
    Map<String, dynamic> company,
  ) {
    final String experience =
        (company['experience'] ?? '')
            .toString()
            .trim();

    if (experience.isNotEmpty) {
      return experience;
    }

    return 'Experience not specified';
  }

  // ==============================================================
  // GET DISTANCE
  // ==============================================================

  String _getDistanceText(
  Map<String, dynamic> company,
) {
  final dynamic rawDistance = company['distanceKm'];

  if (rawDistance == null || rawDistance is! num) {
    return 'Distance unavailable';
  }

  final double distanceKm = rawDistance.toDouble();

  if (distanceKm < 1) {
    return '${(distanceKm * 1000).round()} m away';
  }

  return '${distanceKm.toStringAsFixed(1)} km away';
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: darkGreen,
        centerTitle: true,
        title: Text(
          widget.selectedCategory,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: darkGreen,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? _buildLoading()
          : _errorMessage != null
              ? _buildError()
              : _buildCompanyContent(),
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
  // ERROR
  // ==============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: Colors.red.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 43,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              _errorMessage ??
                  'Unable to load companies.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: darkGreen,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _loadCompanies,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Retry',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // COMPANY CONTENT
  // ==============================================================

  Widget _buildCompanyContent() {
  if (_companies.isEmpty) {
    return _buildEmptyCompanies();
  }

  final List<Map<String, dynamic>> pageCompanies =
      _currentPageCompanies;

  return RefreshIndicator(
    color: green,
    onRefresh: _loadCompanies,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24,
      ),
      children: [
        // Company cards for the current page.
        ...List.generate(pageCompanies.length, (index) {
          return _buildCompanyCard(
            pageCompanies[index],
            (_currentPage * _companiesPerPage) + index,
          );
        }),

        const SizedBox(height: 12),

        // Pagination controls.
        if (_totalPages > 1)
          _buildPaginationControls(),
      ],
    ),
  );
}

Widget _buildPaginationControls() {
  return Container(
    margin: const EdgeInsets.only(top: 8, bottom: 12),
    padding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 12,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: green.withValues(alpha: 0.15),
      ),
    ),
    child: Row(
      children: [
        // Previous page.
        IconButton(
          tooltip: 'Previous page',
          onPressed: _currentPage > 0
              ? () {
                  setState(() {
                    _currentPage--;
                  });
                }
              : null,
          icon: const Icon(Icons.chevron_left),
          color: green,
        ),

        Expanded(
          child: Text(
            'Page ${_currentPage + 1} of $_totalPages',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: darkGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Next page.
        IconButton(
          tooltip: 'Next page',
          onPressed: _currentPage < _totalPages - 1
              ? () {
                  setState(() {
                    _currentPage++;
                  });
                }
              : null,
          icon: const Icon(Icons.chevron_right),
          color: green,
        ),
      ],
    ),
  );
}
  // ==============================================================
  // EMPTY COMPANIES
  // ==============================================================

  Widget _buildEmptyCompanies() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: green.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.business_outlined,
                color: green,
                size: 45,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No companies found',
              style: TextStyle(
                color: darkGreen,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'There are currently no companies registered under ${widget.selectedCategory}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _loadCompanies,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Refresh',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ==============================================================
  // COMPANY CARD
  // ==============================================================

  Widget _buildCompanyCard(
    Map<String, dynamic> company,
    int index,
  ) {
    final String companyName =
        _getCompanyName(company);

    final String category =
        _getCompanyCategory(company);

    final String experience =
        _getExperience(company);

    final String distance =
        _getDistanceText(company);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 13,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _openCompany(
              company,
            );
          },
          borderRadius:
              BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color: green.withValues(
                  alpha: 0.12,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.04,
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
                // COMPANY ICON
                // --------------------------------------------------

                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: green.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: green,
                    size: 32,
                  ),
                ),

                const SizedBox(width: 14),

                // --------------------------------------------------
                // COMPANY INFORMATION
                // --------------------------------------------------

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        companyName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkGreen,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        category,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Row(
                        children: [

                          const Icon(
                            Icons.work_outline,
                            size: 16,
                            color: orange,
                          ),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              experience,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: darkGreen,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // --------------------------------------------------
                // DISTANCE
                // --------------------------------------------------

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [

                    const Icon(
                      Icons.location_on,
                      color: orange,
                      size: 22,
                    ),

                    const SizedBox(height: 3),

                    Text(
                      distance,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: darkGreen,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Icon(
                      Icons.arrow_forward_ios,
                      color: green,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // OPEN COMPANY
  // ==============================================================

  Future<void> _openCompany(
  Map<String, dynamic> company,
) async {
  final double distanceKm =
      (company['distanceKm'] as num?)?.toDouble() ?? 999999;

  // Check free access and the existing active subscription.
  final bool allowed =
      await _hasCompanyAccess(distanceKm);

  if (!mounted) return;

  if (!allowed) {
    await _showCompanyAccessDialog(distanceKm);
    return;
  }

  // Continue to the existing company profile.
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CompanyProfileScreen(
        companyId: company['companyId']?.toString() ?? '',
        companyName:
            company['companyName']?.toString() ??
            company['name']?.toString() ??
            '',
        phoneNumber: '',
        categories: company['categories'] is List
            ? List<String>.from(company['categories'])
            : <String>[
                company['category']?.toString() ?? '',
              ],
        experience: company['experience']?.toString() ?? '',
        latitude:
            (company['latitude'] as num?)?.toDouble(),
        longitude:
            (company['longitude'] as num?)?.toDouble(),
        distanceKm: distanceKm,
      ),
    ),
  );
}
    }

  // ==============================================================
  // GET CATEGORY LIST
  // ==============================================================

  // List<String> _getCompanyCategoriesList(
  //   Map<String, dynamic> company,
  // ) {
  //   final dynamic categories =
  //       company['category'] ??
  //           company['categories'];

  //   if (categories is List) {
  //     return categories
  //         .map(
  //           (item) => item.toString().trim(),
  //         )
  //         .where(
  //           (item) => item.isNotEmpty,
  //         )
  //         .toList();
  //   }

  //   if (categories != null &&
  //       categories.toString().trim().isNotEmpty) {
  //     return [
  //       categories.toString().trim(),
  //     ];
  //   }

  //   return [
  //     widget.selectedCategory,
  //   ];
  // }

  // // ==============================================================
  // // KM RADIUS DIALOG
  // // ==============================================================

  // Future<bool?> _showRadiusDialog(
  //   double distanceKm,
  // ) {
  //   return showDialog<bool>(
  //     context: context,
  //     builder: (
  //       context,
  //     ) {
  //       return AlertDialog(
  //         shape:
  //             RoundedRectangleBorder(
  //           borderRadius:
  //               BorderRadius.circular(22),
  //         ),

  //         title: const Row(
  //           children: [
  //             Icon(
  //               Icons.location_on,
  //               color: orange,
  //             ),

  //             SizedBox(width: 9),

  //             Expanded(
  //               child: Text(
  //                 'Outside Your Area',
  //                 style: TextStyle(
  //                   fontSize: 18,
  //                   color: darkGreen,
  //                   fontWeight:
  //                       FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),

  //         content: Text(
  //           'This company is ${distanceKm.toStringAsFixed(1)} km away. '
  //           'Your current free search radius is 5 km. '
  //           'Please extend your KM radius to view this company.',
  //           style: const TextStyle(
  //             fontSize: 14,
  //           ),
  //         ),

  //         actions: [

  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(
  //                 context,
  //                 false,
  //               );
  //             },
  //             child: const Text(
  //               'Cancel',
  //             ),
  //           ),

  //           ElevatedButton(
  //             onPressed: () {
  //               // --------------------------------------------------
  //               // PAYMENT / KM EXTENSION
  //               //
  //               // Connect your existing payment system here later.
  //               // --------------------------------------------------

  //               Navigator.pop(
  //                 context,
  //                 true,
  //               );
  //             },

  //             style:
  //                 ElevatedButton.styleFrom(
  //               backgroundColor: green,
  //               foregroundColor:
  //                   Colors.white,
  //             ),

  //             child: const Text(
  //               'Extend KM',
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }


  // Future<void> _loadCompanies() async {
  //   if (!mounted) return;

  //   setState(() {
  //     _loading = true;
  //     _errorMessage = null;
  //   });

  //   try {
  //     // ------------------------------------------------------------
  //     // GET USER LOCATION
  //     // ------------------------------------------------------------

  //     await _getUserLocation();

  //     // ------------------------------------------------------------
  //     // LOAD COMPANIES FROM FIRESTORE
  //     // ------------------------------------------------------------

  //     final QuerySnapshot<Map<String, dynamic>>
  //         snapshot = await _firestore
  //             .collection('companies')
  //             .get();

  //     final List<Map<String, dynamic>>
  //         loadedCompanies = [];

  //     for (final document in snapshot.docs) {
  //       final Map<String, dynamic> data =
  //           document.data();

  //       // ----------------------------------------------------------
  //       // CHECK CATEGORY
  //       // ----------------------------------------------------------

  //       if (!_companyMatchesCategory(
  //         data,
  //         widget.selectedCategory,
  //       )) {
  //         continue;
  //       }

  //       // ----------------------------------------------------------
  //       // CREATE COMPANY DATA
  //       // ----------------------------------------------------------

  //       final Map<String, dynamic> company =
  //           Map<String, dynamic>.from(data);

  //       company['companyId'] =
  //           document.id;

  //       // ----------------------------------------------------------
  //       // READ COMPANY LOCATION
  //       // ----------------------------------------------------------

  //       final double? latitude =
  //           _readLatitude(company);

  //       final double? longitude =
  //           _readLongitude(company);

  //       // ----------------------------------------------------------
  //       // CALCULATE DISTANCE
  //       // ----------------------------------------------------------

  //       double? distanceKm;

  //       if (_userPosition != null &&
  //           latitude != null &&
  //           longitude != null) {
  //         final double distanceMeters =
  //             Geolocator.distanceBetween(
  //           _userPosition!.latitude,
  //           _userPosition!.longitude,
  //           latitude,
  //           longitude,
  //         );

  //         distanceKm =
  //             distanceMeters / 1000;
  //       }

  //       company['distanceKm'] =
  //           distanceKm;

  //       loadedCompanies.add(company);
  //     }

  //     // ------------------------------------------------------------
  //     // SORT NEAREST TO FARTHEST
  //     // ------------------------------------------------------------

  //     loadedCompanies.sort(
  //       (a, b) {
  //         final double? distanceA =
  //             a['distanceKm'];

  //         final double? distanceB =
  //             b['distanceKm'];

  //         // Companies without a location go to the bottom.
  //         if (distanceA == null &&
  //             distanceB == null) {
  //           return 0;
  //         }

  //         if (distanceA == null) {
  //           return 1;
  //         }

  //         if (distanceB == null) {
  //           return -1;
  //         }

  //         return distanceA.compareTo(
  //           distanceB,
  //         );
  //       },
  //     );

  //     if (!mounted) return;

  //     setState(() {
  //       _companies = loadedCompanies;
  //       _loading = false;
  //     });
  //   } catch (e) {
  //     if (!mounted) return;

  //     setState(() {
  //       _loading = false;
  //       _errorMessage =
  //           'Unable to load companies. Please try again.';
  //     });
  //   }
  // }
    // ==============================================================
  // READ LATITUDE
  // ==============================================================

  // double? _readLatitude(
  //   Map<String, dynamic> data,
  // ) {
  //   dynamic location =
  //       data['currentLocation'];

  //   if (location is Map) {
  //     final value = location['latitude'];

  //     final result = _toDouble(value);

  //     if (result != null) {
  //       return result;
  //     }
  //   }

  //   location = data['location'];

  //   if (location is Map) {
  //     final value = location['latitude'];

  //     final result = _toDouble(value);

  //     if (result != null) {
  //       return result;
  //     }
  //   }

  //   return _toDouble(
  //     data['latitude'],
  //   );
  // }

  // // ==============================================================
  // // READ LONGITUDE
  // // ==============================================================

  // double? _readLongitude(
  //   Map<String, dynamic> data,
  // ) {
  //   dynamic location =
  //       data['currentLocation'];

  //   if (location is Map) {
  //     final value = location['longitude'];

  //     final result = _toDouble(value);

  //     if (result != null) {
  //       return result;
  //     }
  //   }

  //   location = data['location'];

  //   if (location is Map) {
  //     final value = location['longitude'];

  //     final result = _toDouble(value);

  //     if (result != null) {
  //       return result;
  //     }
  //   }

  //   return _toDouble(
  //     data['longitude'],
  //   );
  // }

  // ==============================================================
  // CONVERT TO DOUBLE
  // ==============================================================

  // double? _toDouble(
  //   dynamic value,
  // ) {
  //   if (value == null) {
  //     return null;
  //   }

  //   if (value is num) {
  //     return value.toDouble();
  //   }

  //   return double.tryParse(
  //     value.toString(),
  //   );
  // }


  // String _getDistanceText(
  //   Map<String, dynamic> company,
  // ) {
  //   final dynamic value =
  //       company['distanceKm'];

  //   if (value == null) {
  //     return 'Distance unavailable';
  //   }

  //   final double? distance =
  //       _toDouble(value);

  //   if (distance == null) {
  //     return 'Distance unavailable';
  //   }

  //   if (distance < 1) {
  //     return '${(distance * 1000).round()} m away';
  //   }

  //   return '${distance.toStringAsFixed(1)} km away';
  // }


  // Future<void> _openCompany(
  //   Map<String, dynamic> company,
  // ) async {
  //   final double? distanceKm =
  //       _toDouble(
  //     company['distanceKm'],
  //   );

  //   // ------------------------------------------------------------
  //   // CHECK KM RADIUS
  //   // ------------------------------------------------------------

  //   if (distanceKm != null) {
  //     const double freeRadiusKm = 5.0;

  //     if (distanceKm > freeRadiusKm) {
  //       final bool? allowed =
  //           await _showRadiusDialog(
  //         distanceKm,
  //       );

  //       if (allowed != true) {
  //         return;
  //       }
  //     }
  //   }

  //   if (!mounted) return;

  //   // ============================================================
  //   // COMPANY PROFILE SCREEN
  //   // ============================================================

  //   // This screen will be created next.
  //   //
  //   // It will contain:
  //   //
  //   // • Company Name
  //   // • Category
  //   // • Experience
  //   // • Call Button
  //   // • Chat Button
  //   // • Location Button
  //   //
  //   // Mobile number will NOT be displayed.
  //   // ============================================================

  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => CompanyProfileScreen(
  //         companyId:
  //             company['companyId']
  //                 .toString(),

  //         companyName:
  //             _getCompanyName(company),

  //         phoneNumber:
  //             (company['phoneNumber'] ??
  //                     company['mobileNumber'] ??
  //                     '')
  //                 .toString(),

  //         categories:
  //             _getCompanyCategoriesList(
  //           company,
  //         ),

  //         experience:
  //             _getExperience(company),

  //         latitude:
  //             _readLatitude(company),

  //         longitude:
  //             _readLongitude(company),

  //         distanceKm:
  //             distanceKm,
  //       ),
  //     ),
  //   );
  // }