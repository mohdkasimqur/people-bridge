import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:google_location_extract/google_location_extract.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jober_india/jober_indiaScreens.dart/Privacy&Terms/privacy_terms_section.dart';
import 'package:jober_india/jober_indiaScreens.dart/TaxiCommercial/screen_taxicomrcial_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_camera_capture.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_home.dart';
import 'package:jober_india/l10n/app_localizations.dart';
import 'package:jober_india/screens/location_localization.dart';


class FishDeliveryVehicleCategory {
  final String id;
  final String name;
  final String iconType;
  final bool isCustom;

  const FishDeliveryVehicleCategory({
    required this.id,
    required this.name,
    required this.iconType,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconType': iconType,
      'isCustom': isCustom,
    };
  }

  factory FishDeliveryVehicleCategory.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return FishDeliveryVehicleCategory(
      id: id,
      name: map['name']?.toString() ?? '',
      iconType: map['iconType']?.toString() ?? 'bike',
      isCustom: map['isCustom'] == true,
    );
  }
}


class FishDeliveryLocation {
  final String placeName;
  final double? latitude;
  final double? longitude;

  FishDeliveryLocation({
    required this.placeName,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'placeName': placeName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory FishDeliveryLocation.fromMap(
    Map<String, dynamic> map,
  ) {
    return FishDeliveryLocation(
      placeName: map['placeName']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

class ScreenFishDeliveryLogin
    extends StatefulWidget {
  const ScreenFishDeliveryLogin({
    super.key,
  });

  @override
  State<ScreenFishDeliveryLogin> createState() =>
      _ScreenFishDeliveryLoginState();
}

class _ScreenFishDeliveryLoginState
    extends State<ScreenFishDeliveryLogin> {
  final _formKey =
      GlobalKey<FormState>();

  // ==========================================================
  // CONTROLLERS
  // ==========================================================
  bool _isValidIndianMobile(String value) {
  return RegExp(r'^[0-9]{10}$').hasMatch(value);
}
static const Color green =
      Color(0xFF138808);

  static const Color darkText =
      Color(0xFF202124);

  static const Color lightFill =
      Color(0xFFF9F9F9);
  bool isCategoryDropdownOpen = false;

  final usernameController =
      TextEditingController();

  final mobileController =
      TextEditingController();

  final TextEditingController secondaryPhoneController =
    TextEditingController();

  final TextEditingController _shopLocationController =
    TextEditingController();

  final otpController =
      TextEditingController();

  final vehicleNumberController =
      TextEditingController();
      
   final TextEditingController vehicleSearchController =
      TextEditingController();

  Color selectedVehicleNumberColor = Colors.white;

  final List<String> customSpecializations = [];

List<String> filteredSpecializations = [];

bool isSpecializationDropdownOpen = false;

bool specializationError = false;

FishDeliveryLocation? currentLocation;

bool isGettingLocation = false;
bool isSearchingLocation = false;

// Used to invalidate an older location request
int _locationRequestId = 0;
bool locationError = false;

final TextEditingController specializationSearchController =
    TextEditingController();

final TextEditingController customSpecializationController =
    TextEditingController();
  // ==========================================================
  // FIREBASE
  // ==========================================================

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  File? selectedProfileImage;
 File? profilePhoto;
  String? profilePhotoUrl;
bool isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();
  // ==========================================================
  // STATE
  // ==========================================================

  bool privacyPolicyAccepted = false;

  String? privacyPolicyError;

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

  bool isLoadingCategories = false;

 String? vehicleNumberError;
 String? usernameError;
String? primaryMobileError;
String? secondaryMobileError;
  // ==========================================================
  // DEFAULT CATEGORIES
  // ==========================================================
bool categoryError = false;
bool isVehicleCategoryDropdownOpen = false;
bool vehicleCategoryError = false;

  List<FishDeliveryVehicleCategory>
      allVehicleCategories = [];

  List<FishDeliveryVehicleCategory>
      filteredVehicleCategories = [];

  final Set<String> selectedVehicleCategoryIds =
      <String>{};

  bool loadingVehicleCategories = false;
  static const List<FishDeliveryVehicleCategory>
      defaultCategories = [
    FishDeliveryVehicleCategory(
      id: 'bike',
      name: 'Bike',
      iconType: 'bike',
    ),
    FishDeliveryVehicleCategory(
      id: 'auto',
      name: 'Auto',
      iconType: 'auto',
    ),
    FishDeliveryVehicleCategory(
      id: 'car',
      name: 'Car',
      iconType: 'car',
    ),
    FishDeliveryVehicleCategory(
      id: 'van',
      name: 'Van',
      iconType: 'van',
    ),
    FishDeliveryVehicleCategory(
      id: 'mini_truck',
      name: 'Mini Truck',
      iconType: 'mini_truck',
    ),
    FishDeliveryVehicleCategory(
      id: 'truck',
      name: 'Truck',
      iconType: 'truck',
    ),
    FishDeliveryVehicleCategory(
      id: 'cycle',
      name: 'Cycle',
      iconType: 'cycle',
    ),
  ];

  List<FishDeliveryVehicleCategory>
      customCategories = [];

  final Set<String>
      selectedCategoryIds = {};

  // ============================================================
  // SPECIALIZATIONS
  // ============================================================

  final List<String> itemList = [
    'Foods',
    'Fish',
    'Vegetables',
    'Fruits',
    'Fruits & Vegetables',
 
  ];

  List<String> selectedItemList = [];

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadVehicleCategories();
 vehicleSearchController.addListener(
      _filterVehicleCategories,
    );

     filteredStates = List<String>.from(indiaStates);

  loadDistricts();
  }

  @override
  void dispose() {

    timer?.cancel();
    usernameController.dispose();
    mobileController.dispose();
    secondaryPhoneController.dispose();
    otpController.dispose();
    vehicleNumberController.dispose();
    vehicleSearchController.dispose();
    specializationSearchController.dispose();
    stateSearchController.dispose();
    districtSearchController.dispose();

    super.dispose();
  }

 List<String> get allSpecializations {
  final List<String> result = [];

  for (final specialization in itemList) {
    if (!result.contains(specialization)) {
      result.add(specialization);
    }
  }

  for (final specialization in customSpecializations) {
    if (!result.contains(specialization)) {
      result.add(specialization);
    }
  }

  return result;
}

  void filterSpecializations(String value) {
  final String search =
      value.trim().toLowerCase();

  final List<String> result =
      allSpecializations.where((specialization) {
    return search.isEmpty ||
        specialization
            .toLowerCase()
            .contains(search);
  }).toList();

  if (!mounted) return;

  setState(() {
    filteredSpecializations = result;
  });
}  

  void addCustomSpecialization() {
  final String specialization =
      customSpecializationController.text.trim();

  if (specialization.isEmpty) {
    showMessage(
      'Please enter a specialization.',
    );
    return;
  }

  final int existingIndex =
      allSpecializations.indexWhere(
    (item) =>
        item.toLowerCase() ==
        specialization.toLowerCase(),
  );

  String actualSpecialization;

  if (existingIndex != -1) {
    actualSpecialization =
        allSpecializations[existingIndex];
  } else {
    customSpecializations.add(
      specialization,
    );

    actualSpecialization =
        specialization;
  }

  if (!selectedItemList
      .contains(actualSpecialization)) {
    selectedItemList.add(
      actualSpecialization,
    );
  }

  customSpecializationController.clear();
  specializationSearchController.clear();

  filterSpecializations('');

  if (mounted) {
    setState(() {
      specializationError = false;
    });
  }

  Navigator.of(context).pop();

  showMessage(
    '$actualSpecialization added.',
  );
}

  void showAddSpecializationDialog() {
  customSpecializationController.clear();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),
        title: const Text(
          'Add Your Own Specialization',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller:
              customSpecializationController,
          textCapitalization:
              TextCapitalization.words,
          maxLength: 50,
          decoration: InputDecoration(
            hintText:
                'Enter specialization',
            prefixIcon: const Icon(
              Icons.medical_services_outlined,
              color: green,
            ),
            filled: true,
            fillColor: lightFill,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
              );
            },
            child: const Text(
              'CANCEL',
            ),
          ),
          ElevatedButton(
            onPressed:
                addCustomSpecialization,
            style:
                ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor:
                  Colors.white,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'ADD',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}
 
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
    final snapshot = await _firestore
        .collection('fishDeliveryVehicleCategories')
        .orderBy('name')
        .get();

    final List<FishDeliveryVehicleCategory> categories = [];

    // Built-in categories
    categories.addAll(defaultCategories);

    // Custom Food Delivery categories
    for (final doc in snapshot.docs) {
      final data = doc.data();

      final name =
          (data['name'] ?? '').toString().trim();

      if (name.isEmpty) {
        continue;
      }

      final category =
          FishDeliveryVehicleCategory.fromMap(
        doc.id,
        data,
      );

      final alreadyExists =
          categories.any(
        (item) =>
            item.name.trim().toLowerCase() ==
            category.name.trim().toLowerCase(),
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
          List<FishDeliveryVehicleCategory>.from(
        categories,
      );

      loadingVehicleCategories = false;
    });
  } catch (e) {
    debugPrint(
      'Food Delivery vehicle category loading error: $e',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      // Built-in categories always remain available.
      allVehicleCategories =
          List<FishDeliveryVehicleCategory>.from(
        defaultCategories,
      );

      filteredVehicleCategories =
          List<FishDeliveryVehicleCategory>.from(
        defaultCategories,
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
          List<FishDeliveryVehicleCategory>.from(
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
    FishDeliveryVehicleCategory category,
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

 void showMessage(
  String message, {
  bool error = false,
}) {
  if (!mounted) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),

        backgroundColor: error
            ? Colors.red
            : const Color(0xFF16803C),

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
}

  // ==============================================================
  // SEND OTP
  // ===============================================================

Future<void> sendOTP({bool isResend = false}) async {
  if (isSendingOtp || isVerifying) return;

  final phone = mobileController.text.trim();

  if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
    showMessage( AppLocalizations.of(context)!.enteradigitmobilenumber,
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
    await _auth.verifyPhoneNumber(
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
          await _auth.signInWithCredential(credential);

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

    await _auth.signInWithCredential(credential);

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

  // ==========================================================
  // PICK PROFILE PHOTO
  // ==========================================================
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

  // ==========================================================
  // CATEGORY ID
  // ==========================================================

  String _makeCategoryId(
    String value,
  ) {
    final normalized =
        value
            .toLowerCase()
            .replaceAll(
              RegExp(r'[^a-z0-9]+'),
              '_',
            )
            .replaceAll(
              RegExp(r'_+'),
              '_',
            )
            .replaceAll(
              RegExp(r'^_|_$'),
              '',
            );

    return normalized.isEmpty
        ? 'custom_${DateTime.now().millisecondsSinceEpoch}'
        : 'custom_$normalized';
  }

  // ==========================================================
  // VEHICLE NUMBER
  // ==========================================================

Widget _vehicleNumberField() {
  final bool hasError =
      vehicleNumberError != null &&
      vehicleNumberError!.isNotEmpty;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // =========================
      // PLATE COLOR SELECTION
      // =========================
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // WHITE
          GestureDetector(
            onTap: () {
              setState(() {
                selectedVehicleNumberColor = Colors.white;
              });
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      selectedVehicleNumberColor == Colors.white
                          ? Colors.black
                          : Colors.grey,
                  width:
                      selectedVehicleNumberColor == Colors.white
                          ? 3
                          : 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child:
                  selectedVehicleNumberColor == Colors.white
                      ? const Icon(
                          Icons.check,
                          color: Colors.black,
                          size: 22,
                        )
                      : null,
            ),
          ),

          const SizedBox(width: 18),

          // YELLOW
          GestureDetector(
            onTap: () {
              setState(() {
                selectedVehicleNumberColor =
                    const Color(0xFFFFD84D);
              });
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD84D),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      selectedVehicleNumberColor ==
                              const Color(0xFFFFD84D)
                          ? Colors.black
                          : Colors.grey,
                  width:
                      selectedVehicleNumberColor ==
                              const Color(0xFFFFD84D)
                          ? 3
                          : 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child:
                  selectedVehicleNumberColor ==
                          const Color(0xFFFFD84D)
                      ? const Icon(
                          Icons.check,
                          color: Colors.black,
                          size: 22,
                        )
                      : null,
            ),
          ),
        ],
      ),

      const SizedBox(height: 12),

      // =========================
      // VEHICLE NUMBER
      // =========================
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: selectedVehicleNumberColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: vehicleNumberController,

          keyboardType: TextInputType.text,

          textCapitalization:
              TextCapitalization.characters,

          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[A-Za-z0-9 ]'),
            ),
            UpperCaseTextFormatter(),
          ],

          onChanged: (value) {
            if (vehicleNumberError != null) {
              setState(() {
                vehicleNumberError = null;
              });
            }
          },

          style: const TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),

          textAlign: TextAlign.center,

          decoration: const InputDecoration(
            hintText: 'Enter your Number Plate',

            hintStyle: TextStyle(
              color: Color(0xFF555555),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),

            prefixIcon: Icon(
              Icons.directions_car_outlined,
              color: Colors.black,
              size: 27,
            ),

            border: InputBorder.none,

            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 17,
            ),
          ),
        ),
      ),

