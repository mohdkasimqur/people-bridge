import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:url_launcher/url_launcher.dart';

class ScreenGroceryProfile extends StatefulWidget {
  final Map<String, dynamic> grocery;

  const ScreenGroceryProfile({
    super.key,
    required this.grocery,
  });

  @override
  State<ScreenGroceryProfile> createState() =>
      _ScreenGroceryProfileState();
}

class _ScreenGroceryProfileState
    extends State<ScreenGroceryProfile> {
  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color darkGreen =
      Color(0xFF12652F);

  static const Color green =
      Color(0xFF138808);

  static const Color orange =
      Color(0xFFED801D);

  static const Color background =
      Color(0xFFF7F8F7);

  // ==========================================================
  // GET SHOP NAME
  // ==========================================================

  String get groceryName {
    final name =
        (widget.grocery['displayName'] ??
                widget.grocery['shopName'] ??
                '')
            .toString()
            .trim();

    if (name.isEmpty) {
      return 'Grocery Store';
    }

    return name;
  }

  // ==========================================================
  // GET CATEGORIES
  // ==========================================================

  List<String> get categories {
    final value =
        widget.grocery['categories'];

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

  // ==========================================================
  // GET MOBILE
  // ==========================================================

  String get mobile {
    return (widget.grocery['mobile'] ??
            '')
        .toString()
        .trim();
  }

  // ==========================================================
  // GET PHOTO URL
  // ==========================================================

  String get photoUrl {
    return (widget.grocery['photoUrl'] ??
            '')
        .toString()
        .trim();
  }

  // ==========================================================
  // GET DISTANCE
  // ==========================================================

  String get distanceText {
    final value =
        (widget.grocery['distanceKm'] as num?)
                ?.toDouble();

    if (value == null) {
      return 'Nearby';
    }

    if (value < 1) {
      final meters =
          (value * 1000).round();

      return '$meters m Away';
    }

    return '${value.toStringAsFixed(1)} KM Away';
  }

  // ==========================================================
  // GET OPENING TIME
  // ==========================================================

  String get openingTime {
    return (widget.grocery['openingTime'] ??
            '')
        .toString()
        .trim();
  }

  // ==========================================================
  // GET CLOSING TIME
  // ==========================================================

  String get closingTime {
    return (widget.grocery['closingTime'] ??
            '')
        .toString()
        .trim();
  }

  // ==========================================================
  // GET LATITUDE
  // ==========================================================

  double? get latitude {
    final value =
        widget.grocery['latitude'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  // ==========================================================
  // GET LONGITUDE
  // ==========================================================

  double? get longitude {
    final value =
        widget.grocery['longitude'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  // ==========================================================
  // GET LOCATION ADDRESS
  // ==========================================================

  String get locationAddress {
    return (widget.grocery[
                'locationAddress'] ??
            '')
        .toString()
        .trim();
  }

  // ==========================================================
  // CALL GROCERY SHOP
  // ==========================================================

  Future<void> _callGrocery() async {
    if (mobile.isEmpty) {
      _showMessage(
        'Phone number is not available.',
      );
      return;
    }

    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: mobile,
    );

    try {
      final canCall =
          await canLaunchUrl(phoneUri);

      if (!canCall) {
        _showMessage(
          'Unable to open the phone app.',
        );
        return;
      }

      await launchUrl(phoneUri);
    } catch (_) {
      _showMessage(
        'Unable to make the call.',
      );
    }
  }

  // ==========================================================
  // OPEN GOOGLE MAPS
  // ==========================================================

  Future<void> _openLocation() async {
    final lat = latitude;
    final lng = longitude;

    if (lat == null || lng == null) {
      _showMessage(
        'Location is not available for this grocery shop.',
      );
      return;
    }

    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=$lat,$lng',
    );

    try {
      final canOpen =
          await canLaunchUrl(mapsUri);

      if (!canOpen) {
        _showMessage(
          'Unable to open Google Maps.',
        );
        return;
      }

      await launchUrl(
        mapsUri,
        mode:
            LaunchMode.externalApplication,
      );
    } catch (_) {
      _showMessage(
        'Unable to open the location.',
      );
    }
  }

  // ==========================================================
  // SHOW MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
  // ==========================================================
  // OPEN CHAT
  // ==========================================================

  void _openChat() {
    final uid =
        (widget.grocery['uid'] ??
                widget.grocery['documentId'] ??
                '')
            .toString();

    final chatData = <String, dynamic>{
      'uid': uid,
      'name': groceryName,
      'workerName': groceryName,
      'shopName': groceryName,
      'displayName': groceryName,
      'mobile': mobile,
      'role': 'grocery',
      'categories': categories,
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'photoUrl': photoUrl,
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

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ========================================================
      // APP BAR
      // ========================================================

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
                text: 'Grocery ',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'Profile',
                style: TextStyle(
                  color: orange,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            15,
            20,
            30,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // ==================================================
              // SHOP PHOTO
              // ==================================================

              _buildPhotoSection(),

              const SizedBox(height: 20),

              // ==================================================
              // SHOP NAME
              // ==================================================

              Center(
                child: Text(
                  groceryName,
                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 7),

              // ==================================================
              // ROLE
              // ==================================================

              const Center(
                child: Text(
                  'Grocery Store',
                  style: TextStyle(
                    color: orange,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // DISTANCE
              // ==================================================

              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFEAF6ED),

                    borderRadius:
                        BorderRadius.circular(20),
                  ),

                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [
                      const Icon(
                        Icons.location_on,
                        color: darkGreen,
                        size: 19,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        distanceText,
                        style:
                            const TextStyle(
                          color: darkGreen,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // CATEGORY SECTION
              // ==================================================

              _sectionTitle(
                'Categories',
                Icons.category_outlined,
              ),

              const SizedBox(height: 10),

              _buildCategories(),

              const SizedBox(height: 22),

              // ==================================================
              // OPENING HOURS
              // ==================================================

              _sectionTitle(
                'Opening Hours',
                Icons.access_time,
              ),

              const SizedBox(height: 10),

              _buildOpeningHours(),

              const SizedBox(height: 22),

              // ==================================================
              // LOCATION
              // ==================================================

              _sectionTitle(
                'Location',
                Icons.location_on_outlined,
              ),

              const SizedBox(height: 10),

              _buildLocationInfo(),

              const SizedBox(height: 28),

              // ==================================================
              // ACTION BUTTONS
              // ==================================================

              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // PHOTO SECTION
  // ==========================================================

  Widget _buildPhotoSection() {
    return Container(
      width: double.infinity,
      height: 220,

      decoration: BoxDecoration(
        color: const Color(0xFFEAF6ED),

        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color: const Color(0xFFE0E0E0),
        ),
      ),

      clipBehavior: Clip.antiAlias,

      child: photoUrl.isEmpty
          ? const Center(
              child: Icon(
                Icons
                    .local_grocery_store_outlined,
                color: darkGreen,
                size: 75,
              ),
            )
          : Image.network(
              photoUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,

              errorBuilder:
                  (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons
                        .local_grocery_store_outlined,
                    color: darkGreen,
                    size: 75,
                  ),
                );
              },

              loadingBuilder:
                  (context, child,
                      loadingProgress) {
                if (loadingProgress ==
                    null) {
                  return child;
                }

                return const Center(
                  child:
                      CircularProgressIndicator(
                    color: darkGreen,
                  ),
                );
              },
            ),
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _sectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: darkGreen,
          size: 21,
        ),

        const SizedBox(width: 8),

        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF202124),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
 

  // ==========================================================
  // CATEGORIES
  // ==========================================================

  Widget _buildCategories() {
    if (categories.isEmpty) {
      return _infoContainer(
        child: const Text(
          'Grocery Store',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
      );
    }

    return _infoContainer(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,

        children: categories.map(
          (category) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 8,
              ),

              decoration: BoxDecoration(
                color:
                    const Color(0xFFEAF6ED),

                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Text(
                category,
                style: const TextStyle(
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
    );
  }

  // ==========================================================
  // OPENING HOURS
  // ==========================================================

  Widget _buildOpeningHours() {
    final hasOpening =
        openingTime.isNotEmpty;

    final hasClosing =
        closingTime.isNotEmpty;

    return _infoContainer(
      child: Row(
        children: [

          Expanded(
            child: _timeItem(
              title: 'Opening',
              value: hasOpening
                  ? openingTime
                  : '--',
            ),
          ),

          Container(
            width: 1,
            height: 45,
            color:
                const Color(0xFFE0E0E0),
          ),

          Expanded(
            child: _timeItem(
              title: 'Closing',
              value: hasClosing
                  ? closingTime
                  : '--',
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TIME ITEM
  // ==========================================================

  Widget _timeItem({
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          value,
          textAlign: TextAlign.center,

          style: const TextStyle(
            color: darkGreen,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // LOCATION INFORMATION
  // ==========================================================

  Widget _buildLocationInfo() {
    return _infoContainer(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Icon(
            Icons.location_on,
            color: orange,
            size: 24,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              locationAddress.isNotEmpty
                  ? locationAddress
                  : 'Current registered location',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // COMMON INFORMATION CONTAINER
  // ==========================================================

  Widget _infoContainer({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(17),

        border: Border.all(
          color: const Color(0xFFE0E0E0),
        ),
      ),

      child: child,
    );
  }
  // ==========================================================
  // ACTION BUTTONS
  // ==========================================================

  Widget _buildActionButtons() {
    return Column(
      children: [

        // ======================================================
        // CALL BUTTON
        // ======================================================

        SizedBox(
          width: double.infinity,
          height: 58,

          child: ElevatedButton.icon(
            onPressed: _callGrocery,

            icon: const Icon(
              Icons.call,
              size: 23,
            ),

            label: const Text(
              'CALL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              foregroundColor: Colors.white,
              elevation: 0,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(18),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ======================================================
        // CHAT BUTTON
        // ======================================================

        SizedBox(
          width: double.infinity,
          height: 58,

          child: ElevatedButton.icon(
            onPressed: _openChat,

            icon: const Icon(
              Icons.chat_bubble_outline,
              size: 23,
            ),

            label: const Text(
              'CHAT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              elevation: 0,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(18),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ======================================================
        // LOCATION BUTTON
        // ======================================================

        SizedBox(
          width: double.infinity,
          height: 58,

          child: ElevatedButton.icon(
            onPressed: _openLocation,

            icon: const Icon(
              Icons.location_on_outlined,
              size: 23,
            ),

            label: const Text(
              'GO TO LOCATION',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              foregroundColor: Colors.white,
              elevation: 0,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(18),
              ),
            ),
          ),
        ),

        const SizedBox(height: 15),

        // ======================================================
        // PRIVACY NOTE
        // ======================================================

        const Text(
          'Phone number is hidden for privacy. '
          'Use CALL or CHAT to contact the grocery shop.',
          textAlign: TextAlign.center,

          style: TextStyle(
            color: Colors.black45,
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}