import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:jober_india/jober_indiaScreens.dart/CorierService/corrier_categories.dart';
import 'package:jober_india/jober_indiaScreens.dart/Privacy&Terms/privacy_terms_section.dart';
import 'package:jober_india/jober_indiaScreens.dart/common_profile_services.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_camera_capture.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_home.dart';
import 'package:jober_india/l10n/app_localizations.dart';
import 'package:jober_india/screens/location_localization.dart';

class CourierVehicleCategory {
  final String id;
  final String name;
  final String iconType;
  final bool isCustom;

  const CourierVehicleCategory({
    required this.id,
    required this.name,
    required this.iconType,
    this.isCustom = false,
  });

  factory CourierVehicleCategory.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return CourierVehicleCategory(
      id: id,
      name: (map['name'] ?? '').toString(),
      iconType: (map['iconType'] ?? 'default').toString(),
      isCustom: map['isCustom'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconType': iconType,
      'isCustom': isCustom,
    };
  }
}

class ScreenCourierLogin extends StatefulWidget {
  const ScreenCourierLogin({super.key});

  @override
  State<ScreenCourierLogin> createState() =>
      _ScreenCourierLoginState();
}

class _ScreenCourierLoginState
    extends State<ScreenCourierLogin> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final FirebaseAuth auth =
      FirebaseAuth.instance;


  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController mobileController =
      TextEditingController();

  final TextEditingController vehicleNumberController =
    TextEditingController();

  final TextEditingController otpController =
      TextEditingController();

  final TextEditingController secondaryMobileController =
      TextEditingController();

  final TextEditingController vehicleSearchController =
      TextEditingController();

  final TextEditingController descriptionController =
    TextEditingController();

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

    static const Color green =
      Color(0xFF138808);

  static const Color darkText =
      Color(0xFF202124);

  static const Color lightFill =
      Color(0xFFF9F9F9);
  bool isCategoryDropdownOpen = false;
 // bool isStateDropdownOpen = false;


 // ============================================================
  // SHOP TIMINGS
  // ============================================================

  TimeOfDay? openingTime;
  TimeOfDay? closingTime;
  bool isOpen24Hours = false;

  bool privacyPolicyAccepted = false;

  String? privacyPolicyError;

 bool nameError = false;
bool mobileError = false;
bool secondaryMobileError = false;
bool categoryError = false;

  // ============================================================
  // IMAGE
  // ============================================================

  File? selectedProfileImage;
 File? profilePhoto;
  String? profilePhotoUrl;
bool isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();
  // ============================================================
  // OTP
  // ============================================================

  // String? verificationId;

  // bool otpSent = false;
  // bool otpVerified = false;

  // bool isSendingOtp = false;
  // bool isVerifying = false;
  // bool isSubmitting = false;

  // bool otpError = false;

  // String otpErrorMessage = '';

  // int secondsRemaining = 30;

  // Timer? timer;

  String? verificationId;

  bool otpSent = false;
  bool otpVerified = false;
int? resendToken;
  bool isSendingOtp = false;
  bool isVerifying = false;
  bool isSubmitting = false;
  bool isCompletingPhoneAuth = false;

  bool otpError = false;

  String otpErrorMessage = '';

  int secondsRemaining = 60;

   Timer? timer;
  // ===============================================================
  // TIMER
  // ===============================================================

  int remainingSeconds = 0;
  // ============================================================
  // SUBMIT / LOADING
  // ============================================================

  // Prevent duplicate Firestore submissions.
  bool _submitLocked = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
     filteredStates = List<String>.from(indiaStates);

  loadDistricts();

    _loadVehicleCategories();

    vehicleSearchController.addListener(
      _filterVehicleCategories,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    timer?.cancel();
    usernameController.dispose();
    mobileController.dispose();
    otpController.dispose();
    secondaryMobileController.dispose();
    vehicleSearchController.dispose();
    descriptionController.dispose();
    vehicleNumberController .dispose();
    stateSearchController.dispose();
    districtSearchController.dispose();


    super.dispose();
  }

  // ============================================================
  // VEHICLE CATEGORIES
  // ============================================================

  bool isVehicleCategoryDropdownOpen = false;
bool vehicleCategoryError = false;

  List<CourierVehicleCategory>
      allVehicleCategories = [];

  List<CourierVehicleCategory>
      filteredVehicleCategories = [];

  final Set<String> selectedVehicleCategoryIds =
      <String>{};

  bool loadingVehicleCategories = false;

 // bool vehicleCategoryError = false;

  // ============================================================
  // DEFAULT VEHICLE CATEGORIES
  // ============================================================

  final List<CourierVehicleCategory>
      defaultVehicleCategories = const [

    CourierVehicleCategory(
      id: 'bike',
      name: 'Bike',
      iconType: 'bike',
    ),

    CourierVehicleCategory(
      id: 'auto',
      name: 'Auto',
      iconType: 'auto',
    ),

    CourierVehicleCategory(
      id: 'car',
      name: 'Car',
      iconType: 'car',
    ),

    CourierVehicleCategory(
      id: 'van',
      name: 'Van',
      iconType: 'van',
    ),

    CourierVehicleCategory(
      id: 'mini_truck',
      name: 'Mini Truck',
      iconType: 'mini_truck',
    ),

    CourierVehicleCategory(
      id: 'truck',
      name: 'Truck',
      iconType: 'truck',
    ),

    CourierVehicleCategory(
      id: 'cycle',
      name: 'Cycle',
      iconType: 'cycle',
    ),
  ];

  Future<void> _loadVehicleCategories() async {
    if (loadingVehicleCategories) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      loadingVehicleCategories = true;
      vehicleCategoryError = false;
    });

    try {
      /*
       * IMPORTANT:
       *
       * We don't download courier users here.
       *
       * Only the small vehicle-category collection
       * is read.
       *
       * This keeps the registration page lightweight
       * even when there are thousands/millions of
       * courier users.
       */

      final snapshot = await _firestore
          .collection('courierVehicleCategories')
          .orderBy('name')
         // .limit(100)
          .get();

      final List<CourierVehicleCategory>
          categories = [];

      // ----------------------------------------------------------
      // Add built-in categories first.
      // ----------------------------------------------------------

      categories.addAll(
        defaultVehicleCategories,
      );

      // ----------------------------------------------------------
      // Add Firestore custom categories.
      // ----------------------------------------------------------

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final name =
            (data['name'] ?? '')
                .toString()
                .trim();

        if (name.isEmpty) {
          continue;
        }

        final category =
            CourierVehicleCategory.fromMap(
          doc.id,
          data,
        );

        // Avoid duplicate names.
        final alreadyExists =
            categories.any(
          (item) =>
              item.name.toLowerCase() ==
              category.name.toLowerCase(),
        );

        if (!alreadyExists) {
          categories.add(category);
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        allVehicleCategories = categories;
        filteredVehicleCategories =
            List<CourierVehicleCategory>.from(
          categories,
        );

        loadingVehicleCategories = false;
      });
    } catch (e) {
      debugPrint(
        'Courier vehicle category loading error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        /*
         * Even if Firestore fails,
         * built-in categories remain available.
         *
         * This prevents the login page from becoming
         * unusable because of a temporary network error.
         */

        allVehicleCategories =
            List<CourierVehicleCategory>.from(
          defaultVehicleCategories,
        );

        filteredVehicleCategories =
            List<CourierVehicleCategory>.from(
          defaultVehicleCategories,
        );

        vehicleCategoryError = true;
        loadingVehicleCategories = false;
      });
    }
  }

  // ============================================================
  // FILTER VEHICLE CATEGORIES
  // ============================================================

void _filterVehicleCategories() {
  final query =
      vehicleSearchController.text.trim().toLowerCase();

  if (!mounted) {
    return;
  }

  if (query.isEmpty) {
    setState(() {
      filteredVehicleCategories =
          List<CourierVehicleCategory>.from(
        allVehicleCategories,
      );
    });

    return;
  }

  final filtered = allVehicleCategories.where(
    (category) {
      return category.name
          .toLowerCase()
          .contains(query);
    },
  ).toList();

  setState(() {
    filteredVehicleCategories = filtered;
  });
}

  // ============================================================
  // VEHICLE ICON
  // ============================================================

  IconData _vehicleIcon(
    CourierVehicleCategory category,
  ) {
    switch (category.iconType) {
      case 'bike':
        return Icons.two_wheeler_outlined;

      case 'auto':
        return Icons.electric_rickshaw_outlined;

      case 'car':
        return Icons.directions_car_outlined;

      case 'van':
        return Icons.airport_shuttle_outlined;

      case 'mini_truck':
        return Icons.local_shipping_outlined;

      case 'truck':
        return Icons.local_shipping;

      case 'cycle':
        return Icons.pedal_bike_outlined;

      default:
        // Common icon for user-created categories.
        return Icons.local_shipping_outlined;
    }
  }


Future<void> _showAddVehicleCategoryDialog() async {
  final TextEditingController categoryController =
      TextEditingController();

  bool isSaving = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: !isSaving,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> saveCategory() async {
            if (isSaving) return;

            final name = categoryController.text.trim();

            if (name.isEmpty) {
              showMessage(
                'Please enter a vehicle category.',
              );
              return;
            }

            if (name.length > 50) {
              showMessage(
                'Category name is too long.',
              );
              return;
            }

            final duplicate = allVehicleCategories.any(
              (item) =>
                  item.name.trim().toLowerCase() ==
                  name.toLowerCase(),
            );

            if (duplicate) {
              showMessage(
                'This vehicle category already exists.',
              );
              return;
            }

            setDialogState(() {
              isSaving = true;
            });

            try {
              final categoryId =
                  _makeCategoryId(name);

              final categoryRef = _firestore
                  .collection(
                    'courierVehicleCategories',
                  )
                  .doc(categoryId);

              await categoryRef
                  .set({
                    'name': name,
                    'iconType': 'default',
                    'isCustom': true,
                    'createdBy':
                        _auth.currentUser?.uid,
                    'createdAt':
                        FieldValue.serverTimestamp(),
                  })
                  .timeout(
                    const Duration(seconds: 15),
                  );

              final newCategory =
                  CourierVehicleCategory(
                id: categoryId,
                name: name,
                iconType: 'default',
                isCustom: true,
              );

              if (!mounted) return;

              // Add category locally.
              setState(() {
                final exists =
                    allVehicleCategories.any(
                  (item) =>
                      item.id == newCategory.id,
                );

                if (!exists) {
                  allVehicleCategories.add(
                    newCategory,
                  );
                }

                selectedVehicleCategoryIds.add(
                  newCategory.id,
                );

                vehicleCategoryError = false;

                // Refresh filtered categories
                // directly here.
                final query =
                    vehicleSearchController.text
                        .trim()
                        .toLowerCase();

                if (query.isEmpty) {
                  filteredVehicleCategories =
                      List<CourierVehicleCategory>.from(
                    allVehicleCategories,
                  );
                } else {
                  filteredVehicleCategories =
                      allVehicleCategories
                          .where(
                            (item) => item.name
                                .toLowerCase()
                                .contains(query),
                          )
                          .toList();
                }
              });

              // Close the dialog.
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }

              showMessage(
                'Vehicle category added successfully.',
              );
            } on TimeoutException {
              debugPrint(
                'ADD COURIER CATEGORY ERROR: Firestore timeout',
              );

              if (mounted) {
                showMessage(
                  'Unable to add category. '
                  'Please check your internet connection.',
                );
              }
            } catch (e, stackTrace) {
              debugPrint(
                'ADD COURIER CATEGORY ERROR: $e',
              );

              debugPrint(
                'STACK TRACE: $stackTrace',
              );

              if (mounted) {
                showMessage(
                  'Unable to add vehicle category. '
                  'Please try again later.',
                );
              }
            } finally {
              if (dialogContext.mounted) {
                setDialogState(() {
                  isSaving = false;
                });
              }
            }
          }

          return AlertDialog(
            title: const Text(
              'Add Vehicle Category',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),

            content: TextField(
              controller: categoryController,
              autofocus: true,
              enabled: !isSaving,
              textCapitalization:
                  TextCapitalization.words,
              maxLength: 50,
              decoration: const InputDecoration(
                hintText:
                    'Example: Electric Cargo Bike',
                prefixIcon: Icon(
                  Icons.local_shipping_outlined,
                ),
              ),
            ),

            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () {
                        Navigator.of(
                          dialogContext,
                        ).pop();
                      },
                child: const Text('Cancel'),
              ),

              ElevatedButton(
                onPressed:
                    isSaving ? null : saveCategory,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                       Colors.white,
                  foregroundColor: Colors.white,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add',style: TextStyle(color: Colors.black),),
              ),
            ],
          );
        },
      );
    },
  );

  categoryController.dispose();
}

