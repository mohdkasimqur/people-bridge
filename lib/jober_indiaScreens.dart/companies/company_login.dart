// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';

// class CompanyLoginPage extends StatefulWidget {
//   const CompanyLoginPage({super.key});

//   @override
//   State<CompanyLoginPage> createState() => _CompanyLoginPageState();
// }

// class _CompanyLoginPageState extends State<CompanyLoginPage> {
//   // ============================================================
//   // CONTROLLERS
//   // ============================================================

//   final TextEditingController nameController =
//       TextEditingController();

//   final TextEditingController mobileController =
//       TextEditingController();

//   final TextEditingController otpController =
//       TextEditingController();

//   final TextEditingController companyNameController =
//       TextEditingController();

//   final TextEditingController categorySearchController =
//       TextEditingController();

//   // ============================================================
//   // FOCUS NODES
//   // ============================================================

//   final FocusNode nameFocus = FocusNode();
//   final FocusNode mobileFocus = FocusNode();
//   final FocusNode otpFocus = FocusNode();
//   final FocusNode companyNameFocus = FocusNode();

//   // ============================================================
//   // CATEGORIES
//   // ============================================================

//   final List<String> defaultCategories = [
//     'Manufacturing Company',
//     'Packing Company',
//   ];

//   final List<String> customCategories = [];

//   String? selectedCategory;

//   String categorySearchText = '';

//   // ============================================================
//   // EXPERIENCE
//   // ============================================================

//   final List<String> experienceOptions = [
//     'No Experience',
//     'Beginner',
//     'Up to 1 year',
//     '1 to 5 years',
//     '5 to 10 years',
//     '10 to 15 years',
//     '15 to 20 years',
//     'Above 20 years',
//   ];

//   String? selectedExperience;

//   // ============================================================
//   // OTP
//   // ============================================================

//   String? verificationId;

//   bool otpSent = false;
//   bool otpVerified = false;
//   bool isSendingOtp = false;
//   bool isVerifyingOtp = false;

//   Timer? otpTimer;

//   int remainingSeconds = 30;

//   // ============================================================
//   // LOCATION
//   // ============================================================

//   Position? currentPosition;

//   bool locationAttached = false;
//   bool gettingLocation = false;

//   // ============================================================
//   // SUBMIT
//   // ============================================================

//   bool isSubmitting = false;

//   @override
//   void dispose() {
//     nameController.dispose();
//     mobileController.dispose();
//     otpController.dispose();
//     companyNameController.dispose();
//     categorySearchController.dispose();

//     nameFocus.dispose();
//     mobileFocus.dispose();
//     otpFocus.dispose();
//     companyNameFocus.dispose();

//     otpTimer?.cancel();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,

//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         centerTitle: true,
//         title: const Text(
//           'Company Registration',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),

//       body: SafeArea(
//         child: SingleChildScrollView(
//           physics: const BouncingScrollPhysics(),

//           padding: const EdgeInsets.fromLTRB(
//             20,
//             10,
//             20,
//             40,
//           ),

//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Company Profile',
//                 style: TextStyle(
//                   fontSize: 25,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 6),

//               const Text(
//                 'Enter your company details below.',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey,
//                 ),
//               ),

//               const SizedBox(height: 25),

//               // NAME
//               _buildSectionTitle('Name'),

//               const SizedBox(height: 8),

//               _buildTextField(
//                 controller: nameController,
//                 focusNode: nameFocus,
//                 hintText: 'Enter your name',
//                 icon: Icons.person_outline,
//                 textInputType: TextInputType.name,
//               ),

//               const SizedBox(height: 20),

//               // MOBILE
//               _buildSectionTitle('Mobile Number'),

//               const SizedBox(height: 8),

//               Row(
//                 crossAxisAlignment:
//                     CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     height: 56,
//                     padding:
//                         const EdgeInsets.symmetric(
//                       horizontal: 14,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF5F5F5),
//                       borderRadius:
//                           BorderRadius.circular(14),
//                       border: Border.all(
//                         color: const Color(0xFFE0E0E0),
//                       ),
//                     ),
//                     alignment: Alignment.center,
//                     child: const Text(
//                       '+91',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),

//                   const SizedBox(width: 8),

//                   Expanded(
//                     child: TextField(
//                       controller: mobileController,
//                       focusNode: mobileFocus,
//                       keyboardType:
//                           TextInputType.phone,
//                       maxLength: 10,

//                       decoration: InputDecoration(
//                         counterText: '',
//                         hintText: 'Mobile number',

//                         prefixIcon:
//                             const Icon(
//                           Icons.phone_outlined,
//                         ),

//                         filled: true,
//                         fillColor:
//                             const Color(0xFFF8F8F8),

//                         border:
//                             OutlineInputBorder(
//                           borderRadius:
//                               BorderRadius.circular(
//                             14,
//                           ),
//                           borderSide:
//                               BorderSide.none,
//                         ),

//                         enabledBorder:
//                             OutlineInputBorder(
//                           borderRadius:
//                               BorderRadius.circular(
//                             14,
//                           ),
//                           borderSide:
//                               const BorderSide(
//                             color:
//                                 Color(0xFFE0E0E0),
//                           ),
//                         ),

//                         focusedBorder:
//                             OutlineInputBorder(
//                           borderRadius:
//                               BorderRadius.circular(
//                             14,
//                           ),
//                           borderSide:
//                               const BorderSide(
//                             color:
//                                 Color(0xFF198B35),
//                             width: 1.5,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(width: 8),

//                   SizedBox(
//                     height: 56,

//                     child: ElevatedButton(
//                       onPressed:
//                           isSendingOtp
//                               ? null
//                               : sendOtp,

//                       style:
//                           ElevatedButton.styleFrom(
//                         backgroundColor:
//                             const Color(
//                           0xFF198B35,
//                         ),
//                         foregroundColor:
//                             Colors.white,
//                         elevation: 0,

//                         padding:
//                             const EdgeInsets
//                                 .symmetric(
//                           horizontal: 12,
//                         ),

//                         shape:
//                             RoundedRectangleBorder(
//                           borderRadius:
//                               BorderRadius.circular(
//                             14,
//                           ),
//                         ),
//                       ),

//                       child: isSendingOtp
//                           ? const SizedBox(
//                               height: 20,
//                               width: 20,
//                               child:
//                                   CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 color:
//                                     Colors.white,
//                               ),
//                             )
//                           : const Text(
//                               'Send OTP',
//                               style: TextStyle(
//                                 fontWeight:
//                                     FontWeight.bold,
//                               ),
//                             ),
//                     ),
//                   ),
//                 ],
//               ),

//               if (otpSent) ...[
//                 const SizedBox(height: 15),
//                 _buildOtpSection(),
//               ],

//               const SizedBox(height: 22),

//               // COMPANY NAME
//               _buildSectionTitle(
//                 'Company Name',
//               ),

//               const SizedBox(height: 8),

//               _buildTextField(
//                 controller:
//                     companyNameController,
//                 focusNode:
//                     companyNameFocus,
//                 hintText:
//                     'Enter company name',
//                 icon:
//                     Icons.business_outlined,
//                 textInputType:
//                     TextInputType.text,
//               ),

//               const SizedBox(height: 22),

//               // CATEGORY
//               _buildSectionTitle(
//                 'Company Category',
//               ),

//               const SizedBox(height: 8),

//               _buildCategorySection(),

//               const SizedBox(height: 22),

//               // LOCATION
//               _buildSectionTitle(
//                 'Current Location',
//               ),

//               const SizedBox(height: 8),

//               _buildLocationSection(),

//               const SizedBox(height: 22),

//               // EXPERIENCE
//               _buildSectionTitle(
//                 'Experience',
//               ),

//               const SizedBox(height: 8),

//               _buildExperienceSection(),

//               const SizedBox(height: 30),

//               // SUBMIT
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,

//                 child: ElevatedButton(
//                   onPressed:
//                       isSubmitting
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
//                     elevation: 0,

//                     shape:
//                         RoundedRectangleBorder(
//                       borderRadius:
//                           BorderRadius.circular(
//                         16,
//                       ),
//                     ),
//                   ),

//                   child: isSubmitting
//                       ? const SizedBox(
//                           height: 25,
//                           width: 25,
//                           child:
//                               CircularProgressIndicator(
//                             strokeWidth: 2.5,
//                             color:
//                                 Colors.white,
//                           ),
//                         )
//                       : const Text(
//                           'Submit Profile',
//                           style: TextStyle(
//                             fontSize: 17,
//                             fontWeight:
//                                 FontWeight.bold,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//   // ============================================================
//   // SECTION TITLE
//   // ============================================================

//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.bold,
//       ),
//     );
//   }

//   // ============================================================
//   // TEXT FIELD
//   // ============================================================

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required FocusNode focusNode,
//     required String hintText,
//     required IconData icon,
//     required TextInputType textInputType,
//   }) {
//     return TextField(
//       controller: controller,
//       focusNode: focusNode,
//       keyboardType: textInputType,

//       decoration: InputDecoration(
//         hintText: hintText,
//         prefixIcon: Icon(icon),

//         filled: true,
//         fillColor: const Color(0xFFF8F8F8),

//         border: OutlineInputBorder(
//           borderRadius:
//               BorderRadius.circular(14),
//           borderSide: BorderSide.none,
//         ),

