// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:hive/hive.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'package:jober_india/jober_indiaScreens.dart/screen_home.dart';

// class ScreenBrokerLogin extends StatefulWidget {
//   const ScreenBrokerLogin({super.key});

//   @override
//   State<ScreenBrokerLogin> createState() => _ScreenBrokerLoginState();
// }

// class _ScreenBrokerLoginState extends State<ScreenBrokerLogin> {
//   // =============================================================
//   // FORM
//   // =============================================================

//   final GlobalKey<FormState> _formKey =
//       GlobalKey<FormState>();

//   // =============================================================
//   // CONTROLLERS
//   // =============================================================

//   final TextEditingController nameController =
//       TextEditingController();

//   final TextEditingController phoneController =
//       TextEditingController();

//   final TextEditingController categorySearchController =
//       TextEditingController();

//   // =============================================================
//   // FIREBASE
//   // =============================================================

//   final FirebaseAuth auth =
//       FirebaseAuth.instance;

//   final FirebaseFirestore firestore =
//       FirebaseFirestore.instance;

//   // =============================================================
//   // OTP
//   // =============================================================

//   String? verificationId;

//   bool otpSent = false;
//   bool otpVerified = false;

//   bool isSendingOtp = false;
//   bool isVerifying = false;
//   bool isSubmitting = false;

//   int secondsRemaining = 30;

//   Timer? timer;

//   final List<TextEditingController> otpBoxes =
//       List.generate(
//     6,
//     (_) => TextEditingController(),
//   );

//   final List<FocusNode> otpFocus =
//       List.generate(
//     6,
//     (_) => FocusNode(),
//   );

//   // =============================================================
//   // BROKER CATEGORIES
//   // =============================================================

//   final List<String> brokerCategories = const [
//     'Real Estate',
//     'Vehicles',
//     'Marriage',
//   ];

//   final Set<String> selectedCategories = {};

//   String categorySearchText = '';

//   bool _categoryDropdownOpen = false;

//   // =============================================================
//   // FILTERED CATEGORIES
//   // =============================================================

//   List<String> get filteredBrokerCategories {
//     final query =
//         categorySearchText.trim().toLowerCase();

//     if (query.isEmpty) {
//       return brokerCategories;
//     }

//     return brokerCategories.where(
//       (category) {
//         return category
//             .toLowerCase()
//             .contains(query);
//       },
//     ).toList();
//   }

//   // =============================================================
//   // INIT
//   // =============================================================

//   @override
//   void initState() {
//     super.initState();

//     categorySearchController.addListener(
//       () {
//         if (!mounted) return;

//         setState(() {
//           categorySearchText =
//               categorySearchController.text.trim();
//         });
//       },
//     );
//   }

//   // =============================================================
//   // MESSAGE
//   // =============================================================

//   void _showMessage(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior: SnackBarBehavior.floating,
//         backgroundColor:
//             const Color(0xFF176B32),
//         shape: RoundedRectangleBorder(
//           borderRadius:
//               BorderRadius.circular(12),
//         ),
//       ),
//     );
//   }

//   // =============================================================
//   // DISPOSE
//   // =============================================================

//   @override
//   void dispose() {
//     timer?.cancel();

//     nameController.dispose();
//     phoneController.dispose();
//     categorySearchController.dispose();

//     for (final controller in otpBoxes) {
//       controller.dispose();
//     }

//     for (final node in otpFocus) {
//       node.dispose();
//     }

//     super.dispose();
//   }

//   // =============================================================
//   // SEND OTP
//   // =============================================================

//   Future<void> sendOTP() async {
//     if (isSendingOtp) return;

//     final phone =
//         phoneController.text.trim();

//     if (phone.length != 10) {
//       _showMessage(
//         'Enter a valid 10-digit mobile number.',
//       );
//       return;
//     }

//     if (otpSent &&
//         secondsRemaining > 0) {
//       _showMessage(
//         'Please wait before requesting another OTP.',
//       );
//       return;
//     }

//     FocusScope.of(context).unfocus();

//     setState(() {
//       isSendingOtp = true;
//       otpVerified = false;
//     });

//     try {
//       await auth.verifyPhoneNumber(
//         phoneNumber: '+91$phone',

//         timeout:
//             const Duration(seconds: 30),

//         // =======================================================
//         // AUTOMATIC VERIFICATION
//         // =======================================================

//         verificationCompleted:
//             (PhoneAuthCredential credential) async {
//           try {
//             await auth.signInWithCredential(
//               credential,
//             );

//             if (!mounted) return;

//             timer?.cancel();
//             clearOtp();

//             setState(() {
//               otpVerified = true;
//               otpSent = false;
//               isSendingOtp = false;
//               isVerifying = false;
//             });

//             _showMessage(
//               'Mobile number verified successfully.',
//             );
//           } on FirebaseAuthException catch (e) {
//             if (!mounted) return;

//             setState(() {
//               isSendingOtp = false;
//             });

//             _showMessage(
//               e.message ??
//                   'Automatic verification failed.',
//             );
//           }
//         },

//         // =======================================================
//         // VERIFICATION FAILED
//         // =======================================================

//         verificationFailed:
//             (FirebaseAuthException e) {
//           if (!mounted) return;

//           setState(() {
//             isSendingOtp = false;
//             otpSent = false;
//           });

//           String message;

//           switch (e.code) {
//             case 'invalid-phone-number':
//               message =
//                   'The mobile number is invalid.';
//               break;

//             case 'too-many-requests':
//               message =
//                   'Too many requests. Please try again later.';
//               break;

//             case 'quota-exceeded':
//               message =
//                   'OTP limit reached. Please try again later.';
//               break;

//             case 'network-request-failed':
//               message =
//                   'Network error. Check your internet connection.';
//               break;

//             case 'app-not-authorized':
//               message =
//                   'This app is not authorized for Firebase Phone Authentication.';
//               break;

//             default:
//               message =
//                   e.message ??
//                       'Could not send OTP.';
//           }

//           _showMessage(message);
//         },

//         // =======================================================
//         // OTP SENT
//         // =======================================================

//         codeSent:
//             (String id, int? resendToken) {
//           if (!mounted) return;

//           verificationId = id;

//           clearOtp();

//           setState(() {
//             otpSent = true;
//             otpVerified = false;
//             isSendingOtp = false;
//             secondsRemaining = 30;
//           });

//           startOtpTimer();

//           _showMessage(
//             'OTP sent successfully.',
//           );
//         },

//         // =======================================================
//         // AUTO RETRIEVAL TIMEOUT
//         // =======================================================

//         codeAutoRetrievalTimeout:
//             (String id) {
//           verificationId = id;
//         },
//       );
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isSendingOtp = false;
//       });

//       debugPrint(
//         'sendOTP error: $e',
//       );

//       _showMessage(
//         'Unable to send OTP. Please try again.',
//       );
//     }
//   }

//   // =============================================================
//   // OTP TIMER
//   // =============================================================

//   void startOtpTimer() {
//     timer?.cancel();

//     if (!mounted) return;

//     setState(() {
//       secondsRemaining = 30;
//     });