// ============================================================
// CREATE SAFE CATEGORY ID
// ============================================================

String _makeCategoryId(
  String name,
) {
  var value =
      name.trim().toLowerCase();

  value = value.replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '_',
  );

  value = value.replaceAll(
    RegExp(r'_+'),
    '_',
  );

  value = value.replaceAll(
    RegExp(r'^_|_$'),
    '',
  );

  if (value.isEmpty) {
    value = 'custom_vehicle';
  }

  /*
   * Prefix prevents collision with
   * built-in category IDs.
   */

  return 'custom_$value';
}

  // ============================================================
  // VEHICLE CATEGORY SECTION
  // ============================================================

Widget _vehicleCategorySection() {
  final selectedCategories = allVehicleCategories
      .where(
        (item) =>
            selectedVehicleCategoryIds.contains(item.id),
      )
      .toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sectionTitle(
        'Vehicle Category',
       // required: true,
      ),

      const SizedBox(height: 6),

      const Text(
        'Select the vehicle you use for courier service.',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF777777),
        ),
      ),

      const SizedBox(height: 10),

      // ==========================================================
      // CATEGORY FIELD
      // ==========================================================
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: vehicleCategoryError
                ? const Color(0xFFE53935)
                : isVehicleCategoryDropdownOpen
                    ? Colors.green
                    :  Colors.white,
            width: 1.4,
          ),
        ),
        child: Column(
          children: [
            // ======================================================
            // SELECT YOUR CATEGORY
            // ======================================================
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                FocusScope.of(context).unfocus();

                setState(() {
                  isVehicleCategoryDropdownOpen =
                      !isVehicleCategoryDropdownOpen;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.green,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 11),

                    Expanded(
                      child: selectedCategories.isEmpty
                          ? const Text(
                              'Select your category',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF777777),
                              ),
                            )
                          : Text(
                              '${selectedCategories.length} vehicle categor${selectedCategories.length == 1 ? 'y' : 'ies'} selected',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF222222),
                              ),
                            ),
                    ),

                    Icon(
                      isVehicleCategoryDropdownOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF555555),
                    ),
                  ],
                ),
              ),
            ),

            // ======================================================
            // DROPDOWN CONTENT
            // ======================================================
            if (isVehicleCategoryDropdownOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  12,
                ),
                child: Column(
                  children: [
                    const Divider(
                      height: 1,
                      color: Color(0xFFE5E5E5),
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // ADD YOUR OWN CATEGORY
                    // ==================================================
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showAddVehicleCategoryDialog,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE0E3),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.green,
                                size: 21,
                              ),
                            ),

                            const SizedBox(width: 10),

                            const Expanded(
                              child: Text(
                                'Add your own category',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ),

                            const Icon(
                              Icons.chevron_right,
                              color: Colors.green,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // SEARCH CATEGORY
                    // ==================================================
                    TextField(
                      controller: vehicleSearchController,
                      onChanged: (_) {
                        setState(() {
                          _filterVehicleCategories();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search category',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF888888),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 21,
                          color: Color(0xFF777777),
                        ),
                        suffixIcon:
                            vehicleSearchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      size: 19,
                                    ),
                                    onPressed: () {
                                      vehicleSearchController.clear();

                                      setState(() {
                                        _filterVehicleCategories();
                                      });
                                    },
                                  )
                                : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.white,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.white,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.green,
                            width: 1.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // VEHICLE CARDS INSIDE CATEGORY FIELD
                    // ==================================================
                    if (loadingVehicleCategories)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    else if (filteredVehicleCategories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No vehicle category found.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF777777),
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 300,
                        ),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 9,
                            runSpacing: 9,
                            children: filteredVehicleCategories
                                .map(
                                  (category) =>
                                      _vehicleCategoryCard(
                                    category,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),

      // ==========================================================
      // ERROR
      // ==========================================================
      if (vehicleCategoryError)
        const Padding(
          padding: EdgeInsets.only(
            left: 4,
            top: 6,
          ),
          child: Text(
            'Please select at least one vehicle category.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFE53935),
            ),
          ),
        ),

      // ==========================================================
      // SELECTED COUNT
      // ==========================================================
      if (selectedCategories.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            top: 6,
          ),
          child: Text(
            '${selectedCategories.length} category${selectedCategories.length == 1 ? '' : 'ies'} selected',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF777777),
            ),
          ),
        ),
    ],
  );
}

  // ============================================================
  // VEHICLE CATEGORY CARD
  // ============================================================

  Widget _vehicleCategoryCard(
    CourierVehicleCategory category,
  ) {
    final selected =
        selectedVehicleCategoryIds
            .contains(category.id);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            selectedVehicleCategoryIds
                .remove(category.id);
          } else {
            selectedVehicleCategoryIds
                .add(category.id);
          }
        });
      },

      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),

        width: 105,

        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 8,
        ),

        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFEBEE)
              : Colors.white,

          borderRadius:
              BorderRadius.circular(14),

          border: Border.all(
            color: selected
                ?  Colors.green
                : Colors.black12,

            width: selected ? 1.5 : 1,
          ),
        ),

        child: Column(
          children: [

            Container(
              width: 44,
              height: 44,

              decoration:
                  BoxDecoration(
                color: selected
                    ?  Colors.green.withValues(alpha: 0.10)
                    : Colors.white,
                shape: BoxShape.circle,
              ),

              child: Icon(
                _vehicleIcon(category),

                color: selected
                    ? Colors.green
                    : Colors.black54,

                size: 25,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              category.name,

              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected
                        ? FontWeight.w700
                        : FontWeight.w500,

                color: selected
                    ? Colors.green
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ============================================================

void showMessage(
  String message, {
  bool isError = false,
}) {
  if (!mounted) {
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor:
            isError ? Colors.red : const Color(0xFF16803C),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
  // ============================================================
  // PROFILE PHOTO UI
  // ============================================================

 
  Future<void> pickProfilePhoto() async {
  final ImageSource? source =
      await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      );
    },
  );

  if (source == null) return;

  File? selectedFile;

  if (source == ImageSource.camera) {
    if (!mounted) return;

    final navigator = Navigator.of(context);

    selectedFile = await navigator.push<File>(
      MaterialPageRoute(
        builder: (_) => const ScreenCameraCapture(),
      ),
    );

    if (!mounted) return;
  } else {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (pickedFile != null) {
      selectedFile = File(pickedFile.path);
    }
  }

  if (selectedFile == null || !mounted) return;

 setState(() {
  profilePhoto = selectedFile;
});
}

  Future<String?> uploadProfilePhoto(String uid) async {
  if (profilePhoto == null) return profilePhotoUrl;

  try {
    final Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('profilePhotos')
        .child(uid)
        .child('profile.jpg');

    await storageRef.putFile(
      profilePhoto!,
      SettableMetadata(
        contentType: 'image/jpeg',
      ),
    );

    final String downloadUrl =
        await storageRef.getDownloadURL();

    return downloadUrl;
  } catch (e) {
    debugPrint('Profile photo upload error: $e');
    return null;
  }
}

  Widget _profilePhotoSection() {
  return GestureDetector(
    onTap: isSubmitting ? null : pickProfilePhoto,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // PROFILE PHOTO
          CircleAvatar(
            radius: 32,
            backgroundImage: profilePhoto != null
                ? FileImage(profilePhoto!)
                : (profilePhotoUrl != null &&
                        profilePhotoUrl!.isNotEmpty)
                    ? NetworkImage(profilePhotoUrl!)
                        as ImageProvider
                    : null,
            child: profilePhoto == null &&
                    (profilePhotoUrl == null ||
                        profilePhotoUrl!.isEmpty)
                ? const Icon(
                    Icons.person,
                    size: 32,
                    color: Colors.grey,
                  )
                : null,
          ),

          const SizedBox(width: 14),

          // TEXT
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add a profile photo (optional)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.camera_alt_outlined,
            color: Colors.red,
          ),
        ],
      ),
    ),
  );
}

 InputDecoration fieldDecoration({
  required String hintText,
   bool hasError = false,
  IconData? icon,
}) {
  return InputDecoration(
    hintText: hintText,

    prefixIcon: icon == null
        ? null
        : Icon(
            icon,
            color: const Color(0xFF16803C),
            size: 27,
          ),

    filled: true,

    fillColor: const Color(0xFFF9F9F9),

    contentPadding: const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 18,
    ),

    hintStyle: const TextStyle(
      color: Color(0xFF777777),
      fontSize: 16,
    ),

    // ==========================================================
    // NORMAL BORDER
    // ==========================================================

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(
        color: hasError
            ? Colors.red
            : const Color(0xFFD5D5D5),
        width: hasError ? 2 : 1.5,
      ),
    ),

    // ==========================================================
    // FOCUSED BORDER
    // ==========================================================

    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(
        color: hasError
            ? Colors.red
            : const Color(0xFF16803C),
        width: 2,
      ),
    ),

    // ==========================================================
    // ERROR BORDER
    // ==========================================================

    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(
        color: Colors.red,
        width: 2,
      ),
    ),

    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(
        color: Colors.red,
        width: 2,
      ),
    ),

    errorStyle: const TextStyle(
      color: Colors.red,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  );
}
 
  // ============================================================
  // MOBILE OTP SECTION
  // ============================================================
   Widget mobileSection() {
    // final bool verified =
    //     otpVerified;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        Container(
          height: 62,

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFF9F9F9,
            ),

            borderRadius:
                BorderRadius.circular(
              20,
            ),

            border: Border.all(
  color: otpVerified
      ? const Color(0xFF16803C)
      : mobileError
          ? Colors.red
          : const Color(0xFFD5D5D5),
  width: otpVerified || mobileError
      ? 2
      : 1.5,
),
          ),

          child: Row(
            children: [

              const SizedBox(
                width: 14,
              ),

              const Icon(
                Icons.phone,
                color:
                    Color(0xFF16803C),
                size: 27,
              ),

              const SizedBox(
                width: 10,
              ),

              const Text(
                '+91',
                style:
                    TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Color(0xFF333333),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: TextField(
                  controller:
                      mobileController,

                  enabled:
                      !otpVerified,

                  keyboardType:
                      TextInputType.phone,

                  maxLength: 10,

                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly,
                  ],

                  onChanged: (_) {
  if (mobileError) {
    setState(() {
      mobileError = false;
    });
  }
},

                  decoration:
                      const InputDecoration(
                    hintText:
                        'Mobile number',

                    hintStyle:
                        TextStyle(
                      color:
                          Color(0xFF777777),
                      fontSize: 16,
                    ),

                    counterText: '',

                    border:
                        InputBorder.none,

                    contentPadding:
                        EdgeInsets.zero,
                  ),
                ),
              ),

              if (otpVerified)
                TextButton(
                  onPressed:
                      changeMobileNumber,

                  child:
                      const Text(
                    'Change',
                    style:
                        TextStyle(
                      color:
                          Color(
                        0xFF16803C,
                      ),
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed:
                      isSendingOtp
                          ? null
                          : sendOTP,

                  child:
                      isSendingOtp
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                color:
                                    Color(
                                  0xFF16803C,
                                ),
                              ),
                            )
                          : const Text(
                              'Send OTP',
                              style:
                                  TextStyle(
                                color:
                                    Color(
                                  0xFF16803C,
                                ),
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                ),

              const SizedBox(
                width: 5,
              ),
            ],
          ),
        ),

        // ========================================================
        // VERIFIED MESSAGE
        // ========================================================

        if (otpVerified)
          Container(
            width:
                double.infinity,

            margin:
                const EdgeInsets.only(
              top: 10,
            ),

            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFEAF7EE,
              ),

              borderRadius:
                  BorderRadius.circular(
                14,
              ),

              border: Border.all(
                color:
                    const Color(
                  0xFF8BC99D,
                ),
              ),
            ),

            child: const Row(
              children: [

                Icon(
                  Icons
                      .check_circle,
                  color:
                      Color(
                    0xFF16803C,
                  ),
                  size: 21,
                ),

                SizedBox(
                  width: 8,
                ),

                Text(
                  'Phone number verified',
                  style:
                      TextStyle(
                    color:
                        Color(
                      0xFF16803C,
                    ),
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
           if (mobileError)
   Padding(
    padding: EdgeInsets.only(left: 12, top: 5),
    child: Text( AppLocalizations.of(context)!.enteradigitmobilenumber,
    //  'Enter a valid 10-digit mobile number.',
      style: TextStyle(
        color: Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
      ],
    );
  }
  
  // ============================================================
  // OTP SECTION
  // ============================================================

  Widget otpSection() {
    if (!otpSent) {
      return const SizedBox.shrink();
    }

    final borderColor = otpError
        ? Colors.red
        : const Color(
            0xFF8BC99D,
          );

    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        top: 14,
        bottom: 24,
      ),

      padding:
          const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        16,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF1F8F3,
        ),

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color: borderColor,
          width:
              otpError ? 2 : 1.3,
        ),
      ),

      child: Column(
        children: [

          // ======================================================
          // HEADER
          // ======================================================

          Row(
            children: [

              Container(
                width: 40,
                height: 40,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF16803C,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child:
                    const Icon(
                  Icons.lock_outline,
                  color:
                      Colors.white,
                  size: 21,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              const Expanded(
                child: Text(
                  'Enter 6-digit OTP',
                  style:
                      TextStyle(
                    color:
                        Color(
                      0xFF12652F,
                    ),
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              if (isVerifying)
                const SizedBox(
                  width: 21,
                  height: 21,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                        Color(
                      0xFF16803C,
                    ),
                  ),
                )
              else
                Text(
                  '${secondsRemaining}s',
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFFED801D,
                    ),
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          // ======================================================
          // SINGLE OTP FIELD
          // ======================================================

          TextField(
            controller:
                otpController,
            
            autofillHints: const [
  AutofillHints.oneTimeCode,
],
            // enabled:
            //     !isVerifying,
            enabled: !isVerifying &&
    !isSendingOtp &&
    secondsRemaining > 0,

            keyboardType:
                TextInputType.number,

            textInputAction:
                TextInputAction.done,

            textAlign:
                TextAlign.center,

            maxLength: 6,

            autofocus: true,

            inputFormatters: [
              FilteringTextInputFormatter
                  .digitsOnly,
            ],

            style:
                const TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.w600,
              letterSpacing: 8,
              color:
                  Colors.black,
            ),

            decoration:
                InputDecoration(
              counterText: '',

              hintText: '------',

              hintStyle:
                  const TextStyle(
                color:
                    Color(0xFFAAAAAA),
                fontSize: 23,
                letterSpacing: 7,
              ),

              filled: true,

              fillColor:
                  Colors.white,

              contentPadding:
                  const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 18,
              ),

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                borderSide:
                    BorderSide(
                  color:
                      borderColor,
                  width:
                      otpError ? 2 : 1.3,
                ),
              ),

              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                borderSide:
                    BorderSide(
                  color:
                      borderColor,
                  width:
                      otpError ? 2 : 1.3,
                ),
              ),

              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                borderSide:
                    BorderSide(
                  color: otpError
                      ? Colors.red
                      : const Color(
                          0xFF16803C,
                        ),
                  width: 2,
                ),
              ),
            ),

            onChanged:
                onOtpChanged,

            onSubmitted:
                (_) {
              if (otpController
                      .text
                      .length ==
                  6) {
                verifyOTP();
              }
            },
          ),

          // ======================================================
          // ERROR MESSAGE
          // ======================================================

          if (otpError &&
              otpErrorMessage
                  .isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 8,
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  const Icon(
                    Icons
                        .error_outline,
                    color:
                        Colors.red,
                    size: 18,
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  Expanded(
                    child: Text(
                      otpErrorMessage,

                      style:
                          const TextStyle(
                        color:
                            Colors.red,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(
            height: 6,
          ),

          // ======================================================
          // RESEND + CHANGE
          // ======================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              if (secondsRemaining == 0)
  TextButton(
    onPressed: isSendingOtp
        ? null
        : resendOTP,
    child: isSendingOtp
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF16803C),
            ),
          )
        : const Text(
            'Resend OTP',
            style: TextStyle(
              color: Color(0xFF16803C),
              fontWeight: FontWeight.bold,
            ),
          ),),

              if (secondsRemaining == 0)
                const SizedBox(
                  width: 4,
                ),

              TextButton(
                onPressed:
                    isVerifying
                        ? null
                        : changeMobileNumber,

                child:
                    const Text(
                  'Change Number',
                  style:
                      TextStyle(
                    color:
                        Color(
                      0xFF16803C,
                    ),
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

 // ============================================================
// SECONDARY MOBILE NUMBER
// ============================================================
 Widget secondaryMobileSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Secondary Mobile Number',
        style: TextStyle(
          color: Color(0xFF252525),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 8),

   TextField(
  controller: secondaryMobileController,
  keyboardType: TextInputType.phone,
  maxLength: 10,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
  ],
  onChanged: (_) {
    if (secondaryMobileError) {
      setState(() {
        secondaryMobileError = false;
      });
    }
  },
  decoration: fieldDecoration(
    hintText: 'Enter secondary mobile number',
    icon: Icons.phone_android_outlined,
    hasError: secondaryMobileError,
  ).copyWith(
    counterText: '',
  ),
),

if (secondaryMobileError)
  const Padding(
    padding: EdgeInsets.only(left: 12, top: 5),
    child: Text(
      'Please enter a valid 10-digit secondary mobile number.',
      style: TextStyle(
        color: Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),

      const SizedBox(height: 5),

      const Text(
        'You can use same Number,if another Number is not available.',
        style: TextStyle(
          color: Color(0xFF777777),
          fontSize: 12,
        ),
      ),
      const  Text(
        'Note : This number will be shown to users when they choose to call you.',
        style: TextStyle(
          color: Color(0xFF777777),
          fontSize: 12,
        ),
      ),
    ],
  );
}

        final TextEditingController nearestCityController =
    TextEditingController();

String stateError = '';
String districtError = '';
String nearestCityError = '';
bool isStateDropdownOpen = false;

String? selectedState;

final TextEditingController stateSearchController =
    TextEditingController();

List<String> filteredStates = [];

static const List<String> indiaStates = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Keralam',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
];
void filterStates(String value) {
  final languageCode = currentLanguageCode(context);
  final search = value.trim().toLowerCase();

  final result = indiaStates.where((state) {
    final englishName = state.toLowerCase();

    final translatedName =
        localizedState(state, languageCode).toLowerCase();

    return search.isEmpty ||
        englishName.contains(search) ||
        translatedName.contains(search);
  }).toList();

  if (!mounted) return;

  setState(() {
    filteredStates = result;
  });
}

String? selectedDistrict;

bool isDistrictDropdownOpen = false;

final TextEditingController districtSearchController =
    TextEditingController();

List<String> filteredDistricts = [];

Map<String, List<String>> indiaDistricts = {};

List<String> get availableDistricts {
  if (selectedState == null ||
      selectedState!.trim().isEmpty) {
    return indiaDistricts.values
        .expand((districts) => districts)
        .toSet()
        .toList();
  }

  return List<String>.from(
    indiaDistricts[selectedState!] ?? [],
  );
}
void filterDistricts(String value) {
  final languageCode = currentLanguageCode(context);
  final search = value.trim().toLowerCase();

  final result = availableDistricts.where((district) {
    final englishName = district.toLowerCase();

    final translatedName =
        localizedDistrict(district, languageCode).toLowerCase();

    return search.isEmpty ||
        englishName.contains(search) ||
        translatedName.contains(search);
  }).toList();

  if (!mounted) return;

  setState(() {
    filteredDistricts = result;
  });
}

Future<void> loadDistricts() async {
  final String jsonString = await rootBundle.loadString(
    'assets/data/india_districts.json',
  );

  final Map<String, dynamic> data =
      json.decode(jsonString);

  if (!mounted) return;

  setState(() {
    indiaDistricts = data.map(
      (key, value) => MapEntry(
        key,
        List<String>.from(value),
      ),
    );

    filteredDistricts =
        List<String>.from(availableDistricts);
  });
}


  Widget stateSection() {
    final languageCode = currentLanguageCode(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sectionTitle( AppLocalizations.of(context)!.state
       // 'State',
      ),

      AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        decoration: BoxDecoration(
          color: lightFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: stateError.isNotEmpty
                ? Colors.red
                : isStateDropdownOpen
                    ? green
                    : Colors.grey.shade300,
            width: stateError.isNotEmpty ||
                    isStateDropdownOpen
                ? 1.5
                : 1,
          ),
        ),
        child: Column(
          children: [
            // ==================================================
            // STATE HEADER
            // ==================================================

            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                FocusScope.of(context).unfocus();

                setState(() {
                 isStateDropdownOpen =
                      !isStateDropdownOpen;

                  if (isStateDropdownOpen) {
                    filteredStates =
                        List<String>.from(indiaStates);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: green,
                      size: 22,
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Text(
                        selectedState == null ||
                                selectedState!.isEmpty
                            ? AppLocalizations.of(context)!.selectyourState
                            // 'Select your State'
                            : localizedState(selectedState!, languageCode),
                            //selectedState!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              selectedState == null ||
                                      selectedState!.isEmpty
                                  ? Colors.grey.shade500
                                  : darkText,
                          fontSize: 15,
                          fontWeight:
                              selectedState == null ||
                                      selectedState!.isEmpty
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                        ),
                      ),
                    ),

                    Icon(
                     isStateDropdownOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: green,
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // STATE DROPDOWN
            // ==================================================

            if (isStateDropdownOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  12,
                ),
                child: Column(
                  children: [
                    // ==================================================
                    // SEARCH STATE
                    // ==================================================

                    TextField(
                      controller: stateSearchController,
                      onChanged: filterStates,
                      decoration: InputDecoration(
                       // hintText: 'Search state...',
                       hintText: AppLocalizations.of(context)!.searchState,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: green,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: green,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Divider(
                      height: 8,
                    ),

                    // ==================================================
                    // STATE LIST
                    // ==================================================

                    SizedBox(
                      height: 320,
                      child: filteredStates.isEmpty
                          ? Center(
                              child: Text( AppLocalizations.of(context)!.nostatefound,
                              //  'No state found',
                                style: TextStyle(
                                  color:
                                      Colors.grey.shade600,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount:
                                  filteredStates.length,
                              itemBuilder:
                                  (context, index) {
                                final state =
                                    filteredStates[index];

                                final bool isSelected =
                                    selectedState == state;

                                return InkWell(
                                  borderRadius:
                                      BorderRadius.circular(
                                    10,
                                  ),
                                  onTap: () {
                                    // setState(() {
                                    //   selectedState = state;

                                    //   categoryError =
                                    //       false;

                                    //   isCategoryDropdownOpen =
                                    //       false;

                                    //   stateSearchController
                                    //       .clear();

                                    //   filteredStates =
                                    //       List<String>.from(
                                    //     indiaStates,
                                    //   );
                                    // });
                                    setState(() {
  final bool stateChanged = selectedState != state;

  selectedState = state;

  if (stateChanged) {
    selectedDistrict = null;
    districtSearchController.clear();
    filteredDistricts = List<String>.from(
      indiaDistricts[state] ?? [],
    );
  }

  stateError = '';
  isStateDropdownOpen = false;

  stateSearchController.clear();
  filteredStates = List<String>.from(indiaStates);
});
                                  },
                                 
                                  child: Container(
                                    margin:
                                        const EdgeInsets
                                            .symmetric(
                                      vertical: 2,
                                    ),
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: isSelected
                                          ? green.withValues(
                                              alpha: 0.08,
                                            )
                                          : Colors
                                              .transparent,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        10,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons
                                                  .radio_button_checked
                                              : Icons
                                                  .radio_button_unchecked,
                                          color: isSelected
                                              ? green
                                              : Colors
                                                  .grey
                                                  .shade400,
                                          size: 21,
                                        ),

                                        const SizedBox(
                                          width: 12,
                                        ),

                                        Expanded(
                                          child:
                                          //  Text(
                                          //   state,
                                          //   style:
                                          //       const TextStyle(
                                          //     color: darkText,
                                          //     fontSize: 14,
                                          //   ),
                                          // ),
                                          Text(localizedState(state, languageCode) ,
                                          style:
                                                const TextStyle(
                                              color: darkText,
                                              fontSize: 14,
                                            ),
                                            )
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),

      // ==================================================
      // ERROR
      // ==================================================

      if (stateError.isNotEmpty)
         Padding(
          padding: EdgeInsets.only(
            left: 12,
            top: 5,
          ),
          child: Text( AppLocalizations.of(context)!.pleaseSelectyourState,
            //'Please select your state.',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
    ],
  );
}

//Widget districtSection() {
Widget districtSection() {
  final languageCode = currentLanguageCode(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      //sectionTitle('District'),
      sectionTitle(AppLocalizations.of(context)!.district),

      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: lightFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: districtError.isNotEmpty
                ? Colors.red
                : isDistrictDropdownOpen
                    ? green
                    : Colors.grey.shade300,
            width: districtError.isNotEmpty ||
                    isDistrictDropdownOpen
                ? 1.5
                : 1,
          ),
        ),
        child: Column(
          children: [
            // =====================================================
            // DISTRICT HEADER
            // =====================================================

            InkWell(
              borderRadius: BorderRadius.circular(20),

              onTap: () {
                FocusScope.of(context).unfocus();

                setState(() {
                  isDistrictDropdownOpen =
                      !isDistrictDropdownOpen;

                  if (isDistrictDropdownOpen) {
                    filteredDistricts =
                        List<String>.from(
                      availableDistricts,
                    );

                    districtSearchController.clear();
                  }
                });
              },

              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: green,
                      size: 22,
                    ),

                    const SizedBox(width: 12),

                    // SELECTED DISTRICT
                    Expanded(
                      child: Text(
                        selectedDistrict == null ||
                                selectedDistrict!.isEmpty
                            // ? 'Select your District'
                            // : selectedDistrict!,
                            ? AppLocalizations.of(context)!.selectyourDistrict
: localizedDistrict(selectedDistrict!, languageCode),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selectedDistrict ==
                                      null ||
                                  selectedDistrict!
                                      .isEmpty
                              ? Colors.grey.shade500
                              : darkText,
                          fontSize: 15,
                          fontWeight:
                              selectedDistrict ==
                                          null ||
                                      selectedDistrict!
                                          .isEmpty
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                        ),
                      ),
                    ),

                    Icon(
                      isDistrictDropdownOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: green,
                    ),
                  ],
                ),
              ),
            ),

            // =====================================================
            // DROPDOWN
            // =====================================================

            if (isDistrictDropdownOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  12,
                ),

                child: Column(
                  children: [
                    // =================================================
                    // SEARCH
                    // =================================================

                    TextField(
                      controller:
                          districtSearchController,

                      onChanged: filterDistricts,

                      decoration:
                          InputDecoration(
                        // hintText:
                        //     'Search district...',
                        hintText: AppLocalizations.of(context)!.searchdistrict,

                        prefixIcon:
                            const Icon(
                          Icons.search,
                          color: green,
                        ),

                        filled: true,
                        fillColor: Colors.white,

                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          borderSide: BorderSide(
                            color: Colors
                                .grey
                                .shade300,
                          ),
                        ),

                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          borderSide: BorderSide(
                            color: Colors
                                .grey
                                .shade300,
                          ),
                        ),

                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          borderSide:
                              const BorderSide(
                            color: green,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Divider(height: 8),

                    // =================================================
                    // DISTRICT LIST
                    // =================================================

                    SizedBox(
                      height: 320,

                      child: filteredDistricts
                              .isEmpty
                          ? Center(
                              child: Text(
                                'No district found',
                                style: TextStyle(
                                  color: Colors
                                      .grey
                                      .shade600,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount:
                                  filteredDistricts
                                      .length,

                              itemBuilder:
                                  (context, index) {
                                final district =
                                    filteredDistricts[
                                        index];

                                final bool
                                    isSelected =
                                    selectedDistrict ==
                                        district;

                                return InkWell(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),

                                  // ===================================
                                  // SELECT DISTRICT
                                  // ===================================

                                  onTap: () {
                                    setState(() {
                                      selectedDistrict =
                                          district;

                                      districtError = '';

                                      isDistrictDropdownOpen =
                                          false;

                                      districtSearchController
                                          .clear();

                                      filteredDistricts =
                                          List<String>
                                              .from(
                                        availableDistricts,
                                      );
                                    });
                                  },

                                  child: Container(
                                    margin:
                                        const EdgeInsets
                                            .symmetric(
                                      vertical: 2,
                                    ),

                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),

                                    decoration:
                                        BoxDecoration(
                                      color: isSelected
                                          ? green.withValues(
                                              alpha: 0.08,
                                            )
                                          : Colors
                                              .transparent,

                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        10,
                                      ),
                                    ),

                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons
                                                  .radio_button_checked
                                              : Icons
                                                  .radio_button_unchecked,

                                          color: isSelected
                                              ? green
                                              : Colors
                                                  .grey
                                                  .shade400,

                                          size: 21,
                                        ),

                                        const SizedBox(
                                          width: 12,
                                        ),

                                        Expanded(
                                          // child: Text(
                                          //   district,
                                          //   style:
                                          //       const TextStyle(
                                          //     color:
                                          //         darkText,
                                          //     fontSize:
                                          //         14,
                                          //   ),
                                          // ),
                                          child: Text(
  localizedDistrict(district, languageCode),
  style: const TextStyle(
    color: darkText,
    fontSize: 14,
  ),
),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),

      // =====================================================
      // ERROR
      // =====================================================

      if (districtError.isNotEmpty)
         Padding(
          padding: EdgeInsets.only(
            left: 12,
            top: 5,
          ),
          child: Text( AppLocalizations.of(context)!.pleaseselectyourdistrict,
          //  'Please select your district.',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
    ],
  );
}

  // ============================================================
  // SUBMIT BUTTON
  // ============================================================

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,

      height: 52,

      child: ElevatedButton(
        onPressed:
            isSubmitting
                ? null
                : _submitCourier,

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
               Colors.green,

          disabledBackgroundColor:
              Colors.grey.shade400,

          elevation: 0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),

        child: isSubmitting
            ? const SizedBox(
                width: 23,
                height: 23,

                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Submit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================
 Widget sectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF202124),
      ),
    );
  }
  // ============================================================
// PART 2
// OTP + CUSTOM VEHICLE CATEGORY
// ============================================================

  // ==============================================================
  // SEND OTP
  // ===============================================================

Future<void> sendOTP({bool isResend = false}) async {
  if (isSendingOtp || isVerifying) return;

  final phone = mobileController.text.trim();

  if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
    showMessage(AppLocalizations.of(context)!.enteradigitmobilenumber,
    //  'Enter a valid 10-digit mobile number.'
      );
    return;
  }

  if (isResend && secondsRemaining > 0) {
    showMessage('Please wait ${secondsRemaining}s.');
    return;
  }

  if (!isResend && otpSent && secondsRemaining > 0) {
    showMessage('Please wait before requesting another OTP.');
    return;
  }

  FocusScope.of(context).unfocus();
  timer?.cancel();

  setState(() {
    isSendingOtp = true;
    otpVerified = false;
    otpError = false;
    otpErrorMessage = '';
    otpController.clear();

    if (!isResend) {
      otpSent = false;
    }
  });

  try {
    await auth.verifyPhoneNumber(
      phoneNumber: '+91$phone',

      timeout: const Duration(seconds: 60),

      // Reuse Firebase resend token for faster resend handling.
      forceResendingToken: isResend ? resendToken : null,

      // AUTOMATIC VERIFICATION
      verificationCompleted:
          (PhoneAuthCredential credential) async {
        if (isCompletingPhoneAuth) return;

        isCompletingPhoneAuth = true;

        try {
          await auth.signInWithCredential(credential);

          if (!mounted) return;

          timer?.cancel();

          setState(() {
            otpVerified = true;
            otpSent = false;
            isSendingOtp = false;
            isVerifying = false;
            isCompletingPhoneAuth = false;
            otpError = false;
            otpErrorMessage = '';
            secondsRemaining = 0;
          });

          otpController.clear();

          showMessage('Mobile number verified successfully.');

        } catch (e) {
          if (!mounted) return;

          setState(() {
            isSendingOtp = false;
            isVerifying = false;
            isCompletingPhoneAuth = false;
            otpError = true;
            otpErrorMessage =
                'Automatic verification failed. Please enter OTP manually.';
          });
        }
      },

      // VERIFICATION FAILED
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;

        timer?.cancel();

        setState(() {
          isSendingOtp = false;
          otpError = true;

          if (!isResend) {
            otpSent = false;
          }

          switch (e.code) {
            case 'invalid-phone-number':
              otpErrorMessage = 'Invalid mobile number.';
              break;

            case 'too-many-requests':
              otpErrorMessage =
                  'Too many requests. Please try again later.';
              break;

            case 'quota-exceeded':
              otpErrorMessage =
                  'OTP limit reached. Please try again later.';
              break;

            case 'network-request-failed':
              otpErrorMessage =
                  'Network error. Check your internet connection.';
              break;

            case 'app-not-authorized':
              otpErrorMessage =
                  'This app is not authorized for Firebase Phone Authentication.';
              break;

            default:
              otpErrorMessage =
                  e.message ?? 'Could not send OTP.';
          }
        });

        showMessage(otpErrorMessage);
      },

      // OTP SENT
      codeSent: (String id, int? token) {
        if (!mounted) return;

        verificationId = id;
        resendToken = token;

        otpController.clear();

        setState(() {
          otpSent = true;
          otpVerified = false;
          isSendingOtp = false;
          isVerifying = false;
          otpError = false;
          otpErrorMessage = '';
          secondsRemaining = 60;
        });

        startOtpTimer();

        showMessage(
          isResend
              ? 'New OTP sent successfully.'
              : 'OTP sent successfully.',
        );
      },

      // AUTOMATIC RETRIEVAL TIMEOUT
      codeAutoRetrievalTimeout: (String id) {
        verificationId = id;
      },
    );
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isSendingOtp = false;
      otpError = true;

      if (!isResend) {
        otpSent = false;
      }

      otpErrorMessage =
          'Unable to send OTP. Please try again.';
    });

    debugPrint('sendOTP error: $e');
  }
}

  // ===============================================================
  // START OTP TIMER
  // ===============================================================

  void startOtpTimer() {
  timer?.cancel();

  if (!mounted) return;

  setState(() {
    secondsRemaining = 60;
  });

  timer = Timer.periodic(
    const Duration(seconds: 1),
    (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      if (secondsRemaining > 1) {
        setState(() {
          secondsRemaining--;
        });
      } else {
        t.cancel();

        setState(() {
          secondsRemaining = 0;
          otpController.clear();
          otpError = false;
          otpErrorMessage = '';
        });
      }
    },
  );
}

void onOtpChanged(String value) {
  if (secondsRemaining <= 0 ||
      isVerifying ||
      isSendingOtp) {
    return;
  }

  if (otpError) {
    setState(() {
      otpError = false;
      otpErrorMessage = '';
    });
  }

  if (value.length == 6 && !otpVerified) {
    verifyOTP();
  }
}

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> verifyOTP() async {
  if (isVerifying || isCompletingPhoneAuth) return;

  if (secondsRemaining <= 0) {
    otpController.clear();

    setState(() {
      otpError = true;
      otpErrorMessage =
          'OTP expired. Please request a new OTP.';
    });

    return;
  }

  final otp = otpController.text.trim();

  if (verificationId == null || verificationId!.isEmpty) {
    setState(() {
      otpError = true;
      otpErrorMessage = 'Please send OTP first.';
    });
    return;
  }

  if (otp.length != 6) {
    setState(() {
      otpError = true;
      otpErrorMessage = 'Enter the complete 6-digit OTP.';
    });
    return;
  }

  FocusScope.of(context).unfocus();

  setState(() {
    isVerifying = true;
    isCompletingPhoneAuth = true;
    otpError = false;
    otpErrorMessage = '';
  });

  try {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId!,
      smsCode: otp,
    );

    await auth.signInWithCredential(credential);

    if (!mounted) return;

    timer?.cancel();

    setState(() {
      isVerifying = false;
      isCompletingPhoneAuth = false;
      otpVerified = true;
      otpSent = false;
      otpError = false;
      otpErrorMessage = '';
      secondsRemaining = 0;
    });

    otpController.clear();

    showMessage('Mobile number verified successfully.');

  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    setState(() {
      isVerifying = false;
      isCompletingPhoneAuth = false;
      otpError = true;

      switch (e.code) {
        case 'invalid-verification-code':
          otpErrorMessage = 'Incorrect OTP. Please try again.';
          break;

        case 'session-expired':
          otpErrorMessage = 'OTP expired. Request a new OTP.';
          break;

        case 'invalid-verification-id':
          otpErrorMessage = 'Verification session expired.';
          break;

        case 'credential-already-in-use':
          otpErrorMessage =
              'This mobile number is already registered.';
          break;

        default:
          otpErrorMessage =
              e.message ?? 'OTP verification failed.';
      }
    });

  } catch (e) {
    if (!mounted) return;

    setState(() {
      isVerifying = false;
      isCompletingPhoneAuth = false;
      otpError = true;
      otpErrorMessage = 'OTP verification failed.';
    });

    debugPrint('verifyOTP error: $e');
  }
}

  void changeMobileNumber() {
    timer?.cancel();
resendToken = null;
isCompletingPhoneAuth = false;
    verificationId = null;

    otpController.clear();

    if (!mounted) return;

    setState(() {
      otpSent = false;
      otpVerified = false;
      isSendingOtp = false;
      isVerifying = false;
      otpError = false;
      otpErrorMessage = '';
      secondsRemaining = 30;
    });
  }

  // ===============================================================
  // RESEND OTP
  // ===============================================================

  Future<void> resendOTP() async {
  if (isSendingOtp || isVerifying) return;

  if (secondsRemaining > 0) {
    showMessage(
      'Please wait ${secondsRemaining}s.',
    );
    return;
  }

  await sendOTP(isResend: true);
}


// ============================================================
// NORMALIZE MOBILE
// ============================================================

String _normalizedMobile(
  String value,
) {
  var mobile =
      value.trim();

  mobile = mobile.replaceAll(
    RegExp(r'[\s\-()]'),
    '',
  );

  if (mobile.startsWith('+91')) {
    mobile =
        mobile.substring(3);
  } else if (mobile.startsWith('91') &&
      mobile.length == 12) {
    mobile =
        mobile.substring(2);
  }

  return mobile;
}

 Widget shopTimingSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sectionTitle(
        'Shop Timing',
      ),

      const SizedBox(height: 10),

      // ============================================================
      // OPEN 24 HOURS BUTTON
      // ============================================================

      SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              isOpen24Hours = !isOpen24Hours;

              // Clear selected times when 24 hours is enabled
              if (isOpen24Hours) {
                openingTime = null;
                closingTime = null;
              }
            });
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: isOpen24Hours
                ? const Color(0xFF16803C)
                : const Color(0xFFF9F9F9),

            foregroundColor: isOpen24Hours
                ? Colors.white
                : const Color(0xFF16803C),

            side: BorderSide(
              color: isOpen24Hours
                  ? const Color(0xFF16803C)
                  : Colors.grey.shade300,
              width: 1.5,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),

            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOpen24Hours
                    ? Icons.check_circle
                    : Icons.access_time,
                size: 21,
              ),

              const SizedBox(width: 8),

              Text(
                isOpen24Hours
                    ? '✓ Open 24 Hours'
                    : 'Open 24 Hours',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),

      // ============================================================
      // OPENING / CLOSING TIME
      // ============================================================

      if (!isOpen24Hours) ...[
        const SizedBox(height: 12),

        Row(
          children: [
            // ========================================================
            // OPENING TIME
            // ========================================================

            Expanded(
              child: InkWell(
                onTap: selectOpeningTime,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 62,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF16803C),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          openingTime == null
                              ? 'Opening Time'
                              : timeToString(
                                  openingTime!,
                                ),
                          style: TextStyle(
                            fontSize: 15,
                            color: openingTime == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ========================================================
            // CLOSING TIME
            // ========================================================

            Expanded(
              child: InkWell(
                onTap: selectClosingTime,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 62,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF16803C),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          closingTime == null
                              ? 'Closing Time'
                              : timeToString(
                                  closingTime!,
                                ),
                          style: TextStyle(
                            fontSize: 15,
                            color: closingTime == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ],
  );
}

    // ============================================================
  // OPENING TIME
  // ============================================================

  Future<void> selectOpeningTime() async {
    final TimeOfDay? selected =
        await showTimePicker(
      context: context,
      initialTime:
          openingTime ?? TimeOfDay.now(),
    );

    if (selected == null) return;

    if (!mounted) return;

    setState(() {
      openingTime = selected;
    });
  }

  // ============================================================
  // CLOSING TIME
  // ============================================================

  Future<void> selectClosingTime() async {
    final TimeOfDay? selected =
        await showTimePicker(
      context: context,
      initialTime:
          closingTime ?? TimeOfDay.now(),
    );

    if (selected == null) return;

    if (!mounted) return;

    setState(() {
      closingTime = selected;
    });
  }

  // ============================================================
  // TIME TO STRING
  // ============================================================

  String timeToString(TimeOfDay time) {
    final int hour =
        time.hourOfPeriod == 0
            ? 12
            : time.hourOfPeriod;

    final String minute =
        time.minute.toString().padLeft(2, '0');

    final String period =
        time.period == DayPeriod.am
            ? 'AM'
            : 'PM';

    return '$hour:$minute $period';
  }

   Widget descriptionSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Business Description (Optional)',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF222222),
        ),
      ),

      const SizedBox(height: 6),

      const Text(
        'Tell customers about your business or services',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey,
        ),
      ),

      const SizedBox(height: 10),

      TextFormField(
        controller: descriptionController,
        maxLines: 5,
        maxLength: 500,

        // Allows users to type naturally in their language.
        textCapitalization: TextCapitalization.sentences,

        // IMPORTANT:
        // Do NOT use FilteringTextInputFormatter here.
        // This allows Malayalam, Hindi, Tamil, Arabic, emojis, etc.
        decoration: InputDecoration(
          hintText:
              'Example: Vegetarian food, chicken dishes, family dining...',

          filled: true,
          fillColor: const Color(0xFFF9F9F9),

          alignLabelWithHint: true,

          contentPadding: const EdgeInsets.all(14),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: green,
              width: 1.2,
            ),
          ),
        ),
      ),
    ],
  );
}

// ============================================================
// SAVE COURIER LOCALLY
// ============================================================

Future<void> saveCourierLocally({
  required String uid,
  required String username,
  required String primaryMobile,
  required String secondaryMobile,
  required List<String> vehicleCategoryIds,
  String? openingTime,
  String? closingTime,
  String? description,
  String? profilePhotoUrl,
}) async {
  final settings =
      Hive.box('settings');

  // ----------------------------------------------------------
  // REGISTRATION
  // ----------------------------------------------------------

  await settings.put(
    'courierRegistered',
    true,
  );

  await settings.put(
    'courierSyncPending',
    true,
  );

  // ----------------------------------------------------------
  // BASIC DETAILS
  // ----------------------------------------------------------

  await settings.put(
    'courierUid',
    uid,
  );

  await settings.put(
    'courierUsername',
    username,
  );

  await settings.put(
    'courierPrimaryMobile',
    primaryMobile,
  );

  await settings.put(
    'courierSecondaryMobile',
    secondaryMobile,
  );

await settings.put(
  'courierState',
  selectedState,
);

await settings.put(
  'courierDistrict',
  selectedDistrict,
);

await settings.put(
  'courierNearestTown',
  nearestCityController.text.trim(),
);

  // ----------------------------------------------------------
  // VEHICLE CATEGORIES
  // ----------------------------------------------------------

  await settings.put(
    'courierVehicleCategoryIds',
    List<String>.from(
      vehicleCategoryIds,
    ),
  );

  // ----------------------------------------------------------
  // OPTIONAL SHOP TIMING
  // ----------------------------------------------------------

  await settings.put(
    'courierOpeningTime',
    openingTime,
  );

  await settings.put(
    'courierClosingTime',
    closingTime,
  );

  // ----------------------------------------------------------
  // OPTIONAL DESCRIPTION
  // ----------------------------------------------------------

  await settings.put(
    'courierDescription',
    description,
  );

  // ----------------------------------------------------------
  // OPTIONAL PROFILE PHOTO
  // ----------------------------------------------------------

  if (profilePhotoUrl != null &&
      profilePhotoUrl.trim().isNotEmpty) {
    await settings.put(
      'courierProfilePhotoUrl',
      profilePhotoUrl.trim(),
    );
  }

  // ----------------------------------------------------------
  // ROLE
  // ----------------------------------------------------------

  await settings.put(
    'courierRole',
    'courier',
  );
}
// ============================================================
// SAVE COURIER TO FIRESTORE
// ============================================================

Future<void> saveCourierToFirestore({
  required String uid,
  required String username,
  required String primaryMobile,
  required String secondaryMobile,
  required List<String> vehicleCategoryIds,
  String? openingTime,
  String? closingTime,
  String? description,
  String? profilePhotoUrl,
  Map<String, dynamic>? existingData,
}) async {
  final DocumentReference<Map<String, dynamic>>
      courierRef = _firestore
          .collection('couriers')
          .doc(uid);

  final Map<String, dynamic> courierData =
      <String, dynamic>{
    'uid': uid,

    'username': username,

    'primaryMobile': primaryMobile,

    'secondaryMobile': secondaryMobile,

    'vehicleCategoryIds':
        vehicleCategoryIds,

    // ----------------------------------------------------------
    // OPTIONAL SHOP TIMING
    // ----------------------------------------------------------

    'openingTime': openingTime,
    'closingTime': closingTime,
    'isOpen24Hours': isOpen24Hours,

    // ----------------------------------------------------------
    // OPTIONAL DESCRIPTION
    // ----------------------------------------------------------

    'description': description,

    // ----------------------------------------------------------
    // LIVE LOCATION
    // ----------------------------------------------------------

    'isLive':
        existingData?['isLive'] ??
            false,
    'isActive': true,
'isRegistered': true,

    'latitude':
        existingData?['latitude'],

    'longitude':
        existingData?['longitude'],

    // ----------------------------------------------------------
    // PROFILE
    // ----------------------------------------------------------

    'role': 'courier',

    'serviceType': 'courier',

    // ----------------------------------------------------------
    // SEARCH
    // ----------------------------------------------------------

    'searchKeywords':
        _buildCourierSearchKeywords(
      username: username,
      vehicleCategoryIds:
          vehicleCategoryIds,
    ),

    'updatedAt':
        FieldValue.serverTimestamp(),

    'createdAt':
        existingData?['createdAt'] ??
            FieldValue.serverTimestamp(),
  };

  // ------------------------------------------------------------
  // OPTIONAL PROFILE PHOTO
  // ------------------------------------------------------------

  if (profilePhotoUrl != null &&
      profilePhotoUrl.trim().isNotEmpty) {
    courierData['profilePhotoUrl'] =
        profilePhotoUrl.trim();
  }

  // ------------------------------------------------------------
  // SAVE
  // ------------------------------------------------------------

  await courierRef
      .set(
    courierData,
    SetOptions(
      merge: true,
    ),
  )
      .timeout(
    const Duration(seconds: 20),
  );
}


Future<void> _saveCourierFirestoreInBackground({
  required String uid,
  required String username,
  required String primaryMobile,
  required String secondaryMobile,
  required List<String> vehicleCategoryIds,
  required String description,
}) async {
  try {
    // ========================================================
    // GET EXISTING DATA
    // ========================================================

    final courierRef =
        _firestore
            .collection('couriers')
            .doc(uid);

    final existingCourier =
        await courierRef.get();

    final existingData =
        existingCourier.data();

    // ========================================================
    // PROFILE PHOTO
    // ========================================================

    String? profilePhotoUrl;

    if (profilePhoto != null) {
      profilePhotoUrl =
          await uploadProfilePhoto(uid);
    } else {
      final oldPhoto =
          existingData?['profilePhotoUrl']
              ?.toString();

      if (oldPhoto != null &&
          oldPhoto.trim().isNotEmpty) {
        profilePhotoUrl =
            oldPhoto.trim();
      }
    }

    // ========================================================
    // CALL YOUR EXISTING FIRESTORE FUNCTION
    // ========================================================

    await saveCourierToFirestore(
      uid: uid,
      username: username,
      primaryMobile: primaryMobile,
      secondaryMobile: secondaryMobile,
      vehicleCategoryIds:
          vehicleCategoryIds,
      openingTime:
          openingTime == null
              ? null
              : timeToString(openingTime!),
      closingTime:
          closingTime == null
              ? null
              : timeToString(closingTime!),
      description:
          description.isEmpty
              ? null
              : description,
      profilePhotoUrl:
          profilePhotoUrl,
      existingData:
          existingData,
    );

    // ========================================================
    // FIRESTORE SYNC COMPLETED
    // ========================================================

    await Hive.box('settings').put(
      'courierSyncPending',
      false,
    );

    debugPrint(
      'Courier Firestore sync completed.',
    );
  } catch (e) {
    // Keep pending = true so it can be synced later.
    debugPrint(
      'Courier Firestore background sync failed: $e',
    );

    await Hive.box('settings').put(
      'courierSyncPending',
      true,
    );
  }
}

Future<void> _submitCourier() async {
if (_submitLocked || isSubmitting) {
return;
}

_submitLocked = true;

if (!mounted) {
_submitLocked = false;
return;
}

setState(() {
isSubmitting = true;

// ----------------------------------------------------------
// CLEAR PREVIOUS ERRORS
// ----------------------------------------------------------
stateError = '';
mobileError = false;
secondaryMobileError = false;
vehicleCategoryError = false;
privacyPolicyError = null;

});

try {
bool hasError = false;

// ==========================================================
// USERNAME - MANDATORY
// ==========================================================

final String name =
    usernameController.text.trim();

 nameError = name.isEmpty || name.length < 2;
  if (nameError) {
    hasError = true;
  }

// ==========================================================
// PRIMARY MOBILE - MANDATORY
// ==========================================================

final String primaryMobile =
    _normalizedMobile(
  mobileController.text,
);

if (!RegExp(
  r'^[6-9][0-9]{9}$',
).hasMatch(primaryMobile)) {
  hasError = true;

  if (mounted) {
    setState(() {
      mobileError = true;
    });
  }
}

// ==========================================================
// SECONDARY MOBILE - MANDATORY
// ==========================================================

final String secondaryMobile =
    _normalizedMobile(
  secondaryMobileController.text,
);

if (!RegExp(
  r'^[6-9][0-9]{9}$',
).hasMatch(secondaryMobile)) {
  hasError = true;

  if (mounted) {
    setState(() {
      secondaryMobileError = true;
    });
  }
}

 final stateValue = selectedState?.trim() ?? '';
final districtValue = selectedDistrict?.trim() ?? '';
final nearestCityValue =
    nearestCityController.text.trim();

setState(() {
  stateError = stateValue.isEmpty
      ? 'Please select a state.'
      : '';

  districtError = districtValue.isEmpty
      ? 'Please select a district.'
      : '';

  nearestCityError = nearestCityValue.isEmpty
      ? 'Please enter the nearest town or city.'
      : '';
});

if (stateError.isNotEmpty ||
    districtError.isNotEmpty ||
    nearestCityError.isNotEmpty) {
  hasError = true;
}

// ==========================================================
// VEHICLE TYPE - MANDATORY
// ==========================================================

if (selectedVehicleCategoryIds.isEmpty) {
  hasError = true;

  if (mounted) {
    setState(() {
      vehicleCategoryError = true;
    });
  }
}

// ==========================================================
// PRIVACY POLICY / TERMS - MANDATORY
// ==========================================================

if (!privacyPolicyAccepted) {
  hasError = true;

  if (mounted) {
    setState(() {
      privacyPolicyError =
          'Please accept the Privacy Policy and Terms & Conditions.';
    });
  }
}

// ==========================================================
// STOP HERE IF ANY FORM ERROR EXISTS
// ==========================================================

if (hasError) {
  _finishSubmitState();
  return;
}

// ==========================================================
// OTP VERIFICATION
// ==========================================================

if (!otpVerified) {
  showMessage(
    'Please verify your mobile number first.',
    isError: true,
  );

  _finishSubmitState();
  return;
}

// ==========================================================
// CURRENT FIREBASE USER
// ==========================================================

final User? currentUser =
    _auth.currentUser;

if (currentUser == null) {
  showMessage(
    'Mobile verification session expired. Please verify OTP again.',
    isError: true,
  );

  if (mounted) {
    setState(() {
      otpVerified = false;
    });
  }

  _finishSubmitState();
  return;
}

// ==========================================================
// CHECK VERIFIED MOBILE
// ==========================================================

final String authPhone =
    currentUser.phoneNumber ?? '';

if (authPhone.isNotEmpty) {
  final String expectedPhone =
      '+91$primaryMobile';

  if (authPhone != expectedPhone) {
    showMessage(
      'Verified mobile number does not match the entered number.',
      isError: true,
    );

    if (mounted) {
      setState(() {
        otpVerified = false;
      });
    }

    _finishSubmitState();
    return;
  }
}

// ==========================================================
// USER ID
// ==========================================================

final String uid =
    currentUser.uid;

final List<String> vehicleCategoryIds =
    selectedVehicleCategoryIds.toList();

final String description =
    descriptionController.text.trim();
final String username = usernameController.text.trim();

// ==========================================================
// SAVE TO HIVE FIRST
// ==========================================================

await saveCourierLocally(
  uid: uid,
  username: username,
  primaryMobile: primaryMobile,
  secondaryMobile: secondaryMobile,
  vehicleCategoryIds: vehicleCategoryIds,
  openingTime: openingTime == null
      ? null
      : timeToString(openingTime!),
  closingTime: closingTime == null
      ? null
      : timeToString(closingTime!),
  description: description.isEmpty
      ? null
      : description,
  profilePhotoUrl: null,
);

// ==========================================================
// SAVE COMMON LOGIN PROFILE
// ==========================================================

await CommonProfileService.saveLogin(
  uid: uid,
  name: username,
  mobile: primaryMobile,
  role: 'courier',
);

// ==========================================================
// FIRESTORE BACKGROUND SAVE
// ==========================================================

_saveCourierFirestoreInBackground(
  uid: uid,
  username: username,
  primaryMobile: primaryMobile,
  secondaryMobile: secondaryMobile,
  vehicleCategoryIds: vehicleCategoryIds,
  description: description,
);

// ==========================================================
// WAIT
// ==========================================================

await Future<void>.delayed(
  const Duration(seconds: 2),
);

if (!mounted) {
  _submitLocked = false;
  return;
}

// ==========================================================
// FINISH SUBMIT
// ==========================================================

_submitLocked = false;

setState(() {
  isSubmitting = false;
});

// ==========================================================
// GO TO HOME
// ==========================================================

Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(
    builder: (_) => const ScreenHome(),
  ),
  (route) => false,
);

} catch (e) {
debugPrint(
'Courier submit error: $e',
);

if (mounted) {
  showMessage(
    'Unable to save courier profile. Please try again.',
    isError: true,
  );
}

_finishSubmitState();

}
}

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white,

      // ==========================================================
      // STUDENT-STYLE APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        elevation: 0,

        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
            color: Colors.black,
          ),

          onPressed: () {
            Navigator.pop(
              context,
            );
          },
        ),

        titleSpacing: 0,

        title: RichText(
          text:
            TextSpan(
            style:
                TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.w800,
            ),

            children: [

              TextSpan(
                text: 'Courier ',
                style:
                    TextStyle(
                  color:
                      Color(0xFF08744F),
                ),
              ),

              TextSpan(
                text: AppLocalizations.of(context)!.registration,
                   // 'Registration',
                style:
                    TextStyle(
                 color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),

     body: SafeArea(
        child: Form(
          key: _formKey,

          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              28,
              10,
              28,
              35,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                // ==================================================
                // SUBTITLE
                // ==================================================

                const Text(
                  'Fill in your details to create your garage or workshop profile',

                  style:
                      TextStyle(
                    color:
                        Color(0xFF777777),
                    fontSize: 17,
                    height: 1.5,
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                // =================================================
                // USERNAME
                // =================================================
                TextField(
  controller: usernameController,
  textCapitalization: TextCapitalization.words,
  textInputAction: TextInputAction.next,
  onChanged: (_) {
    if (nameError) {
      setState(() {
        nameError = false;
      });
    }
  },
  decoration: fieldDecoration(
    hintText: 'Enter your name',
    icon: Icons.person_outline,
    hasError: nameError,
  ),
),
if (nameError)
  const Padding(
    padding: EdgeInsets.only(left: 12, top: 5),
    child: Text(
      'Please enter your name.',
      style: TextStyle(
        color: Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),

               // _usernameSection(),

                const SizedBox(height: 17),
 sectionTitle('Mobile Number'),
              const SizedBox(height: 6),

                // =================================================
                // PRIMARY MOBILE + OTP
                // =================================================
 mobileSection(),

                // ==================================================
                // MOBILE VALIDATION MESSAGE
                // ==================================================

                if (!otpVerified &&
                    mobileController
                        .text
                        .isNotEmpty &&
                    mobileController
                            .text
                            .length !=
                        10)
                   Padding(
                    padding:
                        EdgeInsets.only(
                      top: 6,
                      left: 5,
                    ),

                    child: Text(
                    //  'Enter a valid 10-digit number',
AppLocalizations.of(context)!.enteradigitmobilenumber,
                      style:
                          TextStyle(
                        color:
                            Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),

                // ==================================================
                // OTP
                // ==================================================

                otpSection(),

                const SizedBox(height: 17),

                // =================================================
                // SECONDARY MOBILE
                // =================================================

               secondaryMobileSection(),
if (secondaryMobileError)
  const Padding(
    padding: EdgeInsets.only(
      left: 12,
      top: 5,
    ),
    child: Text(
      'Please enter a valid secondary mobile number.',
      style: TextStyle(
        color: Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
                const SizedBox(height: 20),

                 stateSection(),

const SizedBox(height: 20),

districtSection(),
const SizedBox(height: 20),
sectionTitle('Nearest Town'),
              const SizedBox(height: 8),

TextField(
  controller: nearestCityController,
  textCapitalization: TextCapitalization.words,
  decoration: fieldDecoration(
    hintText: 'Enter nearest Town',
    icon: Icons.location_city_outlined,
    hasError: nearestCityError.isNotEmpty,
  ),
),

if (nearestCityError.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(
      top: 6,
      left: 12,
    ),
    child: Text(
      nearestCityError,
      style: const TextStyle(
        color: Colors.red,
        fontSize: 12,
      ),
    ),
  ),
  const SizedBox(height: 20),

                // =================================================
                // VEHICLE CATEGORY
                // =================================================

                _vehicleCategorySection(),
                const SizedBox(height: 17),

               shopTimingSection(),
                const SizedBox(height: 20),
               descriptionSection(),
                const SizedBox(height: 20),

                 _profilePhotoSection(),

                const SizedBox(height: 35),
                 sectionTitle('Terms & Conditions'),

              const SizedBox(height: 5),

            PrivacyTermsSection(
              value: privacyPolicyAccepted,
               errorText: privacyPolicyError,
                onChanged: (value) {
                  setState(() {
                     privacyPolicyAccepted =
                        value ?? false;

                    privacyPolicyError = null;
                   });
                 },
               ),

              const SizedBox(height: 8),

                // =================================================
                // SUBMIT
                // =================================================

                _submitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ============================================================
// SEARCH KEYWORDS
// ============================================================

List<String>
    _buildCourierSearchKeywords({
  required String username,
  required List<String>
      vehicleCategoryIds,
}) {
  final Set<String> keywords =
      <String>{};

  void addWords(String value) {
    final normalized =
        value.trim().toLowerCase();

    if (normalized.isEmpty) {
      return;
    }

    keywords.add(normalized);

    final words =
        normalized.split(
      RegExp(r'\s+'),
    );

    for (final word in words) {
      if (word.isNotEmpty) {
        keywords.add(word);
      }
    }
  }

  addWords(username);

  for (final categoryId
      in vehicleCategoryIds) {
    addWords(categoryId);
  }

  return keywords.toList();
}

// ============================================================
// FINISH SUBMIT
// ============================================================

void _finishSubmitState() {
  _submitLocked = false;

  if (!mounted) {
    return;
  }

  setState(() {
    isSubmitting = false;
  });
}
}

// ============================================================
// ADD OWN VEHICLE CATEGORY
// ============================================================

// Future<void>
//     _showAddVehicleCategoryDialog() async {
//   final TextEditingController
//       categoryController =
//       TextEditingController();

//   bool isSaving = false;

//   await showDialog<void>(
//     context: context,

//     barrierDismissible:
//         !isSaving,

//     builder: (dialogContext) {
//       return StatefulBuilder(
//         builder: (
//           context,
//           setDialogState,
//         ) {
//          Future<void> saveCategory() async {
//   if (isSaving) return;

//   final name = categoryController.text.trim();

//   if (name.isEmpty) {
//     showMessage('Please enter a vehicle category.');
//     return;
//   }

//   if (name.length > 50) {
//     showMessage('Category name is too long.');
//     return;
//   }

//   final duplicate = allVehicleCategories.any(
//     (item) =>
//         item.name.trim().toLowerCase() ==
//         name.toLowerCase(),
//   );

//   if (duplicate) {
//     showMessage('This vehicle category already exists.');
//     return;
//   }

//   setDialogState(() {
//     isSaving = true;
//   });

//   try {
//     final categoryId = _makeCategoryId(name);

//     final categoryRef = _firestore
//         .collection('courierVehicleCategories')
//         .doc(categoryId);

//     await categoryRef.set({
//       'name': name,
//       'iconType': 'default',
//       'isCustom': true,
//       'createdBy': _auth.currentUser?.uid,
//       'createdAt': FieldValue.serverTimestamp(),
//     });

//     final newCategory = CourierVehicleCategory(
//       id: categoryId,
//       name: name,
//       iconType: 'default',
//       isCustom: true,
//     );

//     if (!mounted) return;

//     setState(() {
//       final exists = allVehicleCategories.any(
//         (item) => item.id == newCategory.id,
//       );

//       if (!exists) {
//         allVehicleCategories.add(newCategory);
//       }

//       selectedVehicleCategoryIds.add(
//         newCategory.id,
//       );

//       vehicleCategoryError = false;
//     });

//     _filterVehicleCategories();
// if(!mounted) return;
//     Navigator.of(this.context).pop();

//     showMessage(
//       'Vehicle category added successfully.',
//     );
//   } catch (e) {
//     debugPrint(
//       'ADD COURIER CATEGORY ERROR: $e',
//     );

//     if (mounted) {
//       showMessage(
//         'Unable to add vehicle category. Please try again later.',
//       );
//     }
//   } finally {
//     if (mounted) {
//       setDialogState(() {
//         isSaving = false;
//       });
//     }
//   }
// }
//           return AlertDialog(
//             title: const Text(
//               'Add Vehicle Category',
//               style: TextStyle(
//                 fontWeight:
//                     FontWeight.w700,
//               ),
//             ),

//             content: TextField(
//               controller:
//                   categoryController,

//               autofocus: true,

//               enabled: !isSaving,

//               textCapitalization:
//                   TextCapitalization.words,

//               maxLength: 50,

//               decoration:
//                   const InputDecoration(
//                 hintText:
//                     'Example: Electric Cargo Bike',
//                 prefixIcon: Icon(
//                   Icons.local_shipping_outlined,
//                 ),
//               ),
//             ),

//             actions: [

//               TextButton(
//                 onPressed: isSaving
//                     ? null
//                     : () {
//                         Navigator.of(
//                           dialogContext,
//                         ).pop();
//                       },

//                 child:
//                     const Text('Cancel'),
//               ),

//               ElevatedButton(
//                 onPressed:
//                     isSaving
//                         ? null
//                         : saveCategory,

//                 style:
//                     ElevatedButton.styleFrom(
//                   backgroundColor:
//                       const Color(
//                     0xFFE53935,
//                   ),
//                   foregroundColor:
//                       Colors.white,
//                 ),

//                 child: isSaving
//                     ? const SizedBox(
//                         width: 18,
//                         height: 18,
//                         child:
//                             CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color:
//                               Colors.white,
//                         ),
//                       )
//                     : const Text(
//                         'Add',
//                       ),
//               ),
//             ],
//           );
//         },
//       );
//     },
//   );

//   categoryController.dispose();
// }
 // ============================================================
  // USERNAME SECTION
  // ============================================================

//  Widget _usernameSection() {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       sectionTitle(
//         'Username',
//         required: true,
//       ),

//       const SizedBox(height: 8),

//       TextField(
//         controller: usernameController,
//         textCapitalization: TextCapitalization.words,
//         decoration: InputDecoration(
//           hintText: 'Enter your name',
//           icon: Icon(Icons.person_outline),
//           errorText: usernameError,
//         ),
//         onChanged: (value) {
//           if (usernameError != null) {
//             setState(() {
//               usernameError = null;
//             });
//           }
//         },
//       ),
//     ],
//   );
// }


  // Widget sectionTitle(
  //   String title, {
  //   bool required = false,
  // }) {
  //   return RichText(
  //     text: TextSpan(
  //       children: [
  //         TextSpan(
  //           text: title,
  //           style: const TextStyle(
  //             color: Color(0xFF222222),
  //             fontSize: 15,
  //             fontWeight: FontWeight.w700,
  //           ),
  //         ),

  //         if (required)
  //           const TextSpan(
  //             text: ' *',
  //             style: TextStyle(
  //               color: Colors.red,
  //               fontWeight:
  //                   FontWeight.w700,
  //             ),
  //           ),
  //       ],
  //     ),
  //   );
  // }


// ============================================================
// PROFILE PHOTO UPLOAD
// ============================================================

// Future<String?> _uploadCourierProfilePhoto({
//   required String uid,
// }) async {
//   final file =
//       selectedProfileImage;

//   if (file == null) {
//     return null;
//   }

//   try {
//     /*
//      * One fixed location per courier.
//      *
//      * This avoids creating unlimited image files
//      * every time the user edits the profile.
//      */

//     final storageRef =
//         FirebaseStorage.instance
//             .ref()
//             .child(
//               'courier_profiles',
//             )
//             .child(
//               '$uid.jpg',
//             );

//     final metadata =
//         SettableMetadata(
//       contentType: 'image/jpeg',
//       cacheControl:
//           'public,max-age=86400',
//     );

//     final uploadTask =
//         storageRef.putFile(
//       file,
//       metadata,
//     );

//     final snapshot =
//         await uploadTask.timeout(
//       const Duration(seconds: 30),
//     );

//     final url =
//         await snapshot.ref
//             .getDownloadURL()
//             .timeout(
//       const Duration(seconds: 15),
//     );

//     return url;
//   } on TimeoutException {
//     throw TimeoutException(
//       'Profile photo upload timed out.',
//     );
//   } catch (e) {
//     debugPrint(
//       'Courier photo upload error: $e',
//     );

//     rethrow;
//   }
// }


// ==========================================================  
// PROFILE PHOTO  
// ==========================================================  

// String? profilePhotoUrl;  

// /*  
//  * If a new image was selected,  
//  * upload the new image.  
//  */  

// if (selectedProfileImage != null) {  
//   profilePhotoUrl =  
//       await _uploadCourierProfilePhoto(  
//     uid: uid,  
//   );  
// } else {  
//   /*  
//    * No new image selected.  
//    *  
//    * Preserve the old profile photo.  
//    */  

//   final oldPhoto =  
//       existingData?[  
//               'profilePhotoUrl']  
//           ?.toString();  

//   if (oldPhoto != null &&  
//       oldPhoto.trim().isNotEmpty) {  
//     profilePhotoUrl =  
//         oldPhoto.trim();  
//   }  
// }  


// ============================================================
// SUBMIT COURIER
// ============================================================

// SUBMIT COURIER
// ============================================================

// Future<void> _submitCourier() async {
// /*

// VERY IMPORTANT:

// Prevent two fast taps from creating

// duplicate courier submissions.
// */


// if (_submitLocked || isSubmitting) {
// return;
// }

// _submitLocked = true;

// if (!mounted) {
// _submitLocked = false;
// return;
// }

// setState(() {
// isSubmitting = true;
// });

// try {
// // ==========================================================
// // FORM VALIDATION
// // ==========================================================

// final valid =  
//     _formKey.currentState?.validate() ?? false;  

// if (!valid) {  
//   _finishSubmitState();  
//   return;  
// }  
// final description =
//     descriptionController.text.trim();
// // ==========================================================  
// // OTP VALIDATION  
// // ==========================================================  

// if (!otpVerified) {  
//   showMessage(  
//     'Please verify your mobile number first.',  
//   );  

//   _finishSubmitState();  
//   return;  
// }

// // ============================================================
// // TERMS & CONDITION / PRIVACY POLICY
// // ============================================================
// if (!privacyPolicyAccepted) {
// setState(() {
// privacyPolicyError =
// 'Please accept the Privacy Policy and Terms & Conditions.';
// });

// showMessage(
// 'Please accept the Privacy Policy and Terms & Conditions.',
// );
// _finishSubmitState();
// return;
// }

// // ==========================================================  
// // VEHICLE CATEGORY VALIDATION  
// // ==========================================================  

// if (selectedVehicleCategoryIds.isEmpty) {  
//   if (mounted) {  
//     setState(() {  
//       vehicleCategoryError = true;  
//       isVehicleCategoryDropdownOpen = true;  
//     });  
//   }  

//   showMessage(  
//     'Please select at least one vehicle category.',  
//   );  

//   _finishSubmitState();  
//   return;  
// }  

// // ==========================================================  
// // USER DATA  
// // ==========================================================  

// final username =  
//     usernameController.text.trim();  

// final primaryMobile =  
//     _normalizedMobile(  
//   mobileController.text,  
// );  

// final secondaryMobile =  
//     _normalizedMobile(  
//   secondaryMobileController.text,  
// );  

// // ==========================================================  
// // PRIMARY MOBILE VALIDATION  
// // ==========================================================  

// if (!RegExp(  
//   r'^[6-9][0-9]{9}$',  
// ).hasMatch(primaryMobile)) {  
//   showMessage(  
//     'Please enter a valid primary mobile number.',  
//   );  

//   _finishSubmitState();  
//   return;  
// }  

// // ==========================================================  
// // SECONDARY MOBILE VALIDATION  
// //  
// // Secondary mobile is OPTIONAL.  
// // Validate it only when the user entered something.  
// // ==========================================================  

// if (secondaryMobile.isNotEmpty &&  
//     !RegExp(  
//       r'^[6-9][0-9]{9}$',  
//     ).hasMatch(secondaryMobile)) {  
//   showMessage(  
//     'Please enter a valid secondary mobile number.',  
//   );  

//   _finishSubmitState();  
//   return;  
// }  

// // ==========================================================  
// // OTP USER CHECK  
// // ==========================================================  

// final currentUser =  
//     _auth.currentUser;  

// if (currentUser == null) {  
//   showMessage(  
//     'Mobile verification session expired. Please verify OTP again.',  
//   );  

//   if (mounted) {  
//     setState(() {  
//       otpVerified = false;  
//     });  
//   }  

//   _finishSubmitState();  
//   return;  
// }  

// // ==========================================================  
// // VERIFY AUTH PHONE  
// // ==========================================================  

// final authPhone =  
//     currentUser.phoneNumber ?? '';  

// if (authPhone.isNotEmpty) {  
//   final expectedPhone =  
//       '+91$primaryMobile';  

//   if (authPhone != expectedPhone) {  
//     showMessage(  
//       'Verified mobile number does not match the entered number.',  
//     );  

//     if (mounted) {  
//       setState(() {  
//         otpVerified = false;  
//       });  
//     }  

//     _finishSubmitState();  
//     return;  
//   }  
// }  

// // ==========================================================  
// // UID  
// // ==========================================================  

// final uid =  
//     currentUser.uid;  

// // ==========================================================  
// // CHECK EXISTING COURIER DOCUMENT  
// // ==========================================================  

// final courierRef =  
//     _firestore  
//         .collection('couriers')  
//         .doc(uid);  

// final existingCourier =  
//     await courierRef.get();  

// final existingData =  
//     existingCourier.data();  

// String? profilePhotoUrl;

// /*
//  * If a new image was selected,
//  * upload the new image.
//  */
// if (profilePhoto != null) {
//   profilePhotoUrl = await uploadProfilePhoto(uid);
// } else {
//   /*
//    * No new image selected.
//    * Preserve the old profile photo.
//    */
//   final oldPhoto =
//       existingData?['profilePhotoUrl']?.toString();

//   if (oldPhoto != null &&
//       oldPhoto.trim().isNotEmpty) {
//     profilePhotoUrl = oldPhoto.trim();
//   }
// }

// // ==========================================================  
// // CATEGORY IDS  
// // ==========================================================  

// final vehicleCategoryIds =  
//     selectedVehicleCategoryIds.toList();  

// // ==========================================================  
// // FIRESTORE DATA  
// // ==========================================================  

// final Map<String, dynamic> courierData = {
//   'uid': uid,

//   'username': username,

//   'primaryMobile':
//       primaryMobile,

//   'secondaryMobile':
//       secondaryMobile,

//   'vehicleCategoryIds':
//       vehicleCategoryIds,

//   // ========================================================
//   // VEHICLE NUMBER
//   // ========================================================

//   // 'vehicleNumber':
//   //     vehicleNumber,

//   // ========================================================
//   // SHOP / BUSINESS TIMING
//   // OPTIONAL
//   // ========================================================

//   'openingTime':
//       openingTime == null
//           ? null
//           : timeToString(openingTime!),

//   'closingTime':
//       closingTime == null
//           ? null
//           : timeToString(closingTime!),

//   'isOpen24Hours':
//       isOpen24Hours,

//   // ========================================================
//   // DESCRIPTION
//   // OPTIONAL
//   // ========================================================

//   'description':
//       description.isEmpty
//           ? null
//           : description,

//   // ========================================================
//   // LIVE LOCATION
//   // ========================================================

//   'isLive':
//       existingData?['isLive'] ??
//           false,

//   'latitude':
//       existingData?['latitude'],

//   'longitude':
//       existingData?['longitude'],

//   // ========================================================
//   // ROLE
//   // ========================================================

//   'role':
//       'courier',

//   'serviceType':
//       'courier',

//   // ========================================================
//   // SEARCH
//   // ========================================================

//   'searchKeywords':
//       _buildCourierSearchKeywords(
//     username: username,
//     vehicleCategoryIds:
//         vehicleCategoryIds,
//   ),

//   // ========================================================
//   // TIMESTAMPS
//   // ========================================================

//   'updatedAt':
//       FieldValue.serverTimestamp(),

//   'createdAt':
//       existingData?['createdAt'] ??
//           FieldValue.serverTimestamp(),
// };

// // ==========================================================  
// // PROFILE PHOTO  
// // ==========================================================  

// if (profilePhotoUrl != null &&  
//     profilePhotoUrl.trim().isNotEmpty) {  
//   courierData[  
//           'profilePhotoUrl'] =  
//       profilePhotoUrl;  
// }  

// // ==========================================================  
// // SAVE TO FIRESTORE  
// // ==========================================================  

// /*  
//  * merge:true  
//  *  
//  * Prevents us from accidentally removing  
//  * live-location or future courier fields.  
//  */  

// await courierRef  
//     .set(  
//       courierData,  
//       SetOptions(  
//         merge: true,  
//       ),  
//     )  
//     .timeout(  
//   const Duration(  
//     seconds: 20,  
//   ),  
// );  

// // ==========================================================  
// // SUCCESS  
// // ==========================================================  

// if (!mounted) {  
//   return;  
// }  

// showMessage(  
//   'Courier profile saved successfully.',  
// );  

// // ==========================================================  
// // SMALL DELAY  
// // ==========================================================  

// await Future<void>.delayed(  
//   const Duration(  
//     milliseconds: 300,  
//   ),  
// );  

// if (!mounted) {  
//   return;  
// }  

// // ==========================================================  
// // GO TO COURIER CATEGORIES  
// // ==========================================================  

// Navigator.pushAndRemoveUntil(  
//   context,  
//   MaterialPageRoute(  
//     builder: (_) =>  
//         const ScreenCourierCategories(),  
//   ),  
//   (route) => false,  
// );

// } on FirebaseException catch (e) {
// debugPrint(
// 'Courier Firestore error: '
// '${e.code} ${e.message}',
// );

// if (!mounted) {  
//   return;  
// }  

// String message =  
//     'Unable to save courier profile.';  

// if (e.code ==  
//     'permission-denied') {  
//   message =  
//       'You do not have permission to save this profile.';  
// } else if (e.code ==  
//     'unavailable') {  
//   message =  
//       'Network is unavailable. Please try again.';  
// } else if (e.code ==  
//     'deadline-exceeded') {  
//   message =  
//       'Saving took too long. Please try again.';  
// } else if (e.message != null &&  
//     e.message!.trim().isNotEmpty) {  
//   message =  
//       e.message!;  
// }  

// showMessage(message);

// } on TimeoutException {
// if (!mounted) {
// return;
// }

// showMessage(  
//   'Saving took too long. Please check your internet connection and try again.',  
// );

// } catch (e) {
// debugPrint(
// 'Courier submit error: $e',
// );

// if (!mounted) {  
//   return;  
// }  

// showMessage(  
//   'Unable to save courier profile. Please try again.',  
// );

// } finally {
// _finishSubmitState();
// }
// }


// Future<void> _submitCourier() async {
//   // ==========================================================
//   // PREVENT DOUBLE SUBMISSION
//   // ==========================================================

//   if (_submitLocked || isSubmitting) {
//     return;
//   }

//   _submitLocked = true;

//   if (!mounted) {
//     _submitLocked = false;
//     return;
//   }

//   setState(() {
//     isSubmitting = true;
//   });

//   try {
//     // ========================================================
//     // FORM VALIDATION
//     // ========================================================

//     final bool valid =
//         _formKey.currentState?.validate() ?? false;

//     if (!valid) {
//       _finishSubmitState();
//       return;
//     }

//     // ========================================================
//     // DESCRIPTION
//     // ========================================================

//     final String description =
//         descriptionController.text.trim();

//     // ========================================================
//     // OTP VALIDATION
//     // ========================================================

//     if (!otpVerified) {
//       showMessage(
//         'Please verify your mobile number first.',
//         isError: true,
//       );

//       _finishSubmitState();
//       return;
//     }

//     // ========================================================
//     // PRIVACY / TERMS
//     // ========================================================

//     if (!privacyPolicyAccepted) {
//       if (mounted) {
//         setState(() {
//           privacyPolicyError =
//               'Please accept the Privacy Policy and Terms & Conditions.';
//         });
//       }

//       _finishSubmitState();
//       return;
//     }

//     // ========================================================
//     // VEHICLE CATEGORY
//     // ========================================================

//     if (selectedVehicleCategoryIds.isEmpty) {
//       if (mounted) {
//         setState(() {
//           vehicleCategoryError = true;
//           isVehicleCategoryDropdownOpen = true;
//         });
//       }

//       _finishSubmitState();
//       return;
//     }

//     // ========================================================
//     // USER DATA
//     // ========================================================

//     final String username =
//         usernameController.text.trim();

//     final String primaryMobile =
//         _normalizedMobile(
//       mobileController.text,
//     );

//     final String secondaryMobile =
//         _normalizedMobile(
//       secondaryMobileController.text,
//     );

//     // ========================================================
//     // PRIMARY MOBILE VALIDATION
//     // ========================================================

//     if (!RegExp(
//       r'^[6-9][0-9]{9}$',
//     ).hasMatch(primaryMobile)) {
//       if (mounted) {
//         setState(() {
//           mobileError = true;
//         });
//       }

//       _finishSubmitState();
//       return;
//     }

//     // ========================================================
//     // SECONDARY MOBILE VALIDATION
//     // MANDATORY
//     // ========================================================

//     if (!RegExp(
//       r'^[6-9][0-9]{9}$',
//     ).hasMatch(secondaryMobile)) {
//       if (mounted) {
//         setState(() {
//           secondaryMobileError = true;
//         });
//       }

//       _finishSubmitState();
//       return;
//     }

//     // ========================================================
//     // FIREBASE USER
//     // ========================================================

//     final User? currentUser =
//         _auth.currentUser;

//     if (currentUser == null) {
//       showMessage(
//         'Mobile verification session expired. Please verify OTP again.',
//         isError: true,
//       );

//       if (mounted) {
//         setState(() {
//           otpVerified = false;
//         });
//       }

//       _finishSubmitState();
//       return;
//     }

//     // ========================================================
//     // VERIFY AUTH PHONE
//     // ========================================================

//     final String authPhone =
//         currentUser.phoneNumber ?? '';

//     if (authPhone.isNotEmpty) {
//       final String expectedPhone =
//           '+91$primaryMobile';

//       if (authPhone != expectedPhone) {
//         showMessage(
//           'Verified mobile number does not match the entered number.',
//           isError: true,
//         );

//         if (mounted) {
//           setState(() {
//             otpVerified = false;
//           });
//         }

//         _finishSubmitState();
//         return;
//       }
//     }

//     // ========================================================
//     // UID
//     // ========================================================

//     final String uid =
//         currentUser.uid;

//     // ========================================================
//     // VEHICLE CATEGORIES
//     // ========================================================

//     final List<String> vehicleCategoryIds =
//         selectedVehicleCategoryIds.toList();

//     // ========================================================
//     // SAVE TO HIVE FIRST
//     // ========================================================

//     await saveCourierLocally(
//       uid: uid,
//       username: username,
//       primaryMobile: primaryMobile,
//       secondaryMobile: secondaryMobile,
//       vehicleCategoryIds:
//           vehicleCategoryIds,
//       openingTime:
//           openingTime == null
//               ? null
//               : timeToString(openingTime!),
//       closingTime:
//           closingTime == null
//               ? null
//               : timeToString(closingTime!),
//       description:
//           description.isEmpty
//               ? null
//               : description,
//       profilePhotoUrl:
//           null,
//     );

//     // ========================================================
//     // SAVE COMMON LOGIN PROFILE
//     // ========================================================

//     await CommonProfileService.saveLogin(
//       uid: uid,
//       name: username,
//       mobile: primaryMobile,
//       role: 'courier',
//     );

//     // ========================================================
//     // FIRESTORE IN BACKGROUND
//     // ========================================================

//     _saveCourierFirestoreInBackground(
//       uid: uid,
//       username: username,
//       primaryMobile: primaryMobile,
//       secondaryMobile: secondaryMobile,
//       vehicleCategoryIds:
//           vehicleCategoryIds,
//       description: description,
//     );

//     // ========================================================
//     // WAIT 2 SECONDS
//     // ========================================================

//     await Future<void>.delayed(
//       const Duration(seconds: 2),
//     );

//     if (!mounted) {
//       return;
//     }

//     // ========================================================
//     // GO TO HOME
//     // ========================================================

//     setState(() {
//       isSubmitting = false;
//     });

//     _submitLocked = false;

//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const ScreenHome(),
//       ),
//       (route) => false,
//     );
//   } catch (e) {
//     debugPrint(
//       'Courier submit error: $e',
//     );

//     if (!mounted) {
//       return;
//     }

//     showMessage(
//       'Unable to save courier profile. Please try again.',
//       isError: true,
//     );

//     _finishSubmitState();
//   }
// }