//         enabledBorder:
//             OutlineInputBorder(
//           borderRadius:
//               BorderRadius.circular(14),
//           borderSide: const BorderSide(
//             color: Color(0xFFE0E0E0),
//           ),
//         ),

//         focusedBorder:
//             OutlineInputBorder(
//           borderRadius:
//               BorderRadius.circular(14),
//           borderSide: const BorderSide(
//             color: Color(0xFF198B35),
//             width: 1.5,
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // OTP SECTION
//   // ============================================================

//   Widget _buildOtpSection() {
//     return Container(
//       padding: const EdgeInsets.all(14),

//       decoration: BoxDecoration(
//         color: const Color(0xFFF8F8F8),
//         borderRadius:
//             BorderRadius.circular(14),
//         border: Border.all(
//           color: const Color(0xFFE0E0E0),
//         ),
//       ),

//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,

//         children: [
//           const Text(
//             'Enter OTP',
//             style: TextStyle(
//               fontWeight:
//                   FontWeight.w600,
//             ),
//           ),

//           const SizedBox(height: 10),

//           TextField(
//             controller: otpController,
//             focusNode: otpFocus,
//             keyboardType:
//                 TextInputType.number,
//             maxLength: 6,
//             textAlign: TextAlign.center,

//             style: const TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               letterSpacing: 8,
//             ),

//             decoration:
//                 InputDecoration(
//               counterText: '',
//               hintText: '------',

//               filled: true,
//               fillColor: Colors.white,

//               border:
//                   OutlineInputBorder(
//                 borderRadius:
//                     BorderRadius.circular(
//                   12,
//                 ),
//                 borderSide:
//                     BorderSide.none,
//               ),

//               enabledBorder:
//                   OutlineInputBorder(
//                 borderRadius:
//                     BorderRadius.circular(
//                   12,
//                 ),
//                 borderSide:
//                     const BorderSide(
//                   color:
//                       Color(0xFFE0E0E0),
//                 ),
//               ),

//               focusedBorder:
//                   OutlineInputBorder(
//                 borderRadius:
//                     BorderRadius.circular(
//                   12,
//                 ),
//                 borderSide:
//                     const BorderSide(
//                   color:
//                       Color(0xFF198B35),
//                   width: 1.5,
//                 ),
//               ),
//             ),
//           ),

//           const SizedBox(height: 10),

//           Row(
//             mainAxisAlignment:
//                 MainAxisAlignment.spaceBetween,

//             children: [
//               if (otpVerified)
//                 const Row(
//                   children: [
//                     Icon(
//                       Icons.verified,
//                       color:
//                           Color(0xFF198B35),
//                       size: 20,
//                     ),
//                     SizedBox(width: 5),
//                     Text(
//                       'Mobile verified',
//                       style: TextStyle(
//                         color:
//                             Color(
//                           0xFF198B35,
//                         ),
//                         fontWeight:
//                             FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 )
//               else
//                 Text(
//                   remainingSeconds > 0
//                       ? 'Resend in $remainingSeconds s'
//                       : 'You can resend OTP',
//                   style:
//                       const TextStyle(
//                     color: Colors.grey,
//                   ),
//                 ),

//               if (!otpVerified)
//                 TextButton(
//                   onPressed:
//                       remainingSeconds == 0 &&
//                               !isSendingOtp
//                           ? sendOtp
//                           : null,
//                   child:
//                       const Text(
//                     'Resend OTP',
//                     style: TextStyle(
//                       fontWeight:
//                           FontWeight.bold,
//                     ),
//                   ),
//                 ),
//             ],
//           ),

//           if (!otpVerified) ...[
//             const SizedBox(height: 5),

//             SizedBox(
//               width: double.infinity,
//               height: 46,

//               child: ElevatedButton(
//                 onPressed:
//                     isVerifyingOtp
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
//                   elevation: 0,

//                   shape:
//                       RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius.circular(
//                       12,
//                     ),
//                   ),
//                 ),

//                 child: isVerifyingOtp
//                     ? const SizedBox(
//                         height: 20,
//                         width: 20,
//                         child:
//                             CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color:
//                               Colors.white,
//                         ),
//                       )
//                     : const Text(
//                         'Verify OTP',
//                         style: TextStyle(
//                           fontWeight:
//                               FontWeight.bold,
//                         ),
//                       ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // CATEGORY SECTION
//   // ============================================================

//   Widget _buildCategorySection() {
//     final allCategories = [
//       ...defaultCategories,
//       ...customCategories,
//     ];

//     final filteredCategories =
//         allCategories.where(
//       (category) {
//         return category
//             .toLowerCase()
//             .contains(
//               categorySearchText
//                   .toLowerCase(),
//             );
//       },
//     ).toList();

//     return Container(
//       padding: const EdgeInsets.all(14),

//       decoration: BoxDecoration(
//         color: const Color(0xFFF8F8F8),
//         borderRadius:
//             BorderRadius.circular(16),
//         border: Border.all(
//           color: const Color(0xFFE0E0E0),
//         ),
//       ),

//       child: Column(
//         children: [
//           TextField(
//             controller:
//                 categorySearchController,

//             onChanged: (value) {
//               setState(() {
//                 categorySearchText =
//                     value;
//               });
//             },

//             decoration:
//                 InputDecoration(
//               hintText:
//                   'Search company category',
//               prefixIcon:
//                   const Icon(
//                 Icons.search,
//               ),

//               filled: true,
//               fillColor: Colors.white,

//               border:
//                   OutlineInputBorder(
//                 borderRadius:
//                     BorderRadius.circular(
//                   12,
//                 ),
//                 borderSide:
//                     BorderSide.none,
//               ),

//               enabledBorder:
//                   OutlineInputBorder(
//                 borderRadius:
//                     BorderRadius.circular(
//                   12,
//                 ),
//                 borderSide:
//                     const BorderSide(
//                   color:
//                       Color(0xFFE0E0E0),
//                 ),
//               ),
//             ),
//           ),

//           const SizedBox(height: 12),

// RadioGroup<String>(
//   groupValue: selectedCategory,

//   onChanged: (String? value) {
//     setState(() {
//       selectedCategory = value;
//     });
//   },

//   child: Column(
//     children: filteredCategories.map(
//       (category) {
//         return RadioListTile<String>(
//           value: category,

//           activeColor: const Color(
//             0xFF198B35,
//           ),

//           contentPadding: EdgeInsets.zero,

//           title: Text(
//             category,
//             style: const TextStyle(
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         );
//       },
//     ).toList(),
//   ),
// ),

//           const SizedBox(height: 5),

//           InkWell(
//             onTap:
//                 _showAddCategoryDialog,

//             borderRadius:
//                 BorderRadius.circular(
//               12,
//             ),

//             child: Container(
//               width: double.infinity,

//               padding:
//                   const EdgeInsets
//                       .symmetric(
//                 vertical: 13,
//                 horizontal: 12,
//               ),

//               decoration:
//                   BoxDecoration(
//                 color: Colors.white,
//                 borderRadius:
//                     BorderRadius.circular(
//                   12,
//                 ),
//                 border: Border.all(
//                   color:
//                       const Color(
//                     0xFF198B35,
//                   ),
//                 ),
//               ),

//               child: const Row(
//                 mainAxisAlignment:
//                     MainAxisAlignment.center,

//                 children: [
//                   Icon(
//                     Icons.add,
//                     color:
//                         Color(
//                       0xFF198B35,
//                     ),
//                   ),

//                   SizedBox(width: 6),

//                   Text(
//                     'Add your own category',
//                     style: TextStyle(
//                       color:
//                           Color(
//                         0xFF198B35,
//                       ),
//                       fontWeight:
//                           FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           if (selectedCategory !=
//               null) ...[
//             const SizedBox(height: 12),

//             Align(
//               alignment:
//                   Alignment.centerLeft,

//               child: Text(
//                 'Selected: $selectedCategory',
//                 style:
//                     const TextStyle(
//                   color:
//                       Color(
//                     0xFF198B35,
//                   ),
//                   fontWeight:
//                       FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // ADD CATEGORY
//   // ============================================================

//   void _showAddCategoryDialog() {
//     final controller =
//         TextEditingController();

//     showDialog(
//       context: context,

//       builder: (dialogContext) {
//         return AlertDialog(
//           title: const Text(
//             'Add Company Category',
//           ),

//           content: TextField(
//             controller: controller,
//             autofocus: true,

//             decoration:
//                 const InputDecoration(
//               hintText:
//                   'Enter category name',
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
//                   const Text('Cancel'),
//             ),

//             ElevatedButton(
//               onPressed: () {
//                 final category =
//                     controller.text
//                         .trim();

//                 if (category.isEmpty) {
//                   return;
//                 }

//                 if (!customCategories
//                     .contains(
//                   category,
//                 )) {
//                   setState(() {
//                     customCategories
//                         .add(category);

//                     selectedCategory =
//                         category;
//                   });
//                 }

//                 Navigator.pop(
//                   dialogContext,
//                 );
//               },

//               style:
//                   ElevatedButton.styleFrom(
//                 backgroundColor:
//                     const Color(
//                   0xFF198B35,
//                 ),
//                 foregroundColor:
//                     Colors.white,
//               ),