//     timer = Timer.periodic(
//       const Duration(seconds: 1),
//       (Timer timer) {
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
//         }
//       },
//     );
//   }

//   // =============================================================
//   // OTP CHANGED
//   // =============================================================

//   void onOtpChanged(
//     String value,
//     int index,
//   ) {
//     if (value.isNotEmpty &&
//         index < 5) {
//       otpFocus[index + 1].requestFocus();
//     }

//     if (value.isEmpty &&
//         index > 0) {
//       otpFocus[index - 1].requestFocus();
//     }

//     final otp = otpBoxes
//         .map(
//           (controller) =>
//               controller.text,
//         )
//         .join();

//     if (otp.length == 6 &&
//         !isVerifying &&
//         !otpVerified) {
//       verifyOTP();
//     }
//   }

//   // =============================================================
//   // VERIFY OTP
//   // =============================================================

//   Future<void> verifyOTP() async {
//     if (isVerifying) return;

//     final otp = otpBoxes
//         .map(
//           (controller) =>
//               controller.text,
//         )
//         .join();

//     if (verificationId == null ||
//         verificationId!.isEmpty) {
//       _showMessage(
//         'Please send OTP first.',
//       );
//       return;
//     }

//     if (otp.length != 6) {
//       _showMessage(
//         'Enter the complete 6-digit OTP.',
//       );
//       return;
//     }

//     FocusScope.of(context).unfocus();

//     setState(() {
//       isVerifying = true;
//     });

//     try {
//       final credential =
//           PhoneAuthProvider.credential(
//         verificationId:
//             verificationId!,
//         smsCode: otp,
//       );

//       await auth.signInWithCredential(
//         credential,
//       );

//       if (!mounted) return;

//       timer?.cancel();
//       clearOtp();

//       setState(() {
//         isVerifying = false;
//         otpVerified = true;
//         otpSent = false;
//       });

//       _showMessage(
//         'Mobile number verified successfully.',
//       );
//     } on FirebaseAuthException catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isVerifying = false;
//       });

//       String message;

//       switch (e.code) {
//         case 'invalid-verification-code':
//           message =
//               'Incorrect OTP. Please check and try again.';
//           break;

//         case 'session-expired':
//           message =
//               'OTP expired. Please request a new OTP.';
//           break;

//         case 'invalid-verification-id':
//           message =
//               'Verification session expired. Please send OTP again.';
//           break;

//         case 'credential-already-in-use':
//           message =
//               'This mobile number is already registered.';
//           break;

//         case 'network-request-failed':
//           message =
//               'Network error. Check your internet connection.';
//           break;

//         default:
//           message =
//               e.message ??
//                   'OTP verification failed.';
//       }

//       _showMessage(message);
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isVerifying = false;
//       });

//       debugPrint(
//         'verifyOTP error: $e',
//       );

//       _showMessage(
//         'OTP verification failed. Please try again.',
//       );
//     }
//   }

//   // =============================================================
//   // CLEAR OTP
//   // =============================================================

//   void clearOtp() {
//     for (final controller in otpBoxes) {
//       controller.clear();
//     }
//   }

//   // =============================================================
//   // CHANGE MOBILE NUMBER
//   // =============================================================

//   void changeMobileNumber() {
//     timer?.cancel();

//     clearOtp();

//     verificationId = null;

//     if (!mounted) return;

//     setState(() {
//       otpSent = false;
//       otpVerified = false;
//       isSendingOtp = false;
//       isVerifying = false;
//       secondsRemaining = 30;
//     });
//   }

//   // =============================================================
//   // RESEND OTP
//   // =============================================================

//   Future<void> resendOTP() async {
//     if (secondsRemaining > 0) {
//       _showMessage(
//         'Please wait ${secondsRemaining}s before requesting another OTP.',
//       );
//       return;
//     }

//     await sendOTP();
//   }
//   // =============================================================
//   // OTP SECTION
//   // =============================================================

//   Widget otpSection() {
//     if (!otpSent) {
//       return const SizedBox.shrink();
//     }

//     return Container(
//       margin: const EdgeInsets.only(
//         top: 18,
//         bottom: 30,
//       ),
//       padding: const EdgeInsets.fromLTRB(
//         14,
//         22,
//         14,
//         18,
//       ),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF2F8F2),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: const Color(0xFF91AF96),
//           width: 1.3,
//         ),
//       ),
//       child: Column(
//         children: [
//           // =====================================================
//           // OTP TITLE
//           // =====================================================

//           Row(
//             children: [
//               Container(
//                 width: 42,
//                 height: 42,
//                 decoration: const BoxDecoration(
//                   color: Color(0xFF198B35),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.verified_user,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//               ),

//               const SizedBox(width: 12),

//               const Text(
//                 'Enter OTP',
//                 style: TextStyle(
//                   color: Color(0xFF12652F),
//                   fontWeight: FontWeight.bold,
//                   fontSize: 15,
//                 ),
//               ),

//               const Spacer(),

//               if (isVerifying)
//                 const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                   ),
//                 ),
//             ],
//           ),

//           const SizedBox(height: 18),

//           // =====================================================
//           // SIX OTP BOXES
//           // =====================================================

//           Row(
//             mainAxisAlignment:
//                 MainAxisAlignment.spaceBetween,
//             children: List.generate(
//               6,
//               (index) {
//                 return SizedBox(
//                   width: 45,
//                   height: 58,
//                   child: TextField(
//                     controller: otpBoxes[index],
//                     focusNode: otpFocus[index],
//                     keyboardType:
//                         TextInputType.number,
//                     textAlign: TextAlign.center,
//                     maxLength: 1,
//                     enabled: !isVerifying,
//                     style: const TextStyle(
//                       fontSize: 22,
//                       color: Colors.black,
//                     ),
//                     inputFormatters: [
//                       FilteringTextInputFormatter
//                           .digitsOnly,
//                     ],
//                     decoration: InputDecoration(
//                       counterText: '',
//                       filled: true,
//                       fillColor: Colors.white,
//                       contentPadding:
//                           EdgeInsets.zero,
//                       border: OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius.circular(7),
//                       ),
//                       enabledBorder:
//                           OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius.circular(7),
//                         borderSide:
//                             const BorderSide(
//                           color: Color(0xFFE0E0E0),
//                         ),
//                       ),
//                       focusedBorder:
//                           OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius.circular(7),
//                         borderSide:
//                             const BorderSide(
//                           width: 2,
//                           color: Color(0xFF198B35),
//                         ),
//                       ),
//                     ),
//                     onChanged: (value) {
//                       onOtpChanged(
//                         value,
//                         index,
//                       );
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),

//           const SizedBox(height: 18),

//           // =====================================================
//           // TIMER
//           // =====================================================

//           Row(
//             mainAxisAlignment:
//                 MainAxisAlignment.center,
//             children: [
//               const Text(
//                 'OTP expires in ',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               Text(
//                 '${secondsRemaining}s',
//                 style: const TextStyle(
//                   color: Color(0xFFEE841B),
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 12),

//           // =====================================================
//           // RESEND / CHANGE NUMBER
//           // =====================================================

