// ============================================================
// screen_broker_profile.dart
// PART 1 OF 3
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:url_launcher/url_launcher.dart';

class ScreenBrokerProfile extends StatefulWidget {
  final Map<String, dynamic> broker;

  final String selectedCategory;

  const ScreenBrokerProfile({
    super.key,
    required this.broker,
    required this.selectedCategory,
  });

  @override
  State<ScreenBrokerProfile> createState() =>
      _ScreenBrokerProfileState();
}

// ============================================================
// STATE
// ============================================================

class _ScreenBrokerProfileState
    extends State<ScreenBrokerProfile> {

  // ==========================================================
  // LOADING STATES
  // ==========================================================

  bool _isCalling = false;

  bool _isOpeningChat = false;

  // ==========================================================
  // BROKER NAME
  // ==========================================================

  String get brokerName {
    final dynamic name =
        widget.broker['name'] ??
        widget.broker['brokerName'] ??
        widget.broker['username'] ??
        widget.broker['userName'];

    if (name == null ||
        name.toString().trim().isEmpty) {
      return 'Broker';
    }

    return name.toString().trim();
  }

  // ==========================================================
  // BROKER UID
  // ==========================================================

  String get brokerUid {
    final dynamic uid =
        widget.broker['uid'] ??
        widget.broker['userId'] ??
        widget.broker['id'];

    if (uid == null) {
      return '';
    }

    return uid.toString();
  }

  // ==========================================================
  // BROKER PHONE
  // ==========================================================

  String get brokerPhone {
    final dynamic phone =
        widget.broker['phone'] ??
        widget.broker['mobile'] ??
        widget.broker['phoneNumber'] ??
        widget.broker['mobileNumber'];

    if (phone == null) {
      return '';
    }

    return phone.toString().trim();
  }

  // ==========================================================
  // BROKER LATITUDE
  // ==========================================================

  double? get brokerLatitude {
    return _readDouble(
      widget.broker['latitude'],
    );
  }

  // ==========================================================
  // BROKER LONGITUDE
  // ==========================================================

  double? get brokerLongitude {
    return _readDouble(
      widget.broker['longitude'],
    );
  }

  // ==========================================================
  // DISTANCE
  // ==========================================================

  double get distanceKm {
    return _readDouble(
          widget.broker['distanceKm'],
        ) ??
        0.0;
  }

  // ==========================================================
  // SAFE DOUBLE
  // ==========================================================

  double? _readDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(
        value.trim(),
      );
    }

    return null;
  }

  // ==========================================================
  // FORMAT DISTANCE
  // ==========================================================

  String _formatDistance() {
    if (distanceKm < 1) {
      final int meters =
          (distanceKm * 1000).round();

      return '$meters m away';
    }

    if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km away';
    }

    return '${distanceKm.toStringAsFixed(0)} km away';
  }

  List<String> _getAllCategories() {
    final List<String> categories = [];


    final dynamic firstCategories =
        widget.broker['categories'];

    if (firstCategories is List) {
      for (final dynamic item
          in firstCategories) {
        final String value =
            item.toString().trim();

        if (value.isNotEmpty &&
            !categories.contains(value)) {
          categories.add(value);
        }
      }
    }

    final dynamic secondCategories =
        widget.broker['brokerCategories'];

    if (secondCategories is List) {
      for (final dynamic item
          in secondCategories) {
        final String value =
            item.toString().trim();

        if (value.isNotEmpty &&
            !categories.contains(value)) {
          categories.add(value);
        }
      }
    }

    final dynamic singleCategory =
        widget.broker['category'];

    if (singleCategory is String) {
      final String value =
          singleCategory.trim();

      if (value.isNotEmpty &&
          !categories.contains(value)) {
        categories.add(value);
      }
    }

  
    if (widget.selectedCategory
            .trim()
            .isNotEmpty &&
        !categories.contains(
          widget.selectedCategory.trim(),
        )) {
      categories.insert(
        0,
        widget.selectedCategory.trim(),
      );
    }

    return categories;
  }


  Future<void> _callBroker() async {
    if (_isCalling) {
      return;
    }

    final String phone =
        brokerPhone;

    if (phone.isEmpty) {
      _showMessage(
        'Phone number is not available.',
      );

      return;
    }

    setState(() {
      _isCalling = true;
    });

    try {
      final String cleanedPhone =
          phone.replaceAll(
        RegExp(r'[^0-9+]'),
        '',
      );

      final Uri phoneUri =
          Uri(
        scheme: 'tel',
        path: cleanedPhone,
      );

      final bool canLaunch =
          await canLaunchUrl(
        phoneUri,
      );

      if (!canLaunch) {
        _showMessage(
          'Unable to open the phone app.',
        );

        return;
      }

      await launchUrl(
        phoneUri,
        mode:
            LaunchMode.externalApplication,
      );
    } catch (_) {
      _showMessage(
        'Unable to make the call.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCalling = false;
        });
      }
    }
  }