//               child:
//                   const Text('Add'),
//             ),
//           ],
//         );
//       },
//     ).then((_) {
//       controller.dispose();
//     });
//   }

//   // ============================================================
//   // LOCATION SECTION
//   // ============================================================

//   Widget _buildLocationSection() {
//     return Container(
//       width: double.infinity,

//       padding:
//           const EdgeInsets.all(16),

//       decoration:
//           BoxDecoration(
//         color:
//             const Color(0xFFF8F8F8),
//         borderRadius:
//             BorderRadius.circular(
//           16,
//         ),
//         border: Border.all(
//           color:
//               const Color(0xFFE0E0E0),
//         ),
//       ),

//       child: Column(
//         children: [
//           Icon(
//             locationAttached
//                 ? Icons.location_on
//                 : Icons.location_searching,

//             size: 42,

//             color: locationAttached
//                 ? const Color(
//                     0xFF198B35,
//                   )
//                 : Colors.grey,
//           ),

//           const SizedBox(height: 10),

//           Text(
//             locationAttached
//                 ? 'Current location attached'
//                 : 'Current location not attached',

//             style: TextStyle(
//               fontSize: 15,
//               fontWeight:
//                   FontWeight.w600,

//               color: locationAttached
//                   ? const Color(
//                       0xFF198B35,
//                     )
//                   : Colors.grey,
//             ),
//           ),

//           const SizedBox(height: 14),

//           SizedBox(
//             width: double.infinity,
//             height: 48,

//             child:
//                 OutlinedButton.icon(
//               onPressed:
//                   gettingLocation
//                       ? null
//                       : attachCurrentLocation,

//               icon: gettingLocation
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child:
//                           CircularProgressIndicator(
//                         strokeWidth: 2,
//                       ),
//                     )
//                   : const Icon(
//                       Icons.my_location,
//                     ),

//               label: Text(
//                 locationAttached
//                     ? 'Location Attached'
//                     : 'Attach Current Location',
//               ),

//               style:
//                   OutlinedButton.styleFrom(
//                 foregroundColor:
//                     const Color(
//                   0xFF198B35,
//                 ),

//                 side:
//                     const BorderSide(
//                   color:
//                       Color(
//                     0xFF198B35,
//                   ),
//                 ),

//                 shape:
//                     RoundedRectangleBorder(
//                   borderRadius:
//                       BorderRadius.circular(
//                     12,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // EXPERIENCE
//   // ============================================================

//   Widget _buildExperienceSection() {
//     return Container(
//       decoration:
//           BoxDecoration(
//         color:
//             const Color(0xFFF8F8F8),
//         borderRadius:
//             BorderRadius.circular(
//           16,
//         ),
//         border: Border.all(
//           color:
//               const Color(0xFFE0E0E0),
//         ),
//       ),

//      child: RadioGroup<String>(
//   groupValue: selectedExperience,

//   onChanged: (String? value) {
//     setState(() {
//       selectedExperience = value;
//     });
//   },

//   child: Column(
//     children: experienceOptions.map(
//       (experience) {
//         return RadioListTile<String>(
//           value: experience,

//           activeColor: const Color(
//             0xFF198B35,
//           ),

//           title: Text(
//             experience,
//             style: const TextStyle(
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         );
//       },
//     ).toList(),
//   ),
// ),
//     );
//   }
//   // ============================================================
//   // SEND OTP
//   // ============================================================

//   Future<void> sendOtp() async {
//     final mobile =
//         mobileController.text.trim();

//     if (mobile.length != 10) {
//       _showMessage(
//         'Please enter a valid 10-digit mobile number.',
//       );
//       return;
//     }

//     FocusScope.of(context).unfocus();

//     setState(() {
//       isSendingOtp = true;
//       otpSent = false;
//       otpVerified = false;
//     });

//     try {
//       await FirebaseAuth.instance
//           .verifyPhoneNumber(
//         phoneNumber: '+91$mobile',

//         timeout:
//             const Duration(
//           seconds: 60,
//         ),

//         verificationCompleted:
//             (PhoneAuthCredential credential) async {
//           try {
//             await FirebaseAuth.instance
//                 .signInWithCredential(
//               credential,
//             );

//             if (!mounted) return;

//             setState(() {
//               otpVerified = true;
//               otpSent = true;
//               isSendingOtp = false;
//             });
//           } catch (_) {
//             if (!mounted) return;

//             setState(() {
//               isSendingOtp = false;
//             });
//           }
//         },

//         verificationFailed:
//             (FirebaseAuthException e) {
//           if (!mounted) return;

//           setState(() {
//             isSendingOtp = false;
//             otpSent = false;
//           });

//           _showMessage(
//             e.message ??
//                 'Unable to send OTP.',
//           );
//         },

//         codeSent:
//             (String id, int? resendToken) {
//           if (!mounted) return;

//           setState(() {
//             verificationId = id;
//             otpSent = true;
//             isSendingOtp = false;
//             remainingSeconds = 30;
//           });

//           startOtpTimer();

//           Future.delayed(
//             const Duration(
//               milliseconds: 150,
//             ),
//             () {
//               if (!mounted) return;

//               FocusScope.of(context)
//                   .requestFocus(
//                 otpFocus,
//               );
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
//         isSendingOtp = false;
//       });

//       _showMessage(
//         'Something went wrong while sending OTP.',
//       );
//     }
//   }

//   // ============================================================
//   // OTP TIMER
//   // ============================================================

//   void startOtpTimer() {
//     otpTimer?.cancel();

//     otpTimer = Timer.periodic(
//       const Duration(seconds: 1),
//       (timer) {
//         if (!mounted) {
//           timer.cancel();
//           return;
//         }

//         if (remainingSeconds <= 1) {
//           timer.cancel();

//           setState(() {
//             remainingSeconds = 0;
//           });
//         } else {
//           setState(() {
//             remainingSeconds--;
//           });
//         }
//       },
//     );
//   }

//   // ============================================================
//   // VERIFY OTP
//   // ============================================================

//   Future<void> verifyOtp() async {
//     final otp =
//         otpController.text.trim();

//     if (otp.length != 6) {
//       _showMessage(
//         'Please enter the 6-digit OTP.',
//       );
//       return;
//     }

//     if (verificationId == null) {
//       _showMessage(
//         'Please request OTP again.',
//       );
//       return;
//     }

//     FocusScope.of(context).unfocus();

//     setState(() {
//       isVerifyingOtp = true;
//     });

//     try {
//       final credential =
//           PhoneAuthProvider.credential(
//         verificationId:
//             verificationId!,
//         smsCode: otp,
//       );

//       await FirebaseAuth.instance
//           .signInWithCredential(
//         credential,
//       );

//       if (!mounted) return;

//       setState(() {
//         otpVerified = true;
//         isVerifyingOtp = false;
//       });

//       _showMessage(
//         'Mobile number verified successfully.',
//       );
//     } on FirebaseAuthException catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isVerifyingOtp = false;
//       });

//       _showMessage(
//         e.message ??
//             'Invalid OTP.',
//       );
//     }
//   }

//   // ============================================================
//   // ATTACH CURRENT LOCATION
//   // ============================================================

//   Future<void> attachCurrentLocation() async {
//     setState(() {
//       gettingLocation = true;
//     });

//     try {
//       final serviceEnabled =
//           await Geolocator
//               .isLocationServiceEnabled();

//       if (!serviceEnabled) {
//         if (!mounted) return;

//         setState(() {
//           gettingLocation = false;
//         });

//         _showMessage(
//           'Please turn on your phone location service.',
//         );

//         await Geolocator
//             .openLocationSettings();

//         return;
//       }

//       LocationPermission permission =
//           await Geolocator.checkPermission();

//       if (permission ==
//           LocationPermission.denied) {
//         permission =
//             await Geolocator.requestPermission();
//       }

//       if (permission ==
//               LocationPermission.denied ||
//           permission ==
//               LocationPermission
//                   .deniedForever) {
//         if (!mounted) return;

//         setState(() {
//           gettingLocation = false;
//         });

//         _showMessage(
//           'Location permission is required.',
//         );

//         if (permission ==
//             LocationPermission
//                 .deniedForever) {
//           await Geolocator
//               .openAppSettings();
//         }

//         return;
//       }

//       final position =
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
//         locationAttached = true;
//         gettingLocation = false;
//       });

//       _showMessage(
//         'Current location attached successfully.',
//       );
//     } catch (_) {
//       if (!mounted) return;

//       setState(() {
//         gettingLocation = false;
//       });

//       _showMessage(
//         'Unable to get current location.',
//       );
//     }
//   }

//   // ============================================================
//   // SUBMIT PROFILE
//   // ============================================================

//   Future<void> submitProfile() async {
//     if (nameController.text
//         .trim()
//         .isEmpty) {
//       _showMessage(
//         'Please enter your name.',
//       );
//       return;
//     }

//     if (mobileController.text
//             .trim()
//             .length !=
//         10) {
//       _showMessage(
//         'Please enter a valid 10-digit mobile number.',
//       );
//       return;
//     }

//     if (!otpVerified) {
//       _showMessage(
//         'Please verify your mobile number first.',
//       );
//       return;
//     }

