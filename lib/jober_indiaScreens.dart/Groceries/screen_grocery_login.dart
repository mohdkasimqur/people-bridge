// import 'dart:async';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:image_picker/image_picker.dart';

// class ScreenGroceryLogin extends StatefulWidget {
//   const ScreenGroceryLogin({super.key});

//   @override
//   State<ScreenGroceryLogin> createState() => _ScreenShopkeeperState();
// }

// class _ScreenShopkeeperState extends State<ScreenGroceryLogin> {
//   // ---------------------------------------------------------
//   // CONTROLLERS
//   // ---------------------------------------------------------

//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController shopNameController = TextEditingController();
//   final TextEditingController mobileController = TextEditingController();
//   final TextEditingController otpController = TextEditingController();

//   // ---------------------------------------------------------
//   // FIREBASE
//   // ---------------------------------------------------------

//   final FirebaseAuth auth = FirebaseAuth.instance;

//   String? verificationId;

//   // ---------------------------------------------------------
//   // OTP
//   // ---------------------------------------------------------

//   bool otpSent = false;
//   bool otpVerified = false;
//   bool isSendingOtp = false;
//   bool isVerifyingOtp = false;

//   int secondsRemaining = 30;
//   Timer? otpTimer;

//   // ---------------------------------------------------------
//   // SHOP DETAILS
//   // ---------------------------------------------------------

//   bool? homeDelivery;

//   TimeOfDay? openingTime;
//   TimeOfDay? closingTime;

//   // ---------------------------------------------------------
//   // SHOP PHOTO
//   // ---------------------------------------------------------

//   File? shopPhoto;

//   final ImagePicker imagePicker = ImagePicker();

//   // ---------------------------------------------------------
//   // HIVE
//   // ---------------------------------------------------------

//   late Box shopBox;

//   @override
//   void initState() {
//     super.initState();

//     // Open Hive box
//     shopBox = Hive.box('grocery');
//   }

//   // =========================================================
//   // SEND OTP
//   // =========================================================

//   Future<void> sendOTP() async {
//     String mobile = mobileController.text.trim();

//     if (mobile.isEmpty) {
//       showMessage('Please enter mobile number');
//       return;
//     }

//     if (mobile.length != 10) {
//       showMessage('Please enter a valid 10-digit mobile number');
//       return;
//     }

//     if (isSendingOtp) return;

//     setState(() {
//       isSendingOtp = true;
//     });

//     try {
//       await auth.verifyPhoneNumber(
//         phoneNumber: '+91$mobile',

//         // ---------------------------------------------------
//         // AUTOMATIC VERIFICATION
//         // ---------------------------------------------------

//         verificationCompleted: (PhoneAuthCredential credential) async {
//           try {
//             await auth.signInWithCredential(credential);

//             if (!mounted) return;

//             setState(() {
//               otpVerified = true;
//               otpSent = false;
//             });

//             otpTimer?.cancel();

//             showMessage('Mobile number verified');
//           } catch (e) {
//             if (!mounted) return;

//             showMessage('Verification failed');
//           }
//         },

//         // ---------------------------------------------------
//         // VERIFICATION FAILED
//         // ---------------------------------------------------

//         verificationFailed: (FirebaseAuthException e) {
//           if (!mounted) return;

//           setState(() {
//             isSendingOtp = false;
//           });

//           String message = 'Could not send OTP';

//           if (e.code == 'invalid-phone-number') {
//             message = 'Invalid mobile number';
//           } else if (e.code == 'too-many-requests') {
//             message = 'Too many requests. Try again later';
//           } else if (e.code == 'billing-not-enabled') {
//             message = 'Firebase billing is not enabled';
//           } else if (e.message != null) {
//             message = e.message!;
//           }

//           showMessage(message);
//         },

//         // ---------------------------------------------------
//         // CODE SENT
//         // ---------------------------------------------------

//         codeSent: (String id, int? resendToken) {
//           if (!mounted) return;

//           setState(() {
//             verificationId = id;
//             otpSent = true;
//             otpVerified = false;
//             isSendingOtp = false;
//             secondsRemaining = 30;
//           });

//           startOtpTimer();

//           showMessage('OTP sent successfully');
//         },

//         // ---------------------------------------------------
//         // AUTO RETRIEVAL TIMEOUT
//         // ---------------------------------------------------

//         codeAutoRetrievalTimeout: (String id) {
//           verificationId = id;
//         },
//       );
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isSendingOtp = false;
//       });

//       showMessage('Something went wrong');
//     }
//   }

//   void startOtpTimer() {
//     otpTimer?.cancel();

//     otpTimer = Timer.periodic(
//       const Duration(seconds: 1),
//       (timer) {
//         if (!mounted) {
//           timer.cancel();
//           return;
//         }

//         if (secondsRemaining > 0) {
//           setState(() {
//             secondsRemaining--;
//           });
//         } else {
//           timer.cancel();

//           setState(() {
//             otpSent = false;
//           });
//         }
//       },
//     );
//   }

//   // =========================================================
//   // VERIFY OTP
//   // =========================================================

//   Future<void> verifyOTP() async {
//     String otp = otpController.text.trim();

//     if (otp.length != 6) {
//       showMessage('Please enter the 6-digit OTP');
//       return;
//     }

//     if (verificationId == null) {
//       showMessage('Please send OTP again');
//       return;
//     }

//     if (isVerifyingOtp) return;

//     setState(() {
//       isVerifyingOtp = true;
//     });

//     try {
//       PhoneAuthCredential credential =
//           PhoneAuthProvider.credential(
//         verificationId: verificationId!,
//         smsCode: otp,
//       );

//       await auth.signInWithCredential(credential);

//       if (!mounted) return;

//       otpTimer?.cancel();

//       setState(() {
//         otpVerified = true;

//         // Remove OTP section
//         otpSent = false;

//         isVerifyingOtp = false;
//       });

//       otpController.clear();

//       showMessage('Mobile number verified');
//     } on FirebaseAuthException catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isVerifyingOtp = false;
//       });

//       if (e.code == 'invalid-verification-code') {
//         showMessage('Incorrect OTP');
//       } else if (e.code == 'session-expired') {
//         showMessage('OTP expired. Please send OTP again');
//       } else {
//         showMessage('OTP verification failed');
//       }
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isVerifyingOtp = false;
//       });

//       showMessage('OTP verification failed');
//     }
//   }

//   Future<void> selectOpeningTime() async {
//     TimeOfDay? selectedTime = await showTimePicker(
//       context: context,
//       initialTime: openingTime ?? TimeOfDay.now(),
//     );

//     if (selectedTime != null) {
//       setState(() {
//         openingTime = selectedTime;
//       });
//     }
//   }

//   Future<void> selectClosingTime() async {
//     TimeOfDay? selectedTime = await showTimePicker(
//       context: context,
//       initialTime: closingTime ?? TimeOfDay.now(),
//     );

//     if (selectedTime != null) {
//       setState(() {
//         closingTime = selectedTime;
//       });
//     }
//   }

//   // =========================================================
//   // PICK SHOP PHOTO
//   // =========================================================

//   Future<void> pickShopPhoto() async {
//     try {
//       XFile? image = await imagePicker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//       );

//       if (image != null) {
//         setState(() {
//           shopPhoto = File(image.path);
//         });
//       }
//     } catch (e) {
//       showMessage('Could not select photo');
//     }
//   }

//   Future<void> saveProfile() async {
//     if (nameController.text.trim().isEmpty) {
//       showMessage('Please enter your name');
//       return;
//     }

//     if (shopNameController.text.trim().isEmpty) {
//       showMessage('Please enter shop name');
//       return;
//     }

//     if (mobileController.text.trim().length != 10) {
//       showMessage('Please enter mobile number');
//       return;
//     }

//     if (!otpVerified) {
//       showMessage('Please verify your mobile number');
//       return;
//     }

//     if (homeDelivery == null) {
//       showMessage('Please select home delivery option');
//       return;
//     }

//     if (openingTime == null) {
//       showMessage('Please select opening time');
//       return;
//     }

//     if (closingTime == null) {
//       showMessage('Please select closing time');
//       return;
//     }

//     try {
//       // Convert TimeOfDay to string
//       String openingTimeString =
//           openingTime!.format(context);

//       String closingTimeString =
//           closingTime!.format(context);

