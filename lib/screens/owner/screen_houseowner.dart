import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jober_india/jober_indiaScreens.dart/Privacy&Terms/privacy_terms_section.dart';
import 'package:jober_india/jober_indiaScreens.dart/common_profile_services.dart';

import 'package:jober_india/jober_indiaScreens.dart/screen_home.dart';
import 'package:jober_india/l10n/app_localizations.dart';
import 'package:jober_india/screens/location_localization.dart';

class ScreenHouseOwner extends StatefulWidget {
  const ScreenHouseOwner({super.key});

  @override
  State<ScreenHouseOwner> createState() => _ScreenHouseOwnerState();
}

class _ScreenHouseOwnerState extends State<ScreenHouseOwner> {
  // ------------------------------------------------------------
  // CONTROLLERS
  // ------------------------------------------------------------

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController mobileController =
      TextEditingController();

  final TextEditingController otpController =
      TextEditingController();

 static const Color green =
      Color(0xFF138808);

  static const Color darkText =
      Color(0xFF202124);

  static const Color lightFill =
      Color(0xFFF9F9F9);

  bool privacyPolicyAccepted = false;
  String? privacyPolicyError;

  // ------------------------------------------------------------
  // FIREBASE
  // ------------------------------------------------------------

  final FirebaseAuth auth = FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // OTP
  // ------------------------------------------------------------

   String? verificationId;

  bool otpSent = false;
  bool otpVerified = false;

  bool isSendingOtp = false;
  bool isVerifying = false;
  bool isSubmitting = false;

  String otpErrorMessage = '';

  int secondsRemaining = 60;

  Timer? timer;
  // ------------------------------------------------------------
  // ERRORS
  // ------------------------------------------------------------
 // bool isStateDropdownOpen = false;

  bool nameError = false;
  bool mobileError = false;
  bool otpError = false;
  bool genderError = false;

  String? selectedGender;

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    otpController.dispose();
    stateSearchController.dispose();
    districtSearchController.dispose();


    timer?.cancel();