//           Row(
//             mainAxisAlignment:
//                 MainAxisAlignment.center,
//             children: [
//               if (secondsRemaining == 0)
//                 TextButton(
//                   onPressed:
//                       isSendingOtp
//                           ? null
//                           : resendOTP,
//                   child: const Text(
//                     'Resend OTP',
//                     style: TextStyle(
//                       color: Color(0xFF12652F),
//                       fontWeight:
//                           FontWeight.bold,
//                     ),
//                   ),
//                 ),

//               TextButton(
//                 onPressed:
//                     isVerifying
//                         ? null
//                         : changeMobileNumber,
//                 child: const Text(
//                   'Change Number',
//                   style: TextStyle(
//                     color: Color(0xFF12652F),
//                     fontWeight:
//                         FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // =============================================================
//   // INPUT DECORATION
//   // =============================================================

//   InputDecoration fieldDecoration({
//     required String label,
//     required IconData icon,
//     String? hint,
//     Widget? suffix,
//   }) {
//     return InputDecoration(
//       labelText: label,
//       hintText: hint,

//       floatingLabelBehavior:
//           FloatingLabelBehavior.always,

//       prefixIcon: Icon(
//         icon,
//         color: const Color(0xFF16803A),
//         size: 27,
//       ),

//       suffixIcon: suffix,

//       filled: true,
//       fillColor: Colors.white,

//       contentPadding:
//           const EdgeInsets.symmetric(
//         horizontal: 18,
//         vertical: 20,
//       ),

//       labelStyle: const TextStyle(
//         color: Color(0xFF12652F),
//         fontSize: 15,
//         fontWeight: FontWeight.bold,
//       ),

//       hintStyle: const TextStyle(
//         color: Color(0xFF777777),
//         fontSize: 17,
//       ),

//       enabledBorder:
//           OutlineInputBorder(
//         borderRadius:
//             BorderRadius.circular(14),
//         borderSide:
//             const BorderSide(
//           color: Color(0xFF3A8050),
//           width: 1.5,
//         ),
//       ),

//       focusedBorder:
//           OutlineInputBorder(
//         borderRadius:
//             BorderRadius.circular(14),
//         borderSide:
//             const BorderSide(
//           color: Color(0xFF198B35),
//           width: 2,
//         ),
//       ),

//       errorBorder:
//           OutlineInputBorder(
//         borderRadius:
//             BorderRadius.circular(14),
//         borderSide:
//             const BorderSide(
//           color: Colors.red,
//           width: 1.5,
//         ),
//       ),

//       focusedErrorBorder:
//           OutlineInputBorder(
//         borderRadius:
//             BorderRadius.circular(14),
//         borderSide:
//             const BorderSide(
//           color: Colors.red,
//           width: 2,
//         ),
//       ),
//     );
//   }

//   // =============================================================
//   // TOGGLE BROKER CATEGORY
//   // =============================================================

//   void toggleCategory(String category) {
//     if (!mounted) return;

//     setState(() {
//       if (selectedCategories.contains(category)) {
//         selectedCategories.remove(category);
//       } else {
//         selectedCategories.add(category);
//       }
//     });
//   }

//   // =============================================================
//   // ADD CUSTOM CATEGORY
//   // =============================================================

//   Future<void> showAddCategoryDialog() async {
//     final controller =
//         TextEditingController();

//     final String? category =
//         await showDialog<String>(
//       context: context,
//       barrierDismissible: true,
//       builder: (dialogContext) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(18),
//           ),

//           title: const Text(
//             'Add Your Own Category',
//             style: TextStyle(
//               color: Color(0xFF12652F),
//               fontWeight: FontWeight.bold,
//             ),
//           ),

//           content: TextField(
//             controller: controller,
//             textCapitalization:
//                 TextCapitalization.words,
//             decoration: InputDecoration(
//               labelText: 'Category name',
//               hintText:
//                   'Enter your category',
//               prefixIcon: const Icon(
//                 Icons.add_business_outlined,
//                 color: Color(0xFF198B35),
//               ),
//               enabledBorder:
//                   OutlineInputBorder(
//                 borderRadius:
//                     BorderRadius.circular(12),
//                 borderSide:
//                     const BorderSide(
//                   color: Color(0xFF3A8050),
//                 ),
//               ),
//               focusedBorder:
//                   OutlineInputBorder(
//                 borderRadius:
//                     BorderRadius.circular(12),
//                 borderSide:
//                     const BorderSide(
//                   color: Color(0xFF198B35),
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
//               onPressed: () {
//                 final value =
//                     controller.text.trim();

//                 if (value.isEmpty) {
//                   return;
//                 }

//                 Navigator.pop(
//                   dialogContext,
//                   value,
//                 );
//               },
//               style:
//                   ElevatedButton.styleFrom(
//                 backgroundColor:
//                     const Color(0xFF198B35),
//                 foregroundColor:
//                     Colors.white,
//               ),
//               child: const Text(
//                 'Add',
//               ),
//             ),
//           ],
//         );
//       },
//     );

//     controller.dispose();

//     if (!mounted) return;

//     if (category == null ||
//         category.trim().isEmpty) {
//       return;
//     }

//     final newCategory =
//         category.trim();

//     final alreadyExists =
//         selectedCategories.any(
//       (item) =>
//           item.trim().toLowerCase() ==
//           newCategory.toLowerCase(),
//     );

//     if (alreadyExists) {
//       _showMessage(
//         'This category is already selected.',
//       );
//       return;
//     }

//     setState(() {
//       selectedCategories.add(
//         newCategory,
//       );
//     });
//   }

//   // =============================================================
//   // BROKER CATEGORY SECTION
//   // =============================================================

//   Widget categorySection() {
//     final categories =
//         filteredBrokerCategories;

//     final isOpen =
//         _categoryDropdownOpen;

//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         // =======================================================
//         // TITLE
//         // =======================================================

//         const Text(
//           'Broker Categories *',
//           style: TextStyle(
//             color: Color(0xFF12652F),
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),

//         const SizedBox(height: 10),

//         // =======================================================
//         // SELECT BOX
//         // =======================================================

//         GestureDetector(
//           onTap: () {
//             setState(() {
//               _categoryDropdownOpen =
//                   !_categoryDropdownOpen;
//             });
//           },

//           child: Container(
//             width: double.infinity,

//             constraints:
//                 const BoxConstraints(
//               minHeight: 62,
//             ),

//             padding:
//                 const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 15,
//             ),

//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius:
//                   BorderRadius.circular(14),
//               border: Border.all(
//                 color:
//                     const Color(0xFF3A8050),
//                 width: 1.5,
//               ),
//             ),

//             child: Row(
//               children: [
//                 const Icon(
//                   Icons.handshake_outlined,
//                   color: Color(0xFF198B35),
//                   size: 28,
//                 ),

//                 const SizedBox(width: 12),

