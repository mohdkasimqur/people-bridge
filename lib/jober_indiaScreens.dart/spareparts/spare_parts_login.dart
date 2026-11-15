// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:hive_flutter/hive_flutter.dart';

// class AutoSparePartsLoginPage extends StatefulWidget {
//   const AutoSparePartsLoginPage({super.key});

//   @override
//   State<AutoSparePartsLoginPage> createState() =>
//       _AutoSparePartsLoginPageState();
// }

// class _AutoSparePartsLoginPageState
//     extends State<AutoSparePartsLoginPage> {
//   // ============================================================
//   // CONTROLLERS
//   // ============================================================

//   final TextEditingController usernameController =
//       TextEditingController();

//   final TextEditingController mobileController =
//       TextEditingController();

//   final TextEditingController shopNameController =
//       TextEditingController();

//   final TextEditingController otpController =
//       TextEditingController();

//   final TextEditingController categorySearchController =
//       TextEditingController();

//   final TextEditingController customCategoryController =
//       TextEditingController();

//   // ============================================================
//   // FOCUS NODES
//   // ============================================================

//   final FocusNode usernameFocus = FocusNode();

//   final FocusNode mobileFocus = FocusNode();

//   final FocusNode shopNameFocus = FocusNode();

//   final FocusNode otpFocus = FocusNode();

//   // ============================================================
//   // FIREBASE
//   // ============================================================

//   final FirebaseAuth _auth =
//       FirebaseAuth.instance;

//   final FirebaseFirestore _firestore =
//       FirebaseFirestore.instance;

//   String? verificationId;

//   // ============================================================
//   // OTP VARIABLES
//   // ============================================================

//   bool otpSent = false;

//   bool otpVerified = false;

//   bool sendingOtp = false;

//   bool verifyingOtp = false;

//   int otpSeconds = 30;

//   Timer? otpTimer;

//   // ============================================================
//   // CATEGORY VARIABLES
//   // ============================================================

//   final List<String> defaultCategories = [
//     'All Auto Spare Parts',
//     '4 Wheeler Spare Parts',
//     '3 Wheeler Spare Parts',
//     '2 Wheeler Spare Parts',
//     '6 Wheeler Spare Parts',
//     'JCB Spare Parts',
//   ];

//   List<String> filteredCategories = [];

//   String? selectedCategory;

//   // ============================================================
//   // EXPERIENCE
//   // ============================================================

//   final List<String> experienceOptions = [
//     'New Shop',
//     'Less than 1 year',
//     '1 to 5 years',
//     '5 to 10 years',
//     '10 to 15 years',
//     '15 to 20 years',
//     'Above 20 years',
//   ];

//   String? selectedExperience;

//   // ============================================================
//   // CURRENT LOCATION
//   // ============================================================

//   Position? currentPosition;

//   bool loadingLocation = false;

//   // ============================================================
//   // SUBMIT
//   // ============================================================

//   bool submitting = false;

//   // ============================================================
//   // INIT STATE
//   // ============================================================

//   @override
//   void initState() {
//     super.initState();

//     filteredCategories =
//         List<String>.from(
//       defaultCategories,
//     );

//     categorySearchController.addListener(
//       _filterCategories,
//     );
//   }

//   // ============================================================
//   // CATEGORY SEARCH
//   // ============================================================

//   void _filterCategories() {
//     final String query =
//         categorySearchController.text
//             .trim()
//             .toLowerCase();

//     if (!mounted) return;

//     setState(() {
//       if (query.isEmpty) {
//         filteredCategories =
//             List<String>.from(
//           defaultCategories,
//         );
//       } else {
//         filteredCategories =
//             defaultCategories
//                 .where(
//                   (category) =>
//                       category
//                           .toLowerCase()
//                           .contains(query),
//                 )
//                 .toList();
//       }
//     });
//   }

//   // ============================================================
//   // SEND OTP
//   // ============================================================

//   Future<void> sendOtp() async {
//     if (sendingOtp) return;

//     final String mobile =
//         mobileController.text.trim();

//     if (mobile.length != 10) {
//       _showMessage(
//         'Please enter a valid 10-digit mobile number.',
//       );
//       return;
//     }

//     FocusScope.of(context).unfocus();

//     setState(() {
//       sendingOtp = true;
//       otpVerified = false;
//     });

//     try {
//       await _auth.verifyPhoneNumber(
//         phoneNumber: '+91$mobile',

//         verificationCompleted:
//             (PhoneAuthCredential credential) async {
//           try {
//             await _auth.signInWithCredential(
//               credential,
//             );

//             if (!mounted) return;

//             setState(() {
//               otpSent = true;
//               otpVerified = true;
//               sendingOtp = false;
//             });
//           } catch (_) {
//             if (!mounted) return;

//             setState(() {
//               sendingOtp = false;
//             });
//           }
//         },

//         verificationFailed:
//             (FirebaseAuthException error) {
//           if (!mounted) return;

//           setState(() {
//             sendingOtp = false;
//           });

//           _showMessage(
//             error.message ??
//                 'Unable to send OTP.',
//           );
//         },

//         codeSent:
//             (String id, int? resendToken) {
//           if (!mounted) return;

//           verificationId = id;

//           setState(() {
//             otpSent = true;
//             sendingOtp = false;
//             otpVerified = false;
//           });

//           _startOtpTimer();

//           _showMessage(
//             'OTP sent successfully.',
//           );

//           Future.delayed(
//             const Duration(
//               milliseconds: 300,
//             ),
//             () {
//               if (mounted) {
//                 otpFocus.requestFocus();
//               }
//             },
//           );
//         },

//         codeAutoRetrievalTimeout:
//             (String id) {
//           verificationId = id;
//         },
//       );
//     } catch (_) {
//       if (!mounted) return;

//       setState(() {
//         sendingOtp = false;
//       });

//       _showMessage(
//         'Something went wrong while sending OTP.',
//       );
//     }
//   }

//   // ============================================================
//   // OTP TIMER
//   // ============================================================

//   void _startOtpTimer() {
//     otpTimer?.cancel();

//     setState(() {
//       otpSeconds = 30;
//     });

//     otpTimer = Timer.periodic(
//       const Duration(seconds: 1),
//       (timer) {
//         if (!mounted) {
//           timer.cancel();
//           return;
//         }

//         if (otpSeconds <= 1) {
//           timer.cancel();

//           setState(() {
//             otpSeconds = 0;
//           });
//         } else {
//           setState(() {
//             otpSeconds--;
//           });
//         }
//       },
//     );
//   }

//   // ============================================================
//   // VERIFY OTP
//   // ============================================================

//   Future<void> verifyOtp() async {
//     if (verifyingOtp) return;

//     if (verificationId == null) {
//       _showMessage(
//         'Please request OTP first.',
//       );
//       return;
//     }

//     final String otp =
//         otpController.text.trim();

//     if (otp.length != 6) {
//       _showMessage(
//         'Please enter the 6-digit OTP.',
//       );
//       return;
//     }

//     FocusScope.of(context).unfocus();

//     setState(() {
//       verifyingOtp = true;
//     });

//     try {
//       final PhoneAuthCredential credential =
//           PhoneAuthProvider.credential(
//         verificationId: verificationId!,
//         smsCode: otp,
//       );

//       await _auth.signInWithCredential(
//         credential,
//       );

//       if (!mounted) return;

//       setState(() {
//         otpVerified = true;
//         verifyingOtp = false;
//       });

//       _showMessage(
//         'Mobile number verified.',
//       );
//     } on FirebaseAuthException catch (error) {
//       if (!mounted) return;

//       setState(() {
//         verifyingOtp = false;
//       });

//       _showMessage(
//         error.message ??
//             'Invalid OTP.',
//       );
//     } catch (_) {
//       if (!mounted) return;

//       setState(() {
//         verifyingOtp = false;
//       });

//       _showMessage(
//         'Unable to verify OTP.',
//       );
//     }
//   }
//   // ============================================================
//   // INPUT DECORATION
//   // ============================================================

//   InputDecoration _inputDecoration({
//     required String label,
//     required IconData icon,
//   }) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon),
//       filled: true,
//       fillColor: Colors.grey.shade50,

//       border: OutlineInputBorder(
//         borderRadius:
//             BorderRadius.circular(14),
//         borderSide: BorderSide(
//           color: Colors.grey.shade300,
//         ),
//       ),

//       enabledBorder:
//           OutlineInputBorder(
//         borderRadius:
//             BorderRadius.circular(14),
//         borderSide: BorderSide(
//           color: Colors.grey.shade300,
//         ),
//       ),

//       focusedBorder:
//           OutlineInputBorder(
//         borderRadius:
//             BorderRadius.circular(14),
//         borderSide: const BorderSide(
//           color: Color(0xFF198B35),
//           width: 1.5,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // MOBILE SECTION
//   // ============================================================

