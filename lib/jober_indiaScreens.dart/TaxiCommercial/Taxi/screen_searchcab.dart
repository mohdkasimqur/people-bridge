import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jober_india/jober_indiaScreens.dart/TaxiCommercial/Taxi/screen_taxi_profile.dart';


class ScreenCabSearch extends StatefulWidget {
  final String vehicleType;
  final String vehicleCategory;

  const ScreenCabSearch({
    super.key,
    required this.vehicleType,
    required this.vehicleCategory,
  });

  @override
  State<ScreenCabSearch> createState() =>
      _ScreenCabSearchState();
}

// ============================================================
// DRIVER MODEL
// ============================================================

class LiveCabDriver {
  final String uid;
  final String name;
  final String vehicleType;
  final String vehicle;
  final String vehicleName;
  final String vehicleNumber;
  final String profilePhotoUrl;
  final String secondaryPhone;

  final double latitude;
  final double longitude;
  final double distanceKm;

  final DateTime updatedAt;

  final Map<String, dynamic> rawData;

  const LiveCabDriver({
    required this.uid,
    required this.name,
    required this.vehicleType,
    required this.vehicle,
    required this.vehicleName,
    required this.vehicleNumber,
    required this.profilePhotoUrl,
    required this.secondaryPhone,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.updatedAt,
    required this.rawData,
  });
}

// ============================================================
// STATE
// ============================================================