//                 Expanded(
//                   child:
//                       selectedCategories.isEmpty
//                           ? const Text(
//                               'Select your Broker categories',
//                               style: TextStyle(
//                                 color:
//                                     Color(0xFF777777),
//                                 fontSize: 16,
//                               ),
//                             )
//                           : Text(
//                               selectedCategories
//                                   .join(', '),
//                               maxLines: 2,
//                               overflow:
//                                   TextOverflow
//                                       .ellipsis,
//                               style:
//                                   const TextStyle(
//                                 color:
//                                     Color(0xFF12652F),
//                                 fontSize: 16,
//                                 fontWeight:
//                                     FontWeight.w600,
//                               ),
//                             ),
//                 ),

//                 Icon(
//                   isOpen
//                       ? Icons
//                           .keyboard_arrow_up
//                       : Icons
//                           .keyboard_arrow_down,
//                   color:
//                       const Color(0xFF12652F),
//                   size: 30,
//                 ),
//               ],
//             ),
//           ),
//         ),

//         // =======================================================
//         // DROPDOWN
//         // =======================================================

//         if (isOpen) ...[
//           const SizedBox(height: 6),

//           Container(
//             width: double.infinity,
//             height: 430,

//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius:
//                   BorderRadius.circular(14),
//               border: Border.all(
//                 color:
//                     const Color(0xFF3A8050),
//                 width: 1.5,
//               ),
//             ),

//             child: Column(
//               children: [
//                 // =================================================
//                 // SEARCH
//                 // =================================================

//                 Padding(
//                   padding:
//                       const EdgeInsets.all(12),

//                   child: TextField(
//                     controller:
//                         categorySearchController,

//                     textInputAction:
//                         TextInputAction.search,

//                     decoration:
//                         InputDecoration(
//                       hintText:
//                           'Search broker category...',

//                       prefixIcon:
//                           const Icon(
//                         Icons.search,
//                         color:
//                             Color(0xFF198B35),
//                       ),

//                       suffixIcon:
//                           categorySearchText
//                                   .isNotEmpty
//                               ? IconButton(
//                                   onPressed: () {
//                                     categorySearchController
//                                         .clear();
//                                   },
//                                   icon:
//                                       const Icon(
//                                     Icons.clear,
//                                   ),
//                                 )
//                               : null,

//                       filled: true,

//                       fillColor:
//                           const Color(0xFFF4F8F4),

//                       border:
//                           OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius.circular(
//                           12,
//                         ),
//                         borderSide:
//                             BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),

//                 const Divider(height: 1),

//                 // =================================================
//                 // ADD YOUR OWN
//                 // =================================================

//                 Material(
//                   color: Colors.white,

//                   child: InkWell(
//                     onTap:
//                         showAddCategoryDialog,

//                     child: const Padding(
//                       padding:
//                           EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 13,
//                       ),

//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons
//                                 .add_circle_outline,
//                             color:
//                                 Color(0xFF198B35),
//                             size: 27,
//                           ),

//                           SizedBox(width: 14),

//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment:
//                                   CrossAxisAlignment
//                                       .start,
//                               children: [
//                                 Text(
//                                   'Add your own Category',
//                                   style:
//                                       TextStyle(
//                                     color:
//                                         Color(
//                                       0xFF12652F,
//                                     ),
//                                     fontSize: 16,
//                                     fontWeight:
//                                         FontWeight
//                                             .bold,
//                                   ),
//                                 ),

//                                 SizedBox(height: 2),

//                                 Text(
//                                   'Add a broker category not listed above',
//                                   style:
//                                       TextStyle(
//                                     fontSize: 12,
//                                     color:
//                                         Colors.grey,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),

//                           Icon(
//                             Icons
//                                 .arrow_forward_ios,
//                             size: 16,
//                             color:
//                                 Color(0xFF198B35),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),

//                 const Divider(height: 1),

//                 // =================================================
//                 // CATEGORY LIST
//                 // =================================================

//                 Expanded(
//                   child:
//                       categories.isEmpty
//                           ? const Center(
//                               child: Text(
//                                 'No broker category found',
//                                 style: TextStyle(
//                                   color:
//                                       Colors.grey,
//                                 ),
//                               ),
//                             )
//                           : ListView.builder(
//                               padding:
//                                   const EdgeInsets
//                                       .symmetric(
//                                 vertical: 6,
//                               ),

//                               itemCount:
//                                   categories.length,

//                               itemBuilder:
//                                   (
//                                 context,
//                                 index,
//                               ) {
//                                 final category =
//                                     categories[index];

//                                 final selected =
//                                     selectedCategories
//                                         .contains(
//                                   category,
//                                 );

//                                 return CheckboxListTile(
//                                   dense: true,

//                                   value: selected,

//                                   activeColor:
//                                       const Color(
//                                     0xFF198B35,
//                                   ),

//                                   title: Text(
//                                     category,
//                                     style:
//                                         TextStyle(
//                                       color: selected
//                                           ? const Color(
//                                               0xFF12652F,
//                                             )
//                                           : Colors
//                                               .black87,
//                                       fontWeight: selected
//                                           ? FontWeight
//                                               .bold
//                                           : FontWeight
//                                               .normal,
//                                     ),
//                                   ),

//                                   onChanged:
//                                       (_) {
//                                     toggleCategory(
//                                       category,
//                                     );
//                                   },
//                                 );
//                               },
//                             ),
//                 ),
//               ],
//             ),
//           ),
//         ],

//         // =======================================================
//         // SELECTED COUNT
//         // =======================================================

//         if (selectedCategories.isNotEmpty)
//           Padding(
//             padding:
//                 const EdgeInsets.only(
//               top: 8,
//             ),

//             child: Text(
//               '${selectedCategories.length} '
//               'categor${selectedCategories.length == 1 ? 'y' : 'ies'} selected',

//               style: const TextStyle(
//                 color: Color(0xFF12652F),
//                 fontWeight:
//                     FontWeight.w600,
//               ),
//             ),
//           ),
//       ],
//     );
//   }
//   // =============================================================
//   // SAVE BROKER PROFILE TO HIVE
//   // =============================================================

//  Future<void> saveProfileToHive({
//   required String uid,
//   required String phone,
// }) async {
//   // ============================================================
//   // BROKER PROFILE BOX
//   // ============================================================

//   final box = Hive.box(
//     'brokerProfiles',
//   );

//   final profile = <String, dynamic>{
//     'uid': uid,

//     'name':
//         nameController.text.trim(),

//     'phone':
//         phone,

//     'categories':
//         selectedCategories.toList(),

//     'profileCompleted':
//         true,

//     'savedAt':
//         DateTime.now().toIso8601String(),
//   };

//   await box.put(
//     'currentUid',
//     uid,
//   );

//   await box.put(
//     uid,
//     profile,
//   );

//   // ============================================================
//   // COMMON LOGGED-IN USER BOX
//   // ============================================================

//   final userBox = Hive.box(
//     'userBox',
//   );

//   await userBox.put(
//     'uid',
//     uid,
//   );

//   await userBox.put(
//     'name',
//     nameController.text.trim(),
//   );

//   await userBox.put(
//     'mobile',
//     phone,
//   );

//   await userBox.put(
//     'role',
//     'broker',
//   );

//   await userBox.put(
//     'categories',
//     selectedCategories.toList(),
//   );

