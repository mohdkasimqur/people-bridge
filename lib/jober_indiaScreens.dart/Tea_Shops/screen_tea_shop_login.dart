// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:hive/hive.dart';


// // ============================================================
// // TEA SHOP LOGIN / REGISTRATION SCREEN
// // ============================================================

// class ScreenTeaShopLogin
//     extends StatefulWidget {

//   const ScreenTeaShopLogin({
//     super.key,
//   });

//   @override
//   State<ScreenTeaShopLogin>
//       createState() =>
//           _ScreenTeaShopLoginState();
// }


// // ============================================================
// // STATE
// // ============================================================

// class _ScreenTeaShopLoginState
//     extends State<ScreenTeaShopLogin> {

//   // ==========================================================
//   // COLORS
//   // ==========================================================

//   static const Color darkGreen =
//       Color(0xFF12652F);

//   static const Color green =
//       Color(0xFF198B35);

//   static const Color orange =
//       Color(0xFFED801D);

//   static const Color background =
//       Color(0xFFF8F8F8);


//   // ==========================================================
//   // FIREBASE
//   // ==========================================================

//   final FirebaseAuth _auth =
//       FirebaseAuth.instance;

//   final FirebaseFirestore _firestore =
//       FirebaseFirestore.instance;


//   // ==========================================================
//   // HIVE
//   // ==========================================================

//   final Box settingsBox =
//       Hive.box('settings');


//   // ==========================================================
//   // FORM KEY
//   // ==========================================================

//   final GlobalKey<FormState>
//       _formKey =
//       GlobalKey<FormState>();


//   // ==========================================================
//   // TEXT CONTROLLERS
//   // ==========================================================

//   final TextEditingController
//       usernameController =
//       TextEditingController();

//   final TextEditingController
//       shopNameController =
//       TextEditingController();

//   final TextEditingController
//       mobileController =
//       TextEditingController();

//   final TextEditingController
//       otpController =
//       TextEditingController();

//   final TextEditingController
//       categorySearchController =
//       TextEditingController();

//   final TextEditingController
//       customCategoryController =
//       TextEditingController();


//   // ==========================================================
//   // FOCUS NODES
//   // ==========================================================

//   final FocusNode usernameFocus =
//       FocusNode();

//   final FocusNode shopNameFocus =
//       FocusNode();

//   final FocusNode mobileFocus =
//       FocusNode();

//   final FocusNode otpFocus =
//       FocusNode();


//   // ==========================================================
//   // OTP
//   // ==========================================================

//   String verificationId = '';

//   bool otpSent = false;

//   bool otpVerified = false;

//   bool isSendingOtp = false;

//   bool isVerifyingOtp = false;

//   int resendSeconds = 30;

//   Timer? resendTimer;


//   // ==========================================================
//   // LOCATION
//   // ==========================================================

//   Position? currentPosition;

//   bool locationAttached = false;

//   bool isGettingLocation = false;


//   // ==========================================================
//   // CATEGORY
//   // ==========================================================

//   String selectedCategory = '';

//   bool showCustomCategory = false;


//   final List<String> shopCategories = [

//     'Coffee Shops',

//     'Tea Shops',

//     'Hotel',

//     'Restaurants',

//     'Thattukada',

//     'Other Business',
//   ];


//   // ==========================================================
//   // FILTERED CATEGORIES
//   // ==========================================================

//   List<String> get filteredCategories {

//     final query =
//         categorySearchController.text
//             .trim()
//             .toLowerCase();

//     if (query.isEmpty) {
//       return shopCategories;
//     }

//     return shopCategories
//         .where(
//           (category) =>
//               category
//                   .toLowerCase()
//                   .contains(query),
//         )
//         .toList();
//   }


//   // ==========================================================
//   // SUBMIT
//   // ==========================================================

//   bool isSubmitting = false;


//   // ==========================================================
//   // ERROR STATES
//   // ==========================================================

//   bool usernameError = false;

//   bool shopNameError = false;

//   bool mobileError = false;

//   bool categoryError = false;

//   bool locationError = false;


//   // ==========================================================
//   // INIT STATE
//   // ==========================================================

//   @override
//   void initState() {
//     super.initState();

//     categorySearchController.addListener(
//       _refreshCategories,
//     );
//   }


//   // ==========================================================
//   // REFRESH CATEGORY LIST
//   // ==========================================================

//   void _refreshCategories() {

//     if (!mounted) {
//       return;
//     }

//     setState(() {});
//   }


//   // ==========================================================
//   // SEND OTP
//   // ==========================================================

//   Future<void> sendOtp() async {

//     final mobile =
//         mobileController.text.trim();

//     if (mobile.isEmpty ||
//         mobile.length < 10) {

//       setState(() {
//         mobileError = true;
//       });

//       return;
//     }


//     setState(() {

//       mobileError = false;

//       isSendingOtp = true;
//     });


//     String phoneNumber =
//         mobile;


//     if (!phoneNumber.startsWith('+')) {

//       if (phoneNumber.startsWith('91') &&
//           phoneNumber.length == 12) {

//         phoneNumber =
//             '+$phoneNumber';

//       } else {

//         phoneNumber =
//             '+91$phoneNumber';
//       }
//     }


//     try {

//       await _auth.verifyPhoneNumber(

//         phoneNumber:
//             phoneNumber,

//         verificationCompleted:
//             (PhoneAuthCredential credential) async {

//           try {

//             await _auth.signInWithCredential(
//               credential,
//             );

//             if (!mounted) {
//               return;
//             }

//             setState(() {

//               otpVerified = true;

//               otpSent = true;

//               isSendingOtp = false;
//             });

//           } catch (e) {

//             debugPrint(
//               'Auto OTP verification error: $e',
//             );
//           }
//         },


//         verificationFailed:
//             (FirebaseAuthException e) {

//           debugPrint(
//             'OTP verification failed: '
//             '${e.code} ${e.message}',
//           );

//           if (!mounted) {
//             return;
//           }

//           setState(() {
//             isSendingOtp = false;
//           });

//           ScaffoldMessenger.of(context)
//               .showSnackBar(
//             SnackBar(
//               content: Text(
//                 e.message ??
//                     'Unable to send OTP.',
//               ),
//             ),
//           );
//         },


//         codeSent:
//             (
//               String id,
//               int? resendToken,
//             ) {

//           verificationId =
//               id;

//           if (!mounted) {
//             return;
//           }

//           setState(() {

//             otpSent = true;

//             otpVerified = false;

//             isSendingOtp = false;

//             resendSeconds = 30;
//           });


//           startResendTimer();
//         },


//         codeAutoRetrievalTimeout:
//             (String id) {

//           verificationId =
//               id;
//         },
//       );

//     } catch (e) {

//       debugPrint(
//         'Send OTP error: $e',
//       );

//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         isSendingOtp = false;
//       });
//     }
//   }


//   // ==========================================================
//   // RESEND TIMER
//   // ==========================================================

//   void startResendTimer() {

//     resendTimer?.cancel();


//     resendTimer =
//         Timer.periodic(
//       const Duration(
//         seconds: 1,
//       ),
//       (timer) {

//         if (resendSeconds <= 0) {

//           timer.cancel();

//           return;
//         }


//         if (!mounted) {

//           timer.cancel();

//           return;
//         }


//         setState(() {
//           resendSeconds--;
//         });
//       },
//     );
//   }


//   // ==========================================================
//   // VERIFY OTP
//   // ==========================================================

//   Future<void> verifyOtp() async {

//     if (verificationId.isEmpty) {
//       return;
//     }


//     final code =
//         otpController.text.trim();


//     if (code.length != 6) {

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Enter the 6 digit OTP.',
//           ),
//         ),
//       );

//       return;
//     }


//     setState(() {
//       isVerifyingOtp = true;
//     });


//     try {

//       final credential =
//           PhoneAuthProvider.credential(
//         verificationId:
//             verificationId,
//         smsCode:
//             code,
//       );


//       await _auth.signInWithCredential(
//         credential,
//       );


//       if (!mounted) {
//         return;
//       }


//       setState(() {

//         otpVerified = true;

//         isVerifyingOtp = false;
//       });


//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Mobile number verified successfully.',
//           ),
//         ),
//       );

//     } on FirebaseAuthException catch (e) {

//       debugPrint(
//         'OTP verify error: '
//         '${e.code} ${e.message}',
//       );


//       if (!mounted) {
//         return;
//       }


//       setState(() {
//         isVerifyingOtp = false;
//       });


//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Invalid OTP. Please try again.',
//           ),
//         ),
//       );

//     } catch (e) {

//       debugPrint(
//         'OTP verification error: $e',
//       );


//       if (!mounted) {
//         return;
//       }


//       setState(() {
//         isVerifyingOtp = false;
//       });
//     }
//   }
//   // ==========================================================
//   // GET CURRENT LOCATION
//   // ==========================================================

//   Future<void> attachCurrentLocation() async {

//     if (isGettingLocation) {
//       return;
//     }

//     setState(() {
//       isGettingLocation = true;
//       locationError = false;
//     });

//     try {

//       // ------------------------------------------------------
//       // CHECK LOCATION SERVICE
//       // ------------------------------------------------------

//       final serviceEnabled =
//           await Geolocator
//               .isLocationServiceEnabled();

//       if (!serviceEnabled) {

//         await Geolocator
//             .openLocationSettings();

//         return;
//       }


//       // ------------------------------------------------------
//       // CHECK PERMISSION
//       // ------------------------------------------------------

//       LocationPermission permission =
//           await Geolocator
//               .checkPermission();


