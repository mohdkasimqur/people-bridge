// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:hive/hive.dart';

// import 'package:jober_india/jober_indiaScreens.dart/screen_home.dart';

// class RentalLoginScreen extends StatefulWidget {
//   const RentalLoginScreen({super.key});

//   @override
//   State<RentalLoginScreen> createState() =>
//       _RentalLoginScreenState();
// }

// class _RentalLoginScreenState
//     extends State<RentalLoginScreen> {
//   // ==============================================================
//   // COLORS
//   // ==============================================================

//   static const Color darkGreen = Color(0xFF12652F);
//   static const Color green = Color(0xFF198B35);
//   static const Color orange = Color(0xFFED801D);
//   static const Color pageBackground = Color(0xFFF8F5EE);

//   // ==============================================================
//   // CONTROLLERS
//   // ==============================================================

//   final TextEditingController _usernameController =
//       TextEditingController();

//   final TextEditingController _phoneController =
//       TextEditingController();

//   final TextEditingController _companyController =
//       TextEditingController();

//   final TextEditingController _categorySearchController =
//       TextEditingController();

//   // ==============================================================
//   // OTP CONTROLLERS
//   // ==============================================================

//   final List<TextEditingController> _otpControllers =
//       List.generate(
//     6,
//     (_) => TextEditingController(),
//   );

//   final List<FocusNode> _otpFocusNodes =
//       List.generate(
//     6,
//     (_) => FocusNode(),
//   );

//   // ==============================================================
//   // FIREBASE
//   // ==============================================================

//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   final FirebaseFirestore _firestore =
//       FirebaseFirestore.instance;

//   String? _verificationId;

//   int? _resendToken;

//   // ==============================================================
//   // OTP STATE
//   // ==============================================================

//   bool _otpSent = false;

//   bool _otpVerified = false;

//   bool _sendingOtp = false;

//   bool _verifyingOtp = false;

//   int _secondsRemaining = 30;

//   Timer? _otpTimer;

//   // ==============================================================
//   // LOCATION STATE
//   // ==============================================================

//   bool _gettingLocation = false;

//   bool _locationAttached = false;

//   Position? _currentPosition;

//   // ==============================================================
//   // SUBMIT STATE
//   // ==============================================================

//   bool _submitting = false;

//   // ==============================================================
//   // CATEGORY STATE
//   // ==============================================================

//   final List<String> _defaultCategories = [
//     'Premium Car Rent',
//     'Car Rent',
//     'Bike Rent',
//     'Car & Bike Rent',
//     'Flat',
//     'House',
//     'Shops',
//     'Tools',
//     'Dress',
//   ];

//   final List<String> _customCategories = [];

//   final Set<String> _selectedCategories = {};

//   bool _showCategorySelector = false;

//   String _categorySearch = '';

//   // ==============================================================
//   // LIFECYCLE
//   // ==============================================================

//   @override
//   void initState() {
//     super.initState();

//     _categorySearchController.addListener(() {
//       if (!mounted) return;

//       setState(() {
//         _categorySearch =
//             _categorySearchController.text.trim().toLowerCase();
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _otpTimer?.cancel();

//     _usernameController.dispose();
//     _phoneController.dispose();
//     _companyController.dispose();
//     _categorySearchController.dispose();

//     for (final controller in _otpControllers) {
//       controller.dispose();
//     }

//     for (final node in _otpFocusNodes) {
//       node.dispose();
//     }

//     super.dispose();
//   }

//   // ==============================================================
//   // ALL CATEGORIES
//   // ==============================================================

//   List<String> get _allCategories {
//     return [
//       ..._defaultCategories,
//       ..._customCategories,
//     ];
//   }

//   List<String> get _filteredCategories {
//     if (_categorySearch.isEmpty) {
//       return _allCategories;
//     }

//     return _allCategories.where((category) {
//       return category.toLowerCase().contains(_categorySearch);
//     }).toList();
//   }

//   // ==============================================================
//   // PHONE NUMBER
//   // ==============================================================

//   String get _fullPhoneNumber {
//     String number =
//         _phoneController.text.trim();

//     number = number.replaceAll(
//       RegExp(r'[^0-9]'),
//       '',
//     );

//     if (number.startsWith('91') &&
//         number.length > 10) {
//       number = number.substring(
//         number.length - 10,
//       );
//     }

//     return '+91$number';
//   }

//   bool get _isPhoneValid {
//     String number =
//         _phoneController.text.trim();

//     number = number.replaceAll(
//       RegExp(r'[^0-9]'),
//       '',
//     );

//     return number.length == 10;
//   }

//   // ==============================================================
//   // SEND OTP
//   // ==============================================================

//   Future<void> _sendOtp() async {
//     FocusScope.of(context).unfocus();

//     if (_usernameController.text.trim().isEmpty) {
//       _showMessage(
//         'Please enter your username.',
//         isError: true,
//       );
//       return;
//     }

//     if (!_isPhoneValid) {
//       _showMessage(
//         'Please enter a valid 10-digit mobile number.',
//         isError: true,
//       );
//       return;
//     }

//     if (_sendingOtp) return;

//     setState(() {
//       _sendingOtp = true;
//     });

//     try {
//       await _auth.verifyPhoneNumber(
//         phoneNumber: _fullPhoneNumber,

//         timeout: const Duration(
//           seconds: 60,
//         ),

//         forceResendingToken: _resendToken,

//         verificationCompleted:
//             (PhoneAuthCredential credential) async {
//           try {
//             await _auth.signInWithCredential(
//               credential,
//             );

//             if (!mounted) return;

//             setState(() {
//               _otpVerified = true;
//               _otpSent = true;
//               _sendingOtp = false;
//             });

//             _showMessage(
//               'Phone number verified automatically.',
//             );
//           } catch (e) {
//             if (!mounted) return;

//             setState(() {
//               _sendingOtp = false;
//             });
//           }
//         },

//         verificationFailed:
//             (FirebaseAuthException e) {
//           if (!mounted) return;

//           setState(() {
//             _sendingOtp = false;
//           });

//           String message =
//               'Unable to send OTP.';

//           if (e.code ==
//               'invalid-phone-number') {
//             message =
//                 'The phone number is invalid.';
//           } else if (e.code ==
//               'too-many-requests') {
//             message =
//                 'Too many requests. Please try again later.';
//           } else if (e.message != null &&
//               e.message!.isNotEmpty) {
//             message = e.message!;
//           }

//           _showMessage(
//             message,
//             isError: true,
//           );
//         },

//         codeSent:
//             (String verificationId,
//                 int? resendToken) {
//           if (!mounted) return;

//           _verificationId =
//               verificationId;

//           _resendToken =
//               resendToken;

//           setState(() {
//             _otpSent = true;
//             _otpVerified = false;
//             _sendingOtp = false;
//           });

//           _startOtpTimer();

//           Future.delayed(
//             const Duration(
//               milliseconds: 200,
//             ),
//             () {
//               if (!mounted) return;

//               if (_otpFocusNodes.isNotEmpty) {
//                 _otpFocusNodes[0].requestFocus();
//               }
//             },
//           );

//           _showMessage(
//             'OTP sent to $_fullPhoneNumber',
//           );
//         },

//         codeAutoRetrievalTimeout:
//             (String verificationId) {
//           _verificationId =
//               verificationId;
//         },
//       );
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         _sendingOtp = false;
//       });

//       _showMessage(
//         'Something went wrong while sending OTP.',
//         isError: true,
//       );
//     }
//   }

//   // ==============================================================
//   // OTP TIMER
//   // ==============================================================

//   void _startOtpTimer() {
//     _otpTimer?.cancel();

//     setState(() {
//       _secondsRemaining = 30;
//     });

//     _otpTimer = Timer.periodic(
//       const Duration(seconds: 1),
//       (timer) {
//         if (!mounted) {
//           timer.cancel();
//           return;
//         }

//         if (_secondsRemaining <= 1) {
//           timer.cancel();

//           setState(() {
//             _secondsRemaining = 0;
//           });
//         } else {
//           setState(() {
//             _secondsRemaining--;
//           });
//         }
//       },
//     );
//   }

//   // ==============================================================
//   // RESEND OTP
//   // ==============================================================

//   Future<void> _resendOtp() async {
//     if (_secondsRemaining > 0) {
//       return;
//     }

//     await _sendOtp();
//   }

//   // ==============================================================
//   // VERIFY OTP
//   // ==============================================================

//   Future<void> _verifyOtp() async {
//     if (_verificationId == null) {
//       _showMessage(
//         'Please request an OTP first.',
//         isError: true,
//       );
//       return;
//     }

//     String otp = _otpControllers
//         .map((controller) =>
//             controller.text.trim())
//         .join();

//     if (otp.length != 6) {
//       _showMessage(
//         'Please enter the complete 6-digit OTP.',
//         isError: true,
//       );
//       return;
//     }

//     if (_verifyingOtp) return;

//     setState(() {
//       _verifyingOtp = true;
//     });

//     try {
//       final PhoneAuthCredential credential =
//           PhoneAuthProvider.credential(
//         verificationId: _verificationId!,
//         smsCode: otp,
//       );

//       await _auth.signInWithCredential(
//         credential,
//       );

//       if (!mounted) return;

//       setState(() {
//         _otpVerified = true;
//         _verifyingOtp = false;
//       });