//   debugPrint(
//     'Broker profile saved successfully.',
//   );
// }
//   // =============================================================
//   // SAVE BROKER PROFILE TO FIRESTORE
//   // =============================================================

//   Future<void> saveProfileToFirestore({
//     required String uid,
//     required String phone,
//   }) async {
//     final brokerReference =
//         firestore
//             .collection('brokers')
//             .doc(uid);

//     await brokerReference.set(
//       {
//         'uid': uid,

//         'name':
//             nameController.text.trim(),

//         'phone':
//             phone,

//         'categories':
//             selectedCategories.toList(),

//         'profileCompleted':
//             true,

//         'isLive':
//             false,

//         'updatedAt':
//             FieldValue.serverTimestamp(),

//         'createdAt':
//             FieldValue.serverTimestamp(),
//       },
//       SetOptions(
//         merge: true,
//       ),
//     );
//   }

//   Future<void> submitProfile() async {
// if (isSubmitting) return;

// // ===========================================================
// // VALIDATE FORM
// // ===========================================================

// if (!_formKey.currentState!.validate()) {
// return;
// }

// // ===========================================================
// // CATEGORY VALIDATION
// // ===========================================================

// if (selectedCategories.isEmpty) {
// _showMessage(
// 'Please select at least one broker category.',
// );
// return;
// }

// // ===========================================================
// // OTP VALIDATION
// // ===========================================================

// if (!otpVerified) {
// _showMessage(
// 'Please verify your mobile number with OTP.',
// );
// return;
// }

// // ===========================================================
// // FIREBASE USER
// // ===========================================================

// final user = auth.currentUser;

// if (user == null) {
// _showMessage(
// 'Authentication session not found. Please verify your mobile number again.',
// );
// return;
// }

// final phone = phoneController.text.trim();

// if (!mounted) return;

// setState(() {
// isSubmitting = true;
// });

// try {
// // =========================================================
// // 1. SAVE LOCALLY FIRST
// // =========================================================

// await saveProfileToHive(
//   uid: user.uid,
//   phone: phone,
// );

// // =========================================================
// // 2. SAVE LOGIN STATE
// // =========================================================

// final prefs =
//     await SharedPreferences.getInstance();

// await prefs.setBool(
//   'isLoggedIn',
//   true,
// );

// await prefs.setString(
//   'userRole',
//   'broker',
// );

// // =========================================================
// // 3. WAIT 2 SECONDS
// // Smooth loading transition
// // =========================================================

// await Future.delayed(
//   const Duration(seconds: 2),
// );

// if (!mounted) return;

// // =========================================================
// // 4. STOP LOADING
// // =========================================================

// setState(() {
//   isSubmitting = false;
// });

// if (!mounted) return;

// // =========================================================
// // 5. GO TO HOME IMMEDIATELY
// // =========================================================

// Navigator.pushAndRemoveUntil(
//   context,
//   MaterialPageRoute(
//     builder: (_) => const ScreenHome(),
//   ),
//   (route) => false,
// );

// // =========================================================
// // 6. SAVE TO FIRESTORE IN BACKGROUND
// // User does NOT need to wait
// // =========================================================

// saveProfileToFirestore(
//   uid: user.uid,
//   phone: phone,
// )
//     .then((_) {
//       debugPrint(
//         'Broker Firestore sync successful.',
//       );
//     })
//     .catchError((error) {
//       debugPrint(
//         'Broker Firestore sync failed: $error',
//       );
//     });

// } on HiveError catch (e) {
// if (!mounted) return;

// setState(() {
//   isSubmitting = false;
// });

// debugPrint(
//   'Broker Hive error: $e',
// );

// _showMessage(
//   'Could not save the profile locally.',
// );

// } catch (e) {
// if (!mounted) return;

// setState(() {
//   isSubmitting = false;
// });

// debugPrint(
//   'Broker submit error: $e',
// );

// _showMessage(
//   'Something went wrong. Please try again.',
// );

// }
// }
  
//   // =============================================================
//   // BUILD
//   // =============================================================

//   @override
//   Widget build(
//     BuildContext context,
//   ) {
//     return Scaffold(
//       backgroundColor:
//           const Color(0xFFF8F5EE),

//       body: SafeArea(
//         child: Container(
//           width: double.infinity,
//           height: double.infinity,

//           // IMPORTANT:
//           // Transparent so the forest image can
//           // cover the complete page.
//           color: Colors.transparent,

//           child: Stack(
//             fit: StackFit.expand,
//             children: [

//               // =================================================
//               // FULL PAGE FOREST BACKGROUND
//               // =================================================

//               Positioned.fill(
//                 child: IgnorePointer(
//                   child: Image.asset(
//                     'assets/images/WhatsApp Image 2026-09-05 at 11.44.48 AM.jpeg',

//                     // This makes the image cover
//                     // the COMPLETE screen.
//                     fit: BoxFit.cover,

//                     alignment:
//                         Alignment.center,
//                   ),
//                 ),
//               ),

//               // =================================================
//               // SLIGHT WHITE TRANSPARENT OVERLAY
//               // =================================================
//               //
//               // This keeps the forest visible while making
//               // the registration fields easier to read.
//               //
//               // You can remove this Container if you want
//               // the original image to be stronger.
//               // =================================================

//               Positioned.fill(
//                 child: IgnorePointer(
//                   child: Container(
//                     color:
//                         Colors.white.withValues(
//                       alpha: 0.18,
//                     ),
//                   ),
//                 ),
//               ),

//               // =================================================
//               // FORM
//               // =================================================

//               Form(
//                 key: _formKey,

//                 child:
//                     SingleChildScrollView(
//                   padding:
//                       const EdgeInsets.fromLTRB(
//                     24,
//                     35,
//                     24,
//                     45,
//                   ),

//                   child: Column(
//                     crossAxisAlignment:
//                         CrossAxisAlignment.start,

//                     children: [

//                       // =========================================
//                       // BACK BUTTON
//                       // =========================================

//                       GestureDetector(
//                         onTap: () {
//                           Navigator.pop(
//                             context,
//                           );
//                         },

//                         child:
//                             const Icon(
//                           Icons.arrow_back,
//                           size: 30,
//                           color: Colors.black,
//                         ),
//                       ),

//                       const SizedBox(
//                         height: 20,
//                       ),

//                       // =========================================
//                       // TITLE
//                       // =========================================

//                       RichText(
//                         text:
//                             const TextSpan(
//                           style:
//                               TextStyle(
//                             fontSize: 25,
//                             fontWeight:
//                                 FontWeight.w800,
//                           ),

//                           children: [

//                             TextSpan(
//                               text:
//                                   'Broker ',
//                               style:
//                                   TextStyle(
//                                 color:
//                                     Color(
//                                   0xFF064C38,
//                                 ),
//                               ),
//                             ),

//                             TextSpan(
//                               text:
//                                   'Registration',
//                               style:
//                                   TextStyle(
//                                 color:
//                                     Color(
//                                   0xFFED801D,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                       const SizedBox(
//                         height: 11,
//                       ),

//                       const Text(
//                         'Fill in your details to create your broker profile',
//                         style: TextStyle(
//                           color:
//                               Color(0xFF777777),
//                           fontSize: 15,
//                         ),
//                       ),