//   Widget buildMobileSection() {
//     return Column(
//       children: [
//         Row(
//           crossAxisAlignment:
//               CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: TextField(
//                 controller:
//                     mobileController,
//                 focusNode:
//                     mobileFocus,
//                 keyboardType:
//                     TextInputType.phone,
//                 maxLength: 10,

//                 decoration:
//                     _inputDecoration(
//                   label:
//                       'Mobile Number',
//                   icon:
//                       Icons.phone_android,
//                 ).copyWith(
//                   prefixText: '+91 ',
//                   counterText: '',
//                 ),
//               ),
//             ),

//             const SizedBox(
//               width: 10,
//             ),

//             SizedBox(
//               height: 54,
//               child: ElevatedButton(
//                 onPressed:
//                     sendingOtp
//                         ? null
//                         : sendOtp,

//                 style:
//                     ElevatedButton.styleFrom(
//                   backgroundColor:
//                       const Color(
//                     0xFF198B35,
//                   ),
//                   foregroundColor:
//                       Colors.white,

//                   shape:
//                       RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius
//                             .circular(
//                       12,
//                     ),
//                   ),
//                 ),

//                 child:
//                     sendingOtp
//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child:
//                                 CircularProgressIndicator(
//                               strokeWidth:
//                                   2,
//                               color:
//                                   Colors.white,
//                             ),
//                           )
//                         : const Text(
//                             'Send OTP',
//                           ),
//               ),
//             ),
//           ],
//         ),

//         buildOtpSection(),
//       ],
//     );
//   }

//   // ============================================================
//   // OTP SECTION
//   // ============================================================

//   Widget buildOtpSection() {
//     if (!otpSent) {
//       return const SizedBox.shrink();
//     }

//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         const SizedBox(
//           height: 16,
//         ),

//         const Text(
//           'Enter OTP',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight:
//                 FontWeight.w700,
//           ),
//         ),

//         const SizedBox(
//           height: 10,
//         ),

//         Row(
//           children: [
//             Expanded(
//               child: TextField(
//                 controller:
//                     otpController,
//                 focusNode:
//                     otpFocus,
//                 keyboardType:
//                     TextInputType.number,
//                 maxLength: 6,

//                 decoration:
//                     _inputDecoration(
//                   label:
//                       '6-digit OTP',
//                   icon:
//                       Icons.lock_outline,
//                 ).copyWith(
//                   counterText: '',
//                 ),
//               ),
//             ),

//             const SizedBox(
//               width: 10,
//             ),

//             SizedBox(
//               height: 54,
//               child: ElevatedButton(
//                 onPressed:
//                     otpVerified ||
//                             verifyingOtp
//                         ? null
//                         : verifyOtp,

//                 style:
//                     ElevatedButton.styleFrom(
//                   backgroundColor:
//                       const Color(
//                     0xFF198B35,
//                   ),
//                   foregroundColor:
//                       Colors.white,

//                   shape:
//                       RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius
//                             .circular(
//                       12,
//                     ),
//                   ),
//                 ),