      if (hasError)
        Padding(
          padding: const EdgeInsets.only(
            left: 8,
            top: 5,
          ),
          child: Text(
            vehicleNumberError!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 13,
            ),
          ),
        ),
    ],
  );
}

  String _normalizeVehicleNumber(String value) {
  return value
      .toUpperCase()
      .replaceAll(
        RegExp(r'[^A-Z0-9]'),
        '',
      );
}

String _displayVehicleNumber(String value) {
  final normalized =
      _normalizeVehicleNumber(value);

  if (normalized.length <= 2) {
    return normalized;
  }

  if (normalized.length <= 4) {
    return '${normalized.substring(0, 2)} '
        '${normalized.substring(2)}';
  }

  if (normalized.length <= 6) {
    return '${normalized.substring(0, 2)} '
        '${normalized.substring(2, 4)} '
        '${normalized.substring(4)}';
  }

  return '${normalized.substring(0, 2)} '
      '${normalized.substring(2, 4)} '
      '${normalized.substring(4, 6)} '
      '${normalized.substring(6)}';
}

  // ==========================================================
  // SAVE FISH DELIVERY → FIRESTORE
  // ==========================================================

  Future<void>
      _saveFishDeliveryToFirestore({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _firestore
        .collection(
          'fishDeliveryGuys',
        )
        .doc(uid)
        .set(
      data,
      SetOptions(
        merge: true,
      ),
    );
  }

  // ==========================================================
  // SAVE FISH DELIVERY → HIVE
  // ==========================================================

  Future<void> _saveFishDeliveryToHive({
    required Map<String, dynamic> data,
  }) async {
    final box =
        await Hive.openBox(
      'fishDeliveryProfiles',
    );

    await box.put(
      'currentProfile',
      data,
    );
  }

  // ==========================================================
  // SUBMIT
  // ==========================================================
Future<void> _submit() async {
  if (isSubmitting) return;

  bool hasError = false;

  // ============================================================
  // USERNAME
  // ============================================================
//final username = usernameController.text.trim();
  if (usernameController.text.trim().isEmpty) {
    hasError = true;
  }

  // ============================================================
  // PRIMARY MOBILE
  // ============================================================

  final primary = mobileController.text
      .trim()
      .replaceAll(RegExp(r'\D'), '');

  if (primary.length != 10) {
    hasError = true;
  }

  // ============================================================
  // SECONDARY MOBILE
  // ============================================================

  final secondary = secondaryPhoneController.text
      .trim()
      .replaceAll(RegExp(r'\D'), '');

  if (secondary.length != 10) {
    hasError = true;
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

  // ============================================================
  // VEHICLE CATEGORY
  // ============================================================

  if (selectedVehicleCategoryIds.isEmpty) {
    hasError = true;
  }

  // ============================================================
  // VEHICLE NUMBER
  // ============================================================

  final vehicleNumber = _normalizeVehicleNumber(
    vehicleNumberController.text,
  );
  if (vehicleNumber.length < 8) {
  vehicleNumberError = AppLocalizations.of(context)!.enteradigitmobilenumber;
  hasError = true;
} else {
  vehicleNumberError = null;
}

  if (vehicleNumber.length < 8) {
    hasError = true;
  }

  if (!mounted) return;

  setState(() {
    vehicleCategoryError =
        selectedVehicleCategoryIds.isEmpty;

    vehicleNumberError =
        vehicleNumber.length < 8
            ? AppLocalizations.of(context)!.enteradigitmobilenumber
            : null;
  });

   // ==========================================================
// GARAGE LOCATION
// ==========================================================

if (currentLocation == null) {
  locationError = true;
  hasError = true;
} else {
  locationError = false;
}


  // ============================================================
  // TERMS & CONDITION / PRIVACY POLICY
  // ============================================================
  if (!privacyPolicyAccepted) {
  setState(() {
    privacyPolicyError =
        'Please accept the Privacy Policy and Terms & Conditions.';
  });

  showMessage(
    'Please accept the Privacy Policy and Terms & Conditions.',
  );

  return;
}

  // ============================================================
  // STOP IF VALIDATION ERROR
  // ============================================================

  if (hasError) {
    return;
  }

if (!otpSent) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Please send OTP first.'),
    ),
  );
  return;
}