//                       // =========================================
//                       // BROKER NAME
//                       // =========================================

//                       const SizedBox(
//                         height: 40,
//                       ),

//                       TextFormField(
//                         controller:
//                             nameController,

//                         textCapitalization:
//                             TextCapitalization.words,

//                         decoration:
//                             fieldDecoration(
//                           label:
//                               'Broker Name',

//                           icon:
//                               Icons.person,

//                           hint:
//                               'Enter broker name',
//                         ),

//                         validator:
//                             (value) {
//                           if (value ==
//                                   null ||
//                               value
//                                   .trim()
//                                   .isEmpty) {
//                             return
//                                 'Please enter broker name';
//                           }

//                           return null;
//                         },
//                       ),

//                       // =========================================
//                       // MOBILE NUMBER
//                       // =========================================

//                       const SizedBox(
//                         height: 30,
//                       ),

//                       TextFormField(
//                         controller:
//                             phoneController,

//                         keyboardType:
//                             TextInputType.phone,

//                         maxLength: 10,

//                         enabled:
//                             !otpVerified,

//                         inputFormatters: [
//                           FilteringTextInputFormatter
//                               .digitsOnly,
//                         ],

//                         decoration:
//                             fieldDecoration(
//                           label:
//                               'Mobile Number',

//                           icon:
//                               Icons.phone,

//                           hint:
//                               'Enter mobile number',

//                           suffix:
//                               otpVerified
//                                   ? TextButton(
//                                       onPressed:
//                                           changeMobileNumber,

//                                       child:
//                                           const Text(
//                                         'Change',
//                                         style:
//                                             TextStyle(
//                                           color:
//                                               Color(
//                                             0xFF12652F,
//                                           ),
//                                           fontWeight:
//                                               FontWeight
//                                                   .bold,
//                                         ),
//                                       ),
//                                     )
//                                   : TextButton(
//                                       onPressed:
//                                           isSendingOtp
//                                               ? null
//                                               : sendOTP,

//                                       child:
//                                           isSendingOtp
//                                               ? const SizedBox(
//                                                   width:
//                                                       18,
//                                                   height:
//                                                       18,
//                                                   child:
//                                                       CircularProgressIndicator(
//                                                     strokeWidth:
//                                                         2,
//                                                   ),
//                                                 )
//                                               : const Text(
//                                                   'Send OTP',
//                                                   style:
//                                                       TextStyle(
//                                                     color:
//                                                         Color(
//                                                       0xFF12652F,
//                                                     ),
//                                                     fontWeight:
//                                                         FontWeight
//                                                             .bold,
//                                                   ),
//                                                 ),
//                                     ),
//                         ),

//                         validator:
//                             (value) {
//                           if (value ==
//                                   null ||
//                               value
//                                   .trim()
//                                   .isEmpty) {
//                             return
//                                 'Please enter mobile number';
//                           }

//                           if (value
//                                   .trim()
//                                   .length !=
//                               10) {
//                             return
//                                 'Enter a valid 10-digit number';
//                           }

//                           return null;
//                         },
//                       ),

//                       // =========================================
//                       // OTP
//                       // =========================================

//                       otpSection(),

//                       // =========================================
//                       // BROKER CATEGORIES
//                       // =========================================

//                       const SizedBox(
//                         height: 20,
//                       ),

//                       categorySection(),

//                       // =========================================
//                       // SUBMIT BUTTON
//                       // =========================================

//                       const SizedBox(
//                         height: 30,
//                       ),

//                       SizedBox(
//                         width:
//                             double.infinity,

//                         height: 58,

//                         child:
//                             ElevatedButton(
//                           onPressed:
//                               isSubmitting
//                                   ? null
//                                   : submitProfile,

//                           style:
//                               ElevatedButton
//                                   .styleFrom(
//                             backgroundColor:
//                                 const Color(
//                               0xFF198B1E,
//                             ),

//                             disabledBackgroundColor:
//                                 const Color(
//                               0xFF9AB89F,
//                             ),

//                             foregroundColor:
//                                 Colors.white,

//                             elevation: 4,

//                             shadowColor:
//                                 Colors.black
//                                     .withValues(
//                               alpha: 0.30,
//                             ),

//                             shape:
//                                 RoundedRectangleBorder(
//                               borderRadius:
//                                   BorderRadius
//                                       .circular(
//                                 32,
//                               ),
//                             ),
//                           ),

//                           child:
//                               isSubmitting
//                                   ? const SizedBox(
//                                       width: 25,
//                                       height: 25,

//                                       child:
//                                           CircularProgressIndicator(
//                                         color:
//                                             Colors.white,
//                                         strokeWidth:
//                                             2.5,
//                                       ),
//                                     )
//                                   : const Text(
//                                       'Submit Profile',

//                                       style:
//                                           TextStyle(
//                                         fontSize: 18,
//                                         fontWeight:
//                                             FontWeight
//                                                 .bold,
//                                       ),
//                                     ),
//                         ),
//                       ),

//                       const SizedBox(
//                         height: 30,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


  // List<String> createSearchKeywords(
  //   String name,
  // ) {

  //   final String text =
  //       name.toLowerCase().trim();


  //   final Set<String> keywords =
  //       <String>{};


  //   for (
  //     int i = 1;
  //     i <= text.length;
  //     i++
  //   ) {

  //     keywords.add(
  //       text.substring(0, i),
  //     );

  //   }


  //   for (final category
  //       in selectedCategories) {

  //     keywords.add(
  //       category.toLowerCase(),
  //     );

  //   }


  //   return keywords.toList();

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
import 'package:jober_india/jober_indiaScreens.dart/Privacy&Terms/privacy_terms_section.dart';
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

class ScreenBrokerLogin extends StatefulWidget {
  const ScreenBrokerLogin({super.key});

  @override
  State<ScreenBrokerLogin> createState() => _ScreenBrokerLoginState();
}

class _ScreenBrokerLoginState extends State<ScreenBrokerLogin> {
  // ============================================================
  // CONTROLLERS
  // ============================================================
   static const Color green =
      Color(0xFF138808);

  // static const Color submitGreen =
  //     Color(0xFF159B16);

  static const Color darkText =
      Color(0xFF202124);

  static const Color lightFill =
      Color(0xFFF9F9F9);

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
AmbulanceLocation? currentLocation;

bool isGettingLocation = false;
bool isSearchingLocation = false;

// Used to invalidate an older location request
int _locationRequestId = 0;

  bool privacyPolicyAccepted = false;

  String? privacyPolicyError;

   File? profilePhoto;
  String? profilePhotoUrl;
bool isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();
  // ============================================================
  // OTP VARIABLES
  // ============================================================

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


  // ============================================================
  // ERROR VARIABLES
  // ============================================================

  bool nameError = false;
  bool mobileError = false;
//  bool otpError = false;
    bool secondaryMobileError = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    filteredCategories =
        List<String>.from(
      brokerCategories,
    );

     filteredStates = List<String>.from(indiaStates);

  loadDistricts();

