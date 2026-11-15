import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jober_india/jober_indiaScreens.dart/Laboratory/laboratory_profile.dart';


class ScreenNearbyLaboratory extends StatefulWidget {
  final String selectedCategory;

  const ScreenNearbyLaboratory({
    super.key,
    required this.selectedCategory,
  });

  @override
  State<ScreenNearbyLaboratory> createState() =>
      _ScreenNearbyLaboratoryState();
}

class _ScreenNearbyLaboratoryState
    extends State<ScreenNearbyLaboratory> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final ScrollController scrollController =
      ScrollController();

  Position? currentPosition;

  final List<Map<String, dynamic>> laboratories = [];

  static const int pageSize = 20;
static const double maximumSearchRadius = 50.0;

int visibleCount = pageSize;

bool isFetchingAllLaboratories = false;

  bool isLoadingLocation = true;
  bool isLoadingLaboratories = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  bool locationPermissionDenied = false;

  String? errorMessage;

double paidRadius = 1.0;
DateTime? subscriptionExpiry;
bool subscriptionIsActive = false;
  DocumentSnapshot? lastDocument;

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

  Future<void> _initializePage() async {
    await _loadPaidRadius();

    final locationReady = await _getCurrentLocation();

    if (!locationReady) {
      return;
    }

    await _loadLaboratories(
      reset: true,
    );
  }
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

      // Clear expired subscription information.
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
    debugPrint('Laboratory subscription loading error: $e');

    paidRadius = 1.0;
    subscriptionExpiry = null;
    subscriptionIsActive = false;
  }

  if (mounted) {
    setState(() {});
  }
}

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
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        if (!mounted) return false;

        setState(() {
          isLoadingLocation = false;
          locationPermissionDenied = true;
          errorMessage =
              'Location permission is required to find nearby laboratories.';
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
});

      return true;
    } catch (e) {
      if (!mounted) return false;

      setState(() {
        isLoadingLocation = false;
        errorMessage =
            'Unable to get your current location.';
      });

      return false;
    }
  }