//       if (permission ==
//           LocationPermission.denied) {

//         permission =
//             await Geolocator
//                 .requestPermission();
//       }


//       // ------------------------------------------------------
//       // PERMISSION DENIED
//       // ------------------------------------------------------

//       if (permission ==
//           LocationPermission.denied) {

//         if (!mounted) {
//           return;
//         }

//         setState(() {
//           locationError = true;
//         });

//         ScaffoldMessenger.of(context)
//             .showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Location permission is required.',
//             ),
//           ),
//         );

//         return;
//       }


//       // ------------------------------------------------------
//       // PERMISSION DENIED FOREVER
//       // ------------------------------------------------------

//       if (permission ==
//           LocationPermission.deniedForever) {

//         if (!mounted) {
//           return;
//         }

//         setState(() {
//           locationError = true;
//         });

//         ScaffoldMessenger.of(context)
//             .showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Location permission is permanently denied. '
//               'Please enable it in Settings.',
//             ),
//           ),
//         );

//         await Geolocator
//             .openAppSettings();

//         return;
//       }


//       // ------------------------------------------------------
//       // GET CURRENT LOCATION
//       // ------------------------------------------------------

//       final position =
//           await Geolocator
//               .getCurrentPosition(
//         locationSettings:
//             const LocationSettings(
//           accuracy:
//               LocationAccuracy.high,
//         ),
//       );


//       if (!mounted) {
//         return;
//       }


//       setState(() {

//         currentPosition =
//             position;

//         locationAttached =
//             true;

//         locationError =
//             false;
//       });


//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Current location attached successfully.',
//           ),
//         ),
//       );

//     } catch (e) {

//       debugPrint(
//         'Location error: $e',
//       );


//       if (!mounted) {
//         return;
//       }


//       setState(() {
//         locationError = true;
//       });


//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Unable to get your current location.',
//           ),
//         ),
//       );

//     } finally {

//       if (mounted) {

//         setState(() {
//           isGettingLocation = false;
//         });
//       }
//     }
//   }


//   // ==========================================================
//   // INPUT DECORATION
//   // ==========================================================

//   InputDecoration inputDecoration({
//     required String hint,
//     required IconData icon,
//     bool hasError = false,
//   }) {

//     return InputDecoration(

//       hintText:
//           hint,

//       prefixIcon:
//           Icon(
//         icon,
//         color:
//             hasError
//                 ? Colors.red
//                 : green,
//       ),

//       filled:
//           true,

//       fillColor:
//           Colors.white,

//       errorText:
//           hasError
//               ? 'This field is required'
//               : null,

//       border:
//           OutlineInputBorder(
//         borderRadius:
//             BorderRadius.circular(
//           14,
//         ),
//         borderSide:
//             BorderSide(
//           color:
//               Colors.grey.shade300,
//         ),
//       ),

//       enabledBorder:
//           OutlineInputBorder(
//         borderRadius:
//             BorderRadius.circular(
//           14,
//         ),
//         borderSide:
//             BorderSide(
//           color:
//               Colors.grey.shade300,
//         ),
//       ),

//       focusedBorder:
//           OutlineInputBorder(
//         borderRadius:
//             BorderRadius.circular(
//           14,
//         ),
//         borderSide:
//             const BorderSide(
//           color:
//               green,
//           width:
//               2,
//         ),
//       ),

//       errorBorder:
//           OutlineInputBorder(
//         borderRadius:
//             BorderRadius.circular(
//           14,
//         ),
//         borderSide:
//             const BorderSide(
//           color:
//               Colors.red,
//         ),
//       ),

//       focusedErrorBorder:
//           OutlineInputBorder(
//         borderRadius:
//             BorderRadius.circular(
//           14,
//         ),
//         borderSide:
//             const BorderSide(
//           color:
//               Colors.red,
//           width:
//               2,
//         ),
//       ),
//     );
//   }


//   // ==========================================================
//   // PAGE TITLE
//   // ==========================================================

//   Widget pageHeader() {

//     return Container(

//       width:
//           double.infinity,

//       padding:
//           const EdgeInsets.fromLTRB(
//         24,
//         35,
//         24,
//         30,
//       ),

//       decoration:
//           const BoxDecoration(

//         gradient:
//             LinearGradient(

//           colors: [
//             darkGreen,
//             green,
//           ],

//           begin:
//               Alignment.topLeft,

//           end:
//               Alignment.bottomRight,
//         ),

//         borderRadius:
//             BorderRadius.only(

//           bottomLeft:
//               Radius.circular(30),

//           bottomRight:
//               Radius.circular(30),
//         ),
//       ),

//       child:
//           SafeArea(

//         bottom:
//             false,

//         child:
//             Column(

//           crossAxisAlignment:
//               CrossAxisAlignment.start,

//           children: [

//             const Icon(
//               Icons.local_cafe,
//               size: 48,
//               color: Colors.white,
//             ),

//             const SizedBox(
//               height: 12,
//             ),

//             const Text(
//               'Tea Shop Registration',
//               style:
//                   TextStyle(
//                 fontSize: 27,
//                 fontWeight:
//                     FontWeight.bold,
//                 color:
//                     Colors.white,
//               ),
//             ),

//             const SizedBox(
//               height: 6,
//             ),

//             const Text(
//               'Create your shop profile and help '
//               'customers find your business nearby.',
//               style:
//                   TextStyle(
//                 fontSize: 14,
//                 color:
//                     Colors.white70,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }


//   // ==========================================================
//   // USERNAME SECTION
//   // ==========================================================

//   Widget usernameSection() {

//     return Column(

//       crossAxisAlignment:
//           CrossAxisAlignment.start,

//       children: [

//         const Text(
//           'Username',
//           style:
//               TextStyle(
//             fontSize: 16,
//             fontWeight:
//                 FontWeight.w600,
//           ),
//         ),

//         const SizedBox(
//           height: 8,
//         ),

//         TextField(

//           controller:
//               usernameController,

//           focusNode:
//               usernameFocus,

//           textInputAction:
//               TextInputAction.next,

//           onChanged:
//               (_) {

//             if (usernameError) {

//               setState(() {
//                 usernameError = false;
//               });
//             }
//           },

//           decoration:
//               inputDecoration(
//             hint:
//                 'Enter your username',
//             icon:
//                 Icons.person_outline,
//             hasError:
//                 usernameError,
//           ),
//         ),
//       ],
//     );
//   }


//   // ==========================================================
//   // SHOP NAME SECTION
//   // ==========================================================

//   Widget shopNameSection() {

//     return Column(

//       crossAxisAlignment:
//           CrossAxisAlignment.start,

//       children: [

//         const Text(
//           'Shop Name',
//           style:
//               TextStyle(
//             fontSize: 16,
//             fontWeight:
//                 FontWeight.w600,
//           ),
//         ),

//         const SizedBox(
//           height: 8,
//         ),

//         TextField(

//           controller:
//               shopNameController,

//           focusNode:
//               shopNameFocus,

//           textInputAction:
//               TextInputAction.next,

//           onChanged:
//               (_) {

//             if (shopNameError) {

//               setState(() {
//                 shopNameError = false;
//               });
//             }
//           },

//           decoration:
//               inputDecoration(
//             hint:
//                 'Enter your shop name',
//             icon:
//                 Icons.storefront_outlined,
//             hasError:
//                 shopNameError,
//           ),
//         ),
//       ],
//     );
//   }


//   // ==========================================================
//   // MOBILE NUMBER SECTION
//   // ==========================================================

//   Widget mobileSection() {

//     return Column(

//       crossAxisAlignment:
//           CrossAxisAlignment.start,

//       children: [

//         const Text(
//           'Mobile Number',
//           style:
//               TextStyle(
//             fontSize: 16,
//             fontWeight:
//                 FontWeight.w600,
//           ),
//         ),

//         const SizedBox(
//           height: 8,
//         ),

//         Row(

//           children: [

//             Expanded(

//               child:
//                   TextField(

//                 controller:
//                     mobileController,

//                 focusNode:
//                     mobileFocus,

//                 keyboardType:
//                     TextInputType.phone,

//                 textInputAction:
//                     TextInputAction.done,

//                 maxLength:
//                     10,

//                 enabled:
//                     !otpVerified,

//                 onChanged:
//                     (_) {

//                   if (mobileError) {

//                     setState(() {
//                       mobileError = false;
//                     });
//                   }
//                 },

//                 decoration:
//                     inputDecoration(
//                   hint:
//                       'Enter mobile number',
//                   icon:
//                       Icons.phone_outlined,
//                   hasError:
//                       mobileError,
//                 ).copyWith(
//                   counterText:
//                       '',
//                 ),
//               ),
//             ),

//             const SizedBox(
//               width: 10,
//             ),

//             SizedBox(

//               height: 55,

//               child:
//                   ElevatedButton(

//                 onPressed:
//                     isSendingOtp ||
//                             otpVerified
//                         ? null
//                         : sendOtp,

//                 style:
//                     ElevatedButton.styleFrom(

//                   backgroundColor:
//                       orange,

//                   foregroundColor:
//                       Colors.white,

//                   shape:
//                       RoundedRectangleBorder(

//                     borderRadius:
//                         BorderRadius.circular(
//                       14,
//                     ),
//                   ),
//                 ),

//                 child:
//                     isSendingOtp

//                         ? const SizedBox(

//                             width:
//                                 22,

//                             height:
//                                 22,

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
//                                 : 'Send OTP',
//                           ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }


//   // ==========================================================
//   // OTP SECTION
//   // ==========================================================

//   Widget otpSection() {