// ============================================================
// OPEN CHAT
// ============================================================

  Future<void> _openChat() async {
    if (_isOpeningChat) {
      return;
    }

    if (brokerUid.isEmpty) {
      _showMessage(
        'Broker information is unavailable.',
      );

      return;
    }

    setState(() {
      _isOpeningChat = true;
    });

    try {
      // ------------------------------------------------------
      // DATA SENT TO SCREEN MESSAGE
      // ------------------------------------------------------

      final Map<String, dynamic> chatBroker =
          Map<String, dynamic>.from(
        widget.broker,
      );

      // ------------------------------------------------------
      // IMPORTANT:
      //
      // Store the category selected by the user.
      //
      // This allows ScreenMessage to show:
      //
      // Real Estate — Kasim
      //
      // in the AppBar.
      // ------------------------------------------------------

      chatBroker['selectedCategory'] =
          widget.selectedCategory;

      chatBroker['chatCategory'] =
          widget.selectedCategory;

      chatBroker['workerName'] =
          brokerName;

      chatBroker['brokerName'] =
          brokerName;

      chatBroker['uid'] =
          brokerUid;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScreenMessage(
            chatUser: chatBroker,
          ),
        ),
      );
    } catch (e) {
      _showMessage(
        'Unable to open chat.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningChat = false;
        });
      }
    }
  }

// ============================================================
// OPEN MAP
// ============================================================

  Future<void> _openMap() async {
    final double? latitude =
        brokerLatitude;

    final double? longitude =
        brokerLongitude;

    if (latitude == null ||
        longitude == null) {
      _showMessage(
        'Broker location is not available.',
      );

      return;
    }

    try {
      final Uri mapUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1'
        '&query=$latitude,$longitude',
      );

      final bool canLaunch =
          await canLaunchUrl(
        mapUri,
      );

      if (!canLaunch) {
        _showMessage(
          'Unable to open Google Maps.',
        );

        return;
      }

      await launchUrl(
        mapUri,
        mode:
            LaunchMode.externalApplication,
      );
    } catch (_) {
      _showMessage(
        'Unable to open the map.',
      );
    }
  }

// ============================================================
// MESSAGE
// ============================================================

  void _showMessage(
    String message,
  ) {
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

// ============================================================
// CATEGORY CHIP
// ============================================================

  Widget _buildCategoryChip(
    String category,
  ) {
    final bool isSelected =
        category.trim().toLowerCase() ==
        widget.selectedCategory
            .trim()
            .toLowerCase();

    return Container(
      margin: const EdgeInsets.only(
        right: 7,
        bottom: 7,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.red.withValues(alpha: 0.08)
            : Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? Colors.red.withValues(alpha: 0.35)
              : Colors.grey.shade300,
        ),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight:
              isSelected
                  ? FontWeight.w600
                  : FontWeight.w500,
          color: isSelected
              ? Colors.red
              : Colors.black87,
        ),
      ),
    );
  }