void _scrollListener() {
  if (!scrollController.hasClients ||
      isLoadingMore ||
      isLoadingLaboratories) {
    return;
  }

  final position = scrollController.position;

  if (position.pixels >= position.maxScrollExtent - 300 &&
      visibleCount < laboratories.length) {
    setState(() {
      isLoadingMore = true;

      visibleCount =
          (visibleCount + pageSize > laboratories.length)
              ? laboratories.length
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

int get displayedLaboratoryCount {
  return visibleCount < laboratories.length
      ? visibleCount
      : laboratories.length;
}

Future<void> _loadLaboratories({
  required bool reset,
}) async {
  if (currentPosition == null ||
      isFetchingAllLaboratories) {
    return;
  }

  if (!reset) return;

  isFetchingAllLaboratories = true;

  if (mounted) {
    setState(() {
      isLoadingLaboratories = true;
      isLoadingMore = false;
      errorMessage = null;

      laboratories.clear();

      visibleCount = pageSize;
      lastDocument = null;
      hasMore = true;
    });
  }

  try {
    final List<Map<String, dynamic>> allResults = [];

    // Fetch every matching Firestore document.
    while (hasMore) {
      Query<Map<String, dynamic>> query = firestore
          .collection('labs')
          .where('isActive', isEqualTo: true)
          .where(
            'categories',
            arrayContains: widget.selectedCategory,
          )
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

        double? latitude;
        double? longitude;

        // Read location from GeoPoint or Map.
        final currentLocation = data['currentLocation'];

        if (currentLocation is GeoPoint) {
          latitude = currentLocation.latitude;
          longitude = currentLocation.longitude;
        } else if (currentLocation is Map) {
          latitude = _readDouble(
            currentLocation['latitude'] ??
                currentLocation['lat'],
          );

          longitude = _readDouble(
            currentLocation['longitude'] ??
                currentLocation['lng'],
          );
        }

        // Fallback to separate coordinate fields.
        latitude ??= _readDouble(data['latitude']);
        longitude ??= _readDouble(data['longitude']);

        if (latitude == null || longitude == null) {
          continue;
        }

        // Validate coordinates.
        if (latitude < -90 ||
            latitude > 90 ||
            longitude < -180 ||
            longitude > 180) {
          continue;
        }

        final distanceInMeters =
            Geolocator.distanceBetween(
          currentPosition!.latitude,
          currentPosition!.longitude,
          latitude,
          longitude,
        );

        final distanceInKm = distanceInMeters / 1000;

        // Keep only laboratories within 50 km.
        if (distanceInKm > maximumSearchRadius) {
          continue;
        }

        final laboratory =
            Map<String, dynamic>.from(data);

        laboratory['uid'] =
            data['uid']?.toString() ?? document.id;

        laboratory['documentId'] = document.id;

        laboratory['latitude'] = latitude;
        laboratory['longitude'] = longitude;

        laboratory['distanceKm'] = distanceInKm;

        allResults.add(laboratory);
      }
    }

    // Sort the COMPLETE result, not individual batches.
    allResults.sort((a, b) {
      final aDistance =
          _readDouble(a['distanceKm']) ?? double.infinity;

      final bDistance =
          _readDouble(b['distanceKm']) ?? double.infinity;

      return aDistance.compareTo(bDistance);
    });

    if (!mounted) return;

    setState(() {
      laboratories
        ..clear()
        ..addAll(allResults);

      // Initially display only the nearest 20.
      visibleCount = laboratories.length < pageSize
          ? laboratories.length
          : pageSize;

      isLoadingLaboratories = false;
      isLoadingMore = false;
      errorMessage = null;
    });
  } catch (e) {
    debugPrint('Laboratory loading error: $e');

    if (mounted) {
      setState(() {
        isLoadingLaboratories = false;
        isLoadingMore = false;
        errorMessage =
            'Unable to load nearby laboratories.';
      });
    }
  } finally {
    isFetchingAllLaboratories = false;
  }
}

  double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  String _laboratoryName(
    Map<String, dynamic> laboratory,
  ) {
    final displayName =
        laboratory['displayName']
            ?.toString()
            .trim();

    if (displayName != null &&
        displayName.isNotEmpty) {
      return displayName;
    }

    final laboratoryName =
        laboratory['laboratoryName']
            ?.toString()
            .trim();

    if (laboratoryName != null &&
        laboratoryName.isNotEmpty) {
      return laboratoryName;
    }

    return 'Laboratory';
  }

  String _categoriesText(
    Map<String, dynamic> laboratory,
  ) {
    final categories =
        laboratory['categories'];

    if (categories is List) {
      final values = categories
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();

      if (values.isNotEmpty) {
        return values.join(', ');
      }
    }

    return widget.selectedCategory;
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      final meters =
          (distance * 1000).round();

      return '$meters m away';
    }

    return '${distance.toStringAsFixed(1)} km away';
  }

String _timeText(
  Map<String, dynamic> laboratory,
  String key,
) {
  final value = laboratory[key]?.toString().trim();

  if (value == null || value.isEmpty) {
    return '';
  }

  return value;
}

bool _isInsidePaidRadius(
  Map<String, dynamic> laboratory,
) {
  final distance =
      _readDouble(laboratory['distanceKm']);

  if (distance == null) {
    return false;
  }

  // First 1 km is always free.
  if (distance <= 1.0) {
    return true;
  }

  // Beyond 1 km requires an active subscription.
  if (!subscriptionIsActive ||
      subscriptionExpiry == null ||
      !DateTime.now().isBefore(subscriptionExpiry!)) {
    return false;
  }

  return distance <= paidRadius;
}

Future<void> _openLaboratory(
  Map<String, dynamic> laboratory,
) async {
  final distance =
      _readDouble(laboratory['distanceKm']);

  if (distance == null) {
    return;
  }

  // Always read the latest subscription from Hive.
  await _loadPaidRadius();

  if (!mounted) return;

  // First 1 km is free.
  // Beyond 1 km requires a valid subscription.
  if (_isInsidePaidRadius(laboratory)) {
    _goToProfile(laboratory);
    return;
  }

  _showPaymentRequiredDialog(
    laboratory,
    distance,
  );
}

  void _goToProfile(
    Map<String, dynamic> laboratory,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ScreenLaboratoryProfile(
          laboratory: laboratory,
        ),
      ),
    );
  }

  void _showPaymentRequiredDialog(
    Map<String, dynamic> laboratory,
    double distance,
  ) {
    final requiredRadius =
        distance.ceil();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Text(
            'Profile Access',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF202124),
            ),
          ),
          content: Text(
            'This laboratory is '
            '${distance.toStringAsFixed(1)} km away.\n\n'
            'Your current access radius is '
            '${paidRadius.toStringAsFixed(0)} km.\n\n'
            'Unlock a larger radius to open this laboratory profile.',
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

                _showRadiusInformation(
                  requiredRadius,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF159B16),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'VIEW OPTIONS',
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRadiusInformation(
    int requiredRadius,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Text(
            'Distance Access',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'This laboratory is approximately '
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
              child: const Text(
                'OK',
              ),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _refresh() async {
  await _loadPaidRadius();

  if (!mounted) return;

  final locationReady =
      await _getCurrentLocation();

  if (!locationReady || !mounted) {
    return;
  }

  await _loadLaboratories(reset: true);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8F7),
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
                text: 'Laboratories',
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
        physics:
            const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _buildTopSection(),
          ),

          if (isLoadingLaboratories)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child:
                    CircularProgressIndicator(
                  color: Color(0xFF159B16),
                ),
              ),
            )
          else if (laboratories.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                0,
                18,
                25,
              ),
              sliver:
                  SliverList.builder(
                itemCount:
    displayedLaboratoryCount +
        (isLoadingMore ? 1 : 0),
                itemBuilder:
                    (context, index) {
                  if (index >= displayedLaboratoryCount) {
                    return const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        vertical: 20,
                      ),
                      child: Center(
                        child:
                            CircularProgressIndicator(
                          color:
                              Color(0xFF159B16),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child:
                        _laboratoryCard(
                      laboratories[index],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        15,
        20,
        18,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
            'Laboratories within '
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
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFEFF8EF),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color:
                      Color(0xFF16803C),
                  size: 21,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${laboratories.length} '
                    'laborator${laboratories.length == 1 ? 'y' : 'ies'} found',
                    style: const TextStyle(
                      color:
                          Color(0xFF16803C),
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.sort,
                  color:
                      Color(0xFF16803C),
                  size: 20,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Nearest first',
                  style: TextStyle(
                    color:
                        Color(0xFF16803C),
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _laboratoryCard(
    Map<String, dynamic> laboratory,
  ) {
    final name =
        _laboratoryName(laboratory);

    final category =
        _categoriesText(laboratory);

    final distance =
        _readDouble(
              laboratory['distanceKm'],
            ) ??
            0;

    final bool isOpen24Hours =
    laboratory['isOpen24Hours'] == true;

final String openingTime =
    _timeText(laboratory, 'openingTime');

final String closingTime =
    _timeText(laboratory, 'closingTime');

final String timingText;

if (isOpen24Hours) {
  timingText = 'Open 24 Hours';
} else if (openingTime.isNotEmpty &&
    closingTime.isNotEmpty) {
  timingText = '$openingTime - $closingTime';
} else {
  timingText = 'Timing not available';
}

    final canOpen =
        _isInsidePaidRadius(
      laboratory,
    );

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(20),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: () {
          _openLaboratory(
            laboratory,
          );
        },
        child: Container(
          padding:
              const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color:
                  const Color(0xFFE1E1E1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: 0.035),
                blurRadius: 7,
                offset:
                    const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _laboratoryImage(
                laboratory,
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF202124),
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      category,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF16803C),
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color:
                              Color(0xFFE87516),
                          size: 18,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          _formatDistance(
                            distance,
                          ),
                          style:
                              const TextStyle(
                            color:
                                Colors.black87,
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
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
                        ? Icons
                            .arrow_forward_ios
                        : Icons.lock_outline,
                    color: canOpen
                        ? const Color(
                            0xFF16803C,
                          )
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
                        fontWeight:
                            FontWeight.w600,
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

  Widget _laboratoryImage(
    Map<String, dynamic> laboratory,
  ) {
    final photoUrl =
    (laboratory['profilePhotoUrl'] ??
            laboratory['photoUrl'])
        ?.toString()
        .trim();

    if (photoUrl != null &&
        photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(15),
        child: Image.network(
          photoUrl,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder:
              (_, _, _) {
            return _defaultLaboratoryIcon();
          },
        ),
      );
    }

    return _defaultLaboratoryIcon();
  }

  Widget _defaultLaboratoryIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color:
            const Color(0xFFEFF8EF),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.biotech_outlined,
        color: Color(0xFF16803C),
        size: 36,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFEFF8EF),
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.biotech_outlined,
                color:
                    Color(0xFF16803C),
                size: 42,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No nearby laboratories',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    Color(0xFF202124),
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'No ${widget.selectedCategory} '
              'was found within '
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
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'SEARCH AGAIN',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF159B16,
                ),
                foregroundColor:
                    Colors.white,
                minimumSize:
                    const Size(
                  170,
                  50,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    25,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFFFF3E8),
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.location_off_outlined,
                color:
                    Color(0xFFE87516),
                size: 42,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Location Required',
              style: TextStyle(
                color:
                    Color(0xFF202124),
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              errorMessage ??
                  'Turn on location to find nearby laboratories.',
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
              icon: const Icon(
                Icons.location_on,
              ),
              label: const Text(
                'ENABLE LOCATION',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF159B16,
                ),
                foregroundColor:
                    Colors.white,
                minimumSize:
                    const Size(
                  190,
                  50,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    25,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}