//                 child:
//                     verifyingOtp
//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child:
//                                 CircularProgressIndicator(
//                               strokeWidth:
//                                   2,
//                               color:
//                                   Colors.white,
//                             ),
//                           )
//                         : Text(
//                             otpVerified
//                                 ? 'Verified'
//                                 : 'Verify',
//                           ),
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(
//           height: 8,
//         ),

//         if (!otpVerified)
//           Row(
//             children: [
//               Text(
//                 otpSeconds > 0
//                     ? 'Resend in $otpSeconds s'
//                     : 'You can resend OTP',
//                 style: TextStyle(
//                   color:
//                       Colors.grey.shade700,
//                 ),
//               ),

//               const Spacer(),

//               if (otpSeconds == 0)
//                 TextButton(
//                   onPressed:
//                       sendOtp,
//                   child:
//                       const Text(
//                     'Resend OTP',
//                   ),
//                 ),
//             ],
//           ),

//         if (otpVerified)
//           const Row(
//             children: [
//               Icon(
//                 Icons.check_circle,
//                 color:
//                     Color(0xFF198B35),
//               ),
//               SizedBox(
//                 width: 6,
//               ),
//               Text(
//                 'Mobile number verified',
//                 style: TextStyle(
//                   color:
//                       Color(0xFF198B35),
//                   fontWeight:
//                       FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//       ],
//     );
//   }

//   // ============================================================
//   // CATEGORY SECTION
//   // ============================================================

//   Widget buildCategorySection() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Spare Parts Category',
//           style: TextStyle(
//             fontSize: 17,
//             fontWeight:
//                 FontWeight.w700,
//           ),
//         ),

//         const SizedBox(
//           height: 12,
//         ),

//         TextField(
//           controller:
//               categorySearchController,

//           decoration:
//               _inputDecoration(
//             label:
//                 'Search category',
//             icon:
//                 Icons.search_rounded,
//           ),
//         ),

//         const SizedBox(
//           height: 12,
//         ),

//         Container(
//           width: double.infinity,
//           padding:
//               const EdgeInsets.all(8),

//           decoration:
//               BoxDecoration(
//             borderRadius:
//                 BorderRadius.circular(
//               16,
//             ),
//             border: Border.all(
//               color:
//                   Colors.grey.shade300,
//             ),
//           ),

//           child: Column(
//             children: [
//               if (filteredCategories
//                   .isEmpty)
//                 Padding(
//                   padding:
//                       const EdgeInsets.all(
//                     20,
//                   ),
//                   child: Text(
//                     'No category found.',
//                     style:
//                         TextStyle(
//                       color:
//                           Colors.grey.shade600,
//                     ),
//                   ),
//                 ),

//               ...filteredCategories
//                   .map(
//                 (category) {
//                   return RadioGroup<String>(
//   groupValue: selectedCategory,
//   onChanged: (String? value) {
//     setState(() {
//       selectedCategory = value;
//     });
//   },
//   child: Column(
//     children: [
//       ...filteredCategories.map(
//         (category) {
//           return RadioListTile<String>(
//             value: category,
//             title: Text(
//               category,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             activeColor: const Color(0xFF198B35),
//           );
//         },
//       ),
//     ],
//   ),
// );
//                 },
//               ),

//               const Divider(),

//               ListTile(
//                 leading:
//                     const Icon(
//                   Icons
//                       .add_circle_outline,
//                   color:
//                       Color(0xFF198B35),
//                 ),

//                 title:
//                     const Text(
//                   'Add your own category',
//                   style:
//                       TextStyle(
//                     fontWeight:
//                         FontWeight.w600,
//                   ),
//                 ),

//                 onTap:
//                     showCustomCategoryDialog,
//               ),
//             ],
//           ),
//         ),

//         if (selectedCategory != null)
//           Padding(
//             padding:
//                 const EdgeInsets.only(
//               top: 10,
//             ),
//             child: Text(
//               'Selected: $selectedCategory',
//               style:
//                   const TextStyle(
//                 color:
//                     Color(0xFF198B35),
//                 fontWeight:
//                     FontWeight.w600,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   // ============================================================
//   // CUSTOM CATEGORY
//   // ============================================================

//   void showCustomCategoryDialog() {
//     customCategoryController.clear();

//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           title:
//               const Text(
//             'Add Your Own Category',
//           ),

//           content:
//               TextField(
//             controller:
//                 customCategoryController,
//             textCapitalization:
//                 TextCapitalization.words,

//             decoration:
//                 const InputDecoration(
//               hintText:
//                   'Enter category name',
//               border:
//                   OutlineInputBorder(),
//             ),
//           ),

//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(
//                   dialogContext,
//                 );
//               },
//               child:
//                   const Text(
//                 'Cancel',
//               ),
//             ),

//             ElevatedButton(
//               onPressed: () {
//                 final String category =
//                     customCategoryController
//                         .text
//                         .trim();

//                 if (category.isEmpty) {
//                   return;
//                 }

//                 setState(() {
//                   selectedCategory =
//                       category;
//                 });

//                 Navigator.pop(
//                   dialogContext,
//                 );
//               },
//               child:
//                   const Text(
//                 'Add',
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // ============================================================
//   // EXPERIENCE DROPDOWN
//   // ============================================================

//   Widget buildExperienceDropdown() {
//     return DropdownButtonFormField<
//         String>(
//       initialValue: selectedExperience,

//       decoration:
//           _inputDecoration(
//         label:
//             'Shop Experience',
//         icon:
//             Icons.history_rounded,
//       ),

//       items:
//           experienceOptions.map(
//         (experience) {
//           return DropdownMenuItem<
//               String>(
//             value: experience,
//             child:
//                 Text(experience),
//           );
//         },
//       ).toList(),

//       onChanged: (value) {
//         setState(() {
//           selectedExperience =
//               value;
//         });
//       },
//     );
//   }

//   // ============================================================
//   // LOCATION PERMISSION
//   // ============================================================

//   Future<bool>
//       _requestLocationPermission() async {
//     final bool serviceEnabled =
//         await Geolocator
//             .isLocationServiceEnabled();

//     if (!serviceEnabled) {
//       _showMessage(
//         'Please turn on location services.',
//       );
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
//       _showMessage(
//         'Location permission is required.',
//       );
//       return false;
//     }

//     return true;
//   }

//   // ============================================================
//   // ATTACH CURRENT LOCATION
//   // ============================================================

//   Future<void>
//       attachCurrentLocation() async {
//     if (loadingLocation) return;

//     setState(() {
//       loadingLocation = true;
//     });

//     try {
//       final bool permission =
//           await _requestLocationPermission();

//       if (!permission) {
//         if (mounted) {
//           setState(() {
//             loadingLocation =
//                 false;
//           });
//         }
//         return;
//       }

//       final Position position =
//           await Geolocator
//               .getCurrentPosition(
//         locationSettings:
//             const LocationSettings(
//           accuracy:
//               LocationAccuracy.high,
//         ),
//       );

//       if (!mounted) return;

//       setState(() {
//         currentPosition =
//             position;
//         loadingLocation = false;
//       });

//       _showMessage(
//         'Current location attached.',
//       );
//     } catch (_) {
//       if (!mounted) return;

//       setState(() {
//         loadingLocation = false;
//       });

//       _showMessage(
//         'Unable to get current location.',
//       );
//     }
//   }

//   // ============================================================
//   // LOCATION UI
//   // ============================================================

//   Widget buildLocationSection() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Shop Location',
//           style: TextStyle(
//             fontSize: 17,
//             fontWeight:
//                 FontWeight.w700,
//           ),
//         ),

//         const SizedBox(
//           height: 12,
//         ),

//         Container(
//           width: double.infinity,
//           padding:
//               const EdgeInsets.all(16),

//           decoration:
//               BoxDecoration(
//             color:
//                 Colors.grey.shade50,
//             borderRadius:
//                 BorderRadius.circular(
//               16,
//             ),
//             border: Border.all(
//               color:
//                   Colors.grey.shade300,
//             ),
//           ),

//           child: Row(
//             children: [
//               Container(
//                 padding:
//                     const EdgeInsets.all(
//                   12,
//                 ),

//                 decoration:
//                     BoxDecoration(
//                   color:
//                       const Color(
//                     0xFF198B35,
//                   ).withValues(alpha: 
//                     0.10,
//                   ),
//                   shape:
//                       BoxShape.circle,
//                 ),

//                 child:
//                     const Icon(
//                   Icons
//                       .my_location_rounded,
//                   color:
//                       Color(0xFF198B35),
//                 ),
//               ),

//               const SizedBox(
//                 width: 12,
//               ),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment
//                           .start,
//                   children: [
//                     const Text(
//                       'Current Location',
//                       style:
//                           TextStyle(
//                         fontWeight:
//                             FontWeight.w700,
//                       ),
//                     ),

//                     const SizedBox(
//                       height: 4,
//                     ),

//                     Text(
//                       currentPosition ==
//                               null
//                           ? 'Location not attached'
//                           : 'Current location attached',
//                       style:
//                           TextStyle(
//                         color:
//                             Colors.grey
//                                 .shade700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               ElevatedButton(
//                 onPressed:
//                     loadingLocation
//                         ? null
//                         : attachCurrentLocation,

//                 style:
//                     ElevatedButton.styleFrom(
//                   backgroundColor:
//                       const Color(
//                     0xFF198B35,
//                   ),
//                   foregroundColor:
//                       Colors.white,

//                   shape:
//                       RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius
//                             .circular(
//                       12,
//                     ),
//                   ),
//                 ),

//                 child:
//                     loadingLocation
//                         ? const SizedBox(
//                             width: 18,
//                             height: 18,
//                             child:
//                                 CircularProgressIndicator(
//                               strokeWidth:
//                                   2,
//                               color:
//                                   Colors.white,
//                             ),
//                           )
//                         : const Text(
//                             'Attach',
//                           ),
//               ),
//             ],
//           ),
//         ),

//         if (currentPosition != null)
//           Padding(
//             padding:
//                 const EdgeInsets.only(
//               top: 8,
//             ),
//             child: Text(
//               'Location attached successfully.',
//               style:
//                   const TextStyle(
//                 color:
//                     Color(0xFF198B35),
//                 fontWeight:
//                     FontWeight.w600,
//               ),
//             ),
//           ),
//       ],
//     );
//   }
//   // ============================================================
//   // VALIDATE FORM
//   // ============================================================

//   bool validateForm() {
//     if (usernameController.text
//         .trim()
//         .isEmpty) {
//       _showMessage(
//         'Please enter username.',
//       );
//       return false;
//     }

//     final String mobile =
//         mobileController.text.trim();

//     if (mobile.length != 10) {
//       _showMessage(
//         'Please enter a valid 10-digit mobile number.',
//       );
//       return false;
//     }

//     if (!otpVerified) {
//       _showMessage(
//         'Please verify your mobile number.',
//       );
//       return false;
//     }

//     if (shopNameController.text
//         .trim()
//         .isEmpty) {
//       _showMessage(
//         'Please enter shop name.',
//       );
//       return false;
//     }

//     if (selectedCategory == null ||
//         selectedCategory!
//             .trim()
//             .isEmpty) {
//       _showMessage(
//         'Please select a spare parts category.',
//       );
//       return false;
//     }

//     if (selectedExperience == null) {
//       _showMessage(
//         'Please select shop experience.',
//       );
//       return false;
//     }

//     if (currentPosition == null) {
//       _showMessage(
//         'Please attach current location.',
//       );
//       return false;
//     }

//     return true;
//   }

//   // ============================================================
//   // SAVE LOCALLY WITH HIVE
//   // ============================================================

//   Future<void> saveLocally() async {
//     final Box box =
//         await Hive.openBox(
//       'auto_spare_parts_shop',
//     );

//     await box.put(
//       'username',
//       usernameController.text.trim(),
//     );

//     await box.put(
//       'mobile',
//       mobileController.text.trim(),
//     );

//     await box.put(
//       'shopName',
//       shopNameController.text.trim(),
//     );

//     await box.put(
//       'category',
//       selectedCategory,
//     );

//     await box.put(
//       'experience',
//       selectedExperience,
//     );

//     if (currentPosition != null) {
//       await box.put(
//         'latitude',
//         currentPosition!.latitude,
//       );

//       await box.put(
//         'longitude',
//         currentPosition!.longitude,
//       );
//     }

//     await box.put(
//       'profileSaved',
//       true,
//     );
//   }

//   // ============================================================
//   // SAVE TO FIRESTORE
//   // ============================================================

//   Future<void> saveToFirestore() async {
//     final User? user =
//         _auth.currentUser;

//     if (user == null) {
//       throw Exception(
//         'User is not authenticated.',
//       );
//     }

//     final DocumentReference
//         shopReference =
//         _firestore
//             .collection(
//               'auto_spare_parts_shops',
//             )
//             .doc(user.uid);

//     final DocumentSnapshot
//         existingDocument =
//         await shopReference.get();

//     final Map<String, dynamic>
//         shopData = {
//       'uid': user.uid,

//       'username':
//           usernameController.text.trim(),

//       'mobile':
//           mobileController.text.trim(),

//       'shopName':
//           shopNameController.text.trim(),

//       'category':
//           selectedCategory,

//       'experience':
//           selectedExperience,

//       'currentLocation': {
//         'latitude':
//             currentPosition!.latitude,
//         'longitude':
//             currentPosition!.longitude,
//       },

//       'updatedAt':
//           FieldValue.serverTimestamp(),
//     };

//     // Only create createdAt during
//     // the first registration.
//     if (!existingDocument.exists) {
//       shopData['createdAt'] =
//           FieldValue.serverTimestamp();
//     }

//     await shopReference.set(
//       shopData,
//       SetOptions(
//         merge: true,
//       ),
//     );
//   }

//   // ============================================================
//   // SUBMIT PROFILE
//   // ============================================================

//   Future<void> submitProfile() async {
//     if (submitting) return;

//     if (!validateForm()) {
//       return;
//     }

//     FocusScope.of(context).unfocus();

//     setState(() {
//       submitting = true;
//     });

//     try {
//       // Local save.
//       await saveLocally();

//       // Cloud save.
//       await saveToFirestore();

//       if (!mounted) return;

//       _showMessage(
//         'Shop profile submitted successfully.',
//       );

//       await Future.delayed(
//         const Duration(
//           milliseconds: 700,
//         ),
//       );

//       if (!mounted) return;

//       Navigator.pop(
//         context,
//         true,
//       );
//     } catch (_) {
//       if (!mounted) return;

//       _showMessage(
//         'Unable to submit profile. Please try again.',
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           submitting = false;
//         });
//       }
//     }
//   }

//   // ============================================================
//   // MESSAGE
//   // ============================================================

//   void _showMessage(
//     String message,
//   ) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context)
//         .hideCurrentSnackBar();

//     ScaffoldMessenger.of(context)
//         .showSnackBar(
//       SnackBar(
//         content:
//             Text(message),
//         behavior:
//             SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(
//     BuildContext context,
//   ) {
//     return Scaffold(
//       backgroundColor:
//           Colors.white,

//       appBar: AppBar(
//         title: const Text(
//           'Auto Spare Parts',
//           style: TextStyle(
//             fontWeight:
//                 FontWeight.w700,
//           ),
//         ),

//         centerTitle: true,

//         backgroundColor:
//             Colors.white,

//         foregroundColor:
//             Colors.black,

//         elevation: 0,
//       ),

//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding:
//               const EdgeInsets.fromLTRB(
//             18,
//             10,
//             18,
//             30,
//           ),

//           child: Column(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,

//             children: [
//               // ==================================================
//               // HEADER
//               // ==================================================

//               Container(
//                 width: double.infinity,

//                 padding:
//                     const EdgeInsets.all(
//                   20,
//                 ),

//                 decoration:
//                     BoxDecoration(
//                   gradient:
//                       const LinearGradient(
//                     begin:
//                         Alignment.topLeft,
//                     end:
//                         Alignment.bottomRight,
//                     colors: [
//                       Color(
//                         0xFF198B35,
//                       ),
//                       Color(
//                         0xFF0E6B27,
//                       ),
//                     ],
//                   ),

//                   borderRadius:
//                       BorderRadius.circular(
//                     20,
//                   ),
//                 ),

//                 child: const Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 28,

//                       backgroundColor:
//                           Colors.white,

//                       child:
//                           Icon(
//                         Icons
//                             .build_circle_outlined,
//                         size: 32,
//                         color:
//                             Color(
//                           0xFF198B35,
//                         ),
//                       ),
//                     ),

//                     SizedBox(
//                       width: 14,
//                     ),

//                     Expanded(
//                       child:
//                           Column(
//                         crossAxisAlignment:
//                             CrossAxisAlignment
//                                 .start,

//                         children: [
//                           Text(
//                             'Auto Spare Parts Shop',
//                             style:
//                                 TextStyle(
//                               color:
//                                   Colors.white,
//                               fontSize:
//                                   19,
//                               fontWeight:
//                                   FontWeight
//                                       .w800,
//                             ),
//                           ),

//                           SizedBox(
//                             height: 4,
//                           ),

//                           Text(
//                             'Register your shop',
//                             style:
//                                 TextStyle(
//                               color:
//                                   Colors.white70,
//                               fontSize:
//                                   13,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(
//                 height: 24,
//               ),

//               // ==================================================
//               // OWNER DETAILS
//               // ==================================================

//               const Text(
//                 'Shop Owner Details',
//                 style: TextStyle(
//                   fontSize: 17,
//                   fontWeight:
//                       FontWeight.w700,
//                 ),
//               ),

//               const SizedBox(
//                 height: 12,
//               ),

//               // USERNAME

//               TextField(
//                 controller:
//                     usernameController,

//                 focusNode:
//                     usernameFocus,

//                 textCapitalization:
//                     TextCapitalization.words,

//                 decoration:
//                     _inputDecoration(
//                   label:
//                       'Username',
//                   icon:
//                       Icons.person_outline,
//                 ),
//               ),

//               const SizedBox(
//                 height: 14,
//               ),

//               // MOBILE + OTP

//               buildMobileSection(),

//               const SizedBox(
//                 height: 20,
//               ),

//               // ==================================================
//               // SHOP NAME
//               // ==================================================

//               TextField(
//                 controller:
//                     shopNameController,

//                 focusNode:
//                     shopNameFocus,

//                 textCapitalization:
//                     TextCapitalization.words,

//                 decoration:
//                     _inputDecoration(
//                   label:
//                       'Shop Name',
//                   icon:
//                       Icons.storefront_outlined,
//                 ),
//               ),

//               const SizedBox(
//                 height: 24,
//               ),

//               // ==================================================
//               // CATEGORY
//               // ==================================================

//               buildCategorySection(),

//               const SizedBox(
//                 height: 24,
//               ),

//               // ==================================================
//               // EXPERIENCE
//               // ==================================================

//               buildExperienceDropdown(),

//               const SizedBox(
//                 height: 24,
//               ),

//               // ==================================================
//               // CURRENT LOCATION
//               // ==================================================

//               buildLocationSection(),

//               const SizedBox(
//                 height: 30,
//               ),

//               // ==================================================
//               // SUBMIT
//               // ==================================================

//               SizedBox(
//                 width:
//                     double.infinity,

//                 height: 56,

//                 child:
//                     ElevatedButton(
//                   onPressed:
//                       submitting
//                           ? null
//                           : submitProfile,

//                   style:
//                       ElevatedButton.styleFrom(
//                     backgroundColor:
//                         const Color(
//                       0xFF198B35,
//                     ),

//                     foregroundColor:
//                         Colors.white,

//                     disabledBackgroundColor:
//                         Colors.grey.shade400,

//                     shape:
//                         RoundedRectangleBorder(
//                       borderRadius:
//                           BorderRadius
//                               .circular(
//                         16,
//                       ),
//                     ),

//                     elevation: 0,
//                   ),

//                   child:
//                       submitting
//                           ? const Row(
//                               mainAxisAlignment:
//                                   MainAxisAlignment
//                                       .center,

//                               children: [
//                                 SizedBox(
//                                   width: 22,
//                                   height: 22,

//                                   child:
//                                       CircularProgressIndicator(
//                                     strokeWidth:
//                                         2.5,
//                                     color:
//                                         Colors.white,
//                                   ),
//                                 ),

//                                 SizedBox(
//                                   width: 12,
//                                 ),

//                                 Text(
//                                   'Submitting...',
//                                   style:
//                                       TextStyle(
//                                     fontSize:
//                                         16,
//                                     fontWeight:
//                                         FontWeight
//                                             .w700,
//                                   ),
//                                 ),
//                               ],
//                             )
//                           : const Text(
//                               'Submit Profile',
//                               style:
//                                   TextStyle(
//                                 fontSize:
//                                     16,
//                                 fontWeight:
//                                     FontWeight
//                                         .w700,
//                               ),
//                             ),
//                 ),
//               ),

//               const SizedBox(
//                 height: 10,
//               ),

//               Center(
//                 child: Text(
//                   'Your shop information will be securely saved.',
//                   style: TextStyle(
//                     color:
//                         Colors.grey.shade600,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // DISPOSE
//   // ============================================================

//   @override
//   void dispose() {
//     otpTimer?.cancel();

//     usernameController.dispose();
//     mobileController.dispose();
//     shopNameController.dispose();
//     otpController.dispose();
//     categorySearchController.dispose();
//     customCategoryController.dispose();

//     usernameFocus.dispose();
//     mobileFocus.dispose();
//     shopNameFocus.dispose();
//     otpFocus.dispose();

//     super.dispose();
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
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
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

// class SparePartsLocation {
//   final String placeName;
//   final double latitude;
//   final double longitude;

//   SparePartsLocation({
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

//   factory SparePartsLocation.fromMap(Map<String, dynamic> map) {
//     return SparePartsLocation(
//       placeName: map['placeName'] ?? '',
//       latitude: (map['latitude'] ?? 0).toDouble(),
//       longitude: (map['longitude'] ?? 0).toDouble(),
//     );
//   }
// }
class SparePartsLocation {
  final String placeName;
  final double? latitude;
  final double? longitude;

  SparePartsLocation({
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

  factory SparePartsLocation.fromMap(
    Map<String, dynamic> map,
  ) {
    return SparePartsLocation(
      placeName: map['placeName']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}


class AutoSparePartsLoginPage extends StatefulWidget {
  const AutoSparePartsLoginPage({super.key});

  @override
  State<AutoSparePartsLoginPage> createState() =>
      _AutoSparePartsLoginPageState();
}

class _AutoSparePartsLoginPageState
    extends State<AutoSparePartsLoginPage> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController mobileController =
      TextEditingController();

  final TextEditingController shopNameController =
      TextEditingController();

  final TextEditingController otpController =
      TextEditingController();

   final TextEditingController secondaryPhoneController =
    TextEditingController();

  final TextEditingController _shopLocationController =
    TextEditingController();

  final TextEditingController categorySearchController =
      TextEditingController();

  final TextEditingController customCategoryController =
      TextEditingController();

  // ==========================================================
  // FOCUS NODES
  // ==========================================================

  final FocusNode nameFocus = FocusNode();
  final FocusNode mobileFocus = FocusNode();
  final FocusNode shopNameFocus = FocusNode();
  final FocusNode otpFocus = FocusNode();

  // ==========================================================
  // FIREBASE
  // ==========================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const Color green =
      Color(0xFF138808);

  // static const Color submitGreen =
  //     Color(0xFF159B16);

  static const Color darkText =
      Color(0xFF202124);

  static const Color lightFill =
      Color(0xFFF9F9F9);

   File? profilePhoto;
  String? profilePhotoUrl;
bool isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();
  // ==========================================================
  // OTP STATE
  // ==========================================================

  //  String? verificationId;

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


  bool privacyPolicyAccepted = false;
  String? privacyPolicyError;

    String? nameError;
    bool mobileError = false;
bool locationError = false;

//String? mobileError;
String? shopNameError;
String? secondaryMobileError;
  // ============================================================
  // SHOP TIMINGS
  // ============================================================

  TimeOfDay? openingTime;
  TimeOfDay? closingTime;
  bool isOpen24Hours = false;

  // ==========================================================
  // LOCATION
  // ==========================================================
SparePartsLocation? currentLocation;

bool isGettingLocation = false;
bool isSearchingLocation = false;

// Used to invalidate an older location request
int _locationRequestId = 0;

  // ==========================================================
  // INIT STATE
  // ==========================================================

  @override
  void initState() {
    super.initState();

    filteredCategories =
        List<String>.from(allCategories);

 filteredStates = List<String>.from(indiaStates);

  loadDistricts();
    // categorySearchController.addListener(
    //   _filterCategories,
    // );
  }

   void showMessage(String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
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
  
  // ==============================================================
  // SEND OTP
  // ===============================================================

Future<void> sendOTP({bool isResend = false}) async {
  if (isSendingOtp || isVerifying) return;

  final phone = mobileController.text.trim();

  if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
    showMessage(AppLocalizations.of(context)!.enteradigitmobilenumber
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
  
  // ==========================================================
  // FIELD DECORATION
  // ==========================================================

    InputDecoration fieldDecoration({
  required String hintText,
   bool hasError = false,
  IconData? icon,
   String? errorText,

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
  // SECTION TITLE
  // ==========================================================

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  // ==========================================================
  // CATEGORY
  // ==========================================================

  final List<String> defaultCategories = [
    'All Auto Spare Parts',
    '4 Wheeler Spare Parts',
    '3 Wheeler Spare Parts',
    '2 Wheeler Spare Parts',
    '6 Wheeler Spare Parts',
    'JCB Spare Parts',
  ];

  final List<String> customCategories = [];

  final List<String> selectedCategories = [];

  List<String> filteredCategories = [];

  bool isCategoryDropdownOpen = false;

  String categorySearchText = '';

  bool categoryError = false;

   List<String> get allCategories {

    final List<String> result = [];

    for (final category in defaultCategories) {

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

  // ==========================================================
  // FILTER CATEGORY
  // ==========================================================

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

  // ==========================================================
  // ADD CUSTOM CATEGORY
  // ==========================================================

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

              hintText:'Enter Spare Parts category',

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

  // ==========================================================
  // CATEGORY SECTION
  // ==========================================================

  Widget categorySection() {
    final categories =
        filteredCategories;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        sectionTitle(
          'Spare Parts Categories',
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
                                    'Select Spare Parts categories',
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

  // ==========================================================
  // MOBILE
  // ==========================================================

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

      // TextFormField(
      //   controller: secondaryPhoneController,
      //   keyboardType: TextInputType.phone,
      //   maxLength: 10,

      //   inputFormatters: [
      //     FilteringTextInputFormatter.digitsOnly,
      //   ],

      //   decoration: fieldDecoration(
      //     hintText: 'Enter secondary mobile number (optional)',
      //     icon: Icons.phone_android_outlined,
      //   ).copyWith(
      //     counterText: '',
      //   ),

      //   validator: (value) {
      //     final number = value?.trim() ?? '';

      //     // Optional field.
      //     if (number.isEmpty) {
      //       return null;
      //     }

      //     if (number.length != 10) {
      //       return 'Enter a valid 10-digit mobile number';
      //     }

      //     return null;
      //   },
      // ),
      TextField(
  controller: secondaryPhoneController,
  keyboardType: TextInputType.phone,
  maxLength: 10,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
  ],
  decoration: fieldDecoration(
    hintText:
        'Enter secondary mobile number',
    icon: Icons.phone_android_outlined,
    errorText: secondaryMobileError,
  ).copyWith(
    counterText: '',
  ),
  onChanged: (value) {
    if (secondaryMobileError != null) {
      setState(() {
        secondaryMobileError = null;
      });
    }
  },
),

      const SizedBox(height: 5),

      const Text(
        'You can add same number,if another number is not available.',
        style: TextStyle(
          color: Color(0xFF777777),
          fontSize: 12,
        ),
      ),
      const Text(
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
  // LOCATION SECTION
  // ============================================================
 Widget locationSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Shop Location',
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
                      'Add Shop location',
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
                              : 'Use Shop Location',
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
            labelText: 'Shop Location',
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
  currentLocation = SparePartsLocation(
    placeName: placeName.trim(),
    latitude: null,
    longitude: null,
  );
  locationError = false;
  isGettingLocation = false;
  isSearchingLocation = false;
});

showMessage(
  'Shop location added.',
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
  currentLocation = SparePartsLocation(
    placeName: placeName,
    latitude: position.latitude,
    longitude: position.longitude,
  );

  locationError = false;
});

    showMessage(
      'Shop location added.',
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

// bool validateForm() {
//   bool valid = true;

//   final name =
//       nameController.text.trim();

//   // final mobile =
//   //     mobileController.text.trim();

//   final secondaryMobile =
//       secondaryPhoneController.text.trim();

//   final shopName =
//       shopNameController.text.trim();

//   setState(() {
//     nameError = null;
//     mobileError = false;
//     shopNameError = null;
//     secondaryMobileError = null;
//     categoryError = false;
//     otpError = false;
//     otpErrorMessage = '';
//     privacyPolicyError = null;
//   });

//   // ==========================================================
//   // NAME / USERNAME - REQUIRED
//   // ==========================================================

//   if (name.isEmpty) {
//     nameError =
//         'Please enter your name.';
//     valid = false;
//   }

//   // ==========================================================
//   // SHOP NAME - REQUIRED
//   // ==========================================================

//   if (shopName.isEmpty) {
//     shopNameError =
//         'Please enter your shop name.';
//     valid = false;
//   }
//  // ==========================================================
//   // MOBILE NUMBER REQUIRED
//   // ==========================================================

  
//    final String phone =
//       mobileController.text.trim();

//   // if (phone.length != 10) {
//   //   mobileError = true;
//   //   valid = true;
//   // }
//   if (phone.length != 10 ||
//     !RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
//   mobileError = true;
//   valid = false;
// }

//   // ==========================================================
//   // OTP - REQUIRED
//   // ==========================================================

//   if (!otpVerified) {
//     otpError = true;
//     otpErrorMessage =
//         'Please verify the OTP before submitting.';
//     valid = false;
//   }

//   // ==========================================================
//   // SECONDARY MOBILE - REQUIRED
//   // ==========================================================

//   if (secondaryMobile.isEmpty) {
//     secondaryMobileError =
//         'Please enter your secondary mobile number.';
//     valid = false;
//   } else if (secondaryMobile.length != 10 ||
//       !RegExp(r'^[0-9]{10}$')
//           .hasMatch(secondaryMobile)) {
//     secondaryMobileError = AppLocalizations.of(context)!.enteradigitmobilenumber;
//        // 'Enter a valid 10-digit mobile number.';
//     valid = false;
//   }

//   final stateValue = selectedState?.trim() ?? '';
// final districtValue = selectedDistrict?.trim() ?? '';
// final nearestCityValue =
//     nearestCityController.text.trim();

// setState(() {
//   stateError = stateValue.isEmpty
//       ? 'Please select a state.'
//       : '';

//   districtError = districtValue.isEmpty
//       ? 'Please select a district.'
//       : '';

//   nearestCityError = nearestCityValue.isEmpty
//       ? 'Please enter the nearest town or city.'
//       : '';
// });

// if (stateError.isNotEmpty ||
//     districtError.isNotEmpty ||
//     nearestCityError.isNotEmpty) {
//   valid = false;
// }

//   // ==========================================================
//   // SPARE PARTS CATEGORY - REQUIRED
//   // ==========================================================

//   if (selectedCategories.isEmpty) {
//     categoryError = true;
//     valid = false;
//   }

// // ==========================================================
// // GARAGE LOCATION
// // ==========================================================

// if (currentLocation == null) {
//   locationError = true;
//   valid = false;
// } else {
//   locationError = false;
// }

//   // ==========================================================
//   // SHOP TIMING
//   // OPTIONAL
//   // ==========================================================

//   // ==========================================================
//   // PRIVACY POLICY / TERMS - REQUIRED
//   // ==========================================================

//   if (!privacyPolicyAccepted) {
//     privacyPolicyError =
//         'Please accept the Privacy Policy and Terms & Conditions.';
//     valid = false;
//   }

//   if (!valid) {
//     setState(() {});
//   }

//   return valid;
// }

bool validateForm() {
  bool valid = true;

  final name = nameController.text.trim();
  final phone = mobileController.text.trim();
  final secondaryMobile =
      secondaryPhoneController.text.trim();
  final shopName = shopNameController.text.trim();

  final stateValue = selectedState?.trim() ?? '';
  final districtValue = selectedDistrict?.trim() ?? '';
  final nearestCityValue =
      nearestCityController.text.trim();

  setState(() {
    nameError = null;
    mobileError = false;
    shopNameError = null;
    secondaryMobileError = null;
    categoryError = false;
    otpError = false;
    otpErrorMessage = '';
    privacyPolicyError = null;

    stateError = '';
    districtError = '';
    nearestCityError = '';
    locationError = false;
  });

  // NAME
  if (name.isEmpty) {
    nameError = 'Please enter your name.';
    valid = false;
  }

  // SHOP NAME
  if (shopName.isEmpty) {
    shopNameError = 'Please enter your shop name.';
    valid = false;
  }

  // MOBILE
  if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
    mobileError = true;
    valid = false;
  }

  // OTP
  if (!otpVerified) {
    otpError = true;
    otpErrorMessage =
        'Please verify the OTP before submitting.';
    valid = false;
  }

  // SECONDARY MOBILE
  if (secondaryMobile.isEmpty) {
    secondaryMobileError =
        'Please enter your secondary mobile number.';
    valid = false;
  } else if (!RegExp(r'^[0-9]{10}$')
      .hasMatch(secondaryMobile)) {
    secondaryMobileError =
        AppLocalizations.of(context)!
            .enteradigitmobilenumber;
    valid = false;
  }

  // STATE
  if (stateValue.isEmpty) {
    stateError = 'Please select a state.';
    valid = false;
  }

  // DISTRICT
  if (districtValue.isEmpty) {
    districtError = 'Please select a district.';
    valid = false;
  }

  // NEAREST TOWN
  if (nearestCityValue.isEmpty) {
    nearestCityError =
        'Please enter the nearest town or city.';
    valid = false;
  }

  // CATEGORIES
  if (selectedCategories.isEmpty) {
    categoryError = true;
    valid = false;
  }

  // LOCATION
  if (currentLocation == null) {
    locationError = true;
    valid = false;
  }

  // PRIVACY POLICY
  if (!privacyPolicyAccepted) {
    privacyPolicyError =
        'Please accept the Privacy Policy and Terms & Conditions.';
    valid = false;
  }

  if (mounted) {
    setState(() {});
  }

  return valid;
}


Future<void> saveLocally({
required String uid,
required String name,
required String mobile,
required String secondaryMobile,
required String shopName,
required List<String> categories,
// required String experience,
double? latitude,
double? longitude,
String? openingTime,
String? closingTime,
required bool isOpen24Hours
}) async {
final settings =
Hive.box('settings');

await settings.put(  
  'autoSparePartsRegistered',  
  true,  
);  

await settings.put(  
  'autoSparePartsSyncPending',  
  true,  
);  

await settings.put(  
  'autoSparePartsUid',  
  uid,  
);  

await settings.put(  
  'autoSparePartsName',  
  name,  
);  

await settings.put(  
  'autoSparePartsMobile',  
  mobile,  
);  
await settings.put(

'autoSparePartsSecondaryMobile',
secondaryMobile,
);

await settings.put(
  'autoSparePartsState',
  selectedState!.trim(),
);

await settings.put(
  'autoSparePartsDistrict',
  selectedDistrict!.trim(),
);

await settings.put(
  'autoSparePartsNearestTown',
  nearestCityController.text.trim(),
);

await settings.put(  
  'autoSparePartsShopName',  
  shopName,  
);  

await settings.put(  
  'autoSparePartsCategories',  
  List<String>.from(categories),  
);  

 await settings.put(

'autoSparePartsOpeningTime',
openingTime,
);

await settings.put(
'autoSparePartsClosingTime',
closingTime,
);

await settings.put(
'autoSparePartsIsOpen24Hours',
isOpen24Hours,
);

await settings.put(  
  'autoSparePartsCategory',  
  categories.join(', '),  
);  

// await settings.put(  
//   'autoSparePartsExperience',  
//   experience,  
// );  

await settings.put(  
  'autoSparePartsLatitude',  
  latitude,  
);  

await settings.put(  
  'autoSparePartsLongitude',  
  longitude,  
);  

await settings.put(  
  'autoSparePartsRole',  
  'auto_spare_parts',  
);
// SAVE CUSTOM CATEGORIES LOCALLY
final List<String> savedCustomCategories =
    List<String>.from(
  settings.get(
    'autoSparePartsCustomCategories',
    defaultValue: <String>[],
  ),
);

final builtInNames = defaultCategories
    .map((e) => e.trim().toLowerCase())
    .toSet();

for (final category in categories) {
  final name = category.trim();

  if (name.isEmpty) continue;

  if (!builtInNames.contains(name.toLowerCase()) &&
      !savedCustomCategories.any(
        (e) => e.toLowerCase() == name.toLowerCase(),
      )) {
    savedCustomCategories.add(name);
  }
}

await settings.put(
  'autoSparePartsCustomCategories',
  savedCustomCategories,
);
}

Future<void> saveAutoSparePartsToFirestore({
  required String uid,
  required String name,
  required String mobile,
  required String secondaryMobile,
  required String shopName,
  required List<String> categories,
  double? latitude,
  double? longitude,
  String? openingTime,
  String? closingTime,
  required bool isOpen24Hours,
}) async {
  try {
    final docRef = _firestore
        .collection('auto_spare_parts_shops')
        .doc(uid);

    final snapshot = await docRef.get();

    final searchKeywords = <String>{
      name.toLowerCase(),
      shopName.toLowerCase(),
      'auto spare parts',
      ...categories.map(
        (category) => category.toLowerCase(),
      ),
    }.toList();
    // Built-in categories are already defined in defaultCategories.
final Set<String> builtInCategoryNames = defaultCategories
    .map((category) => category.trim().toLowerCase())
    .toSet();

// Save only user-added categories in this separate field.
final List<String> customCategoriesToSave = categories
    .map((category) => category.trim())
    .where((category) =>
        category.isNotEmpty &&
        !builtInCategoryNames.contains(category.toLowerCase()))
    .toSet()
    .toList();

    final data = <String, dynamic>{
      'uid': uid,
      'name': name,
      'ownerName': name,
      'mobile': mobile,
      'secondaryMobile': secondaryMobile,
      'state': selectedState!.trim(),
      'district': selectedDistrict!.trim(),
      'nearestTown': nearestCityController.text.trim(),
      'shopName': shopName,
      // 'categories': categories,
      // 'category': categories.join(', '),
      'categories': categories
    .map((category) => category.trim())
    .where((category) => category.isNotEmpty)
    .toSet()
    .toList(),

'customCategories': customCategoriesToSave,

'category': categories.join(', '),
      'openingTime': openingTime,
      'closingTime': closingTime,
      'isOpen24Hours': isOpen24Hours,
      'latitude': latitude,
      'longitude': longitude,
      'profilePhotoUrl': profilePhotoUrl,
      'role': 'auto_spare_parts',
      'active': true,
      'searchKeywords': searchKeywords,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // ========================================================
    // SAVE GEOHASH AND GEOPOINT
    // ========================================================

    if (latitude != null && longitude != null) {
      // Validate coordinates before saving.
      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        throw Exception('Invalid shop location coordinates.');
      }

      final geoPoint = GeoPoint(
        latitude,
        longitude,
      );

      final geoFirePoint = GeoFirePoint(geoPoint);

      // Keep your old location field for compatibility.
      data['location'] = geoPoint;

      // New field used by the nearby geographic search.
      data['geo'] = geoFirePoint.data;
    } else {
      data['location'] = FieldValue.delete();
      data['geo'] = FieldValue.delete();
    }

    // ========================================================
    // CREATED AT
    // ========================================================

    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    // ========================================================
    // SAVE TO FIRESTORE
    // ========================================================

    await docRef.set(
      data,
      SetOptions(merge: true),
    );

    final settings = Hive.box('settings');

    await settings.put(
      'autoSparePartsSyncPending',
      false,
    );

    debugPrint('Auto spare parts profile synced successfully.');
  } catch (e) {
    debugPrint('Auto spare parts Firestore save error: $e');

    // Keep sync pending if Firestore save fails.
    try {
      final settings = Hive.box('settings');

      await settings.put(
        'autoSparePartsSyncPending',
        true,
      );
    } 
    catch (_) {}

    rethrow;
  }
 
}

// ==========================================================
// SUBMIT PROFILE
// ==========================================================

Future<void> submitProfile() async {
  if (isSubmitting) return;

  FocusScope.of(context).unfocus();

  if (!validateForm()) return;

  final user = _auth.currentUser;

  if (user == null) {
    showMessage(
      'Please verify your mobile number first.',
    );
    return;
  }

  final position = currentLocation;

  if (position == null) {
    showMessage(
      'Please attach your current location.',
    );
    return;
  }

  if (!privacyPolicyAccepted) {
    setState(() {
      privacyPolicyError =
          'Please accept the Privacy Policy and Terms & Conditions.';
    });
    return;
  }

  final name = nameController.text.trim();
  final mobile = mobileController.text.trim();
  final secondaryMobile =
      secondaryPhoneController.text.trim();
  final shopName = shopNameController.text.trim();

  final categories =
      List<String>.from(selectedCategories);

  final uid = user.uid;

  final double? latitude = position.latitude;
  final double? longitude = position.longitude;

  final String? savedOpeningTime =
      isOpen24Hours || openingTime == null
          ? null
          : timeToString(openingTime!);

  final String? savedClosingTime =
      isOpen24Hours || closingTime == null
          ? null
          : timeToString(closingTime!);

  setState(() {
    isSubmitting = true;
  });

  try {
    // 1. SAVE LOCALLY
    await saveLocally(
      uid: uid,
      name: name,
      mobile: mobile,
      secondaryMobile: secondaryMobile,
      shopName: shopName,
      categories: categories,
      latitude: latitude,
      longitude: longitude,
      openingTime: savedOpeningTime,
      closingTime: savedClosingTime,
      isOpen24Hours: isOpen24Hours,
    );

    // 2. SAVE LOGIN
    await CommonProfileService.saveLogin(
      uid: uid,
      name: name,
      mobile: mobile,
      role: 'autoSpareParts',
    );

    // 3. TRY FIRESTORE SYNC
    try {
      await saveAutoSparePartsToFirestore(
        uid: uid,
        name: name,
        mobile: mobile,
        secondaryMobile: secondaryMobile,
        shopName: shopName,
        categories: categories,
        latitude: latitude,
        longitude: longitude,
        openingTime: savedOpeningTime,
        closingTime: savedClosingTime,
        isOpen24Hours: isOpen24Hours,
      );

      debugPrint(
        'AUTO SPARE PARTS: Firestore sync successful',
      );
    } catch (e) {
      debugPrint(
        'AUTO SPARE PARTS: Firestore sync pending: $e',
      );

      final settings = Hive.box('settings');

      await settings.put(
        'autoSparePartsSyncPending',
        true,
      );
    }

    if (!mounted) return;

    // 4. GO HOME
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const ScreenHome(),
      ),
      (route) => false,
    );

  } catch (e) {
    debugPrint(
      'AUTO SPARE PARTS REGISTRATION ERROR: $e',
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    showMessage(
      'Unable to save your profile. Please try again.',
    );
  }
}

// ==========================================================
// FIRESTORE SAVE
// ==========================================================

// Future<void>
// saveAutoSparePartsToFirestore({
// required String uid,
// required String name,
// required String mobile,
// required String secondaryMobile,
// required String shopName,
// required List<String> categories,
// double? latitude,
// double? longitude,
// String? openingTime,
// String? closingTime,
// required bool isOpen24Hours
// }) async {
// try {
// final docRef = _firestore
// .collection(
// 'auto_spare_parts_shops',
// )
// .doc(uid);

// final snapshot =  
//       await docRef.get();  

//   final searchKeywords =  
//       <String>{  
//     name.toLowerCase(),  
//     shopName.toLowerCase(),  
//     'auto spare parts',  
//     ...categories.map(  
//       (category) =>  
//           category.toLowerCase(),  
//     ),  
//   }.toList();  

//   final data =  
//       <String, dynamic>{  
//     'uid': uid,  
//     'name': name,  
//     'ownerName': name,  
//     'mobile': mobile,  
//     'secondaryMobile': secondaryMobile, 
//     'state': selectedState!.trim(),
// 'district': selectedDistrict!.trim(),
// 'nearestTown': nearestCityController.text.trim(), 
//     'shopName': shopName,  
//     'categories': categories,  
//     'category':  
//         categories.join(', '),  
//     'openingTime': openingTime,  
//     'closingTime': closingTime,  
//     'isOpen24Hours': isOpen24Hours,  

//     'latitude': latitude,  
//     'longitude': longitude,  
      
//     // 'location': GeoPoint(  
//     //   latitude,  
//     //   longitude,  
//     // ),  
//     'profilePhotoUrl': profilePhotoUrl,  
//     'role': 'autoSpareParts',  
      
//     'active': true,  
//     'searchKeywords':  
//         searchKeywords,  
//     'updatedAt':  
//         FieldValue.serverTimestamp(),  
//   };

// if (latitude != null && longitude != null) {
// data['location'] = GeoPoint(
// latitude,
// longitude,
// );
// } else {
// data['location'] = FieldValue.delete();
// }

// if (!snapshot.exists) {  
//     data['createdAt'] =  
//         FieldValue.serverTimestamp();  
//   }  

//   await docRef.set(  
//     data,  
//     SetOptions(  
//       merge: true,  
//     ),  
//   );  

//   final settings =  
//       Hive.box('settings');  

//   await settings.put(  
//     'autoSparePartsSyncPending',  
//     false,  
//   );  
// } catch (e) {  
//   // Keep pending = true so the data  
//   // can be synchronized later.  
//   try {  
//     final settings =  
//         Hive.box('settings');  

//     await settings.put(  
//       'autoSparePartsSyncPending',  
//       true,  
//     );  
//   } catch (_) {}  
// }

// }



// Future<void> submitProfile() async {
//   if (isSubmitting) return;

//   FocusScope.of(context).unfocus();

//   if (!validateForm()) return;

//   final user = _auth.currentUser;

//   if (user == null) {
//     showMessage('Please verify your mobile number first.');
//     return;
//   }

//   final position = currentLocation;

//   if (position == null ||
//       position.latitude == null ||
//       position.longitude == null) {
//     showMessage('Please attach a valid shop location.');
//     return;
//   }

//   if (!privacyPolicyAccepted) {
//     setState(() {
//       privacyPolicyError =
//           'Please accept the Privacy Policy and Terms & Conditions.';
//     });

//     showMessage(
//       'Please accept the Privacy Policy and Terms & Conditions.',
//     );
//     return;
//   }

//   final name = nameController.text.trim();
//   final mobile = mobileController.text.trim();
//   final secondaryMobile = secondaryPhoneController.text.trim();
//   final shopName = shopNameController.text.trim();

//   final categories = List<String>.from(selectedCategories);

//   final uid = user.uid;

//   final double latitude = position.latitude!;
//   final double longitude = position.longitude!;

//   final String? savedOpeningTime = isOpen24Hours
//       ? null
//       : openingTime == null
//           ? null
//           : timeToString(openingTime!);

//   final String? savedClosingTime = isOpen24Hours
//       ? null
//       : closingTime == null
//           ? null
//           : timeToString(closingTime!);

//   String currentStep = 'Starting submission';

//   setState(() {
//     isSubmitting = true;
//   });

//   try {
//     // STEP 1: SAVE LOCALLY
//     currentStep = 'Saving registration locally';

//     debugPrint('SPARE PARTS: $currentStep');

//     await saveLocally(
//       uid: uid,
//       name: name,
//       mobile: mobile,
//       secondaryMobile: secondaryMobile,
//       shopName: shopName,
//       categories: categories,
//       latitude: latitude,
//       longitude: longitude,
//       openingTime: savedOpeningTime,
//       closingTime: savedClosingTime,
//       isOpen24Hours: isOpen24Hours,
//     );

//     debugPrint('SPARE PARTS: Local save successful');

//     // STEP 2: SAVE TO FIRESTORE
//     currentStep = 'Saving shop profile to Firestore';

//     debugPrint('SPARE PARTS: $currentStep');

//     await saveAutoSparePartsToFirestore(
//       uid: uid,
//       name: name,
//       mobile: mobile,
//       secondaryMobile: secondaryMobile,
//       shopName: shopName,
//       categories: categories,
//       latitude: latitude,
//       longitude: longitude,
//       openingTime: savedOpeningTime,
//       closingTime: savedClosingTime,
//       isOpen24Hours: isOpen24Hours,
//     );

//     debugPrint('SPARE PARTS: Firestore save successful');

//     // STEP 3: SAVE LOGIN
//     currentStep = 'Saving login details';

//     debugPrint('SPARE PARTS: $currentStep');

//     await CommonProfileService.saveLogin(
//       uid: uid,
//       name: name,
//       mobile: mobile,
//       role: 'autoSpareParts',
//     );

//     debugPrint('SPARE PARTS: Login save successful');

//     if (!mounted) return;

//     // STEP 4: NAVIGATE HOME
//     currentStep = 'Opening Home screen';

//     debugPrint('SPARE PARTS: $currentStep');

//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const ScreenHome(),
//       ),
//       (route) => false,
//     );
//   } catch (e, stackTrace) {
//     debugPrint('====================================');
//     debugPrint('SPARE PARTS SUBMISSION FAILED');
//     debugPrint('FAILED STEP: $currentStep');
//     debugPrint('ERROR: $e');
//     debugPrint('STACK TRACE: $stackTrace');
//     debugPrint('====================================');

//     if (!mounted) return;

//     setState(() {
//       isSubmitting = false;
//     });

//     // Temporary diagnostic message.
//     showMessage(
//       'Failed during: $currentStep. Check Debug Console.',
//     );
//   }
// }

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
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: isSubmitting
              ? null
              : () {
                  Navigator.pop(context);
                },
        ),

        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
            children: [
              TextSpan(
                text:
                    'Auto Spare Parts ',
                style: TextStyle(
                  color:
                      Color(0xFF16803C),
                ),
              ),
              TextSpan(
                text: AppLocalizations.of(context)!.registration,
                   // 'Registration',
                style: TextStyle(
                  color:
                      Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            40,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // HEADER
              // ------------------------------------------------

              const Text(
                'Auto Spare Parts Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                'Fill in your details to create your auto spare parts profile',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Colors.grey.shade600,
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // ------------------------------------------------
              // NAME
              // ------------------------------------------------

              sectionTitle(
                'Name *',
              ),

              TextField(
                controller:
                    nameController,
                focusNode:
                    nameFocus,
                textCapitalization:
                    TextCapitalization
                        .words,
                decoration:
                    fieldDecoration(
                  hintText:
                      'Enter your name',
                  icon:
                      Icons.person_outline,
                  errorText:
                      nameError,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ------------------------------------------------
              // SHOP NAME
              // ------------------------------------------------

              sectionTitle(
                'Shop Name *',
              ),

              TextField(
                controller:
                    shopNameController,
                focusNode:
                    shopNameFocus,
                textCapitalization:
                    TextCapitalization
                        .words,
                decoration:
                    fieldDecoration(
                  hintText:
                      'Enter your shop name',
                  icon:
                      Icons.store_outlined,
                  errorText:
                      shopNameError,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ------------------------------------------------
              // MOBILE
              // ------------------------------------------------
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
                height: 18,
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
              // ------------------------------------------------
              // CATEGORY
              // ------------------------------------------------

              categorySection(),

               const SizedBox(height: 10),
                shopTimingSection(),
              const SizedBox(height: 20),
              //  descriptionSection(),
              // const SizedBox(height: 20),

              _profilePhotoSection(),
              const SizedBox(height: 20),

              // ------------------------------------------------
              // LOCATION
              // ------------------------------------------------

              locationSection(),

              // ------------------------------------------------
              // SUBMIT
              // ------------------------------------------------
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

              SizedBox(
                width:
                    double.infinity,
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
                        const Color(
                      0xFF159B16,
                    ),

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        30,
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
                          : const Text(
                              'Submit Profile',
                              style:
                                  TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    timer?.cancel();

    nameController.dispose();
    mobileController.dispose();
    shopNameController.dispose();
    otpController.dispose();
    secondaryPhoneController.dispose();
    categorySearchController.dispose();
    customCategoryController.dispose();
    stateSearchController.dispose();
    districtSearchController.dispose();


    nameFocus.dispose();
    mobileFocus.dispose();
    shopNameFocus.dispose();
    otpFocus.dispose();

    super.dispose();
  }
}

 // ==========================================================
  // MESSAGE
  // ==========================================================

  // void showMessage(String message) {
  //   if (!mounted) return;

  //   ScaffoldMessenger.of(context)
  //     ..hideCurrentSnackBar()
  //     ..showSnackBar(
  //       SnackBar(
  //         content: Text(message),
  //         behavior: SnackBarBehavior.floating,
  //       ),
  //     );
  // }

  // ==========================================================
  // EXPERIENCE
  // ==========================================================

  // final List<String> experienceOptions = [
  //   'New Shop',
  //   'Less than 1 year',
  //   '1 to 5 years',
  //   '5 to 10 years',
  //   '10 to 15 years',
  //   '15 to 20 years',
  //   'Above 20 years',
  // ];

  // String? selectedExperience;



// Future<void> submitProfile() async {
// if (isSubmitting) return;

// FocusScope.of(context).unfocus();

// if (!validateForm()) {
// return;
// }

// final user = _auth.currentUser;

// if (user == null) {
// showMessage(
// 'Please verify your mobile number first.',
// );
// return;
// }

// final SparePartsLocation? position = currentLocation;

// if (position == null) {
// showMessage(
// 'Please attach your current location.',
// );
// return;
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
//   'Please accept the Privacy Policy and Terms & Conditions.',  
// );  

// return;

// }

// final name =
// nameController.text.trim();

// final mobile =
// mobileController.text.trim();
// final secondaryMobile = secondaryPhoneController.text.trim();

// final shopName =
// shopNameController.text.trim();

// // final secondaryMobile =
// //   secondaryPhoneController.text.trim();

// final categories =
// List<String>.from(
// selectedCategories,
// );

// final uid =
// user.uid;
// final double? latitude = currentLocation?.latitude;
// final double? longitude = currentLocation?.longitude;

// // ============================================================
// // SHOP TIMING
// // ============================================================

// final String? savedOpeningTime =
// isOpen24Hours
// ? null
// : openingTime == null
// ? null
// : timeToString(
// openingTime!,
// );

// final String? savedClosingTime =
// isOpen24Hours
// ? null
// : closingTime == null
// ? null
// : timeToString(
// closingTime!,
// );

// // ============================================================
// // START SUBMITTING
// // ============================================================

// setState(() {
// isSubmitting = true;
// });

// try {
// // ============================================================
// // 1. SAVE LOCALLY FIRST
// // ============================================================

// await saveLocally(  
//   uid: uid,  
//   name: name,  
//   mobile: mobile,  
//   secondaryMobile:secondaryMobile,  
//   shopName: shopName,  
//   categories: categories,  
//   latitude: latitude,  
//   longitude: longitude,  

//   openingTime: savedOpeningTime,  
//   closingTime: savedClosingTime,  

//   isOpen24Hours: isOpen24Hours,  
// );  

// // ============================================================  
// // 2. MARK USER LOGGED IN  
// // ============================================================  

// await CommonProfileService.saveLogin(  
//   uid: uid,  
//   name: name,  
//   mobile: mobile,  
//   role: 'autoSpareParts',  
// );  

// if (!mounted) return;  

// // ============================================================  
// // 3. SMALL DELAY FOR SMOOTH TRANSITION  
// // ============================================================  

// await Future.delayed(  
//   const Duration(  
//     seconds: 2,  
//   ),  
// );  

// if (!mounted) return;  

// // ============================================================  
// // 4. GO HOME  
// // ============================================================  

// Navigator.pushAndRemoveUntil(  
//   context,  
//   MaterialPageRoute(  
//     builder: (_) =>  
//         const ScreenHome(),  
//   ),  
//   (route) => false,  
// );  

// // ============================================================  
// // 5. FIRESTORE IN BACKGROUND  
// // ============================================================  

// unawaited(  
//   saveAutoSparePartsToFirestore(  
//     uid: uid,  
//     name: name,  
//     mobile: mobile,  
//     secondaryMobile: secondaryMobile,  
//     shopName: shopName,  
//     categories: categories,  
//     latitude: latitude,  
//     longitude: longitude,  

//     openingTime: savedOpeningTime,  
//     closingTime: savedClosingTime,  

//     isOpen24Hours: isOpen24Hours,  
//   ),  
// );

// } catch (e) {
// if (!mounted) return;

// setState(() {  
//   isSubmitting = false;  
// });  

// showMessage(  
//   'Unable to save your profile. Please try again.',  
// );

// }
// }