//     if (!otpSent) {
//       return const SizedBox();
//     }


//     if (otpVerified) {

//       return Container(

//         width:
//             double.infinity,

//         padding:
//             const EdgeInsets.all(
//           15,
//         ),

//         decoration:
//             BoxDecoration(

//           color:
//               const Color(
//             0xFFEAF7EC,
//           ),

//           borderRadius:
//               BorderRadius.circular(
//             14,
//           ),
//         ),

//         child:
//             const Row(

//           children: [

//             Icon(
//               Icons.verified,
//               color:
//                   green,
//             ),

//             SizedBox(
//               width: 10,
//             ),

//             Expanded(

//               child:
//                   Text(
//                 'Mobile number verified successfully.',
//                 style:
//                     TextStyle(
//                   fontWeight:
//                       FontWeight.w600,
//                   color:
//                       darkGreen,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }


//     return Column(

//       crossAxisAlignment:
//           CrossAxisAlignment.start,

//       children: [

//         const SizedBox(
//           height: 5,
//         ),

//         const Text(
//           'Enter OTP',
//           style:
//               TextStyle(
//             fontSize: 16,
//             fontWeight:
//                 FontWeight.w600,
//           ),
//         ),

//         const SizedBox(
//           height: 8,
//         ),

//         Row(

//           children: [

//             Expanded(

//               child:
//                   TextField(

//                 controller:
//                     otpController,

//                 focusNode:
//                     otpFocus,

//                 keyboardType:
//                     TextInputType.number,

//                 maxLength:
//                     6,

//                 decoration:
//                     inputDecoration(
//                   hint:
//                       'Enter 6 digit OTP',
//                   icon:
//                       Icons.lock_outline,
//                 ).copyWith(
//                   counterText:
//                       '',
//                 ),
//               ),
//             ),

//             const SizedBox(
//               width: 10,
//             ),

//             SizedBox(

//               height: 55,

//               child:
//                   ElevatedButton(

//                 onPressed:
//                     isVerifyingOtp
//                         ? null
//                         : verifyOtp,

//                 style:
//                     ElevatedButton.styleFrom(

//                   backgroundColor:
//                       green,

//                   foregroundColor:
//                       Colors.white,

//                   shape:
//                       RoundedRectangleBorder(

//                     borderRadius:
//                         BorderRadius.circular(
//                       14,
//                     ),
//                   ),
//                 ),

//                 child:
//                     isVerifyingOtp

//                         ? const SizedBox(

//                             width:
//                                 22,

//                             height:
//                                 22,

//                             child:
//                                 CircularProgressIndicator(
//                               strokeWidth:
//                                   2,
//                               color:
//                                   Colors.white,
//                             ),
//                           )

//                         : const Text(
//                             'Verify',
//                           ),
//               ),
//             ),
//           ],
//         ),


//         const SizedBox(
//           height: 10,
//         ),


//         // ------------------------------------------------------
//         // RESEND OTP
//         // ------------------------------------------------------

//         if (resendSeconds > 0)

//           Text(
//             'Resend OTP in $resendSeconds seconds',
//             style:
//                 const TextStyle(
//               color:
//                   Colors.grey,
//               fontSize:
//                   13,
//             ),
//           )

//         else

//           TextButton.icon(

//             onPressed:
//                 isSendingOtp
//                     ? null
//                     : sendOtp,

//             icon:
//                 const Icon(
//               Icons.refresh,
//             ),

//             label:
//                 const Text(
//               'Resend OTP',
//             ),
//           ),
//       ],
//     );
//   }


//   // ==========================================================
//   // CATEGORY SEARCH SECTION
//   // ==========================================================

//   Widget categorySearchSection() {

//     return TextField(

//       controller:
//           categorySearchController,

//       decoration:
//           InputDecoration(

//         hintText:
//             'Search shop category',

//         prefixIcon:
//             const Icon(
//           Icons.search,
//           color:
//               green,
//         ),

//         filled:
//             true,

//         fillColor:
//             Colors.white,

//         border:
//             OutlineInputBorder(

//           borderRadius:
//               BorderRadius.circular(
//             14,
//           ),

//           borderSide:
//               BorderSide(
//             color:
//                 Colors.grey.shade300,
//           ),
//         ),

//         enabledBorder:
//             OutlineInputBorder(

//           borderRadius:
//               BorderRadius.circular(
//             14,
//           ),

//           borderSide:
//               BorderSide(
//             color:
//                 Colors.grey.shade300,
//           ),
//         ),

//         focusedBorder:
//             OutlineInputBorder(

//           borderRadius:
//               BorderRadius.circular(
//             14,
//           ),

//           borderSide:
//               const BorderSide(
//             color:
//                 green,
//             width:
//                 2,
//           ),
//         ),
//       ),
//     );
//   }


//   // ==========================================================
//   // SHOP CATEGORY SECTION
//   // ==========================================================

//   Widget categorySection() {

//     return Column(

//       crossAxisAlignment:
//           CrossAxisAlignment.start,

//       children: [

//         const Text(
//           'Shop Category',
//           style:
//               TextStyle(
//             fontSize: 18,
//             fontWeight:
//                 FontWeight.bold,
//           ),
//         ),

//         const SizedBox(
//           height: 8,
//         ),


//         const Text(
//           'Select the category that best describes your shop.',
//           style:
//               TextStyle(
//             color:
//                 Colors.grey,
//             fontSize:
//                 13,
//           ),
//         ),

//         const SizedBox(
//           height: 15,
//         ),


//         // ------------------------------------------------------
//         // SEARCH
//         // ------------------------------------------------------

//         categorySearchSection(),


//         const SizedBox(
//           height: 12,
//         ),


//         // ------------------------------------------------------
//         // CATEGORY LIST
//         // ------------------------------------------------------

//         Container(

//           constraints:
//               const BoxConstraints(
//             maxHeight:
//                 280,
//           ),

//           decoration:
//               BoxDecoration(

//             color:
//                 Colors.white,

//             borderRadius:
//                 BorderRadius.circular(
//               14,
//             ),

//             border:
//                 Border.all(
//               color:
//                   categoryError
//                       ? Colors.red
//                       : Colors.grey.shade300,
//             ),
//           ),

//           child:
//               ListView.builder(

//             shrinkWrap:
//                 true,

//             itemCount:
//                 filteredCategories.length,

//             itemBuilder:
//                 (context, index) {

//               final category =
//                   filteredCategories[index];


//               return RadioListTile<
//                   String>(

//                 value:
//                     category,

//                 groupValue:
//                     selectedCategory,

//                 title:
//                     Text(
//                   category,
//                   style:
//                       const TextStyle(
//                     fontWeight:
//                         FontWeight.w500,
//                   ),
//                 ),

//                 activeColor:
//                     green,

//                 onChanged:
//                     (value) {

//                   if (value == null) {
//                     return;
//                   }


//                   setState(() {

//                     selectedCategory =
//                         value;

//                     categoryError =
//                         false;

//                     showCustomCategory =
//                         false;

//                     customCategoryController
//                         .clear();
//                   });
//                 },
//               );
//             },
//           ),
//         ),


//         if (categoryError)

//           const Padding(

//             padding:
//                 EdgeInsets.only(
//               top: 7,
//               left: 12,
//             ),

//             child:
//                 Text(
//               'Please select a shop category.',
//               style:
//                   TextStyle(
//                 color:
//                     Colors.red,
//                 fontSize:
//                     12,
//               ),
//             ),
//           ),


//         const SizedBox(
//           height: 15,
//         ),


//         // ------------------------------------------------------
//         // ADD YOUR OWN SHOP
//         // ------------------------------------------------------

//         OutlinedButton.icon(

//           onPressed:
//               () {

//             setState(() {

//               showCustomCategory =
//                   !showCustomCategory;

//               if (showCustomCategory) {

//                 selectedCategory = '';

//                 categoryError = false;
//               }
//             });
//           },

//           icon:
//               const Icon(
//             Icons.add_business_outlined,
//           ),

//           label:
//               const Text(
//             'Add Your Own Shop Category',
//           ),

//           style:
//               OutlinedButton.styleFrom(

//             foregroundColor:
//                 orange,

//             minimumSize:
//                 const Size(
//               double.infinity,
//               52,
//             ),

//             side:
//                 const BorderSide(
//               color:
//                   orange,
//             ),

//             shape:
//                 RoundedRectangleBorder(

//               borderRadius:
//                   BorderRadius.circular(
//                 14,
//               ),
//             ),
//           ),
//         ),


//         // ------------------------------------------------------
//         // CUSTOM CATEGORY FIELD
//         // ------------------------------------------------------

//         if (showCustomCategory) ...[

//           const SizedBox(
//             height: 12,
//           ),

//           TextField(

//             controller:
//                 customCategoryController,

//             textCapitalization:
//                 TextCapitalization.words,

//             onChanged:
//                 (value) {

//               if (value.trim().isNotEmpty) {

//                 setState(() {
//                   categoryError =
//                       false;
//                 });
//               }
//             },

//             decoration:
//                 inputDecoration(
//               hint:
//                   'Enter your shop category',
//               icon:
//                   Icons.store_outlined,
//               hasError:
//                   categoryError,
//             ),
//           ),
//         ],
//       ],
//     );
//   }
//   // ==========================================================
//   // GET FINAL CATEGORY
//   // ==========================================================

//   String get finalCategory {

//     if (showCustomCategory) {
//       return customCategoryController.text
//           .trim();
//     }

//     return selectedCategory.trim();
//   }


//   // ==========================================================
//   // SUBMIT PROFILE
//   // ==========================================================

