// ================================================================
// RENTAL PROFILE SCREEN
// PART 1 / 3
//
// Shows:
// - Rental name / company
// - Rental category
// - Distance
// - Location
// - Call
// - Directions
// - Chat
//
// Firestore collection:
// rentals
// ================================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:url_launcher/url_launcher.dart';

class RentalProfileScreen extends StatefulWidget {
  final String rentalId;

  // Optional values allow this screen to be opened directly
  // from a rental card without having to reload everything.
  final String? username;
  final String? companyName;
  final String? phoneNumber;
  final List<String>? categories;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  const RentalProfileScreen({
    super.key,
    required this.rentalId,
    this.username,
    this.companyName,
    this.phoneNumber,
    this.categories,
    this.latitude,
    this.longitude,
    this.distanceKm,
  });

  @override
  State<RentalProfileScreen> createState() =>
      _RentalProfileScreenState();
}

class _RentalProfileScreenState
    extends State<RentalProfileScreen> {

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

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _loading = true;

  String? _errorMessage;

  // ==============================================================
  // LOCATION
  // ==============================================================

  double? _latitude;

  double? _longitude;

  double? _distanceKm;

  // ==============================================================
  // PROFILE DATA
  // ==============================================================

  String _username = '';

  String _companyName = '';

  String _phoneNumber = '';

  String _secondaryPhoneNumber = '';

  List<String> _categories = [];

  // ==============================================================
  // LIFECYCLE
  // ==============================================================

  @override
  void initState() {
    super.initState();

    _loadRentalProfile();
  }

  // ==============================================================
  // LOAD RENTAL PROFILE
  // ==============================================================

  Future<void> _loadRentalProfile() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await _firestore
              .collection('rentals')
              .doc(widget.rentalId)
              .get();

      if (!snapshot.exists ||
          snapshot.data() == null) {
        // If complete data was supplied through the constructor,
        // allow the profile to still display.
        if (widget.username != null) {
          _usePassedData();

          if (!mounted) return;

          setState(() {
            _loading = false;
          });

          return;
        }

        if (!mounted) return;

        setState(() {
          _loading = false;
          _errorMessage =
              'Rental profile not found.';
        });

        return;
      }

      final Map<String, dynamic> data =
          snapshot.data()!;

      _username =
          (data['username'] ?? '').toString();

      _companyName =
          (data['companyName'] ?? '').toString();

    _phoneNumber =
    (data['phoneNumber'] ?? '').toString();

_secondaryPhoneNumber =
    (data['secondaryPhoneNumber'] ?? '').toString();

      _categories =
          _readCategories(data['categories']);

      _readLocation(data);

      // If a distance was already supplied,
      // prefer it.
      if (widget.distanceKm != null) {
        _distanceKm =
            widget.distanceKm;
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      // Use passed data as a fallback.
      if (widget.username != null) {
        _usePassedData();

        setState(() {
          _loading = false;
        });

        return;
      }

      setState(() {
        _loading = false;
        _errorMessage =
            'Unable to load rental profile.';
      });
    }
  }

  // ==============================================================
  // USE PASSED DATA
  // ==============================================================

  void _usePassedData() {
    _username =
        widget.username ?? '';

    _companyName =
        widget.companyName ?? '';

    _phoneNumber =
        widget.phoneNumber ?? '';

    _categories =
        widget.categories ?? [];

    _latitude =
        widget.latitude;

    _longitude =
        widget.longitude;

    _distanceKm =
        widget.distanceKm;
  }

  // ==============================================================
  // READ CATEGORIES
  // ==============================================================

  List<String> _readCategories(
    dynamic value,
  ) {
    if (value is List) {
      return value
          .map(
            (item) => item.toString(),
          )
          .where(
            (item) => item.trim().isNotEmpty,
          )
          .toList();
    }

    if (value is String &&
        value.trim().isNotEmpty) {
      return [value.trim()];
    }

    return [];
  }

void _readLocation(Map<String, dynamic> data) {
  final dynamic currentLocation = data['currentLocation'];

  if (currentLocation is Map) {
    _latitude ??= _toDouble(
      currentLocation['latitude'],
    );

    _longitude ??= _toDouble(
      currentLocation['longitude'],
    );
  }

  final dynamic location = data['location'];

  if (location is Map) {
    _latitude ??= _toDouble(
      location['latitude'],
    );

    _longitude ??= _toDouble(
      location['longitude'],
    );
  }

  _latitude ??= _toDouble(data['latitude']);
  _longitude ??= _toDouble(data['longitude']);
}

  // ==============================================================
  // DOUBLE CONVERTER
  // ==============================================================

  double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  // ==============================================================
  // DISPLAY NAME
  // ==============================================================

  String get _displayName {
    if (_companyName.trim().isNotEmpty) {
      return _companyName.trim();
    }

    if (_username.trim().isNotEmpty) {
      return _username.trim();
    }

    return 'Rental Service';
  }

  // ==============================================================
  // CATEGORY TEXT
  // ==============================================================

  String get _categoryText {
    if (_categories.isEmpty) {
      return 'Rental Service';
    }

    return _categories.join(' • ');
  }

  // ==============================================================
  // LOCATION AVAILABLE
  // ==============================================================

  bool get _hasLocation {
    return _latitude != null &&
        _longitude != null;
  }

  // ==============================================================
  // PHONE AVAILABLE
  // ==============================================================
