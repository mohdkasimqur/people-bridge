import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:google_location_extract/google_location_extract.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jober_india/jober_indiaScreens.dart/TaxiCommercial/screen_taxicommercial_data.dart';
import 'package:jober_india/jober_indiaScreens.dart/common_profile_services.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_camera_capture.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_home.dart';
import 'package:jober_india/l10n/app_localizations.dart';
import 'package:jober_india/screens/location_localization.dart';
import 'package:path/path.dart' as path;

import '../Privacy&Terms/privacy_terms_section.dart';


class TaxiCommercialLocation {
  final String placeName;
  final double? latitude;
  final double? longitude;

  TaxiCommercialLocation({
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

  factory TaxiCommercialLocation.fromMap(
    Map<String, dynamic> map,
  ) {
    return TaxiCommercialLocation(
      placeName: map['placeName']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

class ScreenTaxicomrcialLogin extends StatefulWidget {
  const ScreenTaxicomrcialLogin({super.key});

  @override
  State<ScreenTaxicomrcialLogin> createState() =>
      _ScreenTaxicomrcialLoginState();
}

class _ScreenTaxicomrcialLoginState
    extends State<ScreenTaxicomrcialLogin> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController secondaryPhoneController =
      TextEditingController();
   final TextEditingController _shopLocationController =
    TextEditingController();
  final TextEditingController nameController =
      TextEditingController();
  final TextEditingController mobileController =
      TextEditingController();
  final TextEditingController otpController =
      TextEditingController();

  // OPTIONAL VEHICLE NAME / MODEL
   final TextEditingController   vehicleNameController =
      TextEditingController();

  // REQUIRED VEHICLE NUMBER
  final TextEditingController vehicleNumberController =
      TextEditingController();

  // ADD YOUR VEHICLE
  final TextEditingController customVehicleController =
      TextEditingController();

 static const Color green =
      Color(0xFF138808);

  static const Color darkText =
      Color(0xFF202124);

  static const Color lightFill =
      Color(0xFFF9F9F9);
  // ============================================================
  // FOCUS NODE
  // ============================================================

  final FocusNode otpFocusNode = FocusNode();

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;


   bool locationError = false;

   // ==========================================================
  // LOCATION
  // ==========================================================
TaxiCommercialLocation? currentLocation;

bool isGettingLocation = false;
bool isSearchingLocation = false;

// Used to invalidate an older location request
int _locationRequestId = 0;

  // ============================================================
  // OTP
  // ============================================================

  // String? verificationId;

  // bool otpSent = false;
  // bool otpVerified = false;

  // bool isSendingOtp = false;
  // bool isVerifying = false;
  // bool isSubmitting = false;

  //  bool otpError = false;

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


  bool privacyPolicyAccepted = false;
  String? privacyPolicyError;

  // ============================================================
  // ERROR STATES
  // ============================================================

  String? nameError;
  String? mobileErrorMessage;
 bool mobileError = false;

  // String? otpError;
  String? genderError;
  String? vehicleError;
  String? vehicleNumberError;
String? secondaryMobileError;
  // ============================================================
  // DRIVER TYPE
  // ============================================================

  String selectedType = 'Taxi';

  // ============================================================
  // VEHICLE
  // ============================================================

  String? selectedVehicle;

  // ============================================================
  // GENDER
  // ============================================================

  String? selectedGender;

  final List<String> genderOptions = [
    'Male',
    'Female',
  ];

  File? profilePhoto;
  String? profilePhotoUrl;
bool isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();
 //VEHICLE SECTION

List<Map<String, String>> _loadedVehicles = [];

//bool _isLoadingVehicles = false;

// List<Map<String, String>> get currentVehicles {
//   if (_loadedVehicles.isNotEmpty) {
//     return _loadedVehicles;
//   }

//   final List<TaxiCommercialVehicleCategory> source =
//       getPredefinedVehicleCategories(selectedType);

//   return source.map((vehicle) {
//     return <String, String>{
//       'name': vehicle.name,
//       'image': vehicle.image,
//       'imageUrl': vehicle.imageUrl,
//       'isCustom': vehicle.isCustom.toString(),
//     };
//   }).toList();
// }
StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _vehicleSubscription;

List<Map<String, String>> get currentVehicles {
  final vehicles = _loadedVehicles.isNotEmpty
      ? List<Map<String, String>>.from(_loadedVehicles)
      : getPredefinedVehicleCategories(selectedType)
          .map((vehicle) => <String, String>{
                'name': vehicle.name,
                'image': vehicle.image,
                'imageUrl': vehicle.imageUrl,
                'isCustom': vehicle.isCustom.toString(),
              })
          .toList();

  // Put custom vehicles first so they appear in the visible grid.
  final custom = vehicles
      .where((v) => v['isCustom'] == 'true')
      .toList();

  final predefined = vehicles
      .where((v) => v['isCustom'] != 'true')
      .toList();

  return [...custom, ...predefined];
}

@override
void initState() {
  super.initState();

    filteredStates = List<String>.from(indiaStates);

    loadDistricts();

    stateSearchController.addListener(() {
      filterStates(stateSearchController.text);
    });

  _listenToVehicles();
}
  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    timer?.cancel();

    nameController.dispose();
    mobileController.dispose();
    otpController.dispose();
    secondaryPhoneController.dispose();
    otpFocusNode.dispose();
    stateSearchController.dispose();
    districtSearchController.dispose();

    _vehicleSubscription?.cancel();
    vehicleNameController.dispose();
    vehicleNumberController.dispose();

    customVehicleController.dispose();

    super.dispose();
  }

//         final TextEditingController nearestCityController =
//     TextEditingController();
// String stateError = '';
// String districtError = '';
// String nearestCityError = '';
//  bool isStateDropdownOpen = false;

// String? selectedState;

// final TextEditingController stateSearchController =
//     TextEditingController();

// List<String> filteredStates = [];

// static const List<String> indiaStates = [
//   'Andhra Pradesh',
//   'Arunachal Pradesh',
//   'Assam',
//   'Bihar',
//   'Chhattisgarh',
//   'Goa',
//   'Gujarat',
//   'Haryana',
//   'Himachal Pradesh',
//   'Jharkhand',
//   'Karnataka',
//   'Keralam',
//   'Madhya Pradesh',
//   'Maharashtra',
//   'Manipur',
//   'Meghalaya',
//   'Mizoram',
//   'Nagaland',
//   'Odisha',
//   'Punjab',
//   'Rajasthan',
//   'Sikkim',
//   'Tamil Nadu',
//   'Telangana',
//   'Tripura',
//   'Uttar Pradesh',
//   'Uttarakhand',
//   'West Bengal',
// ];

// void filterStates(String value) {
//   final String search = value.trim().toLowerCase();

//   final List<String> result = indiaStates.where((state) {
//     return search.isEmpty ||
//         state.toLowerCase().contains(search);
//   }).toList();

//   if (!mounted) return;

//   setState(() {
//     filteredStates = result;
//   });
// }

// String? selectedDistrict;

// bool isDistrictDropdownOpen = false;

// final TextEditingController districtSearchController =
//     TextEditingController();

// List<String> filteredDistricts = [];

// Map<String, List<String>> indiaDistricts = {};

// List<String> get availableDistricts {
//   if (selectedState == null ||
//       selectedState!.trim().isEmpty) {
//     return indiaDistricts.values
//         .expand((districts) => districts)
//         .toSet()
//         .toList();
//   }

//   return List<String>.from(
//     indiaDistricts[selectedState!] ?? [],
//   );
// }

// void filterDistricts(String value) {
//   final search = value.trim().toLowerCase();

//   final result = availableDistricts.where((district) {
//     return search.isEmpty ||
//         district.toLowerCase().contains(search);
//   }).toList();

//   if (!mounted) return;

//   setState(() {
//     filteredDistricts = result;
//   });
// }

// Future<void> loadDistricts() async {
//   final String jsonString = await rootBundle.loadString(
//     'assets/data/india_districts.json',
//   );

//   final Map<String, dynamic> data =
//       json.decode(jsonString);

//   if (!mounted) return;

//   setState(() {
//     indiaDistricts = data.map(
//       (key, value) => MapEntry(
//         key,
//         List<String>.from(value),
//       ),
//     );

//     filteredDistricts =
//         List<String>.from(availableDistricts);
//   });
// }
     void showMessage(
  String message, {
  bool isError = false,
}) {
  if (!mounted) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),

        backgroundColor: isError
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
    showMessage(AppLocalizations.of(context)!.enteradigitmobilenumber
      //'Enter a valid 10-digit mobile number.'
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
  // SAVE BASIC DATA OF TAXI TO HIVE
  // ============================================================

  Future<void> saveBasicUserToHive() async {
    try {
      final Box userBox =
          Hive.box('userBox');

      await userBox.put(
        'name',
        nameController.text.trim(),
      );

      await userBox.put(
        'mobile',
        mobileController.text.trim(),
      );

      await userBox.put(
  'secondaryMobile',
  secondaryPhoneController.text.trim(),
);

// ============================================================
// STATE, DISTRICT AND NEAREST CITY
// ============================================================

await userBox.put(
  'taxiCommercialState',
  selectedState!.trim(),
);

await userBox.put(
  'taxiCommercialDistrict',
  selectedDistrict!.trim(),
);

await userBox.put(
  'taxiCommercialNearestTown',
  nearestCityController.text.trim(),
);

      await userBox.put(
        'role',
        'taxi_commercial',
      );

      await userBox.put(
        'vehicleType',
        selectedType,
      );

      await userBox.put(
        'vehicle',
        selectedVehicle,
      );

      // OPTIONAL VEHICLE NAME / MODEL
      await userBox.put(
        'vehicleName',
        vehicleNameController.text.trim(),
      );

      // REQUIRED VEHICLE NUMBER
      await userBox.put(
        'vehicleNumber',
        vehicleNumberController.text
            .trim()
            .toUpperCase(),
      );

      await userBox.put(
  'profilePhotoUrl',
  profilePhotoUrl ?? '',
);

      await userBox.put(
        'gender',
        selectedGender,
      );

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user != null) {
        await userBox.put(
          'uid',
          user.uid,
        );
      }

      debugPrint(
        'Taxi/Commercial profile saved successfully.',
      );
    } catch (e) {
      debugPrint(
        'Hive save error: $e',
      );
    }
  }

  // ============================================================
  // SAVE PROFILE TO FIRESTORE
  // ============================================================

  Future<void> saveProfileToFirestore() async {
    final User? user =
        auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not authenticated.',
      );
    }

    await firestore
        .collection('taxi_commercial')
        .doc(user.uid)
        .set(
      {
        'uid': user.uid,

        'name':
            nameController.text.trim(),

        'mobile':
            mobileController.text.trim(),

       'secondaryMobile':
    secondaryPhoneController.text.trim(),

// ============================================================
// STATE, DISTRICT AND NEAREST CITY
// ============================================================

'state':
    selectedState!.trim(),

'district':
    selectedDistrict!.trim(),

'nearestTown':
    nearestCityController.text.trim(),

'gender':
    selectedGender,

        'vehicleType':
            selectedType,

        'vehicle':
            selectedVehicle,

        // OPTIONAL
        'vehicleName':
            vehicleNameController.text.trim(),

        // REQUIRED
        'vehicleNumber':
            vehicleNumberController.text
                .trim()
                .toUpperCase(),

        // 'profilePhotoUrl': profilePhotoUrl,

        // 'role': 'taxi_commercial',

        // 'isActive' : true,

        // 'updatedAt':
        //     FieldValue.serverTimestamp(),
        'role': 'taxi_commercial',

'isActive': true,

// Taxi is available online after registration.
'isOnline': true,
'onlineUpdatedAt': FieldValue.serverTimestamp(),

'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // SUBMIT PROFILE
  // ============================================================
  Future<void> submitProfile() async {
  if (isSubmitting) return;

  bool hasError = false;

  nameError = null;
      stateError = '';

 // mobileError = null;
  genderError = null;
  vehicleError = null;
  vehicleNumberError = null;

  if (nameController.text.trim().isEmpty) {
    nameError = 'Please enter your name';
    hasError = true;
  }

// ============================================================
// MOBILE
// ============================================================

final String mobile =
    mobileController.text.trim();

// Clear previous mobile error
mobileError = false;

if (mobile.isEmpty) {
  mobileError = true;
  hasError = true;
} else if (mobile.length != 10) {
  mobileError = true;
  hasError = true;
}

// ============================================================
// OTP VERIFICATION
// ============================================================

if (!otpVerified) {
  mobileError = true;
  hasError = true;
}
// if (!otpVerified) {
//     showMessage(
//       'Please verify your mobile number first.',
//       isError: true,
//     );
//     return;
//   }

// ============================================================
// SECONDARY MOBILE NUMBER
// ============================================================

final String secondaryMobile =
    secondaryPhoneController.text.trim();

if (secondaryMobile.isEmpty) {
  secondaryMobileError =
      'Please enter your secondary mobile number';
  hasError = true;
} else if (secondaryMobile.length != 10) {
  secondaryMobileError =
      'Please enter a valid 10-digit mobile number';
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
  // GENDER
  // ============================================================

  if (selectedGender == null) {
    genderError =
        'Please select your gender';
    hasError = true;
  }

  // ============================================================
  // VEHICLE
  // ============================================================

  if (selectedVehicle == null ||
      selectedVehicle!.trim().isEmpty) {
    vehicleError =
        'Please select a vehicle';
    hasError = true;
  }

// ============================================================
// TERMS & CONDITIONS / PRIVACY POLICY
// ============================================================

if (!privacyPolicyAccepted) {
  privacyPolicyError =
      'Please accept the Privacy Policy and Terms & Conditions.';
  hasError = true;
}

  // ============================================================
  // VEHICLE NUMBER
  // ============================================================

  final String vehicleNumber =
      vehicleNumberController.text.trim();

  if (vehicleNumber.isEmpty) {
    vehicleNumberError =
        'Please enter your vehicle number';
    hasError = true;
  }

  if (!mounted) return;

  setState(() {});

  
  if (hasError) {
    return;
  }
  final User? user = auth.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please verify OTP first.',
        ),
      ),
    );
    return;
  }



  if (!mounted) return;

  setState(() {
    isSubmitting = true;
  });

  try {
  
    vehicleNumberController.text =
        vehicleNumberController.text
            .trim()
            .toUpperCase();

     await saveBasicUserToHive();
    await CommonProfileService.saveLogin(
      uid: user.uid,
      name: nameController.text.trim(),
      mobile: mobile,
      role: 'taxi_commercial',
    );

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const ScreenHome(),
      ),
      (route) => false,
    );

    saveProfileToFirestore()
        .then((_) {
          debugPrint(
            'Taxi/Commercial Firestore sync successful.',
          );
        })
        .catchError((error) {
          debugPrint(
            'Taxi/Commercial Firestore sync failed: $error',
          );
        });

  } catch (e) {
    debugPrint(
      'Taxi/Commercial submit error: $e',
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not save profile locally: $e',
        ),
      ),
    );
  }
}

  // ==========================================================
