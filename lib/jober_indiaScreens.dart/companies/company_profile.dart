// ================================================================
// COMPANY PROFILE SCREEN
// PART 1 / 3
// ================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyProfileScreen extends StatefulWidget {
  final String companyId;

  // Optional data allows this screen to open immediately
  // from the Company List Screen.
  final String? companyName;
  final String? phoneNumber;
  final List<String>? categories;
  final String? experience;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final double? userLatitude;
final double? userLongitude;

  const CompanyProfileScreen({
    super.key,
    required this.companyId,
    this.companyName,
    this.phoneNumber,
    this.categories,
    this.experience,
    this.latitude,
    this.longitude,
    this.userLatitude,
this.userLongitude,
    this.distanceKm,
  });

  @override
  State<CompanyProfileScreen> createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState
    extends State<CompanyProfileScreen> {

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

  // ==============================================================
  // LOADING
  // ==============================================================

  bool _loading = true;

  String? _errorMessage;

  // ==============================================================
  // COMPANY DATA
  // ==============================================================

  String _companyName = '';

  String _phoneNumber = '';
  String _secondaryMobile = '';

  String _experience = '';

String _aboutCompany = '';

//bool _isLoadingCall = false;
  List<String> _categories = [];

  // ==============================================================
  // LOCATION
  // ==============================================================

  double? _latitude;

  double? _longitude;

  double? _distanceKm;

  // ==============================================================
  // INIT STATE
  // ==============================================================

  @override
  void initState() {
    super.initState();

    _loadCompanyProfile();
  }

  // ==============================================================
  // LOAD COMPANY PROFILE
  // ==============================================================

  Future<void> _loadCompanyProfile() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await _firestore
              .collection('companies')
              .doc(widget.companyId)
              .get();

      // ------------------------------------------------------------
      // COMPANY NOT FOUND
      // ------------------------------------------------------------

      if (!snapshot.exists ||
          snapshot.data() == null) {
        if (widget.companyName != null) {
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
              'Company profile not found.';
        });

        return;
      }

      final Map<String, dynamic> data =
          snapshot.data()!;

      // ------------------------------------------------------------
      // COMPANY NAME
      // ------------------------------------------------------------

      _companyName =
          (data['companyName'] ??
                  data['name'] ??
                  '')
              .toString()
              .trim();

      // ------------------------------------------------------------
      // PHONE NUMBER
      //
      // Saved internally for the Call button only.
      // It will NEVER be displayed on this profile screen.
      // ------------------------------------------------------------

     // Primary number — keep internally if needed.
_phoneNumber = (
  data['mobile'] ??
  data['phoneNumber'] ??
  data['mobileNumber'] ??
  ''
).toString().trim();

// Secondary number — used by the Call button.
_secondaryMobile = (
  data['secondaryMobile'] ?? ''
).toString().trim();

      // ------------------------------------------------------------
      // EXPERIENCE
      // ------------------------------------------------------------

      // _experience =
      //     (data['experience'] ?? '')
      //         .toString()
      //         .trim();

      // // ------------------------------------------------------------
      // // CATEGORIES
      // // ------------------------------------------------------------

      // _categories = _readCategories(
      //   data['category'] ??
      //       data['categories'],
      // );
      // Read categories as a list first.
// Your Firestore data may contain both "categories" and "category".
_categories = _readCategories(
  data['categories'] ?? data['category'],
);

// Read the company's About text.
_aboutCompany = (
  data['aboutCompany'] ??
  data['about'] ??
  data['description'] ??
  ''
).toString().trim();

      // ------------------------------------------------------------
      // LOCATION
      // ------------------------------------------------------------

      _readLocation(data);

      // ------------------------------------------------------------
      // DISTANCE
      // ------------------------------------------------------------

      // if (widget.distanceKm != null) {
      //   _distanceKm =
      //       widget.distanceKm;
      // }
      if (widget.distanceKm != null) {
  _distanceKm = widget.distanceKm;
}