//       // Store everything in Hive
//       await shopBox.put('shopkeeperProfile', {
//         'name': nameController.text.trim(),
//         'shopName': shopNameController.text.trim(),
//         'mobile': mobileController.text.trim(),
//         'homeDelivery': homeDelivery,
//         'openingTime': openingTimeString,
//         'closingTime': closingTimeString,

//         // Photo path is optional
//         'shopPhoto': shopPhoto?.path,

//         'mobileVerified': true,
//       });

//       if (!mounted) return;

//       showMessage('Shop profile saved successfully');

//       // You can navigate to your shopkeeper home screen here.
//       //
//       // Navigator.pushReplacement(
//       //   context,
//       //   MaterialPageRoute(
//       //     builder: (context) => const ScreenShopkeeperHome(),
//       //   ),
//       // );
//     } catch (e) {
//       showMessage('Could not save profile');
//     }
//   }

//   // =========================================================
//   // MESSAGE
//   // =========================================================

//   void showMessage(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//       ),
//     );
//   }

//   // =========================================================
//   // DISPOSE
//   // =========================================================

//   @override
//   void dispose() {
//     otpTimer?.cancel();

//     nameController.dispose();
//     shopNameController.dispose();
//     mobileController.dispose();
//     otpController.dispose();

//     super.dispose();
//   }

//   // =========================================================
//   // TEXT FIELD
//   // =========================================================

//   Widget customTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     TextInputType keyboardType = TextInputType.text,
//     int? maxLength,
//   }) {
//     return TextField(
//       controller: controller,
//       keyboardType: keyboardType,
//       maxLength: maxLength,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         counterText: '',
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     );
//   }

//   // =========================================================
//   // TIME BOX
//   // =========================================================

//   Widget timeBox({
//     required String title,
//     required TimeOfDay? time,
//     required VoidCallback onTap,
//   }) {
//     return Expanded(
//       child: InkWell(
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.symmetric(
//             horizontal: 12,
//             vertical: 16,
//           ),
//           decoration: BoxDecoration(
//             border: Border.all(
//               color: Colors.grey,
//             ),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   color: Colors.grey,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               Row(
//                 children: [
//                   const Icon(
//                     Icons.access_time,
//                     size: 20,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     time == null
//                         ? 'Select time'
//                         : time.format(context),
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // =========================================================
//   // BUILD
//   // =========================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Shopkeeper Registration',
//         ),
//         centerTitle: true,
//       ),

//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [

//               // =================================================
//               // NAME
//               // =================================================

//               customTextField(
//                 controller: nameController,
//                 label: 'Name',
//                 icon: Icons.person_outline,
//               ),

//               const SizedBox(height: 18),

//               // =================================================
//               // SHOP NAME
//               // =================================================

//               customTextField(
//                 controller: shopNameController,
//                 label: 'Shop Name',
//                 icon: Icons.store_outlined,
//               ),

//               const SizedBox(height: 18),

//               // =================================================
//               // MOBILE NUMBER
//               // =================================================

//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [

//                   Expanded(
//                     child: customTextField(
//                       controller: mobileController,
//                       label: 'Mobile Number',
//                       icon: Icons.phone_outlined,
//                       keyboardType: TextInputType.phone,
//                       maxLength: 10,
//                     ),
//                   ),

//                   const SizedBox(width: 10),

//                   SizedBox(
//                     height: 56,
//                     child: ElevatedButton(
//                       onPressed:
//                           otpVerified || isSendingOtp
//                               ? null
//                               : sendOTP,
//                       child: isSendingOtp
//                           ? const SizedBox(
//                               width: 20,
//                               height: 20,
//                               child:
//                                   CircularProgressIndicator(
//                                 strokeWidth: 2,
//                               ),
//                             )
//                           : const Text(
//                               'Send OTP',
//                             ),
//                     ),
//                   ),
//                 ],
//               ),

//               // =================================================
//               // OTP SECTION
//               // =================================================

//               if (otpSent && !otpVerified) ...[
//                 const SizedBox(height: 18),

//                 TextField(
//                   controller: otpController,
//                   keyboardType: TextInputType.number,
//                   maxLength: 6,
//                   decoration: InputDecoration(
//                     labelText: 'Enter 6-digit OTP',
//                     prefixIcon:
//                         const Icon(Icons.lock_outline),
//                     counterText: '',
//                     border: OutlineInputBorder(
//                       borderRadius:
//                           BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 10),

//                 Row(
//                   children: [

//                     Expanded(
//                       child: Text(
//                         'OTP expires in $secondsRemaining seconds',
//                         style: const TextStyle(
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ),

//                     ElevatedButton(
//                       onPressed:
//                           secondsRemaining > 0 &&
//                                   !isVerifyingOtp
//                               ? verifyOTP
//                               : null,
//                       child: isVerifyingOtp
//                           ? const SizedBox(
//                               width: 20,
//                               height: 20,
//                               child:
//                                   CircularProgressIndicator(
//                                 strokeWidth: 2,
//                               ),
//                             )
//                           : const Text(
//                               'Verify OTP',
//                             ),
//                     ),
//                   ],
//                 ),
//               ],

//               const SizedBox(height: 25),

//               // =================================================
//               // HOME DELIVERY
//               // =================================================

//               const Text(
//                 'Is home delivery available?',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 10),

//               Row(
//                 children: [

//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () {
//                         setState(() {
//                           homeDelivery = true;
//                         });
//                       },
//                       style: OutlinedButton.styleFrom(
//                         backgroundColor:
//                             homeDelivery == true
//                                 ? Colors.green
//                                     .withValues(alpha:0.15)
//                                 : null,
//                         side: BorderSide(
//                           color: homeDelivery == true
//                               ? Colors.green
//                               : Colors.grey,
//                         ),
//                       ),
//                       child: Text(
//                         'Yes',
//                         style: TextStyle(
//                           color: homeDelivery == true
//                               ? Colors.green
//                               : null,
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(width: 12),

//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () {
//                         setState(() {
//                           homeDelivery = false;
//                         });
//                       },
//                       style: OutlinedButton.styleFrom(
//                         backgroundColor:
//                             homeDelivery == false
//                                 ? Colors.red
//                                     .withValues(alpha:0.15)
//                                 : null,
//                         side: BorderSide(
//                           color: homeDelivery == false
//                               ? Colors.red
//                               : Colors.grey,
//                         ),
//                       ),
//                       child: Text(
//                         'No',
//                         style: TextStyle(
//                           color: homeDelivery == false
//                               ? Colors.red
//                               : null,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 25),

//               // =================================================
//               // SHOP TIMINGS
//               // =================================================

//               const Text(
//                 'Shop Timing',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 12),

//               Row(
//                 children: [

//                   timeBox(
//                     title: 'Opening Time',
//                     time: openingTime,
//                     onTap: selectOpeningTime,
//                   ),

//                   const SizedBox(width: 12),

//                   timeBox(
//                     title: 'Closing Time',
//                     time: closingTime,
//                     onTap: selectClosingTime,
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 25),

//               const Text(
//                 'Shop Photo (Optional)',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 12),

//               InkWell(
//                 onTap: pickShopPhoto,
//                 child: Container(
//                   width: double.infinity,
//                   height: 150,
//                   decoration: BoxDecoration(
//                     border: Border.all(
//                       color: Colors.grey,
//                     ),
//                     borderRadius:
//                         BorderRadius.circular(12),
//                   ),
//                   child: shopPhoto == null
//                       ? const Column(
//                           mainAxisAlignment:
//                               MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.add_a_photo_outlined,
//                               size: 40,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 8),
//                             Text(
//                               'Add Shop Photo',
//                               style: TextStyle(
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ],
//                         )
//                       : ClipRRect(
//                           borderRadius:
//                               BorderRadius.circular(12),
//                           child: Image.file(
//                             shopPhoto!,
//                             width: double.infinity,
//                             height: 150,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                 ),
//               ),

//               const SizedBox(height: 30),

//               // =================================================
//               // SAVE BUTTON
//               // =================================================

//               SizedBox(
//                 width: double.infinity,
//                 height: 52,
//                 child: ElevatedButton(
//                   onPressed: saveProfile,
//                   child: const Text(
//                     'Save Shop Profile',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
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
import 'package:jober_india/jober_indiaScreens.dart/common_profile_services.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_camera_capture.dart';

import 'package:jober_india/jober_indiaScreens.dart/screen_home.dart';
import 'package:jober_india/l10n/app_localizations.dart';
import 'package:jober_india/screens/location_localization.dart';

import '../Privacy&Terms/privacy_terms_section.dart';

// class GroceryLocation {
//   final String placeName;
//   final double latitude;
//   final double longitude;

