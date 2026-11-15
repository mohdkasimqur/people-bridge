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
import 'package:jober_india/jober_indiaScreens.dart/Privacy&Terms/privacy_terms_section.dart';
import 'package:jober_india/jober_indiaScreens.dart/TaxiCommercial/screen_taxicomrcial_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/common_profile_services.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_camera_capture.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_home.dart';
import 'package:jober_india/l10n/app_localizations.dart';
import 'package:jober_india/screens/location_localization.dart';


class AmbulanceLocation {
  final String placeName;
  final double? latitude;
  final double? longitude;

  AmbulanceLocation({
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

  factory AmbulanceLocation.fromMap(
    Map<String, dynamic> map,
  ) {
    return AmbulanceLocation(
      placeName: map['placeName']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
class AmbulanceCategory {
  final String? id;
  final String name;
  final String image;
  final String? imageUrl;
  final bool isUserAdded;

  const AmbulanceCategory({
    this.id,
    required this.name,
    this.image = '',
    this.imageUrl,
    this.isUserAdded = false,
  });
}

class AmbulanceLogin extends StatefulWidget {
  const AmbulanceLogin({super.key});

  @override
  State<AmbulanceLogin> createState() => _AmbulanceLoginState();
}

class _AmbulanceLoginState extends State<AmbulanceLogin> {
 final TextEditingController secondaryPhoneController =
      TextEditingController();
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
 
 
  final TextEditingController vehicleNumberController =
    TextEditingController();

  final TextEditingController _shopLocationController =
    TextEditingController();

 
String? vehicleNumberError;
   final FirebaseAuth auth = FirebaseAuth.instance;
  
   bool locationError = false;

AmbulanceLocation? currentLocation;

bool isGettingLocation = false;
bool isSearchingLocation = false;

int _locationRequestId = 0;

   File? profilePhoto;
  String? profilePhotoUrl;
bool isUploadingPhoto = false;
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

  int secondsRemaining = 30;

  Timer? timer;

  String? mobileErrorMessage;
  bool mobileError = false;

    String? nameError;
    String? secondaryMobileError;

  bool privacyPolicyAccepted = false;

String? privacyPolicyError;

 @override
void initState() {
  super.initState();

   filteredStates = List<String>.from(indiaStates);

  loadDistricts();

  stateSearchController.addListener(() {
    filterStates(stateSearchController.text);
  });
}
  
      void showMessage(String message,{
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error
           ? Colors.red: const Color(0xFF176B32),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }
  
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

      forceResendingToken: isResend ? resendToken : null,

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
        if (mobileError)
   Padding(
    padding: EdgeInsets.only(
      left: 12,
      top: 5,
    ),
    child: Text(AppLocalizations.of(context)!.enteradigitmobilenumber,
      style: TextStyle(
        color: Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),

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

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(
        color: hasError
            ? Colors.red
            : const Color(0xFFD5D5D5),
        width: hasError ? 2 : 1.5,
      ),
    ),

    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(
        color: hasError
            ? Colors.red
            : const Color(0xFF16803C),
        width: 2,
      ),
    ),

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

      TextFormField(
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

  decoration: fieldDecoration(
    hintText: 'Enter secondary mobile number',
    icon: Icons.phone_android_outlined,
  ).copyWith(
    counterText: '',
    errorText: secondaryMobileError,
  ),
),

      const SizedBox(height: 5),

      const Text(
        'You can use same number,if another number is not available.',
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

  Widget locationSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
         Text(AppLocalizations.of(context)!.ambulanceParkedLocation,
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
  onPressed: () {
    _locationRequestId++;

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
  currentLocation = AmbulanceLocation(
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

  final GoogleMapsLocationExtractor extractor =
      GoogleMapsLocationExtractor();

  try {
    final GoogleMapsLocation location =
        await extractor.extract(value);

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
    if (location.placeName != null &&
        location.placeName!.trim().isNotEmpty) {
      return location.placeName!.trim();
    }

    if (location.address != null &&
        location.address!.trim().isNotEmpty) {
      return location.address!.trim();
    }

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

    final expectedState =
        _normalizeLocationName(selectedState!);

   
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

 Future<void> _getCurrentLocation() async {
  if (isGettingLocation) return;

  final int requestId = ++_locationRequestId;

  if (!mounted) return;

  setState(() {
    isGettingLocation = true;
  });

  try {
 
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

    final position =
        await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    if (!mounted || requestId != _locationRequestId) return;

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
  
    String placeName =
        '${position.latitude}, ${position.longitude}';

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

    if (!mounted || requestId != _locationRequestId) return;

    setState(() {
  currentLocation = AmbulanceLocation(
    placeName: placeName,
    latitude: position.latitude,
    longitude: position.longitude,
  );

  locationError = false;
});

    showMessage(
      'Ambulance location added.',
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

 Future<void> pickProfilePhoto() async {
  final NavigatorState navigator = Navigator.of(context);

  final ImageSource? source =
      await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) {
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
                  sheetContext,
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
                  sheetContext,
                  ImageSource.gallery,
                );
              },
            ),
          ],
        ),
      );
    },
  );

  if (!mounted || source == null) return;

  File? selectedFile;


  if (source == ImageSource.camera) {
    selectedFile = await navigator.push<File>(
      MaterialPageRoute(
        builder: (_) => const ScreenCameraCapture(),
      ),
    );

    if (!mounted) return;
  }


  else {
    final XFile? pickedFile =
        await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (!mounted) return;

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

  Widget _vehicleNumberField() {
  final bool hasError =
      vehicleNumberError != null &&
      vehicleNumberError!.isNotEmpty;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD84D),
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

  Future<void> saveBasicAmbulanceToHive() async {
  try {
    final Box settingsBox = Hive.box('settings');

    await settingsBox.put(
      'ambulanceUid',
      auth.currentUser?.uid ?? '',
    );

    await settingsBox.put(
      'ambulanceName',
      nameController.text.trim(),
    );

    await settingsBox.put(
      'ambulanceMobile',
      mobileController.text.trim(),
    );

    await settingsBox.put(
      'ambulanceSecondaryMobile',
      secondaryPhoneController.text.trim(),
    );

await settingsBox.put(
  'ambulanceState',
  selectedState!.trim(),
);

await settingsBox.put(
  'ambulanceDistrict',
  selectedDistrict!.trim(),
);

await settingsBox.put(
  'ambulanceNearestTown',
  nearestCityController.text.trim(),
);

    await settingsBox.put(
      'ambulanceRole',
      'ambulance',
    );

    await settingsBox.put(
      'ambulanceVehicleNumber',
      vehicleNumberController.text.trim(),
    );

    if (currentLocation != null) {
      await settingsBox.put(
        'ambulanceLocation',
        currentLocation!.toMap(),
      );
    }

    await settingsBox.put(
      'ambulanceProfilePhotoUrl',
      profilePhotoUrl ?? '',
    );

    debugPrint(
      'Ambulance basic profile saved to Hive.',
    );
  } catch (e) {
    debugPrint(
      'Error saving ambulance profile to Hive: $e',
    );

    rethrow;
  }
}

  Future<void> saveProfileToFirestore() async {
  try {
    final User? user = auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not authenticated.',
      );
    }

    if (currentLocation == null) {
      throw Exception(
        'Ambulance location is missing.',
      );
    }

    final FirebaseFirestore firestore =
        FirebaseFirestore.instance;

    await firestore
        .collection('ambulances')
        .doc(user.uid)
        .set(
      {
        'uid': user.uid,

        'name': nameController.text.trim(),

        'mobile': mobileController.text.trim(),

      
        'secondaryMobile':
    secondaryPhoneController.text.trim(),

  'state': selectedState!.trim(),

'district': selectedDistrict!.trim(),

'nearestTown':
    nearestCityController.text.trim(),


'role': 'ambulance',

      
        'vehicleNumber':
            vehicleNumberController.text.trim(),

        'profilePhotoUrl':
            profilePhotoUrl ?? '',

        'location': currentLocation!.toMap(),

        'latitude':
            currentLocation!.latitude,

        'longitude':
            currentLocation!.longitude,

       
        'placeName':
            currentLocation!.placeName,

        'isOnline': true,
        'onlineUpdatedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),

        'createdAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    debugPrint(
      'Ambulance profile saved to Firestore.',
    );
  } catch (e) {
    debugPrint(
      'Error saving ambulance profile to Firestore: $e',
    );

    rethrow;
  }
}

Future<void> submitProfile() async {
  if (isSubmitting) return;

  bool hasError = false;

  if (nameController.text.trim().isEmpty) {
    nameError = 'Please enter your name.';
    hasError = true;
  } else {
    nameError = null;
  }

  final String mobile =
      mobileController.text.trim();

  if (mobile.length != 10) {
    mobileError = true;
    hasError = true;
  } else {
    mobileError = false;
  }

final String secondaryMobile =
    secondaryPhoneController.text.trim();

if (secondaryMobile.isEmpty) {
  secondaryMobileError =
      'Please enter the same number or another number.';
  hasError = true;
} else if (secondaryMobile.length != 10) {
  secondaryMobileError =AppLocalizations.of(context)!.enteradigitmobilenumber;
  hasError = true;
} else {
  secondaryMobileError = null;
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

if (currentLocation == null) {
  locationError = true;
  hasError = true;
} else {
  locationError = false;
}

  final String vehicleNumber =
      vehicleNumberController.text.trim();

  if (vehicleNumber.isEmpty) {
    vehicleNumberError =
        'Please enter the ambulance vehicle number.';
    hasError = true;
  } else {
    vehicleNumberError = null;
  }

if (!privacyPolicyAccepted) {
  privacyPolicyError =
      'Please accept the Privacy Policy and Terms & Conditions.';
  hasError = true;
} else {
  privacyPolicyError = null;
}

  if (!mounted) return;

  setState(() {});

  if (hasError) {
    return;
  }

 
  if (!otpVerified) {
  showMessage(
    'Please verify your mobile number using OTP.',
    error: true,
  );

  return;
}

  final User? user = auth.currentUser;

  if (user == null) {
    showMessage(
      'Authentication failed. Please verify OTP again.',
      error: true,
    );

    return;
  }

  if (!mounted) return;

  setState(() {
    isSubmitting = true;
  });

  try {
 
    await saveBasicAmbulanceToHive();

    await CommonProfileService.saveLogin(
      uid: user.uid,
      name: nameController.text.trim(),
      mobile: mobile,
      role: 'ambulance',
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
            'Ambulance Firestore sync successful.',
          );
        })
        .catchError((error) {
          debugPrint(
            'Ambulance Firestore sync failed: $error',
          );
        });
  } catch (e) {
    debugPrint(
      'Ambulance submit error: $e',
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    showMessage(
      'Could not save ambulance profile: $e',
      error: true,
    );
  }
}

  Widget _submitButton() {
  return SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      onPressed: isSubmitting
          ? null
          : submitProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF176B32),
        disabledBackgroundColor:
            Colors.grey.shade400,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: isSubmitting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(
                  Colors.white,
                ),
              ),
            )
          : const Text(
              'Create Ambulance Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
    ),
  );
}

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
                text:  AppLocalizations.of(context)!.ambulance,
                style: TextStyle(
                  color: Color(0xFF08744F),
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text:  AppLocalizations.of(context)!.registration,
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
                'Fill in your details to create your Ambulance profile',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              sectionTitle('Name'),

              const SizedBox(height: 10),

              _nameField(),

              const SizedBox(height: 22),

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

                otpSection(),

                         const SizedBox(height: 22),

              secondaryMobileSection(),

              const SizedBox(height: 22),
               stateSection(),

const SizedBox(height: 20),

districtSection(),
const SizedBox(height: 20),
sectionTitle('Nearest Town'),
              const SizedBox(height: 8),

TextField(
  controller: nearestCityController,
  textCapitalization: TextCapitalization.words,

  onChanged: (value) {
    if (nearestCityError.isNotEmpty &&
        value.trim().isNotEmpty) {
      setState(() {
        nearestCityError = '';
      });
    }
  },

  decoration: fieldDecoration(
    hintText:  AppLocalizations.of(context)!.enternearestTown,
    icon: Icons.location_city_outlined,
    hasError: nearestCityError.isNotEmpty,
  ),
),

const SizedBox(height: 22),

sectionTitle(
  'Vehicle Number ',
),

const SizedBox(height: 10),

_vehicleNumberField(),

const SizedBox(height: 22),

locationSection(),

const SizedBox(height: 22),

   sectionTitle('Profile Photo'),
                const SizedBox(height: 5),
_profilePhotoSection(),

const SizedBox(height: 32),
   sectionTitle( AppLocalizations.of(context)!.termsConditions
    ),

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
_submitButton(),
]
          ),
        ),
      ),
    );
  }
}