_calculateCompanyDistance();

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      // ------------------------------------------------------------
      // FALLBACK DATA
      // ------------------------------------------------------------

      if (widget.companyName != null) {
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
            'Unable to load company profile.';
      });
    }
  }

  // ==============================================================
  // USE PASSED DATA
  // ==============================================================

  void _usePassedData() {
    _companyName =
        widget.companyName ?? '';

    _phoneNumber =
        widget.phoneNumber ?? '';

    _experience =
        widget.experience ?? '';

    _categories =
        widget.categories ?? [];
_aboutCompany = '';
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
            (item) => item.toString().trim(),
          )
          .where(
            (item) => item.isNotEmpty,
          )
          .toList();
    }

    if (value is String &&
        value.trim().isNotEmpty) {
      return [
        value.trim(),
      ];
    }

    return [];
  }

  // ==============================================================
  // READ LOCATION
  // ==============================================================

  void _readLocation(
    Map<String, dynamic> data,
  ) {
    dynamic location =
        data['currentLocation'];

    // ------------------------------------------------------------
    // currentLocation
    // ------------------------------------------------------------

    if (location is Map) {
      _latitude =
          _toDouble(location['latitude']);

      _longitude =
          _toDouble(location['longitude']);
    }

    // ------------------------------------------------------------
    // location
    // ------------------------------------------------------------

    if (_latitude == null ||
        _longitude == null) {
      location = data['location'];

      if (location is Map) {
        _latitude =
            _toDouble(location['latitude']);

        _longitude =
            _toDouble(location['longitude']);
      }
    }

    // ------------------------------------------------------------
    // DIRECT FIELDS
    // ------------------------------------------------------------

    _latitude ??=
        _toDouble(data['latitude']);

    _longitude ??=
        _toDouble(data['longitude']);
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

  void _calculateCompanyDistance() {
  if (widget.userLatitude == null ||
      widget.userLongitude == null ||
      _latitude == null ||
      _longitude == null) {
    return;
  }

  _distanceKm = Geolocator.distanceBetween(
        widget.userLatitude!,
        widget.userLongitude!,
        _latitude!,
        _longitude!,
      ) /
      1000;
}
  // ==============================================================
  // DISPLAY NAME
  // ==============================================================

  String get _displayName {
    if (_companyName.trim().isNotEmpty) {
      return _companyName.trim();
    }

    return 'Company';
  }

  // ==============================================================
  // CATEGORY TEXT
  // ==============================================================

  String get _categoryText {
    if (_categories.isEmpty) {
      return 'Company Service';
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

  // bool get _hasPhone {
  //   return _phoneNumber
  //       .replaceAll(
  //         RegExp(r'[^0-9+]'),
  //         '',
  //       )
  //       .isNotEmpty;
  // }
  bool get _hasPhone =>
    _secondaryMobile.replaceAll(RegExp(r'[^0-9+]'), '').isNotEmpty;

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
  // EXPERIENCE TEXT
  // ==============================================================

  String get _experienceText {
    if (_experience.trim().isEmpty) {
      return 'Experience not specified';
    }

    return _experience.trim();
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
                Icons.business_center_outlined,
                size: 42,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              _errorMessage ??
                  'Unable to load company profile.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: darkGreen,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _loadCompanyProfile,
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
  // PROFILE
  // ==============================================================

  // Widget _buildProfile() {
  //   return CustomScrollView(
  //     slivers: [

  //       // ----------------------------------------------------------
  //       // APP BAR
  //       // ----------------------------------------------------------

  //       SliverAppBar(
  //         pinned: true,
  //         elevation: 0,
  //         backgroundColor: Colors.white,

  //         leading: IconButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //           },
  //           icon: const Icon(
  //             Icons.arrow_back,
  //             color: darkGreen,
  //           ),
  //         ),

  //         title: const Text(
  //           'Company Profile',
  //           style: TextStyle(
  //             color: darkGreen,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),

  //         centerTitle: true,
  //       ),

  //       // ----------------------------------------------------------
  //       // BODY
  //       // ----------------------------------------------------------

  //       SliverPadding(
  //         padding: const EdgeInsets.fromLTRB(
  //           16,
  //           18,
  //           16,
  //           35,
  //         ),
  //         sliver: SliverList(
  //           delegate: SliverChildListDelegate(
  //             [

  //               // --------------------------------------------------
  //               // PROFILE HEADER
  //               // --------------------------------------------------

  //               _buildProfileHeader(),

  //               const SizedBox(height: 18),

  //               // --------------------------------------------------
  //               // CATEGORY CARD
  //               // --------------------------------------------------

  //               _buildCategoryCard(),

  //               const SizedBox(height: 14),

  //               // --------------------------------------------------
  //               // EXPERIENCE CARD
  //               // --------------------------------------------------

  //               _buildExperienceCard(),

  //               const SizedBox(height: 14),

  //               // --------------------------------------------------
  //               // LOCATION CARD
  //               // --------------------------------------------------

  //               _buildLocationCard(),

  //               const SizedBox(height: 22),

  //               // --------------------------------------------------
  //               // ACTION BUTTONS
  //               //
  //               // Created in Part 3
  //               // --------------------------------------------------

  //               _buildActionButtons(),

  //               const SizedBox(height: 20),

  //               // --------------------------------------------------
  //               // INFORMATION CARD
  //               //
  //               // Created in Part 3
  //               // --------------------------------------------------

  //               _buildInformationCard(),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  Widget _buildProfile() {
  return CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: _buildProfileHeader(),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _buildActionButtons(),

            const SizedBox(height: 20),

            _buildCategoryCard(),

            const SizedBox(height: 14),

            _buildLocationCard(),

            const SizedBox(height: 14),

            _buildInformationCard(),

            const SizedBox(height: 14),

            _buildAboutCompanyCard(),
          ]),
        ),
      ),
    ],
  );
}

  // ==============================================================
  // PROFILE HEADER
  // ==============================================================

  // Widget _buildProfileHeader() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(22),
  //     decoration: BoxDecoration(
  //       gradient: const LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           darkGreen,
  //           green,
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(24),
  //       boxShadow: [
  //         BoxShadow(
  //           color: darkGreen.withValues(
  //             alpha: 0.20,
  //           ),
  //           blurRadius: 14,
  //           offset: const Offset(0, 6),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       children: [

  //         // --------------------------------------------------------
  //         // COMPANY ICON
  //         // --------------------------------------------------------

  //         Container(
  //           width: 92,
  //           height: 92,
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             shape: BoxShape.circle,
  //             border: Border.all(
  //               color: Colors.white.withValues(
  //                 alpha: 0.85,
  //               ),
  //               width: 3,
  //             ),
  //           ),
  //           child: const Icon(
  //             Icons.business,
  //             size: 46,
  //             color: darkGreen,
  //           ),
  //         ),

  //         const SizedBox(height: 15),

  //         // --------------------------------------------------------
  //         // COMPANY NAME
  //         // --------------------------------------------------------

  //         Text(
  //           _displayName,
  //           textAlign: TextAlign.center,
  //           maxLines: 2,
  //           overflow: TextOverflow.ellipsis,
  //           style: const TextStyle(
  //             color: Colors.white,
  //             fontSize: 24,
  //             fontWeight: FontWeight.w800,
  //           ),
  //         ),

  //         const SizedBox(height: 7),

  //         // --------------------------------------------------------
  //         // CATEGORY
  //         // --------------------------------------------------------

  //         Text(
  //           _categoryText,
  //           textAlign: TextAlign.center,
  //           maxLines: 3,
  //           overflow: TextOverflow.ellipsis,
  //           style: TextStyle(
  //             color: Colors.white.withValues(
  //               alpha: 0.90,
  //             ),
  //             fontSize: 14,
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),

  //         const SizedBox(height: 15),

  //         // --------------------------------------------------------
  //         // DISTANCE
  //         // --------------------------------------------------------

  //         Container(
  //           padding: const EdgeInsets.symmetric(
  //             horizontal: 15,
  //             vertical: 8,
  //           ),
  //           decoration: BoxDecoration(
  //             color: Colors.white.withValues(
  //               alpha: 0.14,
  //             ),
  //             borderRadius:
  //                 BorderRadius.circular(30),
  //           ),
  //           child: Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               const Icon(
  //                 Icons.location_on,
  //                 size: 17,
  //                 color: Colors.white,
  //               ),

  //               const SizedBox(width: 6),

  //               Text(
  //                 _distanceText,
  //                 style: const TextStyle(
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.w600,
  //                   fontSize: 13,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildProfileHeader() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [darkGreen, green],
      ),
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(30),
      ),
    ),
    child: Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 27,
            ),
          ),
        ),

        Container(
          width: 94,
          height: 94,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.business,
            size: 48,
            color: darkGreen,
          ),
        ),

        const SizedBox(height: 15),

        Text(
          _displayName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          _categoryText,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.near_me_outlined,
                size: 17,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                _distanceText,
                style: const TextStyle(
                  color: Colors.white,
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

  // ==============================================================
  // CATEGORY CARD
  // ==============================================================

  Widget _buildCategoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
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
                'Company Categories',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (_categories.isEmpty)
            const Text(
              'Company services available',
              style: TextStyle(
                color: Colors.grey,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map(
                (category) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: green.withValues(
                        alpha: 0.09,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: green.withValues(
                          alpha: 0.25,
                        ),
                      ),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: darkGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
  // EXPERIENCE CARD
  // ==============================================================

  // Widget _buildExperienceCard() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(17),
  //     decoration: _cardDecoration(),
  //     child: Row(
  //       children: [

  //         Container(
  //           width: 48,
  //           height: 48,
  //           decoration: BoxDecoration(
  //             color: orange.withValues(
  //               alpha: 0.12,
  //             ),
  //             borderRadius:
  //                 BorderRadius.circular(14),
  //           ),
  //           child: const Icon(
  //             Icons.workspace_premium_outlined,
  //             color: orange,
  //             size: 26,
  //           ),
  //         ),

  //         const SizedBox(width: 13),

  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment:
  //                 CrossAxisAlignment.start,
  //             children: [

  //               // const Text(
  //               //   'Experience',
  //               //   style: TextStyle(
  //               //     color: Colors.grey,
  //               //     fontSize: 13,
  //               //   ),
  //               // ),

  //               const SizedBox(height: 4),

  //               // Text(
  //               //   _experienceText,
  //               //   maxLines: 2,
  //               //   overflow: TextOverflow.ellipsis,
  //               //   style: const TextStyle(
  //               //     color: darkGreen,
  //               //     fontSize: 16,
  //               //     fontWeight: FontWeight.bold,
  //               //   ),
  //               // ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

Widget _buildAboutCompanyCard() {
  final String aboutText = _aboutCompany.trim().isEmpty
      ? 'No company description has been provided yet.'
      : _aboutCompany.trim();

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              'About Company',
              style: TextStyle(
                color: darkGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 13),

        Text(
          aboutText,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            height: 1.6,
          ),
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
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
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
                'Company Location',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: background,
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: orange.withValues(
                      alpha: 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.place,
                    color: orange,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        _hasLocation
                            ? 'Location available'
                            : 'Location unavailable',
                        style: const TextStyle(
                          color: darkGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        _hasLocation
                            ? 'Directions are available for this company.'
                            : 'This company has not provided a location.',
                        style: const TextStyle(
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

          // if (_hasLocation) ...[
          //   const SizedBox(height: 12),

          //   SizedBox(
          //     width: double.infinity,
          //     height: 47,
          //     child: OutlinedButton.icon(
          //       onPressed: _openDirections,
          //       icon: const Icon(
          //         Icons.directions,
          //         color: green,
          //       ),
          //       label: const Text(
          //         'Open Location in Maps',
          //         style: TextStyle(
          //           color: green,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //       style: OutlinedButton.styleFrom(
          //         side: const BorderSide(
          //           color: green,
          //         ),
          //         shape: RoundedRectangleBorder(
          //           borderRadius:
          //               BorderRadius.circular(12),
          //         ),
          //       ),
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }
  // ==============================================================
  // ACTION BUTTONS
  // ==============================================================

  // Widget _buildActionButtons() {
  //   return Row(
  //     children: [

  //       // ----------------------------------------------------------
  //       // CALL BUTTON
  //       // ----------------------------------------------------------

  //       Expanded(
  //         child: _buildActionButton(
  //           icon: Icons.phone,
  //           title: 'Call',
  //           color: green,
  //           onTap: _callCompany,
  //           enabled: _hasPhone,
  //         ),
  //       ),

  //       const SizedBox(width: 10),

  //       // ----------------------------------------------------------
  //       // CHAT BUTTON
  //       // ----------------------------------------------------------

  //       Expanded(
  //         child: _buildActionButton(
  //           icon: Icons.chat_bubble_outline,
  //           title: 'Chat',
  //           color: darkGreen,
  //           onTap: _openChat,
  //           enabled: true,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // ==============================================================
  // ACTION BUTTON
  // ==============================================================
Widget _buildActionButtons() {
  return Row(
    children: [
      Expanded(
        child: _buildActionButton(
          icon: Icons.call_outlined,
          title: 'Call',
          color: green,
          onTap: _callCompany,
          enabled: _hasPhone,
        ),
      ),

      const SizedBox(width: 10),

      Expanded(
        child: _buildActionButton(
          icon: Icons.location_on_outlined,
          title: 'Location',
          color: orange,
          onTap: _openDirections,
          enabled: _hasLocation,
        ),
      ),

      const SizedBox(width: 10),

      Expanded(
        child: _buildActionButton(
          icon: Icons.chat_bubble_outline,
          title: 'Chat',
          color: darkGreen,
          onTap: _openChat,
          enabled: true,
        ),
      ),
    ],
  );
}

Widget _buildActionButton({
  required IconData icon,
  required String title,
  required Color color,
  required VoidCallback onTap,
  required bool enabled,
}) {
  return SizedBox(
    height: 82,
    child: ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey.shade400,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 23),
          const SizedBox(height: 5),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

  // ==============================================================
  // COMPANY INFORMATION CARD
  //
  // IMPORTANT:
  // MOBILE NUMBER IS NOT DISPLAYED HERE.
  // The number is only used internally for the Call button.
  // ==============================================================

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
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
                'Company Information',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // --------------------------------------------------------
          // COMPANY NAME
          // --------------------------------------------------------

          _buildInfoRow(
            Icons.business_outlined,
            'Company',
            _displayName,
          ),

          const Divider(height: 22),

          // --------------------------------------------------------
          // CATEGORY
          // --------------------------------------------------------

          _buildInfoRow(
            Icons.category_outlined,
            'Category',
            _categoryText,
          ),

          // const Divider(height: 22),

          // // --------------------------------------------------------
          // // EXPERIENCE
          // // --------------------------------------------------------

          // _buildInfoRow(
          //   Icons.workspace_premium_outlined,
          //   'Experience',
          //   _experienceText,
          //  ),

          const Divider(height: 22),

          // --------------------------------------------------------
          // DISTANCE
          // --------------------------------------------------------

          _buildInfoRow(
            Icons.location_on_outlined,
            'Distance',
            _distanceText,
          ),

          // --------------------------------------------------------
          // MOBILE NUMBER IS INTENTIONALLY NOT SHOWN
          // --------------------------------------------------------
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

        const SizedBox(width: 12),

        SizedBox(
          width: 82,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: darkGreen,
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
        color: Colors.grey.withValues(
          alpha: 0.12,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: 0.045,
          ),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ==============================================================
  // CALL COMPANY
  //
  // The phone number stays hidden from the UI.
  // It is only used when the user presses Call.
  // ==============================================================

  // Future<void> _callCompany() async {
  //   if (!_hasPhone) {
  //     _showMessage(
  //       'Phone number is not available.',
  //       isError: true,
  //     );
  //     return;
  //   }

  //   String phone = _phoneNumber.trim();

  //   phone = phone.replaceAll(
  //     RegExp(r'[^\d+]'),
  //     '',
  //   );

  //   if (phone.isEmpty) {
  //     _showMessage(
  //       'Phone number is not available.',
  //       isError: true,
  //     );
  //     return;
  //   }

  //   final Uri phoneUri = Uri(
  //     scheme: 'tel',
  //     path: phone,
  //   );

  //   try {
  //     final bool launched =
  //         await launchUrl(
  //       phoneUri,
  //       mode:
  //           LaunchMode.externalApplication,
  //     );

  //     if (!launched) {
  //       _showMessage(
  //         'Unable to open phone dialer.',
  //         isError: true,
  //       );
  //     }
  //   } catch (e) {
  //     _showMessage(
  //       'Unable to open phone dialer.',
  //       isError: true,
  //     );
  //   }
  // }
  Future<void> _callCompany() async {
  final String phone = _secondaryMobile.trim().replaceAll(
    RegExp(r'[^\d+]'),
    '',
  );

  if (phone.isEmpty) {
    _showMessage(
      'Secondary mobile number is not available.',
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
  // OPEN COMPANY LOCATION IN GOOGLE MAPS
  // ==============================================================

  Future<void> _openDirections() async {
    if (!_hasLocation) {
      _showMessage(
        'Company location is not available.',
        isError: true,
      );
      return;
    }

    final double lat = _latitude!;
    final double lng = _longitude!;

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

  // ==============================================================
  // OPEN CHAT
  //
  // Uses your existing ScreenMessage.
  // No changes are required in your message screen.
  // ==============================================================

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenMessage(
  chatUser: {
    // Company ID
    'uid': widget.companyId,

    // Name
    'name': _displayName,

    // Company / Shop name
    'companyName': _companyName,

    // This helps the message screen identify the business
    'businessName': _companyName,

    // Phone
    'phoneNumber': _phoneNumber,

    // Category
    'profession': _categoryText,

    // Experience
    'experience': _experienceText,

    // Distance
    'distance': _distanceKm ?? 0.0,

    // Status
    'isActive': true,

    // Role
    'role': 'company',

    // Location coordinates
    'latitude': _latitude,
    'longitude': _longitude,

    // Location name shown in chat header
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
            isError ? Colors.red : green,
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ==============================================================
  // DISPOSE
  // ==============================================================

  @override
  void dispose() {
    super.dispose();
  }
}