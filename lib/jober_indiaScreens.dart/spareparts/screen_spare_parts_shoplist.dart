import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:jober_india/jober_indiaScreens.dart/spareparts/screen_spare_parts_profile.dart';

class ScreenAutoSparePartsShopList extends StatefulWidget {
  final String selectedCategory;

  const ScreenAutoSparePartsShopList({
    super.key,
    required this.selectedCategory,
  });

  @override
  State<ScreenAutoSparePartsShopList> createState() =>
      _ScreenAutoSparePartsShopListState();
}

class _ScreenAutoSparePartsShopListState
    extends State<ScreenAutoSparePartsShopList> {

  // ============================================================
  // FIRESTORE
  // ============================================================

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // SCROLL
  // ============================================================

  final ScrollController scrollController =
      ScrollController();

  // ============================================================
  // LOCATION
  // ============================================================

  Position? currentPosition;

  bool isLoadingLocation = true;
  bool locationPermissionDenied = false;

  // ============================================================
  // SHOP DATA
  // ============================================================

  final List<Map<String, dynamic>> shops = [];

  static const int pageSize = 20;
  static const double maximumSearchRadius = 50.0;

  int visibleCount = pageSize;

  bool isLoadingShops = false;
  bool isLoadingMore = false;
  bool isFetchingAllShops = false;

  String? errorMessage;

  DocumentSnapshot<Map<String, dynamic>>? lastDocument;

  bool hasMore = true;

  // ============================================================
  // SUBSCRIPTION
  // ============================================================

  double paidRadius = 1.0;

  DateTime? subscriptionExpiry;

  bool subscriptionIsActive = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    scrollController.addListener(_scrollListener);

    _initializePage();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // INITIALIZE PAGE
  // ============================================================

  Future<void> _initializePage() async {
    await _loadPaidRadius();

    if (!mounted) return;

    final locationReady = await _getCurrentLocation();

    if (!locationReady || !mounted) return;

    await _loadShops(reset: true);
  }

  // ============================================================
  // LOAD SUBSCRIPTION
  // ============================================================

  Future<void> _loadPaidRadius() async {
    try {
      if (!Hive.isBoxOpen('settings')) {
        await Hive.openBox('settings');
      }

      final box = Hive.box('settings');

      final savedDistance = box.get('activeDistance');
      final savedExpiry = box.get('subscriptionExpiry');

      DateTime? expiry;

      if (savedExpiry is DateTime) {
        expiry = savedExpiry;
      } else if (savedExpiry != null) {
        expiry = DateTime.tryParse(
          savedExpiry.toString(),
        );
      }

      final validSubscription =
          expiry != null &&
          DateTime.now().isBefore(expiry);

      if (validSubscription && savedDistance is num) {
        paidRadius = savedDistance.toDouble();

        subscriptionExpiry = expiry;

        subscriptionIsActive = true;
      } else {
        paidRadius = 1.0;

        subscriptionExpiry = null;

        subscriptionIsActive = false;

        if (expiry != null &&
            !DateTime.now().isBefore(expiry)) {
          await box.delete('activeDistance');
          await box.delete('subscriptionStart');
          await box.delete('subscriptionExpiry');
          await box.delete('subscriptionDuration');
          await box.delete('subscriptionPaidAmount');
          await box.delete('subscriptionActive');
        }
      }
    } catch (e) {
      debugPrint('Spare parts subscription error: $e');

      paidRadius = 1.0;
      subscriptionExpiry = null;
      subscriptionIsActive = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<bool> _getCurrentLocation() async {
    if (mounted) {
      setState(() {
        isLoadingLocation = true;
        locationPermissionDenied = false;
        errorMessage = null;
      });
    }

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return false;

        setState(() {
          isLoadingLocation = false;
          errorMessage =
              'Please turn ON your location service.';
        });

        await Geolocator.openLocationSettings();

        return false;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return false;

        setState(() {
          isLoadingLocation = false;
          locationPermissionDenied = true;

          errorMessage =
              'Location permission is required to find nearby spare parts shops.';
        });

        return false;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return false;

      setState(() {
        currentPosition = position;
        isLoadingLocation = false;
      });

      return true;
    } catch (e) {
      debugPrint('Spare parts location error: $e');

      if (!mounted) return false;

      setState(() {
        isLoadingLocation = false;
        errorMessage =
            'Unable to get your current location.';
      });

      return false;
    }
  }

  // ============================================================
  // LOAD SHOPS
  // ============================================================

  Future<void> _loadShops({
    required bool reset,
  }) async {
    if (currentPosition == null ||
        isFetchingAllShops) {
      return;
    }

    if (!reset) return;

    isFetchingAllShops = true;

    if (mounted) {
      setState(() {
        isLoadingShops = true;
        isLoadingMore = false;
        errorMessage = null;

        shops.clear();

        visibleCount = pageSize;

        lastDocument = null;

        hasMore = true;
      });
    }

    try {
      final List<Map<String, dynamic>> allResults = [];

      final selectedCategory =
          widget.selectedCategory.trim().toLowerCase();

      // --------------------------------------------------------
      // FETCH ALL ACTIVE SHOPS IN BATCHES OF 20
      // --------------------------------------------------------

      while (hasMore) {
        Query<Map<String, dynamic>> query = firestore
            .collection('auto_spare_parts_shops')
            // IMPORTANT:
            // Your registration saves 'active': true.
            .where('active', isEqualTo: true)
            .limit(pageSize);

        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument!);
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) {
          hasMore = false;
          break;
        }

        lastDocument = snapshot.docs.last;

        if (snapshot.docs.length < pageSize) {
          hasMore = false;
        }

        // ------------------------------------------------------
        // PROCESS EACH SHOP
        // ------------------------------------------------------

        for (final document in snapshot.docs) {
          final data = document.data();

          // ----------------------------------------------------
          // CATEGORY FILTER
          // ----------------------------------------------------

          final Set<String> shopCategories = {};

          void addCategories(dynamic rawCategories) {
            if (rawCategories is List) {
              for (final item in rawCategories) {
                final category = item.toString().trim();

                if (category.isNotEmpty) {
                  shopCategories.add(
                    category.toLowerCase(),
                  );
                }
              }
            } else if (rawCategories is String) {
              for (final item in rawCategories.split(',')) {
                final category = item.trim();

                if (category.isNotEmpty) {
                  shopCategories.add(
                    category.toLowerCase(),
                  );
                }
              }
            }
          }

          addCategories(data['categories']);
          addCategories(data['customCategories']);
          addCategories(data['category']);

          // ALL AUTO SPARE PARTS SHOWS EVERY ACTIVE SHOP.

          if (selectedCategory != 'all auto spare parts' &&
              !shopCategories.contains(selectedCategory)) {
            continue;
          }

          // ----------------------------------------------------
          // READ SHOP LOCATION
          // ----------------------------------------------------

          double? latitude;
          double? longitude;

          // 1. GEO FIRESTORE STRUCTURE

          final geoData = data['geo'];

          if (geoData is Map &&
              geoData['geopoint'] is GeoPoint) {
            final point = geoData['geopoint'] as GeoPoint;

            latitude = point.latitude;
            longitude = point.longitude;
          }

          // 2. LOCATION GEOPOINT

          if (latitude == null || longitude == null) {
            final locationData = data['location'];

            if (locationData is GeoPoint) {
              latitude = locationData.latitude;
              longitude = locationData.longitude;
            }
          }

          // 3. DIRECT LATITUDE AND LONGITUDE

          latitude ??= _readDouble(data['latitude']);

          longitude ??= _readDouble(data['longitude']);

          // 4. CURRENT LOCATION MAP

          if (latitude == null || longitude == null) {
            final currentLocation = data['currentLocation'];

            if (currentLocation is GeoPoint) {
              latitude = currentLocation.latitude;
              longitude = currentLocation.longitude;
            } else if (currentLocation is Map) {
              latitude ??= _readDouble(
                currentLocation['latitude'] ??
                    currentLocation['lat'],
              );

              longitude ??= _readDouble(
                currentLocation['longitude'] ??
                    currentLocation['lng'],
              );
            }
          }

          // ----------------------------------------------------
          // VALIDATE LOCATION
          // ----------------------------------------------------

          if (latitude == null || longitude == null) {
            debugPrint(
              'Spare parts shop skipped: ${document.id} - '
              'Location missing',
            );

            continue;
          }

          if (latitude < -90 ||
              latitude > 90 ||
              longitude < -180 ||
              longitude > 180) {
            continue;
          }

          // ----------------------------------------------------
          // CALCULATE ACTUAL DISTANCE FROM USER
          // ----------------------------------------------------

          final distanceInMeters =
              Geolocator.distanceBetween(
            currentPosition!.latitude,
            currentPosition!.longitude,
            latitude,
            longitude,
          );

          final distanceInKm =
              distanceInMeters / 1000.0;

          // ----------------------------------------------------
          // MAXIMUM SEARCH RADIUS: 50 KM
          // ----------------------------------------------------

          if (distanceInKm > maximumSearchRadius) {
            continue;
          }

          // ----------------------------------------------------
          // ADD SHOP
          // ----------------------------------------------------

          final shop =
              Map<String, dynamic>.from(data);

          shop['uid'] =
              data['uid']?.toString() ?? document.id;

          shop['documentId'] = document.id;

          shop['latitude'] = latitude;

          shop['longitude'] = longitude;

          shop['distanceKm'] = distanceInKm;

          allResults.add(shop);
        }
      }

      // --------------------------------------------------------
      // SORT COMPLETE RESULTS: NEAREST FIRST
      // --------------------------------------------------------

      allResults.sort((a, b) {
        final distanceA =
            _readDouble(a['distanceKm']) ?? double.infinity;

        final distanceB =
            _readDouble(b['distanceKm']) ?? double.infinity;

        return distanceA.compareTo(distanceB);
      });

      if (!mounted) return;

      setState(() {
        shops
          ..clear()
          ..addAll(allResults);

        // Initially display only 20 shops.

        visibleCount = shops.length < pageSize
            ? shops.length
            : pageSize;

        isLoadingShops = false;
        isLoadingMore = false;
        errorMessage = null;
      });

      debugPrint(
        'SPARE PARTS SHOPS FOUND WITHIN 50 KM: ${shops.length}',
      );
    } catch (e, stackTrace) {
      debugPrint('Spare parts loading error: $e');
      debugPrint('$stackTrace');

      if (mounted) {
        setState(() {
          isLoadingShops = false;
          isLoadingMore = false;

          errorMessage =
              'Unable to load nearby spare parts shops.';
        });
      }
    } finally {
      isFetchingAllShops = false;
    }
  }

  // ============================================================
  // CONVERT VALUE TO DOUBLE
  // ============================================================

  double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  // ============================================================
  // SCROLL LISTENER
  // ============================================================

  void _scrollListener() {
    if (!scrollController.hasClients ||
        isLoadingMore ||
        isLoadingShops) {
      return;
    }

    final position = scrollController.position;

    if (position.pixels >=
            position.maxScrollExtent - 300 &&
        visibleCount < shops.length) {
      setState(() {
        isLoadingMore = true;

        visibleCount =
            (visibleCount + pageSize > shops.length)
                ? shops.length
                : visibleCount + pageSize;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            isLoadingMore = false;
          });
        }
      });
    }
  }

  // ============================================================
  // DISPLAYED SHOP COUNT
  // ============================================================

  int get displayedShopCount {
    return visibleCount < shops.length
        ? visibleCount
        : shops.length;
  }

  // ============================================================
  // FORMAT DISTANCE
  // ============================================================

  String _formatDistance(double distance) {
    if (distance < 1) {
      final meters = (distance * 1000).round();

      return '$meters m away';
    }

    return '${distance.toStringAsFixed(1)} km away';
  }

  // ============================================================
  // SHOP NAME
  // ============================================================

  String _shopName(Map<String, dynamic> shop) {
    final shopName =
        shop['shopName']?.toString().trim();

    if (shopName != null && shopName.isNotEmpty) {
      return shopName;
    }

    return 'Auto Spare Parts Shop';
  }

  // ============================================================
  // SHOP CATEGORIES
  // ============================================================

  String _shopCategories(
    Map<String, dynamic> shop,
  ) {
    final categories = shop['categories'];

    if (categories is List) {
      final values = categories
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();

      if (values.isNotEmpty) {
        return values.join(', ');
      }
    }

    final customCategories = shop['customCategories'];

    if (customCategories is List &&
        customCategories.isNotEmpty) {
      return customCategories
          .map((e) => e.toString())
          .join(', ');
    }

    final category = shop['category']?.toString().trim();

    if (category != null && category.isNotEmpty) {
      return category;
    }

    return widget.selectedCategory;
  }

  // ============================================================
  // SHOP PLACE
  // ============================================================

  String _shopPlace(Map<String, dynamic> shop) {
    final currentLocation = shop['currentLocation'];

    if (currentLocation is Map) {
      final placeName =
          currentLocation['placeName']?.toString().trim();

      if (placeName != null && placeName.isNotEmpty) {
        return placeName;
      }
    }

    final nearestTown =
        shop['nearestTown']?.toString().trim();

    final district =
        shop['district']?.toString().trim();

    final state =
        shop['state']?.toString().trim();

    if (nearestTown != null && nearestTown.isNotEmpty) {
      return nearestTown;
    }

    if (district != null &&
        district.isNotEmpty &&
        state != null &&
        state.isNotEmpty) {
      return '$district, $state';
    }

    if (district != null && district.isNotEmpty) {
      return district;
    }

    if (state != null && state.isNotEmpty) {
      return state;
    }

    return '';
  }

  // ============================================================
  // SHOP TIMING
  // ============================================================

  String _timingText(Map<String, dynamic> shop) {
    final isOpen24Hours =
        shop['isOpen24Hours'] == true;

    if (isOpen24Hours) {
      return 'Open 24 Hours';
    }

    final openingTime =
        shop['openingTime']?.toString().trim() ?? '';

    final closingTime =
        shop['closingTime']?.toString().trim() ?? '';

    if (openingTime.isNotEmpty &&
        closingTime.isNotEmpty) {
      return '$openingTime - $closingTime';
    }

    return 'Timing not available';
  }

  // ============================================================
  // SHOP IMAGE
  // ============================================================

  Widget _shopImage(Map<String, dynamic> shop) {
    final imageUrl =
        (shop['profilePhotoUrl'] ??
                shop['imageUrl'] ??
                shop['shopImageUrl'])
            ?.toString()
            .trim();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          imageUrl,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return _defaultShopImage();
          },
        ),
      );
    }

    return _defaultShopImage();
  }

  Widget _defaultShopImage() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8EF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.storefront_outlined,
        color: Color(0xFF16803C),
        size: 38,
      ),
    );
  }

  // ============================================================
  // CHECK PROFILE ACCESS
  // ============================================================

  bool _isInsidePaidRadius(
    Map<String, dynamic> shop,
  ) {
    final distance =
        _readDouble(shop['distanceKm']);

    if (distance == null) {
      return false;
    }

    // FIRST 1 KM IS FREE.

    if (distance <= 1.0) {
      return true;
    }

    // SUBSCRIPTION MUST BE ACTIVE.

    if (!subscriptionIsActive ||
        subscriptionExpiry == null ||
        !DateTime.now().isBefore(subscriptionExpiry!)) {
      return false;
    }

    return distance <= paidRadius;
  }

  // ============================================================
  // OPEN SHOP
  // ============================================================

  Future<void> _openShop(
    Map<String, dynamic> shop,
  ) async {
    final distance =
        _readDouble(shop['distanceKm']);

    if (distance == null) return;

    // Always check latest subscription.

    await _loadPaidRadius();

    if (!mounted) return;

    if (_isInsidePaidRadius(shop)) {
      _goToProfile(shop);
      return;
    }

    _showPaymentRequiredDialog(distance);
  }

  // ============================================================
  // GO TO SHOP PROFILE
  // ============================================================

  void _goToProfile(
    Map<String, dynamic> shop,
  ) {
    final position = currentPosition;

    if (position == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenAutoSparePartsShopProfile(
          shop: shop,
          userLatitude: position.latitude,
          userLongitude: position.longitude,
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT REQUIRED DIALOG
  // ============================================================

  void _showPaymentRequiredDialog(double distance) {
    final requiredRadius = distance.ceil();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Profile Access',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF202124),
            ),
          ),
          content: Text(
            'This spare parts shop is '
            '${distance.toStringAsFixed(1)} km away.\n\n'
            'Your current access radius is '
            '${subscriptionIsActive ? paidRadius.toStringAsFixed(0) : '1'} km.\n\n'
            'Unlock a larger distance to open this shop profile.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                _showRadiusInformation(requiredRadius);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF159B16),
                foregroundColor: Colors.white,
              ),
              child: const Text('VIEW OPTIONS'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DISTANCE INFORMATION
  // ============================================================

  void _showRadiusInformation(int requiredRadius) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Distance Access'),
          content: Text(
            'This spare parts shop is approximately '
            '$requiredRadius km away.\n\n'
            'Use your existing distance-unlock/payment flow '
            'to unlock a larger search radius.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _loadPaidRadius();

    if (!mounted) return;

    final locationReady = await _getCurrentLocation();

    if (!locationReady || !mounted) return;

    await _loadShops(reset: true);
  }

  // ============================================================
  // SHOP CARD
  // ============================================================

  Widget _shopCard(Map<String, dynamic> shop) {
    final name = _shopName(shop);

    final category = _shopCategories(shop);

    final place = _shopPlace(shop);

    final distance =
        _readDouble(shop['distanceKm']) ?? 0.0;

    final timing = _timingText(shop);

    final isOpen24Hours =
        shop['isOpen24Hours'] == true;

    final canOpen = _isInsidePaidRadius(shop);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _openShop(shop);
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE1E1E1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SHOP IMAGE

              _shopImage(shop),

              const SizedBox(width: 13),

              // SHOP INFORMATION

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF202124),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      category,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF16803C),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 7),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFFE87516),
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 7),

                    // ACTUAL DISTANCE FROM USER

                    Row(
                      children: [
                        const Icon(
                          Icons.near_me_outlined,
                          color: Color(0xFFE87516),
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatDistance(distance),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    // OPENING TIME

                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: isOpen24Hours
                              ? const Color(0xFF16803C)
                              : Colors.grey,
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            timing,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isOpen24Hours
                                  ? const Color(0xFF16803C)
                                  : Colors.grey,
                              fontSize: 12,
                              fontWeight: isOpen24Hours
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              // ACCESS STATUS

              Column(
                children: [
                  Icon(
                    canOpen
                        ? Icons.arrow_forward_ios
                        : Icons.lock_outline,
                    color: canOpen
                        ? const Color(0xFF16803C)
                        : Colors.grey,
                    size: 18,
                  ),

                  const SizedBox(height: 8),

                  if (!canOpen)
                    const Text(
                      'Locked',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP SECTION
  // ============================================================

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Category',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            widget.selectedCategory,
            style: const TextStyle(
              color: Color(0xFF202124),
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Auto spare parts shops within 50 km '
            'from your current location',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF16803C),
                  size: 21,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    '${shops.length} '
                    'shop${shops.length == 1 ? '' : 's'} found',
                    style: const TextStyle(
                      color: Color(0xFF16803C),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Icon(
                  Icons.sort,
                  color: Color(0xFF16803C),
                  size: 20,
                ),

                const SizedBox(width: 4),

                const Text(
                  'Nearest first',
                  style: TextStyle(
                    color: Color(0xFF16803C),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF8EF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: Color(0xFF16803C),
                size: 42,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No nearby spare parts shops',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF202124),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              widget.selectedCategory.toLowerCase() ==
                      'all auto spare parts'
                  ? 'No spare parts shops were found within 50 km.'
                  : 'No ${widget.selectedCategory} shops '
                      'were found within 50 km.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('SEARCH AGAIN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF159B16),
                foregroundColor: Colors.white,
                minimumSize: const Size(170, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION ERROR
  // ============================================================

  Widget _buildLocationError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.location_off_outlined,
                color: Color(0xFFE87516),
                size: 42,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Location Required',
              style: TextStyle(
                color: Color(0xFF202124),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              errorMessage ??
                  'Turn on location to find nearby spare parts shops.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.location_on),
              label: const Text('ENABLE LOCATION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF159B16),
                foregroundColor: Colors.white,
                minimumSize: const Size(190, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD BODY
  // ============================================================

  Widget _buildBody() {
    if (isLoadingLocation) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF159B16),
        ),
      );
    }

    if (locationPermissionDenied ||
        errorMessage != null) {
      return _buildLocationError();
    }

    return RefreshIndicator(
      color: const Color(0xFF159B16),
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _buildTopSection(),
          ),

          if (isLoadingShops)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF159B16),
                ),
              ),
            )
          else if (shops.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                18,
                0,
                18,
                25,
              ),
              sliver: SliverList.builder(
                itemCount: displayedShopCount +
                    (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= displayedShopCount) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF159B16),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: _shopCard(shops[index]),
                  );
                },
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
                text: 'Nearby ',
                style: TextStyle(
                  color: Color(0xFF08744F),
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'Spare Parts',
                style: TextStyle(
                  color: Color(0xFFE87516),
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        actions: [
          IconButton(
            onPressed: isLoadingShops || isLoadingLocation
                ? null
                : _refresh,
            icon: const Icon(
              Icons.refresh,
              color: Colors.black,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: _buildBody(),
    );
  }
}
