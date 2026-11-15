
//   try {
//     // ===========================================================
//     // GET CURRENT LOCATION
//     // ===========================================================

//     // if (currentPosition == null) {
//     //   final bool locationSuccess =
//     //       await getCurrentLocation();

//     //   if (!locationSuccess ||
//     //       currentPosition == null) {
//     //     if (mounted) {
//     //       setState(() {
//     //         isSubmitting = false;
//     //       });
//     //     }

//     //     return;
//     //   }
//     // }

//     // ===========================================================
//     // CURRENT FIREBASE USER
//     // ===========================================================

//     final User? user =
//         _auth.currentUser;

//     if (user == null) {
//       if (mounted) {
//         setState(() {
//           isSubmitting = false;
//         });
//       }

//       showMessage(
//         'Authentication failed. Please verify OTP again.',
//         isError: true,
//       );

//       return;
//     }

//     // ===========================================================
//     // FINAL VALUES
//     // ===========================================================

//     final String finalCategory =
//         selectedCategories.first;

//     final String? finalExperience =
//         selectedExperience;

//     // ===========================================================
//     // 1. SAVE COMMON PROFILE / LOCAL PROFILE FIRST
//     // ===========================================================
//     //
//     // Keep this because ScreenHome/profile uses the common
//     // profile information.
//     //
//     // ===========================================================

//     await CommonProfileService.saveLogin(
//       uid: user.uid,
//       name: name,
//       mobile: mobile,
//       role: 'self_employee',
//       profilePhotoUrl: profilePhotoUrl,
//     );

//     // SAVE SELF EMPLOYEE PROFILE TO HIVE
// await saveSelfEmployeeToHive(
//   user: user,
//   name: name,
//   mobile: mobile,
//   finalCategory: finalCategory,
//   experience: finalExperience,
// );

//     // ===========================================================
//     // 2. START FIRESTORE SAVE IN BACKGROUND
//     // ===========================================================
//     //
//     // IMPORTANT:
//     // There is NO "await" here.
//     //
//     // Firestore starts saving while we prepare to go to Home.
//     //
//     // ===========================================================

//     saveSelfEmployeeToFirestore(
//       position: currentPosition!,
//       user: user,
//       name: name,
//       mobile: mobile,
//       finalCategory: finalCategory,
//       experience: finalExperience,
//     ).then((_) {
//       debugPrint(
//         'Self Employee Firestore sync completed successfully.',
//       );
//     }).catchError((error) {
//       debugPrint(
//         'Self Employee Firestore background sync failed: $error',
//       );
//     });

//     // ===========================================================
//     // 3. GIVE THE USER A SHORT 2 SECOND TRANSITION
//     // ===========================================================

//     await Future.delayed(
//       const Duration(seconds: 2),
//     );

//     // ===========================================================
//     // 4. GO TO HOME
//     // ===========================================================

//     if (!mounted) {
//       return;
//     }

//     setState(() {
//       isSubmitting = false;
//     });

//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(
//         builder: (context) =>
//             const ScreenHome(),
//       ),
//       (route) => false,
//     );
//   } on FirebaseException catch (error) {
//     // -----------------------------------------------------------
//     // FIREBASE ERROR
//     // -----------------------------------------------------------

//     if (!mounted) {
//       return;
//     }

//     setState(() {
//       isSubmitting = false;
//     });

//     showMessage(
//       error.message ??
//           'Unable to create your profile. Please try again.',
//       isError: true,
//     );
//   } catch (error) {
//     // -----------------------------------------------------------
//     // GENERAL ERROR
//     // -----------------------------------------------------------

//     if (!mounted) {
//       return;
//     }

//     setState(() {
//       isSubmitting = false;
//     });

//     showMessage(
//       'Something went wrong. Please try again.',
//       isError: true,
//     );
//   }

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
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jober_india/jober_indiaScreens.dart/common_profile_services.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_camera_capture.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_home.dart';
import 'package:jober_india/l10n/app_localizations.dart';
import 'package:jober_india/screens/location_localization.dart';
//import 'package:jober_india/jober_indiaScreens.dart/screen_home.dart';

import '../Privacy&Terms/privacy_terms_section.dart';

class SelfEmployeeLocation {
  final String placeName;
  final double? latitude;
  final double? longitude;