    categorySearchController.addListener(() {
      if (!mounted) return;

      setState(() {
        categorySearchText =
            categorySearchController.text.trim();
      });
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
    categorySearchController.dispose();
    customCategoryController.dispose();
    stateSearchController.dispose();
    districtSearchController.dispose();


    super.dispose();
  }

  // void showMessage(String message) {
  //   if (!mounted) return;

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(message),
  //       behavior: SnackBarBehavior.floating,
  //       backgroundColor:
  //           const Color(0xFF176B32),
  //       shape: RoundedRectangleBorder(
  //         borderRadius:
  //             BorderRadius.circular(12),
  //       ),
  //     ),
  //   );
  // }
  void _showMessage(
  String message, {
  bool isError = false,
}) {
  if (!mounted) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),

        backgroundColor:
            isError
                ? Colors.red
                : const Color(0xFF16803C),

        behavior:
            SnackBarBehavior.floating,

        shape:
            RoundedRectangleBorder(
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
    _showMessage(AppLocalizations.of(context)!.enteradigitmobilenumber,
     // 'Enter a valid 10-digit mobile number.'
      );
    return;
  }

  if (isResend && secondsRemaining > 0) {
    _showMessage('Please wait ${secondsRemaining}s.');
    return;
  }

  if (!isResend && otpSent && secondsRemaining > 0) {
    _showMessage('Please wait before requesting another OTP.');
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

          _showMessage('Mobile number verified successfully.');

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

        _showMessage(otpErrorMessage);
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

        _showMessage(
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

    _showMessage('Mobile number verified successfully.');

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
    _showMessage(
      'Please wait ${secondsRemaining}s.',
    );
    return;
  }

  await sendOTP(isResend: true);
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

    Widget categorySection() {
    final categories =
        filteredCategories;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        sectionTitle(
          'Broker Categories',
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
                                    'Select Broker categories',
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
                                  'You can Add your own category',
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
  // BROKER CATEGORIES
  // ============================================================

  final List<String> brokerCategories = const [
    'Real Estate',
    'Vehicles',
    'Marriage',
  ];
    bool categoryError = false;
  String categorySearchText = '';

  bool isCategoryDropdownOpen = false;
  final List<String> customCategories = [];
  final List<String> selectedCategories = [];

  List<String> filteredCategories = [];


  // ============================================================
  // FIELD DECORATION
  // Same style as Student registration
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

   List<String> get allCategories {

    final List<String> result = [];

    for (final category in brokerCategories) {

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
            'You can Add your own Category',
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
                  'Enter Broker category',

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

    void addCustomCategory() {

    final String category =
        customCategoryController.text.trim();


    if (category.isEmpty) {

      _showMessage(
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


    _showMessage(
      '$actualCategory added.',
    );

  }

 
  Future<void> saveProfileToHive({
    required String uid,
    required String phone,
  }) async {
  
    final Box brokerBox =
        Hive.box('brokerProfiles');

    final Map<String, dynamic> profile =
        <String, dynamic>{
      'uid': uid,

      'name':
          nameController.text.trim(),

      'phone':
          phone,

      'secondaryMobile':
    secondaryPhoneController.text.trim(),

    'state': selectedState!.trim(),
'district': selectedDistrict!.trim(),
'nearestTown': nearestCityController.text.trim(),
'locationName': currentLocation?.placeName ?? '',
'latitude': currentLocation?.latitude,
'longitude': currentLocation?.longitude,
      'categories':
          selectedCategories.toList(),
      'profilePhotoUrl': profilePhotoUrl,

      'profileCompleted':
          true,

      'isLive':
          false,

      'savedAt':
          DateTime.now()
              .toIso8601String(),
    };

    await brokerBox.put(
      'currentUid',
      uid,
    );

    await brokerBox.put(
      uid,
      profile,
    );

    final Box userBox =
        Hive.box('userBox');

    await userBox.put(
      'uid',
      uid,
    );

    await userBox.put(
      'name',
      nameController.text.trim(),
    );

    await userBox.put(
      'mobile',
      phone,
    );

    await userBox.put(
  'secondaryMobile',
  secondaryPhoneController.text.trim(),
);

await userBox.put(
  'brokerState',
  selectedState!.trim(),
);

await userBox.put(
  'brokerDistrict',
  selectedDistrict!.trim(),
);

await userBox.put(
  'brokerNearestTown',
  nearestCityController.text.trim(),
);

    await userBox.put(
      'role',
      'broker',
    );

    await userBox.put(
      'categories',
      selectedCategories.toList(),
    );

    debugPrint(
      'Broker profile saved successfully.',
    );
  }

  Future<void> saveProfileToFirestore({
    required String uid,
    required String phone,
  }) async {
    await firestore
        .collection('brokers')
        .doc(uid)
        .set(
      {
        'uid':
            uid,

        'name':
            nameController.text.trim(),

        'phone':
            phone,

        'secondaryMobile':
    secondaryPhoneController.text.trim(),

    'state': selectedState!.trim(),
'district': selectedDistrict!.trim(),
'nearestTown': nearestCityController.text.trim(),
'locationName': currentLocation?.placeName ?? '',
'latitude': currentLocation?.latitude,
'longitude': currentLocation?.longitude,
        'categories':
            selectedCategories.toList(),
        'profilePhotoUrl': profilePhotoUrl,

        'profileCompleted':
            true,

        'isLive':
            false,
'isActive': true,
'registeredAt': FieldValue.serverTimestamp(),
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
    FocusScope.of(context).unfocus();

    bool valid = true;

    if (nameController.text.trim().isEmpty) {
      setState(() {
        nameError = true;
      });

      valid = false;
    }

    final String mobile =
        mobileController.text.trim();

    if (mobile.length != 10) {
      setState(() {
        mobileError = true;
      });

      valid = false;
    }

    final String secondaryMobile =
    secondaryPhoneController.text.trim();

if (secondaryMobile.length != 10) {
  setState(() {
    secondaryMobileError = true;
  });

  valid = false;
} else {
  setState(() {
    secondaryMobileError = false;
  });
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
  valid = false;
}

if (currentLocation == null) {
  locationError = true;
  valid = false;
} else {
  locationError = false;
}


    if (selectedCategories.isEmpty) {
      setState(() {
        categoryError = true;
      });

      valid = false;
    }

   
if (!otpVerified) {
  setState(() {
    mobileError = true;
  });

  _showMessage(
    'Please verify your phone number.',
    isError: true,
  );

  valid = false;
}

  privacyPolicyError =
      'Please accept the Privacy Policy and Terms & Conditions.';
  valid = false;
} else {
  privacyPolicyError = null;
}

 if (!valid) {
      return;
    }
  
    final User? user =
        auth.currentUser;

    if (user == null) {
      _showMessage(
        'Phone verification is required.',
        isError: true,
      );

      return;
    }

    if (isSubmitting) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // --------------------------------------------------------
      // SAVE LOCALLY FIRST
      // --------------------------------------------------------

      await saveProfileToHive(
        uid: user.uid,
        phone: mobile,
      );

      // --------------------------------------------------------
      // LOGIN STATE
      // --------------------------------------------------------

      await CommonProfileService.saveLogin(
  uid: user.uid,
  name: nameController.text.trim(),
  mobile: mobileController.text,
  role: 'broker',
);
      // --------------------------------------------------------
      // SHOW HOME AFTER 2 SECONDS
      // Same behavior as Student
      // --------------------------------------------------------

      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (!mounted) {
        return;
      }

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

      // --------------------------------------------------------
      // FIRESTORE SAVE IN BACKGROUND
      // --------------------------------------------------------

      saveProfileToFirestore(
        uid: user.uid,
        phone: mobile,
      ).catchError(
        (error) {
          debugPrint(
            'Broker Firestore save error: $error',
          );
        },
      );

    } catch (e) {
      debugPrint(
        'Broker submit error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      _showMessage(
        'Something went wrong. Please try again.',
        isError: true,
      );
    }
  }


  // ============================================================
  // MOBILE NUMBER SECTION
  // Same as Student
  // ============================================================

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
        decoration: fieldDecoration(
          hintText: 'Enter secondary mobile number',
          icon: Icons.phone_android_outlined,
        ).copyWith(
          counterText: '',
          errorText: secondaryMobileError
              ? (secondaryPhoneController.text.trim().isEmpty
                  ? 'Please enter your secondary mobile number.'
                  : AppLocalizations.of(context)!.enteradigitmobilenumber
                 // 'Enter a valid 10-digit mobile number'
                  )
              : null,
        ),
        onChanged: (value) {
          if (secondaryMobileError) {
            setState(() {
              secondaryMobileError = false;
            });
          }
        },
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

 Widget mobileSection() {
    final bool verified =
        otpVerified;
    final bool hasMobileError = mobileError;
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
  color: hasMobileError
      ? Colors.red
      : verified
          ? const Color(0xFF16803C)
          : const Color(0xFFD5D5D5),
  width: hasMobileError || verified ? 2 : 1.5,
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
      left: 8,
      top: 6,
    ),
    child: Text( AppLocalizations.of(context)!.enteradigitmobilenumber,
     // 'Enter a valid 10-digit mobile number.',
      style: TextStyle(
        color: Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
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


  Widget locationSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
         Text(AppLocalizations.of(context)!.ambulanceParkedLocation,
         // 'Ambulance Parked Location',
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
                _showMessage(
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
  _showMessage(
    'Could not identify this location. '
    'Please try again.',
    isError: true,
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

_showMessage(
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
    _showMessage(
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
      _showMessage(
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

      _showMessage(
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
      _showMessage(
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

  _showMessage(
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

      _showMessage(
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
  currentLocation = AmbulanceLocation(
    placeName: placeName,
    latitude: position.latitude,
    longitude: position.longitude,
  );

  locationError = false;
});

    _showMessage(
      'Ambulance location added.',
    );
  } catch (e) {
    if (!mounted || requestId != _locationRequestId) return;

    _showMessage(
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
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

        surfaceTintColor:
            Colors.white,

        leading:
            IconButton(
          icon:
              const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),

          onPressed:
              () {
            Navigator.pop(
              context,
            );
          },
        ),

        title:
            RichText(
          text:
               TextSpan(
            children: [

              TextSpan(
                text: 'Broker ',
                style:
                    TextStyle(
                  color:
                      Color(0xFF08744F),

                  fontSize:
                      22,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              TextSpan(
                text: AppLocalizations.of(context)!.registration,
                // 'Registration',
                style:
                    TextStyle(
                  color:
                      Colors.red,

                  fontSize:
                      22,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        centerTitle:
            false,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body:
          SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            28,
            10,
            28,
            35,
          ),

          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // =================================================
              // SUBTITLE
              // =================================================

              const Text(
                'Fill in your details to create your broker profile',

                style:
                    TextStyle(
                  color:
                      Colors.grey,

                  fontSize:
                      14,

                  height:
                      1.4,
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // =================================================
              // NAME
              // =================================================

              sectionTitle(
                'Full Name',
              ),

              const SizedBox(
                height: 10,
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
                height: 20,
              ),
 sectionTitle('Mobile Number'),
              const SizedBox(height: 6),

              // =================================================
              // MOBILE + OTP
              // =================================================
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

                    child: Text(
                     // 'Enter a valid 10-digit number',
AppLocalizations.of(context)!.enteradigitmobilenumber,
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
    hintText: 'Enter nearest Town ',
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
              // BROKER CATEGORY
              // =================================================
              categorySection(),

               const SizedBox(height: 20),
  sectionTitle('Profile Photo'),
                const SizedBox(height: 5),
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
              // SUBMIT PROFILE
              // =================================================

              SizedBox(
                width:
                    double.infinity,

                height:
                    58,

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
                        Color(0xFF138808)
                            ,

                    elevation:
                        0,

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
                                fontSize:
                                    17,

                                fontWeight:
                                    FontWeight.bold,
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
}


    // ============================================================
  // VERIFIED PHONE MESSAGE
  // ============================================================

  // Widget verifiedMessage() {
  //   if (!otpVerified) {
  //     return const SizedBox.shrink();
  //   }

  //   return Container(
  //     width: double.infinity,

  //     margin:
  //         const EdgeInsets.only(
  //       top: 12,
  //     ),

  //     padding:
  //         const EdgeInsets.symmetric(
  //       horizontal: 16,
  //       vertical: 13,
  //     ),

  //     decoration:
  //         BoxDecoration(
  //       color: Colors.green.withValues(
  //         alpha: 0.08,
  //       ),

  //       borderRadius:
  //           BorderRadius.circular(
  //         16,
  //       ),

  //       border:
  //           Border.all(
  //         color: Colors.green.withValues(
  //           alpha: 0.25,
  //         ),
  //       ),
  //     ),

  //     child:
  //         const Row(
  //       children: [

  //         Icon(
  //           Icons.verified,
  //           color: Color(0xFF16803C),
  //           size: 25,
  //         ),

  //         SizedBox(
  //           width: 10,
  //         ),

  //         Expanded(
  //           child: Text(
  //             'Phone number verified',

  //             style: TextStyle(
  //               color: Color(0xFF16803C),
  //               fontSize: 15,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }


  // InputDecoration fieldDecoration({
  //   required String hintText,
  //   required bool hasError,
  //   IconData? icon,
  // }) {
  //   return InputDecoration(
  //     hintText: hintText,

  //     prefixIcon: icon != null
  //         ? Icon(
  //             icon,
  //             color: const Color(0xFF16803C),
  //             size: 27,
  //           )
  //         : null,

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

  //       borderSide:
  //           BorderSide(
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

  //       borderSide:
  //           BorderSide(
  //         color: hasError
  //             ? Colors.red
  //             : const Color(0xFF16803C),

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
  //   );
  // }
  // ============================================================
  // FILTERED CATEGORIES
  // ============================================================

  // List<String> get filteredBrokerCategories {
  //   final query =
  //       categorySearchText.trim().toLowerCase();

  //   if (query.isEmpty) {
  //     return brokerCategories;
  //   }

  //   return brokerCategories.where((category) {
  //     return category
  //         .toLowerCase()
  //         .contains(query);
  //   }).toList();
  // }