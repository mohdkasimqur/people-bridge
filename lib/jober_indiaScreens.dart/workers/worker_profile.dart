import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:url_launcher/url_launcher.dart';

class ScreenWorkerProfile extends StatefulWidget {
  // ============================================================
  // WORKER DATA
  // ============================================================

  final Map<String, dynamic> worker;

  // ============================================================
  // CATEGORY SELECTED BY USER
  // ============================================================

  final String selectedCategoryId;

  final String selectedCategoryName;

  const ScreenWorkerProfile({
    super.key,
    required this.worker,
    required this.selectedCategoryId,
    required this.selectedCategoryName,
  });

  @override
  State<ScreenWorkerProfile> createState() =>
      _ScreenWorkerProfileState();
}

class _ScreenWorkerProfileState
    extends State<ScreenWorkerProfile> {
  // ============================================================
  // WORKER BASIC INFORMATION
  // ============================================================

  late String _workerName;

  late String _selectedCategoryName;

  double? _distanceKm;

  double? _distanceMeters;

  // ============================================================
  // ACTIVE STATUS
  // ============================================================

  bool _activeToday = false;

  @override
  void initState() {
    super.initState();

    _readWorkerData();
  }

  // ============================================================
  // READ WORKER DATA
  // ============================================================

  void _readWorkerData() {
    final Map<String, dynamic> worker =
        widget.worker;

    // ----------------------------------------------------------
    // WORKER NAME
    // ----------------------------------------------------------

    _workerName =
        _getWorkerName(worker);

    // ----------------------------------------------------------
    // SELECTED CATEGORY
    // ----------------------------------------------------------

    _selectedCategoryName =
        widget.selectedCategoryName;

    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    _distanceKm =
        _toDouble(
      worker['distanceKm'],
    );

    _distanceMeters =
        _toDouble(
      worker['distanceMeters'],
    );

    // ----------------------------------------------------------
    // ACTIVE STATUS
    // ----------------------------------------------------------

    final dynamic active =
        worker['activeToday'];

    if (active is bool) {
      _activeToday = active;
    } else {
      _activeToday =
          active?.toString().toLowerCase() ==
              'true';
    }
  }

  // ============================================================
  // WORKER NAME
  // ============================================================

  String _getWorkerName(
    Map<String, dynamic> worker,
  ) {
    final List<String> possibleKeys =
        <String>[
      'name',
      'workerName',
      'username',
      'userName',
      'fullName',
    ];

    for (final String key
        in possibleKeys) {
      final dynamic value =
          worker[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return 'Worker';
  }

  // ============================================================
  // DOUBLE CONVERSION
  // ============================================================

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

  // ============================================================
  // DISTANCE TEXT
  // ============================================================

  String _distanceText() {
    if (_distanceMeters != null) {
      final double meters =
          _distanceMeters!;

      if (meters < 1000) {
        return '${meters.round()} m away';
      }

      final double km =
          meters / 1000;

      if (km < 10) {
        return '${km.toStringAsFixed(1)} km away';
      }

      return '${km.toStringAsFixed(0)} km away';
    }

    if (_distanceKm != null) {
      if (_distanceKm! < 10) {
        return '${_distanceKm!.toStringAsFixed(1)} km away';
      }

      return '${_distanceKm!.toStringAsFixed(0)} km away';
    }

    return 'Distance unavailable';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.white,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        elevation: 0,

        centerTitle: true,

        iconTheme:
            const IconThemeData(
          color: Colors.black,
        ),

        title: const Text(
          'Worker Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 19,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),

          padding:
              const EdgeInsets.fromLTRB(
            18,
            10,
            18,
            25,
          ),

           child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              _buildProfileHeader(),

              const SizedBox(
                height: 22,
              ),

              _buildDistanceCard(),

              const SizedBox(
                height: 22,
              ),

              _buildCategoriesSection(),

              const SizedBox(
                height: 28,
              ),

              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          // ----------------------------------------------------
          // PROFILE ICON
          // ----------------------------------------------------

          Container(
            width: 92,
            height: 92,

            decoration:
                BoxDecoration(
              color:
                  Colors.red.shade50,

              shape:
                  BoxShape.circle,

              border: Border.all(
                color:
                    Colors.red.shade100,
                width: 1.5,
              ),
            ),

            child: Icon(
              Icons.engineering,
              size: 48,
              color:
                  Colors.red.shade700,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ----------------------------------------------------
          // NAME
          // ----------------------------------------------------

          Text(
            _workerName,

            textAlign:
                TextAlign.center,

            maxLines: 2,

            overflow:
                TextOverflow.ellipsis,

            style:
                const TextStyle(
              fontSize: 23,
              fontWeight:
                  FontWeight.w700,
              color: Colors.black,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          // ----------------------------------------------------
          // SELECTED CATEGORY
          // ----------------------------------------------------

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),

            decoration:
                BoxDecoration(
              color:
                  Colors.red.shade50,

              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),

            child: Text(
              _selectedCategoryName,

              style:
                  TextStyle(
                color:
                    Colors.red.shade700,

                fontSize: 13,

                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          // ----------------------------------------------------
          // ACTIVE STATUS
          // ----------------------------------------------------

          Row(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Container(
                width: 9,
                height: 9,

                decoration:
                    BoxDecoration(
                  color:
                      _activeToday
                          ? Colors.green
                          : Colors.grey,

                  shape:
                      BoxShape.circle,
                ),
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                _activeToday
                    ? 'Active Today'
                    : 'Not Active Today',

                style:
                    TextStyle(
                  fontSize: 13,

                  fontWeight:
                      FontWeight.w600,

                  color:
                      _activeToday
                          ? Colors.green
                              .shade700
                          : Colors.grey
                              .shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISTANCE CARD
  // ============================================================

  Widget _buildDistanceCard() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        15,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade50,

        borderRadius:
            BorderRadius.circular(
          14,
        ),

        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,

            decoration:
                BoxDecoration(
              color:
                  Colors.white,

              shape:
                  BoxShape.circle,

              border: Border.all(
                color:
                    Colors.grey.shade200,
              ),
            ),

            child: Icon(
              Icons.location_on_outlined,
              color:
                  Colors.red.shade700,
              size: 23,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                const Text(
                  'Distance from you',

                  style:
                      TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  _distanceText(),

                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Colors.black,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            _activeToday
                ? Icons
                    .radio_button_checked
                : Icons
                    .radio_button_off,

            size: 18,

            color:
                _activeToday
                    ? Colors.green
                    : Colors.grey,
          ),
        ],
      ),
    );
  }
  // ============================================================
// WORKER CATEGORIES
// ============================================================

List<String> _getWorkerCategories() {
  final List<String> result = [];

  final possibleFields = [
    widget.worker['categories'],
    widget.worker['workerCategories'],
    widget.worker['services'],
    widget.worker['selectedCategories'],
    widget.worker['category'],
  ];

  for (final field in possibleFields) {
    _addCategoriesFromValue(field, result);
  }

  // Always make sure the category selected by the user is included.
  if (_selectedCategoryName.trim().isNotEmpty &&
      !result.any(
        (item) =>
            item.toLowerCase() ==
            _selectedCategoryName.trim().toLowerCase(),
      )) {
    result.insert(0, _selectedCategoryName.trim());
  }

  // Remove duplicates.
  final unique = <String>[];
  final seen = <String>{};

  for (final item in result) {
    final clean = item.trim();

    if (clean.isEmpty) continue;

    final key = clean.toLowerCase();

    if (!seen.contains(key)) {
      seen.add(key);
      unique.add(clean);
    }
  }

  return unique;
}

// ============================================================
// READ DIFFERENT CATEGORY FORMATS SAFELY
// ============================================================

void _addCategoriesFromValue(
  dynamic value,
  List<String> result,
) {
  if (value == null) return;

  if (value is List) {
    for (final item in value) {
      _addCategoriesFromValue(item, result);
    }
    return;
  }

  if (value is Map) {
    final map = Map<String, dynamic>.from(value);

    if (map['name'] != null) {
      final name = map['name'].toString().trim();

      if (name.isNotEmpty) {
        result.add(_categoryDisplayName(name));
        return;
      }
    }

    if (map['categoryName'] != null) {
      final name = map['categoryName'].toString().trim();

      if (name.isNotEmpty) {
        result.add(_categoryDisplayName(name));
        return;
      }
    }

    if (map['id'] != null) {
      final id = map['id'].toString().trim();

      if (id.isNotEmpty) {
        result.add(_categoryDisplayName(id));
        return;
      }
    }

    for (final entry in map.entries) {
      final key = entry.key.toString().trim();
      final val = entry.value;

      if (val is String && val.trim().isNotEmpty) {
        result.add(_categoryDisplayName(val.trim()));
      } else if (key.isNotEmpty) {
        result.add(_categoryDisplayName(key));
      }
    }

    return;
  }

  if (value is String) {
    final text = value.trim();

    if (text.isEmpty) return;

    final parts = text.split(',');

    for (final part in parts) {
      final clean = part.trim();

      if (clean.isNotEmpty) {
        result.add(_categoryDisplayName(clean));
      }
    }

    return;
  }
}

// ============================================================
// CATEGORY ID -> DISPLAY NAME
// ============================================================

String _categoryDisplayName(String value) {
  final clean = value.trim();

  switch (clean.toLowerCase()) {
    case 'electrician':
      return 'Electrician';

    case 'plumber':
      return 'Plumber';

    case 'carpenter':
      return 'Carpenter';

    case 'painter':
      return 'Painter';

    case 'mechanic':
      return 'Mechanic';

    case 'cleaner':
      return 'Cleaner';

    case 'mason':
      return 'Mason';

    case 'ac_technician':
    case 'ac technician':
      return 'AC Technician';

    default:
      if (clean.isEmpty) {
        return clean;
      }

      return clean
          .split(' ')
          .map(
            (word) => word.isEmpty
                ? word
                : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
          )
          .join(' ');
  }
}

// ============================================================
// ALL CATEGORIES SECTION
// ============================================================

Widget _buildCategoriesSection() {
  final categories = _getWorkerCategories();

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.grey.shade200,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Services & Categories',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 12),

        if (categories.isEmpty)
          Text(
            _selectedCategoryName.isNotEmpty
                ? _selectedCategoryName
                : 'No categories available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map(
              (category) {
                final isSelected =
                    category.toLowerCase() ==
                    _selectedCategoryName.toLowerCase();

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.red.shade200
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.red.shade700
                          : Colors.grey.shade800,
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

// ============================================================
// ACTION BUTTONS
// ============================================================

Widget _buildActionButtons() {
  return Row(
    children: [
      Expanded(
        child: _buildActionButton(
          icon: Icons.call_outlined,
          label: 'CALL',
          onPressed: () {
            _openCall();
            // Call button intentionally has no action for now.
          },
        ),
      ),

      const SizedBox(width: 12),

      Expanded(
        child: _buildActionButton(
          icon: Icons.chat_bubble_outline,
          label: 'CHAT',
          onPressed: _openChat,
        ),
      ),
    ],
  );
}

// ============================================================
// ACTION BUTTON
// ============================================================

Widget _buildActionButton({
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    height: 48,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 20,
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

// ============================================================
// CALL WORKER USING SECONDARY MOBILE NUMBER
// ============================================================

Future<void> _openCall() async {
  final dynamic savedNumber =
      widget.worker['secondaryPhone'] ??
      widget.worker['secondaryMobile'] ??
      widget.worker['secondaryPhoneNumber'];

  final String phoneNumber =
      savedNumber?.toString().trim() ?? '';

  if (phoneNumber.length != 10 ||
      !RegExp(r'^\d{10}$').hasMatch(phoneNumber)) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'The worker has not provided a valid secondary mobile number.',
        ),
      ),
    );
    return;
  }

  final Uri phoneUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );

  try {
    final bool launched = await launchUrl(phoneUri);

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open the phone dialer.',
          ),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to open the phone dialer.',
        ),
      ),
    );

    debugPrint('Unable to call worker: $e');
  }
}

// ============================================================
// OPEN CHAT
// ============================================================

void _openChat() {
  final chatWorker = <String, dynamic>{
    ...widget.worker,

    // These values allow ScreenMessage to know which category
    // the user selected before opening the worker profile.
    'selectedCategoryId': widget.selectedCategoryId,
    'selectedCategoryName': widget.selectedCategoryName,

    // Also provide the commonly used category fields.
    'categoryId': widget.selectedCategoryId,
    'categoryName': widget.selectedCategoryName,
  };

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ScreenMessage(
        chatUser: chatWorker,
      ),
    ),
  );
}
// ============================================================
// MAIN PROFILE BODY
// ============================================================

}
