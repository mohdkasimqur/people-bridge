import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:url_launcher/url_launcher.dart';

class ScreenGarageList extends StatefulWidget {
  final String category;

  const ScreenGarageList({
    super.key,
    required this.category,
  });

  @override
  State<ScreenGarageList> createState() =>
      _ScreenGarageListState();
}

class _ScreenGarageListState extends State<ScreenGarageList> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth = FirebaseAuth.instance;

  final ScrollController scrollController =
      ScrollController();

  Position? currentPosition;

  final List<GarageItem> garages = [];

  // ============================================================
  // SETTINGS
  // ============================================================

  static const int pageSize = 20;

  static const double maximumSearchRadius = 50.0;

  int visibleCount = pageSize;

  bool isFetchingAllGarages = false;

  bool isLoadingLocation = true;
  bool isLoadingGarages = false;
  bool isLoadingMore = false;

  bool locationPermissionDenied = false;

  String? errorMessage;

  // ============================================================
  // SUBSCRIPTION
  // ============================================================

  double paidRadius = 1.0;

  DateTime? subscriptionExpiry;

  bool subscriptionIsActive = false;

  // ============================================================
  // FIRESTORE PAGINATION
  // ============================================================

  DocumentSnapshot<Map<String, dynamic>>? lastDocument;

  bool hasMore = true;

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
  // INITIALIZE PAGE
  // ============================================================

  Future<void> _initializePage() async {
    await _loadPaidRadius();

    if (!mounted) return;

    final locationReady =
        await _getCurrentLocation();

    if (!locationReady || !mounted) {
      return;
    }

    await _loadGarages(reset: true);
  }

  // ============================================================
  // LOAD PAID DISTANCE FROM HOME PAGE SUBSCRIPTION
  // ============================================================

  Future<void> _loadPaidRadius() async {
    try {
      if (!Hive.isBoxOpen('settings')) {
        await Hive.openBox('settings');
      }

      final box = Hive.box('settings');

      final savedDistance =
          box.get('activeDistance');

      final savedExpiry =
          box.get('subscriptionExpiry');

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

      if (validSubscription &&
          savedDistance is num) {
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
      debugPrint(
        'Garage subscription loading error: $e',
      );

      paidRadius = 1.0;
      subscriptionExpiry = null;
      subscriptionIsActive = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // GET CURRENT USER LOCATION
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
              'Location permission is required to find nearby garages.';
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
      debugPrint(
        'Garage location error: $e',
      );

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
  // SCROLL PAGINATION
  // ============================================================

  void _scrollListener() {
    if (!scrollController.hasClients ||
        isLoadingMore ||
        isLoadingGarages) {
      return;
    }

    final position = scrollController.position;

    if (position.pixels >=
            position.maxScrollExtent - 300 &&
        visibleCount < garages.length) {
      setState(() {
        isLoadingMore = true;

        visibleCount =
            (visibleCount + pageSize > garages.length)
                ? garages.length
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

  int get displayedGarageCount {
    return visibleCount < garages.length
        ? visibleCount
        : garages.length;
  }

  // ============================================================
  // LOAD ALL MATCHING GARAGES FROM FIRESTORE
  // ============================================================

  Future<void> _loadGarages({
    required bool reset,
  }) async {
    if (currentPosition == null ||
        isFetchingAllGarages) {
      return;
    }

    if (!reset) return;

    isFetchingAllGarages = true;

    if (mounted) {
      setState(() {
        isLoadingGarages = true;
        isLoadingMore = false;
        errorMessage = null;

        garages.clear();

        visibleCount = pageSize;

        lastDocument = null;
        hasMore = true;
      });
    }

    try {
      final List<GarageItem> allResults = [];

      // Fetch every active garage matching this category.
      while (hasMore) {
        Query<Map<String, dynamic>> query =
            firestore
                .collection('garageOwners')
                .where(
                  'isActive',
                  isEqualTo: true,
                )
                .where(
                  'categories',
                  arrayContains: widget.category,
                )
                .limit(pageSize);

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

        if (snapshot.docs.length < pageSize) {
          hasMore = false;
        }

        for (final document in snapshot.docs) {
          final data = document.data();

          // Ignore inactive profiles.
          if (data['isActive'] != true) {
            continue;
          }

          final garage =
              GarageItem.fromFirestore(
            document.id,
            data,
          );

          if (garage.latitude == null ||
              garage.longitude == null) {
            continue;
          }

          // Validate coordinates.
          if (garage.latitude! < -90 ||
              garage.latitude! > 90 ||
              garage.longitude! < -180 ||
              garage.longitude! > 180) {
            continue;
          }

          // Calculate distance from user's current location.
          final distanceInMeters =
              Geolocator.distanceBetween(
            currentPosition!.latitude,
            currentPosition!.longitude,
            garage.latitude!,
            garage.longitude!,
          );

          final distanceInKm =
              distanceInMeters / 1000.0;

          // Only garages within 50 km.
          if (distanceInKm > maximumSearchRadius) {
            continue;
          }

          garage.distanceMeters =
              distanceInMeters;

          garage.distanceKm =
              distanceInKm;

          allResults.add(garage);
        }
      }

      // Sort the COMPLETE result by nearest first.
      allResults.sort((a, b) {
        return a.distanceMeters.compareTo(
          b.distanceMeters,
        );
      });

      if (!mounted) return;

      setState(() {
        garages
          ..clear()
          ..addAll(allResults);

        // Initially show the nearest 20.
        visibleCount =
            garages.length < pageSize
                ? garages.length
                : pageSize;

        isLoadingGarages = false;
        isLoadingMore = false;
        errorMessage = null;
      });
    } catch (e) {
      debugPrint(
        'Garage loading error: $e',
      );

      if (mounted) {
        setState(() {
          isLoadingGarages = false;
          isLoadingMore = false;
          errorMessage =
              'Unable to load nearby garages.';
        });
      }
    } finally {
      isFetchingAllGarages = false;
    }
  }

  // ============================================================
  // DISTANCE TEXT
  // ============================================================

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      final meters =
          (distanceKm * 1000).round();

      return '$meters m away';
    }

    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  // ============================================================
  // GARAGE NAME
  // ============================================================

  String _garageName(GarageItem garage) {
    if (garage.garageName.trim().isNotEmpty) {
      return garage.garageName;
    }

    return 'Garage';
  }

  // ============================================================
  // GARAGE CATEGORY TEXT
  // ============================================================

  String _categoriesText(GarageItem garage) {
    if (garage.categories.isNotEmpty) {
      return garage.categories.join(', ');
    }

    return widget.category;
  }

  // ============================================================
  // GARAGE OPENING TIME
  // ============================================================

  String _timingText(GarageItem garage) {
    if (garage.isOpen24Hours) {
      return 'Open 24 Hours';
    }

    if (garage.openingTime.isNotEmpty &&
        garage.closingTime.isNotEmpty) {
      return '${garage.openingTime} - ${garage.closingTime}';
    }

    return 'Timing not available';
  }

  // ============================================================
  // CHECK PAID DISTANCE
  // ============================================================

  bool _isInsidePaidRadius(GarageItem garage) {
    final distanceKm = garage.distanceKm;

    // First 1 km is always free.
    if (distanceKm <= 1.0) {
      return true;
    }

    // Beyond 1 km requires an active subscription.
    if (!subscriptionIsActive ||
        subscriptionExpiry == null ||
        !DateTime.now().isBefore(subscriptionExpiry!)) {
      return false;
    }

    return distanceKm <= paidRadius;
  }

  // ============================================================
  // CHECK ACCESS BEFORE GARAGE ACTION
  // ============================================================

  Future<bool> _checkGarageAccess(
    GarageItem garage,
  ) async {
    // Read the latest payment information from Hive.
    await _loadPaidRadius();

    if (!mounted) return false;

    if (_isInsidePaidRadius(garage)) {
      return true;
    }

    _showPaymentRequiredDialog(garage);

    return false;
  }

  // ============================================================
  // PAYMENT REQUIRED DIALOG
  // ============================================================

  void _showPaymentRequiredDialog(
    GarageItem garage,
  ) {
    final requiredRadius =
        garage.distanceKm.ceil();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Garage Access',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF202124),
            ),
          ),
          content: Text(
            'This garage is '
            '${garage.distanceKm.toStringAsFixed(1)} km away.\n\n'
            'Your current access radius is '
            '${paidRadius.toStringAsFixed(0)} km.\n\n'
            'Please unlock at least $requiredRadius km '
            'from the Home page to contact this garage.',
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
          ],
        );
      },
    );
  }

  // ============================================================
  // OPEN GARAGE LOCATION IN GOOGLE MAPS
  // ============================================================

  Future<void> openGarageLocation(
    GarageItem garage,
  ) async {
    final allowed =
        await _checkGarageAccess(garage);

    if (!allowed || !mounted) return;

    if (garage.latitude == null ||
        garage.longitude == null) {
      _showMessage(
        'Garage location is not available.',
      );

      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${garage.latitude},${garage.longitude}',
    );

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not open the garage location.',
      );
    }
  }

  // ============================================================
  // CALL GARAGE
  // ============================================================

  Future<void> callGarage(
    GarageItem garage,
  ) async {
    final allowed =
        await _checkGarageAccess(garage);

    if (!allowed || !mounted) return;

    final phone = garage.secondaryPhone.trim();

    if (phone.isEmpty) {
      _showMessage(
        'Secondary phone number is not available.',
      );

      return;
    }

    final cleanPhone = phone.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    final dialNumber =
        cleanPhone.startsWith('+')
            ? cleanPhone
            : '+91$cleanPhone';

    final uri = Uri(
      scheme: 'tel',
      path: dialNumber,
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;

        _showMessage(
          'Could not open the phone dialer.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not open the phone dialer.',
      );
    }
  }

  // ============================================================
  // OPEN GARAGE CHAT
  // ============================================================

  Future<void> openGarageChat(
    GarageItem garage,
  ) async {
    final allowed =
        await _checkGarageAccess(garage);

    if (!allowed || !mounted) return;

    final currentUser = auth.currentUser;

    if (currentUser == null) {
      _showMessage(
        'Please login to send a message.',
      );

      return;
    }

    final chatData = <String, dynamic>{
      'uid': garage.uid,
      'name': garage.garageName,
      'garageName': garage.garageName,
      'displayName': garage.garageName,
      'ownerName': garage.ownerName,
      'mobile': garage.secondaryPhone,
      'role': 'garage',
      'categories': garage.categories,
      'latitude': garage.latitude,
      'longitude': garage.longitude,
      'locationAddress': garage.placeName,
      'photoUrl': garage.profilePhotoUrl,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenMessage(
          chatUser: chatData,
        ),
      ),
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _loadPaidRadius();

    if (!mounted) return;

    final locationReady =
        await _getCurrentLocation();

    if (!locationReady || !mounted) {
      return;
    }

    await _loadGarages(reset: true);
  }

  // ============================================================
  // GARAGE IMAGE
  // ============================================================

  Widget _garageImage(GarageItem garage) {
    final photoUrl =
        garage.profilePhotoUrl.trim();

    if (photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          photoUrl,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return _defaultGarageIcon();
          },
        ),
      );
    }

    return _defaultGarageIcon();
  }

  Widget _defaultGarageIcon() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8EF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.car_repair,
        color: Color(0xFF16803C),
        size: 38,
      ),
    );
  }

  // ============================================================
  // GARAGE CARD
  // ============================================================

  Widget _garageCard(GarageItem garage) {
    final canOpen =
        _isInsidePaidRadius(garage);

    final timingText =
        _timingText(garage);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // The card itself does not open a separate
          // payment page. Its actions use the same access check.
          openGarageLocation(garage);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _garageImage(garage),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _garageName(garage),
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
                          _categoriesText(garage),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF16803C),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 9),

                        // DISTANCE FROM USER
                        Row(
                          children: [
                            const Icon(
                              Icons.my_location,
                              color: Color(0xFFE87516),
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _formatDistance(
                                  garage.distanceKm,
                                ),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 7),

                        // GARAGE LOCATION
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.grey,
                              size: 17,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                garage.placeName.isNotEmpty
                                    ? garage.placeName
                                    : 'Garage location',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
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
                              color: garage.isOpen24Hours
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
                                  color: garage.isOpen24Hours
                                      ? const Color(0xFF16803C)
                                      : Colors.grey,
                                  fontSize: 12,
                                  fontWeight:
                                      garage.isOpen24Hours
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

              const SizedBox(height: 14),

              // ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        openGarageLocation(garage);
                      },
                      icon: const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                      ),
                      label: const Text('Location'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        openGarageChat(garage);
                      },
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                      ),
                      label: const Text('Chat'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        callGarage(garage);
                      },
                      icon: const Icon(
                        Icons.call_outlined,
                        size: 18,
                      ),
                      label: const Text('Call'),
                    ),
                  ),
                ],
              ),

              if (!canOpen) ...[
                const SizedBox(height: 8),

                const Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Unlock a larger radius from the Home page to contact this garage.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
                Icons.car_repair,
                color: Color(0xFF16803C),
                size: 42,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No nearby garages',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF202124),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'No ${widget.category} garages were found within '
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
                  'Turn on location to find nearby garages.',
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
            widget.category,
            style: const TextStyle(
              color: Color(0xFF202124),
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Garages within '
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
                    '${garages.length} '
                    '${garages.length == 1 ? 'garage' : 'garages'} found',
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

          if (isLoadingGarages)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF159B16),
                ),
              ),
            )
          else if (garages.isEmpty)
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
                itemCount:
                    displayedGarageCount +
                    (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= displayedGarageCount) {
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
                    child: _garageCard(
                      garages[index],
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
                text: 'Garages',
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
}

// ================================================================
// GARAGE MODEL
// ================================================================

class GarageItem {
  final String uid;
  final String ownerName;
  final String garageName;
  final String secondaryPhone;

  final String placeName;
  final String profilePhotoUrl;

  final List<String> categories;

  final bool isOpen24Hours;
  final String openingTime;
  final String closingTime;

  final double? latitude;
  final double? longitude;

  double distanceMeters;
  double distanceKm;

  GarageItem({
    required this.uid,
    required this.ownerName,
    required this.garageName,
    required this.secondaryPhone,
    required this.placeName,
    required this.profilePhotoUrl,
    required this.categories,
    required this.isOpen24Hours,
    required this.openingTime,
    required this.closingTime,
    required this.latitude,
    required this.longitude,
    this.distanceMeters = 0,
    this.distanceKm = 0,
  });

  // ============================================================
  // READ NUMBER
  // ============================================================

  static double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim());
    }

    return null;
  }

  // ============================================================
  // READ LOCATION
  // Supports GeoPoint and Map.
  // ============================================================

  factory GarageItem.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    double? latitude;
    double? longitude;

    String placeName = '';

    // Your registration saves:
    // location: currentLocation?.toMap()

    final rawLocation = data['location'];

    if (rawLocation is GeoPoint) {
      latitude = rawLocation.latitude;
      longitude = rawLocation.longitude;
    } else if (rawLocation is Map) {
      final location =
          Map<String, dynamic>.from(rawLocation);

      latitude = _readDouble(
        location['latitude'] ??
            location['lat'],
      );

      longitude = _readDouble(
        location['longitude'] ??
            location['lng'] ??
            location['lon'],
      );

      placeName =
          location['placeName']?.toString() ??
          location['address']?.toString() ??
          location['locationAddress']?.toString() ??
          '';
    }

    // Support currentLocation too, if older profiles
    // saved their location under that field.
    final rawCurrentLocation =
        data['currentLocation'];

    if (latitude == null || longitude == null) {
      if (rawCurrentLocation is GeoPoint) {
        latitude = rawCurrentLocation.latitude;
        longitude = rawCurrentLocation.longitude;
      } else if (rawCurrentLocation is Map) {
        final location =
            Map<String, dynamic>.from(rawCurrentLocation);

        latitude ??= _readDouble(
          location['latitude'] ??
              location['lat'],
        );

        longitude ??= _readDouble(
          location['longitude'] ??
              location['lng'] ??
              location['lon'],
        );

        if (placeName.isEmpty) {
          placeName =
              location['placeName']?.toString() ??
              location['address']?.toString() ??
              location['locationAddress']?.toString() ??
              '';
        }
      }
    }

    // Fallback to separate coordinate fields.
    latitude ??= _readDouble(data['latitude']);
    longitude ??= _readDouble(data['longitude']);

    // Fallback to separate address field.
    if (placeName.isEmpty) {
      placeName =
          data['placeName']?.toString() ??
          data['locationAddress']?.toString() ??
          data['address']?.toString() ??
          '';
    }

    final rawCategories = data['categories'];

    final List<String> categories =
        rawCategories is List
            ? rawCategories
                .whereType<String>()
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
            : <String>[];

    return GarageItem(
      uid: data['uid']?.toString() ?? documentId,

      ownerName:
          data['ownerName']?.toString() ?? '',

      garageName:
          data['garageName']?.toString() ?? '',

      secondaryPhone:
          data['secondaryPhone']?.toString() ?? '',

      placeName: placeName,

      profilePhotoUrl:
          data['profilePhotoUrl']?.toString() ?? '',

      categories: categories,

      isOpen24Hours:
          data['isOpen24Hours'] == true,

      openingTime:
          data['openingTime']?.toString() ?? '',

      closingTime:
          data['closingTime']?.toString() ?? '',

      latitude: latitude,
      longitude: longitude,
    );
  }
}