//     if (companyNameController.text
//         .trim()
//         .isEmpty) {
//       _showMessage(
//         'Please enter your company name.',
//       );
//       return;
//     }

//     if (selectedCategory == null) {
//       _showMessage(
//         'Please select a company category.',
//       );
//       return;
//     }

//     if (!locationAttached ||
//         currentPosition == null) {
//       _showMessage(
//         'Please attach your current location.',
//       );
//       return;
//     }

//     if (selectedExperience == null) {
//       _showMessage(
//         'Please select your experience.',
//       );
//       return;
//     }

//     if (isSubmitting) return;

//     setState(() {
//       isSubmitting = true;
//     });

//     try {
//       final user =
//           FirebaseAuth.instance
//               .currentUser;

//       if (user == null) {
//         if (!mounted) return;

//         setState(() {
//           isSubmitting = false;
//         });

//         _showMessage(
//           'Please verify your mobile number again.',
//         );

//         return;
//       }

//       // ========================================================
//       // IMPORTANT:
//       // These fields are saved specifically so the message
//       // screen can display them later.
//       // ========================================================

//       final companyData = {
//         'userId': user.uid,

//         'name':
//             nameController.text.trim(),

//         'mobile':
//             mobileController.text.trim(),

//         'companyName':
//             companyNameController
//                 .text
//                 .trim(),

//         'category':
//             selectedCategory,

//         'experience':
//             selectedExperience,

//         'location': {
//           'latitude':
//               currentPosition!.latitude,
//           'longitude':
//               currentPosition!.longitude,
//         },

//         // Easy fields for the message screen
//         'messageDisplay': {
//           'companyName':
//               companyNameController
//                   .text
//                   .trim(),
//           'mobile':
//               mobileController.text.trim(),
//           'latitude':
//               currentPosition!.latitude,
//           'longitude':
//               currentPosition!.longitude,
//         },

//         'profileType':
//             'company',

//         'createdAt':
//             FieldValue.serverTimestamp(),

//         'updatedAt':
//             FieldValue.serverTimestamp(),
//       };

//       await FirebaseFirestore.instance
//           .collection('companies')
//           .doc(user.uid)
//           .set(
//             companyData,
//             SetOptions(
//               merge: true,
//             ),
//           );

//       if (!mounted) return;

//       setState(() {
//         isSubmitting = false;
//       });

//       _showSuccessDialog();
//     } on FirebaseException catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isSubmitting = false;
//       });

//       _showMessage(
//         e.message ??
//             'Unable to save company profile.',
//       );
//     } catch (_) {
//       if (!mounted) return;

//       setState(() {
//         isSubmitting = false;
//       });

//       _showMessage(
//         'Unable to save company profile.',
//       );
//     }
//   }

//   // ============================================================
//   // SUCCESS
//   // ============================================================

//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,

//       builder: (dialogContext) {
//         return AlertDialog(
//           shape:
//               RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(
//               20,
//             ),
//           ),

//           content: Column(
//             mainAxisSize:
//                 MainAxisSize.min,

//             children: [
//               const Icon(
//                 Icons.check_circle,
//                 size: 65,
//                 color:
//                     Color(0xFF198B35),
//               ),

//               const SizedBox(height: 15),

//               const Text(
//                 'Profile Submitted',
//                 style: TextStyle(
//                   fontSize: 21,
//                   fontWeight:
//                       FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 8),

//               const Text(
//                 'Your company profile has been saved successfully.',
//                 textAlign:
//                     TextAlign.center,
//                 style: TextStyle(
//                   color: Colors.grey,
//                 ),
//               ),

//               const SizedBox(height: 20),

//               SizedBox(
//                 width: double.infinity,

//                 child:
//                     ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(
//                       dialogContext,
//                     );

//                     // Put your next-page
//                     // navigation here.
//                   },

//                   style:
//                       ElevatedButton
//                           .styleFrom(
//                     backgroundColor:
//                         const Color(
//                       0xFF198B35,
//                     ),
//                     foregroundColor:
//                         Colors.white,
//                   ),

//                   child:
//                       const Text(
//                     'Continue',
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ============================================================
//   // MESSAGE
//   // ============================================================

//   void _showMessage(String message) {
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

//         duration:
//             const Duration(
//           seconds: 3,
//         ),
//       ),
//     );
//   }
// }

// // =================================================================
// // COMPANY MESSAGE HEADER
// // =================================================================
// //
// // Put this widget at the top of your message screen.
// //
// // It reads the company profile from Firestore and displays:
// //
// // 1. Company name
// // 2. Mobile number
// // 3. Attached location
// //
// // =================================================================

// class CompanyMessageHeader
//     extends StatelessWidget {
//   final String companyId;

//   const CompanyMessageHeader({
//     super.key,
//     required this.companyId,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<
//         DocumentSnapshot<Map<String, dynamic>>>(
//       stream:
//           FirebaseFirestore.instance
//               .collection('companies')
//               .doc(companyId)
//               .snapshots(),

//       builder:
//           (context, snapshot) {
//         if (snapshot.connectionState ==
//             ConnectionState.waiting) {
//           return const SizedBox(
//             height: 100,
//             child: Center(
//               child:
//                   CircularProgressIndicator(),
//             ),
//           );
//         }

//         if (!snapshot.hasData ||
//             !snapshot.data!.exists) {
//           return const SizedBox.shrink();
//         }

//         final data =
//             snapshot.data!.data();

//         if (data == null) {
//           return const SizedBox.shrink();
//         }

//         final companyName =
//             data['companyName']
//                     ?.toString() ??
//                 'Company';

//         final mobile =
//             data['mobile']
//                     ?.toString() ??
//                 '';

//         final location =
//             data['location'];

//         double? latitude;
//         double? longitude;

//         if (location
//             is Map<String, dynamic>) {
//           latitude =
//               (location['latitude']
//                       as num?)
//                   ?.toDouble();

//           longitude =
//               (location['longitude']
//                       as num?)
//                   ?.toDouble();
//         }

//         return Container(
//           width: double.infinity,

//           padding:
//               const EdgeInsets.all(14),

//           decoration:
//               const BoxDecoration(
//             color: Colors.white,
//             border: Border(
//               bottom: BorderSide(
//                 color:
//                     Color(0xFFE0E0E0),
//               ),
//             ),
//           ),

//           child: Row(
//             children: [
//               Container(
//                 width: 48,
//                 height: 48,

//                 decoration:
//                     BoxDecoration(
//                   color:
//                       const Color(
//                     0xFFEAF6ED,
//                   ),
//                   borderRadius:
//                       BorderRadius.circular(
//                     14,
//                   ),
//                 ),

//                 child: const Icon(
//                   Icons.business,
//                   color:
//                       Color(0xFF198B35),
//                 ),
//               ),

//               const SizedBox(width: 12),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,

//                   children: [
//                     Text(
//                       companyName,
//                       maxLines: 1,
//                       overflow:
//                           TextOverflow.ellipsis,

//                       style:
//                           const TextStyle(
//                         fontSize: 16,
//                         fontWeight:
//                             FontWeight.bold,
//                       ),
//                     ),

//                     const SizedBox(
//                         height: 4),

//                     Text(
//                       mobile.isEmpty
//                           ? 'Mobile number unavailable'
//                           : '+91 $mobile',

//                       style:
//                           const TextStyle(
//                         fontSize: 13,
//                         color:
//                             Colors.grey,
//                       ),
//                     ),

