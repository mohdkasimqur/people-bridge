import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:url_launcher/url_launcher.dart';

// Change this import to the actual file containing ScreenMessage.

class ScreenClinicProfile extends StatefulWidget {
  final Map<String, dynamic> clinicData;
  final double? userLatitude;
  final double? userLongitude;
  final String? selectedCategory;

  const ScreenClinicProfile({
    super.key,
    required this.clinicData,
    this.userLatitude,
    this.userLongitude,
    this.selectedCategory,
  });

  @override
  State<ScreenClinicProfile> createState() =>
      _ScreenClinicProfileState();
}

class _ScreenClinicProfileState extends State<ScreenClinicProfile> {
  static const Color green = Color(0xFF16803C);
  static const Color darkGreen = Color(0xFF12652F);
  static const Color orange = Color(0xFFED801D);
  static const Color background = Color(0xFFF7F7F7);

  late Map<String, dynamic> clinicData;

  String clinicId = '';
  String username = '';
  String clinicName = 'Clinic';
  String category = '';
  String phoneNumber = '';
  String stateName = '';
  String district = '';
  String nearestTown = '';
  String openingTime = '';
  String closingTime = '';

  List<String> categories = [];

  double? latitude;
  double? longitude;
  double? distanceInKm;

  bool isActive = true;
  bool isOpen24Hours = false;
  bool isCalling = false;
  bool isOpeningLocation = false;

  @override
  void initState() {
    super.initState();

    clinicData = Map<String, dynamic>.from(widget.clinicData);
    _readClinicData();
  }