if (!otpVerified) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Please verify OTP first.'),
    ),
  );
  return;
}
  // ============================================================
  // OTP SENT
  // ============================================================

  if (!otpSent) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please send OTP first.',
        ),
      ),
    );

    return;
  }

  // ============================================================
  // OTP VERIFIED
  // ============================================================

  if (!otpVerified) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please verify OTP first.',
        ),
      ),
    );

    return;
  }

  // ============================================================
  // FIREBASE USER
  // ============================================================

  final User? user = _auth.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Authentication failed. Please verify OTP again.',
        ),
      ),
    );

    return;
  }

  if (!mounted) return;

  // ============================================================
  // START LOADING
  // ============================================================

  setState(() {
    isSubmitting = true;
  });

  try {
    final uid = user.uid;

    // ============================================================
    // SELECTED CATEGORIES
    // ============================================================

    final selectedCategories =
        allVehicleCategories
            .where(
              (category) =>
                  selectedVehicleCategoryIds
                      .contains(category.id),
            )
            .map(
              (category) => category.toMap(),
            )
            .toList();

    // ============================================================
    // VEHICLE COLOR
    // ============================================================

    final String vehicleNumberColor =
        selectedVehicleNumberColor ==
                const Color(0xFFFFD84D)
            ? 'yellow'
            : 'white';

    // ============================================================
    // PROFILE DATA
    //
    // Do NOT upload photo or Firestore here.
    // First save locally, just like Student.
    // ============================================================

    final Map<String, dynamic> hiveData = {
      'uid': uid,

      'role': 'fish_delivery',

      'serviceType': 'fish_delivery',

      'username':
    usernameController.text.trim(),

'mobileNumber':
    '+91$primary',

'secondaryMobileNumber':
    '+91$secondary',

// STATE, DISTRICT AND NEAREST CITY
'state': selectedState!.trim(),

'district': selectedDistrict!.trim(),

'nearestTown':
    nearestCityController.text.trim(),

// ==========================================================
// CURRENT CONSULTATION LOCATION
// ==========================================================

'currentLocationName':
    currentLocation?.placeName ?? '',

'currentLocationLatitude':
    currentLocation?.latitude,

'currentLocationLongitude':
    currentLocation?.longitude,

// VEHICLE CATEGORIES
'categories':
    selectedVehicleCategoryIds.toList(),

// DELIVERY SPECIALIZATIONS
'specializations':
    List<String>.from(selectedItemList),

'customSpecializations':
    List<String>.from(customSpecializations),

// VEHICLE CATEGORY DETAILS
'categoryDetails':
    selectedCategories,

      'vehicleNumber':
          vehicleNumber,

      'vehicleNumberDisplay':
          _displayVehicleNumber(
        vehicleNumber,
      ),

      'vehicleNumberColor':
          vehicleNumberColor,

      // Keep existing URL if this is an edit.
      'profilePhotoUrl':
          profilePhotoUrl,

      'isActive': true,

      'profileCompleted': true,

      'isLive': false,

      'liveDate': null,

      'updatedAt':
          DateTime.now().toIso8601String(),
    };

    // ============================================================
    // 1. SAVE HIVE FIRST
    // ============================================================

    await _saveFishDeliveryToHive(
      data: hiveData,
    );

    // ============================================================
    // 2. WAIT 2 SECONDS
    // Same behavior as Student
    // ============================================================

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    // ============================================================
    // 3. STOP LOADING
    // ============================================================

    setState(() {
      isSubmitting = false;
    });

    // ============================================================
    // 4. GO TO HOME
    // ============================================================

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const ScreenHome(),
      ),
      (route) => false,
    );

    // ============================================================
    // 5. FIRESTORE + PHOTO SYNC IN BACKGROUND
    // 
    _syncFishDeliveryToFirestore(
  uid: uid,
  primary: primary,
  secondary: secondary,
  selectedCategories: selectedCategories,
  selectedCategoryIds:
      selectedVehicleCategoryIds.toList(),
  vehicleNumber: vehicleNumber,
  vehicleNumberColor: vehicleNumberColor,
  profileData: Map<String, dynamic>.from(hiveData),
);



  } catch (e, stackTrace) {
    debugPrint(
      'Food Delivery submit error: $e',
    );

    debugPrint(
      'Stack trace: $stackTrace',
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not save Food Delivery profile locally: $e',
        ),
      ),
    );
  }
}

