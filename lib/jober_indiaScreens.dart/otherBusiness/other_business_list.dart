
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:jober_india/jober_indiaScreens.dart/otherBusiness/categories.dart';
import 'package:jober_india/jober_indiaScreens.dart/otherBusiness/other_business_profile.dart';

class ScreenOtherBusinessList extends StatefulWidget {
  final String category;
  final String categoryKey;

  const ScreenOtherBusinessList({
    super.key,
    required this.category,
    required this.categoryKey,
  });

  @override
  State<ScreenOtherBusinessList> createState() =>
      _ScreenOtherBusinessListState();
}

class _ScreenOtherBusinessListState
    extends State<ScreenOtherBusinessList> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final ScrollController scrollController =
      ScrollController();

  final List<Map<String, dynamic>> businesses = [];

  static const int pageSize = 20;
  static const double maximumSearchRadius = 50.0;

  Position? currentPosition;

  DocumentSnapshot<Map<String, dynamic>>? lastDocument;

  int visibleCount = pageSize;

  bool isLoadingLocation = true;
  bool isLoadingBusinesses = false;
  bool isLoadingMore = false;
  bool isFetchingAllBusinesses = false;
  bool hasMore = true;
  bool locationPermissionDenied = false;

  String? errorMessage;

  double paidRadius = 1.0;
  DateTime? subscriptionExpiry;
  bool subscriptionIsActive = false;

  @override
  void initState() {
    super.initState();

    scrollController.addListener(_scrollListener);

    _initializePage();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializePage() async {
    await _loadPaidRadius();

    final locationReady = await _getCurrentLocation();

    if (!locationReady || !mounted) return;

    await _loadBusinesses(reset: true);
  }

  // ============================================================
  // SUBSCRIPTION
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
        expiry = DateTime.tryParse(savedExpiry.toString());
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
      debugPrint('Other Business subscription error: $e');

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

        return false;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return false;

        setState(() {
          isLoadingLocation = false;
          locationPermissionDenied = true;
          errorMessage =
              'Location permission is required to find nearby businesses.';
        });

        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return false;

      setState(() {
        currentPosition = position;
        isLoadingLocation = false;
      });

      return true;
    } catch (e) {
      debugPrint('Other Business location error: $e');

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
  // NUMBER CONVERSION
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
  // LOAD ALL MATCHING BUSINESSES
  // ============================================================

  Future<void> _loadBusinesses({
    required bool reset,
  }) async {
    if (currentPosition == null ||
        isFetchingAllBusinesses) {
      return;
    }

    if (!reset) return;

    isFetchingAllBusinesses = true;

    if (mounted) {
      setState(() {
        isLoadingBusinesses = true;
        isLoadingMore = false;
        errorMessage = null;

        businesses.clear();

        visibleCount = pageSize;
        lastDocument = null;
        hasMore = true;
      });
    }

    try {
      final List<Map<String, dynamic>> allResults = [];

      while (hasMore) {
        Query<Map<String, dynamic>> query =
            firestore
                .collection('otherBusinesses')
                .where('isActive', isEqualTo: true)
                .orderBy('name')
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

        for (final document in snapshot.docs) {
          final data = document.data();

          // ================================================
          // CATEGORY MATCHING
          // ================================================

          final String selectedKey =
              widget.categoryKey.trim().toLowerCase();

          bool categoryMatches = false;

          final dynamic savedKeys = data['categoryKeys'];

          if (savedKeys is List) {
            categoryMatches = savedKeys.any(
              (value) =>
                  value.toString().trim().toLowerCase() ==
                  selectedKey,
            );
          }

          // Fallback for older documents without categoryKeys.
          if (!categoryMatches) {
            final dynamic savedCategories = data['categories'];

            if (savedCategories is List) {
              categoryMatches = savedCategories.any(
                (value) =>
                    categoryKey(value.toString())
                        .trim()
                        .toLowerCase() ==
                    selectedKey,
              );
            }
          }

          // Older single-category fallback.
          if (!categoryMatches) {
            final oldCategory =
                data['category']?.toString().trim() ?? '';

            if (oldCategory.isNotEmpty) {
              categoryMatches =
                  categoryKey(oldCategory).toLowerCase() ==
                  selectedKey;
            }
          }

          if (!categoryMatches) continue;

          // ================================================
          // READ LOCATION FROM REGISTRATION MAP
          // ================================================

          double? latitude;
          double? longitude;

          final dynamic savedLocation = data['location'];

          if (savedLocation is GeoPoint) {
            latitude = savedLocation.latitude;
            longitude = savedLocation.longitude;
          } else if (savedLocation is Map) {
            latitude = _readDouble(
              savedLocation['latitude'] ??
                  savedLocation['lat'],
            );

            longitude = _readDouble(
              savedLocation['longitude'] ??
                  savedLocation['lng'],
            );
          }

          // Coordinate fallback if present.
          latitude ??= _readDouble(data['latitude']);
          longitude ??= _readDouble(data['longitude']);

          if (latitude == null || longitude == null) {
            continue;
          }

          if (latitude < -90 ||
              latitude > 90 ||
              longitude < -180 ||
              longitude > 180) {
            continue;
          }

          // ================================================
          // DISTANCE
          // ================================================

          final distanceInMeters =
              Geolocator.distanceBetween(
            currentPosition!.latitude,
            currentPosition!.longitude,
            latitude,
            longitude,
          );

          final distanceInKm = distanceInMeters / 1000;

          if (distanceInKm > maximumSearchRadius) {
            continue;
          }

          final business =
              Map<String, dynamic>.from(data);

          business['uid'] =
              data['uid']?.toString() ?? document.id;

          business['documentId'] = document.id;

          business['latitude'] = latitude;
          business['longitude'] = longitude;

          business['distanceKm'] = distanceInKm;

          allResults.add(business);
        }
      }

      // ================================================
      // SORT NEAREST FIRST
      // ================================================

      allResults.sort((a, b) {
        final aDistance =
            _readDouble(a['distanceKm']) ??
                double.infinity;

        final bDistance =
            _readDouble(b['distanceKm']) ??
                double.infinity;

        return aDistance.compareTo(bDistance);
      });

      if (!mounted) return;

      setState(() {
        businesses
          ..clear()
          ..addAll(allResults);

        visibleCount = businesses.length < pageSize
            ? businesses.length
            : pageSize;

        isLoadingBusinesses = false;
        isLoadingMore = false;
        errorMessage = null;
      });

      debugPrint(
        'Other Business results: ${businesses.length}',
      );

      debugPrint(
        'Selected category: ${widget.category} (${widget.categoryKey})',
      );
    } catch (e) {
      debugPrint('Other Business loading error: $e');

      if (mounted) {
        setState(() {
          isLoadingBusinesses = false;
          isLoadingMore = false;
          errorMessage =
              'Unable to load nearby businesses.';
        });
      }
    } finally {
      isFetchingAllBusinesses = false;
    }
  }

  // ============================================================
  // SCROLL PAGINATION
  // ============================================================

  void _scrollListener() {
    if (!scrollController.hasClients ||
        isLoadingMore ||
        isLoadingBusinesses) {
      return;
    }

    final position = scrollController.position;

    if (position.pixels >=
            position.maxScrollExtent - 300 &&
        visibleCount < businesses.length) {
      setState(() {
        isLoadingMore = true;

        visibleCount =
            (visibleCount + pageSize > businesses.length)
                ? businesses.length
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

  int get displayedBusinessCount {
    return visibleCount < businesses.length
        ? visibleCount
        : businesses.length;
  }

  // ============================================================
  // BUSINESS DETAILS
  // ============================================================

  String _businessName(Map<String, dynamic> business) {
    final value = business['name']?.toString().trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'Business';
  }

  String _categoriesText(Map<String, dynamic> business) {
    final savedCategories = business['categories'];

    if (savedCategories is List) {
      final values = savedCategories
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();

      if (values.isNotEmpty) {
        return values.join(', ');
      }
    }

    return widget.category;
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).round()} m away';
    }

    return '${distance.toStringAsFixed(1)} km away';
  }

  String _timeText(
    Map<String, dynamic> business,
    String key,
  ) {
    return business[key]?.toString().trim() ?? '';
  }

  // ============================================================
  // SUBSCRIPTION ACCESS
  // ============================================================

  bool _isInsidePaidRadius(
    Map<String, dynamic> business,
  ) {
    final distance =
        _readDouble(business['distanceKm']);

    if (distance == null) return false;

    // First 1 km is free.
    if (distance <= 1.0) return true;

    if (!subscriptionIsActive ||
        subscriptionExpiry == null ||
        !DateTime.now().isBefore(subscriptionExpiry!)) {
      return false;
    }

    return distance <= paidRadius;
  }

  Future<void> _openBusiness(
    Map<String, dynamic> business,
  ) async {
    final distance =
        _readDouble(business['distanceKm']);

    if (distance == null) return;

    await _loadPaidRadius();

    if (!mounted) return;

    if (_isInsidePaidRadius(business)) {
      _goToProfile(business);
      return;
    }

    _showPaymentRequiredDialog(
      business,
      distance,
    );
  }

  void _goToProfile(
    Map<String, dynamic> business,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenOtherBusinessProfile(
          business: business,
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT DIALOG
  // ============================================================

  void _showPaymentRequiredDialog(
    Map<String, dynamic> business,
    double distance,
  ) {
    final requiredRadius = distance.ceil();

    showDialog(
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
            'This business is '
            '${distance.toStringAsFixed(1)} km away.\n\n'
            'Your current access radius is '
            '${paidRadius.toStringAsFixed(0)} km.\n\n'
            'Unlock a larger radius to open this business profile.',
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('VIEW OPTIONS'),
            ),
          ],
        );
      },
    );
  }

  void _showRadiusInformation(int requiredRadius) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Distance Access',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'This business is approximately '
            '$requiredRadius km away.\n\n'
            'Your existing distance-unlock/payment flow '
            'can be connected here.',
            style: const TextStyle(height: 1.5),
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

    await _loadBusinesses(reset: true);
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
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Nearby ',
                style: TextStyle(
                  color: Color(0xFF08744F),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'Businesses',
                style: const TextStyle(
                  color: Color(0xFFE87516),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoadingLocation) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF159B16),
        ),
      );
    }

    if (locationPermissionDenied || errorMessage != null) {
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

          if (isLoadingBusinesses)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF159B16),
                ),
              ),
            )
          else if (businesses.isEmpty)
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
                itemCount: displayedBusinessCount +
                    (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= displayedBusinessCount) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF159B16),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _businessCard(businesses[index]),
                  );
                },
              ),
            ),
        ],
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
            widget.category,
            style: const TextStyle(
              color: Color(0xFF202124),
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Businesses within 50 km from your current location',
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
                    '${businesses.length} businesses found',
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
  // BUSINESS CARD
  // ============================================================

  Widget _businessCard(
    Map<String, dynamic> business,
  ) {
    final name = _businessName(business);
    final category = _categoriesText(business);

    final distance =
        _readDouble(business['distanceKm']) ?? 0;

    final bool isOpen24Hours =
        business['isOpen24Hours'] == true;

    final String openingTime =
        _timeText(business, 'openingTime');

    final String closingTime =
        _timeText(business, 'closingTime');

    final String timingText;

    if (isOpen24Hours) {
      timingText = 'Open 24 Hours';
    } else if (openingTime.isNotEmpty &&
        closingTime.isNotEmpty) {
      timingText = '$openingTime - $closingTime';
    } else {
      timingText = 'Timing not available';
    }

    final canOpen = _isInsidePaidRadius(business);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openBusiness(business),
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
              _businessImage(business),

              const SizedBox(width: 13),

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

                    const SizedBox(height: 9),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFE87516),
                          size: 18,
                        ),

                        const SizedBox(width: 4),

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
                            timingText,
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
  // BUSINESS IMAGE
  // ============================================================

  Widget _businessImage(
    Map<String, dynamic> business,
  ) {
    final photoUrl =
        business['profilePhotoUrl']?.toString().trim();

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          photoUrl,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return _defaultBusinessIcon();
          },
        ),
      );
    }

    return _defaultBusinessIcon();
  }

  Widget _defaultBusinessIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8EF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.business_outlined,
        color: Color(0xFF16803C),
        size: 36,
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
                Icons.business_outlined,
                color: Color(0xFF16803C),
                size: 42,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No nearby businesses',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF202124),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'No ${widget.category} businesses were found within 50 km.',
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
                  'Turn on location to find nearby businesses.',
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
}