  SelfEmployeeLocation({
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

  factory SelfEmployeeLocation.fromMap(
    Map<String, dynamic> map,
  ) {
    return SelfEmployeeLocation(
      placeName: map['placeName']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
// ===============================================================
// SCREEN SELF EMPLOYEES
// ===============================================================

class ScreenSelfEmployeesLogin extends StatefulWidget {
  const ScreenSelfEmployeesLogin({
    super.key,
  });

  @override
  State<ScreenSelfEmployeesLogin> createState() =>
      _ScreenSelfEmployeesLoginState();
}


// ===============================================================
// STATE
// ===============================================================

class _ScreenSelfEmployeesLoginState
    extends State<ScreenSelfEmployeesLogin>
    with WidgetsBindingObserver {


  // ===============================================================
  // CONTROLLERS
  // ===============================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController mobileController =
      TextEditingController();

  final TextEditingController otpController =
      TextEditingController();

  final TextEditingController secondaryPhoneController =
    TextEditingController();

  final TextEditingController categorySearchController =
      TextEditingController();

  final TextEditingController customCategoryController =
      TextEditingController();

  final TextEditingController _shopLocationController =
    TextEditingController();
  // ===============================================================
  // FIREBASE
  // ===============================================================

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

   final FirebaseFirestore _firestore =
       FirebaseFirestore.instance;

  static const Color green =
     // Color(0xFF16803C);
      Color(0xFF138808);

  // static const Color submitGreen =
  //     Color(0xFF159B16);

  static const Color darkText =
      Color(0xFF202124);

  static const Color lightFill =
      Color(0xFFF9F9F9);

     bool locationError = false;

   // ==========================================================
  // LOCATION
  // ==========================================================
SelfEmployeeLocation? currentLocation;

bool isGettingLocation = false;
bool isSearchingLocation = false;

// Used to invalidate an older location request
int _locationRequestId = 0;

  bool privacyPolicyAccepted = false;
  String? privacyPolicyError;

//    File? profilePhoto;
//   String? profilePhotoUrl;
// bool isUploadingPhoto = false;
//   final ImagePicker _imagePicker = ImagePicker();
File? profilePhoto;
String? profilePhotoUrl;

bool isUploadingPhoto = false;
double photoUploadProgress = 0.0;

Future<void>? photoUploadFuture;

final ImagePicker _imagePicker = ImagePicker();
  // ===============================================================
  // OTP VARIABLES
  // ===============================================================

  final List<String> experienceOptions = [
    'No Experience',
    'Beginner',
    'Up to 1 year',
    '1 to 5 years',
    '5 to 10 years',
    '10 to 15 years',
    '15 to 20 years',
    'Above 20 years',
  ];

  bool nameError = false;
bool mobileError = false;
bool secondaryMobileError = false;
bool categoryError = false;
bool experienceError = false;

  String? selectedExperience;

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

  int secondsRemaining = 30;

   Timer? timer;
  // ===============================================================
  // TIMER
  // ===============================================================

  int remainingSeconds = 0;


  // ===============================================================
  // CATEGORY
  // ===============================================================
    final List<String> customCategories = [];


  final List<String> selectedCategories = [];


  List<String> filteredCategories = [];

  String? selectedCategory;

  bool showCustomCategory = false;
  bool isCategoryDropdownOpen = false;
   // bool isStateDropdownOpen = false;


  // ===============================================================
  // LOCATION
  // ===============================================================

  Position? currentPosition;

//  bool isGettingLocation = false;


  // ===============================================================
  // ERROR MESSAGE
  // ===============================================================

  String? errorMessage;
//bool mobileError = false;


  // ===============================================================
  // SELF EMPLOYEE CATEGORIES
  // ===============================================================

  final List<String> selfEmployeeCategories = [

    // -------------------------------------------------------------
    // USER REQUESTED MAIN CATEGORIES
    // -------------------------------------------------------------

    'Artist',

    'Designers',

    'Professionals',

    'Govt Retired',


    // -------------------------------------------------------------
    // MORE USEFUL SELF EMPLOYMENT CATEGORIES
    // -------------------------------------------------------------

    'Freelancer',

    'Consultant',

    'Photographer',

    'Videographer',

    'Graphic Designer',

    'Web Designer',

    'Interior Designer',

    'Fashion Designer',

    'Writer',

    'Content Creator',

    'Teacher',

    'Tutor',

    'Trainer',

    'Accountant',

    'Legal Consultant',

    'Business Consultant',

    'Marketing Professional',

    'Sales Professional',

    'Architect',

    'Engineer',

    'Social Media Manager',

    'Event Planner',

    'Makeup Artist',

    'Beautician',

    'Musician',

    'Singer',

    'Painter',

    'Craft Worker',

    'Other',
  ];

  // ===============================================================
  // INIT STATE
  // ===============================================================

  @override
  void initState() {

    super.initState();

    WidgetsBinding.instance
        .addObserver(this);

     filteredCategories =
        List<String>.from(
      selfEmployeeCategories,
    );
     filteredStates = List<String>.from(indiaStates);

  loadDistricts();
    // -------------------------------------------------------------
    // CATEGORY SEARCH LISTENER
    // -------------------------------------------------------------

    // categorySearchController
    //     .addListener(
    //   _refreshCategorySearch,
    // );
  }

//         final TextEditingController nearestCityController =
//     TextEditingController();

// String stateError = '';
// String districtError = '';
// String nearestCityError = '';
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


  // ===============================================================
  // REFRESH CATEGORY SEARCH
  // ===============================================================

  // void _refreshCategorySearch() {

  //   if (!mounted) return;

  //   setState(() {});
  // }

   List<String> get allCategories {

    final List<String> result = [];

    for (final category in selfEmployeeCategories) {

      if (!result.contains(category)) {

        result.add(category);

      }

    }

    for (final category in customCategories) {

      if (!result.contains(category)) {

        result.add(category);

      }

    }

    return result;
  }

  void filterCategories(String value) {
  final String search =
      value.trim().toLowerCase();

  final List<String> result =
      allCategories.where((category) {
    return search.isEmpty ||
        category.toLowerCase().contains(search);
  }).toList();

  if (!mounted) return;

  setState(() {
    filteredCategories = result;
  });
}

   void addCustomCategory() {
    final String category =
        customCategoryController.text.trim();

    if (category.isEmpty) {
      showMessage(
        'Please enter a category.',
      );
      return;
    }

    final int existingIndex =
        allCategories.indexWhere(
      (item) =>
          item.toLowerCase() ==
          category.toLowerCase(),
    );

    String actualCategory;

    if (existingIndex != -1) {

      actualCategory =
          allCategories[existingIndex];

    } else {

      customCategories.add(
        category,
      );
      actualCategory = category;
    }

    if (!selectedCategories.contains(
      actualCategory,
    )) {

      selectedCategories.add(
        actualCategory,
      );

    }

    customCategoryController.clear();
    categorySearchController.clear();

filterCategories(categorySearchController.text);

    if (mounted) {

      setState(() {

        categoryError = false;

      });

    }

    Navigator.of(context).pop();

    showMessage(
      '$actualCategory added.',
    );

  }

  void showAddCategoryDialog() {
    customCategoryController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) {

        return AlertDialog(

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Add Your Own Category',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          content: TextField(

            controller:
                customCategoryController,

            textCapitalization:TextCapitalization.words,

            maxLength: 50,

            decoration:InputDecoration(

              hintText:'Enter Your Job Category',

              prefixIcon:
                  const Icon(Icons.work_outline,
                color: green),

              filled: true,
              fillColor: lightFill,

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  15,
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
                'CANCEL',
              ),

            ),

            ElevatedButton(

              onPressed:
                  addCustomCategory,

              style:
                  ElevatedButton.styleFrom(

                backgroundColor:
                    green,

                foregroundColor:
                    Colors.white,

                elevation: 0,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

              ),

              child:
                  const Text(
                'ADD',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===============================================================
  // DISPOSE
  // ===============================================================

  @override
  void dispose() {

    WidgetsBinding.instance
        .removeObserver(this);

    timer?.cancel();
    nameController.dispose();
    mobileController.dispose();
    otpController.dispose();
    secondaryPhoneController.dispose();
    categorySearchController.dispose();
    customCategoryController.dispose();
    stateSearchController.dispose();
    districtSearchController.dispose();


    super.dispose();
  }


  // ===============================================================
  // APPLICATION LIFECYCLE
  // ===============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {

    if (state ==
        AppLifecycleState.resumed) {

      // Location permission may have been changed
      // from phone settings.

    }
  }


  // ===============================================================
  // VALIDATE MOBILE NUMBER
  // ===============================================================

  bool _isValidIndianMobile(
    String mobile,
  ) {

    return RegExp(
      r'^[6-9][0-9]{9}$',
    ).hasMatch(
      mobile,
    );
  }

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
  
  String? getFinalCategory() {
    if (selectedCategories.isEmpty){
      return null;
    }
    return selectedCategories.first;
  }


  // ===============================================================
  // CREATE SEARCH KEYWORDS
  //
  // This helps Firestore search/filter selfEmployeeCategories efficiently.
  // ===============================================================

  List<String> createSearchKeywords(
    String value,
  ) {

    final String text =
        value
            .trim()
            .toLowerCase();


    if (text.isEmpty) {
      return [];
    }


    final List<String> keywords = [];


    final List<String> words =
        text.split(
      RegExp(r'\s+'),
    );

    for (
      int i = 1;
      i <= text.length;
      i++
    ) {

      keywords.add(
        text.substring(0, i),
      );
    }


    // -------------------------------------------------------------
    // WORD PREFIXES
    // Example:
    // Graphic Designer
    // graphic
    // designer
    // -------------------------------------------------------------

    for (
      final String word
          in words
    ) {

      for (
        int i = 1;
        i <= word.length;
        i++
      ) {

        keywords.add(
          word.substring(0, i),
        );
      }
    }


    return keywords
        .toSet()
        .toList();
  }

Future<void> saveSelfEmployeeToHive({
  required User user,
  required String name,
  required String mobile,
  required String finalCategory,
  required String? experience,
}) async {
  final Box userBox = await Hive.openBox('userBox');

  await userBox.putAll({
    'uid': user.uid,
    'name': name,
    'mobile': mobile,
    'role': 'self_employee',

    'state': selectedState!.trim(),
    'district': selectedDistrict!.trim(),
    'nearestTown': nearestCityController.text.trim(),

    'categories': List<String>.from(selectedCategories),
    'category': finalCategory,
    'experience': experience,

    'profilePhotoUrl': profilePhotoUrl ?? '',

    // CURRENT / PARKED LOCATION
    'selfEmployeeCurrentLocationName':
        currentLocation?.placeName ?? '',

    'selfEmployeeCurrentLocationLatitude':
        currentLocation?.latitude,

    'selfEmployeeCurrentLocationLongitude':
        currentLocation?.longitude,
  });
}

  // ===============================================================
  // SUBMIT SELF EMPLOYEE
  // ===============================================================

Future<void> saveSelfEmployeeToFirestore({
  required User user,
  required String name,
  required String mobile,
  required String finalCategory,
  required String? experience,
}) async {
  final List<String> categories = selectedCategories
      .map((category) => category.trim())
      .where((category) => category.isNotEmpty)
      .toSet()
      .toList();

  if (categories.isEmpty) {
    throw Exception('Please select at least one category.');
  }

  final String mainCategory = categories.contains(finalCategory.trim())
      ? finalCategory.trim()
      : categories.first;

  final Map<String, dynamic> data = <String, dynamic>{
    'uid': user.uid,
    'name': name,
    'mobile': mobile,
    'state': selectedState!.trim(),
    'district': selectedDistrict!.trim(),
    'nearestTown': nearestCityController.text.trim(),

    'currentLocationName': currentLocation?.placeName ?? '',
    'currentLocationLatitude': currentLocation?.latitude,
    'currentLocationLongitude': currentLocation?.longitude,

    'currentLocation': {
      'placeName': currentLocation?.placeName ?? '',
      'latitude': currentLocation?.latitude,
      'longitude': currentLocation?.longitude,
    },

    'role': 'self_employee',
    'categories': categories,
    'category': mainCategory,
    'experience': experience,

    'isActive': true,
    'isOnline': true,
    'onlineUpdatedAt': FieldValue.serverTimestamp(),

    'nameKeywords': createSearchKeywords(name),

    'categoryKeywords': categories
        .expand((category) => createSearchKeywords(category))
        .toSet()
        .toList(),

    if (profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty)
      'profilePhotoUrl': profilePhotoUrl,

    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  // Save the profile only once.
  await _firestore
      .collection('selfEmployees')
      .doc(user.uid)
      .set(data, SetOptions(merge: true));

  debugPrint(
    'Self-employed Firestore save successful: ${user.uid}',
  );
}

Future<void> submitSelfEmployee() async {
  // -------------------------------------------------------------
  // PREVENT DOUBLE SUBMISSION
  // -------------------------------------------------------------

  if (isSubmitting) {
    return;
  }

  bool hasError = false;

  // -------------------------------------------------------------
  // GET VALUES
  // -------------------------------------------------------------

  final String name =
      nameController.text.trim();

  final String mobile =
      mobileController.text.trim();

  final String secondaryMobile =
      secondaryPhoneController.text.trim();

  // -------------------------------------------------------------
  // NAME VALIDATION
  // -------------------------------------------------------------

  nameError =
      name.isEmpty || name.length < 2;

  if (nameError) {
    hasError = true;
  }

  // -------------------------------------------------------------
  // MOBILE VALIDATION
  // -------------------------------------------------------------

  mobileError =
      !_isValidIndianMobile(mobile);

  if (mobileError) {
    hasError = true;
  }

  // -------------------------------------------------------------
  // SECONDARY MOBILE VALIDATION
  // -------------------------------------------------------------

  secondaryMobileError =
      !_isValidIndianMobile(secondaryMobile);

  if (secondaryMobileError) {
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

  // -------------------------------------------------------------
  // CATEGORY VALIDATION
  // -------------------------------------------------------------

  categoryError =
      selectedCategories.isEmpty;

  if (categoryError) {
    hasError = true;
  }

  // -------------------------------------------------------------
  // EXPERIENCE VALIDATION
  // -------------------------------------------------------------

  experienceError =
      selectedExperience == null ||
      selectedExperience!.trim().isEmpty;

  if (experienceError) {
    hasError = true;
  }

// ==========================================================
// GARAGE LOCATION
// ==========================================================

if (currentLocation == null) {
  locationError = true;
  hasError = true;
} else {
  locationError = false;
}

  // -------------------------------------------------------------
  // PRIVACY POLICY / TERMS VALIDATION
  // -------------------------------------------------------------

  if (!privacyPolicyAccepted) {
    privacyPolicyError =
        'Please accept the Privacy Policy and Terms & Conditions.';

    hasError = true;
  } else {
    privacyPolicyError = null;
  }

  // -------------------------------------------------------------
  // SHOW ALL RED BORDERS + RED ERROR TEXT
  // -------------------------------------------------------------
  //
  // IMPORTANT:
  // Do this BEFORE returning.
  // This makes every mandatory invalid field show its
  // red border and red error message at the same time.
  // -------------------------------------------------------------

  if (mounted) {
    setState(() {});
  }

  // -------------------------------------------------------------
  // STOP SUBMISSION IF ANY VALIDATION FAILED
  // -------------------------------------------------------------

  if (hasError) {
    return;
  }

  // -------------------------------------------------------------
  // OTP VALIDATION
  // -------------------------------------------------------------

  if (!otpVerified) {
    showMessage(
      'Please verify your mobile number first.',
      isError: true,
    );
    return;
  }

  // -------------------------------------------------------------
  // START SUBMISSION
  // -------------------------------------------------------------

  if (!mounted) {
    return;
  }

  setState(() {
    isSubmitting = true;
  });

try {
    // 1. Get the authenticated user.
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Authentication failed. Please verify your mobile number again.',
      );
    }

    final String finalCategory = selectedCategories.first.trim();
    final String? finalExperience = selectedExperience;

    // 2. Save the common profile.
    await CommonProfileService.saveLogin(
      uid: user.uid,
      name: name,
      mobile: mobile,
      role: 'self_employee',
      profilePhotoUrl: profilePhotoUrl,
    );

    // 3. Save the local profile.
    await saveSelfEmployeeToHive(
      user: user,
      name: name,
      mobile: mobile,
      finalCategory: finalCategory,
      experience: finalExperience,
    );

    // 4. Start Firestore sync without blocking navigation.
    // saveSelfEmployeeToFirestore(
    //   user: user,
    //   name: name,
    //   mobile: mobile,
    //   finalCategory: finalCategory,
    //   experience: finalExperience,
    // ).then((_) {
    //   debugPrint(
    //     'Self-employed Firestore save successful: ${user.uid}',
    //   );
    // }).catchError((Object error, StackTrace stackTrace) {
    //   debugPrint('Self-employed Firestore save failed: $error');
    //   debugPrintStack(stackTrace: stackTrace);
    // });
    // 4. Save the Firestore profile and WAIT for completion.
await saveSelfEmployeeToFirestore(
  user: user,
  name: name,
  mobile: mobile,
  finalCategory: finalCategory,
  experience: finalExperience,
);

debugPrint(
  'Self-employed Firestore save successful: ${user.uid}',
);

    // 5. Short transition, then navigate Home.
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const ScreenHome(),
      ),
      (route) => false,
    );
  } on FirebaseException catch (error, stackTrace) {
    debugPrint('Firebase profile save error: $error');
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    showMessage(
      error.message ??
          'Unable to save your profile. Please check your connection and try again.',
      isError: true,
    );
  } catch (error, stackTrace) {
    debugPrint('Self-employed submission error: $error');
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    showMessage(
      error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : 'Something went wrong while saving your profile. Please try again.',
      isError: true,
    );
  }
}

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
  controller: secondaryPhoneController,
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

   Widget categorySection() {
    final selfEmployeeCategories =
        filteredCategories;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        sectionTitle(
          'Employee Categories',
        ),
        const SizedBox(height: 8),

        AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 180,
          ),
          decoration: BoxDecoration(
            color: lightFill,
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: categoryError
                  ? Colors.red
                  : isCategoryDropdownOpen
                      ? green
                      : Colors.grey.shade300,
              width:
                  categoryError ||
                          isCategoryDropdownOpen
                      ? 1.5
                      : 1,
            ),
          ),
          child: Column(
            children: [
              // ------------------------------------------------
              // CATEGORY HEADER
              // ------------------------------------------------

              InkWell(
                borderRadius:
                    BorderRadius.circular(20),
                onTap: () {
                  FocusScope.of(context)
                      .unfocus();

                  setState(() {
                    isCategoryDropdownOpen =
                        !isCategoryDropdownOpen;

                   // categoryError = false;
                  });
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.work_outline,
                        color: green,
                        size: 22,
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child:
                            selectedCategories
                                    .isEmpty
                                ? Text(
                                    'Select your Own Job',
                                    style:
                                        TextStyle(
                                      color: Colors
                                          .grey
                                          .shade500,
                                      fontSize: 15,
                                    ),
                                  )
                                : Text(
                                    selectedCategories
                                        .join(', '),
                                    maxLines: 2,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style:
                                        const TextStyle(
                                      color:
                                          darkText,
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight
                                              .w500,
                                    ),
                                  ),
                      ),

                      Icon(
                        isCategoryDropdownOpen
                            ? Icons
                                .keyboard_arrow_up
                            : Icons
                                .keyboard_arrow_down,
                        color: green,
                      ),
                    ],
                  ),
                ),
              ),

              // ------------------------------------------------
              // DROPDOWN CONTENT
              // ------------------------------------------------

              if (isCategoryDropdownOpen)
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    12,
                    0,
                    12,
                    12,
                  ),
                  child: Column(
                    children: [
                      // SEARCH
                      TextField(
                        controller:
                            categorySearchController,
                        onChanged:
                            filterCategories,
                        decoration:
                            InputDecoration(
                          hintText:
                              'Search category...',
                          prefixIcon:
                              const Icon(
                            Icons.search,
                            color: green,
                          ),
                          filled: true,
                          fillColor:
                              Colors.white,
                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color: Colors
                                  .grey
                                  .shade300,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color: Colors
                                  .grey
                                  .shade300,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
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

                      const SizedBox(
                        height: 8,
                      ),

                      // ADD CUSTOM CATEGORY
                      InkWell(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        onTap:
                            showAddCategoryDialog,
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration:
                                    BoxDecoration(
                                  color: green
                                      .withValues(alpha: 
                                    0.10,
                                  ),
                                  shape:
                                      BoxShape
                                          .circle,
                                ),
                                child:
                                    const Icon(
                                  Icons.add,
                                  color: green,
                                  size: 21,
                                ),
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              const Expanded(
                                child: Text(
                                  'Add your own category',
                                  style:
                                      TextStyle(
                                    color:
                                        darkText,
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                              ),

                              const Icon(
                                Icons
                                    .chevron_right,
                                color: green,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Divider(
                        height: 8,
                      ),

                      // CATEGORY LIST
                      SizedBox(
                        height: 320,
                        child: selfEmployeeCategories.isEmpty
                            ? Center(
                                child: Text(
                                  'No category found',
                                  style:
                                      TextStyle(
                                    color: Colors
                                        .grey
                                        .shade600,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount:
                                    selfEmployeeCategories.length,
                                itemBuilder:
                                    (
                                  context,
                                  index,
                                ) {
                                  final category =
                                      selfEmployeeCategories[
                                          index];

                                  final isSelected =
                                      selectedCategories
                                          .contains(
                                    category,
                                  );

                                  return CheckboxListTile(
                                    dense: true,
                                    contentPadding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 2,
                                    ),
                                    activeColor:
                                        green,
                                    checkColor:
                                        Colors.white,
                                    value:
                                        isSelected,
                                    title: Text(
                                      category,
                                      style:
                                          const TextStyle(
                                        color:
                                            darkText,
                                        fontSize:
                                            14,
                                      ),
                                    ),
                                    onChanged:
                                        (value) {
                                      setState(() {
                                        if (value ==
                                            true) {
                                          if (!selectedCategories
                                              .contains(
                                            category,
                                          )) {
                                            selectedCategories
                                                .add(
                                              category,
                                            );
                                          }
                                        } else {
                                          selectedCategories
                                              .remove(
                                            category,
                                          );
                                        }

                                        categoryError =
                                            false;
                                      });
                                    },
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
if (categoryError)
  const Padding(
    padding: EdgeInsets.only(left: 12, top: 5),
    child: Text(
      'Please select at least one category.',
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

    Widget experienceSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Experience',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.3,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedExperience,
              isExpanded: true,
              hint: const Row(
                children: [
                  Icon(
                    Icons.work_outline,
                    color: Color(0xFF16803C),
                    size: 27,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Select experience',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black54,
              ),
              borderRadius:
                  BorderRadius.circular(15),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 5,
              ),
              items:
                  experienceOptions.map(
                (String experience) {
                  return DropdownMenuItem<String>(
                    value: experience,
                    child: Text(
                      experience,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  );
                },
              ).toList(),
              onChanged:
                  (String? value) {
                setState(() {
                  selectedExperience =
                      value;

                  experienceError =
                      false;
                });
              },
            ),
          ),
        ),
      ],
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
                              : 'Use Working Location',
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

setState(() {
  currentLocation = SelfEmployeeLocation(
    placeName: placeName.trim(),
    latitude: null,
    longitude: null,
  );
  locationError = false;
  isGettingLocation = false;
  isSearchingLocation = false;
});

showMessage(
  'Ambulance Parked location added.',
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

    if (!mounted || requestId != _locationRequestId) return;

    setState(() {
  currentLocation = SelfEmployeeLocation(
    placeName: placeName,
    latitude: position.latitude,
    longitude: position.longitude,
  );

  locationError = false;
});

    showMessage(
      'Current location added.',
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

  Future<void> pickProfilePhoto() async {
  if (isSubmitting) return;

  final ImageSource? source =
      await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
              ),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(
                  context,
                  ImageSource.camera,
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
              ),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(
                  context,
                  ImageSource.gallery,
                );
              },
            ),
          ],
        ),
      );
    },
  );

  if (source == null || !mounted) return;

  File? selectedFile;

  try {
    if (source == ImageSource.camera) {
      selectedFile = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (_) => const ScreenCameraCapture(),
        ),
      );
    } else {
      final XFile? pickedFile =
          await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        selectedFile = File(pickedFile.path);
      }
    }
  } catch (e) {
    debugPrint(
      'Profile photo selection error: $e',
    );

    if (mounted) {
      showMessage(
        'Unable to select the photo.',
        isError: true,
      );
    }

    return;
  }

  if (selectedFile == null || !mounted) return;

  setState(() {
    profilePhoto = selectedFile;
    profilePhotoUrl = null;
    isUploadingPhoto = true;
    photoUploadProgress = 0.0;
  });

  // Start upload immediately.
  photoUploadFuture =
      _uploadProfilePhotoInBackground(
    selectedFile,
  );
}


Future<void> _uploadProfilePhotoInBackground(
  File file,
) async {
  final User? user = _auth.currentUser;

  if (user == null) {
    if (mounted) {
      setState(() {
        isUploadingPhoto = false;
      });
    }
    return;
  }

  try {
    final Reference storageRef =
        FirebaseStorage.instance
            .ref()
            .child('profilePhotos')
            .child(user.uid)
            .child('profile.jpg');

    final UploadTask uploadTask =
        storageRef.putFile(
      file,
      SettableMetadata(
        contentType: 'image/jpeg',
      ),
    );

    uploadTask.snapshotEvents.listen(
      (TaskSnapshot snapshot) {
        if (!mounted) return;

        if (snapshot.totalBytes > 0) {
          final double progress =
              snapshot.bytesTransferred /
                  snapshot.totalBytes;

          setState(() {
            photoUploadProgress = progress;
          });
        }
      },
    );

    final TaskSnapshot snapshot =
        await uploadTask;

    final String url =
        await snapshot.ref.getDownloadURL();

    if (!mounted) return;

    setState(() {
      profilePhotoUrl = url;
      isUploadingPhoto = false;
      photoUploadProgress = 1.0;
    });
  } catch (e) {
    debugPrint(
      'Self employee photo upload failed: $e',
    );

    if (!mounted) return;

    setState(() {
      isUploadingPhoto = false;
      photoUploadProgress = 0.0;
    });

    // IMPORTANT:
    // Photo is optional.
    // Registration can still continue.
    showMessage(
      'Photo upload failed. You can continue without a photo.',
      isError: true,
    );
  }
}
  
  Widget _profilePhotoSection() {
  final bool hasPhoto =
      profilePhoto != null ||
      (profilePhotoUrl != null &&
          profilePhotoUrl!.isNotEmpty);

  return GestureDetector(
    onTap: isSubmitting
        ? null
        : pickProfilePhoto,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage:
                    profilePhoto != null
                        ? FileImage(profilePhoto!)
                        : profilePhotoUrl != null &&
                                profilePhotoUrl!.isNotEmpty
                            ? NetworkImage(
                                profilePhotoUrl!,
                              )
                            : null,
                child: !hasPhoto
                    ? const Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.grey,
                      )
                    : null,
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
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

          if (isUploadingPhoto) ...[
            const SizedBox(height: 12),

            LinearProgressIndicator(
              value: photoUploadProgress > 0
                  ? photoUploadProgress
                  : null,
              minHeight: 4,
              borderRadius:
                  BorderRadius.circular(10),
            ),

            const SizedBox(height: 6),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                photoUploadProgress > 0
                    ? 'Uploading photo... '
                        '${(photoUploadProgress * 100).round()}%'
                    : 'Uploading photo...',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],

          if (!isUploadingPhoto &&
              profilePhotoUrl != null &&
              profilePhotoUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),

            const Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Color(0xFF16803C),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Photo uploaded',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF16803C),
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
  // ===============================================================
  // BUILD
  // ===============================================================
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

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      backgroundColor:
          const Color(
        0xFFF7F8F7,
      ),


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
                text: 'Self Employee',
                style:
                    TextStyle(
                  color:
                      Color(0xFF08744F),
                ),
              ),

              TextSpan(
                text: AppLocalizations.of(context)!.registration,
                  //  ' Registration',
                style:
                    TextStyle(
                 color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),

      body:
          SafeArea(

        child:
            SingleChildScrollView(

          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,

          padding:
              const EdgeInsets.all(
            16,
          ),

          child:
              Column(

            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [


              // // ===================================================
              // // HEADER
              // // ===================================================

              const SizedBox(
                height: 6,
              ),


              const Text(

                'Create your profile and let nearby people find your services.',

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(

                  fontSize:
                      14,

                  color:
                      Colors.black54,

                ),

              ),

              const SizedBox(
                height: 25,
              ),

              // ===================================================
              // NAME
              // ===================================================

               sectionTitle('Name'),

              const SizedBox(height: 10),



            TextField(
  controller: nameController,
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

              const SizedBox(
                height: 20,
              ),


              // ===================================================
              // MOBILE NUMBER
              // ===================================================

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

              const SizedBox(
                height: 25,
              ),

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
              // ===================================================
              // CATEGORY TITLE
              // ===================================================

              categorySection(),
            
      const SizedBox(height: 10),
       experienceSection(),

                 const SizedBox(height: 20),
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

              // ===================================================
              // SUBMIT BUTTON
              // ===================================================

              SizedBox(

                height:
                    56,

                child:
                    ElevatedButton(

                  onPressed:

                      isSubmitting ||
                              isGettingLocation

                          ? null

                          : submitSelfEmployee,


                  style:
                      ElevatedButton.styleFrom(

                    backgroundColor:
                        const Color(
                      0xFF198B35,
                    ),

                    foregroundColor:
                        Colors.white,

                    shape:
                        RoundedRectangleBorder(

                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),

                    ),

                  ),


                  child:

                      isSubmitting ||
                              isGettingLocation

                          ? const SizedBox(

                              height:
                                  24,

                              width:
                                  24,

                              child:
                                  CircularProgressIndicator(

                                color:
                                    Colors.white,

                                strokeWidth:
                                    2,

                              ),

                            )

                          : const Text(

                              'SUBMIT',

                              style:
                                  TextStyle(

                                fontSize:
                                    16,

                                fontWeight:
                                    FontWeight.bold,

                              ),

                            ),

                ),

              ),


              const SizedBox(
                height: 30,
              ),


            ]
          )

        ),

      ),

    );
  }

}


// Future<void> submitSelfEmployee() async {
//   if (isSubmitting) return;

//   bool hasError = false;

//   // ============================================================
//   // NAME VALIDATION
//   // ============================================================

//   final String name = nameController.text.trim();


//   if (name.isEmpty || name.length < 2) {
//   nameError = true;
//   hasError = true;
// } else {
//   nameError = false;
// }

//   // ============================================================
//   // MOBILE VALIDATION
//   // ============================================================

//   final String mobile = mobileController.text.trim();

//   if (mobile.length != 10 ||
//       !_isValidIndianMobile(mobile)) {
//     mobileError = true;
//     hasError = true;
//   } else {
//     mobileError = false;
//   }

//   // ============================================================
//   // OTP VALIDATION
//   // ============================================================

//   if (!otpVerified) {
//     showMessage(
//       'Please verify your mobile number first',
//       isError: true,
//     );
//     return;
//   }

//   // ============================================================
//   // SECONDARY MOBILE VALIDATION
//   // ============================================================

//   final String secondaryMobile =
//       secondaryPhoneController.text.trim();


//  if (secondaryMobile.isEmpty ||
//     !_isValidIndianMobile(secondaryMobile)) {
//   secondaryMobileError = true;
//   hasError = true;
// } else {
//   secondaryMobileError = false;
// }
//   // ============================================================
//   // CATEGORY VALIDATION
//   // ============================================================
// if (selectedCategories.isEmpty) {
//   categoryError = true;
//   hasError = true;
// } else {
//   categoryError = false;
// }

//   // ============================================================
//   // PRIVACY / TERMS
//   // ============================================================

//   if (!privacyPolicyAccepted) {
//     privacyPolicyError =
//         'Please accept the Privacy Policy and Terms & Conditions.';
//     hasError = true;
//   } else {
//     privacyPolicyError = null;
//   }

//   // ============================================================
//   // UPDATE ALL VALIDATION UI
//   // ============================================================

//   if (mounted) {
//     setState(() {});
//   }

//   // ============================================================
//   // STOP IF VALIDATION FAILED
//   // ============================================================

//   if (hasError) {
//     return;
//   }

//   // ============================================================
//   // START SUBMISSION
//   // ============================================================

//   if (!mounted) return;

//   setState(() {
//     isSubmitting = true;
//   });

//   try {
//     // Your existing submission code continues here...

      // ===========================================================
      // SAVE TO FIRESTORE
      //
      // Document ID = Firebase UID
      //
      // This prevents duplicate profiles and is safer for
      // large numbers of users.
      // ===========================================================

      // final DocumentReference<Map<String, dynamic>>
      //     employeeRef =

      //     _firestore
      //         .collection(
      //           'selfEmployees',
      //         )
      //         .doc(
      //           user.uid,
      //         );


      // await employeeRef.set(

      //   {

      //     // -------------------------------------------------------
      //     // BASIC DETAILS
      //     // -------------------------------------------------------

      //     'uid':
      //         user.uid,

      //     'name':
      //         name,

      //     'mobile':
      //         mobile,

      //     'category':
      //         finalCategory,


      //     // -------------------------------------------------------
      //     // SEARCH
      //     // -------------------------------------------------------

      //     'nameKeywords':
      //         createSearchKeywords(
      //       name,
      //     ),

      //     'categoryKeywords':
      //         createSearchKeywords(
      //       finalCategory,
      //     ),


      //     // -------------------------------------------------------
      //     // LOCATION
      //     // -------------------------------------------------------

      //     'latitude':
      //         currentPosition!.latitude,

      //     'longitude':
      //         currentPosition!.longitude,


      //     // -------------------------------------------------------
      //     // LOCATION MAP
      //     //
      //     // Useful for future map queries.
      //     // -------------------------------------------------------

      //     'location':
      //         GeoPoint(
      //       currentPosition!.latitude,
      //       currentPosition!.longitude,
      //     ),


      //     // -------------------------------------------------------
      //     // STATUS
      //     // -------------------------------------------------------

      //     'isActive':
      //         true,

      //     'role': 'self_employee',


      //     // -------------------------------------------------------
      //     // TIME
      //     // -------------------------------------------------------

      //     'createdAt':
      //         FieldValue.serverTimestamp(),

      //     'updatedAt':
      //         FieldValue.serverTimestamp(),

      //   },

      //   SetOptions(
      //     merge: true,
      //   ),

      // );


//   Future<void> submitSelfEmployee() async {

//   bool hasError = false;

//     // -------------------------------------------------------------
//     // PREVENT DOUBLE SUBMISSION
//     // -------------------------------------------------------------

//     if (isSubmitting) {
//       return;
//     }


//     //_clearError();


//     // -------------------------------------------------------------
//     // NAME
//     // -------------------------------------------------------------

//     final String name =
//         nameController.text
//             .trim();


//     if (name.isEmpty) {

//       showMessage(
//         'Please enter your name',
//         isError: true,
//       );

//       return;
//     }


//     if (name.length < 2) {

//       showMessage(
//         'Please enter a valid name',
//         isError: true,
//       );

//       return;
//     }


//     // -------------------------------------------------------------
//     // MOBILE
//     // -------------------------------------------------------------

//     // final String mobile =
//     //     mobileController.text
//     //         .trim();


//     // if (!_isValidIndianMobile(
//     //   mobile,
//     // )) {

//     //   showMessage(
//     //     'Please enter a valid mobile number',
//     //     isError: true,
//     //   );

//     //   return;
//     // }
    
//   final String mobile =
//       mobileController.text.trim();
// if (mobile.length != 10) {
//   mobileError = true;
//   hasError = true;
// } else {
//   mobileError = false;
// }

//     // -------------------------------------------------------------
//     // OTP VERIFICATION
//     // -------------------------------------------------------------

//     if (!otpVerified) {

//       showMessage(
//         'Please verify your mobile number first',
//         isError: true,
//       );

//       return;
//     }

//     // -------------------------------------------------------------
// // SECONDARY MOBILE
// // -------------------------------------------------------------

// final String secondaryMobile =
//     secondaryPhoneController.text.trim();

// if (secondaryMobile.isEmpty) {
//   showMessage(
//     'Please enter your secondary mobile number',
//     isError: true,
//   );
//   return;
// }

// if (!_isValidIndianMobile(secondaryMobile)) {
//   showMessage(
//     'Please enter a valid secondary mobile number',
//     isError: true,
//   );
//   return;
// }

//     // -------------------------------------------------------------
//     // CATEGORY
//     // -------------------------------------------------------------

//     final String? finalCategory =
//         getFinalCategory();


//     if (finalCategory == null ||
//         finalCategory.isEmpty) {

//       showMessage(
//         'Please select or add a category',
//         isError: true,
//       );

//       return;
//     }

// //     if (selectedCategories.isEmpty) {
// //   setState(() {
// //     categoryError = true;
// //   });

// //   showMessage(
// //     'Please select at least one category',
// //     isError: true,
// //   );

// //   return;
// // }

//   // ============================================================
//   // TERMS & CONDITION / PRIVACY POLICY
//   // ============================================================
//   if (!privacyPolicyAccepted) {
//   setState(() {
//     privacyPolicyError =
//         'Please accept the Privacy Policy and Terms & Conditions.';
//   });

//   showMessage(
//     'Please accept the Privacy Policy and Terms & Conditions.',
//   );

//   return;
// }

//     // -------------------------------------------------------------
//     // START SUBMISSION
//     // -------------------------------------------------------------

//     if (mounted) return;

//       setState(() {

//         isSubmitting = true;

//       });
    
//      if (hasError) {
//     showMessage(
//       'Please complete all required fields.',
//       isError: true,
//     );

//     return;
//   } 



//     try {

//       // ===========================================================
//       // GET CURRENT LOCATION
//       // ===========================================================

//       if (currentPosition == null) {

//         final bool locationSuccess =
//             await getCurrentLocation();


//         if (!locationSuccess) {

//           if (mounted) {

//             setState(() {

//               isSubmitting = false;

//             });
//           }

//           return;
//         }
//       }


//       // -----------------------------------------------------------
//       // SAFETY CHECK
//       // -----------------------------------------------------------

//       if (currentPosition == null) {

//         if (mounted) {

//           setState(() {

//             isSubmitting = false;

//           });
//         }

//         return;
//       }


//       // ===========================================================
//       // CURRENT FIREBASE USER
//       // ===========================================================

//       final User? user =
//           _auth.currentUser;


//       if (user == null) {

//         if (!mounted) {

//           setState(() {

//             isSubmitting = false;

//           });
//         }


//         showMessage(
//           'Authentication failed. Please verify OTP again.',
//           isError: true,
//         );

//         return;
//       }


//        final String? finalExperience =
//         selectedExperience;
//         final String finalCategory =
//     selectedCategories.isNotEmpty
//         ? selectedCategories.first
//         : '';
//       await saveSelfEmployeeToFirestore(
//   position: currentPosition!,
//   user: user,
//   name: name,
//   mobile: mobile,
//   finalCategory: finalCategory,
//   experience: finalExperience,

// );

// await CommonProfileService.saveLogin(
//   uid: user.uid,
//   name: name,
//   mobile: mobile,
//   role: 'self_employee',
//   profilePhotoUrl: profilePhotoUrl,
// );

//       // ===========================================================
//       // SUCCESS
//       // ===========================================================

//       if (!mounted) {
//         return;
//       }


//       setState(() {

//         isSubmitting = false;

//       });


//       showMessage(
//         'SELF EMPLOYEE profile created successfully',
//       );


//       // ===========================================================
//       // RETURN / NEXT SCREEN
//       //
//       // You can later replace this with ScreenHome navigation.
//       // ===========================================================

//       await Future.delayed(
//         const Duration(
//           milliseconds: 500,
//         ),
//       );


//       if (!mounted) {
//         return;
//       }


//       Navigator.of(context)
//           .pop(
//         true,
//       );


//     } on FirebaseException catch (error) {


//       if (!mounted) {
//         return;
//       }


//       setState(() {

//         isSubmitting = false;

//       });


//       showMessage(
//         error.message ??
//             'Unable to save your profile. Please try again.',
//         isError: true,
//       );


//     } catch (error) {


//       if (!mounted) {
//         return;
//       }


//       setState(() {

//         isSubmitting = false;

//       });


//       showMessage(
//         'Something went wrong. Please try again.',
//         isError: true,
//       );

//     }
//   }
// // ===============================================================
  // // GET CURRENT LOCATION
  // // ===============================================================

  // Future<bool> getCurrentLocation() async {

  //   // -------------------------------------------------------------
  //   // PREVENT MULTIPLE LOCATION REQUESTS
  //   // -------------------------------------------------------------

  //   if (isGettingLocation) {
  //     return false;
  //   }


  //   if (mounted) {

  //     setState(() {

  //       isGettingLocation = true;

  //     });
  //   }


  //   try {

  //     // -----------------------------------------------------------
  //     // CHECK LOCATION SERVICE
  //     // -----------------------------------------------------------

  //     bool serviceEnabled =
  //         await Geolocator
  //             .isLocationServiceEnabled();


  //     if (!serviceEnabled) {

  //       showMessage(
  //         'Please turn on your phone location service.',
  //         isError: true,
  //       );


  //       if (mounted) {

  //         setState(() {

  //           isGettingLocation = false;

  //         });
  //       }


  //       return false;
  //     }


  //     // -----------------------------------------------------------
  //     // CHECK PERMISSION
  //     // -----------------------------------------------------------

  //     LocationPermission permission =
  //         await Geolocator
  //             .checkPermission();


  //     // -----------------------------------------------------------
  //     // REQUEST PERMISSION
  //     // -----------------------------------------------------------

  //     if (permission ==
  //         LocationPermission.denied) {

  //       permission =
  //           await Geolocator
  //               .requestPermission();
  //     }


  //     // -----------------------------------------------------------
  //     // PERMISSION DENIED
  //     // -----------------------------------------------------------

  //     if (permission ==
  //         LocationPermission.denied) {

  //       showMessage(
  //         'Location permission is required to show nearby SELF EMPLOYEES.',
  //         isError: true,
  //       );


  //       if (mounted) {

  //         setState(() {

  //           isGettingLocation = false;

  //         });
  //       }


  //       return false;
  //     }


  //     // -----------------------------------------------------------
  //     // PERMISSION PERMANENTLY DENIED
  //     // -----------------------------------------------------------

  //     if (permission ==
  //         LocationPermission.deniedForever) {

  //       showMessage(
  //         'Location permission is permanently denied. Enable it from Settings.',
  //         isError: true,
  //       );


  //       if (mounted) {

  //         setState(() {

  //           isGettingLocation = false;

  //         });
  //       }


  //       return false;
  //     }


  //     // -----------------------------------------------------------
  //     // GET LOCATION
  //     // -----------------------------------------------------------

  //     final Position position =
  //         await Geolocator
  //             .getCurrentPosition(

  //       locationSettings:
  //           const LocationSettings(

  //         accuracy:
  //             LocationAccuracy.high,

  //       ),

  //     );


  //     if (!mounted) {
  //       return false;
  //     }


  //     setState(() {

  //       currentPosition =
  //           position;

  //       isGettingLocation =
  //           false;

  //     });


  //     return true;

  //   } catch (error) {

  //     if (!mounted) {
  //       return false;
  //     }


  //     setState(() {

  //       isGettingLocation =
  //           false;

  //     });


  //     showMessage(
  //       'Unable to get your current location. Please try again.',
  //       isError: true,
  //     );


  //     return false;
  //   }
  // }

  // ===============================================================
  // GET FINAL CATEGORY
  // ===============================================================

  // String? getFinalCategory() {

  //   if (selectedCategory == null) {
  //     return null;
  //   }


  //   if (selectedCategory == 'Other') {

  //     final String customCategory =
  //         customCategoryController.text
  //             .trim();

  //     if (customCategory.isEmpty) {
  //       return null;
  //     }

  //     return customCategory;
  //   }


  //   return selectedCategory;
  // }