//                     if (latitude != null &&
//                         longitude != null)
//                       const Padding(
//                         padding:
//                             EdgeInsets.only(
//                           top: 3,
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(
//                               Icons
//                                   .location_on,
//                               size: 15,
//                               color:
//                                   Color(
//                                 0xFF198B35,
//                               ),
//                             ),
//                             SizedBox(
//                                 width: 3),
//                             Text(
//                               'Location attached',
//                               style:
//                                   TextStyle(
//                                 fontSize:
//                                     12,
//                                 color:
//                                     Color(
//                                   0xFF198B35,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//               ),

//               if (latitude != null &&
//                   longitude != null)
//                 IconButton(
//                   tooltip:
//                       'View Location',

//                   icon:
//                       const Icon(
//                     Icons
//                         .location_on_outlined,
//                     color:
//                         Color(
//                       0xFF198B35,
//                     ),
//                   ),

//                   onPressed: () {
//                     // You can connect this to
//                     // your map/location screen.
//                     //
//                     // latitude and longitude
//                     // are available here.
//                     _showLocationDialog(
//                       context,
//                       latitude!,
//                       longitude!,
//                     );
//                   },
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ============================================================
//   // LOCATION DIALOG
//   // ============================================================

//   void _showLocationDialog(
//     BuildContext context,
//     double latitude,
//     double longitude,
//   ) {
//     showDialog(
//       context: context,

//       builder: (context) {
//         return AlertDialog(
//           title:
//               const Text(
//             'Company Location',
//           ),

//           content: Text(
//             'Latitude: $latitude\n'
//             'Longitude: $longitude',
//           ),

//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(
//                   context,
//                 );
//               },

//               child:
//                   const Text('Close'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }


//   Future<void> submitProfile() async {
//     if (isSubmitting) return;

//     final String name =
//         nameController.text.trim();

//     final String mobile =
//         mobileController.text.trim();

//     final String companyName =
//         companyNameController.text.trim();

//     final List<String> categories =
//         List<String>.from(
//       selectedCategories,
//     );

//     // ==========================================================
//     // VALIDATION
//     // ==========================================================

//     bool hasError = false;

//     if (name.isEmpty) {
//       hasError = true;

//       if (mounted) {
//         setState(() {
//           nameError = true;
//         });
//       }
//     } else {
//       if (mounted) {
//         setState(() {
//           nameError = false;
//         });
//       }
//     }

//     if (mobile.length != 10) {
//       hasError = true;

//       if (mounted) {
//         setState(() {
//           mobileError = true;
//         });
//       }
//     } else {
//       if (mounted) {
//         setState(() {
//           mobileError = false;
//         });
//       }
//     }

//     if (companyName.isEmpty) {
//       hasError = true;

//       if (mounted) {
//         setState(() {
//           companyNameError = true;
//         });
//       }
//     } else {
//       if (mounted) {
//         setState(() {
//           companyNameError = false;
//         });
//       }
//     }

//     if (categories.isEmpty) {
//       hasError = true;

//       if (mounted) {
//         setState(() {
//           categoryError = true;
//         });
//       }
//     } else {
//       if (mounted) {
//         setState(() {
//           categoryError = false;
//         });
//       }
//     }

//     if (!otpVerified) {
//       hasError = true;

//       if (otpSent) {
//         showMessage(
//           'Please verify your mobile number.',
//         );
//       }
//     }

//     if (!locationAttached ||
//         currentPosition == null) {
//       hasError = true;

//       if (mounted) {
//         setState(() {
//           locationError = true;
//         });
//       }
//     }

//     if (hasError) {
//       return;
//     }

//     // ==========================================================
//     // FIREBASE USER
//     // ==========================================================

//     final User? user =
//         auth.currentUser;

//     if (user == null) {
//       showMessage(
//         'Your phone verification session expired. Please verify OTP again.',
//       );

//       return;
//     }

//     // ==========================================================
//     // PREVENT DOUBLE SUBMIT
//     // ==========================================================

//     if (!mounted) return;

//     setState(() {
//       isSubmitting = true;
//     });

//     // ==========================================================
//     // CAPTURE ALL DATA BEFORE NAVIGATION
//     // ==========================================================

//     final String uid = user.uid;

//     final String finalName = name;

//     final String finalMobile = mobile;

//     final String finalCompanyName =
//         companyName;

//     final List<String> finalCategories =
//         List<String>.from(categories);

//     final String finalCategoryText =
//         finalCategories.join(', ');

//     final String? finalExperience =
//         selectedExperience;

//     final double finalLatitude =
//         currentPosition!.latitude;

//     final double finalLongitude =
//         currentPosition!.longitude;

//     // ==========================================================
//     // LOCAL SAVE FIRST
//     // ==========================================================

//     try {
//       final Box settingsBox =
//           Hive.box('settings');

//       await settingsBox.put(
//         'companyRegistered',
//         true,
//       );

//       await settingsBox.put(
//         'companySyncPending',
//         true,
//       );

//       await settingsBox.put(
//         'companyUid',
//         uid,
//       );

//       await settingsBox.put(
//         'companyOwnerName',
//         finalName,
//       );

//       await settingsBox.put(
//         'companyName',
//         finalCompanyName,
//       );

//       await settingsBox.put(
//         'companyMobile',
//         finalMobile,
//       );

//       await settingsBox.put(
//         'companyCategories',
//         finalCategories,
//       );

//       await settingsBox.put(
//         'companyCategory',
//         finalCategoryText,
//       );

//       await settingsBox.put(
//         'companyExperience',
//         finalExperience,
//       );

//       await settingsBox.put(
//         'companyLatitude',
//         finalLatitude,
//       );

//       await settingsBox.put(
//         'companyLongitude',
//         finalLongitude,
//       );

//       await settingsBox.put(
//         'companyRole',
//         'company',
//       );

//       // ========================================================
//       // LOGIN STATE
//       // ========================================================

//      await CommonProfileService.saveLogin(
//   uid: uid,
//   name: finalName,
//   mobile: finalMobile,
//   role: 'company',
// );
//     } catch (e) {
//       debugPrint(
//         'Local company save error: $e',
//       );
//     }
    
//     // ==========================================================
//     // GIVE UI A LITTLE TIME
//     // ==========================================================

//     await Future.delayed(
//       const Duration(seconds: 2),
//     );

//     // ==========================================================
//     // GO HOME FIRST
//     // ==========================================================

//     if (!mounted) return;

//     setState(() {
//       isSubmitting = false;
//     });

//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             const ScreenHome(),
//       ),
//       (route) => false,
//     );

//     // ==========================================================
//     // FIRESTORE IN BACKGROUND
//     // ==========================================================

//     unawaited(
//       saveCompanyToFirestore(
//         uid: uid,
//         name: finalName,
//         mobile: finalMobile,
//         companyName: finalCompanyName,
//         categories: finalCategories,
//         categoryText: finalCategoryText,
//         experience: finalExperience,
//         latitude: finalLatitude,
//         longitude: finalLongitude,
//       ),
//     );
//   }


    // Location is OFF on the phone
    // if (!serviceEnabled) {
    //   setState(() {
    //     isGettingLocation = false;
    //   });

    //   // Open phone Location Settings
    //   await Geolocator.openLocationSettings();

    //   return;
    // }
                            //   OutlinedButton.icon(
                            // onPressed: () {
                            //   setState(() {
                            //     currentLocation =
                            //         null;
                            //   });
                            // },
                            // icon:
                            //     const Icon(
                            //   Icons.delete_outline,
                            // ),
                            // label:
                            //     const Text(
                            //   'Remove',
                            // ),
                            // style:
                            //     OutlinedButton
                            //         .styleFrom(
                            //   foregroundColor:
                            //       Colors.red,
                            //   side:
                            //       const BorderSide(
                            //     color: Colors.red,
                            //   ),
                            //   shape:
                            //       RoundedRectangleBorder(
                            //     borderRadius:
                            //         BorderRadius
                            //             .circular(
                            //       18,
                            //     ),
                            //   ),
                            // ),

  // Widget experienceSection() {
  //   return Column(
  //     crossAxisAlignment:
  //         CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Experience',
  //         style: TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.black87,
  //         ),
  //       ),

  //       const SizedBox(height: 10),

  //       Container(
  //         decoration: BoxDecoration(
  //           color: const Color(0xFFF9F9F9),
  //           borderRadius:
  //               BorderRadius.circular(20),
  //           border: Border.all(
  //             color: Colors.grey.shade300,
  //             width: 1.3,
  //           ),
  //         ),
  //         child: DropdownButtonHideUnderline(
  //           child: DropdownButton<String>(
  //             value: selectedExperience,
  //             isExpanded: true,
  //             hint: const Row(
  //               children: [
  //                 Icon(
  //                   Icons.work_outline,
  //                   color: Color(0xFF16803C),
  //                   size: 27,
  //                 ),
  //                 SizedBox(width: 12),
  //                 Text(
  //                   'Select experience',
  //                   style: TextStyle(
  //                     color: Colors.grey,
  //                     fontSize: 15,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             icon: const Icon(
  //               Icons.keyboard_arrow_down,
  //               color: Colors.black54,
  //             ),
  //             borderRadius:
  //                 BorderRadius.circular(15),
  //             padding:
  //                 const EdgeInsets.symmetric(
  //               horizontal: 16,
  //               vertical: 5,
  //             ),
  //             items:
  //                 experienceOptions.map(
  //               (String experience) {
  //                 return DropdownMenuItem<String>(
  //                   value: experience,
  //                   child: Text(
  //                     experience,
  //                     style: const TextStyle(
  //                       fontSize: 15,
  //                       color: Colors.black87,
  //                     ),
  //                   ),
  //                 );
  //               },
  //             ).toList(),
  //             onChanged:
  //                 (String? value) {
  //               setState(() {
  //                 selectedExperience =
  //                     value;

  //                 experienceError =
  //                     false;
  //               });
  //             },
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  // ============================================================
  // CATEGORY ADD
  // ============================================================

  //  Future<void> saveCompanyToFirestore({
  //   required String uid,
  //   required String name,
  //   required String mobile,
  //   required String companyName,
  //   required List<String> categories,
  //   required String categoryText,
  //   required String? experience,
  //   required double latitude,
  //   required double longitude,
  // }) async {
  //   try {
  //     final DocumentReference companyRef =
  //         firestore
  //             .collection('companies')
  //             .doc(uid);

  //     await companyRef.set(
  //       {
  //         'uid': uid,
  //         'companyId': uid,

  //         'name': name,
  //         'ownerName': name,

  //         'companyName': companyName,

  //         'mobile': mobile,

  //         'categories': categories,

  //         'category': categoryText,

  //         'searchKeywords': [
  //           ...categories.map(
  //             (category) =>
  //                 category.toLowerCase(),
  //           ),
  //           companyName.toLowerCase(),
  //           name.toLowerCase(),
  //         ],

  //         'experience': experience,

  //         'latitude': latitude,
  //         'longitude': longitude,

  //         'location': GeoPoint(
  //           latitude,
  //           longitude,
  //         ),

  //         'role': 'company',

  //         'isActive': true,

  //         'updatedAt':
  //             FieldValue.serverTimestamp(),
  //       },
  //       SetOptions(
  //         merge: true,
  //       ),
  //     );

  //     // ========================================================
  //     // MARK LOCAL SYNC COMPLETE
  //     // ========================================================

  //     try {
  //       final Box settingsBox =
  //           Hive.box('settings');

  //       await settingsBox.put(
  //         'companySyncPending',
  //         false,
  //       );
  //     } catch (e) {
  //       debugPrint(
  //         'Could not update sync status: $e',
  //       );
  //     }

  //     debugPrint(
  //       'Company Firestore save completed.',
  //     );
  //   } catch (e) {
  //     // ========================================================
  //     // IMPORTANT:
  //     // LOCAL PROFILE REMAINS AVAILABLE
  //     // ========================================================

  //     debugPrint(
  //       'Company Firestore background save failed: $e',
  //     );

  //     try {
  //       final Box settingsBox =
  //           Hive.box('settings');

  //       await settingsBox.put(
  //         'companySyncPending',
  //         true,
  //       );
  //     } catch (_) {}
  //   }
  // }

  // void addCustomCategory() {
  //   final String value =
  //       customCategoryController.text.trim();

  //   if (value.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text(
  //           'Please enter a category.',
  //         ),
  //       ),
  //     );
  //     return;
  //   }

  //   final List<String> allCategories = [
  //     ...defaultCategories,
  //     ...customCategories,
  //   ];

  //   String? existingCategory;

  //   for (final String category in allCategories) {
  //     if (category.toLowerCase() ==
  //         value.toLowerCase()) {
  //       existingCategory = category;
  //       break;
  //     }
  //   }

  //   final String categoryToUse =
  //       existingCategory ?? value;

  //   if (existingCategory == null) {
  //     setState(() {
  //       customCategories.add(value);
  //     });
  //   }

  //   if (!selectedCategories.any(
  //     (category) =>
  //         category.toLowerCase() ==
  //         categoryToUse.toLowerCase(),
  //   )) {
  //     setState(() {
  //       selectedCategories.add(
  //         categoryToUse,
  //       );

  //       categoryError = false;
  //     });
  //   }

  //   customCategoryController.clear();
  // }

  // ============================================================
  // CATEGORY FILTER
  // ============================================================

  // List<String> get filteredCategories {
  //   final List<String> allCategories = [
  //     ...defaultCategories,
  //     ...customCategories,
  //   ];

  //   if (categorySearchText.isEmpty) {
  //     return allCategories;
  //   }

  //   return allCategories.where(
  //     (category) {
  //       return category
  //           .toLowerCase()
  //           .contains(
  //             categorySearchText.toLowerCase(),
  //           );
  //     },
  //   ).toList();
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
import 'package:jober_india/jober_indiaScreens.dart/Privacy&Terms/privacy_terms_section.dart';
import 'package:jober_india/jober_indiaScreens.dart/common_profile_services.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_camera_capture.dart';

import 'package:jober_india/jober_indiaScreens.dart/screen_home.dart';
import 'package:jober_india/l10n/app_localizations.dart';
import 'package:jober_india/screens/location_localization.dart';

// class CompanyLocation {
//   final String placeName;
//   final double latitude;
//   final double longitude;

//   CompanyLocation({
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

//   factory CompanyLocation.fromMap(Map<String, dynamic> map) {
//     return CompanyLocation(
//       placeName: map['placeName'] ?? '',
//       latitude: (map['latitude'] ?? 0).toDouble(),
//       longitude: (map['longitude'] ?? 0).toDouble(),
//     );
//   }
// }

class CompanyLocation {
  final String placeName;
  final double? latitude;
  final double? longitude;

  CompanyLocation({
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

  factory CompanyLocation.fromMap(
    Map<String, dynamic> map,
  ) {
    return CompanyLocation(
      placeName: map['placeName']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

class CompanyLoginPage extends StatefulWidget {
  const CompanyLoginPage({super.key});

  @override
  State<CompanyLoginPage> createState() =>
      _CompanyLoginPageState();
}

class _CompanyLoginPageState
    extends State<CompanyLoginPage> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController mobileController =
      TextEditingController();

  final TextEditingController otpController =
      TextEditingController();

   final TextEditingController secondaryMobileController =
    TextEditingController();

  final TextEditingController companyNameController =
      TextEditingController();

  final TextEditingController _shopLocationController =
    TextEditingController();

  final TextEditingController categorySearchController =
      TextEditingController();

  final TextEditingController customCategoryController =
      TextEditingController();

  // ============================================================
  // FOCUS NODES
  // ============================================================

  final FocusNode nameFocus = FocusNode();
  final FocusNode mobileFocus = FocusNode();
  final FocusNode otpFocus = FocusNode();
  final FocusNode companyNameFocus = FocusNode();
  static const Color green =
      Color(0xFF138808);

  // static const Color submitGreen =
  //     Color(0xFF159B16);

  static const Color darkText =
      Color(0xFF202124);

  static const Color lightFill =
      Color(0xFFF9F9F9);
  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth auth = FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

   File? profilePhoto;
  String? profilePhotoUrl;
bool isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();

  bool isCategoryDropdownOpen = false;

  String categorySearchText = '';

  bool categoryError = false;

  List<String> filteredCategories = [];

  bool privacyPolicyAccepted = false;
  String? privacyPolicyError;

   // ============================================================
  // SHOP TIMINGS
  // ============================================================

  TimeOfDay? openingTime;
  TimeOfDay? closingTime;
  bool isOpen24Hours = false;

  // ==========================================================
  // LOCATION
  // ==========================================================
CompanyLocation? currentLocation;

bool isGettingLocation = false;
bool isSearchingLocation = false;

// Used to invalidate an older location request
int _locationRequestId = 0;

  
  // ============================================================
  // EXPERIENCE
  // ============================================================

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

  String? selectedExperience;

  bool experienceError = false;

  // ============================================================
  // OTP
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
  // ===============================================================
  // TIMER
  // ===============================================================

  int remainingSeconds = 0;

  // ============================================================
  // LOCATION
  // ============================================================

  Position? currentPosition;

  bool locationAttached = false;
  bool gettingLocation = false;

  bool locationError = false;

// ============================================================
// OTHER ERRORS
// ============================================================
    String? nameError;

//bool nameError = false;
bool mobileError = false;
bool companyNameError = false;
bool secondaryMobileError = false;

bool timingError = false;
String timingErrorMessage = '';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    filteredCategories =
        List<String>.from(
      defaultCategories,
    );

    filteredStates = List<String>.from(indiaStates);
    loadDistricts();

    categorySearchController.addListener(
      _refreshCategorySearch,
    );
  }

//       final TextEditingController nearestCityController =
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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    timer?.cancel();

    categorySearchController.removeListener(
      _refreshCategorySearch,
    );

    nameController.dispose();
    mobileController.dispose();
    otpController.dispose();
    companyNameController.dispose();
    categorySearchController.dispose();
    customCategoryController.dispose();
    secondaryMobileController.dispose();
    stateSearchController.dispose();
    districtSearchController.dispose();

    nameFocus.dispose();
    mobileFocus.dispose();
    otpFocus.dispose();
    companyNameFocus.dispose();

    super.dispose();
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
  // CATEGORY
  // ============================================================

  final List<String> defaultCategories = [
    'Manufacturing Company',
    'Packing Company',
  ];

  final List<String> customCategories = [];

  final List<String> selectedCategories = [];
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
                                  'Select Company categories',
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


  void _refreshCategorySearch() {
    if (!mounted) return;

    setState(() {
      categorySearchText =
          categorySearchController.text.trim();
    });
  }

   List<String> get allCategories {

    final List<String> result = [];

    for (final category in defaultCategories) {

      if (!result.contains(category)) {

        result.add(category);

      }

    }

    for (final category in customCategories) {
      if (!result.contains(category)) {
        result.add(category);}}
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

              hintText:'Enter Company category',

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
  // LOCATION SECTION
  // ============================================================

  Widget locationSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Consulting Location',
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
                      'Add your Consultation location',
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
                              : 'Add Consultation Location',
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
            labelText: 'Consultation Location',
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
  currentLocation = CompanyLocation(
    placeName: placeName.trim(),
    latitude: null,
    longitude: null,
  );
  locationError = false;
  isGettingLocation = false;
  isSearchingLocation = false;
});

showMessage(
  'Consultation location added.',
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
  currentLocation = CompanyLocation(
    placeName: placeName,
    latitude: position.latitude,
    longitude: position.longitude,
  );

  locationError = false;
});

    showMessage(
      'Company location added.',
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
    }

    timingError = false;
    timingErrorMessage = '';
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
    color: timingError
        ? Colors.red
        : Colors.grey.shade300,
    width: timingError ? 2 : 1.5,
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
      // ============================================================
      // TIMING ERROR MESSAGE
      // ============================================================

      if (timingError)
        Padding(
          padding: const EdgeInsets.only(
            left: 12,
            top: 6,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 17,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  timingErrorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
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
      timingError = false;
      timingErrorMessage = '';
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
      timingError = false;
      timingErrorMessage = '';
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

  // ============================================================
// SHOP TIMING VALIDATION
// ============================================================

bool validateShopTiming() {
  if (isOpen24Hours) {
    timingError = false;
    timingErrorMessage = '';
    return true;
  }

  if (openingTime == null && closingTime == null) {
    timingError = true;
    timingErrorMessage =
        'Please select opening and closing time.';
    return false;
  }

  if (openingTime == null) {
    timingError = true;
    timingErrorMessage =
        'Please select opening time.';
    return false;
  }

  if (closingTime == null) {
    timingError = true;
    timingErrorMessage =
        'Please select closing time.';
    return false;
  }

  final int openingMinutes =
      openingTime!.hour * 60 +
      openingTime!.minute;

  final int closingMinutes =
      closingTime!.hour * 60 +
      closingTime!.minute;

  if (openingMinutes == closingMinutes) {
    timingError = true;
    timingErrorMessage =
        'Opening and closing time cannot be the same.';
    return false;
  }

  timingError = false;
  timingErrorMessage = '';

  return true;
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
  // SECTION TITLE
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

Future<void> saveCompanyToFirestore({
  required String uid,
  required String name,
  required String mobile,
  required String secondaryMobile,
  required String companyName,
  required List<String> categories,
  required String categoryText,
  required String? experience,
  required CompanyLocation? currentLocation,
  required bool isOpen24Hours,
  String? openingTime,
  String? closingTime,
  String? profilePhotoUrl,
}) async {
  try {
    debugPrint('========================================');
    debugPrint('COMPANY FIRESTORE SAVE START');
    debugPrint('UID: $uid');
    debugPrint('========================================');

    final Map<String, dynamic> companyData = {
      'uid': uid,
      'companyId': uid,

      'name': name,
      'ownerName': name,

      'companyName': companyName,

      'mobile': mobile,
      'secondaryMobile': secondaryMobile,

      // ========================================================
// STATE / DISTRICT / NEAREST TOWN
// ========================================================

'state': selectedState!.trim(),
'district': selectedDistrict!.trim(),
'nearestTown': nearestCityController.text.trim(),


      'categories': categories,
      'category': categoryText,

      'searchKeywords': [
        ...categories.map(
          (category) => category.toLowerCase(),
        ),
        companyName.toLowerCase(),
        name.toLowerCase(),
      ],

      if (experience != null &&
          experience.isNotEmpty)
        'experience': experience,

      // ========================================================
      // SHOP TIMING
      // ========================================================

      'isOpen24Hours': isOpen24Hours,

      'openingTime': isOpen24Hours
          ? null
          : openingTime,

      'closingTime': isOpen24Hours
          ? null
          : closingTime,

      // ========================================================
      // LOCATION
      // ========================================================
 
       'location': currentLocation?.toMap(),

      // ========================================================
      // ROLE / STATUS
      // ========================================================

'role': 'company',
'isActive': true,
'isOnline': true,
'onlineUpdatedAt': FieldValue.serverTimestamp(),
      // ========================================================
      // PROFILE PHOTO
      // ========================================================

      if (profilePhotoUrl != null &&
          profilePhotoUrl.isNotEmpty)
        'profilePhotoUrl': profilePhotoUrl,

      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    await firestore
        .collection('companies')
        .doc(uid)
        .set(
          companyData,
          SetOptions(merge: true),
        );
    await syncCompanyCategoriesOnRegistration(
  uid: uid,
  categories: categories,
);

    debugPrint('========================================');
    debugPrint('COMPANY FIRESTORE SAVE SUCCESS');
    debugPrint('UID: $uid');
    debugPrint('========================================');
  } on FirebaseException catch (e) {
    debugPrint('========================================');
    debugPrint('COMPANY FIRESTORE ERROR');
    debugPrint('CODE: ${e.code}');
    debugPrint('MESSAGE: ${e.message}');
    debugPrint('========================================');

    rethrow;
  } catch (e) {
    debugPrint('========================================');
    debugPrint('COMPANY FIRESTORE UNKNOWN ERROR');
    debugPrint('$e');
    debugPrint('========================================');

    rethrow;
  }
}
Future<void> syncCompanyCategoriesOnRegistration({
  required String uid,
  required List<String> categories,
}) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  const List<String> defaultCategories = [
    'Manufacturing Company',
    'Packing Company',
  ];

  // Avoid duplicate categories, ignoring capitalization.
  final Map<String, String> uniqueCategories = {};

  for (final String item in categories) {
    final String name = item.trim();

    if (name.isNotEmpty) {
      uniqueCategories.putIfAbsent(
        name.toLowerCase(),
        () => name,
      );
    }
  }

  for (final String name in uniqueCategories.values) {
    final bool isDefault = defaultCategories.any(
      (String item) =>
          item.toLowerCase() == name.toLowerCase(),
    );

    final String categoryId =
        Uri.encodeComponent(name.toLowerCase());

    final DocumentReference<Map<String, dynamic>> categoryRef =
        db.collection('company_categories').doc(categoryId);

    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(categoryRef);
      final data = snapshot.data();

      final List<String> companyUids = List<String>.from(
        data?['companyUids'] ?? <String>[],
      );

      if (!companyUids.contains(uid)) {
        companyUids.add(uid);
      }

      transaction.set(
        categoryRef,
        {
          'name': data?['name'] ?? name,
          'isCustom': isDefault
              ? false
              : (data?['isCustom'] ?? true),
          'companyUids': companyUids,
          'updatedAt': FieldValue.serverTimestamp(),
          if (!snapshot.exists)
            'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    debugPrint(
      'COMPANY CATEGORY SYNCED: $name | UID: $uid',
    );
  }
}
  // ============================================================
  // SAVE BASIC COMPANY DATA TO HIVE
  // ============================================================

Future<void> saveBasicCompanyToHive() async {
  try {
    final Box settingsBox =
        Hive.box('settings');

    await settingsBox.put(
      'companyName',
      companyNameController.text.trim(),
    );

    await settingsBox.put(
      'companyOwnerName',
      nameController.text.trim(),
    );

    await settingsBox.put(
      'companyMobile',
      mobileController.text.trim(),
    );

    await settingsBox.put(
      'companySecondaryMobile',
      secondaryMobileController.text.trim(),
    );

 // ==========================================================
// COMPANY STATE / DISTRICT / NEAREST TOWN
// ==========================================================

await settingsBox.put(
  'companyState',
  selectedState!.trim(),
);

await settingsBox.put(
  'companyDistrict',
  selectedDistrict!.trim(),
);

await settingsBox.put(
  'companyNearestTown',
  nearestCityController.text.trim(),
);

    await settingsBox.put(
      'companyRole',
      'company',
    );

    await settingsBox.put(
      'companyCategories',
      List<String>.from(
        selectedCategories,
      ),
    );

    await settingsBox.put(
      'companyCategory',
      selectedCategories.join(', '),
    );

    await settingsBox.put(
      'companyExperience',
      selectedExperience,
    );

    // ==========================================================
    // SHOP TIMING
    // ==========================================================

    await settingsBox.put(
      'companyIsOpen24Hours',
      isOpen24Hours,
    );

    await settingsBox.put(
      'companyOpeningTime',
      openingTime == null
          ? null
          : timeToString(openingTime!),
    );

    await settingsBox.put(
      'companyClosingTime',
      closingTime == null
          ? null
          : timeToString(closingTime!),
    );

    // ==========================================================
    // LOCATION
    // ==========================================================

    final User? user =
        auth.currentUser;

    if (user != null) {
      await settingsBox.put(
        'companyUid',
        user.uid,
      );
    }

 await settingsBox.put(
  'companyLocation',
  currentLocation?.toMap(),
);
 
    // ==========================================================
    // PROFILE PHOTO
    // ==========================================================

    if (profilePhotoUrl != null &&
        profilePhotoUrl!.isNotEmpty) {
      await settingsBox.put(
        'companyProfilePhotoUrl',
        profilePhotoUrl,
      );
    }

    debugPrint(
      'Company data saved locally.',
    );
  } catch (e) {
    debugPrint(
      'Company Hive save error: $e',
    );
  }
}
  // ============================================================
  // SUBMIT PROFILE
  // ============================================================

Future<void> submitProfile() async {
  if (isSubmitting) return;

  bool hasError = false;

  // ============================================================
  // NAME
  // ============================================================

  if (nameController.text.trim().isEmpty) {
    nameError = 'Please enter your name.';
    hasError = true;
  } else {
    nameError = null;
  }

  // ============================================================
  // COMPANY NAME
  // ============================================================

  if (companyNameController.text.trim().isEmpty) {
    companyNameError = true;
    hasError = true;
  } else {
    companyNameError = false;
  }

  // ============================================================
  // PRIMARY MOBILE
  // ============================================================

  final String mobile =
      mobileController.text.trim();

  if (mobile.length != 10) {
    mobileError = true;
    hasError = true;
  } else {
    mobileError = false;
  }

  // ============================================================
  // SECONDARY MOBILE
  // ============================================================

  final String secondaryMobile =
      secondaryMobileController.text.trim();

  if (secondaryMobile.length != 10) {
    secondaryMobileError = true;
    hasError = true;
  } else {
    secondaryMobileError = false;
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
  // COMPANY CATEGORY
  // ============================================================

  if (selectedCategories.isEmpty) {
    categoryError = true;
    hasError = true;
  } else {
    categoryError = false;
  }

  // ============================================================
  // SHOP TIMING
  // ============================================================

  if (!validateShopTiming()) {
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

  // ============================================================
  // PRIVACY POLICY / TERMS
  // ============================================================

  if (!privacyPolicyAccepted) {
    privacyPolicyError =
        'Please accept the Privacy Policy and Terms & Conditions.';

    hasError = true;
  } else {
    privacyPolicyError = null;
  }

  // ============================================================
  // REFRESH VALIDATION UI
  // ============================================================

  if (!mounted) return;

  setState(() {});

  // ============================================================
  // STOP IF VALIDATION FAILED
  // ============================================================

  if (hasError) {
    showMessage(
      'Please complete all required fields.',
      isError: true,
    );

    return;
  }

  // ============================================================
  // OTP VERIFIED
  // ============================================================

  // IMPORTANT:
  // Do NOT check otpSent here.
  // After successful verification your code sets:
  //
  // otpSent = false
  //
  // Therefore otpVerified is the correct state to check.

  if (!otpVerified) {
    showMessage(
      'Please verify your primary mobile number with OTP.',
      isError: true,
    );

    return;
  }

  // ============================================================
  // FIREBASE USER
  // ============================================================

  final User? user =
      auth.currentUser;

  if (user == null) {
    showMessage(
      'Authentication failed. Please verify OTP again.',
      isError: true,
    );

    return;
  }

  // ============================================================
  // START SUBMITTING
  // ============================================================

  if (!mounted) return;

  setState(() {
    isSubmitting = true;
  });

  try {
    // ==========================================================
    // CAPTURE DATA
    // ==========================================================

    final String uid =
        user.uid;

    final String name =
        nameController.text.trim();

    final String companyName =
        companyNameController.text.trim();

    final List<String> categories =
        List<String>.from(
      selectedCategories,
    );

    final String categoryText =
        categories.join(', ');

    final String? experience =
        selectedExperience;

    // final double latitude =
    //     currentLocation!.latitude;

    // final double longitude =
    //     currentLocation!.longitude;

    // final String locationName =
    //     currentLocation!.placeName;

    final String? openingTimeText =
        openingTime == null
            ? null
            : timeToString(openingTime!);

    final String? closingTimeText =
        closingTime == null
            ? null
            : timeToString(closingTime!);

    // ==========================================================
    // PROFILE PHOTO
    // ==========================================================

    String? uploadedPhotoUrl =
        profilePhotoUrl;

    if (profilePhoto != null) {
      uploadedPhotoUrl =
          await uploadProfilePhoto(uid);
    }

    // ==========================================================
    // 1. SAVE LOCAL DATA
    // ==========================================================

    await saveBasicCompanyToHive();

    // ==========================================================
    // 2. SAVE LOGIN STATUS
    // ==========================================================

    await CommonProfileService.saveLogin(
      uid: uid,
      name: name,
      mobile: mobile,
      role: 'company',
    );

    // ==========================================================
    // 3. SAVE FIRESTORE
    // ==========================================================

    await saveCompanyToFirestore(
      uid: uid,
      name: name,
      mobile: mobile,
      secondaryMobile: secondaryMobile,
      companyName: companyName,
      categories: categories,
      categoryText: categoryText,
      experience: experience,
      // latitude: latitude,
      // longitude: longitude,
      // locationName: locationName,
      currentLocation: currentLocation,
      isOpen24Hours: isOpen24Hours,
      openingTime: openingTimeText,
      closingTime: closingTimeText,
      profilePhotoUrl: uploadedPhotoUrl,
    );

    // ==========================================================
    // 4. SAVE PHOTO URL LOCALLY
    // ==========================================================

    if (uploadedPhotoUrl != null &&
        uploadedPhotoUrl.isNotEmpty) {
      final Box settingsBox =
          Hive.box('settings');

      await settingsBox.put(
        'companyProfilePhotoUrl',
        uploadedPhotoUrl,
      );
    }

    // ==========================================================
    // 5. STOP LOADING
    // ==========================================================

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    // ==========================================================
    // 6. GO TO HOME
    // ==========================================================

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
      'Company submit error: $e',
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    showMessage(
      'Could not save company profile. Please try again.',
      isError: true,
    );
  }
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
        'Secondary Mobile Number ',
        style: TextStyle(
          color: Color(0xFF252525),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 8),

      TextField(
        controller: secondaryMobileController,
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
          hasError: secondaryMobileError,
          icon: Icons.phone_android_outlined,
        ).copyWith(
          counterText: '',
        ),
      ),

      if (secondaryMobileError)
         Padding(
          padding: EdgeInsets.only(
            left: 12,
            top: 5,
          ),
          child: Text(AppLocalizations.of(context)!.enteradigitmobilenumber,
          // 'Enter a valid 10-digit secondary mobile number.',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
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

      const SizedBox(height: 3),

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
        if (mobileError)
   Padding(
    padding: EdgeInsets.only(
      left: 12,
      top: 5,
    ),
    child: Text(AppLocalizations.of(context)!.enteradigitmobilenumber,
    //  'Enter a valid 10-digit mobile number.',
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
      backgroundColor: Colors.white,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation: 0,

        leading: IconButton(
          onPressed:
              isSubmitting
                  ? null
                  : () {
                      Navigator.pop(
                        context,
                      );
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
                text: 'Company ',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
                  color: Color(
                    0xFF08744F,
                  ),
                ),
              ),
              TextSpan(
                text:  AppLocalizations.of(context)!.registration,
                //'Registration',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
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
          physics:
              const BouncingScrollPhysics(),

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
              // ==================================================
              // HEADER
              // ==================================================

              const Text(
                'Company Profile',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Fill in your details to create your company profile',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // NAME
              // ==================================================

              sectionTitle(
                'Your Name ',
              ),

              const SizedBox(height: 6),

_nameField(),
              const SizedBox(height: 20),

              // ==================================================
              // COMPANY NAME
              // ==================================================

              sectionTitle(
                'Company Name ',
              ),

              const SizedBox(height: 6),

              TextField(
                controller:
                    companyNameController,
                focusNode:
                    companyNameFocus,
                textCapitalization:
                    TextCapitalization.words,
                textInputAction:
                    TextInputAction.next,
                onChanged:
                    (String value) {
                  if (companyNameError) {
                    setState(() {
                      companyNameError =
                          false;
                    });
                  }
                },
                decoration:
                    fieldDecoration(
                  hintText:
                      'Enter company name',
                  hasError:
                      companyNameError ,
                  icon:
                      Icons.business_outlined,
                ),
              ),
               if (companyNameError)
  const Padding(
    padding: EdgeInsets.only(
      left: 12,
      top: 5,
    ),
    child: Text(
      'Enter Your Company Name.',
      style: TextStyle(
        color: Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),

              const SizedBox(height: 20),

              // ==================================================
              // MOBILE
              // ==================================================

              sectionTitle(
                'Mobile Number ',
              ),

              const SizedBox(height: 6),

              mobileSection(),

              const SizedBox(height: 14),

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
              // CATEGORY
              // ==================================================
sectionTitle('Select Category'),
              const SizedBox(height: 8),
              categorySection(),
              const SizedBox(height: 20),

              shopTimingSection(),

              const SizedBox(height: 20),

              // ==================================================
              // EXPERIENCE
              // ================================================

              // experienceSection(),
              //  const SizedBox(height: 22)
              _profilePhotoSection(),
              const SizedBox(height: 20),

              // ==================================================
              // LOCATION
              // ==================================================

              locationSection(),

              const SizedBox(height: 30),
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
              // SUBMIT PROFILE
              // ==================================================

              SizedBox(
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
                            strokeWidth: 2.5,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}



  // void showMessage(String message,{
  //   bool error = false,
  // }) {
  //   if (!mounted) return;

  //   ScaffoldMessenger.of(context)
  //   ..hideCurrentSnackBar()
  //   ..showSnackBar(   
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


//   Widget locationSection() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Company Location',
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
//            border: Border.all(
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
//       currentPosition = null;
//       isGettingLocation = false;
//       isSearchingLocation = false;
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
//         if (locationError)
//   const Padding(
//     padding: EdgeInsets.only(
//       left: 12,
//       top: 6,
//     ),
//     child: Text(
//       'Please add your Company location.',
//       style: TextStyle(
//         color: Colors.red,
//         fontSize: 12,
//         fontWeight: FontWeight.w500,
//       ),
//     ),
//   ),
//       ],
//     );
//   }
//   // ==========================================================
//   // GET CURRENT LOCATION
//   // ==========================================================

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

//     if (!serviceEnabled) {
//   if (mounted) {
//     setState(() {
//       isGettingLocation = false;
//     });
//   }

//   showMessage(
//     'Please turn on location services.',
//     isError: true,
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
//         isError: true,
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
//   currentPosition = position;

//   currentLocation = CompanyLocation(
//     placeName: placeName,
//     latitude: position.latitude,
//     longitude: position.longitude,
//   );

//   locationError = false;
// });

//     showMessage(
//       'Company location added.',
//     );
//   } catch (e) {
//     if (!mounted || requestId != _locationRequestId) return;

//     showMessage(
//       'Unable to get your location.',
//       isError: true,
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