bool get _hasPhone {
  return _secondaryPhoneNumber
      .replaceAll(RegExp(r'[^0-9]'), '')
      .isNotEmpty;
}

  // ==============================================================
  // DISTANCE TEXT
  // ==============================================================

  String get _distanceText {
    if (_distanceKm == null) {
      return 'Distance unavailable';
    }

    if (_distanceKm! < 1) {
      return '${(_distanceKm! * 1000).round()} m away';
    }

    return '${_distanceKm!.toStringAsFixed(1)} km away';
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

      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _errorMessage != null
                ? _buildError()
                : _buildProfile(),
      ),
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
        padding:
            const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration:
                  BoxDecoration(
                color:
                    Colors.red.withValues(alpha: 
                  0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .business_center_outlined,
                size: 40,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              _errorMessage ??
                  'Unable to load profile.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
                color: darkGreen,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed:
                  _loadRentalProfile,
              icon: const Icon(
                Icons.refresh,
              ),
              label:
                  const Text('Retry'),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // PROFILE
  // ==============================================================

  Widget _buildProfile() {
    return CustomScrollView(
      slivers: [

        // ----------------------------------------------------------
        // APP BAR
        // ----------------------------------------------------------

        SliverAppBar(
          pinned: true,
          elevation: 0,
          backgroundColor:
              Colors.white,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back,
              color: darkGreen,
            ),
          ),
          title: const Text(
            'Rental Profile',
            style: TextStyle(
              color: darkGreen,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),

        // ----------------------------------------------------------
        // BODY
        // ----------------------------------------------------------

        SliverPadding(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            35,
          ),
          sliver:
              SliverList(
            delegate:
                SliverChildListDelegate(
              [

                _buildProfileHeader(),

                const SizedBox(
                  height: 18,
                ),

                _buildCategoryCard(),

                const SizedBox(
                  height: 14,
                ),

                _buildLocationCard(),

                const SizedBox(
                  height: 22,
                ),

                _buildActionButtons(),

                const SizedBox(
                  height: 20,
                ),

                _buildInformationCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
  // ================================================================
// RENTAL PROFILE SCREEN
// PART 2 / 3
//
// Profile UI
// Categories
// Location
// Action buttons
// ================================================================

// ==============================================================
// PROFILE HEADER
// ==============================================================

Widget _buildProfileHeader() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),

    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          darkGreen,
          green,
        ],
      ),

      borderRadius:
          BorderRadius.circular(24),

      boxShadow: [
        BoxShadow(
          color:
              darkGreen.withValues(alpha: 0.20),
          blurRadius: 14,
          offset:
              const Offset(0, 6),
        ),
      ],
    ),

    child: Column(
      children: [

        // ----------------------------------------------------------
        // RENTAL ICON
        // ----------------------------------------------------------

        Container(
          width: 92,
          height: 92,

          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,

            border: Border.all(
              color:
                  Colors.white.withValues(alpha: 
                0.85,
              ),
              width: 3,
            ),
          ),

          child: const Icon(
            Icons
                .directions_car_filled,
            size: 46,
            color: darkGreen,
          ),
        ),

        const SizedBox(
          height: 15,
        ),

        // ----------------------------------------------------------
        // NAME
        // ----------------------------------------------------------

        Text(
          _displayName,

          textAlign: TextAlign.center,

          maxLines: 2,

          overflow:
              TextOverflow.ellipsis,

          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        // ----------------------------------------------------------
        // CATEGORY
        // ----------------------------------------------------------

        Text(
          _categoryText,

          textAlign: TextAlign.center,

          maxLines: 3,

          overflow:
              TextOverflow.ellipsis,

          style: TextStyle(
            color: Colors.white
                .withValues(alpha: .90),
            fontSize: 14,
            fontWeight:
                FontWeight.w500,
          ),
        ),

        const SizedBox(
          height: 15,
        ),

        // ----------------------------------------------------------
        // DISTANCE
        // ----------------------------------------------------------

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 8,
          ),

          decoration: BoxDecoration(
            color: Colors.white
                .withValues(alpha: 0.14),

            borderRadius:
                BorderRadius.circular(
              30,
            ),
          ),

          child: Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                size: 17,
                color: Colors.white,
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                _distanceText,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ==============================================================
// CATEGORY CARD
// ==============================================================

Widget _buildCategoryCard() {
  return Container(
    width: double.infinity,

    padding:
        const EdgeInsets.all(17),

    decoration:
        _cardDecoration(),

    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        const Row(
          children: [
            Icon(
              Icons.category_outlined,
              color: green,
              size: 23,
            ),
            SizedBox(width: 9),
            Text(
              'Rental Categories',
              style: TextStyle(
                color: darkGreen,
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 14,
        ),

        if (_categories.isEmpty)
          const Text(
            'Rental services available',
            style: TextStyle(
              color: Colors.grey,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _categories.map(
              (category) {
                return Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),

                  decoration:
                      BoxDecoration(
                    color: green
                        .withValues(alpha: 
                      0.09,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),

                    border: Border.all(
                      color: green
                          .withValues(alpha: 
                        0.25,
                      ),
                    ),
                  ),

                  child: Text(
                    category,
                    style:
                        const TextStyle(
                      color: darkGreen,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                );
              },
            ).toList(),
          ),
      ],
    ),
  );
}

// ==============================================================
// LOCATION CARD
// ==============================================================

Widget _buildLocationCard() {
  return Container(
    width: double.infinity,

    padding:
        const EdgeInsets.all(17),

    decoration:
        _cardDecoration(),

    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        const Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: orange,
              size: 24,
            ),
            SizedBox(width: 9),
            Text(
              'Rental Location',
              style: TextStyle(
                color: darkGreen,
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 13,
        ),

        Container(
          width: double.infinity,

          padding:
              const EdgeInsets.all(13),

          decoration:
              BoxDecoration(
            color:
                const Color(0xFFF8F5EE),
            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Container(
                width: 40,
                height: 40,

                decoration:
                    BoxDecoration(
                  color:
                      orange.withValues(alpha: 
                    0.12,
                  ),
                  shape:
                      BoxShape.circle,
                ),

                child: const Icon(
                  Icons.place,
                  color: orange,
                  size: 22,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Text(
                      _hasLocation
                          ? 'Location available'
                          : 'Location unavailable',

                      style:
                          const TextStyle(
                        color: darkGreen,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    if (_hasLocation)
                      Text(
                        'Coordinates available for directions.',
                        style:
                            const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      )
                    else
                      const Text(
                        'This rental has not provided a location.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (_hasLocation) ...[
          const SizedBox(
            height: 12,
          ),

          // --------------------------------------------------------
          // DIRECTIONS BUTTON
          // --------------------------------------------------------

          SizedBox(
            width: double.infinity,
            height: 47,

            child:
                OutlinedButton.icon(
              onPressed:
                  _openDirections,

              icon: const Icon(
                Icons.directions,
                color: green,
              ),

              label: const Text(
                'Open Location in Maps',
                style: TextStyle(
                  color: green,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              style:
                  OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: green,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

// ==============================================================
// ACTION BUTTONS
// ==============================================================

Widget _buildActionButtons() {
  return Row(
    children: [

      // ------------------------------------------------------------
      // CALL
      // ------------------------------------------------------------

      Expanded(
        child: _buildActionButton(
          icon: Icons.phone,
          title: 'Call',
          color: green,
          onTap:
              _callRental,
          enabled: _hasPhone,
        ),
      ),

      const SizedBox(
        width: 10,
      ),

      // ------------------------------------------------------------
      // CHAT
      // ------------------------------------------------------------

      Expanded(
        child: _buildActionButton(
          icon: Icons.chat_bubble_outline,
          title: 'Chat',
          color: darkGreen,
          onTap:
              _openChat,
          enabled: true,
        ),
      ),
    ],
  );
}

// ==============================================================
// ACTION BUTTON
// ==============================================================

Widget _buildActionButton({
  required IconData icon,
  required String title,
  required Color color,
  required VoidCallback onTap,
  required bool enabled,
}) {
  return SizedBox(
    height: 58,

    child: ElevatedButton(
      onPressed:
          enabled ? onTap : null,

      style:
          ElevatedButton.styleFrom(
        backgroundColor:
            enabled
                ? color
                : Colors.grey.shade400,

        foregroundColor:
            Colors.white,

        elevation: 2,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
        ),
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [

          Icon(
            icon,
            size: 21,
          ),

          const SizedBox(
            width: 7,
          ),

          Text(
            title,
            style:
                const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

// ==============================================================
// INFORMATION CARD
// ==============================================================

Widget _buildInformationCard() {
  return Container(
    width: double.infinity,

    padding:
        const EdgeInsets.all(17),

    decoration:
        _cardDecoration(),

    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        const Row(
          children: [
            Icon(
              Icons.info_outline,
              color: green,
              size: 23,
            ),
            SizedBox(width: 9),
            Text(
              'Rental Information',
              style: TextStyle(
                color: darkGreen,
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 15,
        ),

        _buildInfoRow(
          Icons.business_outlined,
          'Rental',
          _displayName,
        ),

        const Divider(
          height: 22,
        ),

        _buildInfoRow(
          Icons.category_outlined,
          'Category',
          _categoryText,
        ),

        const Divider(
          height: 22,
        ),

        _buildInfoRow(
          Icons.location_on_outlined,
          'Distance',
          _distanceText,
        ),
      ],
    ),
  );
}

// ==============================================================
// INFORMATION ROW
// ==============================================================

Widget _buildInfoRow(
  IconData icon,
  String title,
  String value,
) {
  return Row(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [

      Icon(
        icon,
        size: 21,
        color: green,
      ),

      const SizedBox(
        width: 12,
      ),

      SizedBox(
        width: 75,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ),

      const SizedBox(
        width: 8,
      ),

      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: darkGreen,
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

// ==============================================================
// CARD DECORATION
// ==============================================================

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,

    borderRadius:
        BorderRadius.circular(18),

    border: Border.all(
      color: Colors.grey
          .withValues(alpha: 0.12),
    ),

    boxShadow: [
      BoxShadow(
        color: Colors.black
            .withValues(alpha: 0.045),
        blurRadius: 10,
        offset:
            const Offset(0, 4),
      ),
    ],
  );
}
// ================================================================
// RENTAL PROFILE SCREEN
// PART 3 / 3
//
// Call
// Google Maps
// Chat integration
// Helper methods
// ================================================================

// ==============================================================
// CALL RENTAL
// ==============================================================
Future<void> _callRental() async {
  final String phone = _secondaryPhoneNumber
      .replaceAll(RegExp(r'[^0-9+]'), '')
      .trim();

  if (phone.isEmpty) {
    _showMessage(
      'Secondary phone number is not available.',
      isError: true,
    );
    return;
  }

  final Uri phoneUri = Uri(
    scheme: 'tel',
    path: phone,
  );

  try {
    final bool launched = await launchUrl(
      phoneUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      _showMessage(
        'Unable to open phone dialer.',
        isError: true,
      );
    }
  } catch (e) {
    _showMessage(
      'Unable to open phone dialer.',
      isError: true,
    );
  }
}

// ==============================================================
// OPEN GOOGLE MAPS
// ==============================================================

Future<void> _openDirections() async {
  if (!_hasLocation) {
    _showMessage(
      'Rental location is not available.',
      isError: true,
    );
    return;
  }

  final double lat =
      _latitude!;

  final double lng =
      _longitude!;

  // --------------------------------------------------------------
  // Google Maps URL
  // --------------------------------------------------------------

  final Uri mapsUri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=$lat,$lng',
  );

  try {
    final bool launched =
        await launchUrl(
      mapsUri,
      mode:
          LaunchMode.externalApplication,
    );

    if (!launched) {
      _showMessage(
        'Unable to open Google Maps.',
        isError: true,
      );
    }
  } catch (e) {
    _showMessage(
      'Unable to open Google Maps.',
      isError: true,
    );
  }
}

void _openChat() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ScreenMessage(
  chatUser: {
    // Rental ID
    'uid': widget.rentalId,

    // User details
    'username': _username,
    'name': _displayName,

    // Rental / company name
    'companyName': _companyName,
    'businessName': _companyName,

    // Phone
    'phoneNumber': _phoneNumber,

    // Category
    'profession': _categoryText,

    // Experience
    //'experience': '',

    // Distance
    'distance': _distanceKm ?? 0.0,

    // Status
    'isActive': true,

    // Role
    'role': 'rental',

    // Location coordinates
    'latitude': _latitude,
    'longitude': _longitude,

    // Location name displayed in chat header
    'locationName': 'Current Location',
  },
),
    ),
  );
}

// ==============================================================
// SHOW MESSAGE
// ==============================================================

void _showMessage(
  String message, {
  bool isError = false,
}) {
  if (!mounted) return;

  ScaffoldMessenger.of(context)
      .hideCurrentSnackBar();

  ScaffoldMessenger.of(context)
      .showSnackBar(
    SnackBar(
      content: Text(message),

      backgroundColor:
          isError
              ? Colors.red
              : green,

      behavior:
          SnackBarBehavior.floating,

      margin:
          const EdgeInsets.all(16),

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
    ),
  );
}

@override
void dispose() {
  super.dispose();
}
}

// ================================================================
// END OF RENTAL PROFILE SCREEN
// ================================================================