//   Future<void> submitProfile() async {

//     // --------------------------------------------------------
//     // PREVENT DOUBLE TAP / DUPLICATE SUBMISSION
//     // --------------------------------------------------------

//     if (isSubmitting) {
//       return;
//     }


//     bool hasError = false;


//     // --------------------------------------------------------
//     // USERNAME
//     // --------------------------------------------------------

//     if (usernameController.text
//         .trim()
//         .isEmpty) {

//       usernameError = true;
//       hasError = true;

//     } else {

//       usernameError = false;
//     }


//     // --------------------------------------------------------
//     // SHOP NAME
//     // --------------------------------------------------------

//     if (shopNameController.text
//         .trim()
//         .isEmpty) {

//       shopNameError = true;
//       hasError = true;

//     } else {

//       shopNameError = false;
//     }


//     // --------------------------------------------------------
//     // MOBILE
//     // --------------------------------------------------------

//     final mobile =
//         mobileController.text.trim();

//     if (mobile.isEmpty ||
//         mobile.length != 10) {

//       mobileError = true;
//       hasError = true;

//     } else {

//       mobileError = false;
//     }


//     // --------------------------------------------------------
//     // OTP
//     // --------------------------------------------------------

//     if (!otpVerified) {

//       hasError = true;

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please verify your mobile number first.',
//           ),
//         ),
//       );
//     }


//     // --------------------------------------------------------
//     // CATEGORY
//     // --------------------------------------------------------

//     final category =
//         finalCategory;

//     if (category.isEmpty) {

//       categoryError = true;
//       hasError = true;
//     } else {

//       categoryError = false;
//     }


//     // --------------------------------------------------------
//     // LOCATION
//     // --------------------------------------------------------

//     if (!locationAttached ||
//         currentPosition == null) {

//       locationError = true;
//       hasError = true;

//     } else {

//       locationError = false;
//     }


//     // --------------------------------------------------------
//     // SHOW VALIDATION ERRORS
//     // --------------------------------------------------------

//     if (mounted) {

//       setState(() {});
//     }


//     if (hasError) {
//       return;
//     }


//     // --------------------------------------------------------
//     // START SUBMISSION
//     // --------------------------------------------------------

//     setState(() {

//       isSubmitting = true;
//     });


//     try {

//       // ------------------------------------------------------
//       // CURRENT FIREBASE USER
//       // ------------------------------------------------------

//       final user =
//           _auth.currentUser;


//       if (user == null) {

//         throw Exception(
//           'User is not authenticated.',
//         );
//       }


//       // ------------------------------------------------------
//       // CREATE SHOP DOCUMENT
//       //
//       // Auto ID prevents collisions when many shops
//       // register at the same time.
//       // ------------------------------------------------------

//       final shopDocument =
//           _firestore
//               .collection('tea_shops')
//               .doc();


//       final shopId =
//           shopDocument.id;


//       // ------------------------------------------------------
//       // LOCATION
//       // ------------------------------------------------------

//       final latitude =
//           currentPosition!
//               .latitude;

//       final longitude =
//           currentPosition!
//               .longitude;


//       // ------------------------------------------------------
//       // SHOP DATA
//       // ------------------------------------------------------

//       final Map<String, dynamic>
//           shopData = {

//         'shopId':
//             shopId,

//         'userId':
//             user.uid,

//         'username':
//             usernameController.text
//                 .trim(),

//         'shopName':
//             shopNameController.text
//                 .trim(),

//         'mobile':
//             mobile,

//         'category':
//             category,

//         'categorySearch':
//             category
//                 .toLowerCase(),

//         'latitude':
//             latitude,

//         'longitude':
//             longitude,

//         'location':
//             GeoPoint(
//           latitude,
//           longitude,
//         ),

//         'isActive':
//             true,

//         'createdAt':
//             FieldValue.serverTimestamp(),

//         'updatedAt':
//             FieldValue.serverTimestamp(),
//       };


//       // ------------------------------------------------------
//       // SAVE TO FIRESTORE
//       // ------------------------------------------------------

//       await shopDocument.set(
//         shopData,
//       );


//       // ------------------------------------------------------
//       // SAVE BASIC INFORMATION TO HIVE
//       //
//       // This allows the app to remember the registered
//       // shop locally without repeatedly loading everything.
//       // ------------------------------------------------------

//       await settingsBox.put(
//         'teaShopRegistered',
//         true,
//       );

//       await settingsBox.put(
//         'teaShopId',
//         shopId,
//       );

//       await settingsBox.put(
//         'teaShopUsername',
//         usernameController.text
//             .trim(),
//       );

//       await settingsBox.put(
//         'teaShopName',
//         shopNameController.text
//             .trim(),
//       );

//       await settingsBox.put(
//         'teaShopMobile',
//         mobile,
//       );

//       await settingsBox.put(
//         'teaShopCategory',
//         category,
//       );

//       await settingsBox.put(
//         'teaShopLatitude',
//         latitude,
//       );

//       await settingsBox.put(
//         'teaShopLongitude',
//         longitude,
//       );


//       // ------------------------------------------------------
//       // SUCCESS
//       // ------------------------------------------------------

//       if (!mounted) {
//         return;
//       }


//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Tea shop profile created successfully.',
//           ),
//           duration:
//               Duration(seconds: 2),
//         ),
//       );


//       // ------------------------------------------------------
//       // GO BACK
//       //
//       // Change this later to your Tea Shop Home screen
//       // when that screen is ready.
//       // ------------------------------------------------------

//       await Future.delayed(
//         const Duration(
//           milliseconds: 800,
//         ),
//       );


//       if (!mounted) {
//         return;
//       }


//       Navigator.pop(
//         context,
//         true,
//       );

//     } on FirebaseException catch (e) {

//       debugPrint(
//         'Tea shop Firestore error: '
//         '${e.code} ${e.message}',
//       );


//       if (!mounted) {
//         return;
//       }


//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         SnackBar(
//           content: Text(
//             e.message ??
//                 'Unable to save tea shop profile.',
//           ),
//         ),
//       );

//     } catch (e) {

//       debugPrint(
//         'Tea shop registration error: $e',
//       );


//       if (!mounted) {
//         return;
//       }


//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Something went wrong. Please try again.',
//           ),
//         ),
//       );

//     } finally {

//       if (mounted) {

//         setState(() {

//           isSubmitting = false;
//         });
//       }
//     }
//   }


//   // ==========================================================
//   // LOCATION BUTTON
//   // ==========================================================

//   Widget locationSection() {

//     return Column(

//       crossAxisAlignment:
//           CrossAxisAlignment.start,

//       children: [

//         const Text(
//           'Shop Location',
//           style:
//               TextStyle(
//             fontSize: 18,
//             fontWeight:
//                 FontWeight.bold,
//           ),
//         ),

//         const SizedBox(
//           height: 7,
//         ),

//         const Text(
//           'Attach your current shop location so customers '
//           'can find your shop nearby.',
//           style:
//               TextStyle(
//             color:
//                 Colors.grey,
//             fontSize:
//                 13,
//           ),
//         ),

//         const SizedBox(
//           height: 15,
//         ),

//         Container(

//           width:
//               double.infinity,

//           padding:
//               const EdgeInsets.all(
//             16,
//           ),

//           decoration:
//               BoxDecoration(

//             color:
//                 locationAttached
//                     ? const Color(
//                         0xFFEAF7EC,
//                       )
//                     : Colors.white,

//             borderRadius:
//                 BorderRadius.circular(
//               16,
//             ),

//             border:
//                 Border.all(
//               color:
//                   locationError
//                       ? Colors.red
//                       : locationAttached
//                           ? green
//                           : Colors.grey.shade300,
//             ),
//           ),

//           child:
//               Row(

//             children: [

//               Container(

//                 width:
//                     48,

//                 height:
//                     48,

//                 decoration:
//                     BoxDecoration(

//                   color:
//                       locationAttached
//                           ? green
//                           : Colors.grey.shade100,

//                   shape:
//                       BoxShape.circle,
//                 ),

//                 child:
//                     Icon(
//                   locationAttached
//                       ? Icons.location_on
//                       : Icons.location_off,
//                   color:
//                       locationAttached
//                           ? Colors.white
//                           : Colors.grey,
//                 ),
//               ),

//               const SizedBox(
//                 width: 14,
//               ),

//               Expanded(

//                 child:
//                     Column(

//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,

//                   children: [

//                     Text(
//                       locationAttached
//                           ? 'Current location attached'
//                           : 'Location not attached',
//                       style:
//                           const TextStyle(
//                         fontSize:
//                             15,
//                         fontWeight:
//                             FontWeight.w600,
//                       ),
//                     ),

//                     const SizedBox(
//                       height: 4,
//                     ),

//                     Text(
//                       locationAttached &&
//                               currentPosition != null
//                           ? '${currentPosition!.latitude.toStringAsFixed(5)}, '
//                             '${currentPosition!.longitude.toStringAsFixed(5)}'
//                           : 'Tap the button to attach your location.',
//                       style:
//                           const TextStyle(
//                         fontSize:
//                             12,
//                         color:
//                             Colors.grey,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(
//                 width: 8,
//               ),

//               ElevatedButton(

//                 onPressed:
//                     isGettingLocation
//                         ? null
//                         : attachCurrentLocation,

//                 style:
//                     ElevatedButton.styleFrom(

//                   backgroundColor:
//                       green,

//                   foregroundColor:
//                       Colors.white,

//                   padding:
//                       const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 12,
//                   ),