//       _showMessage(
//         'Mobile number verified successfully.',
//       );
//     } on FirebaseAuthException catch (e) {
//       if (!mounted) return;

//       setState(() {
//         _verifyingOtp = false;
//       });

//       String message =
//           'Invalid OTP. Please try again.';

//       if (e.code == 'invalid-verification-code') {
//         message =
//             'The OTP is incorrect.';
//       }

//       _showMessage(
//         message,
//         isError: true,
//       );
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         _verifyingOtp = false;
//       });

//       _showMessage(
//         'Unable to verify OTP.',
//         isError: true,
//       );
//     }
//   }

//   // ==============================================================
//   // OTP BOX INPUT
//   // ==============================================================

//   void _onOtpChanged(
//     int index,
//     String value,
//   ) {
//     if (value.isNotEmpty &&
//         index < 5) {
//       _otpFocusNodes[index + 1]
//           .requestFocus();
//     }

//     if (value.isEmpty &&
//         index > 0) {
//       _otpFocusNodes[index - 1]
//           .requestFocus();
//     }

//     String otp = _otpControllers
//         .map((controller) =>
//             controller.text)
//         .join();

//     if (otp.length == 6) {
//       _verifyOtp();
//     }
//   }

//   // ==============================================================
//   // LOCATION PERMISSION
//   // ==============================================================

//   Future<bool> _requestLocationPermission() async {
//     bool serviceEnabled =
//         await Geolocator.isLocationServiceEnabled();

//     if (!serviceEnabled) {
//       if (!mounted) return false;

//       _showLocationServiceDialog();

//       return false;
//     }

//     LocationPermission permission =
//         await Geolocator.checkPermission();

//     if (permission ==
//         LocationPermission.denied) {
//       permission =
//           await Geolocator.requestPermission();
//     }

//     if (permission ==
//             LocationPermission.denied ||
//         permission ==
//             LocationPermission.deniedForever) {
//       if (!mounted) return false;

//       _showMessage(
//         'Location permission is required to attach your rental location.',
//         isError: true,
//       );

//       return false;
//     }

//     return true;
//   }

//   // ==============================================================
//   // GET CURRENT LOCATION
//   // ==============================================================

//   Future<void> _attachCurrentLocation() async {
//     if (_gettingLocation) return;

//     setState(() {
//       _gettingLocation = true;
//     });

//     try {
//       final bool permissionGranted =
//           await _requestLocationPermission();

//       if (!permissionGranted) {
//         if (!mounted) return;

//         setState(() {
//           _gettingLocation = false;
//         });

//         return;
//       }

//       final Position position =
//           await Geolocator.getCurrentPosition(
//         locationSettings:
//             const LocationSettings(
//           accuracy: LocationAccuracy.high,
//         ),
//       );

//       if (!mounted) return;

//       setState(() {
//         _currentPosition = position;
//         _locationAttached = true;
//         _gettingLocation = false;
//       });

//       _showMessage(
//         'Current location attached successfully.',
//       );
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         _gettingLocation = false;
//       });

//       _showMessage(
//         'Unable to get your current location.',
//         isError: true,
//       );
//     }
//   }

//   // ==============================================================
//   // LOCATION SERVICE DIALOG
//   // ==============================================================

//   void _showLocationServiceDialog() {
//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           shape:
//               RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(20),
//           ),
//           title: const Row(
//             children: [
//               Icon(
//                 Icons.location_on,
//                 color: orange,
//               ),
//               SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   'Location is Off',
//                 ),
//               ),
//             ],
//           ),
//           content: const Text(
//             'Please turn on location services and try again.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(
//                   dialogContext,
//                 );
//               },
//               child: const Text(
//                 'OK',
//                 style: TextStyle(
//                   color: green,
//                   fontWeight:
//                       FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // ==============================================================
//   // ADD CUSTOM CATEGORY
//   // ==============================================================

//   Future<void> _showAddCategoryDialog() async {
//     final TextEditingController controller =
//         TextEditingController();