class _ScreenCabSearchState
    extends State<ScreenCabSearch> {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final TextEditingController pickupController =
      TextEditingController();

  final TextEditingController dropoffController =
      TextEditingController();

  bool isSearching = false;
  bool isSendingRideRequest = false;

  bool hasSearched = false;

  Position? currentPosition;

  List<LiveCabDriver> allDrivers = [];

  // ----------------------------------------------------------
  // PAGINATION
  // ----------------------------------------------------------

  static const int driversPerPage = 10;

  int visibleDriverCount = driversPerPage;

  // ----------------------------------------------------------
  // HOW MANY DRIVERS RECEIVE THE REQUEST
  // ----------------------------------------------------------

  static const int maxDriversToNotify = 10;

  // ----------------------------------------------------------
  // RIDE REQUEST CREATED
  // ----------------------------------------------------------

  String? createdRideRequestId;

  @override
  void dispose() {
    pickupController.dispose();
    dropoffController.dispose();
    super.dispose();
  }

  // ==========================================================
  // GET TODAY START
  // ==========================================================

  DateTime _startOfToday() {
    final DateTime now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  // ==========================================================
  // LOCATION PERMISSION
  // ==========================================================

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return false;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Location is turned off',
            ),
            content: const Text(
              'Please turn on your phone location to find nearby drivers.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission is required.',
          ),
        ),
      );

      return false;
    }

    if (permission ==
        LocationPermission.deniedForever) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission is permanently denied. Please enable it from Settings.',
          ),
        ),
      );

      return false;
    }

    return true;
  }

  // ==========================================================
  // GET CURRENT LOCATION
  // ==========================================================

  Future<Position?> _getCurrentPosition() async {
    final bool allowed =
        await _checkLocationPermission();

    if (!allowed) {
      return null;
    }

    try {
      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return position;
    } catch (e) {
      debugPrint(
        'Error getting customer location: $e',
      );

      if (!mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not get your current location.',
          ),
        ),
      );

      return null;
    }
  }

  // ==========================================================
  // SEARCH CABS
  // ==========================================================

  Future<void> searchCabs() async {
    if (isSearching) {
      return;
    }

    FocusScope.of(context).unfocus();

    final String pickup =
        pickupController.text.trim();

    final String dropoff =
        dropoffController.text.trim();

    // --------------------------------------------------------
    // VALIDATION
    // --------------------------------------------------------

    if (pickup.isEmpty) {
      _showMessage(
        'Please enter the pickup point.',
      );
      return;
    }

    if (dropoff.isEmpty) {
      _showMessage(
        'Please enter the drop-off point.',
      );
      return;
    }

    final User? customer =
        _auth.currentUser;

    if (customer == null) {
      _showMessage(
        'Please login before searching for a cab.',
      );
      return;
    }

    setState(() {
      isSearching = true;
      hasSearched = true;
      allDrivers = [];
      visibleDriverCount = driversPerPage;
      createdRideRequestId = null;
    });

    try {
      // ------------------------------------------------------
      // CUSTOMER LOCATION
      // ------------------------------------------------------

      final Position? position =
          await _getCurrentPosition();

      if (position == null) {
        return;
      }

      currentPosition = position;

      // ------------------------------------------------------
      // TODAY
      // ------------------------------------------------------

      final DateTime startOfToday =
          _startOfToday();

      // ------------------------------------------------------
      // LIVE DRIVERS
      //
      // We intentionally query isLive only and filter:
      // role/date/type/category on the device.
      //
      // This avoids requiring a large composite Firestore
      // index for this first implementation.
      // ------------------------------------------------------

      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection('liveLocations')
              .where(
                'isLive',
                isEqualTo: true,
              )
              .get();

      final List<LiveCabDriver> foundDrivers = [];

      for (final QueryDocumentSnapshot<
              Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data =
            doc.data();

        // ----------------------------------------------------
        // ROLE
        // ----------------------------------------------------

        final String role =
            data['role']?.toString().trim() ?? '';

        if (role != 'taxi_commercial') {
          continue;
        }

        // ----------------------------------------------------
        // UPDATED AT
        // ----------------------------------------------------

        final dynamic updatedValue =
            data['updatedAt'];

        DateTime? updatedAt;

        if (updatedValue is Timestamp) {
          updatedAt =
              updatedValue.toDate();
        } else if (updatedValue is DateTime) {
          updatedAt = updatedValue;
        }

        if (updatedAt == null) {
          continue;
        }

        // ----------------------------------------------------
        // ONLY TODAY
        // ----------------------------------------------------

        if (updatedAt.isBefore(startOfToday)) {
          continue;
        }

        // ----------------------------------------------------
        // VEHICLE TYPE
        // ----------------------------------------------------

        final String vehicleType =
            data['vehicleType']?.toString().trim() ?? '';

        if (vehicleType.toLowerCase() !=
            widget.vehicleType
                .trim()
                .toLowerCase()) {
          continue;
        }

        // ----------------------------------------------------
        // VEHICLE CATEGORY
        // ----------------------------------------------------

        final String vehicle =
            data['vehicle']?.toString().trim() ?? '';

        if (vehicle.toLowerCase() !=
            widget.vehicleCategory
                .trim()
                .toLowerCase()) {
          continue;
        }

        // ----------------------------------------------------
        // UID
        // ----------------------------------------------------

        final String uid =
            data['uid']?.toString().trim().isNotEmpty == true
                ? data['uid'].toString().trim()
                : doc.id;

        if (uid.isEmpty) {
          continue;
        }

        // ----------------------------------------------------
        // LATITUDE / LONGITUDE
        // ----------------------------------------------------

        final double? driverLatitude =
            _toDouble(data['latitude']);

        final double? driverLongitude =
            _toDouble(data['longitude']);

        if (driverLatitude == null ||
            driverLongitude == null) {
          continue;
        }

        // ----------------------------------------------------
        // DISTANCE
        // ----------------------------------------------------

        final double distanceMeters =
            Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          driverLatitude,
          driverLongitude,
        );

        final double distanceKm =
            distanceMeters / 1000.0;

        // ----------------------------------------------------
        // MAXIMUM 50 KM
        // ----------------------------------------------------

        if (distanceKm > 50.0) {
          continue;
        }

        // ----------------------------------------------------
        // DRIVER DETAILS
        // ----------------------------------------------------

        final String name =
            data['name']?.toString().trim() ??
                'Driver';

        final String vehicleName =
            data['vehicleName']?.toString().trim() ??
                '';

        final String vehicleNumber =
            data['vehicleNumber']?.toString().trim() ??
                '';

        final String profilePhotoUrl =
            data['profilePhotoUrl']
                    ?.toString()
                    .trim() ??
                '';

        final String secondaryPhone =
            data['secondaryPhone']
                    ?.toString()
                    .trim() ??
                '';

        foundDrivers.add(
          LiveCabDriver(
            uid: uid,
            name: name.isEmpty
                ? 'Driver'
                : name,
            vehicleType: vehicleType,
            vehicle: vehicle,
            vehicleName: vehicleName,
            vehicleNumber: vehicleNumber,
            profilePhotoUrl:
                profilePhotoUrl,
            secondaryPhone:
                secondaryPhone,
            latitude: driverLatitude,
            longitude: driverLongitude,
            distanceKm: distanceKm,
            updatedAt: updatedAt,
            rawData: data,
          ),
        );
      }

      // ------------------------------------------------------
      // NEAREST FIRST
      // ------------------------------------------------------

      foundDrivers.sort(
        (a, b) => a.distanceKm.compareTo(
          b.distanceKm,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        allDrivers = foundDrivers;
        visibleDriverCount =
            math.min(
          driversPerPage,
          allDrivers.length,
        );
      });

      if (foundDrivers.isEmpty) {
        _showMessage(
          'No live ${widget.vehicleCategory} drivers found within 50 km.',
        );
      }
    } catch (e) {
      debugPrint(
        'Cab search error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not search for drivers. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    }
  }

  // ==========================================================
  // LOAD MORE
  // ==========================================================

  void loadMoreDrivers() {
    if (visibleDriverCount >= allDrivers.length) {
      return;
    }

    setState(() {
      visibleDriverCount =
          math.min(
        visibleDriverCount + driversPerPage,
        allDrivers.length,
      );
    });
  }

  // ==========================================================
  // CONVERT NUMBER
  // ==========================================================

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  // ==========================================================
  // CREATE RIDE REQUEST
  // ==========================================================

  Future<void> _createRideRequest() async {
    if (isSendingRideRequest) {
      return;
    }

    if (allDrivers.isEmpty) {
      _showMessage(
        'There are no available drivers.',
      );
      return;
    }

    final User? customer =
        _auth.currentUser;

    if (customer == null) {
      _showMessage(
        'Please login again.',
      );
      return;
    }

    final String pickup =
        pickupController.text.trim();

    final String dropoff =
        dropoffController.text.trim();

    if (pickup.isEmpty ||
        dropoff.isEmpty) {
      _showMessage(
        'Please enter pickup and drop-off.',
      );
      return;
    }

    setState(() {
      isSendingRideRequest = true;
    });

    try {
      // ------------------------------------------------------
      // ONLY NEAREST DRIVERS RECEIVE THE REQUEST
      // ------------------------------------------------------

      final List<LiveCabDriver> targetDrivers =
          allDrivers
              .take(maxDriversToNotify)
              .toList();

      // ------------------------------------------------------
      // CREATE ONE PARENT RIDE
      //
      // This is the master ride request.
      // Only ONE driver will be able to change it from
      // pending -> accepted.
      // ------------------------------------------------------

      final DocumentReference<
          Map<String, dynamic>> rideRef =
          _firestore
              .collection('rideRequests')
              .doc();

      final String requestId =
          rideRef.id;

      final Position? customerPosition =
          currentPosition;

      await rideRef.set(
        {
          'requestId': requestId,

          'type': 'ride_request',

          'customerUid': customer.uid,

          'vehicleType':
              widget.vehicleType,

          'vehicle':
              widget.vehicleCategory,

          'pickupText': pickup,

          'dropoffText': dropoff,

          'customerLatitude':
              customerPosition?.latitude,

          'customerLongitude':
              customerPosition?.longitude,

          'status': 'pending',

          'createdAt':
              FieldValue.serverTimestamp(),

          'driverCount':
              targetDrivers.length,
        },
      );

      // ------------------------------------------------------
      // CREATE ONE DRIVER REQUEST FOR EACH TARGET DRIVER
      // ------------------------------------------------------

      final WriteBatch batch =
          _firestore.batch();

      for (final LiveCabDriver driver
          in targetDrivers) {

        final DocumentReference<
                Map<String, dynamic>>
            driverRequestRef =
            rideRef
                .collection('driverRequests')
                .doc(driver.uid);

        batch.set(
          driverRequestRef,
          {
            'requestId': requestId,

            'type': 'ride_request',

            'customerUid':
                customer.uid,

            'driverUid':
                driver.uid,

            'vehicleType':
                widget.vehicleType,

            'vehicle':
                widget.vehicleCategory,

            'pickupText':
                pickup,

            'dropoffText':
                dropoff,

            'customerLatitude':
                customerPosition?.latitude,

            'customerLongitude':
                customerPosition?.longitude,

            'driverLatitude':
                driver.latitude,

            'driverLongitude':
                driver.longitude,

            'distanceKm':
                driver.distanceKm,

            'status': 'pending',

            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      if (!mounted) {
        return;
      }

      setState(() {
        createdRideRequestId =
            requestId;
      });

      _showRideRequestSentDialog(
        targetDrivers.length,
      );
    } catch (e) {
      debugPrint(
        'Ride request error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not send ride request.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSendingRideRequest = false;
        });
      }
    }
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ==========================================================
  // RIDE REQUEST DIALOG
  // ==========================================================

  void _showRideRequestSentDialog(
    int driverCount,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.local_taxi,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                'Ride Request Sent',
              ),
            ],
          ),
          content: Text(
            driverCount == 1
                ? 'Your ride request was sent to the nearest available driver.'
                : 'Your ride request was sent to $driverCount nearby drivers.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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
  // ==========================================================
  // OPEN DRIVER PROFILE
  // ==========================================================

  void _openDriverProfile(
    LiveCabDriver driver,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ScreenTaxiCommercialProfile(
          driver: {
            'uid': driver.uid,
            'name': driver.name,
            'vehicleType':
                driver.vehicleType,
            'vehicle':
                driver.vehicle,
            'vehicleName':
                driver.vehicleName,
            'vehicleNumber':
                driver.vehicleNumber,
            'profilePhotoUrl':
                driver.profilePhotoUrl,
            'secondaryPhone':
                driver.secondaryPhone,
            'latitude':
                driver.latitude,
            'longitude':
                driver.longitude,
            'distanceKm':
                driver.distanceKm,
            ...driver.rawData,
          },
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final List<LiveCabDriver> visibleDrivers =
        allDrivers
            .take(visibleDriverCount)
            .toList();

    final bool hasMore =
        visibleDriverCount <
            allDrivers.length;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black,
        elevation: 0,

        title: Text(
          widget.vehicleCategory,
          style: const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
  child: Column(
    children: [

      // ==================================================
      // SEARCH SECTION
      // ==================================================

      Flexible(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            16,
            14,
            16,
            8,
          ),
          child: _buildSearchBox(),
        ),
      ),

      // ==================================================
      // RESULTS
      // ==================================================

      Expanded(
        child: _buildResults(
          visibleDrivers,
          hasMore,
        ),
      ),
    ],
  ),
),
    );
  }

  // ==========================================================
  // SEARCH BOX
  // ==========================================================

  Widget _buildSearchBox() {
    return Container(
      padding:
          const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.05),
            blurRadius: 10,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // --------------------------------------------------
          // TITLE
          // --------------------------------------------------

          Row(
            children: [
              Container(
                width: 38,
                height: 38,

                decoration:
                    BoxDecoration(
                  color: Colors.red
                      .withValues(alpha: 0.10),
                  shape:
                      BoxShape.circle,
                ),

                child: const Icon(
                  Icons.local_taxi_outlined,
                  color: Colors.red,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search ${widget.vehicleCategory}',
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Find live drivers within 50 km',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors
                            .grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // --------------------------------------------------
          // PICKUP
          // --------------------------------------------------

          _buildLocationField(
            controller:
                pickupController,
            hint:
                'Enter pickup location',
            icon:
                Icons.my_location,
            iconColor:
                Colors.green,
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------
          // DROP-OFF
          // --------------------------------------------------

          _buildLocationField(
            controller:
                dropoffController,
            hint:
                'Enter drop-off location',
            icon:
                Icons.location_on,
            iconColor:
                Colors.red,
          ),

          const SizedBox(height: 12),

          // --------------------------------------------------
          // SEARCH BUTTON
          // --------------------------------------------------

          SizedBox(
            width: double.infinity,
            height: 50,

            child: ElevatedButton(
              onPressed:
                  isSearching
                      ? null
                      : searchCabs,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,

                disabledBackgroundColor:
                    Colors.red
                        .withValues(alpha: 0.55),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                elevation: 0,
              ),

              child: isSearching
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<
                                Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Search Cabs',
                          style:
                              TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // LOCATION FIELD
  // ==========================================================

  Widget _buildLocationField({
    required TextEditingController
        controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return TextField(
      controller: controller,

      textInputAction:
          TextInputAction.next,

      decoration:
          InputDecoration(
        hintText: hint,

        prefixIcon: Icon(
          icon,
          color: iconColor,
          size: 21,
        ),

        filled: true,

        fillColor:
            const Color(0xFFF8F8F8),

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),
          borderSide:
              BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),
          borderSide:
              BorderSide.none,
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),
          borderSide:
              BorderSide(
            color: Colors.red
                .withValues(alpha: 0.45),
            width: 1.3,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // RESULTS
  // ==========================================================

  Widget _buildResults(
    List<LiveCabDriver> drivers,
    bool hasMore,
  ) {
    if (!hasSearched) {
      return _buildInitialState();
    }

    if (isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (allDrivers.isEmpty) {
      return _buildNoDriversState();
    }

    return RefreshIndicator(
      onRefresh: searchCabs,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24,
        ),

        children: [

          // --------------------------------------------------
          // RESULT HEADER
          // --------------------------------------------------

          Row(
            children: [

              Expanded(
                child: Text(
                  'Available ${widget.vehicleCategory} Drivers',
                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.red
                      .withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: Text(
                  '${allDrivers.length}',
                  style:
                      const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            'Nearest drivers are shown first',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 12),

          // --------------------------------------------------
          // DRIVER CARDS
          // --------------------------------------------------

          ...drivers.map(
            (driver) =>
                _buildDriverCard(driver),
          ),

          // --------------------------------------------------
          // PAGINATION
          // --------------------------------------------------

          if (hasMore) ...[
            const SizedBox(height: 8),

            SizedBox(
              height: 46,
              width: double.infinity,

              child: OutlinedButton(
                onPressed:
                    loadMoreDrivers,

                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.red,
                  side:
                      const BorderSide(
                    color: Colors.red,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                ),

                child: Text(
                  'Load More Drivers',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],

          if (!hasMore &&
              allDrivers.length >
                  driversPerPage)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 12,
              ),
              child: Center(
                child: Text(
                  'All nearby drivers shown',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ),
            ),

          // --------------------------------------------------
          // SEND RIDE REQUEST
          // --------------------------------------------------

          const SizedBox(height: 18),

          _buildRideRequestButton(),
        ],
      ),
    );
  }

  // ==========================================================
  // DRIVER CARD
  // ==========================================================

  Widget _buildDriverCard(
    LiveCabDriver driver,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(17),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.04),
            blurRadius: 8,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(17),

        onTap: () {
          _openDriverProfile(driver);
        },

        child: Padding(
          padding:
              const EdgeInsets.all(12),

          child: Row(
            children: [

              // ------------------------------------------------
              // PHOTO
              // ------------------------------------------------

              _buildDriverPhoto(driver),

              const SizedBox(width: 12),

              // ------------------------------------------------
              // DRIVER DETAILS
              // ------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      driver.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      driver.vehicle,
                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    if (driver
                        .vehicleName
                        .isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          top: 2,
                        ),
                        child: Text(
                          driver.vehicleName,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),
                      ),

                    const SizedBox(height: 5),

                    Row(
                      children: [

                        const Icon(
                          Icons
                              .location_on_outlined,
                          size: 15,
                          color: Colors.red,
                        ),

                        const SizedBox(
                          width: 3,
                        ),

                        Text(
                          '${driver.distanceKm.toStringAsFixed(1)} km away',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors
                                .grey
                                .shade700,
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Container(
                          width: 7,
                          height: 7,
                          decoration:
                              const BoxDecoration(
                            color:
                                Colors.green,
                            shape:
                                BoxShape.circle,
                          ),
                        ),

                        const SizedBox(
                          width: 4,
                        ),

                        const Text(
                          'LIVE',
                          style:
                              TextStyle(
                            fontSize: 10,
                            color:
                                Colors.green,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ------------------------------------------------
              // ARROW
              // ------------------------------------------------

              const Icon(
                Icons
                    .chevron_right_rounded,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DRIVER PHOTO
  // ==========================================================

  Widget _buildDriverPhoto(
    LiveCabDriver driver,
  ) {
    if (driver.profilePhotoUrl.isEmpty) {
      return Container(
        width: 62,
        height: 62,

        decoration:
            BoxDecoration(
          color: Colors.red
              .withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),

        child: const Icon(
          Icons.person_outline,
          color: Colors.red,
          size: 31,
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        driver.profilePhotoUrl,

        width: 62,
        height: 62,

        fit: BoxFit.cover,

        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            width: 62,
            height: 62,
            color: Colors.red
                .withValues(alpha: 0.08),
            child: const Icon(
              Icons.person_outline,
              color: Colors.red,
              size: 31,
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // RIDE REQUEST BUTTON
  // ==========================================================

  Widget _buildRideRequestButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,

      child: ElevatedButton.icon(
        onPressed:
            isSendingRideRequest
                ? null
                : _createRideRequest,

        icon: isSendingRideRequest
            ? const SizedBox(
                width: 19,
                height: 19,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    Colors.white,
                  ),
                ),
              )
            : const Icon(
                Icons.local_taxi,
              ),

        label: Text(
          isSendingRideRequest
              ? 'Sending Ride Request...'
              : 'Request a ${widget.vehicleCategory}',
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              Colors.red,
          foregroundColor:
              Colors.white,
          disabledBackgroundColor:
              Colors.red
                  .withValues(alpha: .55),
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // INITIAL STATE
  // ==========================================================

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Container(
              width: 78,
              height: 78,

              decoration:
                  BoxDecoration(
                color: Colors.red
                    .withValues(alpha: .08),
                shape:
                    BoxShape.circle,
              ),

              child: const Icon(
                Icons.local_taxi_outlined,
                size: 40,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Find a nearby driver',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Enter your pickup and drop-off locations, then search for live ${widget.vehicleCategory} drivers.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color:
                    Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // NO DRIVERS
  // ==========================================================

  Widget _buildNoDriversState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Icon(
              Icons
                  .local_taxi_outlined,
              size: 60,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(height: 12),

            const Text(
              'No drivers found',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'No live ${widget.vehicleCategory} drivers were found within 50 km today.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:
                    Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 15),

            OutlinedButton.icon(
              onPressed: searchCabs,

              icon: const Icon(
                Icons.refresh,
              ),

              label: const Text(
                'Search Again',
              ),

              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    Colors.red,
                side:
                    const BorderSide(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