//                   shape:
//                       RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius.circular(
//                       12,
//                     ),
//                   ),
//                 ),

//                 child:
//                     isGettingLocation

//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child:
//                                 CircularProgressIndicator(
//                               strokeWidth: 2,
//                               color: Colors.white,
//                             ),
//                           )

//                         : Text(
//                             locationAttached
//                                 ? 'Update'
//                                 : 'Attach',
//                           ),
//               ),
//             ],
//           ),
//         ),

//         if (locationError)

//           const Padding(

//             padding:
//                 EdgeInsets.only(
//               top: 7,
//               left: 12,
//             ),

//             child:
//                 Text(
//               'Please attach your current location.',
//               style:
//                   TextStyle(
//                 color:
//                     Colors.red,
//                 fontSize:
//                     12,
//               ),
//             ),
//           ),
//       ],
//     );
//   }


//   // ==========================================================
//   // SUBMIT BUTTON
//   // ==========================================================

//   Widget submitButton() {

//     return SizedBox(

//       width:
//           double.infinity,

//       height:
//           56,

//       child:
//           ElevatedButton(

//         onPressed:
//             isSubmitting
//                 ? null
//                 : submitProfile,

//         style:
//             ElevatedButton.styleFrom(

//           backgroundColor:
//               darkGreen,

//           foregroundColor:
//               Colors.white,

//           disabledBackgroundColor:
//               Colors.grey.shade400,

//           shape:
//               RoundedRectangleBorder(

//             borderRadius:
//                 BorderRadius.circular(
//               16,
//             ),
//           ),

//           elevation:
//               2,
//         ),

//         child:
//             isSubmitting

//                 ? const SizedBox(

//                     width:
//                         25,

//                     height:
//                         25,

//                     child:
//                         CircularProgressIndicator(
//                       strokeWidth:
//                           2.5,
//                       color:
//                           Colors.white,
//                     ),
//                   )

//                 : const Row(

//                     mainAxisAlignment:
//                         MainAxisAlignment.center,

//                     children: [

//                       Icon(
//                         Icons.check_circle_outline,
//                       ),

//                       SizedBox(
//                         width: 10,
//                       ),

//                       Text(
//                         'Submit Profile',
//                         style:
//                             TextStyle(
//                           fontSize:
//                               17,
//                           fontWeight:
//                               FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//       ),
//     );
//   }


//   // ==========================================================
//   // BUILD
//   // ==========================================================

//   @override
//   Widget build(
//     BuildContext context,
//   ) {

//     return Scaffold(

//       backgroundColor:
//           background,

//       body:
//           SafeArea(

//         top:
//             false,

//         child:
//             Column(

//           children: [

//             // ------------------------------------------------
//             // HEADER
//             // ------------------------------------------------

//             pageHeader(),


//             // ------------------------------------------------
//             // SCROLLABLE CONTENT
//             // ------------------------------------------------

//             Expanded(

//               child:
//                   SingleChildScrollView(

//                 physics:
//                     const BouncingScrollPhysics(),

//                 padding:
//                     const EdgeInsets.fromLTRB(
//                   20,
//                   22,
//                   20,
//                   30,
//                 ),

//                 child:
//                     Form(

//                   key:
//                       _formKey,

//                   child:
//                       Column(

//                     crossAxisAlignment:
//                         CrossAxisAlignment.start,

//                     children: [

//                       usernameSection(),

//                       const SizedBox(
//                         height: 18,
//                       ),

//                       shopNameSection(),

//                       const SizedBox(
//                         height: 18,
//                       ),

//                       mobileSection(),

//                       const SizedBox(
//                         height: 12,
//                       ),

//                       otpSection(),

//                       const SizedBox(
//                         height: 24,
//                       ),

//                       categorySection(),

//                       const SizedBox(
//                         height: 25,
//                       ),

//                       locationSection(),

//                       const SizedBox(
//                         height: 30,
//                       ),

//                       submitButton(),

//                       const SizedBox(
//                         height: 20,
//                       ),

//                       const Center(
//                         child:
//                             Text(
//                           'Your information is securely stored.',
//                           style:
//                               TextStyle(
//                             fontSize:
//                                 12,
//                             color:
//                                 Colors.grey,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }


//   // ==========================================================
//   // DISPOSE
//   // ==========================================================

//   @override
//   void dispose() {

//     resendTimer?.cancel();

//     usernameController.dispose();

//     shopNameController.dispose();

//     mobileController.dispose();

//     otpController.dispose();

//     categorySearchController.dispose();

//     customCategoryController.dispose();

//     usernameFocus.dispose();

//     shopNameFocus.dispose();

//     mobileFocus.dispose();

//     otpFocus.dispose();

//     super.dispose();
//   }
// }


// Future<void> submitProfile() async {
//   if (isSubmitting) return;

//   FocusScope.of(context).unfocus();

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
//   // ==========================================================
//   // OTP VALIDATION
//   // ==========================================================

//   if (!otpVerified) {
//     showMessage(
//       'Please verify your mobile number first.',
//       error: true,
//     );
//     return;
//   }

//   final user =
//       FirebaseAuth.instance.currentUser;

//   if (user == null) {
//     showMessage(
//       'User authentication failed.',
//       error: true,
//     );
//     return;
//   }

//   setState(() {
//     isSubmitting = true;
//   });

//   try {
//     // ==========================================================
//     // SAVE BASIC DATA LOCALLY
//     // ==========================================================

//     await saveBasicTeaShopToHive();

//     // ==========================================================
//     // COMMON PROFILE DATA
//     // ==========================================================

//     await CommonProfileService.saveLogin(
//       uid: user.uid,
//       name:
//           shopNameController.text.trim(),
//       mobile:
//           mobileController.text.trim(),
//       role: 'tea_shop',
//     );

//     // ==========================================================
//     // OPTIONAL PROFILE PHOTO
//     // ==========================================================

//     if (profilePhoto != null) {
//       final uploadedUrl =
//           await uploadProfilePhoto(
//         user.uid,
//       );

//       if (uploadedUrl != null &&
//           uploadedUrl.isNotEmpty) {
//         profilePhotoUrl =
//             uploadedUrl;

//         debugPrint(
//           'PROFILE PHOTO URL SAVED: '
//           '$profilePhotoUrl',
//         );
//       }
//     }

//     // ==========================================================
//     // SAVE PROFILE TO FIRESTORE
//     // ==========================================================

//     await saveProfileToFirestore();

//     debugPrint(
//       'TEA SHOP PROFILE SAVED TO FIRESTORE',
//     );

//     // ==========================================================
//     // CHECK WIDGET
//     // ==========================================================

//     if (!mounted) return;

//     setState(() {
//       isSubmitting = false;
//     });

//     // ==========================================================
//     // GO TO HOME
//     // ==========================================================

//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             const ScreenHome(),
//       ),
//       (route) => false,
//     );
//   } catch (e) {
//     debugPrint(
//       'Submit profile error: $e',
//     );

//     if (!mounted) return;

//     setState(() {
//       isSubmitting = false;
//     });

//     showMessage(
//       'Something went wrong. Please try again.',
//       error: true,
//     );
//   }
// }

  //  // ============================================================
  // // OPENING TIME
  // // ============================================================

  // Future<void> selectOpeningTime() async {
  //   final TimeOfDay? selected =
  //       await showTimePicker(
  //     context: context,
  //     initialTime:
  //         openingTime ?? TimeOfDay.now(),
  //   );

  //   if (selected == null) return;

  //   if (!mounted) return;

  //   setState(() {
  //     openingTime = selected;
  //   });
  // }

  // // ============================================================
  // // CLOSING TIME
  // // ============================================================

  // Future<void> selectClosingTime() async {
  //   final TimeOfDay? selected =
  //       await showTimePicker(
  //     context: context,
  //     initialTime:
  //         closingTime ?? TimeOfDay.now(),
  //   );

  //   if (selected == null) return;

  //   if (!mounted) return;

  //   setState(() {
  //     closingTime = selected;
  //   });
  // }

  // // ============================================================
  // // TIME TO STRING
  // // ============================================================

  // String timeToString(TimeOfDay time) {
  //   final int hour =
  //       time.hourOfPeriod == 0
  //           ? 12
  //           : time.hourOfPeriod;

  //   final String minute =
  //       time.minute.toString().padLeft(2, '0');

  //   final String period =
  //       time.period == DayPeriod.am
  //           ? 'AM'
  //           : 'PM';

  //   return '$hour:$minute $period';
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
//                     const SizedBox(height: 10),

//                     SizedBox(
//   width: double.infinity,
//   height: 48,
//   child: OutlinedButton.icon(
//     onPressed: _showManualLocationDialog,
//     icon: const Icon(Icons.edit_location_alt_outlined),
//     label: const Text('Enter Shop Location'),
//     style: OutlinedButton.styleFrom(
//       foregroundColor: const Color(0xFF16803C),
//       side: const BorderSide(
//         color: Color(0xFF16803C),
//       ),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(24),
//       ),
//     ),
//   ),
// ),
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

//   Future<void> _showManualLocationDialog() async {
//   _shopLocationController.clear();

//   await showDialog(
//     context: context,
//     builder: (dialogContext) {
//       return AlertDialog(
//         title: const Text(
//           'Enter Shop Location',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         content: TextField(
//           controller: _shopLocationController,
//           maxLines: 4,
//           decoration: InputDecoration(
//             hintText:
//                 'Example: Near private bus stand',
//             labelText: 'Shop Location',
//             prefixIcon: const Icon(
//               Icons.location_on_outlined,
//               color: Color(0xFF16803C),
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(dialogContext);
//             },
//             child: const Text('Cancel'),
//           ),