// CHANGE TAXI / COMMERCIAL VEHICLE TYPE
// ==========================================================

void changeVehicleType(String type) {
  setState(() {
    selectedType = type;
    selectedVehicle = null;

    // Clear the previous type's categories.
    _loadedVehicles = [];

    vehicleNameController.clear();
    vehicleNumberController.clear();

    vehicleError = null;
    vehicleNumberError = null;
  });

  // Listen to categories for the newly selected type.
  _listenToVehicles();
}


  void selectVehicle(
    String vehicleName,
  ) {
    setState(() {
      selectedVehicle = vehicleName;

      vehicleError = null;
      //vehicleNumberError = null;
    });
  }

  // ============================================================
  // VIEW ALL VEHICLES
  // ============================================================

  Future<void> openAllVehicles() async {
    final result =
        await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AllVehiclesPage(
          vehicleType: selectedType,
          vehicles: currentVehicles,
          selectedVehicle:
              selectedVehicle,
        ),
      ),
    );

    if (!mounted) return;

    if (result != null &&
        result.trim().isNotEmpty) {
      setState(() {
        selectedVehicle = result.trim();

        vehicleError = null;
      });
    }
  }

  // ============================================================
  // ADD YOUR VEHICLE
  // ============================================================

Future<void> addYourVehicle() async {
  customVehicleController.clear();

  File? selectedVehiclePhoto;

  final Map<String, dynamic>? result =
      await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Add Your Vehicle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: customVehicleController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: selectedType == 'Taxi'
                          ? 'Example: Toyota Rumion'
                          : 'Example: BharatBenz',
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF16803C),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 130,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: selectedVehiclePhoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              selectedVehiclePhoto!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.broken_image_outlined,
                                  size: 45,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.directions_car_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final XFile? picked =
                            await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedVehiclePhoto = File(picked.path);
                          });
                        }
                      } catch (e) {
                        debugPrint(
                          'Vehicle photo selection error: $e',
                        );

                        if (!dialogContext.mounted) return;

                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not select the photo. Please try again.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      selectedVehiclePhoto == null
                          ? 'Choose Vehicle Photo (Optional)'
                          : 'Change Vehicle Photo',
                    ),
                  ),
                  if (selectedVehiclePhoto != null)
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          selectedVehiclePhoto = null;
                        });
                      },
                      child: const Text(
                        'Remove Photo',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final String name =
                      customVehicleController.text.trim();

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a vehicle name.'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    <String, dynamic>{
                      'name': name,
                      'photo': selectedVehiclePhoto,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16803C),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Vehicle'),
              ),
            ],
          );
        },
      );
    },
  );

  if (!mounted || result == null) return;

  final String vehicleName =
      (result['name'] as String? ?? '').trim();

  final File? photo = result['photo'] as File?;

  if (vehicleName.isEmpty) return;

  // Check for an existing category.
  final existing = await loadCustomTaxiCommercialCategories(
   selectedType,
  );

  final duplicate = existing.any(
    (item) => item.name.trim().toLowerCase() ==
        vehicleName.toLowerCase(),
  );

  if (duplicate) {
    showMessage('$vehicleName already exists.');
    return;
  }

  try {
    String imageUrl = '';

    // Upload only if the user selected a photo.
    if (photo != null) {
      final String extension =
          path.extension(photo.path).toLowerCase();

      final String contentType;

      switch (extension) {
        case '.png':
          contentType = 'image/png';
          break;
        case '.webp':
          contentType = 'image/webp';
          break;
        case '.jpg':
        case '.jpeg':
          contentType = 'image/jpeg';
          break;
        default:
          showMessage(
            'Choose a JPG, PNG, or WebP photo.',
            isError: true,
          );
          return;
      }

      showMessage('Uploading vehicle photo...');

      final ref = FirebaseStorage.instance
          .ref()
          .child('taxiVehicleCategories')
          .child(selectedType.toLowerCase())
          .child(
            '${DateTime.now().millisecondsSinceEpoch}$extension',
          );

      final snapshot = await ref.putFile(
        photo,
        SettableMetadata(contentType: contentType),
      );

      imageUrl = await snapshot.ref.getDownloadURL();
    }

    // Save the category using your existing helper.
    // No photo means imageUrl remains empty.
    // await saveCustomTaxiCommercialCategory(
    //   name: vehicleName,
    //   type: selectedType,
    //   uid: FirebaseAuth.instance.currentUser?.uid ?? 'local',
    //   imageUrl: imageUrl,
    // );
    await saveCustomTaxiCommercialCategory(
  name: vehicleName,
  type: selectedType,
  uid: FirebaseAuth.instance.currentUser?.uid ?? 'local',
  imageUrl: imageUrl,
);

   // await _loadVehicles(force: true);

  // Select the newly added category immediately.
if (!mounted) return;

setState(() {
  selectedVehicle = vehicleName;
  vehicleError = null;
  customVehicleController.clear();
});

// Refresh the selected vehicle type's categories.
_listenToVehicles();

// Show success message.
ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(
    SnackBar(
      content: Text('$vehicleName added and selected successfully.'),
      backgroundColor: const Color(0xFF16803C),
      behavior: SnackBarBehavior.floating,
    ),
  );
  } on FirebaseException catch (e) {
    debugPrint('ADD VEHICLE ERROR ${e.code}: ${e.message}');

    if (!mounted) return;

    showMessage(
      'Could not save the vehicle. Please check Firebase permissions.',
      isError: true,
    );
  } catch (e) {
    debugPrint('ADD VEHICLE ERROR: $e');

    if (!mounted) return;

    showMessage(
      'Could not add the vehicle. Please try again.',
      isError: true,
    );
  }
}