//     await showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           shape:
//               RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(20),
//           ),
//           title: const Text(
//             'Add Your Own Category',
//             style: TextStyle(
//               color: darkGreen,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           content: TextField(
//             controller: controller,
//             textCapitalization:
//                 TextCapitalization.words,
//             decoration:
//                 InputDecoration(
//               hintText:
//                   'Example: Wedding Car',
//               prefixIcon:
//                   const Icon(
//                 Icons.add_business,
//                 color: green,
//               ),
//               border:
//                   OutlineInputBorder(
//                 borderRadius:
//                     BorderRadius.circular(14),
//               ),
//               focusedBorder:
//                   OutlineInputBorder(
//                 borderRadius:
//                     BorderRadius.circular(14),
//                 borderSide:
//                     const BorderSide(
//                   color: green,
//                   width: 2,
//                 ),
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(
//                   dialogContext,
//                 );
//               },
//               child: const Text(
//                 'Cancel',
//                 style: TextStyle(
//                   color: Colors.grey,
//                 ),
//               ),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: green,
//                 foregroundColor:
//                     Colors.white,
//                 shape:
//                     RoundedRectangleBorder(
//                   borderRadius:
//                       BorderRadius.circular(12),
//                 ),
//               ),
//               onPressed: () {
//                 final String category =
//                     controller.text.trim();

//                 if (category.isEmpty) {
//                   return;
//                 }

//                 final bool alreadyExists =
//                     _allCategories.any(
//                   (item) =>
//                       item.toLowerCase() ==
//                       category.toLowerCase(),
//                 );

//                 if (alreadyExists) {
//                   Navigator.pop(
//                     dialogContext,
//                   );

//                   _showMessage(
//                     'This category already exists.',
//                     isError: true,
//                   );

//                   return;
//                 }

//                 setState(() {
//                   _customCategories
//                       .add(category);

//                   _selectedCategories
//                       .add(category);
//                 });

//                 Navigator.pop(
//                   dialogContext,
//                 );
//               },
//               child: const Text(
//                 'Add Category',
//               ),
//             ),
//           ],
//         );
//       },
//     );

//     controller.dispose();
//   }

//   // ==============================================================
//   // CATEGORY SELECTION
//   // ==============================================================

//   void _toggleCategory(
//     String category,
//   ) {
//     setState(() {
//       if (_selectedCategories
//           .contains(category)) {
//         _selectedCategories
//             .remove(category);
//       } else {
//         _selectedCategories
//             .add(category);
//       }
//     });
//   }

//   // ==============================================================
//   // MESSAGE
//   // ==============================================================

//   void _showMessage(
//     String message, {
//     bool isError = false,
//   }) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context)
//         .hideCurrentSnackBar();

//     ScaffoldMessenger.of(context)
//         .showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor:
//             isError ? Colors.red : green,
//         behavior:
//             SnackBarBehavior.floating,
//         margin:
//             const EdgeInsets.all(16),
//         shape:
//             RoundedRectangleBorder(
//           borderRadius:
//               BorderRadius.circular(12),
//         ),
//       ),
//     );
//   }

//   // ==============================================================
//   // INPUT DECORATION
//   // ==============================================================

//   InputDecoration _inputDecoration({
//     required String label,
//     required IconData icon,
//     String? hint,
//   }) {
//     return InputDecoration(
//       labelText: label,
//       hintText: hint,

//       prefixIcon: Icon(
//         icon,
//         color: green,
//       ),

//       filled: true,
//       fillColor: Colors.white,

//       labelStyle: const TextStyle(
//         color: darkGreen,
//         fontWeight: FontWeight.w600,
//       ),

//       hintStyle: const TextStyle(
//         color: Colors.grey,
//       ),

//       border: OutlineInputBorder(
//         borderRadius:
//             BorderRadius.circular(14),
//         borderSide:
//             const BorderSide(
//           color: green,
//         ),
//       ),

//       enabledBorder:
//           OutlineInputBorder(
//         borderRadius:
//             BorderRadius.circular(14),
//         borderSide:
//             BorderSide(
//           color:
//               green.withValues(alpha: 0.65),
//         ),
//       ),

//       focusedBorder:
//           OutlineInputBorder(
//         borderRadius:
//             BorderRadius.circular(14),
//         borderSide:
//             const BorderSide(
//           color: green,
//           width: 2,
//         ),
//       ),

//       contentPadding:
//           const EdgeInsets.symmetric(
//         horizontal: 16,
//         vertical: 16,
//       ),
//     );
//   }

//   // ==============================================================
//   // BUILD
//   // ==============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor:
//           pageBackground,

//       resizeToAvoidBottomInset: true,

//       body: Stack(
//         children: [

//           // ======================================================
//           // FULL PAGE FOREST BACKGROUND
//           // ======================================================

//           Positioned.fill(
//             child: IgnorePointer(
//               child: Image.asset(
//                 'assets/images/WhatsApp Image 2026-09-05 at 11.44.48 AM.jpeg',
//                 fit: BoxFit.cover,
//                 alignment:
//                     Alignment.center,
//               ),
//             ),
//           ),

//           // ======================================================
//           // READABILITY OVERLAY
//           // ======================================================

//           Positioned.fill(
//             child: IgnorePointer(
//               child: Container(
//                 color: Colors.white
//                     .withValues(alpha: 0.15),
//               ),
//             ),
//           ),

//           // ======================================================
//           // PAGE
//           // ======================================================

//           SafeArea(
//             child: SingleChildScrollView(
//               padding:
//                   const EdgeInsets.fromLTRB(
//                 18,
//                 10,
//                 18,
//                 35,
//               ),
//               child: Column(
//                 crossAxisAlignment:
//                     CrossAxisAlignment.start,
//                 children: [

//                   // ==================================================
//                   // TOP BAR
//                   // ==================================================

//                   Row(
//                     children: [
//                       IconButton(
//                         onPressed: () {
//                           Navigator.pop(
//                             context,
//                           );
//                         },
//                         icon:
//                             const Icon(
//                           Icons.arrow_back,
//                           color: darkGreen,
//                         ),
//                       ),

//                       const SizedBox(
//                         width: 4,
//                       ),

//                       const Expanded(
//                         child: Column(
//                           crossAxisAlignment:
//                               CrossAxisAlignment
//                                   .start,
//                          // children: [
//                             // Text(
//                             //   'CITIZEN',
//                             //   style:
//                             //       TextStyle(
//                             //     fontSize: 25,
//                             //     fontWeight:
//                             //         FontWeight
//                             //             .w900,
//                             //     color:
//                             //         darkGreen,
//                             //     letterSpacing:
//                             //         1,
//                             //   ),
//                             // ),
//                             // Text(
//                             //   'INDIA',
//                             //   style:
//                             //       TextStyle(
//                             //     fontSize: 20,
//                             //     fontWeight:
//                             //         FontWeight
//                             //             .w900,
//                             //     color:
//                             //         orange,
//                             //     letterSpacing:
//                             //         2,
//                             //   ),
//                             // ),
//                             // Text(
//                             //   'Opportunities for Everyone',
//                             //   style:
//                             //       TextStyle(
//                             //     fontSize: 11,
//                             //     color:
//                             //         Colors.grey,
//                             //   ),
//                             // ),
//                           //],
//                         ),
//                       ),

//                       Container(
//                         width: 42,
//                         height: 42,
//                         decoration:
//                             BoxDecoration(
//                           color: Colors
//                               .deepPurple
//                               .withValues(alpha: 
//                                   0.10),
//                           shape:
//                               BoxShape.circle,
//                         ),
//                         child:
//                             const Icon(
//                           Icons.person,
//                           color:
//                               Colors.deepPurple,
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(
//                     height: 20,
//                   ),

//                   // ==================================================
//                   // TITLE
//                   // ==================================================

//                   const Center(
//                     child: Text.rich(
//                       TextSpan(
//                         children: [
//                           TextSpan(
//                             text: 'Rental ',
//                             style:
//                                 TextStyle(
//                               color:
//                                   darkGreen,
//                               fontSize: 27,
//                               fontWeight:
//                                   FontWeight
//                                       .w800,
//                             ),
//                           ),
//                           TextSpan(
//                             text:
//                                 'Registration',
//                             style:
//                                 TextStyle(
//                               color:
//                                   orange,
//                               fontSize: 27,
//                               fontWeight:
//                                   FontWeight
//                                       .w800,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 6,
//                   ),

//                   const Center(
//                     child: Text(
//                       'Create your rental profile',
//                       style: TextStyle(
//                         color: Colors.grey,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 25,
//                   ),

//                   // ==================================================
//                   // USERNAME
//                   // ==================================================

//                   const Text(
//                     'Username',
//                     style: TextStyle(
//                       color: darkGreen,
//                       fontSize: 15,
//                       fontWeight:
//                           FontWeight.bold,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 8,
//                   ),

//                   TextField(
//                     controller:
//                         _usernameController,
//                     textCapitalization:
//                         TextCapitalization.words,
//                     decoration:
//                         _inputDecoration(
//                       label: 'Username',
//                       hint:
//                           'Enter your name',
//                       icon:
//                           Icons.person_outline,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 18,
//                   ),

//                   // ==================================================
//                   // PHONE NUMBER
//                   // ==================================================

//                   const Text(
//                     'Mobile Number',
//                     style: TextStyle(
//                       color: darkGreen,
//                       fontSize: 15,
//                       fontWeight:
//                           FontWeight.bold,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 8,
//                   ),

//                   TextField(
//                     controller:
//                         _phoneController,
//                     keyboardType:
//                         TextInputType.phone,
//                     maxLength: 10,
//                     enabled:
//                         !_otpVerified,
//                     decoration:
//                         _inputDecoration(
//                       label:
//                           'Mobile Number',
//                       hint:
//                           '+91 Enter Mobile Number',
//                       icon:
//                           Icons.phone_outlined,
//                     ).copyWith(
//                       counterText: '',
//                       suffixIcon:
//                           _otpVerified
//                               ? const Icon(
//                                   Icons.verified,
//                                   color:
//                                       green,
//                                 )
//                               : null,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 12,
//                   ),

//                   // ==================================================
//                   // SEND OTP
//                   // ==================================================

//                   SizedBox(
//                     width:
//                         double.infinity,
//                     height: 52,
//                     child:
//                         ElevatedButton(
//                       onPressed:
//                           _sendingOtp ||
//                                   _otpVerified
//                               ? null
//                               : _sendOtp,
//                       style:
//                           ElevatedButton
//                               .styleFrom(
//                         backgroundColor:
//                             green,
//                         foregroundColor:
//                             Colors.white,
//                         disabledBackgroundColor:
//                             Colors.grey
//                                 .shade400,
//                         elevation: 2,
//                         shape:
//                             RoundedRectangleBorder(
//                           borderRadius:
//                               BorderRadius
//                                   .circular(
//                             14,
//                           ),
//                         ),
//                       ),
//                       child: _sendingOtp
//                           ? const SizedBox(
//                               width: 22,
//                               height: 22,
//                               child:
//                                   CircularProgressIndicator(
//                                 strokeWidth:
//                                     2.5,
//                                 color:
//                                     Colors.white,
//                               ),
//                             )
//                           : Text(
//                               _otpVerified
//                                   ? 'Mobile Number Verified'
//                                   : _otpSent
//                                       ? 'OTP Sent'
//                                       : 'Send OTP',
//                               style:
//                                   const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight:
//                                     FontWeight
//                                         .bold,
//                               ),
//                             ),
//                     ),
//                   ),

//                   // ==================================================
//                   // OTP SECTION
//                   // ==================================================

//                   if (_otpSent &&
//                       !_otpVerified)
//                     _buildOtpSection(),

//                   // ==================================================
//                   // VERIFIED MESSAGE
//                   // ==================================================

//                   if (_otpVerified)
//                     Container(
//                       width:
//                           double.infinity,
//                       margin:
//                           const EdgeInsets.only(
//                         top: 15,
//                       ),
//                       padding:
//                           const EdgeInsets.all(
//                         14,
//                       ),
//                       decoration:
//                           BoxDecoration(
//                         color: green
//                             .withValues(alpha: 
//                                 0.10),
//                         borderRadius:
//                             BorderRadius
//                                 .circular(
//                           14,
//                         ),
//                         border:
//                             Border.all(
//                           color: green
//                               .withValues(alpha: 
//                                   0.4),
//                         ),
//                       ),
//                       child: const Row(
//                         children: [
//                           Icon(
//                             Icons
//                                 .check_circle,
//                             color: green,
//                           ),
//                           SizedBox(
//                             width: 10,
//                           ),
//                           Expanded(
//                             child: Text(
//                               'Mobile number verified successfully.',
//                               style:
//                                   TextStyle(
//                                 color:
//                                     darkGreen,
//                                 fontWeight:
//                                     FontWeight
//                                         .w600,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                   const SizedBox(
//                     height: 22,
//                   ),

//                   // ==================================================
//                   // COMPANY NAME
//                   // ==================================================

//                   const Text(
//                     'Company Name',
//                     style: TextStyle(
//                       color: darkGreen,
//                       fontSize: 15,
//                       fontWeight:
//                           FontWeight.bold,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 8,
//                   ),

//                   TextField(
//                     controller:
//                         _companyController,
//                     textCapitalization:
//                         TextCapitalization.words,
//                     decoration:
//                         _inputDecoration(
//                       label:
//                           'Company Name (Optional)',
//                       hint:
//                           'Enter company name',
//                       icon:
//                           Icons.business_outlined,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 22,
//                   ),

//                   // ==================================================
//                   // CATEGORIES HEADER
//                   // ==================================================

//                   Row(
//                     children: [
//                       const Expanded(
//                         child: Text(
//                           'Rental Categories',
//                           style:
//                               TextStyle(
//                             color:
//                                 darkGreen,
//                             fontSize: 16,
//                             fontWeight:
//                                 FontWeight
//                                     .bold,
//                           ),
//                         ),
//                       ),

//                       Text(
//                         '${_selectedCategories.length} selected',
//                         style:
//                             const TextStyle(
//                           color: green,
//                           fontWeight:
//                               FontWeight
//                                   .w600,
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(
//                     height: 8,
//                   ),

//                   // ==================================================
//                   // CATEGORY FIELD
//                   // ==================================================

//                   GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         _showCategorySelector =
//                             !_showCategorySelector;
//                       });
//                     },
//                     child: Container(
//                       width:
//                           double.infinity,
//                       padding:
//                           const EdgeInsets
//                               .symmetric(
//                         horizontal: 15,
//                         vertical: 16,
//                       ),
//                       decoration:
//                           BoxDecoration(
//                         color: Colors.white,
//                         borderRadius:
//                             BorderRadius
//                                 .circular(
//                           14,
//                         ),
//                         border:
//                             Border.all(
//                           color: green
//                               .withValues(alpha: 
//                                   0.65),
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(
//                             Icons
//                                 .category_outlined,
//                             color: green,
//                           ),
//                           const SizedBox(
//                             width: 12,
//                           ),
//                           Expanded(
//                             child: Text(
//                               _selectedCategories
//                                       .isEmpty
//                                   ? 'Select rental categories'
//                                   : _selectedCategories
//                                       .join(', '),
//                               maxLines: 3,
//                               overflow:
//                                   TextOverflow
//                                       .ellipsis,
//                               style:
//                                   TextStyle(
//                                 color:
//                                     _selectedCategories
//                                             .isEmpty
//                                         ? Colors
//                                             .grey
//                                         : darkGreen,
//                                 fontWeight:
//                                     _selectedCategories
//                                             .isEmpty
//                                         ? FontWeight
//                                             .normal
//                                         : FontWeight
//                                             .w600,
//                               ),
//                             ),
//                           ),
//                           Icon(
//                             _showCategorySelector
//                                 ? Icons
//                                     .keyboard_arrow_up
//                                 : Icons
//                                     .keyboard_arrow_down,
//                             color: green,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   // ==================================================
//                   // CATEGORY SELECTOR
//                   // ==================================================

//                   if (_showCategorySelector)
//                     _buildCategorySelector(),

//                   const SizedBox(
//                     height: 22,
//                   ),

//                   // ==================================================
//                   // LOCATION
//                   // ==================================================

//                   const Text(
//                     'Rental Location',
//                     style: TextStyle(
//                       color: darkGreen,
//                       fontSize: 16,
//                       fontWeight:
//                           FontWeight.bold,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 8,
//                   ),

//                   _buildLocationButton(),

//                   const SizedBox(
//                     height: 30,
//                   ),

//                   // ==================================================
//                   // SUBMIT BUTTON
//                   // ==================================================

//                   _buildSubmitButton(),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   // ================================================================
// // RENTAL REGISTRATION SCREEN
// // PART 2 / 3
// //
// // UI helper methods
// // OTP
// // Categories
// // Location
// // ================================================================

// // ==============================================================
// // OTP SECTION
// // ==============================================================

// Widget _buildOtpSection() {
//   return Container(
//     margin: const EdgeInsets.only(top: 18),
//     padding: const EdgeInsets.all(16),
//     decoration: BoxDecoration(
//       color: Colors.white.withValues(alpha: 0.96),
//       borderRadius: BorderRadius.circular(18),
//       border: Border.all(
//         color: green.withValues(alpha: 0.45),
//       ),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withValues(alpha: 0.06),
//           blurRadius: 10,
//           offset: const Offset(0, 4),
//         ),
//       ],
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Row(
//           children: [
//             Icon(
//               Icons.lock_outline,
//               color: green,
//             ),
//             SizedBox(width: 8),
//             Text(
//               'Enter OTP',
//               style: TextStyle(
//                 color: darkGreen,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(height: 6),

//         const Text(
//           'Enter the 6-digit OTP sent to your mobile number.',
//           style: TextStyle(
//             color: Colors.grey,
//             fontSize: 13,
//           ),
//         ),

//         const SizedBox(height: 16),

//         // ----------------------------------------------------------
//         // SIX OTP BOXES
//         // ----------------------------------------------------------

//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: List.generate(
//             6,
//             (index) {
//               return SizedBox(
//                 width: 45,
//                 height: 58,
//                 child: TextField(
//                   controller:
//                       _otpControllers[index],
//                   focusNode:
//                       _otpFocusNodes[index],
//                   keyboardType:
//                       TextInputType.number,
//                   textAlign: TextAlign.center,
//                   maxLength: 1,

//                   style: const TextStyle(
//                     fontSize: 21,
//                     fontWeight: FontWeight.bold,
//                     color: darkGreen,
//                   ),

//                   decoration: InputDecoration(
//                     counterText: '',
//                     filled: true,
//                     fillColor:
//                         const Color(0xFFF8F5EE),

//                     border:
//                         OutlineInputBorder(
//                       borderRadius:
//                           BorderRadius.circular(12),
//                       borderSide:
//                           BorderSide(
//                         color: green
//                             .withValues(alpha: 0.55),
//                       ),
//                     ),

//                     enabledBorder:
//                         OutlineInputBorder(
//                       borderRadius:
//                           BorderRadius.circular(12),
//                       borderSide:
//                           BorderSide(
//                         color: green
//                             .withValues(alpha: 0.55),
//                       ),
//                     ),

//                     focusedBorder:
//                         OutlineInputBorder(
//                       borderRadius:
//                           BorderRadius.circular(12),
//                       borderSide:
//                           const BorderSide(
//                         color: green,
//                         width: 2,
//                       ),
//                     ),
//                   ),

//                   onChanged: (value) {
//                     _onOtpChanged(
//                       index,
//                       value,
//                     );
//                   },
//                 ),
//               );
//             },
//           ),
//         ),

//         const SizedBox(height: 18),

//         // ----------------------------------------------------------
//         // VERIFY BUTTON
//         // ----------------------------------------------------------

//         SizedBox(
//           width: double.infinity,
//           height: 48,
//           child: ElevatedButton(
//             onPressed:
//                 _verifyingOtp
//                     ? null
//                     : _verifyOtp,

//             style:
//                 ElevatedButton.styleFrom(
//               backgroundColor: darkGreen,
//               foregroundColor: Colors.white,
//               disabledBackgroundColor:
//                   Colors.grey.shade400,

//               shape:
//                   RoundedRectangleBorder(
//                 borderRadius:
//                     BorderRadius.circular(13),
//               ),
//             ),

//             child: _verifyingOtp
//                 ? const SizedBox(
//                     width: 21,
//                     height: 21,
//                     child:
//                         CircularProgressIndicator(
//                       strokeWidth: 2.5,
//                       color: Colors.white,
//                     ),
//                   )
//                 : const Text(
//                     'Verify OTP',
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight:
//                           FontWeight.bold,
//                     ),
//                   ),
//           ),
//         ),

//         const SizedBox(height: 14),

//         // ----------------------------------------------------------
//         // TIMER / RESEND
//         // ----------------------------------------------------------

//         Center(
//           child: _secondsRemaining > 0
//               ? Text(
//                   'Resend OTP in $_secondsRemaining seconds',
//                   style: const TextStyle(
//                     color: Colors.grey,
//                     fontSize: 13,
//                   ),
//                 )
//               : TextButton(
//                   onPressed: _resendOtp,
//                   child: const Text(
//                     'Resend OTP',
//                     style: TextStyle(
//                       color: green,
//                       fontWeight:
//                           FontWeight.bold,
//                     ),
//                   ),
//                 ),
//         ),

//         // ----------------------------------------------------------
//         // CHANGE NUMBER
//         // ----------------------------------------------------------

//         Center(
//           child: TextButton(
//             onPressed: () {
//               _otpTimer?.cancel();

//               for (final controller
//                   in _otpControllers) {
//                 controller.clear();
//               }

//               setState(() {
//                 _otpSent = false;
//                 _otpVerified = false;
//                 _verificationId = null;
//                 _secondsRemaining = 30;
//               });

//               Future.delayed(
//                 const Duration(
//                   milliseconds: 100,
//                 ),
//                 () {
//                   if (!mounted) return;

//                   FocusScope.of(context)
//                       .requestFocus(
//                     FocusNode(),
//                   );
//                 },
//               );
//             },
//             child: const Text(
//               'Change Number',
//               style: TextStyle(
//                 color: orange,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }

// // ==============================================================
// // CATEGORY SELECTOR
// // ==============================================================

// Widget _buildCategorySelector() {
//   return Container(
//     margin: const EdgeInsets.only(top: 10),
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white.withValues(alpha: 0.97),
//       borderRadius: BorderRadius.circular(18),
//       border: Border.all(
//         color: green.withValues(alpha: 0.45),
//       ),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withValues(alpha: 0.06),
//           blurRadius: 10,
//           offset: const Offset(0, 4),
//         ),
//       ],
//     ),
//     child: Column(
//       children: [

//         // ----------------------------------------------------------
//         // SEARCH CATEGORY
//         // ----------------------------------------------------------

//         TextField(
//           controller:
//               _categorySearchController,

//           decoration:
//               InputDecoration(
//             hintText:
//                 'Search rental category...',

//             prefixIcon:
//                 const Icon(
//               Icons.search,
//               color: green,
//             ),

//             suffixIcon:
//                 _categorySearchController
//                         .text
//                         .isNotEmpty
//                     ? IconButton(
//                         onPressed: () {
//                           _categorySearchController
//                               .clear();
//                         },
//                         icon:
//                             const Icon(
//                           Icons.clear,
//                           color: Colors.grey,
//                         ),
//                       )
//                     : null,

//             filled: true,
//             fillColor:
//                 const Color(0xFFF8F5EE),

//             border:
//                 OutlineInputBorder(
//               borderRadius:
//                   BorderRadius.circular(13),
//               borderSide:
//                   BorderSide.none,
//             ),

//             focusedBorder:
//                 OutlineInputBorder(
//               borderRadius:
//                   BorderRadius.circular(13),
//               borderSide:
//                   const BorderSide(
//                 color: green,
//                 width: 1.5,
//               ),
//             ),
//           ),
//         ),

//         const SizedBox(height: 12),

//         // ----------------------------------------------------------
//         // ADD YOUR OWN CATEGORY
//         // ----------------------------------------------------------

//         SizedBox(
//           width: double.infinity,
//           child: OutlinedButton.icon(
//             onPressed:
//                 _showAddCategoryDialog,

//             icon: const Icon(
//               Icons.add_circle_outline,
//               color: orange,
//             ),

//             label: const Text(
//               '+ Add your own category',
//               style: TextStyle(
//                 color: orange,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),

//             style:
//                 OutlinedButton.styleFrom(
//               side: BorderSide(
//                 color:
//                     orange.withValues(alpha: 0.65),
//               ),

//               shape:
//                   RoundedRectangleBorder(
//                 borderRadius:
//                     BorderRadius.circular(13),
//               ),

//               padding:
//                   const EdgeInsets.symmetric(
//                 vertical: 13,
//               ),
//             ),
//           ),
//         ),

//         const SizedBox(height: 12),

//         // ----------------------------------------------------------
//         // CATEGORY LIST
//         // ----------------------------------------------------------

//         if (_filteredCategories.isEmpty)
//           const Padding(
//             padding:
//                 EdgeInsets.symmetric(
//               vertical: 20,
//             ),
//             child: Column(
//               children: [
//                 Icon(
//                   Icons.search_off,
//                   size: 35,
//                   color: Colors.grey,
//                 ),
//                 SizedBox(height: 7),
//                 Text(
//                   'No category found.',
//                   style: TextStyle(
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//           )
//         else
//           ConstrainedBox(
//             constraints:
//                 const BoxConstraints(
//               maxHeight: 310,
//             ),
//             child: ListView.builder(
//               shrinkWrap: true,
//               itemCount:
//                   _filteredCategories.length,
//               itemBuilder:
//                   (context, index) {
//                 final String category =
//                     _filteredCategories[
//                         index];

//                 final bool selected =
//                     _selectedCategories
//                         .contains(category);

//                 return InkWell(
//                   borderRadius:
//                       BorderRadius.circular(
//                     12,
//                   ),

//                   onTap: () {
//                     _toggleCategory(
//                       category,
//                     );
//                   },

//                   child: Container(
//                     margin:
//                         const EdgeInsets.only(
//                       bottom: 6,
//                     ),

//                     padding:
//                         const EdgeInsets
//                             .symmetric(
//                       horizontal: 10,
//                       vertical: 10,
//                     ),

//                     decoration:
//                         BoxDecoration(
//                       color: selected
//                           ? green
//                               .withValues(alpha: 
//                                   0.09)
//                           : Colors.transparent,

//                       borderRadius:
//                           BorderRadius.circular(
//                         12,
//                       ),
//                     ),

//                     child: Row(
//                       children: [
//                         AnimatedContainer(
//                           duration:
//                               const Duration(
//                             milliseconds: 180,
//                           ),
//                           width: 25,
//                           height: 25,
//                           decoration:
//                               BoxDecoration(
//                             color: selected
//                                 ? green
//                                 : Colors
//                                     .white,

//                             borderRadius:
//                                 BorderRadius
//                                     .circular(
//                               7,
//                             ),

//                             border: Border.all(
//                               color: selected
//                                   ? green
//                                   : Colors
//                                       .grey
//                                       .shade400,
//                               width: 1.5,
//                             ),
//                           ),

//                           child: selected
//                               ? const Icon(
//                                   Icons.check,
//                                   size: 17,
//                                   color:
//                                       Colors.white,
//                                 )
//                               : null,
//                         ),

//                         const SizedBox(
//                           width: 12,
//                         ),

//                         Expanded(
//                           child: Text(
//                             category,
//                             style:
//                                 TextStyle(
//                               color:
//                                   darkGreen,
//                               fontWeight:
//                                   selected
//                                       ? FontWeight
//                                           .bold
//                                       : FontWeight
//                                           .w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),

//         // ----------------------------------------------------------
//         // SELECTED CATEGORY COUNT
//         // ----------------------------------------------------------

//         if (_selectedCategories.isNotEmpty)
//           Container(
//             margin:
//                 const EdgeInsets.only(
//               top: 8,
//             ),

//             padding:
//                 const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 9,
//             ),

//             decoration:
//                 BoxDecoration(
//               color:
//                   green.withValues(alpha: 0.08),
//               borderRadius:
//                   BorderRadius.circular(10),
//             ),

//             child: Row(
//               children: [
//                 const Icon(
//                   Icons.check_circle,
//                   size: 18,
//                   color: green,
//                 ),

//                 const SizedBox(
//                   width: 8,
//                 ),

//                 Expanded(
//                   child: Text(
//                     '${_selectedCategories.length} categor${_selectedCategories.length == 1 ? 'y' : 'ies'} selected',
//                     style:
//                         const TextStyle(
//                       color: darkGreen,
//                       fontWeight:
//                           FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//       ],
//     ),
//   );
// }

// // ==============================================================
// // LOCATION BUTTON
// // ==============================================================

// Widget _buildLocationButton() {
//   return Column(
//     children: [

//       InkWell(
//         borderRadius:
//             BorderRadius.circular(16),

//         onTap:
//             _attachCurrentLocation,

//         child: Container(
//           width: double.infinity,

//           padding:
//               const EdgeInsets.all(16),

//           decoration:
//               BoxDecoration(
//             color: Colors.white,
//             borderRadius:
//                 BorderRadius.circular(16),

//             border: Border.all(
//               color: _locationAttached
//                   ? green
//                   : green.withValues(alpha: 
//                       0.55,
//                     ),
//               width:
//                   _locationAttached
//                       ? 2
//                       : 1,
//             ),

//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black
//                     .withValues(alpha: 0.04),
//                 blurRadius: 8,
//                 offset:
//                     const Offset(0, 3),
//               ),
//             ],
//           ),

//           child: Row(
//             children: [

//               Container(
//                 width: 48,
//                 height: 48,

//                 decoration:
//                     BoxDecoration(
//                   color: _locationAttached
//                       ? green.withValues(alpha: 
//                           0.12,
//                         )
//                       : orange.withValues(alpha: 
//                           0.12,
//                         ),
//                   shape:
//                       BoxShape.circle,
//                 ),

//                 child:
//                     _gettingLocation
//                         ? const Padding(
//                             padding:
//                                 EdgeInsets.all(
//                               13,
//                             ),
//                             child:
//                                 CircularProgressIndicator(
//                               strokeWidth:
//                                   2.5,
//                               color: green,
//                             ),
//                           )
//                         : Icon(
//                             _locationAttached
//                                 ? Icons
//                                     .location_on
//                                 : Icons
//                                     .my_location,
//                             color:
//                                 _locationAttached
//                                     ? green
//                                     : orange,
//                           ),
//               ),

//               const SizedBox(
//                 width: 13,
//               ),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                   children: [

//                     Text(
//                       _locationAttached
//                           ? 'Location Attached'
//                           : 'Attach Current Location',

//                       style:
//                           const TextStyle(
//                         color: darkGreen,
//                         fontSize: 15,
//                         fontWeight:
//                             FontWeight.bold,
//                       ),
//                     ),

//                     const SizedBox(
//                       height: 4,
//                     ),

//                     Text(
//                       _locationAttached
//                           ? 'Your rental location is ready.'
//                           : 'Use your current location for your rental profile.',

//                       style:
//                           const TextStyle(
//                         color: Colors.grey,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               Icon(
//                 _locationAttached
//                     ? Icons.check_circle
//                     : Icons
//                         .arrow_forward_ios,
//                 size:
//                     _locationAttached
//                         ? 24
//                         : 17,
//                 color:
//                     _locationAttached
//                         ? green
//                         : Colors.grey,
//               ),
//             ],
//           ),
//         ),
//       ),

//       // ----------------------------------------------------------
//       // COORDINATES
//       // ----------------------------------------------------------

//       if (_currentPosition != null)
//         Container(
//           width: double.infinity,
//           margin:
//               const EdgeInsets.only(
//             top: 8,
//           ),
//           padding:
//               const EdgeInsets.all(11),
//           decoration:
//               BoxDecoration(
//             color:
//                 green.withValues(alpha: 0.07),
//             borderRadius:
//                 BorderRadius.circular(11),
//           ),
//           child: Row(
//             children: [
//               const Icon(
//                 Icons.pin_drop,
//                 size: 18,
//                 color: green,
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}   '
//                   'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
//                   style:
//                       const TextStyle(
//                     color: darkGreen,
//                     fontSize: 11,
//                     fontWeight:
//                         FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//     ],
//   );
// }
// // ================================================================
// // RENTAL REGISTRATION SCREEN
// // PART 3 / 3
// //
// // Submit rental profile
// // Hive storage
// // Firestore storage
// // Validation
// // ================================================================

// // ==============================================================
// // SUBMIT BUTTON
// // ==============================================================

// Widget _buildSubmitButton() {
//   return SizedBox(
//     width: double.infinity,
//     height: 56,

//     child: ElevatedButton(
//       onPressed:
//           _submitting
//               ? null
//               : _submitRentalProfile,

//       style:
//           ElevatedButton.styleFrom(
//         backgroundColor:
//             const Color(0xFF198B1E),

//         foregroundColor:
//             Colors.white,

//         disabledBackgroundColor:
//             Colors.grey.shade400,

//         elevation: 3,

//         shape:
//             RoundedRectangleBorder(
//           borderRadius:
//               BorderRadius.circular(16),
//         ),
//       ),

//       child: _submitting
//           ? const SizedBox(
//               width: 24,
//               height: 24,
//               child:
//                   CircularProgressIndicator(
//                 strokeWidth: 2.5,
//                 color: Colors.white,
//               ),
//             )
//           : const Row(
//               mainAxisAlignment:
//                   MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.check_circle_outline,
//                   size: 23,
//                 ),
//                 SizedBox(width: 9),
//                 Text(
//                   'Submit Rental Profile',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight:
//                         FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//     ),
//   );
// }

// // ==============================================================
// // VALIDATE FORM
// // ==============================================================

// bool _validateRentalForm() {
//   if (_usernameController.text
//       .trim()
//       .isEmpty) {
//     _showMessage(
//       'Please enter your username.',
//       isError: true,
//     );
//     return false;
//   }

//   if (!_isPhoneValid) {
//     _showMessage(
//       'Please enter a valid 10-digit mobile number.',
//       isError: true,
//     );
//     return false;
//   }

//   if (!_otpVerified) {
//     _showMessage(
//       'Please verify your mobile number with OTP.',
//       isError: true,
//     );
//     return false;
//   }

//   if (_selectedCategories.isEmpty) {
//     _showMessage(
//       'Please select at least one rental category.',
//       isError: true,
//     );

//     setState(() {
//       _showCategorySelector = true;
//     });

//     return false;
//   }

//   if (!_locationAttached ||
//       _currentPosition == null) {
//     _showMessage(
//       'Please attach your current location.',
//       isError: true,
//     );
//     return false;
//   }

//   return true;
// }

// // ==============================================================
// // SUBMIT RENTAL PROFILE
// // ==============================================================

// Future<void> _submitRentalProfile() async {
//   FocusScope.of(context).unfocus();

//   if (!_validateRentalForm()) {
//     return;
//   }

//   if (_submitting) return;

//   setState(() {
//     _submitting = true;
//   });

//   try {
//     // ============================================================
//     // CURRENT USER
//     // ============================================================

//     final User? user = _auth.currentUser;

//     if (user == null) {
//       if (mounted) {
//         setState(() {
//           _submitting = false;
//         });

//         _showMessage(
//           'Your mobile verification session has expired. Please verify again.',
//           isError: true,
//         );
//       }

//       return;
//     }

//     final String uid = user.uid;

//     final String username =
//         _usernameController.text.trim();

//     final String companyName =
//         _companyController.text.trim();

//     final String phoneNumber =
//         _fullPhoneNumber;

//     final List<String> categories =
//         _selectedCategories.toList();

//     // ============================================================
//     // LOCATION SAFETY
//     // ============================================================

//     if (_currentPosition == null) {
//       if (mounted) {
//         setState(() {
//           _submitting = false;
//         });

//         _showMessage(
//           'Please select your current location first.',
//           isError: true,
//         );
//       }

//       return;
//     }

//     final double latitude =
//         _currentPosition!.latitude;

//     final double longitude =
//         _currentPosition!.longitude;

//     // ============================================================
//     // RENTAL DATA
//     // ============================================================

//     final Map<String, dynamic> rentalData = {
//       'uid': uid,

//       'username': username,

//       'companyName':
//           companyName.isEmpty
//               ? null
//               : companyName,

//       'phoneNumber': phoneNumber,

//       'categories': categories,

//       'currentLocation': {
//         'latitude': latitude,
//         'longitude': longitude,
//       },

//       'location': {
//         'latitude': latitude,
//         'longitude': longitude,
//       },

//       'updatedAt':
//           FieldValue.serverTimestamp(),
//     };

//     // ============================================================
//     // SAVE LOCALLY FIRST
//     // ============================================================

//     try {
//       final Box box =
//           await Hive.openBox(
//         'rentalProfiles',
//       );

//       await box.put(
//         uid,
//         {
//           'uid': uid,
//           'username': username,
//           'companyName': companyName,
//           'phoneNumber': phoneNumber,
//           'categories': categories,
//           'latitude': latitude,
//           'longitude': longitude,
//         },
//       );

//       final Box settingsBox =
//           await Hive.openBox(
//         'appSettings',
//       );

//       await settingsBox.put(
//         'userRole',
//         'rental',
//       );

//       await settingsBox.put(
//         'isRentalRegistered',
//         true,
//       );

//       await settingsBox.put(
//         'rentalUid',
//         uid,
//       );
//     } catch (e) {
//       debugPrint(
//         'Rental Hive save error: $e',
//       );
//     }

//     // ============================================================
//     // STOP LOADING
//     // ============================================================

//     if (!mounted) return;

//     setState(() {
//       _submitting = false;
//     });

//     // ============================================================
//     // GO TO HOME IMMEDIATELY
//     // ============================================================

//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             const ScreenHome(),
//       ),
//       (route) => false,
//     );

//     // ============================================================
//     // FIRESTORE SYNC IN BACKGROUND
//     // ============================================================

//     try {
//       await _firestore
//           .collection('rentals')
//           .doc(uid)
//           .set(
//             rentalData,
//             SetOptions(
//               merge: true,
//             ),
//           );

//       debugPrint(
//         'Rental Firestore sync successful.',
//       );
//     } catch (e) {
//       debugPrint(
//         'Rental Firestore sync failed: $e',
//       );
//     }
//   } catch (e) {
//     debugPrint(
//       'Rental submit error: $e',
//     );

//     if (mounted) {
//       setState(() {
//         _submitting = false;
//       });

//       _showMessage(
//         'Unable to save rental profile. Please try again.',
//         isError: true,
//       );
//     }
//   }
// }
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
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jober_india/jober_indiaScreens.dart/common_profile_services.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_camera_capture.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_home.dart';
import 'package:jober_india/l10n/app_localizations.dart';
import 'package:jober_india/screens/location_localization.dart';

import '../Privacy&Terms/privacy_terms_section.dart';

// class RentalsLocation {
//   final String placeName;
//   final double latitude;
//   final double longitude;

//   RentalsLocation({
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

//   factory RentalsLocation.fromMap(Map<String, dynamic> map) {
//     return RentalsLocation(
//       placeName: map['placeName'] ?? '',
//       latitude: (map['latitude'] ?? 0).toDouble(),
//       longitude: (map['longitude'] ?? 0).toDouble(),
//     );
//   }
// }

class RentalsLocation {
  final String placeName;
  final double? latitude;
  final double? longitude;

  RentalsLocation({
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

  factory RentalsLocation.fromMap(
    Map<String, dynamic> map,
  ) {
    return RentalsLocation(
      placeName: map['placeName']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

class RentalLoginScreen extends StatefulWidget {
  const RentalLoginScreen({super.key});

  @override
  State<RentalLoginScreen> createState() =>
      _RentalLoginScreenState();
}

class _RentalLoginScreenState
    extends State<RentalLoginScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryGreen = Color(0xFF12652F);
  static const Color backgroundColor = Colors.white;
  static const Color darkText = Color(0xFF222222);
  static const Color green =
      //Color(0xFF16803C);
      Color(0xFF138808);

  // static const Color submitGreen =
  //     Color(0xFF159B16);

  static const Color lightFill =
      Color(0xFFF9F9F9);


  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController mobileController =
      TextEditingController();

  final TextEditingController otpController =
      TextEditingController();

  final TextEditingController secondaryPhoneController =
    TextEditingController();

  final TextEditingController companyController =
      TextEditingController();

  final TextEditingController _shopLocationController =
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

  bool privacyPolicyAccepted = false;
  String? privacyPolicyError;
   // ==========================================================
  // LOCATION
  // ==========================================================
RentalsLocation? currentLocation;

bool isGettingLocation = false;
bool isSearchingLocation = false;

// Used to invalidate an older location request
int _locationRequestId = 0;

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
  // FORM VARIABLES
  // ============================================================


  bool gettingLocation = false;

  bool locationAttached = false;

  Position? currentPosition;

  // ============================================================
  // ERROR VARIABLES
  // ============================================================

 bool nameError = false;
bool mobileError = false;
//bool otpError = false;
bool secondaryMobileError = false;
bool categoryError = false;
bool locationError = false;

String nameErrorMessage = '';
String mobileErrorMessage = '';
String secondaryMobileErrorMessage = '';
String categoryErrorMessage = '';
String locationErrorMessage = '';


   File? profilePhoto;
  String? profilePhotoUrl;
  bool isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();


  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    //  filteredCategories =
    //     List<String>.from(
    //   rentalCategories,
    // );
    filteredCategories = allCategories.toList();

 filteredStates = List<String>.from(indiaStates);

  loadDistricts();

    categorySearchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    timer?.cancel();

    nameController.dispose();
    mobileController.dispose();
    otpController.dispose();
    secondaryPhoneController.dispose();
    companyController.dispose();
    categorySearchController.dispose();
    customCategoryController.dispose();
    descriptionController.dispose();
    stateSearchController.dispose();
    districtSearchController.dispose();


    super.dispose();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

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

  // ============================================================
  // PHONE NUMBER
  // ============================================================

  String get cleanMobileNumber {
    String mobile = mobileController.text
        .replaceAll(RegExp(r'[^0-9]'), '');

    if (mobile.startsWith('91') &&
        mobile.length > 10) {
      mobile = mobile.substring(
        mobile.length - 10,
      );
    }

    return mobile;
  }

  String get fullPhoneNumber {
    return '+91$cleanMobileNumber';
  }

  bool get isPhoneValid {
    return cleanMobileNumber.length == 10;
  }

  // ==============================================================
  // SEND OTP
  // ===============================================================

Future<void> sendOTP({bool isResend = false}) async {
  if (isSendingOtp || isVerifying) return;

  final phone = mobileController.text.trim();

  if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
    showMessage(AppLocalizations.of(context)!.enteradigitmobilenumber,
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
  // LOCATION SECTION
  // ============================================================
 Widget locationSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Rentals Location',
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
                      'Add your Rental location',
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
                              : 'Use Rental Location',
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
            labelText: 'Rentals Location',
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
  currentLocation = RentalsLocation(
    placeName: placeName.trim(),
    latitude: null,
    longitude: null,
  );
  locationError = false;
  isGettingLocation = false;
  isSearchingLocation = false;
});

showMessage(
  'Rentals location added.',
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
  currentLocation = RentalsLocation(
    placeName: placeName,
    latitude: position.latitude,
    longitude: position.longitude,
  );

  locationError = false;
});

    showMessage(
      'Rentals location added.',
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

   Widget descriptionSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Rental Description (Optional)',
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
  // FORM VALIDATION
  // ============================================================

bool validateRentalForm() {
  bool isValid = true;

  final String name =
      nameController.text.trim();

  final String mobile =
      cleanMobileNumber;

  final String secondaryMobile =
      secondaryPhoneController.text
          .replaceAll(RegExp(r'[^0-9]'), '');

  // ==========================================================
  // RESET VALIDATION
  // ==========================================================

  setState(() {
    nameError = false;
    mobileError = false;
    secondaryMobileError = false;
    categoryError = false;
    stateError = '';

    // LOCATION IS OPTIONAL
    //locationError = false;

    nameErrorMessage = '';
    mobileErrorMessage = '';
    secondaryMobileErrorMessage = '';
    categoryErrorMessage = '';
    locationErrorMessage = '';
  });

  // ==========================================================
  // USERNAME / NAME - REQUIRED
  // ==========================================================

  if (name.isEmpty) {
    nameError = true;
    nameErrorMessage =
        'Please enter your name.';
    isValid = false;
  }

  // ==========================================================
  // PRIMARY MOBILE - REQUIRED
  // ==========================================================

  if (mobile.isEmpty) {
    mobileError = true;
    mobileErrorMessage =
        'Please enter and verify The OTP.';
    isValid = false;
  } else if (mobile.length != 10) {
    mobileError = true;
    mobileErrorMessage = AppLocalizations.of(context)!.enteradigitmobilenumber;
       // 'Enter a valid 10-digit mobile number.';
    isValid = false;
  }

  // ==========================================================
  // OTP - REQUIRED
  // ==========================================================
if (!otpVerified) {
  mobileError = true;
  mobileErrorMessage =
      'Please verify your mobile number with OTP.';
  isValid = false;
}

  // ==========================================================
  // SECONDARY MOBILE - REQUIRED
  // ==========================================================

  if (secondaryMobile.isEmpty) {
    secondaryMobileError = true;
    secondaryMobileErrorMessage =
        'Please enter your secondary mobile number.';
    isValid = false;
  } else if (secondaryMobile.length != 10) {
    secondaryMobileError = true;
    secondaryMobileErrorMessage = AppLocalizations.of(context)!.enteradigitmobilenumber;
       // 'Enter a valid 10-digit secondary mobile number.';
    isValid = false;
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
  isValid = false;
}

  // ==========================================================
  // RENTAL CATEGORY - REQUIRED
  // ==========================================================

  if (selectedCategories.isEmpty) {
    categoryError = true;
    categoryErrorMessage =
        'Please select at least one rental category.';
    isValid = false;
  }

  // // ============================================================
  // // CURRENT LOCATION - REQUIRED
  // // ============================================================

  // if (currentLocation == null) {
  //   locationError = true;
  //   isValid = true;
  // }
   // ==========================================================
// GARAGE LOCATION
// ==========================================================

if (currentLocation == null) {
  locationError = true;
  isValid = true;
} else {
  locationError = false;
}
  // ==========================================================
  // PRIVACY POLICY / TERMS - REQUIRED
  // ==========================================================

  if (!privacyPolicyAccepted) {
    privacyPolicyError =
        'Please accept the Privacy Policy and Terms & Conditions.';
    isValid = false;
  } else {
    privacyPolicyError = null;
  }

  // ==========================================================
  // UPDATE UI
  // ==========================================================

  setState(() {});

  // ==========================================================
  // SHOW FIRST ERROR
  // ==========================================================

  if (!isValid) {
    if (nameError) {
      showMessage(
        nameErrorMessage,
        error: true,
      );
    } else if (mobileError) {
      showMessage(
        mobileErrorMessage,
        error: true,
      );
    } else if (otpError) {
      showMessage(
        otpErrorMessage,
        error: true,
      );
    } else if (secondaryMobileError) {
      showMessage(
        secondaryMobileErrorMessage,
        error: true,
      );
    } else if (categoryError) {
      showMessage(
        categoryErrorMessage,
        error: true,
      );
    } else if (!privacyPolicyAccepted) {
      showMessage(
        privacyPolicyError!,
        error: true,
      );
    }

    return false;
  }

  return true;
}

 // ============================================================
  // CATEGORY TOGGLE
  // ============================================================

   Widget categorySection() {
    final categories =
        filteredCategories;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        sectionTitle(
          'Rental Categories',
        ),

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
                                    'Select Rentals',
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
  Padding(
    padding: const EdgeInsets.only(
      left: 12,
      top: 5,
    ),
    child: Text(
      categoryErrorMessage.isEmpty
          ? 'Please select at least one rental category.'
          : categoryErrorMessage,
      style: const TextStyle(
        color: Colors.red,
        fontSize: 12,
      ),
    ),
  ),
      ],
    );
  }

    // ============================================================
  // RENTAL CATEGORIES
  // ============================================================
  bool isCategoryDropdownOpen = false;

  final List<String> rentalCategories = [
    'Premium Car Rent',
    'Car Rent',
    'Bike Rent',
    'Car & Bike Rent',
    'Flat',
    'House',
    'Shops',
    'Tools',
    'Dress',
  ];

  final List<String> selectedCategories = [];

   final List<String> customCategories = [];

  List<String> filteredCategories = [];

void addCustomCategory(BuildContext dialogContext) {
  final String category =
      customCategoryController.text.trim();

  if (category.isEmpty) {
    showMessage('Please enter a category.');
    return;
  }

  // Find an existing category without case sensitivity.
  final int existingIndex = allCategories.indexWhere(
    (item) =>
        item.trim().toLowerCase() ==
        category.toLowerCase(),
  );

  late final String actualCategory;

  setState(() {
    if (existingIndex != -1) {
      actualCategory = allCategories[existingIndex];
    } else {
      // Add new custom category.
      customCategories.add(category);
      actualCategory = category;
    }

    // Automatically select the added category.
    if (!selectedCategories.any(
      (item) =>
          item.toLowerCase() ==
          actualCategory.toLowerCase(),
    )) {
      selectedCategories.add(actualCategory);
    }

    // Refresh the category list.
    filteredCategories = allCategories.toList();

    categoryError = false;
  });

  customCategoryController.clear();
  categorySearchController.clear();

  // Close the correct dialog.
  Navigator.pop(dialogContext);

  showMessage('$actualCategory added.');
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

            textCapitalization:
                TextCapitalization.words,

            maxLength: 50,

            decoration:
                InputDecoration(

              hintText:
                  'Enter Rental category',

              prefixIcon:
                  const Icon(
                Icons.work_outline,
                color: green,
              ),

              filled: true,

              fillColor:
                  lightFill,

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

              // onPressed:
              //     addCustomCategory,
              onPressed: () {
  addCustomCategory(dialogContext);
},

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

  List<String> get allCategories {
  final List<String> result = [];

  for (final category in rentalCategories) {
    if (!result.any(
      (item) =>
          item.toLowerCase() ==
          category.toLowerCase(),
    )) {
      result.add(category);
    }
  }

  for (final category in customCategories) {
    if (!result.any(
      (item) =>
          item.toLowerCase() ==
          category.toLowerCase(),
    )) {
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

 Future<void> saveRentalToFirestore({
  required String uid,
  required Map<String, dynamic> rentalData,
}) async {
  try {
    await firestore
        .collection('rentals')
        .doc(uid)
        .set(
          rentalData,
          SetOptions(merge: true),
        );

    debugPrint(
      'Rental profile saved successfully: $uid',
    );
  } on FirebaseException catch (e) {
    debugPrint(
      'Rental Firestore error: ${e.code} - ${e.message}',
    );

    rethrow;
  } catch (e) {
    debugPrint(
      'Rental Firestore unknown error: $e',
    );

    rethrow;
  }
}
  // ============================================================
  // SUBMIT RENTAL PROFILE
  // ============================================================

 Future<void> submitRentalProfile() async {
  if (isSubmitting) return;

  FocusScope.of(context).unfocus();

  // ==========================================================
  // VALIDATE EVERYTHING FIRST
  // ==========================================================

  if (!validateRentalForm()) {
    return;
  }

  final User? user = auth.currentUser;

  if (user == null) {
    showMessage(
      'Please verify your mobile number first.',
      error: true,
    );
    return;
  }

  final RentalsLocation? location =
      currentLocation;

  if (!mounted) return;

  setState(() {
    isSubmitting = true;
  });

  try {
    // ========================================================
    // BASIC DATA
    // ========================================================

    final String name =
        nameController.text.trim();

    final String company =
        companyController.text.trim();

    final String phone =
        cleanMobileNumber;

    final String secondaryPhone =
        secondaryPhoneController.text
            .replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );

    final String description =
        descriptionController.text.trim();

    // ========================================================
    // PROFILE PHOTO
    // OPTIONAL
    // ========================================================

    String? photoUrl =
        profilePhotoUrl;

    if (profilePhoto != null) {
      photoUrl = await uploadProfilePhoto(
        user.uid,
      );

      if (photoUrl == null) {
        debugPrint(
          'Rental profile photo upload failed.',
        );
      }
    }

    // ========================================================
    // RENTAL DATA
    // ========================================================

    final Map<String, dynamic> rentalData = {
      'uid': user.uid,

      // USERNAME / NAME
      'name': name,
      'username': name,

      // COMPANY
      'companyName': company,

      // PRIMARY MOBILE
      'phoneNumber':
          '+91$phone',

      // SECONDARY MOBILE
      'secondaryPhoneNumber':
          '+91$secondaryPhone',

      'state': selectedState!.trim(),
'district': selectedDistrict!.trim(),
'nearestTown': nearestCityController.text.trim(),

      // CATEGORIES
      'categories':
          List<String>.from(
        selectedCategories,
      ),

      // DESCRIPTION
      'description':
          description,

      // ROLE
      'role': 'rental',

      // LOCATION
if (location != null) ...{
  'latitude': location.latitude,
  'longitude': location.longitude,

  'currentLocation': {
    'placeName': location.placeName,
    'latitude': location.latitude,
    'longitude': location.longitude,
  },
},
      // STATUS
      'isRegistered': true,
      'isActive': true,

      // PROFILE PHOTO
      if (photoUrl != null &&
          photoUrl.isNotEmpty)
        'profilePhotoUrl':
            photoUrl,

      // TIMESTAMP
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    // ========================================================
    // FIRESTORE
    // ========================================================

    await saveRentalToFirestore(
      uid: user.uid,
      rentalData: rentalData,
    );

    // ========================================================
    // HIVE
    // ========================================================

    final Box rentalBox =
        await Hive.openBox(
      'rentalProfiles',
    );

    await rentalBox.put(
      user.uid,
      {
        'uid': user.uid,

        'name': name,

        'username': name,

        'companyName': company,

        'phoneNumber':
            '+91$phone',

        'secondaryPhoneNumber':
            '+91$secondaryPhone',

        'state': selectedState!.trim(),
'district': selectedDistrict!.trim(),
'nearestTown': nearestCityController.text.trim(),

        'categories':
            List<String>.from(
          selectedCategories,
        ),

        'description':
            description,

        'role': 'rental',

        if (location != null) ...{
  'latitude': location.latitude,
  'longitude': location.longitude,
  'placeName': location.placeName,
},

        'profilePhotoUrl':
            photoUrl ?? '',

        'isRegistered': true,

        'isActive': true,
      },
    );

    // ========================================================
    // APP SETTINGS
    // ========================================================

    final Box settingsBox =
        await Hive.openBox(
      'appSettings',
    );

    await settingsBox.put(
      'userRole',
      'rental',
    );

    await settingsBox.put(
      'isRentalRegistered',
      true,
    );

    await settingsBox.put(
      'rentalUid',
      user.uid,
    );

    // ========================================================
    // COMMON LOGIN
    // ========================================================

    await CommonProfileService.saveLogin(
      uid: user.uid,
      name: name,
      mobile: phone,
      role: 'rental',
    );

    // ========================================================
    // SUCCESS
    // ========================================================

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ScreenHome(),
      ),
      (route) => false,
    );
  } on FirebaseException catch (e) {
    debugPrint(
      'Rental submit Firebase error: '
      '${e.code} - ${e.message}',
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    switch (e.code) {
      case 'permission-denied':
        showMessage(
          'You do not have permission to save this profile.',
          error: true,
        );
        break;

      case 'unavailable':
      case 'deadline-exceeded':
        showMessage(
          'Network is slow. Please check your internet and try again.',
          error: true,
        );
        break;

      case 'unauthenticated':
        showMessage(
          'Your login session expired. Please verify again.',
          error: true,
        );
        break;

      default:
        showMessage(
          'Unable to save rental profile. Please try again.',
          error: true,
        );
    }
  } catch (e) {
    debugPrint(
      'Rental submit error: $e',
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    showMessage(
      'Unable to create rental profile. Please try again.',
      error: true,
    );
  }
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
  color: verified
      ? const Color(0xFF16803C)
      : mobileError
          ? Colors.red
          : const Color(0xFFD5D5D5),
  width: verified || mobileError ? 2 : 1.5,
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

  //  InputDecoration fieldDecoration({
  //   required String hint,
  //   IconData? icon,
  //   bool error = false
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

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration inputDecoration({
    required String hint,
    IconData? icon,
    bool error = false,
  }) {
    return InputDecoration(
      hintText: hint,

      prefixIcon:
          icon == null
              ? null
              : Icon(
                  icon,
                  color: primaryGreen,
                  size: 21,
                ),

      filled: true,

      fillColor: Colors.white,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),

        borderSide:
            BorderSide(
          color: Colors.grey.shade300,
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),

        borderSide:
            BorderSide(
          color: error
              ? Colors.red
              : Colors.grey.shade300,

          width:
              error ? 1.5 : 1,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),

        borderSide: BorderSide(
          color:
              error
                  ? Colors.red
                  : primaryGreen,

          width: 1.7,
        ),
      ),
    );
  }

  // ============================================================
  // SUBMIT BUTTON
  // ============================================================

  Widget buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,

      child: ElevatedButton(
        onPressed:
            isSubmitting
                ? null
                : submitRentalProfile,

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              primaryGreen,

          foregroundColor:
              Colors.white,

          disabledBackgroundColor:
              Colors.grey.shade400,

          elevation: 0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),

        child:
            isSubmitting
                ? const SizedBox(
                    width: 23,
                    height: 23,

                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.5,

                      valueColor:
                          AlwaysStoppedAnimation<
                              Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : const Text(
                    'SUBMIT RENTAL PROFILE',

                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
      ),
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
  // MAIN BUILD
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
      backgroundColor: backgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: darkText,
        centerTitle: true,

       
         title: RichText(text: 
          TextSpan(children: [
        TextSpan(text: 'Rental',
                   style: TextStyle(
                  color:
                      Color(0xFF08744F),
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
             )
          ),
          TextSpan(
                  text:  AppLocalizations.of(context)!.registration,
                  //'Registration',
                  style: TextStyle(
                  color:
                      Colors.red,
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
             )
          ),
        ]
      )
   ),
        
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // ==================================================
              // HEADING
              // ==================================================

              const Text(
                'Create your rental profile',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // NAME
              // ==================================================

              const Text(
                'Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 7),

             TextField(
  controller: nameController,

  textCapitalization:
      TextCapitalization.words,

  onChanged: (_) {
    if (nameError) {
      setState(() {
        nameError = false;
        nameErrorMessage = '';
      });
    }
  },

  decoration: inputDecoration(
    hint: 'Enter your name',
    icon: Icons.person_outline,
    error: nameError,
  ),
),

if (nameError &&
    nameErrorMessage.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(
      left: 5,
      top: 5,
    ),
    child: Text(
      nameErrorMessage,
      style: const TextStyle(
        color: Colors.red,
        fontSize: 12,
      ),
    ),
  ),
              const SizedBox(height: 18),

              // ==================================================
              // MOBILE NUMBER
              // ==================================================

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

                    child: Text( AppLocalizations.of(context)!.enteradigitmobilenumber,
                     // 'Enter a valid 10-digit number',

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

              // ==================================================
              // COMPANY NAME
              // ==================================================

              const Text(
                'Company Name (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 7),

              TextField(
                controller: companyController,

                textCapitalization:
                    TextCapitalization.words,

                decoration: inputDecoration(
                  hint: 'Enter company name',
                  icon:
                      Icons.business_outlined,
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // RENTAL CATEGORY
              // ==================================================

              categorySection(),
              const SizedBox(height: 20),
              descriptionSection(),


              const SizedBox(height: 20),
              sectionTitle('Profile Photo'),
              _profilePhotoSection(),
              const SizedBox(height: 20),
              // ==================================================
              // CURRENT LOCATION
              // ==================================================

locationSection(),

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

              // ==================================================
              // SUBMIT BUTTON
              // ==================================================

              buildSubmitButton(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}