Future<void> _syncFishDeliveryToFirestore({
  required String uid,
  required String primary,
  required String secondary,
  required List<String> selectedCategoryIds,
  required List<Map<String, dynamic>> selectedCategories,
  required String vehicleNumber,
  required String vehicleNumberColor,
  required Map<String, dynamic> profileData,
}) async {
  try {
    // ==========================================================
    // PROFILE PHOTO
    // ==========================================================

    String? photoUrl = profilePhotoUrl;

    if (profilePhoto != null) {
      photoUrl = await uploadProfilePhoto(uid);
    }

    // ==========================================================
    // FIRESTORE PROFILE
    // ==========================================================

    final profileRef = _firestore
        .collection('fishDeliveryGuys')
        .doc(uid);

    final existingProfile =
        await profileRef.get();

    final Map<String, dynamic> data = {
      ...profileData,
      'uid': uid,

      'role': 'fish_delivery',

      'serviceType': 'fish_delivery',

      'username':
    usernameController.text.trim(),

'mobileNumber':
    '+91$primary',

'secondaryMobileNumber':
    '+91$secondary',

// ==========================================================
// CURRENT CONSULTATION LOCATION
// ==========================================================

'currentLocationName':
    currentLocation?.placeName ?? '',

'currentLocationLatitude':
    currentLocation?.latitude,

'currentLocationLongitude':
    currentLocation?.longitude,

'currentLocation': {
  'placeName': currentLocation?.placeName ?? '',
  'latitude': currentLocation?.latitude,
  'longitude': currentLocation?.longitude,
},

// Compatibility fields for location-based searches.
if (currentLocation?.latitude != null &&
    currentLocation?.longitude != null) ...{
  'latitude': currentLocation!.latitude,
  'longitude': currentLocation!.longitude,
  'location': GeoPoint(
    currentLocation!.latitude!,
    currentLocation!.longitude!,
  ),
},

// STATE, DISTRICT AND NEAREST CITY
'state': selectedState!.trim(),

'district': selectedDistrict!.trim(),

'nearestTown':
    nearestCityController.text.trim(),

// VEHICLE CATEGORIES
'categories': selectedCategoryIds,

// DELIVERY SPECIALIZATIONS
'specializations':
    List<String>.from(selectedItemList),

'customSpecializations':
    List<String>.from(customSpecializations),

// SEARCH-FRIENDLY SPECIALIZATIONS
'specializationSearch':
    selectedItemList
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toList(),

      'categoryDetails':
          selectedCategories,

      'vehicleNumber':
          vehicleNumber,

      'vehicleNumberDisplay':
          _displayVehicleNumber(
        vehicleNumber,
      ),

      'vehicleNumberColor':
          vehicleNumberColor,

      'profilePhotoUrl':
          photoUrl,

'isActive': true,
'isOnline': true,
'onlineUpdatedAt': FieldValue.serverTimestamp(),
'profileCompleted': true,
      'isLive': false,

      'liveDate': null,

      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    if (!existingProfile.exists) {
      data['createdAt'] =
          FieldValue.serverTimestamp();
    }

  await _saveFishDeliveryToFirestore(
  uid: uid,
  data: data,
);

await _saveFishDeliverySpecializations();

    debugPrint(
      'Food Delivery Firestore sync successful.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'Food Delivery Firestore sync failed: $e',
    );

    debugPrint(
      'Food Delivery Firestore stack trace: $stackTrace',
    );
  }
}

Future<void> _saveFishDeliverySpecializations() async {
  final Set<String> names = {
    ...itemList,
    ...customSpecializations,
  };

  final WriteBatch batch = _firestore.batch();

  for (final String value in names) {
    final String name = value.trim();

    if (name.isEmpty) continue;

    final String id =
        Uri.encodeComponent(name.toLowerCase());

    final DocumentReference<Map<String, dynamic>> ref =
        _firestore
            .collection('fishDeliverySpecializations')
            .doc(id);

    batch.set(
      ref,
      {
        'name': name,
        'normalizedName': name.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  await batch.commit();
}

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

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

   Widget mobileSection() {
    final bool verified =
        otpVerified;

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
  color: primaryMobileError != null
      ? Colors.red
      : verified
          ? const Color(0xFF16803C)
          : Colors.grey.shade300,
  width: primaryMobileError != null || verified
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

                  onChanged: (value) {
  if (primaryMobileError != null &&
      _isValidIndianMobile(value.trim())) {
    setState(() {
      primaryMobileError = null;
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

  Widget secondaryMobileSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sectionTitle(
        'Secondary Mobile Number',
      ),

      const SizedBox(height: 8),

      Container(
        height: 62,

        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),

          borderRadius: BorderRadius.circular(20),

         border: Border.all(
  color: secondaryMobileError != null
      ? Colors.red
      : const Color(0xFFD5D5D5),
  width: secondaryMobileError != null
      ? 2
      : 1.5,
),
        ),

        child: Row(
          children: [
            const SizedBox(
              width: 14,
            ),

            // --------------------------------------------------
            // PHONE ICON
            // --------------------------------------------------

            const Icon(
              Icons.phone_android_outlined,
              color: Color(0xFF16803C),
              size: 27,
            ),

            const SizedBox(
              width: 10,
            ),

            // --------------------------------------------------
            // COUNTRY CODE
            // --------------------------------------------------

            const Text(
              '+91',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            // --------------------------------------------------
            // MOBILE NUMBER
            // --------------------------------------------------

            Expanded(
              child: TextFormField(
                controller:
                    secondaryPhoneController,

                keyboardType:
                    TextInputType.phone,

                maxLength: 10,

                inputFormatters: [
                  FilteringTextInputFormatter
                      .digitsOnly,
                ],
                 onChanged: (value) {
  if (secondaryMobileError != null &&
      _isValidIndianMobile(value.trim())) {
    setState(() {
      secondaryMobileError = null;
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

                  enabledBorder:
                      InputBorder.none,

                  focusedBorder:
                      InputBorder.none,

                  errorBorder:
                      InputBorder.none,

                  focusedErrorBorder:
                      InputBorder.none,

                  contentPadding:
                      EdgeInsets.zero,
                ),

                validator: (value) {
                  final number =
                      value?.trim() ?? '';

                  if (number.isEmpty) {
                    return 'Please enter secondary mobile number';
                  }

                  if (number.length != 10) {
                    return  AppLocalizations.of(context)!.enteradigitmobilenumber;
                  }

                  if (!RegExp(
                    r'^[6-9][0-9]{9}$',
                  ).hasMatch(number)) {
                    return AppLocalizations.of(context)!.enteradigitmobilenumber;
                  }

                  return null;
                },
              ),
            ),

            const SizedBox(
              width: 12,
            ),
          ],
        ),
      ),
      if (secondaryMobileError != null)
  Padding(
    padding: const EdgeInsets.only(
      top: 6,
      left: 5,
    ),
    child: Text(
      secondaryMobileError!,
      style: const TextStyle(
        color: Colors.red,
        fontSize: 12,
      ),
    ),
  ),

      const SizedBox(
        height: 7,
      ),

      const Text(
        'You can use the same number if another number is not available.',
        style: TextStyle(
          color: Color(0xFF777777),
          fontSize: 12,
          height: 1.4,
        ),
      ),

      const SizedBox(
        height: 2,
      ),

      const Text(
        'Note : This number will be shown to users when they choose to call you.',
        style: TextStyle(
          color: Color(0xFF777777),
          fontSize: 12,
          height: 1.4,
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
                            : localizedState(selectedState!, languageCode),
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

Widget districtSection() {
  final languageCode = currentLanguageCode(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
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
  // LOCATION SECTION
  // ============================================================

  Widget locationSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Consulting Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),

        const SizedBox(height: 8),

        Container(
          width: double.infinity,

          padding:
              const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color:
                const Color(0xFFF9F9F9),
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
  color: locationError
      ? Colors.red
      : const Color(0xFFE0E0E0),
  width: locationError ? 2 : 1.5,
),
          ),

          child: currentLocation == null
              ? Column(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color:
                          Color(0xFF08744F),
                      size: 38,
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Add your Consultation location',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            Color(0xFF666666),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 48,
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            isGettingLocation
                                ? null
                                : _getCurrentLocation,

                        icon:
                            isGettingLocation
                                ? const SizedBox(
                                    width: 19,
                                    height: 19,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location,
                                  ),

                        label: Text(
                          isGettingLocation
                              ? 'Getting Location...'
                              : 'Add Consultation Location',
                        ),

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(
                            0xFF16803C,
                          ),
                          foregroundColor:
                              Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

SizedBox(
  width: double.infinity,
  height: 48,
  child: OutlinedButton.icon(
    onPressed: _showManualLocationDialog,
    icon: const Icon(Icons.edit_location_alt_outlined),
    label: const Text('Enter or Paste Garage Location'),
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF16803C),
      side: const BorderSide(
        color: Color(0xFF16803C),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
  ),
),
                  ],
                )
              : Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color:
                              Color(0xFF16803C),
                          size: 28,
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text(
                                'Shop Location',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color:
                                      Color(
                                    0xFF12652F,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                currentLocation!
                                    .placeName,
                                style:
                                    const TextStyle(
                                  fontSize: 14,
                                  color:
                                      Color(
                                    0xFF555555,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child:
                   
                            OutlinedButton.icon(
  onPressed: () {
    // Immediately invalidate any running location request.
    _locationRequestId++;

    // Immediately update the UI.
    setState(() {
      currentLocation = null;
      isGettingLocation = false;
      isSearchingLocation = false;
      locationError = false;
    });
  },
  icon: const Icon(
    Icons.delete_outline,
  ),
  label: const Text(
    'Remove',
  ),
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.red,
    side: const BorderSide(
      color: Colors.red,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  ),
),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

Future<void> _showManualLocationDialog() async {
  _shopLocationController.clear();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'Enter / Copy & Paste from Google Maps',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: _shopLocationController,
          maxLines: 4,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            hintText:
                'Type a place name or paste a Google Maps link',
            labelText: 'Consultation Location',
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF16803C),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final String input =
                  _shopLocationController.text.trim();

              if (input.isEmpty) {
                showMessage(
                  'Please enter or paste your garage location.',
                  error: true,
                );
                return;
              }

              Navigator.pop(dialogContext);

         final String? placeName =
    await _processManualGarageLocation(input);

if (!mounted) return;

if (placeName == null ||
    placeName.trim().isEmpty) {
  showMessage(
    'Could not identify this location. '
    'Please try again.',
    error: true,
  );
  return;
}

setState(() {
  currentLocation = FishDeliveryLocation(
    placeName: placeName.trim(),
    latitude: null,
    longitude: null,
  );
  locationError = false;
  isGettingLocation = false;
  isSearchingLocation = false;
});

showMessage(
  'Consultation location added.',
);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16803C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Add Location'),
          ),
        ],
      );
    },
  );
}

Future<String?> _processManualGarageLocation(
  String input,
) async {
  final String value = input.trim();

  if (value.isEmpty) {
    return null;
  }

  // ==========================================================
  // CHECK IF THIS IS A GOOGLE MAPS LINK
  // ==========================================================

  final bool isGoogleMapsLink =
      value.contains('google.com/maps') ||
      value.contains('maps.google.com') ||
      value.contains('maps.app.goo.gl') ||
      value.contains('goo.gl/maps');

  if (!isGoogleMapsLink) {
  try {
    final locations =
        await geo.locationFromAddress(value);

    if (locations.isEmpty) {
      return null;
    }

    // A text address must resolve to coordinates
    // before it can be accepted.
    for (final location in locations) {
      final matches =
          await _verifyLocationAgainstSelection(
        location.latitude,
        location.longitude,
      );

      if (!mounted) return null;

      if (matches) {
        return value;
      }
    }

    return null;
  } catch (e) {
    debugPrint('Manual address verification error: $e');
    return null;
  }
}

  // ==========================================================
  // GOOGLE MAPS LINK
  // ==========================================================

  final GoogleMapsLocationExtractor extractor =
      GoogleMapsLocationExtractor();

  try {
    final GoogleMapsLocation location =
        await extractor.extract(value);

// Never accept a Google Maps link based on its
// displayed place name alone. Verify its coordinates.
if (location.latitude != null &&
    location.longitude != null) {
  final matches = await _verifyLocationAgainstSelection(
    location.latitude!,
    location.longitude!,
  );

  if (!mounted || !matches) {
    return null;
  }
} else {
  // Without coordinates, resolve the address or place name
  // to coordinates and verify before accepting it.
  final addressToVerify =
      (location.address ?? '').trim().isNotEmpty
          ? location.address!.trim()
          : (location.placeName ?? '').trim();

  if (addressToVerify.isEmpty) {
    return null;
  }

  try {
    final locations =
        await geo.locationFromAddress(addressToVerify);

    if (locations.isEmpty) {
      return null;
    }

    bool matched = false;

    for (final candidate in locations) {
      if (await _verifyLocationAgainstSelection(
        candidate.latitude,
        candidate.longitude,
      )) {
        matched = true;
        break;
      }
    }

    if (!mounted || !matched) {
      return null;
    }
  } catch (e) {
    debugPrint('Maps address verification error: $e');
    return null;
  }
}
    // --------------------------------------------------------
    // FIRST PRIORITY: PLACE NAME
    // --------------------------------------------------------

    if (location.placeName != null &&
        location.placeName!.trim().isNotEmpty) {
      return location.placeName!.trim();
    }

    // --------------------------------------------------------
    // SECOND PRIORITY: ADDRESS
    // --------------------------------------------------------

    if (location.address != null &&
        location.address!.trim().isNotEmpty) {
      return location.address!.trim();
    }

    // --------------------------------------------------------
    // THIRD PRIORITY: COORDINATES
    // --------------------------------------------------------

    if (location.latitude != null &&
        location.longitude != null) {
      try {
        final placemarks =
            await geo.placemarkFromCoordinates(
          location.latitude!,
          location.longitude!,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          final parts = <String>[
            if ((place.name ?? '').trim().isNotEmpty)
              place.name!.trim(),

            if ((place.locality ?? '').trim().isNotEmpty)
              place.locality!.trim(),

            if ((place.administrativeArea ?? '')
                .trim()
                .isNotEmpty)
              place.administrativeArea!.trim(),
          ];

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      } catch (e) {
        debugPrint(
          'Reverse geocoding error: $e',
        );
      }
    }

    return null;
  } catch (e) {
    debugPrint(
      'Google Maps location extraction error: $e',
    );

    return null;
  } finally {
    extractor.close();
  }
}

String _normalizeLocationName(String value) {
  return value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
}

Future<bool> _verifyLocationAgainstSelection(
  double latitude,
  double longitude,
) async {
  // State selection is required.
  if (selectedState == null ||
      selectedState!.trim().isEmpty) {
    showMessage(
      'Please select your state first.',
      error: true,
    );
    return false;
  }

  try {
    final placemarks =
        await geo.placemarkFromCoordinates(
      latitude,
      longitude,
    );

    if (!mounted) return false;

    if (placemarks.isEmpty) {
      showMessage(
        'Unable to verify your current state. '
        'Please try again.',
        error: true,
      );
      return false;
    }

    // Check the detected state only.
    final expectedState =
        _normalizeLocationName(selectedState!);

    // Check available placemarks because the first one
    // may not contain the state name.
    final detectedStates = placemarks
        .map((place) =>
            (place.administrativeArea ?? '').trim())
        .where((state) => state.isNotEmpty)
        .toSet();

    debugPrint('========== LOCATION DEBUG ==========');
    debugPrint('Selected State: $selectedState');
    debugPrint('GPS Latitude: $latitude');
    debugPrint('GPS Longitude: $longitude');
    debugPrint('Detected States: $detectedStates');
    debugPrint('====================================');

    final stateMatches = detectedStates.any(
      (state) =>
          _normalizeLocationName(state) ==
          expectedState,
    );

    if (!stateMatches) {
      final detectedState = detectedStates.isEmpty
          ? 'unknown'
          : detectedStates.join(', ');

      showMessage(
        'State mismatch. You selected $selectedState, '
        'but your detected state is $detectedState. '
        'Location was not attached.',
        error: true,
      );

      return false;
    }

    // State matches. District is intentionally not checked.
    return true;
  } catch (e) {
    debugPrint('Location verification error: $e');

    if (mounted) {
      showMessage(
        'Unable to verify your state. '
        'Please check your internet connection '
        'and try again.',
        error: true,
      );
    }

    return false;
  }
}

  // ==========================================================
  // GET CURRENT LOCATION
  // ==========================================================

 Future<void> _getCurrentLocation() async {
  if (isGettingLocation) return;

  final int requestId = ++_locationRequestId;

  if (!mounted) return;

  setState(() {
    isGettingLocation = true;
  });

  try {
    // ----------------------------------------------------------
    // CHECK LOCATION SERVICE
    // ----------------------------------------------------------

    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!mounted || requestId != _locationRequestId) return;

   
    if (!serviceEnabled) {
  if (mounted) {
    setState(() {
      isGettingLocation = false;
    });
  }

  showMessage(
    'Please turn on location services.',
    error: true,
  );

  return;
}

    // ----------------------------------------------------------
    // CHECK PERMISSION
    // ----------------------------------------------------------

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (!mounted || requestId != _locationRequestId) return;

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (!mounted || requestId != _locationRequestId) return;

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        isGettingLocation = false;
      });

      showMessage(
        'Location permission is required.',
        error: true,
      );

      return;
    }

    // ----------------------------------------------------------
    // GET CURRENT LOCATION
    // ----------------------------------------------------------

    final position =
        await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    if (!mounted || requestId != _locationRequestId) return;

// Verify the actual GPS coordinates before attaching.
final bool locationMatches =
    await _verifyLocationAgainstSelection(
  position.latitude,
  position.longitude,
);

if (!mounted || requestId != _locationRequestId) {
  return;
}

if (!locationMatches) {
  return;
}
    // ----------------------------------------------------------
    // DEFAULT LOCATION NAME
    // ----------------------------------------------------------

    String placeName =
        '${position.latitude}, ${position.longitude}';

    // ----------------------------------------------------------
    // REVERSE GEOCODING
    // ----------------------------------------------------------

    try {
      final placemarks =
          await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted || requestId != _locationRequestId) return;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final parts = <String>[
          if ((place.name ?? '').trim().isNotEmpty)
            place.name!.trim(),

          if ((place.locality ?? '').trim().isNotEmpty)
            place.locality!.trim(),

          if ((place.administrativeArea ?? '')
              .trim()
              .isNotEmpty)
            place.administrativeArea!.trim(),
        ];

        if (parts.isNotEmpty) {
          placeName = parts.join(', ');
        }
      }
    } catch (e) {
      debugPrint(
        'Reverse geocoding error: $e',
      );
    }

    // ----------------------------------------------------------
    // SAVE LOCATION
    // ----------------------------------------------------------

    if (!mounted || requestId != _locationRequestId) return;

    setState(() {
  currentLocation = FishDeliveryLocation(
    placeName: placeName,
    latitude: position.latitude,
    longitude: position.longitude,
  );

  locationError = false;
});

    showMessage(
      'Consultation location added.',
    );
  } catch (e) {
    if (!mounted || requestId != _locationRequestId) return;

    showMessage(
      'Unable to get your location.',
      error: true,
    );
  } finally {
    if (mounted &&
        requestId == _locationRequestId) {
      setState(() {
        isGettingLocation = false;
      });
    }
  }
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
  // ==========================================================
  // CATEGORY SECTION
  // ==========================================================
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

Future<void> _showAddVehicleCategoryDialog() async {
  final TextEditingController categoryController =
      TextEditingController();

  bool isSaving = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (
          dialogContext,
          setDialogState,
        ) {
          Future<void> saveCategory() async {
            if (isSaving) return;

            final name =
                categoryController.text.trim();

            // ==================================================
            // VALIDATION
            // ==================================================

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

            final duplicate =
                allVehicleCategories.any(
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

            // ==================================================
            // CREATE CATEGORY
            // ==================================================

            final categoryId =
                _makeCategoryId(name);

            final newCategory =
                FishDeliveryVehicleCategory(
              id: categoryId,
              name: name,
              iconType: 'default',
              isCustom: true,
            );

            // ==================================================
            // CLOSE / UPDATE UI IMMEDIATELY
            // ==================================================

            setDialogState(() {
              isSaving = true;
            });

            if (!mounted) return;

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

              // Automatically select the
              // newly added category.
              if (!selectedVehicleCategoryIds
                  .contains(newCategory.id)) {
                selectedVehicleCategoryIds.add(
                  newCategory.id,
                );
              }

              vehicleCategoryError = false;

              // ==================================================
              // REFRESH SEARCH RESULTS
              // ==================================================

              final query =
                  vehicleSearchController.text
                      .trim()
                      .toLowerCase();

              if (query.isEmpty) {
                filteredVehicleCategories =
                    List<
                      FishDeliveryVehicleCategory
                    >.from(
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

            // ==================================================
            // CLOSE DIALOG IMMEDIATELY
            // ==================================================

            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }

            // ==================================================
            // SHOW SUCCESS IMMEDIATELY
            // ==================================================

            if (mounted) {
              showMessage(
                'Vehicle category added successfully.',
              );
            }

            // ==================================================
            // FIRESTORE SAVE IN BACKGROUND
            // ==================================================

            try {
              final uid =
                  _auth.currentUser?.uid;

              await _firestore
                  .collection(
                    'fishDeliveryVehicleCategories',
                  )
                  .doc(categoryId)
                  .set({
                'id': categoryId,
                'name': name,
                'iconType': 'default',
                'isCustom': true,
                'createdBy': uid,
                'createdAt':
                    FieldValue.serverTimestamp(),
              });

              debugPrint(
                'Food Delivery category saved: $name',
              );
            } catch (e, stackTrace) {
              debugPrint(
                'FOOD DELIVERY CATEGORY SAVE ERROR: $e',
              );

              debugPrint(
                'STACK TRACE: $stackTrace',
              );

              // ==================================================
              // IMPORTANT
              //
              // Category is already visible locally.
              // If Firestore fails, inform the user.
              // ==================================================

              if (mounted) {
                showMessage(
                  'Category added on this device, '
                  'but could not sync to the server.',
                );
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
                child: const Text(
                  'Cancel',
                ),
              ),

              ElevatedButton(
                onPressed:
                    isSaving ? null : saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
              ),
            ],
          );
        },
      );
    },
  );

  categoryController.dispose();
}
//======================================
  // VEHICLE CATEGORY CARD
  // ============================================================

  Widget _vehicleCategoryCard(
    FishDeliveryVehicleCategory category,
  ) {
    final selected =
        selectedVehicleCategoryIds
            .contains(category.id);

    return GestureDetector(
      onTap: () {
  setState(() {
    if (selectedVehicleCategoryIds.contains(category.id)) {
      selectedVehicleCategoryIds.remove(category.id);
    } else {
      selectedVehicleCategoryIds.add(category.id);
    }

    if (selectedVehicleCategoryIds.isNotEmpty) {
      vehicleCategoryError = false;
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
 
  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
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
                text: 'Fish Delivery',
                style:
                    TextStyle(
                  color:
                      Color(0xFF08744F),
                ),
              ),

              TextSpan(
                text:  AppLocalizations.of(context)!.registration,
                style:
                    TextStyle(
                 color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),

      body: Form(
        key: _formKey,

        child:
            ListView(
          padding:
              const EdgeInsets.all(
            16,
          ),

          children: [
            // ==================================================
            // USERNAME
            // ==================================================

            sectionTitle(
              'Username',
            ),

            const SizedBox(
              height: 8,
            ),

           
            TextFormField(
  controller: usernameController,
  textCapitalization: TextCapitalization.words,

  onChanged: (value) {
    if (usernameError != null &&
        value.trim().length >= 2) {
      setState(() {
        usernameError = null;
      });
    }
  },

  decoration: InputDecoration(
    hintText: 'Enter your name',
    prefixIcon: const Icon(Icons.person_outline),

    errorText: usernameError,

    border: const OutlineInputBorder(),

    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: usernameError != null
            ? Colors.red
            : Colors.grey.shade300,
        width: usernameError != null ? 2 : 1.5,
      ),
    ),

    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: usernameError != null
            ? Colors.red
            : const Color(0xFF16803C),
        width: 2,
      ),
    ),

    errorBorder: const OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.red,
        width: 2,
      ),
    ),

    focusedErrorBorder: const OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.red,
        width: 2,
      ),
    ),
  ),
),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // PRIMARY MOBILE
            // ==================================================

          sectionTitle('Mobile Number'),
              const SizedBox(height: 6),

   mobileSection(),

              
                 const SizedBox(height: 12),

                // =================================================
                // OTP
                // =================================================

                otpSection(),


            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // SECONDARY MOBILE
            // ==================================================

            const SizedBox(
              height: 8,
            ),

             secondaryMobileSection(),

            const SizedBox(
              height: 20,
            ),
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

            // ==================================================
            // CATEGORIES
            // ==================================================

             _vehicleCategorySection(),
            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // VEHICLE NUMBER
            // ==================================================

            sectionTitle(
              'Vehicle Number',
            ),

            const SizedBox(
              height: 8,
            ),

           _vehicleNumberField(),

            const SizedBox(height: 20),

            // ==================================================
            // OPTIONAL PHOTO
            // ==================================================

            _profilePhotoSection(),
              const SizedBox(height: 20),

              locationSection(),


            const SizedBox(
              height: 35,
            ),
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

            // ==================================================
            // SUBMIT
            // ==================================================

            SizedBox(
              height: 52,

              child:
                  ElevatedButton(
                onPressed:
                    isSubmitting
                        ? null
                        : _submit,

                child:
                    isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2.5,
                            ),
                          )
                        : const Text(
                            'Submit',
                            style:
                                TextStyle(
                              fontSize:
                                  16,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}