//           ElevatedButton(
//             onPressed: () {
//               final String text =
//                   _shopLocationController.text.trim();

//               if (text.isEmpty) {
//                 showMessage(
//                   'Please enter your shop location.',
//                   error: true,
//                 );
//                 return;
//               }

//               Navigator.pop(dialogContext);

//               setState(() {
//                 currentLocation = TeaShopLocation(
//                   placeName: text,
//                   latitude: null,
//                   longitude: null,
//                 );

//                 isGettingLocation = false;
//                 isSearchingLocation = false;
//               });

//               showMessage(
//                 'Garage location added.',
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor:
//                   const Color(0xFF16803C),
//               foregroundColor: Colors.white,
//               elevation: 0,
//               shape: RoundedRectangleBorder(
//                 borderRadius:
//                     BorderRadius.circular(20),
//               ),
//             ),
//             child: const Text('Add Location'),
//           ),
//         ],
//       );
//     },
//   );
// }

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
//   currentLocation = TeaShopLocation(
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

// TextFormField(
      //   controller: secondaryPhoneController,
      //   keyboardType: TextInputType.phone,
      //   maxLength: 10,

      //   inputFormatters: [
      //     FilteringTextInputFormatter.digitsOnly,
      //   ],

      //   decoration: fieldDecoration(
      //     hint: 'Enter secondary mobile number (optional)',
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

// class TeaShopLocation {
//   final String placeName;
//   final double latitude;
//   final double longitude;

//   TeaShopLocation({
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

//   factory TeaShopLocation.fromMap(Map<String, dynamic> map) {
//     return TeaShopLocation(
//       placeName: map['placeName'] ?? '',
//       latitude: (map['latitude'] ?? 0).toDouble(),
//       longitude: (map['longitude'] ?? 0).toDouble(),
//     );
//   }
// }


//  Widget shopTimingSection() {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       sectionTitle(
//         'Shop Timing',
//       ),

//       const SizedBox(height: 10),

//       // ============================================================
//       // OPEN 24 HOURS BUTTON
//       // ============================================================

//       SizedBox(
//         width: double.infinity,
//         height: 54,
//         child: OutlinedButton(
//           onPressed: () {
//             setState(() {
//               isOpen24Hours = !isOpen24Hours;

//               // Clear selected times when 24 hours is enabled
//               if (isOpen24Hours) {
//                 openingTime = null;
//                 closingTime = null;
//               }
//             });
//           },
//           style: OutlinedButton.styleFrom(
//             backgroundColor: isOpen24Hours
//                 ? const Color(0xFF16803C)
//                 : const Color(0xFFF9F9F9),

//             foregroundColor: isOpen24Hours
//                 ? Colors.white
//                 : const Color(0xFF16803C),

//             side: BorderSide(
//               color: isOpen24Hours
//                   ? const Color(0xFF16803C)
//                   : Colors.grey.shade300,
//               width: 1.5,
//             ),

//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),

//             elevation: 0,
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 isOpen24Hours
//                     ? Icons.check_circle
//                     : Icons.access_time,
//                 size: 21,
//               ),

//               const SizedBox(width: 8),

//               Text(
//                 isOpen24Hours
//                     ? '✓ Open 24 Hours'
//                     : 'Open 24 Hours',
//                 style: const TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),

//       // ============================================================
//       // OPENING / CLOSING TIME
//       // ============================================================

//       if (!isOpen24Hours) ...[
//         const SizedBox(height: 12),

//         Row(
//           children: [
//             // ========================================================
//             // OPENING TIME
//             // ========================================================

