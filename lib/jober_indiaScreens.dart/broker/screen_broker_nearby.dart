import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:jober_india/jober_indiaScreens.dart/broker/broker_profile.dart';

class ScreenBrokerNearby extends StatefulWidget {
  final String selectedCategory;

  const ScreenBrokerNearby({
    super.key,
    required this.selectedCategory,
  });

  @override
  State<ScreenBrokerNearby> createState() =>
      _ScreenBrokerNearbyState();
}

class _ScreenBrokerNearbyState
    extends State<ScreenBrokerNearby> {

  // ============================================================
  // FIRESTORE
  // ============================================================

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final ScrollController scrollController =
      ScrollController();

  Position? currentPosition;

  final List<Map<String, dynamic>> brokers = [];

  static const int pageSize = 20;
  static const int fetchBatchSize = 100;
  static const double maximumSearchRadius = 50.0;

  int visibleCount = pageSize;

  bool isFetchingAllBrokers = false;
  bool isLoadingLocation = true;
  bool isLoadingBrokers = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  bool locationPermissionDenied = false;

  String? errorMessage;

  DocumentSnapshot<Map<String, dynamic>>?
      lastDocument;

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

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializePage() async {
    await _loadPaidRadius();

    if (!mounted) return;

    final locationReady = await _getCurrentLocation();

    if (!locationReady || !mounted) return;

    await _loadBrokers(reset: true);
  }

  // ============================================================
  // LOAD PAID RADIUS
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
          DateTime.now().isBefore(expiry) &&
          savedDistance is num &&
          savedDistance > 1;

      if (validSubscription) {
        paidRadius = savedDistance
            .toDouble()
            .clamp(1.0, maximumSearchRadius);

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
      debugPrint('Broker subscription error: $e');

      paidRadius = 1.0;
      subscriptionExpiry = null;
      subscriptionIsActive = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // GET CURRENT LOCATION
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
              'Location permission is required to find nearby brokers.';
        });

        return false;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return false;

      setState(() {
        currentPosition = position;
        isLoadingLocation = false;
        locationPermissionDenied = false;
      });

      return true;
    } catch (e) {
      debugPrint('Broker location error: $e');

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
  // SCROLL LISTENER
  // ============================================================

  void _scrollListener() {
    if (!scrollController.hasClients ||
        isLoadingMore ||
        isLoadingBrokers) {
      return;
    }

    final position = scrollController.position;

    if (position.pixels >=
            position.maxScrollExtent - 300 &&
        visibleCount < brokers.length) {
      setState(() {
        isLoadingMore = true;

        visibleCount =
            (visibleCount + pageSize > brokers.length)
                ? brokers.length
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
  // DISPLAYED BROKER COUNT
  // ============================================================

  int get displayedBrokerCount {
    return visibleCount < brokers.length
        ? visibleCount
        : brokers.length;
  }

  // ============================================================
  // LOAD ALL ACTIVE BROKERS
  // CATEGORY + 50 KM
  // NEAREST FIRST
  // ============================================================

  Future<void> _loadBrokers({
    required bool reset,
  }) async {
    if (currentPosition == null ||
        isFetchingAllBrokers ||
        !reset) {
      return;
    }

    isFetchingAllBrokers = true;

    if (mounted) {
      setState(() {
        isLoadingBrokers = true;
        isLoadingMore = false;
        errorMessage = null;

        brokers.clear();

        visibleCount = pageSize;
        lastDocument = null;
        hasMore = true;
      });
    }

    try {
      final List<Map<String, dynamic>> allResults = [];

      // Fetch all active brokers in batches.
      while (hasMore) {
        Query<Map<String, dynamic>> query =
            firestore
                .collection('brokers')
                .where(
                  'isActive',
                  isEqualTo: true,
                )
                .orderBy(FieldPath.documentId)
                .limit(fetchBatchSize);

        if (lastDocument != null) {
          query = query.startAfterDocument(
            lastDocument!,
          );
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) {
          hasMore = false;
          break;
        }

        lastDocument = snapshot.docs.last;

        if (snapshot.docs.length < fetchBatchSize) {
          hasMore = false;
        }

        debugPrint(
          'Fetched ${snapshot.docs.length} brokers.',
        );

        for (final document in snapshot.docs) {
          final data = Map<String, dynamic>.from(
            document.data(),
          );

          if (data['isActive'] != true) continue;

          // CATEGORY FILTER
          if (!_brokerHasSelectedCategory(
            data,
            widget.selectedCategory,
          )) {
            continue;
          }

          // LOCATION
          double? latitude = _readDouble(
            data['latitude'] ?? data['lat'],
          );

          double? longitude = _readDouble(
            data['longitude'] ?? data['lng'],
          );

          // CURRENT LOCATION
          final currentLocation = data['currentLocation'];

          if (currentLocation is GeoPoint) {
            latitude ??= currentLocation.latitude;
            longitude ??= currentLocation.longitude;
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

          // LOCATION FIELD
          final savedLocation = data['location'];

          if (savedLocation is GeoPoint) {
            latitude ??= savedLocation.latitude;
            longitude ??= savedLocation.longitude;
          } else if (savedLocation is Map) {
            latitude ??= _readDouble(
              savedLocation['latitude'] ??
                  savedLocation['lat'],
            );

            longitude ??= _readDouble(
              savedLocation['longitude'] ??
                  savedLocation['lng'],
            );
          }

          if (latitude == null || longitude == null) {
            debugPrint(
              'Broker ${document.id}: location missing.',
            );
            continue;
          }

          // VALIDATE COORDINATES
          if (!latitude.isFinite ||
              !longitude.isFinite ||
              latitude < -90 ||
              latitude > 90 ||
              longitude < -180 ||
              longitude > 180) {
            continue;
          }

          // DISTANCE
          final distanceMeters =
              Geolocator.distanceBetween(
            currentPosition!.latitude,
            currentPosition!.longitude,
            latitude,
            longitude,
          );

          final distanceKm = distanceMeters / 1000;

          if (distanceKm > maximumSearchRadius) {
            continue;
          }

          // SAVE BROKER
          data['uid'] =
              data['uid']?.toString() ?? document.id;

          data['documentId'] = document.id;

          data['latitude'] = latitude;
          data['longitude'] = longitude;

          data['distanceKm'] = distanceKm;
          data['distanceMeters'] = distanceMeters;

          allResults.add(data);
        }
      }

      // SORT NEAREST FIRST
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
        brokers
          ..clear()
          ..addAll(allResults);

        visibleCount = brokers.length < pageSize
            ? brokers.length
            : pageSize;

        isLoadingBrokers = false;
        isLoadingMore = false;
        errorMessage = null;
      });

      debugPrint(
        'TOTAL BROKERS FOUND: ${allResults.length}',
      );

      debugPrint(
        'CATEGORY: ${widget.selectedCategory}',
      );
    } catch (e, stackTrace) {
      debugPrint('Broker loading error: $e');
      debugPrint('$stackTrace');

      if (mounted) {
        setState(() {
          isLoadingBrokers = false;
          isLoadingMore = false;
          errorMessage =
              'Unable to load nearby brokers.';
        });
      }
    } finally {
      isFetchingAllBrokers = false;
    }
  }

  // ============================================================
  // CATEGORY MATCHING
  // NEW + OLD FIRESTORE STRUCTURES
  // ============================================================

  bool _brokerHasSelectedCategory(
    Map<String, dynamic> broker,
    String selectedCategory,
  ) {
    final wanted =
        selectedCategory.trim().toLowerCase();

    if (wanted.isEmpty) return false;

    final Set<String> savedCategories = {};

    void addCategories(dynamic value) {
      if (value is List) {
        for (final item in value) {
          final category =
              item.toString().trim().toLowerCase();

          if (category.isNotEmpty) {
            savedCategories.add(category);
          }
        }
      } else if (value is String) {
        for (final item in value.split(',')) {
          final category =
              item.trim().toLowerCase();

          if (category.isNotEmpty) {
            savedCategories.add(category);
          }
        }
      }
    }

    addCategories(broker['categories']);
    addCategories(broker['category']);
    addCategories(broker['brokerCategories']);

    return savedCategories.contains(wanted);
  }

  // ============================================================
  // READ DOUBLE
  // ============================================================

  double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim());
    }

    return null;
  }

  // ============================================================
  // BROKER NAME
  // ============================================================

  String _brokerName(
    Map<String, dynamic> broker,
  ) {
    final name = (
      broker['displayName'] ??
      broker['brokerName'] ??
      broker['name'] ??
      broker['username'] ??
      broker['userName']
    )?.toString().trim();

    if (name == null || name.isEmpty) {
      return 'Broker';
    }

    return name;
  }

  // ============================================================
  // BROKER CATEGORIES TEXT
  // ============================================================

  String _categoriesText(
    Map<String, dynamic> broker,
  ) {
    final Map<String, String> uniqueCategories = {};

    void addCategories(dynamic value) {
      if (value is List) {
        for (final item in value) {
          final category = item.toString().trim();

          if (category.isNotEmpty) {
            uniqueCategories.putIfAbsent(
              category.toLowerCase(),
              () => category,
            );
          }
        }
      } else if (value is String) {
        for (final item in value.split(',')) {
          final category = item.trim();

          if (category.isNotEmpty) {
            uniqueCategories.putIfAbsent(
              category.toLowerCase(),
              () => category,
            );
          }
        }
      }
    }

    addCategories(broker['categories']);
    addCategories(broker['category']);
    addCategories(broker['brokerCategories']);

    if (uniqueCategories.isEmpty) {
      return widget.selectedCategory;
    }

    return uniqueCategories.values.join(', ');
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
  // TIMING
  // ============================================================

  String _timeText(
    Map<String, dynamic> broker,
    String key,
  ) {
    final value = broker[key]?.toString().trim();

    if (value == null || value.isEmpty) {
      return '';
    }

    return value;
  }

  // ============================================================
  // PAID RADIUS CHECK
  // ============================================================

  bool _isInsidePaidRadius(
    Map<String, dynamic> broker,
  ) {
    final distance =
        _readDouble(broker['distanceKm']);

    if (distance == null) return false;

    // First 1 km is free.
    if (distance <= 1.0) {
      return true;
    }

    if (!subscriptionIsActive ||
        subscriptionExpiry == null ||
        !DateTime.now().isBefore(subscriptionExpiry!)) {
      return false;
    }

    return distance <= paidRadius;
  }

  // ============================================================
  // OPEN BROKER PROFILE
  // ============================================================

  Future<void> _openBroker(
    Map<String, dynamic> broker,
  ) async {
    final distance =
        _readDouble(broker['distanceKm']);

    if (distance == null) return;

    await _loadPaidRadius();

    if (!mounted) return;

    if (_isInsidePaidRadius(broker)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScreenBrokerProfile(
            broker: broker,
            selectedCategory: widget.selectedCategory,
          ),
        ),
      );

      return;
    }

    _showPaymentRequiredDialog(distance);
  }

  // ============================================================
  // PAYMENT REQUIRED DIALOG
  // ============================================================

  void _showPaymentRequiredDialog(double distance) {
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
            'This broker is '
            '${distance.toStringAsFixed(1)} km away.\n\n'
            'Your current access radius is '
            '${paidRadius.toStringAsFixed(0)} km.\n\n'
            'Unlock a larger radius to open this broker profile.',
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
                _showRadiusInformation(distance.ceil());
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

  // ============================================================
  // RADIUS INFORMATION
  // ============================================================

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
            'This broker is approximately '
            '$requiredRadius km away.\n\n'
            'Your existing distance-unlock/payment '
            'flow can be connected here.',
            style: const TextStyle(
              height: 1.5,
            ),
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

    await _loadBrokers(reset: true);
  }

  // ============================================================
  // BROKER IMAGE
  // ============================================================

  Widget _brokerImage(
    Map<String, dynamic> broker,
  ) {
    final photoUrl = (
      broker['profilePhotoUrl'] ??
      broker['photoUrl'] ??
      broker['profileImage']
    )?.toString().trim();

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          photoUrl,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return _defaultBrokerIcon();
          },
        ),
      );
    }

    return _defaultBrokerIcon();
  }

  // ============================================================
  // DEFAULT BROKER ICON
  // ============================================================

  Widget _defaultBrokerIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8EF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.handshake_outlined,
        color: Color(0xFF16803C),
        size: 36,
      ),
    );
  }

  // ============================================================
  // BUILD BROKER CARD
  // ============================================================

  Widget _brokerCard(
    Map<String, dynamic> broker,
  ) {
    final name = _brokerName(broker);

    final category = _categoriesText(broker);

    final distance =
        _readDouble(broker['distanceKm']) ?? 0;

    final canOpen = _isInsidePaidRadius(broker);

    final isOpen24Hours =
        broker['isOpen24Hours'] == true;

    final openingTime =
        _timeText(broker, 'openingTime');

    final closingTime =
        _timeText(broker, 'closingTime');

    final String timingText;

    if (isOpen24Hours) {
      timingText = 'Open 24 Hours';
    } else if (openingTime.isNotEmpty &&
        closingTime.isNotEmpty) {
      timingText = '$openingTime - $closingTime';
    } else {
      timingText = 'Timing not available';
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _openBroker(broker);
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
              // BROKER IMAGE
              _brokerImage(broker),

              const SizedBox(width: 13),

              // BROKER DETAILS
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

                    // DISTANCE
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

                    // TIMING
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

              // ACCESS INDICATOR
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
                text: 'Brokers',
                style: TextStyle(
                  color: Color(0xFFE87516),
                  fontSize: 23,
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
          // TOP SECTION
          SliverToBoxAdapter(
            child: _buildTopSection(),
          ),

          if (isLoadingBrokers)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF159B16),
                ),
              ),
            )
          else if (brokers.isEmpty)
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
                itemCount: displayedBrokerCount +
                    (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= displayedBrokerCount) {
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
                    child: _brokerCard(
                      brokers[index],
                    ),
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
      padding: const EdgeInsets.fromLTRB(
        20,
        15,
        20,
        18,
      ),
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

          Text(
            'Brokers within '
            '${maximumSearchRadius.toStringAsFixed(0)} km '
            'from your current location',
            style: const TextStyle(
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
                    '${brokers.length} '
                    '${brokers.length == 1 ? 'broker' : 'brokers'} found',
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
                Icons.handshake_outlined,
                color: Color(0xFF16803C),
                size: 42,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No nearby brokers',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF202124),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'No ${widget.selectedCategory} '
              'brokers were found within '
              '${maximumSearchRadius.toStringAsFixed(0)} km.',
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
                  'Turn on location to find nearby brokers.',
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