//   GroceryLocation({
//     required this.placeName,
//     required this.latitude,
//     required this.longitude,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'placeName': placeName,
//       'latitude': latitude,
//       'longitude': longitude,
//     };
//   }

//   factory GroceryLocation.fromMap(Map<String, dynamic> map) {
//     return GroceryLocation(
//       placeName: map['placeName'] ?? '',
//       latitude: (map['latitude'] ?? 0).toDouble(),
//       longitude: (map['longitude'] ?? 0).toDouble(),
//     );
//   }
// }
class GroceryLocation {
  final String placeName;
  final double? latitude;
  final double? longitude;

  GroceryLocation({
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

  factory GroceryLocation.fromMap(
    Map<String, dynamic> map,
  ) {
    return GroceryLocation(
      placeName: map['placeName']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

class ScreenGroceryLogin extends StatefulWidget {
  const ScreenGroceryLogin({super.key});

  @override
  State<ScreenGroceryLogin> createState() => _ScreenGroceryLoginState();
}

class _ScreenGroceryLoginState extends State<ScreenGroceryLogin> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController shopNameController =
      TextEditingController();

  final TextEditingController _shopLocationController =
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

  final TextEditingController descriptionController =
    TextEditingController();

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth auth = FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;
  
  static const Color green =
      Color(0xFF138808);

  // static const Color submitGreen =
  //     Color(0xFF159B16);

  static const Color darkText =
      Color(0xFF202124);

  static const Color lightFill =
      Color(0xFFF9F9F9);
  // ============================================================
  // HIVE
  // ============================================================
  late Box groceryBox;

  bool privacyPolicyAccepted = false;
  String? privacyPolicyError;

bool nameError = false;
bool mobileError = false;
bool secondaryMobileError = false;
bool categoryError = false;
bool shopTimingError = false;

String? mobileErrorMessage;
String secondaryMobileErrorMessage = '';
  // ============================================================
  // IMAGE PICKER
  // ============================================================
 File? profilePhoto;
  String? profilePhotoUrl;
bool isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();
 // ==========================================================
  // LOCATION
  // ==========================================================
GroceryLocation? currentLocation;

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
 
  // ============================================================
  // ERRORS
  // ============================================================

  bool shopNameError = false;
  bool locationError = false;
  bool homeDeliveryError = false;

  // ============================================================
  // HOME DELIVERY
  // ============================================================

  bool? homeDelivery;

  // ============================================================
  // CATEGORY
  // ============================================================

  bool isCategoryDropdownOpen = false;
 // bool isStateDropdownOpen = false;


   final List<String> customCategories = [];


  final List<String> selectedCategories = [];


  List<String> filteredCategories = [];

  final List<String> groceryCategories = [
    'പലചരക്ക് കട',
    'Grocery Store',
    'Super Market',
    'Mini Super Market',
    'Provision Store',
    'General Store',
    'Rice & Grains',
    'Flour & Atta',
    'Pulses & Dal',
    'Spices & Masala',
    'Oil & Ghee',
    'Sugar & Salt',
    'Dry Fruits & Nuts',
    'Bakery Products',
    'Biscuits & Snacks',
    'Chips & Namkeen',
    'Tea & Coffee',
    'Juices & Soft Drinks',
    'Packaged Foods',
    'Frozen Foods',
    'Dairy Products',
    'Milk Products',
    'Fruits & Vegetables',
    'Organic Grocery',
    'Baby Food',
    'Household Grocery',
    'Cleaning Products',
    'Personal Care',
    'Pet Food', 'Other Grocery',
  ];

  // ============================================================
  // LOCATION
  // ============================================================

  double? shopLatitude;
  double? shopLongitude;

  // bool isGettingLocation = false;

 // String locationText = 'Shop location not added';

  // ============================================================
  // SHOP TIMINGS
  // ============================================================

  TimeOfDay? openingTime;
  TimeOfDay? closingTime;
  bool isOpen24Hours = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    filteredCategories =
        List<String>.from(
      groceryCategories,
    );

     filteredStates = List<String>.from(indiaStates);

  loadDistricts();

    groceryBox = Hive.box('grocery');

    categorySearchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

//        final TextEditingController nearestCityController =
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

 List<String> get allCategories {

    final List<String> result = [];

    for (final category in groceryCategories) {

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

  // ============================================================
  // FILTERED CATEGORIES
  // ============================================================

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

  // ============================================================
  // ADD CUSTOM CATEGORY
  // ============================================================

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
              : const Color(0xFF12652F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
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

              hintText:'Enter Grocery Category',

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

  // ==============================================================
  // SEND OTP
  // ===============================================================

Future<void> sendOTP({bool isResend = false}) async {
  if (isSendingOtp || isVerifying) return;

  final phone = mobileController.text.trim();

  if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
    showMessage( AppLocalizations.of(context)!.enteradigitmobilenumber,
     // 'Enter a valid 10-digit mobile number.'
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
  // CURRENT SHOP LOCATION
  // ============================================================

 Widget locationSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Grocery Location',
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
                      'Add your Grocery location',
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
                              : 'Use Grocery Location',
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
          'Enter or Paste Garage Location',
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
            labelText: 'Grocery Location',
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
  currentLocation = GroceryLocation(
    placeName: placeName.trim(),
    latitude: null,
    longitude: null,
  );
  locationError = false;
  isGettingLocation = false;
  isSearchingLocation = false;
});

showMessage(
  'Grocery location added.',
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
  currentLocation = GroceryLocation(
    placeName: placeName,
    latitude: position.latitude,
    longitude: position.longitude,
  );

  locationError = false;
});

    showMessage(
      'Grocery location added.',
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

    if (closingTime != null) {
      shopTimingError = false;
    }
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

    if (openingTime != null) {
      shopTimingError = false;
    }
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

Future<void> saveBasicUserToHive() async {
  try {
    final User? user = auth.currentUser;

    // ==========================================================
    // BASIC DETAILS
    // ==========================================================

    await groceryBox.put(
      'name',
      nameController.text.trim(),
    );

    await groceryBox.put(
      'shopName',
      shopNameController.text.trim(),
    );

    await groceryBox.put(
      'mobile',
      mobileController.text.trim(),
    );

    await groceryBox.put(
      'secondaryMobile',
      secondaryPhoneController.text.trim(),
    );

    await groceryBox.put(
  'state',
  selectedState!.trim(),
);

await groceryBox.put(
  'district',
  selectedDistrict!.trim(),
);

await groceryBox.put(
  'nearestTown',
  nearestCityController.text.trim(),
);

    await groceryBox.put(
      'role',
      'grocery',
    );

    // ==========================================================
    // UID
    // ==========================================================

    if (user != null) {
      await groceryBox.put(
        'uid',
        user.uid,
      );
    }

    // ==========================================================
    // CATEGORIES
    // ==========================================================

    await groceryBox.put(
      'categories',
      List<String>.from(
        selectedCategories,
      ),
    );

    await groceryBox.put(
      'customCategories',
      List<String>.from(
        customCategories,
      ),
    );

    // ==========================================================
    // HOME DELIVERY
    // ==========================================================

    await groceryBox.put(
      'homeDelivery',
      homeDelivery,
    );

    // ==========================================================
    // SHOP TIMING
    // ==========================================================

    await groceryBox.put(
      'isOpen24Hours',
      isOpen24Hours,
    );

    await groceryBox.put(
      'openingTime',
      isOpen24Hours || openingTime == null
          ? null
          : timeToString(openingTime!),
    );

    await groceryBox.put(
      'closingTime',
      isOpen24Hours || closingTime == null
          ? null
          : timeToString(closingTime!),
    );

    // ==========================================================
    // DESCRIPTION
    // ==========================================================

    final String description =
        descriptionController.text.trim();

    await groceryBox.put(
      'description',
      description.isEmpty
          ? null
          : description,
    );

    // ==========================================================
    // LOCATION
    // ==========================================================

    await groceryBox.put(
      'hasLocation',
      currentLocation != null,
    );

    await groceryBox.put(
      'locationName',
      currentLocation?.placeName,
    );

    await groceryBox.put(
      'latitude',
      shopLatitude,
    );

    await groceryBox.put(
      'longitude',
      shopLongitude,
    );

    // ==========================================================
    // PHOTO
    // ==========================================================

    await groceryBox.put(
      'profilePhotoUrl',
      profilePhotoUrl,
    );

    // ==========================================================
    // OTP VERIFICATION
    // ==========================================================

    await groceryBox.put(
      'mobileVerified',
      otpVerified,
    );

    // ==========================================================
    // PRIVACY / TERMS
    // ==========================================================

    await groceryBox.put(
      'privacyPolicyAccepted',
      privacyPolicyAccepted,
    );

    // ==========================================================
    // ACTIVE STATUS
    // ==========================================================

    await groceryBox.put(
      'isActive',
      true,
    );

    // ==========================================================
    // REGISTRATION STATUS
    // ==========================================================

    await groceryBox.put(
      'registered',
      true,
    );

    debugPrint(
      'Grocery profile saved successfully to Hive.',
    );
  } catch (e) {
    debugPrint(
      'Grocery Hive save error: $e',
    );

    rethrow;
  }
}
  // ============================================================
  // SAVE PROFILE TO FIRESTORE
  // ============================================================
Future<void> saveProfileToFirestore() async {
  final User? user = auth.currentUser;

  if (user == null) {
    throw Exception(
      'User is not authenticated.',
    );
  }

  if (shopLatitude == null ||
      shopLongitude == null) {
    throw Exception(
      'Shop location is missing.',
    );
  }

  // ==========================================================
  // OPTIONAL DESCRIPTION
  // ==========================================================

  final String? description =
      descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim();

  // ==========================================================
  // SHOP TIMING
  // ==========================================================

  final String? opening =
      isOpen24Hours || openingTime == null
          ? null
          : timeToString(openingTime!);

  final String? closing =
      isOpen24Hours || closingTime == null
          ? null
          : timeToString(closingTime!);

  // ==========================================================
  // FIRESTORE
  // ==========================================================

  await firestore
      .collection('groceryShops')
      .doc(user.uid)
      .set(
    {
      // ========================================================
      // BASIC DETAILS
      // ========================================================

      'uid': user.uid,

      'name':
          nameController.text.trim(),

      'shopName':
          shopNameController.text.trim(),

      'mobile':
          mobileController.text.trim(),

      'secondaryMobile':
          secondaryPhoneController.text.trim(),

      'state': selectedState!.trim(),
      'district': selectedDistrict!.trim(),
      'nearestTown': nearestCityController.text.trim(),

      'role':
          'grocery',

      // ========================================================
      // CATEGORIES
      // ========================================================

      'categories':
          List<String>.from(
        selectedCategories,
      ),

      'customCategories':
          List<String>.from(
        customCategories,
      ),

      // ========================================================
      // HOME DELIVERY
      // ========================================================

      'homeDelivery':
          homeDelivery == true,

      // ========================================================
      // SHOP TIMING
      // ========================================================

      'isOpen24Hours':
          isOpen24Hours,

      'openingTime':
          opening,

      'closingTime':
          closing,

      // ========================================================
      // DESCRIPTION
      // ========================================================

      'description':
          description,

      // ========================================================
      // LOCATION
      // ========================================================

      'hasLocation':
          true,

      'locationName':
          currentLocation?.placeName,

      'latitude':
          shopLatitude,

      'longitude':
          shopLongitude,

      'location':
          GeoPoint(
        shopLatitude!,
        shopLongitude!,
      ),

      // ========================================================
      // PHOTO
      // ========================================================

      'profilePhotoUrl':
          profilePhotoUrl,

      // 'shopPhotoPath':
      //     profilePhoto?.path,

      // ========================================================
      // VERIFICATION
      // ========================================================

      'mobileVerified':
          otpVerified,

      // ========================================================
      // PRIVACY / TERMS
      // ========================================================

      'privacyPolicyAccepted':
          privacyPolicyAccepted,

      // ========================================================
      // STATUS
      // ========================================================

      'isActive':
          true,

      // ========================================================
      // TIMESTAMPS
      // ========================================================

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

Future<void> submitProfile() async {
  if (isSubmitting) return;

  bool hasError = false;

  // ==========================================================
  // NAME
  // ==========================================================

  if (nameController.text.trim().isEmpty) {
    nameError = true;
    hasError = true;
  } else {
    nameError = false;
  }

  // ==========================================================
  // SHOP NAME
  // ==========================================================

  if (shopNameController.text.trim().isEmpty) {
    shopNameError = true;
    hasError = true;
  } else {
    shopNameError = false;
  }

  // ==========================================================
  // MOBILE
  // ==========================================================

  final String mobile =
      mobileController.text.trim();

  if (mobile.isEmpty) {
    mobileError = true;
    mobileErrorMessage =
        'Please enter mobile number.';
    hasError = true;
  } else if (mobile.length != 10) {
    mobileError = true;
    mobileErrorMessage =
        'Please enter a valid 10-digit mobile number.';
    hasError = true;
  } else {
    mobileError = false;
    mobileErrorMessage = '';
  }

  // ==========================================================
  // SECONDARY MOBILE
  // ==========================================================

  final String secondaryMobile =
      secondaryPhoneController.text.trim();

  if (secondaryMobile.isEmpty) {
    secondaryMobileError = true;
    secondaryMobileErrorMessage =
        'Please enter Same number or Other Number.';
    hasError = true;
  } else if (secondaryMobile.length != 10) {
    secondaryMobileError = true;
    secondaryMobileErrorMessage =
        'Please enter a valid 10-digit mobile number.';
    hasError = true;
  } else {
    secondaryMobileError = false;
    secondaryMobileErrorMessage = '';
  }

  // ==========================================================
  // CATEGORY
  // ==========================================================

  if (selectedCategories.isEmpty) {
    categoryError = true;
    hasError = true;
  } else {
    categoryError = false;
  }

  // ==========================================================
  // SHOP TIMING
  // ==========================================================

  if (isOpen24Hours) {
    // Open 24 Hours is a valid timing selection.
    shopTimingError = false;
  } else if (openingTime == null ||
      closingTime == null) {
    shopTimingError = true;
    hasError = true;
  } else {
    shopTimingError = false;
  }

  // ==========================================================
  // HOME DELIVERY
  // ==========================================================

  if (homeDelivery == null) {
    homeDeliveryError = true;
    hasError = true;
  } else {
    homeDeliveryError = false;
  }

  // ==========================================================
  // STATE DISTRICT NEAREST TOWN
  // ==========================================================

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
// GARAGE LOCATION
// ==========================================================

if (currentLocation == null) {
  locationError = true;
  hasError = true;
} else {
  locationError = false;
}

  // ==========================================================
  // TERMS & CONDITIONS / PRIVACY POLICY
  // ==========================================================

  if (!privacyPolicyAccepted) {
    privacyPolicyError =
        'Please accept the Privacy Policy and Terms & Conditions.';
    hasError = true;
  } else {
    privacyPolicyError = null;
  }

  // ==========================================================
  // SHOW ALL VALIDATION ERRORS
  // ==========================================================

  if (!mounted) return;

  setState(() {});

  // Stop here if any required field has an error.
  if (hasError) {
    return;
  }

  // ==========================================================
  // OTP
  // ==========================================================

  if (!otpVerified) {
    mobileError = true;
    mobileErrorMessage =
        'Please verify your mobile number.';

    if (!mounted) return;

    setState(() {});

    return;
  }

  // ==========================================================
  // FIREBASE USER
  // ==========================================================

  final User? user =
      auth.currentUser;

  if (user == null) {
    showMessage(
      'Authentication failed. Please verify OTP again.',
    );
    return;
  }

  if (!mounted) return;

  // ==========================================================
  // START SUBMITTING
  // ==========================================================

  setState(() {
    isSubmitting = true;
  });

  try {
    // ========================================================
    // 1. SAVE LOCAL DATA FIRST
    // ========================================================

    await saveBasicUserToHive();

    // ========================================================
    // 2. SAVE LOGIN STATUS
    // ========================================================

    await CommonProfileService.saveLogin(
      uid: user.uid,
      name: nameController.text.trim(),
      mobile: mobileController.text.trim(),
      role: 'grocery',
    );

    // ========================================================
    // 3. SAVE TO FIRESTORE
    // ========================================================

    try {
      await saveProfileToFirestore();
    } catch (e) {
      debugPrint(
        'Grocery Firestore sync error: $e',
      );
    }

    // ========================================================
    // 4. SHORT TRANSITION
    // ========================================================

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    // ========================================================
    // 5. GO HOME
    // ========================================================

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const ScreenHome(),
      ),
      (route) => false,
    );
  } catch (e) {
    debugPrint(
      'Grocery submit error: $e',
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    showMessage(
      'Could not save grocery shop profile.',
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
  // ============================================================
  // FIELD DECORATION
  // ============================================================

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
  // HOME DELIVERY BUTTON
  // Same visual style as Student gender buttons
  // ============================================================

  Widget deliveryButton({
    required String title,
    required bool value,
  }) {
    final bool selected =
        homeDelivery == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          homeDelivery = value;
          homeDeliveryError = false;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
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
                : Colors.grey.shade300,
            width:
                selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
              color: selected
                  ? const Color(0xFF159B16)
                  : const Color(0xFF202124),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY SECTION
  // ============================================================

  Widget categorySection() {
    final categories =
        filteredCategories;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // sectionTitle(
        //   'Freelancer Categories',
        // ),

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
                                    'Select Grocery categories',
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
            padding:
                EdgeInsets.only(
              left: 12,
              top: 5,
            ),
            child: Text(
              'Please select at least one category.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
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

              if (isOpen24Hours) {
                openingTime = null;
                closingTime = null;

                // Valid because user selected 24 hours.
                shopTimingError = false;
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
              color: shopTimingError
                  ? Colors.red
                  : isOpen24Hours
                      ? const Color(0xFF16803C)
                      : Colors.grey.shade300,
              width: shopTimingError || isOpen24Hours
                  ? 2
                  : 1.5,
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
                      color: shopTimingError
                          ? Colors.red
                          : Colors.grey.shade300,
                      width: shopTimingError ? 2 : 1.5,
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
                      color: shopTimingError
                          ? Colors.red
                          : Colors.grey.shade300,
                      width: shopTimingError ? 2 : 1.5,
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

      // ============================================================
      // TIMING ERROR MESSAGE
      // ============================================================

      if (shopTimingError)
        const Padding(
          padding: EdgeInsets.only(
            left: 12,
            top: 6,
          ),
          child: Text(
            'Please select shop timing or choose Open 24 Hours.',
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

   Widget descriptionSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Describe your Store (Optional)',
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
  // SHOP PHOTO SECTION
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
 
  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    timer?.cancel();

    nameController.dispose();
    shopNameController.dispose();
    mobileController.dispose();
    otpController.dispose();
    secondaryPhoneController.dispose();
    categorySearchController.dispose();
    descriptionController.dispose();
    stateSearchController.dispose();
    districtSearchController.dispose();



    super.dispose();
  }

  // ============================================================
  // BUILD
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
  @override
  Widget build(BuildContext context) {
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

        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text:
                    'Grocery / Super Market ',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF08744F),
                ),
              ),
              TextSpan(
                text:  AppLocalizations.of(context)!.registration,
                //'Registration',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Colors.red,
                ),
              ),
            ],
          ),
        ),

        centerTitle: false,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
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
                CrossAxisAlignment.stretch,
            children: [
              // =================================================
              // SUBTITLE
              // =================================================

              const Text(
                'Fill in your details to create your grocery shop profile',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color:
                      Color(0xFF777777),
                ),
              ),

              const SizedBox(
                height: 32,
              ),

              // =================================================
              // FULL NAME
              // =================================================

              sectionTitle(
                'Full Name',
              ),

              const SizedBox(
                height: 9,
              ),


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
                height: 28,
              ),

              // =================================================
              // SHOP NAME
              // =================================================

              sectionTitle(
                'Shop Name',
              ),

              const SizedBox(
                height: 9,
              ),

              TextField(
                controller:
                    shopNameController,
                textInputAction:
                    TextInputAction.next,
                onChanged: (value) {
                  if (value
                          .trim()
                          .isNotEmpty &&
                      shopNameError) {
                    setState(() {
                      shopNameError =
                          false;
                    });
                  }
                },
                decoration:
                    fieldDecoration(
                  hintText:
                      'Enter shop name',
                  hasError:
                      shopNameError,
                  icon:
                      Icons.store_outlined,
                ),
              ),

              if (shopNameError)
                const Padding(
                  padding:
                      EdgeInsets.only(
                    left: 8,
                    top: 5,
                  ),
                  child: Text(
                    'Please enter shop name.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(
                height: 28,
              ),

              // =================================================
              // HOME DELIVERY
              // =================================================

              sectionTitle(
                'Is Home Delivery Available?',
              ),

              const SizedBox(
                height: 10,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        deliveryButton(
                      title: 'Yes',
                      value: true,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                        deliveryButton(
                      title: 'No',
                      value: false,
                    ),
                  ),
                ],
              ),

              if (homeDeliveryError)
                const Padding(
                  padding:
                      EdgeInsets.only(
                    left: 8,
                    top: 5,
                  ),
                  child: Text(
                    'Please select home delivery option.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(
                height: 28,
              ),

              // =================================================
              // CATEGORY
              // =================================================

              categorySection(),

              const SizedBox(
                height: 28,
              ),

              // =================================================
              // MOBILE NUMBER
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

              const SizedBox(
                height: 28,
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

              // =================================================
              // SHOP TIMING
              // =================================================

              shopTimingSection(),
              const SizedBox(height: 20),
               descriptionSection(),
              const SizedBox(height: 20),


              const SizedBox(
                height: 28,
              ),

              // =================================================
              // SHOP PHOTO
              // =================================================
              const SizedBox(height: 10),
              _profilePhotoSection(),
               const SizedBox(height: 28),

              // =================================================
              // SHOP LOCATION
              // =================================================

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

              // =================================================
              // SUBMIT PROFILE
              // =================================================

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
                        Colors.grey
                            .shade400,
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
                                FontWeight
                                    .bold,
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
}

//  Future<void> saveProfileToFirestore() async {
//   final User? user =
//       auth.currentUser;

//   if (user == null) {
//     throw Exception(
//       'User is not authenticated.',
//     );
//   }

//   if (shopLatitude == null ||
//       shopLongitude == null) {
//     throw Exception(
//       'Shop location is missing.',
//     );
//   }

//   // ==========================================================
//   // OPTIONAL SHOP TIMING
//   // ==========================================================

//   final String? opening =
//       openingTime == null
//           ? null
//           : timeToString(openingTime!);

//   final String? closing =
//       closingTime == null
//           ? null
//           : timeToString(closingTime!);

//   // ==========================================================
//   // OPTIONAL DESCRIPTION
//   // ==========================================================

//   final String? description =
//       descriptionController.text.trim().isEmpty
//           ? null
//           : descriptionController.text.trim();

//   // ==========================================================
//   // FIRESTORE
//   // ==========================================================

//   await firestore
//       .collection('groceryShops')
//       .doc(user.uid)
//       .set(
//     {
//       'uid':
//           user.uid,

//       'name':
//           nameController.text.trim(),

//       'shopName':
//           shopNameController.text.trim(),

//       'mobile':
//           mobileController.text.trim(),

//       'secondaryMobile':
//     secondaryPhoneController.text.trim(),

//       'profilePhotoUrl':
//           profilePhotoUrl,

//       'role':
//           'grocery',

//       'categories':
//           List<String>.from(
//         selectedCategories,
//       ),

//       'homeDelivery':
//           homeDelivery == true,

//       // ========================================================
//       // OPTIONAL TIMING
//       // ========================================================

//       'openingTime':
//           opening,

//       'closingTime':
//           closing,
//       'isOpen24Hours': isOpen24Hours,

//       // ========================================================
//       // OPTIONAL DESCRIPTION
//       // ========================================================

//       'description':
//           description,

//       // ========================================================
//       // LOCATION
//       // ========================================================

//       'latitude':
//           shopLatitude,

//       'longitude':
//           shopLongitude,

//       'location':
//           GeoPoint(
//         shopLatitude!,
//         shopLongitude!,
//       ),

//       // ========================================================
//       // VERIFICATION
//       // ========================================================

//       'mobileVerified':
//           otpVerified,

//       'shopPhotoPath':
//           profilePhoto?.path,

//       'isActive':
//           true,

//       'updatedAt':
//           FieldValue.serverTimestamp(),

//       'createdAt':
//           FieldValue.serverTimestamp(),
//     },
//     SetOptions(
//       merge: true,
//     ),
//   );
// }
  // ============================================================
  // SUBMIT PROFILE
  // ============================================================

//   Future<void> submitProfile() async {
//     if (isSubmitting) return;

//     bool hasError = false;

//     // ==========================================================
//     // NAME
//     // ==========================================================

//     if (nameController.text
//         .trim()
//         .isEmpty) {
//       nameError = true;
//       hasError = true;
//     } else {
//       nameError = false;
//     }

//     // ==========================================================
//     // SHOP NAME
//     // ==========================================================

//     if (shopNameController.text
//         .trim()
//         .isEmpty) {
//       shopNameError = true;
//       hasError = true;
//     } else {
//       shopNameError = false;
//     }

//     // ==========================================================
//     // MOBILE
//     // ==========================================================

//     // final String mobile =
//     //     mobileController.text.trim();

//     // if (mobile.length != 10) {
//     //   mobileError = true;
//     //   hasError = true;
//     // } else {
//     //   mobileError = false;
//     // }
//     final String mobile =
//     mobileController.text.trim();

// if (mobile.isEmpty) {
//   mobileError = true;
//   mobileErrorMessage =
//       'Please enter mobile number.';
//   hasError = true;
// } else if (mobile.length != 10) {
//   mobileError = true;
//   mobileErrorMessage =
//       'Please enter a valid 10-digit mobile number.';
//   hasError = true;
// } else {
//   mobileError = false;
//   mobileErrorMessage = '';
// }

//     // ==========================================================
// // SECONDARY MOBILE
// // ==========================================================

// // final String secondaryMobile =
// //     secondaryPhoneController.text.trim();

// // if (secondaryMobile.length != 10) {
// //   secondaryMobileError = true;
// //   hasError = true;
// // } else {
// //   secondaryMobileError = false;
// // }
// // ==========================================================
// // SECONDARY MOBILE
// // ==========================================================

// final String secondaryMobile =
//     secondaryPhoneController.text.trim();

// if (secondaryMobile.isEmpty) {
//   secondaryMobileError = true;
//   secondaryMobileErrorMessage =
//       'Please enter Same number or Other Number.';
//   hasError = true;
// } else if (secondaryMobile.length != 10) {
//   secondaryMobileError = true;
//   secondaryMobileErrorMessage =
//       'Please enter a valid 10-digit mobile number.';
//   hasError = true;
// } else {
//   secondaryMobileError = false;
//   secondaryMobileErrorMessage = '';
// }

//     // ==========================================================
//     // CATEGORY
//     // ==========================================================

//     if (selectedCategories.isEmpty) {
//       categoryError = true;
//       hasError = true;
//     } else {
//       categoryError = false;
//     }

//     // ==========================================================
// // SHOP TIMING
// // ==========================================================

// if (isOpen24Hours) {
//   // Open 24 Hours is a valid timing selection.
//   shopTimingError = false;
// } else if (openingTime == null || closingTime == null) {
//   shopTimingError = true;
//   hasError = true;
// } else {
//   shopTimingError = false;
// }

//     // ==========================================================
//     // HOME DELIVERY
//     // ==========================================================

//     if (homeDelivery == null) {
//       homeDeliveryError = true;
//       hasError = true;
//     } else {
//       homeDeliveryError = false;
//     }

//     // ==========================================================
//     // LOCATION
//     //
//     // Location is required because the customer-side system
//     // needs it to calculate the distance and show shops
//     // within 50 KM.
//     // ==========================================================

//     if (shopLatitude == null ||
//         shopLongitude == null) {
//       locationError = true;
//       hasError = true;
//     } else {
//       locationError = false;
//     }

   

//     // ==========================================================
//     // OTP
//     // ==========================================================

//     if (!otpSent && !otpVerified) {
//       // If already verified, this condition is false.
//     }

//     if (!otpVerified) {
//       showMessage(
//         'Please verify your mobile number first.',
//       );
//       return;
//     }

// //   // ============================================================
// //   // TERMS & CONDITION / PRIVACY POLICY
// //   // ============================================================
// //   if (!privacyPolicyAccepted) {
// //   setState(() {
// //     privacyPolicyError =
// //         'Please accept the Privacy Policy and Terms & Conditions.';
// //   });

// //   showMessage(
// //     'Please accept the Privacy Policy and Terms & Conditions.',
// //   );

// //   return;
// // }
// // ============================================================
// // TERMS & CONDITIONS / PRIVACY POLICY
// // ============================================================

// if (!privacyPolicyAccepted) {
//   privacyPolicyError =
//       'Please accept the Privacy Policy and Terms & Conditions.';

//   hasError = true;
// }

//     // ==========================================================
//     // FIREBASE USER
//     // ==========================================================

//     final User? user =
//         auth.currentUser;

//     if (user == null) {
//       showMessage(
//         'Authentication failed. Please verify OTP again.',
//       );
//       return;
//     }
//  if (!mounted) return;

//     setState(() {});

//     if (hasError) {
//       return;
//     }

//     if (!mounted) return;

//     // ==========================================================
//     // START SUBMITTING
//     // ==========================================================

//     setState(() {
//       isSubmitting = true;
//     });

//     try {
//       // ========================================================
//       // 1. SAVE LOCAL DATA FIRST
//       // ========================================================

//       await saveBasicUserToHive();

//       // ========================================================
//       // 2. SAVE LOGIN STATUS
//       // ========================================================

//       // final SharedPreferences prefs =
//       //     await SharedPreferences.getInstance();

//       // await prefs.setBool(
//       //   'isLoggedIn',
//       //   true,
//       // );
//         await CommonProfileService.saveLogin(
//   uid: user.uid,
//   name: nameController.text.trim(),
//   mobile: mobileController.text.trim(),
//   role: 'grocery',
// );

//       // ========================================================
//       // 3. FIRESTORE
//       //
//       // We save it before navigating so the shop is available
//       // immediately after registration.
//       // ========================================================

//       try {
//         await saveProfileToFirestore();
//       } catch (e) {
//         // Do not crash the app if Firestore has a temporary
//         // network problem.
//         debugPrint(
//           'Grocery Firestore sync error: $e',
//         );
//       }

//       // ========================================================
//       // 4. SHORT TRANSITION
//       // ========================================================

//       await Future.delayed(
//         const Duration(seconds: 2),
//       );

//       if (!mounted) return;

//       setState(() {
//         isSubmitting = false;
//       });

//       // ========================================================
//       // 5. GO HOME
//       // ========================================================

//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(
//           builder: (_) =>
//               const ScreenHome(),
//         ),
//         (route) => false,
//       );
//     } catch (e) {
//       debugPrint(
//         'Grocery submit error: $e',
//       );

//       if (!mounted) return;

//       setState(() {
//         isSubmitting = false;
//       });

//       showMessage(
//         'Could not save grocery shop profile.',
//       );
//     }
//   }

              // TextField(
              //   controller:
              //       nameController,
              //   textInputAction:
              //       TextInputAction.next,
              //   onChanged: (value) {
              //     if (value
              //             .trim()
              //             .isNotEmpty &&
              //         nameError) {
              //       setState(() {
              //         nameError = false;
              //       });
              //     }
              //   },
              //   decoration:
              //       fieldDecoration(
              //     hint:
              //         'Enter your name',
              //     // hasError:
              //     //     nameError,
              //     icon:
              //         Icons.person,
              //   ),
              // ),

              // if (nameError)
              //   const Padding(
              //     padding:
              //         EdgeInsets.only(
              //       left: 8,
              //       top: 5,
              //     ),
              //     child: Text(
              //       'Please enter your name.',
              //       style: TextStyle(
              //         color: Colors.red,
              //         fontSize: 12,
              //       ),
              //     ),
              //   ),

                // ============================================================
  // SHOP TIMING SECTION
  // ============================================================

  // Widget shopTimingSection() {
  //   return Column(
  //     crossAxisAlignment:
  //         CrossAxisAlignment.start,
  //     children: [
  //       sectionTitle(
  //         'Shop Timing',
  //       ),

  //       const SizedBox(height: 10),

  //       Row(
  //         children: [
  //           Expanded(
  //             child: InkWell(
  //               onTap:
  //                   selectOpeningTime,
  //               borderRadius:
  //                   BorderRadius.circular(20),
  //               child: Container(
  //                 height: 62,
  //                 padding:
  //                     const EdgeInsets.symmetric(
  //                   horizontal: 16,
  //                 ),
  //                 decoration:
  //                     BoxDecoration(
  //                   color:
  //                       const Color(0xFFF9F9F9),
  //                   borderRadius:
  //                       BorderRadius.circular(
  //                     20,
  //                   ),
  //                   border: Border.all(
  //                     color:
  //                         Colors.grey.shade300,
  //                     width: 1.5,
  //                   ),
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     const Icon(
  //                       Icons.access_time,
  //                       color:
  //                           Color(0xFF16803C),
  //                     ),

  //                     const SizedBox(
  //                       width: 10,
  //                     ),

  //                     Expanded(
  //                       child: Text(
  //                         openingTime == null
  //                             ? 'Opening Time'
  //                             : timeToString(
  //                                 openingTime!,
  //                               ),
  //                         style: TextStyle(
  //                           fontSize: 15,
  //                           color:
  //                               openingTime ==
  //                                       null
  //                                   ? Colors.grey
  //                                   : Colors.black,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),

  //           const SizedBox(width: 12),

  //           Expanded(
  //             child: InkWell(
  //               onTap:
  //                   selectClosingTime,
  //               borderRadius:
  //                   BorderRadius.circular(20),
  //               child: Container(
  //                 height: 62,
  //                 padding:
  //                     const EdgeInsets.symmetric(
  //                   horizontal: 16,
  //                 ),
  //                 decoration:
  //                     BoxDecoration(
  //                   color:
  //                       const Color(0xFFF9F9F9),
  //                   borderRadius:
  //                       BorderRadius.circular(
  //                     20,
  //                   ),
  //                   border: Border.all(
  //                     color:
  //                         Colors.grey.shade300,
  //                     width: 1.5,
  //                   ),
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     const Icon(
  //                       Icons.access_time,
  //                       color:
  //                           Color(0xFF16803C),
  //                     ),

  //                     const SizedBox(
  //                       width: 10,
  //                     ),

  //                     Expanded(
  //                       child: Text(
  //                         closingTime == null
  //                             ? 'Closing Time'
  //                             : timeToString(
  //                                 closingTime!,
  //                               ),
  //                         style: TextStyle(
  //                           fontSize: 15,
  //                           color:
  //                               closingTime ==
  //                                       null
  //                                   ? Colors.grey
  //                                   : Colors.black,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

    // ============================================================
  // SHOP PHOTO
  // ============================================================

  // Future<void> pickShopPhoto() async {
  //   try {
  //     final XFile? image =
  //         await _imagePicker.pickImage(
  //       source: ImageSource.gallery,
  //       imageQuality: 80,
  //     );

  //     if (image == null) return;

  //     if (!mounted) return;

  //     setState(() {
  //       shopPhoto = File(image.path);
  //     });
  //   } catch (e) {
  //     showMessage(
  //       'Could not select shop photo.',
  //     );
  //   }
  // }
  // ============================================================
  // SAVE BASIC USER TO HIVE
  // ============================================================

//  Future<void> saveBasicUserToHive() async {
//   try {
//     await groceryBox.put(
//       'name',
//       nameController.text.trim(),
//     );

//     await groceryBox.put(
//       'shopName',
//       shopNameController.text.trim(),
//     );

//     await groceryBox.put(
//       'mobile',
//       mobileController.text.trim(),
//     );

//     await groceryBox.put(
//   'secondaryMobile',
//   secondaryPhoneController.text.trim(),
// );

//     await groceryBox.put(
//       'role',
//       'grocery',
//     );

//     final User? user =
//         auth.currentUser;

//     if (user != null) {
//       await groceryBox.put(
//         'uid',
//         user.uid,
//       );
//     }

//     await groceryBox.put(
//       'categories',
//       List<String>.from(
//         selectedCategories,
//       ),
//     );

//     await groceryBox.put(
//       'homeDelivery',
//       homeDelivery,
//     );

//     // =========================================================
//     // OPTIONAL SHOP TIMING
//     // ==========================================================

//     await groceryBox.put(
//       'openingTime',
//       openingTime == null
//           ? null
//           : timeToString(openingTime!),
//     );

//     await groceryBox.put(
//       'closingTime',
//       closingTime == null
//           ? null
//           : timeToString(closingTime!),
//     );

//     // ==========================================================
//     // OPTIONAL DESCRIPTION
//     // ==========================================================

//     final String description =
//         descriptionController.text.trim();

//     await groceryBox.put(
//       'description',
//       description.isEmpty
//           ? null
//           : description,
//     );

//     // ==========================================================
//     // LOCATION
//     // ==========================================================

//     await groceryBox.put(
//       'latitude',
//       shopLatitude,
//     );

//     await groceryBox.put(
//       'longitude',
//       shopLongitude,
//     );

//     // ==========================================================
//     // PHOTO
//     // ==========================================================

//     await groceryBox.put(
//       'shopPhoto',
//       profilePhoto?.path,
//     );

//     // ==========================================================
//     // OTP
//     // ==========================================================

//     await groceryBox.put(
//       'mobileVerified',
//       otpVerified,
//     );

//     debugPrint(
//       'Grocery profile saved successfully to Hive.',
//     );
//   } catch (e) {
//     debugPrint(
//       'Grocery Hive save error: $e',
//     );
//   }
// }

//   Widget locationSection() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "Tea Shop's Location",
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: Color(0xFF222222),
//           ),
//         ),

//         const SizedBox(height: 8),

//         Container(
//           width: double.infinity,

//           padding:
//               const EdgeInsets.all(16),

//           decoration: BoxDecoration(
//             color:
//                 const Color(0xFFF9F9F9),
//             borderRadius:
//                 BorderRadius.circular(20),
//             border: Border.all(
//   color: locationError
//       ? Colors.red
//       : const Color(0xFFE0E0E0),
//   width: locationError ? 2 : 1.5,
// ),
//           ),

//           child: currentLocation == null
//               ? Column(
//                   children: [
//                     const Icon(
//                       Icons.location_on_outlined,
//                       color:
//                           Color(0xFF08744F),
//                       size: 38,
//                     ),

//                     const SizedBox(height: 8),

//                     const Text(
//                       'Add your current shop location',
//                       textAlign:
//                           TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 15,
//                         color:
//                             Color(0xFF666666),
//                       ),
//                     ),

//                     const SizedBox(height: 12),

//                     SizedBox(
//                       width:
//                           double.infinity,
//                       height: 48,
//                       child:
//                           ElevatedButton.icon(
//                         onPressed:
//                             isGettingLocation
//                                 ? null
//                                 : _getCurrentLocation,

//                         icon:
//                             isGettingLocation
//                                 ? const SizedBox(
//                                     width: 19,
//                                     height: 19,
//                                     child:
//                                         CircularProgressIndicator(
//                                       strokeWidth:
//                                           2,
//                                       color:
//                                           Colors.white,
//                                     ),
//                                   )
//                                 : const Icon(
//                                     Icons.my_location,
//                                   ),

//                         label: Text(
//                           isGettingLocation
//                               ? 'Getting Location...'
//                               : 'Use Current Location',
//                         ),

//                         style:
//                             ElevatedButton.styleFrom(
//                           backgroundColor:
//                               const Color(
//                             0xFF16803C,
//                           ),
//                           foregroundColor:
//                               Colors.white,
//                           elevation: 0,
//                           shape:
//                               RoundedRectangleBorder(
//                             borderRadius:
//                                 BorderRadius
//                                     .circular(
//                               24,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 )
//               : Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       crossAxisAlignment:
//                           CrossAxisAlignment.start,
//                       children: [
//                         const Icon(
//                           Icons.location_on,
//                           color:
//                               Color(0xFF16803C),
//                           size: 28,
//                         ),

//                         const SizedBox(
//                           width: 10,
//                         ),

//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment:
//                                 CrossAxisAlignment
//                                     .start,
//                             children: [
//                               const Text(
//                                 'Shop Location',
//                                 style:
//                                     TextStyle(
//                                   fontWeight:
//                                       FontWeight
//                                           .bold,
//                                   color:
//                                       Color(
//                                     0xFF12652F,
//                                   ),
//                                 ),
//                               ),

//                               const SizedBox(
//                                 height: 4,
//                               ),

//                               Text(
//                                 currentLocation!
//                                     .placeName,
//                                 style:
//                                     const TextStyle(
//                                   fontSize: 14,
//                                   color:
//                                       Color(
//                                     0xFF555555,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 12),

//                     Row(
//                       children: [
//                         const SizedBox(
//                           width: 10,
//                         ),

//                         Expanded(
//                           child:
//                             OutlinedButton.icon(
//   onPressed: () {
//     // Immediately invalidate any running location request.
//     _locationRequestId++;

//     // Immediately update the UI.
//     setState(() {
//       currentLocation = null;
//       isGettingLocation = false;
//       isSearchingLocation = false;
//       locationError = false;
//     });
//   },
//   icon: const Icon(
//     Icons.delete_outline,
//   ),
//   label: const Text(
//     'Remove',
//   ),
//   style: OutlinedButton.styleFrom(
//     foregroundColor: Colors.red,
//     side: const BorderSide(
//       color: Colors.red,
//     ),
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(18),
//     ),
//   ),
// ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//         ),
//       ],
//     );
//   }

//  Future<void> _getCurrentLocation() async {
//   if (isGettingLocation) return;

//   final int requestId = ++_locationRequestId;

//   if (!mounted) return;

//   setState(() {
//     isGettingLocation = true;
//   });

//   try {
//     // ----------------------------------------------------------
//     // CHECK LOCATION SERVICE
//     // ----------------------------------------------------------

//     final serviceEnabled =
//         await Geolocator.isLocationServiceEnabled();

//     if (!mounted || requestId != _locationRequestId) return;

//     // Location is OFF on the phone
//     // if (!serviceEnabled) {
//     //   setState(() {
//     //     isGettingLocation = false;
//     //   });

//     //   // Open phone Location Settings
//     //   await Geolocator.openLocationSettings();

//     //   return;
//     // }
//     if (!serviceEnabled) {
//   if (mounted) {
//     setState(() {
//       isGettingLocation = false;
//     });
//   }

//   showMessage(
//     'Please turn on location services.',
//     error: true,
//   );

//   return;
// }

//     // ----------------------------------------------------------
//     // CHECK PERMISSION
//     // ----------------------------------------------------------

//     LocationPermission permission =
//         await Geolocator.checkPermission();

//     if (!mounted || requestId != _locationRequestId) return;

//     if (permission == LocationPermission.denied) {
//       permission =
//           await Geolocator.requestPermission();
//     }

//     if (!mounted || requestId != _locationRequestId) return;

//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       setState(() {
//         isGettingLocation = false;
//       });

//       showMessage(
//         'Location permission is required.',
//         error: true,
//       );

//       return;
//     }

//     // ----------------------------------------------------------
//     // GET CURRENT LOCATION
//     // ----------------------------------------------------------

//     final position =
//         await Geolocator.getCurrentPosition(
//       locationSettings: const LocationSettings(
//         accuracy: LocationAccuracy.high,
//       ),
//     );

//     if (!mounted || requestId != _locationRequestId) return;

//     // ----------------------------------------------------------
//     // DEFAULT LOCATION NAME
//     // ----------------------------------------------------------

//     String placeName =
//         '${position.latitude}, ${position.longitude}';

//     // ----------------------------------------------------------
//     // REVERSE GEOCODING
//     // ----------------------------------------------------------

//     try {
//       final placemarks =
//           await geo.placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );

//       if (!mounted || requestId != _locationRequestId) return;

//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;

//         final parts = <String>[
//           if ((place.name ?? '').trim().isNotEmpty)
//             place.name!.trim(),

//           if ((place.locality ?? '').trim().isNotEmpty)
//             place.locality!.trim(),

//           if ((place.administrativeArea ?? '')
//               .trim()
//               .isNotEmpty)
//             place.administrativeArea!.trim(),
//         ];

//         if (parts.isNotEmpty) {
//           placeName = parts.join(', ');
//         }
//       }
//     } catch (e) {
//       debugPrint(
//         'Reverse geocoding error: $e',
//       );
//     }

//     // ----------------------------------------------------------
//     // SAVE LOCATION
//     // ----------------------------------------------------------

//     if (!mounted || requestId != _locationRequestId) return;

//    setState(() {
//   currentLocation = GroceryLocation(
//     placeName: placeName,
//     latitude: position.latitude,
//     longitude: position.longitude,
//   );

//   locationError = false;
  
//   isGettingLocation = false;
// });

//     showMessage(
//       'Tea Shop location added.',
//     );
//   } catch (e) {
//     if (!mounted || requestId != _locationRequestId) return;

//     showMessage(
//       'Unable to get your location.',
//       error: true,
//     );
//   } finally {
//     if (mounted &&
//         requestId == _locationRequestId) {
//       setState(() {
//         isGettingLocation = false;
//       });
//     }
//   }
// }
  // ============================================================
  // SHOP PHOTO
  // ============================================================

  // Future<void> pickShopPhoto() async {
  //   try {
  //     final XFile? image =
  //         await _imagePicker.pickImage(
  //       source: ImageSource.gallery,
  //       imageQuality: 80,
  //     );

  //     if (image == null) return;

  //     if (!mounted) return;

  //     setState(() {
  //       shopPhoto = File(image.path);
  //     });
  //   } catch (e) {
  //     showMessage(
  //       'Could not select shop photo.',
  //     );
  //   }
  // }
  // ============================================================
  // SAVE BASIC USER TO HIVE
  // ============================================================

//  Future<void> saveBasicUserToHive() async {
//   try {
//     await groceryBox.put(
//       'name',
//       nameController.text.trim(),
//     );

//     await groceryBox.put(
//       'shopName',
//       shopNameController.text.trim(),
//     );

//     await groceryBox.put(
//       'mobile',
//       mobileController.text.trim(),
//     );

//     await groceryBox.put(
//   'secondaryMobile',
//   secondaryPhoneController.text.trim(),
// );

//     await groceryBox.put(
//       'role',
//       'grocery',
//     );

//     final User? user =
//         auth.currentUser;

//     if (user != null) {
//       await groceryBox.put(
//         'uid',
//         user.uid,
//       );
//     }

//     await groceryBox.put(
//       'categories',
//       List<String>.from(
//         selectedCategories,
//       ),
//     );

//     await groceryBox.put(
//       'homeDelivery',
//       homeDelivery,
//     );

//     // =========================================================
//     // OPTIONAL SHOP TIMING
//     // ==========================================================

//     await groceryBox.put(
//       'openingTime',
//       openingTime == null
//           ? null
//           : timeToString(openingTime!),
//     );

//     await groceryBox.put(
//       'closingTime',
//       closingTime == null
//           ? null
//           : timeToString(closingTime!),
//     );

//     // ==========================================================
//     // OPTIONAL DESCRIPTION
//     // ==========================================================

//     final String description =
//         descriptionController.text.trim();

//     await groceryBox.put(
//       'description',
//       description.isEmpty
//           ? null
//           : description,
//     );

//     // ==========================================================
//     // LOCATION
//     // ==========================================================

//     await groceryBox.put(
//       'latitude',
//       shopLatitude,
//     );

//     await groceryBox.put(
//       'longitude',
//       shopLongitude,
//     );

//     // ==========================================================
//     // PHOTO
//     // ==========================================================

//     await groceryBox.put(
//       'shopPhoto',
//       profilePhoto?.path,
//     );

//     // ==========================================================
//     // OTP
//     // ==========================================================

//     await groceryBox.put(
//       'mobileVerified',
//       otpVerified,
//     );

//     debugPrint(
//       'Grocery profile saved successfully to Hive.',
//     );
//   } catch (e) {
//     debugPrint(
//       'Grocery Hive save error: $e',
//     );
//   }
// }


  // InputDecoration fieldDecoration({
  //   required String hintText,
  //   required bool hasError,
  //   IconData? icon,
  // }) {
  //   return InputDecoration(
  //     hintText: hintText,

  //     prefixIcon: icon == null
  //         ? null
  //         : Icon(
  //             icon,
  //             color:
  //                 const Color(0xFF16803C),
  //             size: 27,
  //           ),

  //     filled: true,

  //     fillColor:
  //         const Color(0xFFF9F9F9),

  //     contentPadding:
  //         const EdgeInsets.symmetric(
  //       horizontal: 18,
  //       vertical: 18,
  //     ),

  //     enabledBorder:
  //         OutlineInputBorder(
  //       borderRadius:
  //           BorderRadius.circular(20),
  //       borderSide: BorderSide(
  //         color: hasError
  //             ? Colors.red
  //             : Colors.grey.shade300,
  //         width:
  //             hasError ? 2 : 1.5,
  //       ),
  //     ),

  //     focusedBorder:
  //         OutlineInputBorder(
  //       borderRadius:
  //           BorderRadius.circular(20),
  //       borderSide: BorderSide(
  //         color: hasError
  //             ? Colors.red
  //             : const Color(0xFF16803C),
  //         width: 2,
  //       ),
  //     ),
  //   );
  // }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  // Widget sectionTitle(String title) {
  //   return Text(
  //     title,
  //     style: const TextStyle(
  //       fontSize: 18,
  //       fontWeight: FontWeight.bold,
  //       color: Color(0xFF202124),
  //     ),
  //   );
  // }