  void _readClinicData() {
    clinicId = (clinicData['uid'] ??
            clinicData['clinicId'] ??
            clinicData['id'] ??
            '')
        .toString();

    username = (clinicData['username'] ??
            clinicData['ownerName'] ??
            '')
        .toString()
        .trim();

    clinicName = (clinicData['clinicName'] ??
            clinicData['name'] ??
            'Clinic')
        .toString()
        .trim();

    if (clinicName.isEmpty) clinicName = 'Clinic';

    final rawCategories = clinicData['categories'];

    if (rawCategories is List) {
      categories = rawCategories
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
    }

    category = widget.selectedCategory?.trim().isNotEmpty == true
        ? widget.selectedCategory!.trim()
        : categories.isNotEmpty
            ? categories.first
            : (clinicData['category'] ?? 'Clinic').toString();

    // Use the secondary number for the Call button.
    // The phone number is not displayed in the UI.
    phoneNumber = (clinicData['secondaryPhone'] ??
            clinicData['secondaryMobile'] ??
            '')
        .toString()
        .trim();

    stateName = (clinicData['state'] ?? '').toString();
    district = (clinicData['district'] ?? '').toString();
    nearestTown = (clinicData['nearestTown'] ?? '').toString();

    openingTime = (clinicData['openingTime'] ?? '').toString();
    closingTime = (clinicData['closingTime'] ?? '').toString();

    isOpen24Hours = clinicData['isOpen24Hours'] == true;

    final activeValue = clinicData['isActive'];
    isActive = activeValue is bool ? activeValue : true;

    _readLocation();
    _calculateDistance();
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _readLocation() {
    latitude = null;
    longitude = null;

    // Clinic registration saves currentLocation.toMap()
    // under the Firestore field "locationAddress".
    final candidates = [
      clinicData['locationAddress'],
      clinicData['currentLocation'],
      clinicData['location'],
      clinicData,
    ];

    for (final candidate in candidates) {
      if (candidate is GeoPoint) {
        latitude = candidate.latitude;
        longitude = candidate.longitude;
        break;
      }

      if (candidate is! Map) continue;

      final lat = _toDouble(
        candidate['latitude'] ?? candidate['lat'],
      );

      final lng = _toDouble(
        candidate['longitude'] ??
            candidate['lng'] ??
            candidate['lon'],
      );

      if (lat != null &&
          lng != null &&
          lat >= -90 &&
          lat <= 90 &&
          lng >= -180 &&
          lng <= 180) {
        latitude = lat;
        longitude = lng;
        break;
      }

      // Support a nested GeoPoint if the saved map uses one.
      final point = candidate['geoPoint'] ??
          candidate['coordinates'];

      if (point is GeoPoint) {
        latitude = point.latitude;
        longitude = point.longitude;
        break;
      }
    }
  }

  void _calculateDistance() {
    if (widget.userLatitude == null ||
        widget.userLongitude == null ||
        latitude == null ||
        longitude == null) {
      distanceInKm = null;
      return;
    }

    distanceInKm = Geolocator.distanceBetween(
          widget.userLatitude!,
          widget.userLongitude!,
          latitude!,
          longitude!,
        ) /
        1000;
  }

  String get formattedDistance {
    if (distanceInKm == null) return 'Distance unavailable';

    if (distanceInKm! < 1) {
      return '${(distanceInKm! * 1000).round()} m away';
    }

    return '${distanceInKm!.toStringAsFixed(1)} km away';
  }

  String get statusText =>
      isActive ? 'Active' : 'Currently unavailable';

  Color get statusColor => isActive ? green : Colors.grey;

  String get locationDescription {
    final parts = [
      nearestTown,
      district,
      stateName,
    ].where((item) => item.trim().isNotEmpty).toList();

    return parts.isEmpty ? 'Location details unavailable' : parts.join(', ');
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> callClinic() async {
    if (phoneNumber.isEmpty) {
      _showMessage('Clinic contact number is not available.');
      return;
    }

    if (isCalling) return;

    setState(() => isCalling = true);

    try {
      var phone = phoneNumber.replaceAll(RegExp(r'\s+'), '');

      if (!phone.startsWith('+') && phone.length == 10) {
        phone = '+91$phone';
      }

      final uri = Uri(scheme: 'tel', path: phone);

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage('Unable to open the phone application.');
      }
    } catch (e) {
      debugPrint('Clinic call error: $e');
      _showMessage('Unable to open the phone application.');
    } finally {
      if (mounted) setState(() => isCalling = false);
    }
  }

  Future<void> openClinicLocation() async {
    if (latitude == null || longitude == null) {
      _showMessage('Clinic location is not available.');
      return;
    }

    if (isOpeningLocation) return;

    setState(() => isOpeningLocation = true);

    try {
      final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$latitude,$longitude'
        '&travelmode=driving',
      );

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage('Unable to open Google Maps.');
      }
    } catch (e) {
      debugPrint('Clinic map error: $e');
      _showMessage('Unable to open the clinic location.');
    } finally {
      if (mounted) setState(() => isOpeningLocation = false);
    }
  }

  void openChat() {
    if (clinicId.isEmpty) {
      _showMessage('Clinic account information is unavailable.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenMessage(
          chatUser: {
            'uid': clinicId,
            'name': clinicName,
            'location': formattedDistance,
            'type': 'clinic',
          },
        ),
      ),
    );
  }

  Widget _profileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [darkGreen, green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Spacer(),
                if (category.isNotEmpty)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_hospital_outlined,
                color: green,
                size: 49,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              clinicName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (categories.length > 1) ...[
              const SizedBox(height: 8),
              Text(
                categories.join(' • '),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    Color iconColor = green,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool loading = false,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 23),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _actionSection() {
    return Row(
      children: [
        _actionButton(
          icon: Icons.call,
          label: 'Call',
          color: green,
          loading: isCalling,
          onPressed: callClinic,
        ),
        const SizedBox(width: 9),
        _actionButton(
          icon: Icons.location_on_outlined,
          label: 'Location',
          color: orange,
          loading: isOpeningLocation,
          onPressed: openClinicLocation,
        ),
        const SizedBox(width: 9),
        _actionButton(
          icon: Icons.chat_bubble_outline,
          label: 'Chat',
          color: darkGreen,
          onPressed: openChat,
        ),
      ],
    );
  }

  Widget _openingHoursCard() {
    final value = isOpen24Hours
        ? 'Open 24 hours'
        : openingTime.isNotEmpty && closingTime.isNotEmpty
            ? '$openingTime – $closingTime'
            : 'Opening hours not provided';

    return _infoCard(
      icon: Icons.access_time,
      title: 'Opening Hours',
      value: value,
      iconColor: orange,
    );
  }

  Widget _aboutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: green),
              SizedBox(width: 9),
              Text(
                'About this Clinic',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome to $clinicName.'
            '${category.isNotEmpty ? ' Category: $category.' : ''} '
            'Use the buttons above to call the clinic, get directions, '
            'or start a chat.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _profileHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _actionSection(),
                    const SizedBox(height: 23),
                    const Text(
                      'Clinic Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 13),
                    _infoCard(
                      icon: Icons.category_outlined,
                      title: 'Clinic Categories',
                      value: categories.isEmpty
                          ? category
                          : categories.join(', '),
                    ),
                    const SizedBox(height: 11),
                    _infoCard(
                      icon: Icons.location_on_outlined,
                      title: 'Distance from you',
                      value: formattedDistance,
                      iconColor: orange,
                    ),
                    const SizedBox(height: 11),
                    _infoCard(
                      icon: Icons.map_outlined,
                      title: 'Clinic Area',
                      value: locationDescription,
                      iconColor: darkGreen,
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 11),
                      _infoCard(
                        icon: Icons.person_outline,
                        title: 'Clinic Owner',
                        value: username,
                      ),
                    ],
                    const SizedBox(height: 11),
                    _openingHoursCard(),
                    const SizedBox(height: 22),
                    _aboutSection(),
                    const SizedBox(height: 22),
                    Center(
                      child: Text(
                        'Contact the clinic using the Call button',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}