// ============================================================
// ACTION BUTTON
// ============================================================

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool loading = false,
  }) {
    return Expanded(
      child: SizedBox(
        height: 45,
        child: ElevatedButton.icon(
          onPressed:
              loading ? null : onPressed,
          icon: loading
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  icon,
                  size: 19,
                ),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.red,
            foregroundColor:
                Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
            ),
          ),
        ),
      ),
    );
  }
  // ============================================================
// screen_broker_profile.dart
// PART 3 OF 3
// ============================================================

// ============================================================
// BUILD
// ============================================================

  @override
  Widget build(BuildContext context) {
    final List<String> categories =
        _getAllCategories();

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Broker Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 19,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            14,
            14,
            14,
            25,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // =================================================
              // PROFILE CARD
              // =================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(18),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  border: Border.all(
                    color:
                        Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: 
                        0.035,
                      ),
                      blurRadius: 6,
                      offset:
                          const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [

                    // -------------------------------------------
                    // BROKER ICON
                    // -------------------------------------------

                    Container(
                      width: 78,
                      height: 78,
                      decoration:
                          BoxDecoration(
                        color: Colors.red
                            .withValues(alpha: 
                          0.08,
                        ),
                        shape:
                            BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons
                            .business_center_outlined,
                        color:
                            Colors.red,
                        size: 39,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // -------------------------------------------
                    // NAME
                    // -------------------------------------------

                    Text(
                      brokerName,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Colors.black87,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    // -------------------------------------------
                    // SELECTED CATEGORY
                    // -------------------------------------------

                    Text(
                      widget.selectedCategory,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Colors.red,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // -------------------------------------------
                    // DISTANCE
                    // -------------------------------------------

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons
                              .location_on_outlined,
                          size: 17,
                          color:
                              Colors.grey.shade600,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          _formatDistance(),
                          style:
                              TextStyle(
                            fontSize: 13,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // =================================================
              // CATEGORIES
              // =================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  border: Border.all(
                    color:
                        Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    const Text(
                      'Broker Categories',
                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Colors.black87,
                      ),
                    ),

                    const SizedBox(
                      height: 11,
                    ),

                    if (categories.isEmpty)
                      Text(
                        widget.selectedCategory,
                        style:
                            TextStyle(
                          fontSize: 13,
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      )
                    else
                      Wrap(
                        children:
                            categories
                                .map(
                          (category) {
                            return _buildCategoryChip(
                              category,
                            );
                          },
                        ).toList(),
                      ),
                  ],
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // =================================================
              // LOCATION CARD
              // =================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
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
                      width: 42,
                      height: 42,
                      decoration:
                          BoxDecoration(
                        color: Colors.red
                            .withValues(alpha: 
                          0.08,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                      child:
                          const Icon(
                        Icons
                            .location_on_outlined,
                        color:
                            Colors.red,
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
                            'Distance',
                            style:
                                TextStyle(
                              fontSize: 13,
                              color:
                                  Colors.grey,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            _formatDistance(),
                            style:
                                const TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    OutlinedButton(
                      onPressed:
                          _openMap,
                      style:
                          OutlinedButton
                              .styleFrom(
                        foregroundColor:
                            Colors.red,
                        side:
                            const BorderSide(
                          color:
                              Colors.red,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            8,
                          ),
                        ),
                      ),
                      child:
                          const Text(
                        'MAP',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // =================================================
              // ACTION BUTTONS
              // =================================================

              Row(
                children: [

                  _buildActionButton(
                    icon:
                        Icons.phone_outlined,
                    label: 'CALL',
                    onPressed:
                        _callBroker,
                    loading:
                        _isCalling,
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  _buildActionButton(
                    icon:
                        Icons.chat_outlined,
                    label: 'CHAT',
                    onPressed:
                        _openChat,
                    loading:
                        _isOpeningChat,
                  ),
                ],
              ),

              const SizedBox(
                height: 15,
              ),

              // =================================================
              // PRIVACY MESSAGE
              // =================================================

              Center(
                child: Text(
                  'Broker contact details are kept private.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color:
                        Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}