Future<void> deleteCustomTaxiCommercialCategory(
  String category,
) async {
  final String typeToDelete = selectedType;
  final String categoryName = category.trim();

  if (categoryName.isEmpty) return;

  // Never allow built-in vehicle categories to be deleted.
  final bool isBuiltIn = getPredefinedVehicleCategories(
    typeToDelete,
  ).any(
    (item) =>
        item.name.trim().toLowerCase() ==
        categoryName.toLowerCase(),
  );

  if (isBuiltIn) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Built-in vehicle categories cannot be deleted.',
        ),
      ),
    );
    return;
  }

  // Ask for confirmation.
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Delete vehicle category?'),
      content: Text(
        'Delete "$categoryName" from the $typeToDelete '
        'vehicle categories for everyone? '
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(false),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () =>
              Navigator.of(dialogContext).pop(true),
          child: const Text('DELETE'),
        ),
      ],
    ),
  );

  if (confirmed != true || !mounted) return;

  try {
    final firestore = FirebaseFirestore.instance;

    // Use the same document ID helper used when saving.
    final String documentId = taxiCommercialCategoryId(
      typeToDelete,
      categoryName,
    );

    final docRef = firestore
        .collection('taxi_vehicle_categories')
        .doc(documentId);

    // Verify that the document exists and is a custom category.
    final docSnapshot = await docRef.get();

    if (!mounted) return;

    if (!docSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This vehicle category no longer exists.',
          ),
        ),
      );

      // Refresh the current list from the listener.
      _listenToVehicles();
      return;
    }

    final data = docSnapshot.data();

    if (data == null ||
        data['isCustom'] != true ||
        data['vehicleType'] != typeToDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Only custom vehicle categories can be deleted.',
          ),
        ),
      );
      return;
    }

    // Delete the shared custom category from Firestore.
    await docRef.delete();

    if (!mounted) return;

    // Update the current screen immediately.
    setState(() {
      _loadedVehicles.removeWhere(
        (item) =>
            item['name']?.trim().toLowerCase() ==
            categoryName.toLowerCase(),
      );

      if (selectedVehicle?.trim().toLowerCase() ==
          categoryName.toLowerCase()) {
        selectedVehicle = null;
      }

      vehicleError = null;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '"$categoryName" deleted successfully.',
          ),
          backgroundColor: const Color(0xFF16803C),
          behavior: SnackBarBehavior.floating,
        ),
      );
  } on FirebaseException catch (e) {
    debugPrint(
      'DELETE VEHICLE CATEGORY ERROR '
      '${e.code}: ${e.message}',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not delete the category. Check your Firebase permissions.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('DELETE VEHICLE CATEGORY ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'An error occurred while deleting the category.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _saveTaxiCommercialLocation(
  TaxiCommercialLocation location,
) async {
  final User? user = auth.currentUser;

  if (user == null) {
    throw Exception(
      'Please log in before saving the parked location.',
    );
  }

  final Box userBox = Hive.box('userBox');

  // ==========================================================
  // SAVE TO HIVE
  // ==========================================================

  await userBox.put(
    'taxiCommercialParkedLocation',
    location.placeName,
  );

  await userBox.put(
    'taxiCommercialLatitude',
    location.latitude,
  );

  await userBox.put(
    'taxiCommercialLongitude',
    location.longitude,
  );

  // ==========================================================
  // SAVE TO FIRESTORE
  // Collection: taxi_commercial
  // Document ID: authenticated user's UID
  // ==========================================================

  await firestore
      .collection('taxi_commercial')
      .doc(user.uid)
      .set(
    {
      'uid': user.uid,
      'parkedLocation': location.placeName,
      'parkedLatitude': location.latitude,
      'parkedLongitude': location.longitude,
      'locationUpdatedAt':
          FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );

  debugPrint(
    'Taxi commercial parked location saved to Hive and Firestore.',
  );
}


  Widget locationSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Ambulance Parked Location',
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
                      'Add Ambulance Parked location',
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
                              : 'Use Ambulance Location',
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
    label: const Text('Enter or Paste Parked Location'),
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
  // onPressed: () {
  //   // Immediately invalidate any running location request.
  //   _locationRequestId++;

  //   // Immediately update the UI.
  //   setState(() {
  //     currentLocation = null;
  //     isGettingLocation = false;
  //     isSearchingLocation = false;
  //     locationError = false;
  //   });
  // },
  onPressed: () async {
  // Cancel any location request currently in progress.
  _locationRequestId++;

  if (!mounted) return;

  setState(() {
    currentLocation = null;
    isGettingLocation = false;
    isSearchingLocation = false;
    locationError = false;
  });

  try {
    await _removeTaxiCommercialLocation();

    if (!mounted) return;

    showMessage('Parked location removed.');
  } catch (e) {
    debugPrint('Remove parked location error: $e');

    if (!mounted) return;

    showMessage(
      'Could not remove the saved location.',
      isError: true,
    );
  }
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
            labelText: 'Ambulance Parked Location',
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
                  'Please enter or paste Parked location.',
                  isError: true,
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
    isError: true,
  );
  return;
}

// setState(() {
//   currentLocation = TaxiCommercialLocation(
//     placeName: placeName.trim(),
//     latitude: null,
//     longitude: null,
//   );
//   locationError = false;
//   isGettingLocation = false;
//   isSearchingLocation = false;
// });

// showMessage(
//   'Ambulance Parked location added.',
// );
final TaxiCommercialLocation location =
    TaxiCommercialLocation(
  placeName: placeName.trim(),
  latitude: null,
  longitude: null,
);

try {
  await _saveTaxiCommercialLocation(location);

  if (!mounted) return;

  setState(() {
    currentLocation = location;
    locationError = false;
    isGettingLocation = false;
    isSearchingLocation = false;
  });

  showMessage(
    'Parked location saved successfully.',
  );
} catch (e) {
  debugPrint(
    'Manual parked location save error: $e',
  );

  if (!mounted) return;

  showMessage(
    'Could not save parked location: $e',
    isError: true,
  );
}
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

  // ==========================================================
  // NORMAL TEXT
  // ==========================================================

  // if (!isGoogleMapsLink) {
  //   return value;
  // }
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
      isError: true,
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
        isError: true,
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
        isError: true,
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
        isError: true,
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
    isError: true,
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
        isError: true,
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

//     if (!mounted || requestId != _locationRequestId) return;

//     setState(() {
//   currentLocation = TaxiCommercialLocation(
//     placeName: placeName,
//     latitude: position.latitude,
//     longitude: position.longitude,
//   );

//   locationError = false;
// });

//     showMessage(
//       'Ambulance location added.',
//     );
// ----------------------------------------------------------
    // SAVE LOCATION TO HIVE AND FIRESTORE
    // ----------------------------------------------------------

    if (!mounted || requestId != _locationRequestId) {
      return;
    }

    final TaxiCommercialLocation location =
        TaxiCommercialLocation(
      placeName: placeName,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    await _saveTaxiCommercialLocation(location);

    if (!mounted || requestId != _locationRequestId) {
      return;
    }

    setState(() {
      currentLocation = location;
      locationError = false;
    });

    showMessage(
      'Parked location saved successfully.',
    );
  } catch (e) {
    if (!mounted || requestId != _locationRequestId) return;

    showMessage(
      'Unable to get your location.',
      isError: true,
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

Future<void> _removeTaxiCommercialLocation() async {
  final User? user = auth.currentUser;
  final Box userBox = Hive.box('userBox');

  // Remove the local values.
  await userBox.delete('taxiCommercialParkedLocation');
  await userBox.delete('taxiCommercialLatitude');
  await userBox.delete('taxiCommercialLongitude');

  // Remove the Firestore values.
  if (user != null) {
    await firestore
        .collection('taxi_commercial')
        .doc(user.uid)
        .set(
      {
        'parkedLocation': FieldValue.delete(),
        'parkedLatitude': FieldValue.delete(),
        'parkedLongitude': FieldValue.delete(),
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
            size: 26,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        titleSpacing: 0,

        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Driver',
                style: TextStyle(
                  color: Color(0xFF08744F),
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text:  AppLocalizations.of(context)!.registration,
                //' Registration',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            28,
            10,
            28,
            35,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Text(
                'Fill in your details to create your driver profile',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              // =================================================
              // NAME
              // =================================================

              _sectionTitle('Name'),

              const SizedBox(height: 8),

              _nameField(),

              const SizedBox(height: 20),

              // =================================================
              // GENDER
              // =================================================

              _sectionTitle('Gender'),

              const SizedBox(height: 8),

              _genderSection(),

              const SizedBox(height: 20),

              // =================================================
              // MOBILE
              // =================================================

              sectionTitle('Mobile Number'),
              const SizedBox(height: 6),

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

                    child: Text(AppLocalizations.of(context)!.enteradigitmobilenumber,
                    //  'Enter a valid 10-digit number',

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

              const SizedBox(height: 20),

              secondaryMobileSection(),

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
              // DRIVER TYPE
              // =================================================

              _sectionTitle(
                'I want to join as',
              ),

              const SizedBox(height: 8),

              _driverTypeSection(),

              const SizedBox(height: 20),

              // =================================================
              // VEHICLE CATEGORY
              // =================================================

              _sectionTitle(
                'Select Vehicle',
              ),

              const SizedBox(height: 8),

              _vehicleSection(),

              // =================================================
              // IMPORTANT:
              // These fields ONLY appear after a vehicle
              // category has been selected.
              // =================================================

              if (selectedVehicle != null) ...[
                const SizedBox(height: 22),

                // -----------------------------------------------
                // OPTIONAL VEHICLE NAME
                // -----------------------------------------------

                _sectionTitle(
                  'Vehicle Name / Model',
                ),

                const SizedBox(height: 8),

                _vehicleNameField(),

                const SizedBox(height: 20),

                // -----------------------------------------------
                // REQUIRED VEHICLE NUMBER
                // -----------------------------------------------

                _sectionTitle(
                  'Vehicle Number *',
                ),

                const SizedBox(height: 8),

                _vehicleNumberField(),
              ],
              const SizedBox(height: 20),
// =================================================
// CURRENT LOCATION
// =================================================

locationSection(),

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
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
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
  // NAME FIELD
  // ============================================================

  Widget _nameField() {
    final bool hasError =
        nameError != null &&
        nameError!.isNotEmpty;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Container(
          decoration: BoxDecoration(
            color:
                const Color(0xFFF9F9F9),

            borderRadius:
                BorderRadius.circular(20),

            border: Border.all(
              color: hasError
                  ? Colors.red
                  : Colors.grey.shade300,

              width:
                  hasError ? 2 : 1,
            ),
          ),

          child: TextField(
            controller:
                nameController,

            onChanged: (_) {
              if (nameError != null) {
                setState(() {
                  nameError = null;
                });
              }
            },

            textCapitalization:
                TextCapitalization.words,

            decoration:
                const InputDecoration(
              hintText:
                  'Enter your name',

              prefixIcon: Icon(
                Icons.person_outline,
                color:
                    Color(0xFF16803C),
                size: 27,
              ),

              border:
                  InputBorder.none,

              contentPadding:
                  EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
            ),
          ),
        ),

        if (hasError)
          Padding(
            padding:
                const EdgeInsets.only(
              left: 8,
              top: 5,
            ),

            child: Text(
              nameError!,
              style:
                  const TextStyle(
                color: Colors.red,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // GENDER SECTION
  // ============================================================

  Widget _genderSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            Expanded(
              child: _genderButton(
                title: 'Male',
                value: 'Male',
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _genderButton(
                title: 'Female',
                value: 'Female',
              ),
            ),
          ],
        ),

        if (genderError != null)
          Padding(
            padding:
                const EdgeInsets.only(
              left: 8,
              top: 6,
            ),

            child: Text(
              genderError!,
              style:
                  const TextStyle(
                color: Colors.red,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // GENDER BUTTON
  // ============================================================

  Widget _genderButton({
    required String title,
    required String value,
  }) {
    final bool selected =
        selectedGender == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = value;
          genderError = null;
        });
      },

      child: Container(
        height: 58,

        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEFF8EF)
              : const Color(0xFFF8F9FA),

          borderRadius:
              BorderRadius.circular(16),

          border: Border.all(
            color: selected
                ? const Color(0xFF159B16)
                : genderError != null
                    ? Colors.red
                    : Colors.grey.shade300,

            width:
                selected ||
                        genderError != null
                    ? 2
                    : 1,
          ),
        ),

        alignment: Alignment.center,

        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,

            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.w500,

            color: selected
                ? const Color(0xFF159B16)
                : const Color(0xFF202124),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE SECTION
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
    child: Text(AppLocalizations.of(context)!.enteradigitmobilenumber,
     // 'Enter a valid 10-digit mobile number.',
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

Widget secondaryMobileSection() {
  final bool hasError =
      secondaryMobileError != null &&
      secondaryMobileError!.isNotEmpty;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Secondary Mobile Number *',
        style: TextStyle(
          color: Color(0xFF252525),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 8),

      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasError
                ? Colors.red
                : Colors.grey.shade300,
            width: hasError ? 2 : 1.5,
          ),
        ),

        child: TextField(
          controller: secondaryPhoneController,

          keyboardType: TextInputType.phone,

          maxLength: 10,

          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],

          onChanged: (value) {
            if (secondaryMobileError != null) {
              setState(() {
                secondaryMobileError = null;
              });
            }
          },

          decoration: const InputDecoration(
            hintText:
                'Enter secondary mobile number',

            prefixIcon: Icon(
              Icons.phone_android_outlined,
              color: Color(0xFF16803C),
              size: 26,
            ),

            counterText: '',

            border: InputBorder.none,

            contentPadding: EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
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
            secondaryMobileError!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 13,
            ),
          ),
        ),

      const SizedBox(height: 5),

      const Text(
        'You can add the same number if another number is not available.',
        style: TextStyle(
          color: Color(0xFF777777),
          fontSize: 12,
        ),
      ),

      const Text(
        'Note: This number will be shown to users when they choose to call you.',
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
  // DRIVER TYPE SECTION
  // ============================================================

  Widget _driverTypeSection() {
    return Row(
      children: [
        Expanded(
          child:
              _driverTypeButton(
            title: 'Taxi',
            value: 'Taxi',
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child:
              _driverTypeButton(
            title: 'Commercial',
            value: 'Commercial',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DRIVER TYPE BUTTON
  // ============================================================

  Widget _driverTypeButton({
    required String title,
    required String value,
  }) {
    final bool selected =
        selectedType == value;

    return GestureDetector(
      onTap: () {
        changeVehicleType(value);
      },

      child: Container(
        height: 58,

        decoration:
            BoxDecoration(
          color: selected
              ? const Color(
                  0xFFEFF8EF,
                )
              : const Color(
                  0xFFF8F9FA,
                ),

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          border: Border.all(
            color: selected
                ? const Color(
                    0xFF159B16,
                  )
                : Colors.grey.shade300,

            width:
                selected ? 2 : 1,
          ),
        ),

        alignment:
            Alignment.center,

        child: Text(
          title,

          style: TextStyle(
            fontSize: 16,

            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.w500,

            color: selected
                ? const Color(
                    0xFF159B16,
                  )
                : const Color(
                    0xFF202124,
                  ),
          ),
        ),
      ),
    );
  }

  // ============================================================
//   // VEHICLE SECTION
//   // ============================================================
// ==========================================================
// REAL-TIME TAXI / COMMERCIAL VEHICLE CATEGORIES
// ==========================================================

void _listenToVehicles() {
  // Stop listening to the previously selected vehicle type.
  _vehicleSubscription?.cancel();

  final String typeToLoad = selectedType;

  _vehicleSubscription = FirebaseFirestore.instance
      .collection('taxi_vehicle_categories')
      .where('vehicleType', isEqualTo: typeToLoad)
      .snapshots()
      .listen(
    (snapshot) {
      if (!mounted || typeToLoad != selectedType) return;

      // Load custom vehicles directly from the latest snapshot.
      final List<Map<String, String>> customVehicles = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final String name =
            (data['name'] ?? '').toString().trim();

        if (name.isEmpty) continue;

        customVehicles.add({
          'name': name,
          'image': '',
          'imageUrl': (data['imageUrl'] ?? '').toString(),
          'isCustom': 'true',
        });
      }

      // Remove duplicate custom vehicle names.
      final Set<String> seenNames = {};

      final List<Map<String, String>> uniqueCustomVehicles =
          customVehicles.where((vehicle) {
        return seenNames.add(
          (vehicle['name'] ?? '').trim().toLowerCase(),
        );
      }).toList();

      // Load the built-in categories for the selected type.
      final predefinedVehicles =
          getPredefinedVehicleCategories(typeToLoad).map(
        (vehicle) => <String, String>{
          'name': vehicle.name,
          'image': vehicle.image,
          'imageUrl': vehicle.imageUrl,
          'isCustom': 'false',
        },
      );

      // Put custom vehicles first so the newest additions
      // can appear in the first four grid cards.
      final List<Map<String, String>> allVehicles = [
        ...uniqueCustomVehicles,
      ];

      for (final vehicle in predefinedVehicles) {
        final String name =
            (vehicle['name'] ?? '').trim().toLowerCase();

        if (seenNames.add(name)) {
          allVehicles.add(vehicle);
        }
      }

      // Update the registration screen immediately.
      setState(() {
        _loadedVehicles = allVehicles;
      });
    },
    onError: (Object error, StackTrace stackTrace) {
      debugPrint(
        'Vehicle category listener error: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}
  
  Widget _vehicleSection() {
    final List<Map<String, String>>
        vehicles = currentVehicles;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        // ======================================================
        // VEHICLE GRID
        // ======================================================

        GridView.builder(
          shrinkWrap: true,

          physics:
              const NeverScrollableScrollPhysics(),

          itemCount:
              vehicles.length > 4
                  ? 4
                  : vehicles.length,

          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,

            crossAxisSpacing: 12,

            mainAxisSpacing: 12,

            childAspectRatio: 1.12,
          ),

          itemBuilder:
              (context, index) {
            final vehicle =
                vehicles[index];

          final bool isCustom = vehicle['isCustom'] == 'true';

return Stack(
  children: [
    Positioned.fill(
      child: _vehicleCard(
        name: vehicle['name'] ?? '',
        image: vehicle['image'] ?? '',
        imageUrl: vehicle['imageUrl'] ?? '',
      ),
    ),

    // Show delete only for custom vehicle categories.
    if (isCustom)
      Positioned(
        top: 5,
        right: 5,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 2,
          child: IconButton(
            tooltip: 'Delete vehicle category',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 21,
            ),
            onPressed: () {
              deleteCustomTaxiCommercialCategory(
                vehicle['name'] ?? '',
              );
            },
          ),
        ),
      ),
  ],
);
          },
        ),

        const SizedBox(height: 14),

        // ======================================================
        // VIEW ALL
        // ======================================================

        if (vehicles.length > 4)
          SizedBox(
            width: double.infinity,
            height: 48,

            child: OutlinedButton(
              onPressed:
                  openAllVehicles,

              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(
                  0xFF159B16,
                ),

                side:
                    const BorderSide(
                  color:
                      Color(0xFF159B16),
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
              ),

              child: const Text(
                'View All Vehicles',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // ======================================================
        // ADD YOUR VEHICLE
        // ======================================================

        SizedBox(
          width: double.infinity,
          height: 48,

          child:
              OutlinedButton.icon(
            onPressed:
                addYourVehicle,

            icon: const Icon(
              Icons.add,
              size: 20,
            ),

            label: const Text(
              'Add Your Vehicle',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 15,
              ),
            ),

            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  const Color(
                0xFFE87516,
              ),

              side:
                  const BorderSide(
                color:
                    Color(0xFFE87516),
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
              ),
            ),
          ),
        ),

        // ======================================================
        // SELECTED VEHICLE
        // ======================================================

        if (selectedVehicle !=
            null) ...[
          const SizedBox(height: 14),

          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.all(
              14,
            ),

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF1FAF3,
              ),

              borderRadius:
                  BorderRadius.circular(
                16,
              ),

              border:
                  Border.all(
                color:
                    const Color(
                  0xFF159B16,
                ),

                width: 1.4,
              ),
            ),

            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color:
                      Color(
                    0xFF159B16,
                  ),
                  size: 25,
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Text(
                    selectedVehicle!,

                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(
                        0xFF202124,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (vehicleError !=
                null &&
            vehicleError!
                .isNotEmpty) ...[
          const SizedBox(height: 5),

          Padding(
            padding:
                const EdgeInsets.only(
              left: 8,
            ),

            child: Text(
              vehicleError!,

              style:
                  const TextStyle(
                color: Colors.red,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }
Widget buildVehicleImage({
  required String image,
  required String imageUrl,
}) {
  if (imageUrl.trim().isNotEmpty) {
    return Image.network(
      imageUrl,
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _defaultVehicleIcon();
      },
    );
  }

  if (image.trim().isNotEmpty) {
    return Image.asset(
      image,
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _defaultVehicleIcon();
      },
    );
  }

  return _defaultVehicleIcon();
}

Widget _defaultVehicleIcon() {
  return const Center(
    child: Icon(
      Icons.directions_car_outlined,
      size: 45,
      color: Colors.grey,
    ),
  );
}
  // ============================================================
  // VEHICLE CARD
  // ============================================================

Widget _vehicleCard({
  required String name,
  required String image,
  required String imageUrl,
}) {
  // Check whether this vehicle is selected.
  final bool selected = selectedVehicle == name;

  final bool hasError =
      vehicleError != null && vehicleError!.isNotEmpty;

  return GestureDetector(
    onTap: () {
      selectVehicle(name);
    },
    child: Container(
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFEFF8EF)
            : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? const Color(0xFF159B16)
              : hasError
                  ? Colors.red
                  : Colors.grey.shade300,
          width: selected || hasError ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: buildVehicleImage(
                image: image,
                imageUrl: imageUrl,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 9,
            ),
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.w600,
                color: selected
                    ? const Color(0xFF159B16)
                    : const Color(0xFF202124),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // ============================================================
  // OPTIONAL VEHICLE NAME / MODEL
  // ============================================================

  Widget _vehicleNameField() {
    return Container(
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF9F9F9),

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border:
            Border.all(
          color:
              Colors.grey.shade300,
        ),
      ),

      child: TextField(
        controller:
            vehicleNameController,

        textCapitalization:
            TextCapitalization.words,

        decoration:
            const InputDecoration(
          hintText:
              'Enter vehicle name or model (optional)',

          prefixIcon:
              Icon(
            Icons.directions_car_outlined,
            color:
                Color(0xFF16803C),
            size: 27,
          ),

          border:
              InputBorder.none,

          contentPadding:
              EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REQUIRED VEHICLE NUMBER
  // ============================================================

  Widget _vehicleNumberField() {
    final bool hasError =
        vehicleNumberError !=
                null &&
            vehicleNumberError!
                .isNotEmpty;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Container(
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

            border:
                Border.all(
              color: hasError
                  ? Colors.red
                  : Colors.grey
                      .shade300,

              width:
                  hasError ? 2 : 1,
            ),
          ),

          child: TextField(
            controller:
                vehicleNumberController,

            keyboardType:
                TextInputType
                    .text,

            textCapitalization:
                TextCapitalization
                    .characters,

            inputFormatters: [
              FilteringTextInputFormatter
                  .allow(
                RegExp(
                  r'[A-Za-z0-9 ]',
                ),
              ),

              UpperCaseTextFormatter(),
            ],

            onChanged: (value) {
              if (vehicleNumberError !=
                  null) {
                setState(() {
                  vehicleNumberError =
                      null;
                });
              }
            },

            decoration:
                const InputDecoration(
              hintText:
                  'Enter vehicle number',

              prefixIcon:
                  Icon(
                Icons
                    .confirmation_number_outlined,
                color:
                    Color(
                  0xFF16803C,
                ),
                size: 27,
              ),

              border:
                  InputBorder.none,

              contentPadding:
                  EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
            ),
          ),
        ),

        if (hasError)
          Padding(
            padding:
                const EdgeInsets.only(
              left: 8,
              top: 5,
            ),

            child: Text(
              vehicleNumberError!,

              style:
                  const TextStyle(
                color: Colors.red,
                fontSize: 13,
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

      height: 58,

      child: ElevatedButton(
        onPressed:
            isSubmitting
                ? null
                : submitProfile,

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              const Color(
            0xFF159B16,
          ),

          disabledBackgroundColor:
              const Color(
            0xFF159B16,
          ),

          foregroundColor:
              Colors.white,

          elevation: 0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              30,
            ),
          ),
        ),

        child: isSubmitting
            ? const SizedBox(
                width: 25,
                height: 25,

                child:
                    CircularProgressIndicator(
                  strokeWidth:
                      2.5,
                  color:
                      Colors.white,
                ),
              )
            : const Text(
                'Submit Profile',

                style:
                    TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Colors.white,
                ),
              ),
      ),
    );
  }
}

// ============================================================
// UPPERCASE VEHICLE NUMBER FORMATTER
// ============================================================

class UpperCaseTextFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection:
          newValue.selection,
      composing:
          TextRange.empty,
    );
  }
}
class AllVehiclesPage
    extends StatefulWidget {
  final String vehicleType;

  final List<Map<String, String>>
      vehicles;

  final String? selectedVehicle;

  const AllVehiclesPage({
    super.key,

    required this.vehicleType,

    required this.vehicles,

    this.selectedVehicle,
  });

  @override
  State<AllVehiclesPage> createState() =>
      _AllVehiclesPageState();
}

class _AllVehiclesPageState
    extends State<AllVehiclesPage> {
  final TextEditingController
      searchController =
      TextEditingController();

  String searchText = '';

  @override
  void dispose() {
    searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // FILTER VEHICLES
  // ============================================================

  List<Map<String, String>>
      get filteredVehicles {
    if (searchText
        .trim()
        .isEmpty) {
      return widget.vehicles;
    }

    final query =
        searchText
            .trim()
            .toLowerCase();

    return widget.vehicles
        .where(
          (vehicle) {
            final name =
                vehicle['name']
                        ?.toLowerCase() ??
                    '';

            return name.contains(
              query,
            );
          },
        )
        .toList();
  }

  // ============================================================
  // SELECT VEHICLE
  // ============================================================

  void selectVehicle(
    String vehicle,
  ) {
    Navigator.pop(
      context,
      vehicle,
    );
  }

  // ============================================================
  // ADD CUSTOM VEHICLE
  // ============================================================

  Future<void>
      addCustomVehicle() async {
    final TextEditingController
        controller =
        TextEditingController();

    final result =
        await showDialog<String>(
      context: context,

      builder:
          (dialogContext) {
        return AlertDialog(
          backgroundColor:
              Colors.white,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),

          title: const Text(
            'Add Your Vehicle',

            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          content: TextField(
            controller:
                controller,

            textCapitalization:
                TextCapitalization
                    .words,

            decoration:
                InputDecoration(
              hintText:
                  widget.vehicleType ==
                          'Taxi'
                      ? 'Example: Toyota Rumion'
                      : 'Example: BharatBenz',

              filled: true,

              fillColor:
                  const Color(
                0xFFF9F9F9,
              ),

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),

              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),

                borderSide:
                    const BorderSide(
                  color:
                      Color(
                    0xFF159B16,
                  ),

                  width: 2,
                ),
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

              child:
                  const Text(
                'Cancel',

                style:
                    TextStyle(
                  color:
                      Colors.grey,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                final value =
                    controller.text
                        .trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF159B16,
                ),

                foregroundColor:
                    Colors.white,

                elevation: 0,
              ),

              child:
                  const Text(
                'Add Vehicle',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted) return;

    if (result != null &&
        result
            .trim()
            .isNotEmpty) {
      Navigator.pop(
        context,
        result.trim(),
      );
    }
  }

//   Widget buildVehicleImage({
//   required String image,
//   required String imageUrl,
// }) {
//   if (imageUrl.trim().isNotEmpty) {
//     return Image.network(
//       imageUrl,
//       width: double.infinity,
//       fit: BoxFit.cover,
//       errorBuilder: (_, _, _) {
//         return const Center(
//           child: Icon(
//             Icons.directions_car_outlined,
//             size: 45,
//             color: Colors.grey,
//           ),
//         );
//       },
//     );
//   }

//   if (image.trim().isNotEmpty) {
//     return Image.asset(
//       image,
//       width: double.infinity,
//       fit: BoxFit.cover,
//     //  errorBuilder : (_, _, _) {
//     //     return const Center(
//     //       child: Icon(
//     //         Icons.directions_car_outlined,
//     //         size: 45,
//     //         color: Colors.grey,
//     //       ),
//     //     );
//      // },
//      errorBuilder: (context, error, stackTrace) {
//   return const Center(
//           child: Icon(
//             Icons.directions_car_outlined,
//             size: 45,
//             color: Colors.grey,
//           ),
//         );
// },
//     );
// }
// }
Widget buildVehicleImage({
  required String image,
  required String imageUrl,
}) {
  // 1. Display uploaded vehicle photo from Firebase Storage.
  if (imageUrl.trim().isNotEmpty) {
    return Image.network(
      imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _defaultVehicleIcon();
      },
    );
  }

  // 2. Display predefined vehicle asset image.
  if (image.trim().isNotEmpty) {
    return Image.asset(
      image,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _defaultVehicleIcon();
      },
    );
  }

  // 3. Display a default icon if no image exists.
  return _defaultVehicleIcon();
}

Widget _defaultVehicleIcon() {
  return const Center(
    child: Icon(
      Icons.directions_car_outlined,
      size: 45,
      color: Colors.grey,
    ),
  );
}

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final vehicles =
        filteredVehicles;

    return Scaffold(
      backgroundColor:
          Colors.white,

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.white,

        elevation: 0,

        leading:
            IconButton(
          icon:
              const Icon(
            Icons.arrow_back,
            color:
                Colors.black87,
          ),

          onPressed: () {
            Navigator.pop(
              context,
            );
          },
        ),

        titleSpacing: 0,

        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Choose ',

                style:
                    TextStyle(
                  color:
                      Color(
                    0xFF08744F,
                  ),

                  fontSize: 23,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              TextSpan(
                text:
                    widget.vehicleType,

                style:
                    const TextStyle(
                  color:
                      Color(
                    0xFFE87516,
                  ),

                  fontSize: 23,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets
                  .fromLTRB(
            20,
            10,
            20,
            20,
          ),

          child: Column(
            children: [
              const Align(
                alignment:
                    Alignment.centerLeft,

                child: Text(
                  'Select your vehicle',
                  style: TextStyle(
                    color:
                        Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // =================================================
              // SEARCH
              // =================================================

              Container(
                height: 58,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF9F9F9,
                  ),

                  borderRadius:
                      BorderRadius
                          .circular(
                    18,
                  ),

                  border:
                      Border.all(
                    color: Colors
                        .grey
                        .shade300,
                  ),
                ),

                child: TextField(
                  controller:
                      searchController,

                  onChanged:
                      (value) {
                    setState(() {
                      searchText =
                          value;
                    });
                  },

                  decoration:
                      InputDecoration(
                    hintText:
                        'Search vehicle',

                    prefixIcon:
                        const Icon(
                      Icons.search,

                      color:
                          Color(
                        0xFF16803C,
                      ),
                    ),

                    suffixIcon:
                        searchText
                                .isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(
                                  Icons.clear,
                                ),

                                onPressed:
                                    () {
                                  searchController
                                      .clear();

                                  setState(
                                    () {
                                      searchText =
                                          '';
                                    },
                                  );
                                },
                              )
                            : null,

                    border:
                        InputBorder.none,

                    contentPadding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 17,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // =================================================
              // VEHICLES
              // =================================================

              Expanded(
                child: vehicles
                        .isEmpty
                    ? const Center(
                        child: Text(
                          'No vehicle found',

                          style:
                              TextStyle(
                            fontSize:
                                17,
                            color:
                                Colors.grey,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      )
                    : GridView
                        .builder(
                        padding:
                            const EdgeInsets
                                .only(
                          bottom: 15,
                        ),

                        itemCount:
                            vehicles
                                .length,

                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              2,

                          crossAxisSpacing:
                              12,

                          mainAxisSpacing:
                              12,

                          childAspectRatio:
                              1.05,
                        ),

                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          final vehicle =
                              vehicles[
                                  index];

                          final name =
                              vehicle[
                                      'name'] ??
                                  '';

                        final image = vehicle['image'] ?? '';
final imageUrl = vehicle['imageUrl'] ?? '';

                          final selected =
                              widget.selectedVehicle ==
                                  name;

                          return GestureDetector(
                            onTap:
                                () {
                              selectVehicle(
                                name,
                              );
                            },

                            child:
                                Container(
                              decoration:
                                  BoxDecoration(
                                color:
                                    selected
                                        ? const Color(
                                            0xFFEFF8EF,
                                          )
                                        : const Color(
                                            0xFFF9F9F9,
                                          ),

                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),

                                border:
                                    Border.all(
                                  color: selected
                                      ? const Color(
                                          0xFF159B16,
                                        )
                                      : Colors
                                          .grey
                                          .shade300,

                                  width:
                                      selected
                                          ? 2
                                          : 1,
                                ),
                              ),

                              child:
                                  Column(
                                children: [
                                  Expanded(
                                    child:
                                        ClipRRect(
                                      borderRadius:
                                          const BorderRadius.vertical(
                                        top:
                                            Radius.circular(
                                          15,
                                        ),
                                      ),

                                      // child:
                                      //     Image.asset(
                                      //   image,

                                      //   width:
                                      //       double.infinity,

                                      //   fit:
                                      //       BoxFit.cover,

                                      //   errorBuilder:
                                      //       (
                                      //     context,
                                      //     error,
                                      //     stackTrace,
                                      //   ) {
                                      //     return const Center(
                                      //       child:
                                      //           Icon(
                                      //         Icons
                                      //             .directions_car_outlined,

                                      //         size:
                                      //             45,

                                      //         color:
                                      //             Colors.grey,
                                      //       ),
                                      //     );
                                      //   },
                                      // ),
                                      child: buildVehicleImage(
  image: image,
  imageUrl: imageUrl,
),
                                    ),
                                  ),

                                  Padding(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal:
                                          8,

                                      vertical:
                                          10,
                                    ),

                                    child:
                                        Text(
                                      name,

                                      maxLines:
                                          1,

                                      overflow:
                                          TextOverflow
                                              .ellipsis,

                                      textAlign:
                                          TextAlign
                                              .center,

                                      style:
                                          TextStyle(
                                        fontSize:
                                            14,

                                        fontWeight:
                                            FontWeight
                                                .bold,

                                        color:
                                            selected
                                                ? const Color(
                                                    0xFF159B16,
                                                  )
                                                : const Color(
                                                    0xFF202124,
                                                  ),
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

              const SizedBox(
                height: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}



  //  InputDecoration fieldDecoration({
  //   required String hint,
  //   IconData? icon,
  // }) {
  //   return InputDecoration(
  //     hintText: hint,

  //     prefixIcon: icon == null
  //         ? null
  //         : Icon(
  //             icon,
  //             color:
  //                 const Color(0xFF16803C),
  //             size: 26,
  //           ),

  //     filled: true,

  //     fillColor:
  //         const Color(0xFFF9F9F9),

  //     contentPadding:
  //         const EdgeInsets.symmetric(
  //       horizontal: 18,
  //       vertical: 18,
  //     ),

  //     hintStyle:
  //         const TextStyle(
  //       color:
  //           Color(0xFF777777),
  //       fontSize: 16,
  //     ),

  //     enabledBorder:
  //         OutlineInputBorder(
  //       borderRadius:
  //           BorderRadius.circular(20),
  //       borderSide:
  //           const BorderSide(
  //         color:
  //             Color(0xFFD5D5D5),
  //         width: 1.5,
  //       ),
  //     ),

  //     focusedBorder:
  //         OutlineInputBorder(
  //       borderRadius:
  //           BorderRadius.circular(20),
  //       borderSide:
  //           const BorderSide(
  //         color:
  //             Color(0xFF16803C),
  //         width: 2,
  //       ),
  //     ),

  //     errorBorder:
  //         OutlineInputBorder(
  //       borderRadius:
  //           BorderRadius.circular(20),
  //       borderSide:
  //           const BorderSide(
  //         color: Colors.red,
  //         width: 2,
  //       ),
  //     ),

  //     focusedErrorBorder:
  //         OutlineInputBorder(
  //       borderRadius:
  //           BorderRadius.circular(20),
  //       borderSide:
  //           const BorderSide(
  //         color: Colors.red,
  //         width: 2,
  //       ),
  //     ),

  //     errorStyle:
  //         const TextStyle(
  //       color: Colors.red,
  //       fontSize: 12,
  //       fontWeight:
  //           FontWeight.w500,
  //     ),
  //   );
  // }

//   Widget secondaryMobileSection() {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       const Text(
//         'Secondary Mobile Number',
//         style: TextStyle(
//           color: Color(0xFF252525),
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//         ),
//       ),

//       const SizedBox(height: 8),

//       TextFormField(
//         controller: secondaryPhoneController,
//         keyboardType: TextInputType.phone,
//         maxLength: 10,

//         inputFormatters: [
//           FilteringTextInputFormatter.digitsOnly,
//         ],
// onChanged: (value) {
//   if (secondaryMobileError != null) {
//     setState(() {
//       secondaryMobileError = null;
//     });
//   }
// },
//         decoration: InputDecoration(
//           hintText: 'Enter secondary mobile number (optional)',
//           icon: Icon(Icons.phone_android_outlined),
//         ).copyWith(
//           counterText: '',
//         ),

//         validator: (value) {
//           final number = value?.trim() ?? '';

//           // Optional field.
//           if (number.isEmpty) {
//             return null;
//           }

//           if (number.length != 10) {
//             return 'Enter a valid 10-digit mobile number';
//           }

//           return null;
//         },
//       ),

//       const SizedBox(height: 5),

//       const Text(
//         'You can add same number,if another number is not available.',
//         style: TextStyle(
//           color: Color(0xFF777777),
//           fontSize: 12,
//         ),
//       ),
//       const  Text(
//         'Note : This number will be shown to users when they choose to call you.',
//         style: TextStyle(
//           color: Color(0xFF777777),
//           fontSize: 12,
//         ),
//       ),
//     ],
//   );
// }

//  Future<void> addYourVehicle() async {
//   customVehicleController.clear();

//   final result = await showDialog<String>(
//     context: context,
//     builder: (dialogContext) {
//       return AlertDialog(
//         backgroundColor: Colors.white,

//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),

//         title: const Text(
//           'Add Your Vehicle',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//           ),
//         ),

//         content: TextField(
//           controller: customVehicleController,

//           textCapitalization:
//               TextCapitalization.words,

//           decoration: InputDecoration(
//             hintText: selectedType == 'Taxi'
//                 ? 'Example: Toyota Rumion'
//                 : 'Example: BharatBenz',

//             filled: true,

//             fillColor:
//                 const Color(0xFFF9F9F9),

//             border: OutlineInputBorder(
//               borderRadius:
//                   BorderRadius.circular(16),
//             ),

//             focusedBorder: OutlineInputBorder(
//               borderRadius:
//                   BorderRadius.circular(16),

//               borderSide: const BorderSide(
//                 color: Color(0xFF159B16),
//                 width: 2,
//               ),
//             ),
//           ),
//         ),

//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(dialogContext);
//             },

//             child: const Text(
//               'Cancel',
//               style: TextStyle(
//                 color: Colors.grey,
//               ),
//             ),
//           ),

//           ElevatedButton(
//             onPressed: () {
//               final vehicle =
//                   customVehicleController
//                       .text
//                       .trim();

//               if (vehicle.isEmpty) {
//                 return;
//               }

//               Navigator.pop(
//                 dialogContext,
//                 vehicle,
//               );
//             },

//             style: ElevatedButton.styleFrom(
//               backgroundColor:
//                   const Color(0xFF16803C),
//               foregroundColor:
//                   Colors.white,
//             ),

//             child: const Text(
//               'Add Vehicle',
//             ),
//           ),
//         ],
//       );
//     },
//   );

//   // ==========================================================
//   // USER CANCELLED
//   // ==========================================================

//   if (!mounted || result == null) {
//     return;
//   }

//   final String vehicleName =
//       result.trim();

//   if (vehicleName.isEmpty) {
//     return;
//   }

//   // ==========================================================
//   // CURRENT FIREBASE USER
//   // ==========================================================

//   final user =
//       FirebaseAuth.instance.currentUser;

//   if (user == null) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(
//           'Please verify your phone number first.',
//         ),
//       ),
//     );

//     return;
//   }

//   // ==========================================================
//   // SAVE CUSTOM CATEGORY TO FIRESTORE
//   // ==========================================================

//   try {
//     await saveCustomTaxiCommercialCategory(
//       name: vehicleName,
//       type: selectedType,
//       uid: user.uid,
//     );
//     await _loadVehicles();

//     // ========================================================
//     // UPDATE CURRENT REGISTRATION PAGE
//     // ========================================================

//     if (!mounted) {
//       return;
//     }

//     setState(() {
//       selectedVehicle = vehicleName;
//       vehicleError = null;
//       customVehicleController.clear();
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           '$vehicleName added to $selectedType vehicles',
//         ),
//       ),
//     );
//   } catch (e) {
//     debugPrint(
//       'Error saving custom vehicle category: $e',
//     );

//     if (!mounted) {
//       return;
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(
//           'Could not save vehicle category',
//         ),
//       ),
//     );
//   }
// // }
// Future<void> addYourVehicle() async {
//   customVehicleController.clear();

//   File? selectedVehiclePhoto;

//   final Map<String, dynamic>? result =
//       await showDialog<Map<String, dynamic>>(
//     context: context,
//     builder: (dialogContext) {
//       return StatefulBuilder(
//         builder: (context, setDialogState) {
//           return AlertDialog(
//             backgroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             title: const Text(
//               'Add Your Vehicle',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     controller: customVehicleController,
//                     textCapitalization:
//                         TextCapitalization.words,
//                     decoration: InputDecoration(
//                       hintText: selectedType == 'Taxi'
//                           ? 'Example: Toyota Rumion'
//                           : 'Example: BharatBenz',
//                       filled: true,
//                       fillColor: const Color(0xFFF9F9F9),
//                       border: OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius.circular(16),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius.circular(16),
//                         borderSide: const BorderSide(
//                           color: Color(0xFF16803C),
//                           width: 2,
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 16),

//                   // Optional vehicle photo preview.
//                   Container(
//                     width: double.infinity,
//                     height: 130,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF9F9F9),
//                       borderRadius:
//                           BorderRadius.circular(14),
//                       border: Border.all(
//                         color: Colors.grey.shade300,
//                       ),
//                     ),
//                     child: selectedVehiclePhoto != null
//                         ? ClipRRect(
//                             borderRadius:
//                                 BorderRadius.circular(14),
//                             child: Image.file(
//                               selectedVehiclePhoto!,
//                               fit: BoxFit.contain,
//                             ),
//                           )
//                         : const Center(
//                             child: Icon(
//                               Icons.directions_car_outlined,
//                               size: 48,
//                               color: Colors.grey,
//                             ),
//                           ),
//                   ),

//                   const SizedBox(height: 10),

//                   OutlinedButton.icon(
//                     onPressed: () async {
//                       final XFile? picked =
//                           await _imagePicker.pickImage(
//                         source: ImageSource.gallery,
//                         imageQuality: 80,
//                         maxWidth: 1200,
//                         maxHeight: 1200,
//                       );

//                       if (picked != null) {
//                         setDialogState(() {
//                           selectedVehiclePhoto =
//                               File(picked.path);
//                         });
//                       }
//                     },
//                     icon: const Icon(
//                       Icons.photo_library_outlined,
//                     ),
//                     label: Text(
//                       selectedVehiclePhoto == null
//                           ? 'Choose Vehicle Photo (Optional)'
//                           : 'Change Vehicle Photo',
//                     ),
//                   ),

//                   if (selectedVehiclePhoto != null)
//                     TextButton(
//                       onPressed: () {
//                         setDialogState(() {
//                           selectedVehiclePhoto = null;
//                         });
//                       },
//                       child: const Text(
//                         'Remove Photo',
//                         style: TextStyle(
//                           color: Colors.red,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(dialogContext);
//                 },
//                 child: const Text(
//                   'Cancel',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   final String name =
//                       customVehicleController.text.trim();

//                   if (name.isEmpty) {
//                     ScaffoldMessenger.of(context)
//                         .showSnackBar(
//                       const SnackBar(
//                         content: Text(
//                           'Please enter a vehicle name.',
//                         ),
//                       ),
//                     );
//                     return;
//                   }

//                   Navigator.pop(
//                     dialogContext,
//                     <String, dynamic>{
//                       'name': name,
//                       'photo': selectedVehiclePhoto,
//                     },
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor:
//                       const Color(0xFF16803C),
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('Add Vehicle'),
//               ),
//             ],
//           );
//         },
//       );
//     },
//   );

//   if (!mounted || result == null) return;

//   final String vehicleName =
//       (result['name'] as String? ?? '').trim();

//   final File? photo = result['photo'] as File?;

//   if (vehicleName.isEmpty) return;

//   final User? user = FirebaseAuth.instance.currentUser;

// final String creatorUid =
//     user?.uid ?? 'unverified_${DateTime.now().millisecondsSinceEpoch}';

//   // try {
//   //   String imageUrl = '';

//   //   // Upload the photo only if one was selected.
//   //   if (photo != null) {
//   //     showMessage('Uploading vehicle photo...');

//   //     final Reference storageRef =
//   //         FirebaseStorage.instance
//   //             .ref()
//   //             .child('taxiVehicleCategories')
//   //             .child(selectedType.toLowerCase())
//   //             .child(
//   //               '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
//   //             );

//   //     await storageRef.putFile(
//   //       photo,
//   //       SettableMetadata(
//   //         contentType: 'image/jpeg',
//   //       ),
//   //     );

//   //     imageUrl = await storageRef.getDownloadURL();
//   //   }

//   //   // Save the category and its photo URL.
//   //   await saveCustomTaxiCommercialCategory(
//   //     name: vehicleName,
//   //     type: selectedType,
//   //     uid: user.uid,
//   //     imageUrl: imageUrl,
//   //   );

//   //   // Reload the list, including custom categories.
//   //   await _loadVehicles(force: true);

//   //   if (!mounted) return;

//   //   setState(() {
//   //     selectedVehicle = vehicleName;
//   //     vehicleError = null;
//   //     customVehicleController.clear();
//   //   });

//   //   showMessage(
//   //     photo == null
//   //         ? '$vehicleName added successfully.'
//   //         : '$vehicleName and its photo saved successfully.',
//   //   );
//   // } catch (e) {
//   //   debugPrint('Error saving custom vehicle: $e');

//   //   if (!mounted) return;

//   //   showMessage(
//   //     'Could not save the vehicle. Please try again.',
//   //     isError: true,
//   //   );
//   // }
//   try {
//   String imageUrl = '';

//   if (photo != null) {
//     showMessage('Uploading vehicle photo...');

//     // final Reference storageRef = FirebaseStorage.instance
//     //     .ref()
//     //     .child('taxiVehicleCategories')
//     //     .child(selectedType.toLowerCase())
//     //     .child(
//     //       '${creatorUid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
//     //     );

//     // final UploadTask uploadTask = storageRef.putFile(
//     //   photo,
//     //   SettableMetadata(contentType: 'image/jpeg'),
//     // );
//     final String extension =
//     path.extension(photo.path).toLowerCase();

// final String contentType;

// switch (extension) {
//   case '.png':
//     contentType = 'image/png';
//     break;
//   case '.webp':
//     contentType = 'image/webp';
//     break;
//   case '.jpg':
//   case '.jpeg':
//   default:
//     contentType = 'image/jpeg';
//     break;
// }

// final Reference storageRef =
//     FirebaseStorage.instance
//         .ref()
//         .child('taxiVehicleCategories')
//         .child(selectedType.toLowerCase())
//         .child(
//           '${creatorUid}_${DateTime.now().millisecondsSinceEpoch}$extension',
//         );

// await storageRef.putFile(
//   photo,
//   SettableMetadata(contentType: contentType),
// );

// imageUrl = await storageRef.getDownloadURL();

//     final TaskSnapshot snapshot = await uploadTask;
//     imageUrl = await snapshot.ref.getDownloadURL();
//   }

//   await saveCustomTaxiCommercialCategory(
//     name: vehicleName,
//     type: selectedType,
//     uid: creatorUid,
//     imageUrl: imageUrl,
//   );

//   await _loadVehicles(force: true);

//   if (!mounted) return;

//   setState(() {
//     selectedVehicle = vehicleName;
//     vehicleError = null;
//     customVehicleController.clear();
//   });

//   showMessage(
//     photo == null
//         ? '$vehicleName added successfully.'
//         : '$vehicleName and its photo saved successfully.',
//   );
// } catch (e, stackTrace) {
//   debugPrint('Error saving custom vehicle: $e');
//   debugPrintStack(stackTrace: stackTrace);

//   if (!mounted) return;

//   showMessage(
//     'Could not save the vehicle: $e',
//     isError: true,
//   );
// }
// }

// void changeVehicleType(String type) {
//   setState(() {
//     selectedType = type;

//     selectedVehicle = null;
//     selectedVehicles.clear();

//     _loadedVehicles = [];

//     vehicleNameController.clear();
//     vehicleNumberController.clear();

//     vehicleError = null;
//     vehicleNumberError = null;
//   });

//   _listenToVehicles();
// }