//             Expanded(
//               child: InkWell(
//                 onTap: selectOpeningTime,
//                 borderRadius: BorderRadius.circular(20),
//                 child: Container(
//                   height: 62,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                   ),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF9F9F9),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                       color: Colors.grey.shade300,
//                       width: 1.5,
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(
//                         Icons.access_time,
//                         color: Color(0xFF16803C),
//                       ),

//                       const SizedBox(width: 10),

//                       Expanded(
//                         child: Text(
//                           openingTime == null
//                               ? 'Opening Time'
//                               : timeToString(
//                                   openingTime!,
//                                 ),
//                           style: TextStyle(
//                             fontSize: 15,
//                             color: openingTime == null
//                                 ? Colors.grey
//                                 : Colors.black,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(width: 12),

//             // ========================================================
//             // CLOSING TIME
//             // ========================================================

//             Expanded(
//               child: InkWell(
//                 onTap: selectClosingTime,
//                 borderRadius: BorderRadius.circular(20),
//                 child: Container(
//                   height: 62,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                   ),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF9F9F9),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                       color: Colors.grey.shade300,
//                       width: 1.5,
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(
//                         Icons.access_time,
//                         color: Color(0xFF16803C),
//                       ),

//                       const SizedBox(width: 10),

//                       Expanded(
//                         child: Text(
//                           closingTime == null
//                               ? 'Closing Time'
//                               : timeToString(
//                                   closingTime!,
//                                 ),
//                           style: TextStyle(
//                             fontSize: 15,
//                             color: closingTime == null
//                                 ? Colors.grey
//                                 : Colors.black,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     ],
//   );
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


class TeaShopLocation {
  final String placeName;
  final double? latitude;
  final double? longitude;

  TeaShopLocation({
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

  factory TeaShopLocation.fromMap(
    Map<String, dynamic> map,
  ) {
    return TeaShopLocation(
      placeName: map['placeName']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

// ============================================================
// TEA SHOP REGISTRATION SCREEN
// ============================================================

class ScreenTeaShopLogin extends StatefulWidget {
  const ScreenTeaShopLogin({super.key});

  @override
  State<ScreenTeaShopLogin> createState() =>
      _ScreenTeaShopLoginState();
}

class _ScreenTeaShopLoginState
    extends State<ScreenTeaShopLogin> {

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController shopNameController =
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

  final TextEditingController _shopLocationController =
    TextEditingController();

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth auth = FirebaseAuth.instance;

  final FirebaseFirestore firestore =
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
  // ============================================================
  // HIVE
  // ============================================================

  final Box settingsBox = Hive.box('settings');

  bool privacyPolicyAccepted = false;
  String? privacyPolicyError;

   File? profilePhoto;
  String? profilePhotoUrl;
bool isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();
  // ============================================================
  // OTP VARIABLES
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

  // ============================================================
  // SHOP TIMINGS
  // ============================================================

  TimeOfDay? openingTime;
  TimeOfDay? closingTime;
  bool isOpen24Hours = false;
  String? shopTimingError;

//bool shopsTimingError = false;

  // ============================================================
  // ERROR VARIABLES
  // ============================================================

  bool usernameError = false;

  bool shopNameError = false;

  bool mobileError = false;

  bool categoryError = false;

  bool locationError = false;
  bool secondaryMobileError = false;

   // ==========================================================
  // LOCATION
  // ==========================================================
TeaShopLocation? currentLocation;

bool isGettingLocation = false;
bool isSearchingLocation = false;

// Used to invalidate an older location request
int _locationRequestId = 0;
 
 
  // ==============================================================
  // SEND OTP
  // ===============================================================

Future<void> sendOTP({bool isResend = false}) async {
  if (isSendingOtp || isVerifying) return;

  final phone = mobileController.text.trim();

  if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
    showMessage( AppLocalizations.of(context)!.enteradigitmobilenumber
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
           ? const Color(0xFF176B32):Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
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
  // SECTION TITLE
  // SAME AS STUDENT REGISTRATION
  // ============================================================

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF202124),
      ),
    );
  }


Widget shopTimingSection() {
  return Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      sectionTitle(
        'Shop Timing',
      ),

      const SizedBox(height: 10),

      // ============================================================
      // OPEN 24 HOURS
      // ============================================================

      SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              isOpen24Hours =
                  !isOpen24Hours;

              if (isOpen24Hours) {
                openingTime = null;
                closingTime = null;
                shopTimingError = null;
              }
            });
          },

          style:
              OutlinedButton.styleFrom(
            backgroundColor:
                isOpen24Hours
                    ? const Color(0xFF16803C)
                    : const Color(0xFFF9F9F9),

            foregroundColor:
                isOpen24Hours
                    ? Colors.white
                    : const Color(0xFF16803C),

            side: BorderSide(
              color: shopTimingError != null
                  ? Colors.red
                  : isOpen24Hours
                      ? const Color(0xFF16803C)
                      : Colors.grey.shade300,
              width:
                  shopTimingError != null
                      ? 2
                      : 1.5,
            ),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20),
            ),

            elevation: 0,
          ),

          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
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
                style:
                    const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w600,
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
            Expanded(
              child: InkWell(
                onTap:
                    selectOpeningTime,
                borderRadius:
                    BorderRadius.circular(20),

                child: Container(
                  height: 62,

                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(0xFFF9F9F9),

                    borderRadius:
                        BorderRadius.circular(20),

                    border: Border.all(
                      color:
                          shopTimingError != null
                              ? Colors.red
                              : Colors.grey.shade300,
                      width:
                          shopTimingError != null
                              ? 2
                              : 1.5,
                    ),
                  ),

                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color:
                            Color(0xFF16803C),
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
                            color:
                                openingTime ==
                                        null
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

            Expanded(
              child: InkWell(
                onTap:
                    selectClosingTime,
                borderRadius:
                    BorderRadius.circular(20),

                child: Container(
                  height: 62,

                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(0xFFF9F9F9),

                    borderRadius:
                        BorderRadius.circular(20),

                    border: Border.all(
                      color:
                          shopTimingError != null
                              ? Colors.red
                              : Colors.grey.shade300,
                      width:
                          shopTimingError != null
                              ? 2
                              : 1.5,
                    ),
                  ),

                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color:
                            Color(0xFF16803C),
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
                            color:
                                closingTime ==
                                        null
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
      // TIMING ERROR
      // ============================================================

      if (shopTimingError != null) ...[
        const SizedBox(height: 6),

        Padding(
          padding:
              const EdgeInsets.only(left: 8),
          child: Text(
            shopTimingError!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 13,
            ),
          ),
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
    shopTimingError = null;
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
    shopTimingError = null;
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

  TimeOfDay? stringToTimeOfDay(String value) {
  try {
    final parts = value.trim().split(' ');

    if (parts.length != 2) {
      return null;
    }

    final timeParts = parts[0].split(':');

    if (timeParts.length != 2) {
      return null;
    }

    int hour = int.parse(timeParts[0]);
    final int minute = int.parse(timeParts[1]);

    final String period =
        parts[1].toUpperCase();

    if (period == 'AM') {
      if (hour == 12) {
        hour = 0;
      }
    } else if (period == 'PM') {
      if (hour != 12) {
        hour += 12;
      }
    } else {
      return null;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  } catch (e) {
    debugPrint(
      'Time parsing error: $e',
    );

    return null;
  }
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
  // CATEGORY
  // ============================================================
  bool isCategoryDropdownOpen = false;
 final List<String> customCategories = [];
  final List<String> selectedCategories = [];

  List<String> filteredCategories = [];

  bool showCustomCategory = false;

  String selectedCategory = '';

  final List<String> shopCategories = [
    'Coffee Shops',
    'Tea Shops',
    'Hotel',
    'Restaurants',
    'Thattukada',
    'Other Business',
  ];

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();
     filteredCategories =
        List<String>.from(
      shopCategories,
    );
     filteredStates = List<String>.from(indiaStates);

  loadDistricts();

    categorySearchController.addListener(
      _refreshCategories,
    );
  }

   List<String> get allCategories {

    final List<String> result = [];

    for (final category in shopCategories) {

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

              hintText:'Enter Tea Shop category',

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

  // ============================================================
  // REFRESH CATEGORY LIST
  // ============================================================

  void _refreshCategories() {
    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // GET FINAL CATEGORY
  // ============================================================

  // String get finalCategory {
  //   if (showCustomCategory) {
  //     return customCategoryController.text.trim();
  //   }

  //   return selectedCategory.trim();
  // }
  String get finalCategory {
  return selectedCategories.join(', ');
}

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    usernameController.dispose();
    shopNameController.dispose();
    mobileController.dispose();
    otpController.dispose();
    secondaryPhoneController.dispose();
    categorySearchController.dispose();
    customCategoryController.dispose();
    descriptionController.dispose();
    _shopLocationController.dispose();
    stateSearchController.dispose();
    districtSearchController.dispose();



    timer?.cancel();

    super.dispose();
  }


  // ============================================================
  // DOCTOR-STYLE DROPDOWN SYSTEM
  // TEA SHOP CATEGORY SECTION
  // ============================================================

  Widget categorySection() {
    final categories =
        filteredCategories;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        sectionTitle(
          'Shop Categories',
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
                                    'Select Shops',
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


  // ============================================================
  // SAVE BASIC TEA SHOP DATA TO HIVE
  // ============================================================

 Future<void> saveBasicTeaShopToHive() async {
  try {
    final User? user = auth.currentUser;

    await settingsBox.put(
      'teaShopRegistered',
      true,
    );

    await settingsBox.put(
      'teaShopUsername',
      usernameController.text.trim(),
    );

    await settingsBox.put(
      'teaShopName',
      shopNameController.text.trim(),
    );

    await settingsBox.put(
      'teaShopMobile',
      mobileController.text.trim(),
    );

    await settingsBox.put(
  'teaShopSecondaryMobile',
  secondaryPhoneController.text.trim(),
);

 // State
await settingsBox.put(
  'teaShopState',
  selectedState!.trim(),
);

// District
await settingsBox.put(
  'teaShopDistrict',
  selectedDistrict!.trim(),
);

// Nearest town or city
await settingsBox.put(
  'teaShopNearestTown',
  nearestCityController.text.trim(),
);


    await settingsBox.put(
      'teaShopCategory',
      finalCategory,
    );

    // ==========================================================
    // OPTIONAL SHOP TIMING
    // ==========================================================

    await settingsBox.put(
      'teaShopOpeningTime',
      openingTime == null
          ? null
          : timeToString(openingTime!),
    );

    await settingsBox.put(
      'teaShopClosingTime',
      closingTime == null
          ? null
          : timeToString(closingTime!),
    );

    await settingsBox.put(
  'teaShopIsOpen24Hours',
  isOpen24Hours,
);

    // ==========================================================
    // OPTIONAL DESCRIPTION
    // ==========================================================

    final String description =
        descriptionController.text.trim();

    await settingsBox.put(
      'teaShopDescription',
      description.isEmpty
          ? null
          : description,
    );

    // ==========================================================
    // ROLE
    // ==========================================================

    await settingsBox.put(
      'teaShopRole',
      'tea_shop',
    );

    if (user != null) {
      await settingsBox.put(
        'teaShopUid',
        user.uid,
      );
    }

    // ==========================================================
    // LOCATION
    // ==========================================================

    if (currentLocation != null) {
      await settingsBox.put(
        'teaShopLatitude',
        currentLocation!.latitude,
      );

      await settingsBox.put(
        'teaShopLongitude',
        currentLocation!.longitude,
      );
    }

    debugPrint(
      'Tea shop profile saved successfully to Hive.',
    );
  } catch (e) {
    debugPrint(
      'Tea shop Hive save error: $e',
    );
  }
}

Future<void> saveTeaShopCategoriesToFirestore() async {
  final User? user = auth.currentUser;

  if (user == null) {
    throw Exception('User is not authenticated.');
  }

  final FirebaseFirestore db = FirebaseFirestore.instance;

  final Set<String> defaultNames = shopCategories
      .map((category) => category.trim().toLowerCase())
      .toSet();

  final Set<String> categoriesToSave = selectedCategories
      .map((category) => category.trim())
      .where((category) => category.isNotEmpty)
      .toSet();

  for (final String name in categoriesToSave) {
    final String categoryId =
        Uri.encodeComponent(name.toLowerCase());

    final DocumentReference<Map<String, dynamic>> categoryRef =
        db.collection('teaShopCategories').doc(categoryId);

    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(categoryRef);
      final data = snapshot.data() ?? <String, dynamic>{};

      final List<String> owners =
          (data['teaShopUids'] as List?)
                  ?.map((item) => item.toString())
                  .toList() ??
              <String>[];

      if (!owners.contains(user.uid)) {
        owners.add(user.uid);
      }

      final bool isCustom =
          data['isCustom'] == true ||
          !defaultNames.contains(name.toLowerCase());

      transaction.set(
        categoryRef,
        {
          'name': name,
          'normalizedName': name.toLowerCase(),
          'isCustom': isCustom,
          'teaShopUids': owners,
          'updatedAt': FieldValue.serverTimestamp(),
          if (!snapshot.exists)
            'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}
  // ============================================================
  // SAVE TEA SHOP PROFILE TO FIRESTORE
  // ============================================================

 Future<void> saveProfileToFirestore() async {
  final User? user = auth.currentUser;

  if (user == null) {
    throw Exception(
      'User is not authenticated.',
    );
  }

  if (currentLocation == null) {
    throw Exception(
      'Shop location is missing.',
    );
  }

  final String shopId = user.uid;

  // final double latitude =
  //     currentLocation!.latitude;

  // final double longitude =
  //     currentLocation!.longitude;

  // ==========================================================
  // OPTIONAL SHOP TIMING
  // ==========================================================

  final String? opening =
      openingTime == null
          ? null
          : timeToString(openingTime!);

  final String? closing =
      closingTime == null
          ? null
          : timeToString(closingTime!);

  // ==========================================================
  // OPTIONAL DESCRIPTION
  // ==========================================================

  final String? description =
      descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim();

  // ==========================================================
  // FIRESTORE
  // ==========================================================

  await firestore
      .collection('tea_shops')
      .doc(shopId)
      .set(
    {
      'shopId': shopId,

      'userId': user.uid,

      'uid': user.uid,

      'username':
          usernameController.text.trim(),

      'shopName':
          shopNameController.text.trim(),

      'mobile':
          mobileController.text.trim(),
          'secondaryMobile':
    secondaryPhoneController.text.trim(),

      // 'category':
      //     finalCategory,

      // 'categorySearch':
      //     finalCategory.toLowerCase(),
      // All categories selected during registration.
'categories': List<String>.from(selectedCategories),

// Keep the comma-separated field for compatibility
// with any existing code that reads "category".
'category': selectedCategories.join(', '),

'categorySearch': selectedCategories
    .map((category) => category.toLowerCase().trim())
    .join(', '),

// Available until the provider logs out.
// 'isOnline': true,
'isOnline': true,
'onlineUpdatedAt': FieldValue.serverTimestamp(),
//'isActive': true,

      // ========================================================
      // OPTIONAL TIMING
      // ========================================================

      'openingTime':
          opening,

      'closingTime':
          closing,
      'isOpen24Hours': isOpen24Hours,

      // ========================================================
      // OPTIONAL DESCRIPTION
      // ========================================================

      'description':
          description,

      // ========================================================
      // LOCATION
      // ========================================================

        'location':
    currentLocation?.toMap(),

      // ========================================================
      // ROLE
      // ========================================================

      'role':
          'tea_shop',

      'isActive':
          true,

      'profilePhotoUrl':
          profilePhotoUrl,

      'updatedAt':
          FieldValue.serverTimestamp(),
    },
    SetOptions(
      merge: true,
    ),
  );
}

Future<void> submitProfile() async {
  if (isSubmitting) return;

  FocusScope.of(context).unfocus();

  // ============================================================
  // CLEAR OLD VALIDATION ERRORS
  // ============================================================

  setState(() {
    usernameError = false;
    shopNameError = false;
    mobileError = false;
    secondaryMobileError = false;
    stateError = '';

    categoryError = false;
    shopTimingError = null;
   // locationError = false;
    privacyPolicyError = null;
  });

  bool hasError = false;

  // ============================================================
  // USERNAME - REQUIRED
  // ============================================================

 // NAME
 final String name =
      usernameController.text.trim();
  usernameError = name.isEmpty || name.length < 2;
  if (usernameError) {
    hasError = true;
  }

  // ============================================================
  // SHOP NAME - REQUIRED
  // ============================================================

  if (shopNameController.text.trim().isEmpty) {
    shopNameError = true;
    hasError = true;
  }

  // ============================================================
  // PRIMARY MOBILE - REQUIRED
  // ============================================================

  final String primaryMobile =
      mobileController.text.trim();

  if (primaryMobile.isEmpty ||
      primaryMobile.length != 10) {
    mobileError = true;
    hasError = true;
  }

  // ============================================================
  // OTP - REQUIRED
  // ============================================================

  if (!otpVerified) {
    hasError = true;
  }

  // ============================================================
  // SECONDARY MOBILE - REQUIRED
  // ============================================================
final String secondaryMobile =
    secondaryPhoneController.text.trim();

if (secondaryMobile.isEmpty ||
    secondaryMobile.length != 10) {
  secondaryMobileError = true;
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
  // CATEGORY - REQUIRED
  // ============================================================

  if (selectedCategories.isEmpty) {
    categoryError = true;
    hasError = true;
  }

// ============================================================
// SHOP TIMING - REQUIRED
// ============================================================

if (!isOpen24Hours &&
    (openingTime == null || closingTime == null)) {
  shopTimingError =
      'Please select opening and closing time, or choose Open 24 Hours.';
  hasError = true;
}

  // ============================================================
  // CURRENT LOCATION - REQUIRED
  // ============================================================

  // if (currentLocation == null) {
  //   locationError = true;
  //   hasError = true;
  // }
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
  // PRIVACY POLICY / TERMS - REQUIRED
  // ============================================================

  if (!privacyPolicyAccepted) {
    privacyPolicyError =
        'Please accept the Privacy Policy and Terms & Conditions.';
    hasError = true;
  }

  // ============================================================
  // UPDATE ALL VALIDATION ERRORS
  // ============================================================

  if (hasError) {
    setState(() {});

    showMessage(
      'Please complete all required fields.',
      error: true,
    );

    return;
  }

  // ============================================================
  // FIREBASE USER
  // ============================================================

  final User? user =
      FirebaseAuth.instance.currentUser;

  if (user == null) {
    showMessage(
      'User authentication failed.',
      error: true,
    );
    return;
  }

  // ============================================================
  // SUBMIT LOCK
  // ============================================================

  setState(() {
    isSubmitting = true;
  });

  try {
    // ==========================================================
    // SAVE BASIC DATA TO HIVE
    // ==========================================================

    await saveBasicTeaShopToHive();

    // ==========================================================
    // COMMON PROFILE
    // ==========================================================

    await CommonProfileService.saveLogin(
      uid: user.uid,
      name:
          shopNameController.text.trim(),
      mobile:
          mobileController.text.trim(),
      role: 'tea_shop',
    );

    // ==========================================================
    // OPTIONAL PROFILE PHOTO
    // ==========================================================

    if (profilePhoto != null) {
      final String? uploadedUrl =
          await uploadProfilePhoto(
        user.uid,
      );

      if (uploadedUrl != null &&
          uploadedUrl.isNotEmpty) {
        profilePhotoUrl = uploadedUrl;
      }
    }

    // ==========================================================
    // SAVE COMPLETE PROFILE TO FIRESTORE
    // ==========================================================

    await saveProfileToFirestore();
    await saveTeaShopCategoriesToFirestore();

    debugPrint(
      'TEA SHOP PROFILE SAVED SUCCESSFULLY',
    );

    // ==========================================================
    // FINISH
    // ==========================================================

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
  } catch (e) {
    debugPrint(
      'Submit profile error: $e',
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    showMessage(
      'Something went wrong. Please try again.',
      error: true,
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

      
      TextFormField(
  controller: secondaryPhoneController,

  keyboardType: TextInputType.phone,

  maxLength: 10,

  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
  ],

  onChanged: (value) {
    if (secondaryMobileError &&
        value.trim().length == 10) {
      setState(() {
        secondaryMobileError = false;
      });
    }
  },

  decoration: fieldDecoration(
    hintText: 'Enter secondary mobile number',
    icon: Icons.phone_android_outlined,
  ).copyWith(
    counterText: '',
    errorText: secondaryMobileError
        ? AppLocalizations.of(context)!.enteradigitmobilenumber
       // 'Enter a valid 10-digit secondary mobile number.'
        : null,
  ),
),

      const SizedBox(height: 5),

      const Text(
        'You can add same number,if another number is not available.',
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
                      'Add Tea Shop location',
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
  currentLocation = TeaShopLocation(
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
  currentLocation = TeaShopLocation(
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

//   Future<String?> uploadProfilePhoto(String uid) async {
//   if (profilePhoto == null) return profilePhotoUrl;

//   try {
//     final Reference storageRef = FirebaseStorage.instance
//         .ref()
//         .child('profilePhotos')
//         .child(uid)
//         .child('profile.jpg');

//     await storageRef.putFile(
//       profilePhoto!,
//       SettableMetadata(
//         contentType: 'image/jpeg',
//       ),
//     );

//     final String downloadUrl =
//         await storageRef.getDownloadURL();

//     return downloadUrl;
//   } catch (e) {
//     debugPrint('Profile photo upload error: $e');
//     return null;
//   }
// }
  Future<String?> uploadProfilePhoto(String uid) async {
  if (profilePhoto == null) return profilePhotoUrl;

  try {
    setState(() {
      isUploadingPhoto = true;
    });

    final ref = FirebaseStorage.instance
        .ref()
        .child('profilePhotos')
        .child(uid)
        .child('profile.jpg');

    await ref.putFile(profilePhoto!);

    final url = await ref.getDownloadURL();

    profilePhotoUrl = url;

    return url;
  } catch (e) {
    debugPrint('Profile photo upload error: $e');
    return null;
  } finally {
    if (mounted) {
      setState(() {
        isUploadingPhoto = false;
      });
    }
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // APP BAR
      // SAME STYLE AS STUDENT REGISTRATION
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
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
                text: 'Tea Shop ',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF08744F),
                ),
              ),

              TextSpan(
                text:  AppLocalizations.of(context)!.registration,
                //'Registration',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
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
                'Fill in your details to create your tea shop profile',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color: Color(0xFF777777),
                ),
              ),

              const SizedBox(height: 32),

              // =================================================
              // USERNAME
              // =================================================

              sectionTitle('Username'),

              const SizedBox(height: 9),
 TextField(
  controller: usernameController,
  textCapitalization: TextCapitalization.words,
  textInputAction: TextInputAction.next,
  onChanged: (_) {
    if (usernameError) {
      setState(() {
        usernameError = false;
      });
    }
  },
  decoration: fieldDecoration(
    hintText: 'Enter your name',
    icon: Icons.person_outline,
    hasError: usernameError,
  ),
),
if (usernameError)
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


              const SizedBox(height: 28),

              // =================================================
              // SHOP NAME
              // =================================================

              sectionTitle('Shop Name'),

              const SizedBox(height: 9),

              TextField(
                controller: shopNameController,

                textInputAction: TextInputAction.next,

                textCapitalization:
                    TextCapitalization.words,

                onChanged: (value) {
                  if (value.trim().isNotEmpty &&
                      shopNameError) {
                    setState(() {
                      shopNameError = false;
                    });
                  }
                },

                decoration: fieldDecoration(
                  hintText: 'Enter your shop name',
                  hasError: shopNameError,
                  icon: Icons.storefront_outlined,
                ),
              ),

              if (shopNameError)
                const Padding(
                  padding: EdgeInsets.only(
                    left: 8,
                    top: 5,
                  ),

                  child: Text(
                    'Please enter your shop name.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 28),

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
                    //  'Enter a valid 10-digit number',

                      style:
                          TextStyle(
                        color:
                            Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),

                otpSection(),


              const SizedBox(height: 28),
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
              // ================================================
              // CATEGORY
              // ================================================

              categorySection(),

              const SizedBox(height: 28),
               shopTimingSection(),
              const SizedBox(height: 20),
               descriptionSection(),
              const SizedBox(height: 20),

              _profilePhotoSection(),
              const SizedBox(height: 28),
           
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

              SizedBox(
                height: 58,

                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : submitProfile,

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF159B16),

                    foregroundColor: Colors.white,

                    disabledBackgroundColor:
                        Colors.grey.shade400,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30),
                    ),
                  ),

                  child: isSubmitting
                      ? const SizedBox(
                          width: 25,
                          height: 25,

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Profile',

                          style: TextStyle(
                            fontSize: 19,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
