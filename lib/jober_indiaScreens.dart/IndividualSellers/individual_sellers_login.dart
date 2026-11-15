import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jober_india/jober_indiaScreens.dart/common_profile_services.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_camera_capture.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_home.dart';
import 'package:jober_india/l10n/app_localizations.dart';
import 'package:jober_india/screens/location_localization.dart';

import '../Privacy&Terms/privacy_terms_section.dart';


// ===============================================================
// SCREEN SELF BUSINESS
// ===============================================================

class ScreenSelfBusinessLogin extends StatefulWidget {
  const ScreenSelfBusinessLogin({
    super.key,
  });

  @override
  State<ScreenSelfBusinessLogin> createState() =>
      _ScreenSelfBusinessLoginState();
}


// ===============================================================
// STATE
// ===============================================================

class _ScreenSelfBusinessLoginState
    extends State<ScreenSelfBusinessLogin> {

  // =============================================================
  // COLORS
  // =============================================================

  static const Color black =
      Colors.black;

  static const Color background =
      Color(0xFFF7F8F7);

  static const Color borderColor =
      Color(0xFFE0E0E0);

  static const Color green =
      Color(0xFF138808);

  static const Color darkText =
      Color(0xFF202124);

  static const Color lightFill =
      Color(0xFFF9F9F9);
  // =============================================================
  // FORM KEY
  // =============================================================

  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();


  // =============================================================
  // TEXT CONTROLLERS
  // =============================================================

  final TextEditingController
      usernameController =
      TextEditingController();

  final TextEditingController
      selfBusinessNameController =
      TextEditingController();

  final TextEditingController
      mobileController =
      TextEditingController();

  final TextEditingController secondaryPhoneController =
    TextEditingController();

  final TextEditingController categorySearchController =
      TextEditingController();

  final TextEditingController customCategoryController =
      TextEditingController();

  final TextEditingController descriptionController =
    TextEditingController();


  // =============================================================
  // OTP CONTROLLERS
  // =============================================================

  final TextEditingController otpController =
      TextEditingController();

  // =============================================================
  // OTP FOCUS NODES
  // =============================================================

  final FocusNode otpFocus =
      FocusNode();

  final FocusNode otp2Focus =
      FocusNode();

  final FocusNode otp3Focus =
      FocusNode();

  final FocusNode otp4Focus =
      FocusNode();

  final FocusNode otp5Focus =
      FocusNode();

  final FocusNode otp6Focus =
      FocusNode();


  // =============================================================
  // FIREBASE
  // =============================================================

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  bool privacyPolicyAccepted = false;
  String? privacyPolicyError;
  // ============================================================
  // SHOP TIMINGS
  // ============================================================

  TimeOfDay? openingTime;
  TimeOfDay? closingTime;
  bool isOpen24Hours = false;


bool usernameError = false;
bool companyNameError = false;
bool mobileError = false;
bool secondaryMobileError = false;
bool categoryError = false;

String? mobileErrorMessage;
File? profilePhoto;

String? profilePhotoUrl;

bool isUploadingPhoto = false;

double photoUploadProgress = 0.0;

Future<void>? photoUploadFuture;

final ImagePicker _imagePicker = ImagePicker();

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

  // =============================================================
  // CATEGORY VARIABLES
  // =============================================================
  final List<String> customCategories = [];

  final List<String> selectedCategories = [];

  List<String> filteredCategories = [];

  String? selectedCategory;

  bool isCustomCategory = false;
  bool isCategoryDropdownOpen = false;

  final List<String>
      businessCategories = [

   'Fish Stall',
'Meat Stall',
'Vegetable Stall',
'Juice Stall',
'Tea/Coffee Stall',
'Fast Food Stall',
'Home Made Food',
'Pickle Business',
'Cake Home made',
'Milk/Milk Products sales',
'Tailoring',
'Beautition',
'Mobile Repairing',
'Electronics Repairing',
'Computer Repairing'

  ];


String secondaryMobileErrorMessage = '';
  // =============================================================
  // INIT STATE
  // =============================================================
 
  @override
  void initState() {

    super.initState();

    filteredCategories =
        List<String>.from(
      businessCategories,
    );

     filteredStates = List<String>.from(indiaStates);

  loadDistricts();
  }

List<String> get allCategories {
  final List<String> result = [];

  for (final category in businessCategories) {
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


// =============================================================
// FINAL BUSINESS CATEGORIES
// =============================================================

List<String> get finalBusinessCategories {
  final List<String> result =
      List<String>.from(selectedCategories);

  if (isCustomCategory) {
    final String custom =
        customCategoryController.text.trim();

    if (custom.isNotEmpty &&
        !result.contains(custom)) {
      result.add(custom);
    }
  }

  return result;
}

  // =============================================================
  // FILTER CATEGORIES
  // =============================================================

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

              hintText:'Enter Your Business Category',

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

  // =============================================================
  // SELECT CATEGORY
  // =============================================================

  void selectCategory(
    String category,
  ) {

    setState(() {

      selectedCategory =
          category;

      isCustomCategory =
          false;

      categoryError =
          false;

      customCategoryController
          .clear();
    });
  }


  // =============================================================
  // ENABLE CUSTOM CATEGORY
  // =============================================================

  void enableCustomCategory() {

    setState(() {

      selectedCategory =
          null;

      isCustomCategory =
          true;

      categoryError =
          false;
    });
  }


  // =============================================================
  // DISABLE CUSTOM CATEGORY
  // =============================================================

  void disableCustomCategory() {

    setState(() {

      isCustomCategory =
          false;

      customCategoryController
          .clear();
    });
  }

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {

    timer?.cancel();
    usernameController.dispose();
    selfBusinessNameController.dispose();
    mobileController.dispose();
    categorySearchController.dispose();
    secondaryPhoneController.dispose();
    customCategoryController.dispose();
    otpController.dispose();
    otpFocus.dispose();
    descriptionController.dispose();
      stateSearchController.dispose();
    districtSearchController.dispose();


    super.dispose();
  }


  // ==============================================================
  // SEND OTP
  // ===============================================================

Future<void> sendOTP({bool isResend = false}) async {
  if (isSendingOtp || isVerifying) return;

  final phone = mobileController.text.trim();

  if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
    showMessage(AppLocalizations.of(context)!.enteradigitmobilenumber,
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
  
Future<void> saveSelfBusinessToHive({
  required String uid,
  required String username,
  required String companyName,
  required String mobile,
  required String secondaryMobile,
  required List<String> categories,
  String? openingTime,
  String? closingTime,
  required bool isOpen24Hours,
  String? description,
  required bool privacyPolicyAccepted,
}) async {
  final box =
      await Hive.openBox(
    'selfBusinessProfiles',
  );

  await box.put(
    'currentUid',
    uid,
  );

  await box.put(
    'uid',
    uid,
  );

  await box.put(
    'username',
    username,
  );

  await box.put(
    'companyName',
    companyName,
  );

  await box.put(
    'mobile',
    mobile,
  );

  await box.put(
    'secondaryMobile',
    secondaryMobile,
  );

  await box.put(
  'state',
  selectedState!.trim(),
);

await box.put(
  'district',
  selectedDistrict!.trim(),
);

await box.put(
  'nearestTown',
  nearestCityController.text.trim(),
);

  await box.put(
    'categories',
    List<String>.from(categories),
  );

  await box.put(
    'category',
    categories.isNotEmpty
        ? categories.first
        : '',
  );

  await box.put(
    'isCustomCategory',
    isCustomCategory,
  );

  await box.put(
    'isOpen24Hours',
    isOpen24Hours,
  );

  await box.put(
    'openingTime',
    isOpen24Hours
        ? null
        : openingTime,
  );

  await box.put(
    'closingTime',
    isOpen24Hours
        ? null
        : closingTime,
  );

  await box.put(
    'description',
    description ?? '',
  );

  await box.put(
    'profilePhotoUrl',
    profilePhotoUrl ?? '',
  );

  await box.put(
    'privacyPolicyAccepted',
    privacyPolicyAccepted,
  );

  await box.put(
    'role',
    'individual_sellers',
  );

  await box.put(
    'registered',
    true,
  );
}

Future<void> saveSelfBusinessToFirestore({
  required User user,
  required String username,
  required String companyName,
  required String mobile,
  required String secondaryMobile,
  required List<String> categories,
  String? openingTime,
  String? closingTime,
  required bool isOpen24Hours,
  String? description,
  required bool privacyPolicyAccepted,
}) async {
  final DocumentReference<Map<String, dynamic>>
      businessRef = firestore
          .collection('selfBusinesses')
          .doc(user.uid);

 final Map<String, dynamic> data = {
  'uid': user.uid,

  'userId': user.uid,

  'username': username,

  'companyName': companyName,

  'mobileNumber': mobile,

  'mobile': mobile,

  'secondaryMobileNumber':
      secondaryMobile,

  'secondaryMobile':
      secondaryMobile,

'state': selectedState!.trim(),
'district': selectedDistrict!.trim(),
'nearestTown': nearestCityController.text.trim(),

  'categories': categories,

  'category':
      categories.isNotEmpty
          ? categories.first
          : '',

  'isCustomCategory':
      isCustomCategory,

  'customCategories':
    List<String>.from(customCategories),

      'privacyPolicyAccepted':
    privacyPolicyAccepted,

  // ==========================================================
  // SHOP TIMING
  // ==========================================================

  'isOpen24Hours':
      isOpen24Hours,

  'openingTime':
      isOpen24Hours
          ? null
          : openingTime,

  'closingTime':
      isOpen24Hours
          ? null
          : closingTime,

  // ==========================================================
  // DESCRIPTION
  // ==========================================================

  'description':
      description ?? '',

  'isActive': true,

  'role': 'individual_sellers',

  if (profilePhotoUrl != null &&
      profilePhotoUrl!.isNotEmpty)
    'profilePhotoUrl':
        profilePhotoUrl,

  'updatedAt':
      FieldValue.serverTimestamp(),
};

  // ------------------------------------------------------------
  // Only create createdAt when the document is new.
  // ------------------------------------------------------------

  final DocumentSnapshot<Map<String, dynamic>>
      existing =
      await businessRef.get();

  if (!existing.exists) {
    data['createdAt'] =
        FieldValue.serverTimestamp();
  }

  await businessRef.set(
    data,
    SetOptions(
      merge: true,
    ),
  );
}
  // =============================================================
  // SUBMIT PROFILE
  // =============================================================

Future<void> submitProfile() async {
  if (isSubmitting) return;

  FocusScope.of(context).unfocus();

  bool hasError = false;

  // ==========================================================
  // CLEAR PREVIOUS ERRORS
  // ==========================================================

  setState(() {
    usernameError = false;
    companyNameError = false;
    mobileError = false;
    secondaryMobileError = false;
    categoryError = false;
    stateError = '';

    privacyPolicyError = null;
    mobileErrorMessage = null;
    secondaryMobileErrorMessage = '';
  });

  // ==========================================================
  // 1. USERNAME
  // ==========================================================

  final String username =
      usernameController.text.trim();

  if (username.isEmpty) {
    usernameError = true;
    hasError = true;
  }

  // ==========================================================
  // 2. SELF COMPANY NAME
  // ==========================================================

  final String companyName =
      selfBusinessNameController.text.trim();

  if (companyName.isEmpty) {
    companyNameError = true;
    hasError = true;
  }

  // ==========================================================
  // 3. MOBILE NUMBER + OTP
  // ==========================================================

  final String mobile =
      mobileController.text.trim();

  if (mobile.length != 10) {
    mobileError = true;
    mobileErrorMessage =AppLocalizations.of(context)!.enteradigitmobilenumber;
    hasError = true;
  } else if (!otpVerified) {
    mobileError = true;
    mobileErrorMessage =
        'Please verify your mobile number.';
    hasError = true;
  }

  // ==========================================================
  // 4. SECONDARY MOBILE NUMBER
  // ==========================================================

  final String secondaryMobile =
      secondaryPhoneController.text.trim();

  if (secondaryMobile.length != 10) {
    secondaryMobileError = true;
    secondaryMobileErrorMessage =
        'Please enter a valid 10-digit secondary mobile number.';
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

  // ==========================================================
  // 5. BUSINESS CATEGORY
  // ==========================================================

  final List<String> categories =
      List<String>.from(finalBusinessCategories);

  if (categories.isEmpty) {
    categoryError = true;
    hasError = true;
  }

  // ==========================================================
  // SHOP TIMING
  // OPTIONAL
  //
  // If one time is selected, both must be selected.
  // ==========================================================

  if (!isOpen24Hours) {
    final bool onlyOpeningSelected =
        openingTime != null &&
        closingTime == null;

    final bool onlyClosingSelected =
        openingTime == null &&
        closingTime != null;

    if (onlyOpeningSelected ||
        onlyClosingSelected) {
      hasError = true;

      showMessage(
        'Please select both opening and closing time.',
      );
    }
  }

  // ==========================================================
  // 6. PRIVACY POLICY + TERMS
  // ==========================================================

  if (!privacyPolicyAccepted) {
    privacyPolicyError =
        'Please accept the Privacy Policy and Terms & Conditions.';
    hasError = true;
  }

  // ==========================================================
  // UPDATE UI WITH ERRORS
  // ==========================================================

  if (mounted) {
    setState(() {});
  }

  // Stop if any validation failed.
  if (hasError) {
    return;
  }

  // ==========================================================
  // START SUBMIT
  // ==========================================================

  if (mounted) {
    setState(() {
      isSubmitting = true;
    });
  }

  try {
    // ========================================================
    // CURRENT FIREBASE USER
    // ========================================================

    final User? user =
        auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'User is not authenticated.',
      );
    }

    // ========================================================
    // WAIT FOR PHOTO UPLOAD IF RUNNING
    // ========================================================

    if (isUploadingPhoto &&
        photoUploadFuture != null) {
      try {
        await photoUploadFuture;
      } catch (e) {
        debugPrint(
          'Profile photo upload error: $e',
        );
      }
    }

    // ========================================================
    // DESCRIPTION
    // ========================================================

    final String description =
        descriptionController.text.trim();

    // ========================================================
    // OPENING / CLOSING TIME
    // ========================================================

    final String? openingTimeString =
        openingTime == null
            ? null
            : timeToString(openingTime!);

    final String? closingTimeString =
        closingTime == null
            ? null
            : timeToString(closingTime!);

    // ========================================================
    // SAVE TO HIVE FIRST
    //
    // PRIVACY POLICY IS ALSO SAVED HERE.
    // ========================================================

    await saveSelfBusinessToHive(
      uid: user.uid,
      username: username,
      companyName: companyName,
      mobile: mobile,
      secondaryMobile: secondaryMobile,
      categories: categories,
      openingTime: openingTimeString,
      closingTime: closingTimeString,
      isOpen24Hours: isOpen24Hours,
      description: description,

      // IMPORTANT
      privacyPolicyAccepted:
          privacyPolicyAccepted,
    );

    // ========================================================
    // SAVE COMMON LOGIN INFORMATION
    // ========================================================

    await CommonProfileService.saveLogin(
      uid: user.uid,
      name: username,
      mobile: mobile,
      role: 'individual_sellers',
    );

    // ========================================================
    // HIVE SAVED SUCCESSFULLY
    // NOW ALLOW USER TO GO HOME
    // ========================================================

    if (mounted) {
      setState(() {
        isSubmitting = false;
      });
    }

    // ========================================================
    // NAVIGATE TO HOME
    // ========================================================

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const ScreenHome(),
        ),
        (route) => false,
      );
    }

    // ========================================================
    // FIRESTORE BACKGROUND SAVE
    //
    // WAIT 3 SECONDS AFTER NAVIGATION.
    // PRIVACY POLICY IS ALSO SAVED HERE.
    // ========================================================

    Future.delayed(
      const Duration(seconds: 3),
      () async {
        try {
          await saveSelfBusinessToFirestore(
            user: user,
            username: username,
            companyName: companyName,
            mobile: mobile,
            secondaryMobile: secondaryMobile,
            categories: categories,
            openingTime: openingTimeString,
            closingTime: closingTimeString,
            isOpen24Hours: isOpen24Hours,
            description: description,

            // IMPORTANT
            privacyPolicyAccepted:
                privacyPolicyAccepted,
          );

          debugPrint(
            'Individual Sellers Firestore save successful.',
          );
        } catch (e) {
          debugPrint(
            'Individual Sellers Firestore background save failed: $e',
          );
        }
      },
    );
  }

  // ==========================================================
  // HIVE ERROR
  // ==========================================================

  on HiveError catch (e) {
    debugPrint(
      'Individual Sellers Hive error: $e',
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    showMessage(
      'Could not save the business profile locally.',
    );
  }

  // ==========================================================
  // FIREBASE AUTH ERROR
  // ==========================================================

  on FirebaseAuthException catch (e) {
    debugPrint(
      'Individual Sellers Auth error: $e',
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    showMessage(
      'Authentication failed. Please try again.',
    );
  }

  // ==========================================================
  // OTHER ERROR
  // ==========================================================

  catch (e) {
    debugPrint(
      'Individual Sellers submit error: $e',
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    showMessage(
      'Something went wrong. Please try again.',
    );
  }
}

  // =============================================================
  // SHOW MESSAGE
  // =============================================================

  void showMessage(
    String message,
  ) {

    if (!mounted) {return;}

    ScaffoldMessenger
        .of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger
        .of(context)
        .showSnackBar(

      SnackBar(

        content:
            Text(message),

        behavior:
            SnackBarBehavior
                .floating,

        duration:
            const Duration(
          seconds: 3,
        ),
      ),
    );
  }

     Widget mobileSection() {

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
      mobileErrorMessage = null;
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
  if (mobileError &&
    mobileErrorMessage != null)
  Padding(
    padding:
        const EdgeInsets.only(
      left: 12,
      top: 5,
    ),
    child: Text(
      mobileErrorMessage!,
      style: const TextStyle(
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
  
   Widget categorySection() {
    final categories =
        filteredCategories;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

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

                    categoryError = false;
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
                                    'Select your Business categories',
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
                        child: categories.isEmpty
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
                                    categories.length,
                                itemBuilder:
                                    (
                                  context,
                                  index,
                                ) {
                                  final category =
                                      categories[
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


 Future<void> pickProfilePhoto() async {
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

  if (source == null) return;

  File? selectedFile;

  if (source == ImageSource.camera) {
    if (!mounted) return;

    final File? capturedFile =
        await Navigator.of(context).push<File>(
      MaterialPageRoute(
        builder: (_) =>
            const ScreenCameraCapture(),
      ),
    );

    if (!mounted) return;

    selectedFile = capturedFile;
  } else {
    final XFile? pickedFile =
        await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (pickedFile != null) {
      selectedFile = File(
        pickedFile.path,
      );
    }
  }

  if (selectedFile == null ||
      !mounted) {
    return;
  }

  setState(() {
    profilePhoto = selectedFile;
    isUploadingPhoto = true;
    photoUploadProgress = 0.0;
  });

  // ------------------------------------------------------------
  // START PHOTO UPLOAD IN BACKGROUND
  // ------------------------------------------------------------

  photoUploadFuture =
      _uploadProfilePhotoInBackground(
    selectedFile,
  );
}

  Future<void> _uploadProfilePhotoInBackground(
  File file,
) async {
  final User? user = auth.currentUser;

  if (user == null) {
    if (mounted) {
      setState(() {
        isUploadingPhoto = false;
        photoUploadProgress = 0.0;
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

        final int total =
            snapshot.totalBytes;

        if (total > 0) {
          setState(() {
            photoUploadProgress =
                snapshot.bytesTransferred /
                    total;
          });
        }
      },
    );

    await uploadTask;

    final String url =
        await storageRef.getDownloadURL();

    if (!mounted) return;

    setState(() {
      profilePhotoUrl = url;
      isUploadingPhoto = false;
      photoUploadProgress = 1.0;
    });

    showMessage(
      'Profile photo uploaded.',
    );
  } catch (e) {
    debugPrint(
      'Individual Sellers photo upload error: $e',
    );

    if (!mounted) return;

    setState(() {
      isUploadingPhoto = false;
      photoUploadProgress = 0.0;
      profilePhotoUrl = null;
    });

    // ----------------------------------------------------------
    // PHOTO IS OPTIONAL
    // Registration can continue.
    // ----------------------------------------------------------

    showMessage(
      'Photo upload failed. You can continue without a photo.',
    );
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
 // =============================================================
  // BUILD
  // =============================================================
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
          background,

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
                text: 'Individual Sellers',
                style:
                    TextStyle(
                  color:
                      Color(0xFF08744F),
                ),
              ),

              TextSpan(
                text: AppLocalizations.of(context)!.registration,
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

          key: formKey,

          child: SingleChildScrollView(

            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior
                    .onDrag,

            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              30,
            ),

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const SizedBox(
                  height: 8,
                ),

                const Center(

                  child: Text(

                    'Add your business details',

                    textAlign:
                        TextAlign.center,

                    style: TextStyle(

                      fontSize: 14,

                      color:
                          Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),


                // ===============================================
                // USERNAME
                // ===============================================

                buildSectionTitle(
                  'Username',
                  required: true,
                ),

                const SizedBox(
                  height: 8,
                ),

TextField(
  controller: usernameController,

  textCapitalization:
      TextCapitalization.words,

  textInputAction:
      TextInputAction.next,

  onChanged: (_) {
    if (usernameError) {
      setState(() {
        usernameError = false;
      });
    }
  },

  decoration: buildInputDecoration(
    hint: 'Enter your name',
    icon: Icons.person_outline,
    hasError: usernameError,
  ),
),

if (usernameError)
  buildErrorText(
    'Please enter your name.',
  ),

                const SizedBox(
                  height: 15,
                ),


                // ===============================================
                // COMPANY NAME
                // ===============================================

                buildSectionTitle(
                  'Self Company Name',
                  required: true,
                ),

                const SizedBox(
                  height: 8,
                ),

               TextField(
  controller: selfBusinessNameController,

  textCapitalization:
      TextCapitalization.words,

  onChanged: (_) {
    if (companyNameError) {
      setState(() {
        companyNameError = false;
      });
    }
  },

  decoration:
      buildInputDecoration(
    hint:
        'Enter company or business name',
    icon:
        Icons.business_outlined,
    hasError:
        companyNameError,
  ),
),

if (companyNameError)
  buildErrorText(
    'Company name is required',
  ),

                const SizedBox(
                  height: 15,
                ),


                sectionTitle('Mobile Number'),
              const SizedBox(height: 6),

                 mobileSection(),

                otpSection(),

                const SizedBox(
                  height: 15,
                ),
                
                secondaryMobileSection(),

              const SizedBox(height: 15),
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
                // ===============================================
                // BUSINESS CATEGORY
                // ===============================================

                buildSectionTitle(
                  'Individual Sellers Category',
                  required: true,
                ),

                const SizedBox(
                  height: 8,
                ),

              categorySection(),
                 const SizedBox(height: 15),

                 shopTimingSection(),
              const SizedBox(height: 20),
               descriptionSection(),
              const SizedBox(height: 20),

               
              _profilePhotoSection(),

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

                // ===============================================
                // SUBMIT BUTTON
                // ===============================================

                SizedBox(

                  width:
                      double.infinity,

                  height:
                      56,

                  child:
                      ElevatedButton(

                    onPressed:
                        isSubmitting
                            ? null
                            : submitProfile,

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

                        isSubmitting

                            ? const SizedBox(

                                width: 24,

                                height: 24,

                                child:
                                    CircularProgressIndicator(

                                  strokeWidth:
                                      2.5,

                                  color:
                                      Colors.white,
                                ),
                              )

                            : const Row(

                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,

                                children: [

                                  Icon(
                                    Icons
                                        .check_circle_outline,
                                  ),

                                  SizedBox(
                                    width: 10,
                                  ),

                                  Text(

                                    'SUBMIT BUSINESS',

                                    style:
                                        TextStyle(

                                      
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // =============================================================
  // SECTION TITLE
  // =============================================================

  Widget buildSectionTitle(
    String title, {

    bool required = false,

    bool optional = false,

  }) {

    return Row(

      children: [

        Text(

          title,

          style:
              const TextStyle(

            fontSize:
                16,

            fontWeight:
                FontWeight.w700,

            color:
                black,
          ),
        ),

        const SizedBox(
          width: 5,
        ),

        if (optional)

          const Text(

            '(Optional)',

            style:
                TextStyle(

              color:
                  Colors.grey,

              fontSize:
                  13,
            ),
          ),
      ],
    );
  }


  // =============================================================
  // INPUT DECORATION
  // =============================================================

  InputDecoration
      buildInputDecoration({

    required String hint,

    required IconData icon,

    bool hasError = false,

    String? counterText,

    Widget? suffixIcon,

  }) {

    return InputDecoration(

      hintText:
          hint,

      hintStyle:
          const TextStyle(
        color:
            Colors.grey,
      ),

      prefixIcon:
          Icon(
        icon,
        color:
            black,
      ),

      suffixIcon:
          suffixIcon,

      counterText:
          counterText,

      filled:
          true,

      fillColor:
          Colors.white,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),

      border:
          OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        borderSide:
            BorderSide(
          color:
              borderColor,
        ),
      ),

      enabledBorder:
          OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        borderSide:
            BorderSide(

          color:
              hasError
                  ? Colors.red
                  : borderColor,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        borderSide:
            BorderSide(

          color:
              hasError
                  ? Colors.red
                  : green,

          width:
              1.5,
        ),
      ),
    );
  }


  // =============================================================
  // ERROR TEXT
  // =============================================================

  Widget buildErrorText(
    String message,
  ) {

    return Padding(

      padding:
          const EdgeInsets.only(
        top: 6,
        left: 4,
      ),

      child:
          Text(

        message,

        style:
            const TextStyle(

          color:
              Colors.red,

          fontSize:
              12,

          fontWeight:
              FontWeight.w500,
        ),
      ),
    );
  }
}