    super.dispose();
  }

   @override
  void initState() {
    super.initState();

     filteredStates = List<String>.from(indiaStates);

  loadDistricts();
  }

   void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xFF176B32),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> sendOTP() async {
    if (isSendingOtp) return;

    final phone =
        mobileController.text.trim();

    if (phone.length != 10) {
      showMessage(AppLocalizations.of(context)!.enteradigitmobilenumber
      );
      return;
    }

    if (otpSent &&
        secondsRemaining > 0) {
      showMessage(
        'Please wait before requesting another OTP.',
      );
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
    });

    try {
      await auth.verifyPhoneNumber(
        phoneNumber: '+91$phone',

        timeout:
            const Duration(seconds: 30),

        // ======================================================
        // AUTOMATIC FIREBASE VERIFICATION
        // ======================================================

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            await auth.signInWithCredential(
              credential,
            );

            if (!mounted) return;

            timer?.cancel();

            setState(() {
              otpVerified = true;
              otpSent = false;
              isSendingOtp = false;
              isVerifying = false;
              otpError = false;
              otpErrorMessage = '';
            });

            otpController.clear();

            showMessage(
              'Mobile number verified successfully.',
            );
          } on FirebaseAuthException catch (e) {
            if (!mounted) return;

            setState(() {
              isSendingOtp = false;
              otpError = true;
              otpErrorMessage =
                  e.message ??
                  'Automatic verification failed.';
            });
          }
        },

        // ======================================================
        // VERIFICATION FAILED
        // ======================================================

        verificationFailed:
            (FirebaseAuthException e) {
          if (!mounted) return;

          timer?.cancel();

          setState(() {
            isSendingOtp = false;
            otpSent = false;
            otpError = true;
          });

          switch (e.code) {
            case 'invalid-phone-number':
              otpErrorMessage =
                  'The mobile number is invalid.';
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
                  e.message ??
                  'Could not send OTP.';
          }

          showMessage(
            otpErrorMessage,
          );
        },

        // ======================================================
        // CODE SENT
        // ======================================================

        codeSent:
            (String id, int? resendToken) {
          if (!mounted) return;

          verificationId = id;

          otpController.clear();

          setState(() {
            otpSent = true;
            otpVerified = false;
            isSendingOtp = false;
            isVerifying = false;
            otpError = false;
            otpErrorMessage = '';
            secondsRemaining = 30;
          });

          startOtpTimer();

          showMessage(
            'OTP sent successfully.',
          );
        },

        // ======================================================
        // AUTO RETRIEVAL TIMEOUT
        // ======================================================

        codeAutoRetrievalTimeout:
            (String id) {
          verificationId = id;
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSendingOtp = false;
        otpError = true;
        otpErrorMessage =
            'Unable to send OTP. Please try again.';
      });

      debugPrint(
        'sendOTP error: $e',
      );
    }
  }
  // ============================================================
  // OTP TIMER
  // ============================================================

   void startOtpTimer() {
    timer?.cancel();

    if (!mounted) return;

    setState(() {
      secondsRemaining = 30;
    });

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (secondsRemaining > 0) {
          setState(() {
            secondsRemaining--;
          });
        } else {
          timer.cancel();
        }
      },
    );
  }

   void onOtpChanged(String value) {
    if (otpError) {
      setState(() {
        otpError = false;
        otpErrorMessage = '';
      });
    }

    if (value.length == 6 &&
        !isVerifying &&
        !otpVerified) {
      verifyOTP();
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> verifyOTP() async {
    if (isVerifying) return;

    final otp =
        otpController.text.trim();

    // ----------------------------------------------------------
    // OTP SESSION
    // ----------------------------------------------------------

    if (verificationId == null ||
        verificationId!.isEmpty) {
      setState(() {
        otpError = true;
        otpErrorMessage =
            'Please send OTP first.';
      });
      return;
    }

    // ----------------------------------------------------------
    // OTP LENGTH
    // ----------------------------------------------------------

    if (otp.length != 6) {
      setState(() {
        otpError = true;
        otpErrorMessage =
            'Enter the complete 6-digit OTP.';
      });
      return;
    }

    // ----------------------------------------------------------
    // EXPIRED OTP
    // ----------------------------------------------------------

    if (secondsRemaining <= 0) {
      setState(() {
        otpError = true;
        otpErrorMessage =
            'OTP expired. Please resend OTP.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isVerifying = true;
      otpError = false;
      otpErrorMessage = '';
    });

    try {
      final credential =
          PhoneAuthProvider.credential(
        verificationId:
            verificationId!,
        smsCode: otp,
      );

      await auth.signInWithCredential(
        credential,
      );

      if (!mounted) return;

      timer?.cancel();

      setState(() {
        isVerifying = false;
        otpVerified = true;
        otpSent = false;
        otpError = false;
        otpErrorMessage = '';
      });

      otpController.clear();

      showMessage(
        'Mobile number verified successfully.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        isVerifying = false;
        otpError = true;
      });

      switch (e.code) {
        case 'invalid-verification-code':
          otpErrorMessage =
              'Incorrect OTP. Please check and try again.';
          break;

        case 'session-expired':
          otpErrorMessage =
              'OTP expired. Please request a new OTP.';
          break;

        case 'invalid-verification-id':
          otpErrorMessage =
              'Verification session expired. Please send OTP again.';
          break;

        case 'credential-already-in-use':
          otpErrorMessage =
              'This mobile number is already registered.';
          break;

        case 'network-request-failed':
          otpErrorMessage =
              'Network error. Check your internet connection.';
          break;

        default:
          otpErrorMessage =
              e.message ??
              'OTP verification failed.';
      }

      setState(() {});

    } catch (e) {
      if (!mounted) return;

      setState(() {
        isVerifying = false;
        otpError = true;
        otpErrorMessage =
            'OTP verification failed. Please try again.';
      });

      debugPrint(
        'verifyOTP error: $e',
      );
    }
  }

   void changeMobileNumber() {
    timer?.cancel();

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


  Future<void> resendOTP() async {
    if (secondsRemaining > 0) {
      showMessage(
        'Please wait ${secondsRemaining}s before requesting another OTP.',
      );
      return;
    }

    await sendOTP();
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

            enabled:
                !isVerifying,

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
                  onPressed:
                      isSendingOtp
                          ? null
                          : resendOTP,

                  child:
                      const Text(
                    'Resend OTP',
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

  Future<void> saveBasicUserToHive() async {
  try {
    final Box userBox =
        Hive.box('userBox');

    // ==========================================================
    // NAME
    // ==========================================================

    await userBox.put(
      'name',
      nameController.text.trim(),
    );

    // ==========================================================
    // MOBILE
    // ==========================================================

    await userBox.put(
      'mobile',
      mobileController.text.trim(),
    );

    // ==========================================================
    // GENDER
    // ==========================================================

    await userBox.put(
      'gender',
      selectedGender ?? '',
    );

      // State
await userBox.put(
  'ambulanceState',
  selectedState!.trim(),
);

// District
await userBox.put(
  'ambulanceDistrict',
  selectedDistrict!.trim(),
);

// Nearest town or city
await userBox.put(
  'ambulanceNearestTown',
  nearestCityController.text.trim(),
);

    // ==========================================================
    // ROLE
    // ==========================================================

    await userBox.put(
      'role',
      'houseOwner',
    );

    // ==========================================================
    // FIREBASE USER UID
    // ==========================================================

    final user =
        FirebaseAuth.instance.currentUser;

    if (user != null) {
      await userBox.put(
        'uid',
        user.uid,
      );
    }

    debugPrint(
      'House Owner profile saved successfully to Hive.',
    );
  } catch (e) {
    debugPrint(
      'Hive save error: $e',
    );
  }
}

  // ============================================================
  // SAVE HOUSE OWNER PROFILE TO FIRESTORE
  // ============================================================

  Future<void> saveProfileToFirestore() async {
    final User? user = auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not authenticated.',
      );
    }

    await firestore
        .collection('houseOwners')
        .doc(user.uid)
        .set(
      {
        'uid': user.uid,

        'name':
            nameController.text.trim(),

        'mobile':
            mobileController.text.trim(),

        'gender':
            selectedGender,

       'state': selectedState!.trim(),

'district': selectedDistrict!.trim(),

'nearestTown':
    nearestCityController.text.trim(),

        'role':
            'houseOwner',

        'updatedAt':
            FieldValue.serverTimestamp(),

        'createdAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }


  bool _isValidIndianMobile(
    String mobile,
  ) {

    return RegExp(
      r'^[6-9][0-9]{9}$',
    ).hasMatch(
      mobile,
    );
  }
  
  Future<void> submitProfile() async {
  if (isSubmitting) return;

  bool hasError = false;
  final String mobile =
      mobileController.text.trim();
  // ============================================================
  // NAME VALIDATION
  // ============================================================

  if (nameController.text.trim().isEmpty) {
    nameError = true;
    hasError = true;
  } else {
    nameError = false;
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
  // MOBILE VALIDATION
  // -------------------------------------------------------------

  mobileError =
      !_isValidIndianMobile(mobile);

  if (mobileError) {
    hasError = true;
  }
  // ============================================================
  // GENDER VALIDATION
  // ============================================================

  if (selectedGender == null) {
    genderError = true;
    hasError = true;
  } else {
    genderError = false;
  }

    // ============================================================
  // TERMS & CONDITION / PRIVACY POLICY
  // ============================================================

 if (!privacyPolicyAccepted) {
    privacyPolicyError =
        'Please accept the Privacy Policy and Terms & Conditions.';

    hasError = true;
  } else {
    privacyPolicyError = null;
  }

  setState(() {});

  if (hasError) {
    return;
  }

  // ============================================================
  // OTP SENT CHECK
  // ============================================================

  // ============================================================
  // OTP VERIFIED CHECK
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

  final User? user = auth.currentUser;

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

  setState(() {
    isSubmitting = true;
  });

  try {
    // ============================================================
    // 1. SAVE LOCALLY FIRST
    // ============================================================

    await saveBasicUserToHive();

    await CommonProfileService.saveLogin(
  uid: user.uid,
  name: nameController.text.trim(),
  mobile: mobileController.text.trim(),
  role: 'houseOwner',
);

    // ============================================================
    // 3. STOP LOADING
    // ============================================================

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    // ============================================================
    // 4. GO TO HOME IMMEDIATELY
    // ============================================================

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ScreenHome(),
      ),
      (route) => false,
    );

    // ============================================================
    // 5. SAVE TO FIRESTORE IN BACKGROUND
    // ============================================================

    try {
      await saveProfileToFirestore();

      debugPrint(
        'House owner Firestore sync successful.',
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'House owner Firebase sync failed: '
        '${e.code} ${e.message}',
      );
    } catch (e) {
      debugPrint(
        'House owner Firestore sync failed: $e',
      );
    }
  } catch (e) {
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
  // SECTION TITLE
  // ============================================================

  Widget sectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
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
      backgroundColor:
          const Color(0xFFFFFBFF),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFFFFBFF),

        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },

          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
            size: 30,
          ),
        ),

        title: const Text(
          'House Owner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF171717),
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            35,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [

              const SizedBox(
                height: 15,
              ),

              // ------------------------------------------------
              // HEADER
              // ------------------------------------------------

              const Text(
                'Create your profile',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF171717),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'Enter your details to continue.',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      Color(0xFF9E9E9E),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // ------------------------------------------------
              // NAME
              // ------------------------------------------------

              sectionTitle(
                'Full Name',
              ),

              const SizedBox(
                height: 8,
              ),

              TextField(
                controller:
                    nameController,

                textInputAction:
                    TextInputAction.next,

                onChanged: (value) {
                  if (value
                          .trim()
                          .isNotEmpty &&
                      nameError) {
                    setState(() {
                      nameError = false;
                    });
                  }
                },

                decoration:
                    fieldDecoration(
                  hintText:
                      'Enter your name',
                  hasError:
                      nameError,
                ),
              ),

              if (nameError)
                const Padding(
                  padding:
                      EdgeInsets.only(
                    top: 5,
                    left: 5,
                  ),
                  child: Text(
                    'Please enter your name.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(
                height: 20,
              ),

              // ------------------------------------------------
              // MOBILE
              // ------------------------------------------------
               sectionTitle('Mobile Number'),
              const SizedBox(height: 6),
              mobileSection(),

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

                    child: Text( AppLocalizations.of(context)!.enteradigitmobilenumber,

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

              const SizedBox(
                height: 25,
              ),

              // ------------------------------------------------
              // GENDER
              // ------------------------------------------------

              sectionTitle(
                'Gender',
              ),

              const SizedBox(
                height: 10,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        _genderButton(
                      title: 'Male',
                      value: 'Male',
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                        _genderButton(
                      title: 'Female',
                      value:
                          'Female',
                    ),
                  ),
                ],
              ),

              if (genderError)
                const Padding(
                  padding:
                      EdgeInsets.only(
                    top: 6,
                    left: 5,
                  ),
                  child: Text(
                    'Please select your gender.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),

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
              // ------------------------------------------------
              // SUBMIT BUTTON
              // ------------------------------------------------

              SizedBox(
                height: 58,

                child:
                    ElevatedButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : submitProfile,

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF159B16,
                    ),

                    foregroundColor:
                        Colors.white,

                    disabledBackgroundColor:
                        Colors.grey.shade400,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),

                    elevation: 0,
                  ),

                  child: isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Profile',
                          style:
                              TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),
            ],
          ),
        ),
      ),
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
          genderError = false;
        });
      },

      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 200,
        ),

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

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            const SizedBox(width: 8),

            Text(title,style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selected ? const Color(0xFF159B16):const Color(0xFF202124)
              ),
            ),
          ],
        ),
      ),
    );
  }
}
