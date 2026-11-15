// import 'dart:async';
// import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:image_picker/image_picker.dart';

// class ScreenLabLogin extends StatefulWidget {
//   const ScreenLabLogin({super.key});

//   @override
//   State<ScreenLabLogin> createState() =>
//       _ScreenLabLoginState();
// }

// class _ScreenLabLoginState extends State<ScreenLabLogin> {
//   final _formKey = GlobalKey<FormState>();

//   final TextEditingController usernameController =
//       TextEditingController();

//       final Geocoding geocoding =
//       Geocoding();

//   final TextEditingController mobileController =
//       TextEditingController();

//   final TextEditingController categorySearchController =
//       TextEditingController();

//   final ImagePicker imagePicker = ImagePicker();

//   bool isSubmitting = false;
//   bool isGettingCurrentLocation = false;

//   File? selectedPhoto;

//   Position? currentPosition;
//   String? currentLocationAddress;

//   final List<String> defaultCategories = [
//     'Blood Checking Lab',
//     'Water Checking Lab',
//   ];

//   final List<String> selectedCategories = [];

//   final List<String> customCategories = [];

//   final List<LabBranchLocation> branchLocations = [];

//   String categorySearchText = '';

//   @override
//   void initState() {
//     super.initState();

//     categorySearchController.addListener(() {
//       if (!mounted) return;

//       setState(() {
//         categorySearchText =
//             categorySearchController.text.trim().toLowerCase();
//       });
//     });
//   }

//   @override
//   void dispose() {
//     usernameController.dispose();
//     mobileController.dispose();
//     categorySearchController.dispose();

//     super.dispose();
//   }

//   List<String> get allCategories {
//     return [
//       ...defaultCategories,
//       ...customCategories,
//     ];
//   }

//   List<String> get filteredCategories {
//     if (categorySearchText.isEmpty) {
//       return allCategories;
//     }

//     return allCategories.where((category) {
//       return category.toLowerCase().contains(categorySearchText);
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         title: const Text(
//           'Lab Registration',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.green.shade700,
//         foregroundColor: Colors.white,
//       ),
//       body: SafeArea(
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             padding: const EdgeInsets.all(16),
//             children: [
//               _buildHeader(),

//               const SizedBox(height: 20),

//               _buildUsernameField(),

//               const SizedBox(height: 16),

//               _buildMobileField(),

//               const SizedBox(height: 24),

//               _buildCategorySection(),

//               const SizedBox(height: 24),

//               _buildPhotoSection(),

//               const SizedBox(height: 24),

//               _buildCurrentLocationSection(),

//               const SizedBox(height: 24),

//               _buildBranchSection(),

//               const SizedBox(height: 30),

//               _buildSubmitButton(),

//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Colors.green.shade700,
//             Colors.green.shade500,
//           ],
//         ),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: const Column(
//         children: [
//           Icon(
//             Icons.biotech,
//             size: 55,
//             color: Colors.white,
//           ),
//           SizedBox(height: 10),
//           Text(
//             'Register Your Laboratory',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 6),
//           Text(
//             'Please provide the required laboratory details',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: Colors.white70,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUsernameField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _sectionTitle(
//           'Username',
//           required: true,
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: usernameController,
//           textInputAction: TextInputAction.next,
//           decoration: InputDecoration(
//             hintText: 'Enter username',
//             prefixIcon: const Icon(Icons.person_outline),
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide.none,
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide(
//                 color: Colors.grey.shade300,
//               ),
//             ),
//           ),
//           validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//               return 'Please enter username';
//             }

//             if (value.trim().length < 3) {
//               return 'Username must contain at least 3 characters';
//             }

//             return null;
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildMobileField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _sectionTitle(
//           'Mobile Number',
//           required: true,
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: mobileController,
//           keyboardType: TextInputType.phone,
//           maxLength: 10,
//           decoration: InputDecoration(
//             counterText: '',
//             hintText: 'Enter 10 digit mobile number',
//             prefixText: '+91  ',
//             prefixIcon: const Icon(Icons.phone_outlined),
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide.none,
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide(
//                 color: Colors.grey.shade300,
//               ),
//             ),
//           ),
//           validator: (value) {
//             final mobile = value?.trim() ?? '';

//             if (mobile.isEmpty) {
//               return 'Please enter mobile number';
//             }

//             if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile)) {
//               return 'Enter a valid 10 digit mobile number';
//             }

//             return null;
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildCategorySection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _sectionTitle(
//           'Lab Category',
//           required: true,
//         ),

//         const SizedBox(height: 5),

//         Text(
//           'Select at least one category',
//           style: TextStyle(
//             fontSize: 13,
//             color: Colors.grey.shade600,
//           ),
//         ),

//         const SizedBox(height: 12),

//         TextField(
//           controller: categorySearchController,
//           decoration: InputDecoration(
//             hintText: 'Search category',
//             prefixIcon: const Icon(Icons.search),
//             suffixIcon: categorySearchController.text.isNotEmpty
//                 ? IconButton(
//                     icon: const Icon(Icons.clear),
//                     onPressed: () {
//                       categorySearchController.clear();
//                     },
//                   )
//                 : null,
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide.none,
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide(
//                 color: Colors.grey.shade300,
//               ),
//             ),
//           ),
//         ),

//         const SizedBox(height: 12),

//         if (filteredCategories.isEmpty)
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: const Text(
//               'No category found.',
//               style: TextStyle(
//                 color: Colors.grey,
//               ),
//             ),
//           ),

//         ...filteredCategories.map(
//           (category) {
//             final isSelected =
//                 selectedCategories.contains(category);

//             return Container(
//               margin: const EdgeInsets.only(bottom: 8),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(
//                   color: isSelected
//                       ? Colors.green
//                       : Colors.grey.shade300,
//                   width: isSelected ? 1.5 : 1,
//                 ),
//               ),
//               child: CheckboxListTile(
//                 value: isSelected,
//                 activeColor: Colors.green.shade700,
//                 title: Text(
//                   category,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 onChanged: (value) {
//                   setState(() {
//                     if (value == true) {
//                       selectedCategories.add(category);
//                     } else {
//                       selectedCategories.remove(category);
//                     }
//                   });
//                 },
//               ),
//             );
//           },
//         ),

//         const SizedBox(height: 5),

//         OutlinedButton.icon(
//           onPressed: isSubmitting
//               ? null
//               : () {
//                   _showAddCustomCategoryDialog();
//                 },
//           icon: const Icon(Icons.add),
//           label: const Text(
//             'Add Your Own Category',
//           ),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: Colors.green.shade700,
//             minimumSize: const Size(
//               double.infinity,
//               50,
//             ),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(14),
//             ),
//           ),
//         ),

//         if (selectedCategories.isEmpty)
//           Padding(
//             padding: const EdgeInsets.only(
//               top: 8,
//               left: 4,
//             ),
//             child: Text(
//               'Please select at least one lab category',
//               style: TextStyle(
//                 color: Colors.red.shade700,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildPhotoSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _sectionTitle(
//           'User Photo',
//           required: false,
//         ),

//         const SizedBox(height: 8),

//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: Colors.grey.shade300,
//             ),
//           ),
//           child: Row(
//             children: [
//               CircleAvatar(
//                 radius: 32,
//                 backgroundColor: Colors.green.shade50,
//                 backgroundImage: selectedPhoto != null
//                     ? FileImage(selectedPhoto!)
//                     : null,
//                 child: selectedPhoto == null
//                     ? Icon(
//                         Icons.person,
//                         size: 35,
//                         color: Colors.green.shade700,
//                       )
//                     : null,
//               ),

//               const SizedBox(width: 15),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Profile Photo',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Optional',
//                       style: TextStyle(
//                         color: Colors.grey.shade600,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               ElevatedButton(
//                 onPressed: isSubmitting
//                     ? null
//                     : _pickPhoto,
//                 child: Text(
//                   selectedPhoto == null
//                       ? 'Add Photo'
//                       : 'Change',
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCurrentLocationSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _sectionTitle(
//           'Current Location',
//           required: true,
//         ),

//         const SizedBox(height: 8),

//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: currentPosition != null
//                   ? Colors.green
//                   : Colors.grey.shade300,
//             ),
//           ),
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                     currentPosition != null
//                         ? Icons.location_on
//                         : Icons.location_off,
//                     color: currentPosition != null
//                         ? Colors.green.shade700
//                         : Colors.grey,
//                     size: 32,
//                   ),

//                   const SizedBox(width: 12),

//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment:
//                           CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           currentPosition != null
//                               ? 'Current location attached'
//                               : 'Current location required',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: currentPosition != null
//                                 ? Colors.green.shade700
//                                 : Colors.black87,
//                           ),
//                         ),

//                         if (currentLocationAddress != null)
//                           Padding(
//                             padding:
//                                 const EdgeInsets.only(top: 5),
//                             child: Text(
//                               currentLocationAddress!,
//                               maxLines: 2,
//                               overflow:
//                                   TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 color: Colors.grey.shade600,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 14),

//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: isGettingCurrentLocation ||
//                           isSubmitting
//                       ? null
//                       : _attachCurrentLocation,
//                   icon: isGettingCurrentLocation
//                       ? const SizedBox(
//                           height: 18,
//                           width: 18,
//                           child:
//                               CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : const Icon(Icons.my_location),
//                   label: Text(
//                     currentPosition == null
//                         ? 'Attach Current Location'
//                         : 'Update Current Location',
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor:
//                         Colors.green.shade700,
//                     foregroundColor: Colors.white,
//                     minimumSize: const Size(
//                       double.infinity,
//                       50,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius:
//                           BorderRadius.circular(14),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildBranchSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _sectionTitle(
//           'Other Branch Locations',
//           required: false,
//         ),

//         const SizedBox(height: 5),

//         Text(
//           'Optional • You can add up to 10 branches',
//           style: TextStyle(
//             color: Colors.grey.shade600,
//             fontSize: 13,
//           ),
//         ),

//         const SizedBox(height: 12),

//         if (branchLocations.isNotEmpty)
//           ...List.generate(
//             branchLocations.length,
//             (index) {
//               final branch = branchLocations[index];

//               return Container(
//                 margin: const EdgeInsets.only(bottom: 10),
//                 padding: const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(15),
//                   border: Border.all(
//                     color: Colors.grey.shade300,
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       backgroundColor:
//                           Colors.green.shade50,
//                       child: Text(
//                         '${index + 1}',
//                         style: TextStyle(
//                           color: Colors.green.shade700,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),

//                     const SizedBox(width: 12),

//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment:
//                             CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Branch Location',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             branch.address,
//                             maxLines: 2,
//                             overflow:
//                                 TextOverflow.ellipsis,
//                             style: TextStyle(
//                               color:
//                                   Colors.grey.shade600,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     IconButton(
//                       onPressed: isSubmitting
//                           ? null
//                           : () {
//                               setState(() {
//                                 branchLocations
//                                     .removeAt(index);
//                               });
//                             },
//                       icon: const Icon(
//                         Icons.delete_outline,
//                         color: Colors.red,
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),

//         if (branchLocations.length < 10)
//           OutlinedButton.icon(
//             onPressed: isSubmitting
//                 ? null
//                 : _addBranchLocation,
//             icon: const Icon(
//               Icons.add_location_alt_outlined,
//             ),
//             label: Text(
//               'Add Other Branch Location '
//               '(${branchLocations.length}/10)',
//             ),
//             style: OutlinedButton.styleFrom(
//               foregroundColor: Colors.green.shade700,
//               minimumSize: const Size(
//                 double.infinity,
//                 52,
//               ),
//               shape: RoundedRectangleBorder(
//                 borderRadius:
//                     BorderRadius.circular(14),
//               ),
//             ),
//           )
//         else
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(15),
//             decoration: BoxDecoration(
//               color: Colors.orange.shade50,
//               borderRadius:
//                   BorderRadius.circular(14),
//             ),
//             child: const Text(
//               'Maximum 10 branch locations added.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildSubmitButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: 56,
//       child: ElevatedButton(
//         onPressed: isSubmitting
//             ? null
//             : _submitLabProfile,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.green.shade700,
//           foregroundColor: Colors.white,
//           disabledBackgroundColor:
//               Colors.green.shade300,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//         ),
//         child: isSubmitting
//             ? const Row(
//                 mainAxisAlignment:
//                     MainAxisAlignment.center,
//                 children: [
//                   SizedBox(
//                     height: 22,
//                     width: 22,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2.5,
//                       color: Colors.white,
//                     ),
//                   ),
//                   SizedBox(width: 12),
//                   Text(
//                     'Submitting...',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               )
//             : const Text(
//                 'SUBMIT PROFILE',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//       ),
//     );
//   }

//   Widget _sectionTitle(
//     String title, {
//     required bool required,
//   }) {
//     return RichText(
//       text: TextSpan(
//         text: title,
//         style: const TextStyle(
//           color: Colors.black87,
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//         ),
//         children: [
//           if (required)
//             const TextSpan(
//               text: ' *',
//               style: TextStyle(
//                 color: Colors.red,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//   Future<void> _showAddCustomCategoryDialog() async {
//     final controller = TextEditingController();

//     await showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           title: const Text(
//             'Add Your Own Category',
//           ),
//           content: TextField(
//             controller: controller,
//             textCapitalization:
//                 TextCapitalization.words,
//             decoration: const InputDecoration(
//               hintText: 'Enter lab category',
//               prefixIcon: Icon(
//                 Icons.category_outlined,
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(dialogContext);
//               },
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 final category =
//                     controller.text.trim();

//                 if (category.isEmpty) {
//                   return;
//                 }

//                 if (allCategories.any(
//                   (item) =>
//                       item.toLowerCase() ==
//                       category.toLowerCase(),
//                 )) {
//                   ScaffoldMessenger.of(context)
//                       .showSnackBar(
//                     const SnackBar(
//                       content: Text(
//                         'This category already exists.',
//                       ),
//                     ),
//                   );
//                   return;
//                 }

//                 setState(() {
//                   customCategories.add(category);
//                   selectedCategories.add(category);
//                 });

//                 Navigator.pop(dialogContext);
//               },
//               child: const Text('Add'),
//             ),
//           ],
//         );
//       },
//     );

//     controller.dispose();
//   }

//   Future<void> _pickPhoto() async {
//     try {
//       final XFile? pickedFile =
//           await imagePicker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 70,
//         maxWidth: 1000,
//         maxHeight: 1000,
//       );

//       if (pickedFile == null) {
//         return;
//       }

//       if (!mounted) return;

//       setState(() {
//         selectedPhoto = File(pickedFile.path);
//       });
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Unable to select photo: $e',
//           ),
//         ),
//       );
//     }
//   }

//   Future<bool> _checkLocationPermission() async {
//     bool serviceEnabled =
//         await Geolocator.isLocationServiceEnabled();

//     if (!serviceEnabled) {
//       if (!mounted) return false;

//       await showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text(
//               'Location is disabled',
//             ),
//             content: const Text(
//               'Please turn on location services '
//               'and try again.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 child: const Text('OK'),
//               ),
//             ],
//           );
//         },
//       );

//       return false;
//     }

//     LocationPermission permission =
//         await Geolocator.checkPermission();

//     if (permission == LocationPermission.denied) {
//       permission =
//           await Geolocator.requestPermission();
//     }

//     if (permission ==
//             LocationPermission.denied ||
//         permission ==
//             LocationPermission.deniedForever) {
//       if (!mounted) return false;

//       await showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text(
//               'Location permission required',
//             ),
//             content: const Text(
//               'Current location is mandatory for '
//               'lab registration. Please allow '
//               'location permission.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   Navigator.pop(context);

//                   await Geolocator.openAppSettings();
//                 },
//                 child: const Text(
//                   'Open Settings',
//                 ),
//               ),
//             ],
//           );
//         },
//       );

//       return false;
//     }

//     return true;
//   }

//   Future<void> _attachCurrentLocation() async {
//     if (isGettingCurrentLocation) {
//       return;
//     }

//     setState(() {
//       isGettingCurrentLocation = true;
//     });

//     try {
//       final allowed =
//           await _checkLocationPermission();

//       if (!allowed) {
//         if (!mounted) return;

//         setState(() {
//           isGettingCurrentLocation = false;
//         });

//         return;
//       }

//       final position =
//           await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high,
//         ),
//       );

//       String address =
//           'Location attached';

//       try {
//         final placemarks =
//             await geocoding.placemarkFromCoordinates(
//           position.latitude,
//           position.longitude,
//         );

//         if (placemarks.isNotEmpty) {
//           final place = placemarks.first;

//           final parts = <String>[
//             if ((place.name ?? '').trim().isNotEmpty)
//               place.name!.trim(),
//             if ((place.locality ?? '').trim().isNotEmpty)
//               place.locality!.trim(),
//             if ((place.administrativeArea ?? '')
//                 .trim()
//                 .isNotEmpty)
//               place.administrativeArea!.trim(),
//           ];

//           if (parts.isNotEmpty) {
//             address = parts.join(', ');
//           }
//         }
//       } catch (_) {
//         // Coordinates are still valid even if
//         // address lookup fails.
//       }

//       if (!mounted) return;

//       setState(() {
//         currentPosition = position;
//         currentLocationAddress = address;
//         isGettingCurrentLocation = false;
//       });
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isGettingCurrentLocation = false;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Unable to get current location: $e',
//           ),
//         ),
//       );
//     }
//   }

//   Future<void> _addBranchLocation() async {
//     if (branchLocations.length >= 10) {
//       return;
//     }

//     final result =
//         await Navigator.of(context).push<LabBranchLocation>(
//       MaterialPageRoute(
//         builder: (_) => const LabMapPickerScreen(),
//       ),
//     );

//     if (result == null || !mounted) {
//       return;
//     }

//     setState(() {
//       branchLocations.add(result);
//     });
//   }

//   Future<String?> _uploadPhoto(
//     String labId,
//   ) async {
//     if (selectedPhoto == null) {
//       return null;
//     }

//     final file = selectedPhoto!;

//     final extension = file.path
//         .split('.')
//         .last
//         .toLowerCase();

//     final storageReference =
//         FirebaseStorage.instance
//             .ref()
//             .child('lab_photos')
//             .child(labId)
//             .child('profile.$extension');

//     final metadata = SettableMetadata(
//       contentType: extension == 'png'
//           ? 'image/png'
//           : 'image/jpeg',
//     );

//     await storageReference.putFile(
//       file,
//       metadata,
//     );

//     return await storageReference
//         .getDownloadURL();
//   }

//   Future<void> _submitLabProfile() async {
//     if (isSubmitting) {
//       return;
//     }

//     FocusScope.of(context).unfocus();

//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     if (selectedCategories.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please select at least one lab category.',
//           ),
//         ),
//       );
//       return;
//     }

//     if (currentPosition == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please attach your current location.',
//           ),
//         ),
//       );
//       return;
//     }

//     setState(() {
//       isSubmitting = true;
//     });

//     try {
//       final firestore =
//           FirebaseFirestore.instance;

//       /*
//        * Create the Lab document first.
//        *
//        * Using an auto-generated document ID avoids
//        * loading/searching all labs before registration.
//        */
//       final labReference =
//           firestore.collection('labs').doc();

//       final labId = labReference.id;

//       String? photoUrl;

//       /*
//        * Upload photo only if the user selected one.
//        */
//       if (selectedPhoto != null) {
//         photoUrl = await _uploadPhoto(labId);
//       }

//       /*
//        * Save the main lab profile.
//        *
//        * Only small data is stored here.
//        */
//       await labReference.set({
//         'username':
//             usernameController.text.trim(),

//         'mobile':
//             '+91${mobileController.text.trim()}',

//         'categories':
//             List<String>.from(selectedCategories),

//         'photoUrl':
//             photoUrl,

//         'currentLocation': {
//           'latitude':
//               currentPosition!.latitude,
//           'longitude':
//               currentPosition!.longitude,
//           'address':
//               currentLocationAddress ??
//                   'Current location',
//         },

//         'branchCount':
//             branchLocations.length,

//         'createdAt':
//             FieldValue.serverTimestamp(),

//         'updatedAt':
//             FieldValue.serverTimestamp(),
//       });

//       /*
//        * Save branches separately.
//        *
//        * Maximum is only 10, so this batch is very small.
//        */
//       if (branchLocations.isNotEmpty) {
//         final batch = firestore.batch();

//         for (final branch
//             in branchLocations) {
//           final branchReference =
//               labReference
//                   .collection('locations')
//                   .doc();

//           batch.set(
//             branchReference,
//             {
//               'latitude':
//                   branch.latitude,

//               'longitude':
//                   branch.longitude,

//               'address':
//                   branch.address,

//               'createdAt':
//                   FieldValue.serverTimestamp(),
//             },
//           );
//         }

//         await batch.commit();
//       }

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Lab profile submitted successfully.',
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );

//       /*
//        * Navigate only after all Firebase operations
//        * are completed.
//        *
//        * Replace this with your actual next screen.
//        */
//       Navigator.of(context).pop();
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Unable to submit lab profile: $e',
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );

//       setState(() {
//         isSubmitting = false;
//       });

//       return;
//     }

//     if (!mounted) return;

//     setState(() {
//       isSubmitting = false;
//     });
//   }
// }

// class LabBranchLocation {
//   final double latitude;
//   final double longitude;
//   final String address;

//   const LabBranchLocation({
//     required this.latitude,
//     required this.longitude,
//     required this.address,
//   });
// }
// class LabMapPickerScreen extends StatefulWidget {
//   const LabMapPickerScreen({
//     super.key,
//   });

//   @override
//   State<LabMapPickerScreen> createState() =>
//       _LabMapPickerScreenState();
// }

// class _LabMapPickerScreenState
//     extends State<LabMapPickerScreen> {
//   GoogleMapController? mapController;

//   final TextEditingController searchController =
//       TextEditingController();
//   final Geocoding geocoding =
//       Geocoding();


//   LatLng? selectedLocation;

//   String selectedAddress =
//       'Select a location on the map';

//   bool isSearching = false;
//   bool isGettingCurrentLocation = false;

//   Set<Marker> markers = {};

//   static const LatLng defaultLocation =
//       LatLng(10.5276, 76.2144);

//   @override
//   void dispose() {
//     searchController.dispose();
//     mapController?.dispose();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Select Branch Location',
//         ),
//         backgroundColor: Colors.green.shade700,
//         foregroundColor: Colors.white,
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition:
//                 const CameraPosition(
//               target: defaultLocation,
//               zoom: 10,
//             ),
//             myLocationEnabled: true,
//             myLocationButtonEnabled: false,
//             zoomControlsEnabled: false,
//             mapToolbarEnabled: false,
//             markers: markers,
//             onMapCreated: (controller) {
//               mapController = controller;
//             },
//             onTap: _selectMapLocation,
//           ),

//           Positioned(
//             top: 15,
//             left: 15,
//             right: 15,
//             child: _buildSearchBox(),
//           ),

//           Positioned(
//             right: 15,
//             bottom: 145,
//             child: FloatingActionButton(
//               heroTag: 'currentLocation',
//               backgroundColor: Colors.white,
//               foregroundColor: Colors.green.shade700,
//               onPressed:
//                   isGettingCurrentLocation
//                       ? null
//                       : _getCurrentLocation,
//               child:
//                   isGettingCurrentLocation
//                       ? const SizedBox(
//                           height: 22,
//                           width: 22,
//                           child:
//                               CircularProgressIndicator(
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : const Icon(
//                           Icons.my_location,
//                         ),
//             ),
//           ),

//           Positioned(
//             left: 15,
//             right: 15,
//             bottom: 15,
//             child: _buildBottomPanel(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchBox() {
//     return Material(
//       elevation: 5,
//       borderRadius: BorderRadius.circular(15),
//       child: TextField(
//         controller: searchController,
//         textInputAction: TextInputAction.search,
//         onSubmitted: (_) {
//           _searchLocation();
//         },
//         decoration: InputDecoration(
//           hintText: 'Search location',
//           prefixIcon: const Icon(
//             Icons.search,
//           ),
//           suffixIcon: isSearching
//               ? const Padding(
//                   padding: EdgeInsets.all(12),
//                   child: SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                     ),
//                   ),
//                 )
//               : IconButton(
//                   icon: const Icon(
//                     Icons.search,
//                   ),
//                   onPressed: _searchLocation,
//                 ),
//           filled: true,
//           fillColor: Colors.white,
//           border: OutlineInputBorder(
//             borderRadius:
//                 BorderRadius.circular(15),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomPanel() {
//     return Material(
//       elevation: 8,
//       borderRadius: BorderRadius.circular(18),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius:
//               BorderRadius.circular(18),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment:
//               CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Selected Location',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),

//             const SizedBox(height: 6),

//             Text(
//               selectedAddress,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 color: Colors.grey.shade700,
//                 fontSize: 13,
//               ),
//             ),

//             const SizedBox(height: 12),

//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton.icon(
//                 onPressed: selectedLocation == null
//                     ? null
//                     : _confirmLocation,
//                 icon: const Icon(
//                   Icons.check,
//                 ),
//                 label: const Text(
//                   'Confirm Location',
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor:
//                       Colors.green.shade700,
//                   foregroundColor: Colors.white,
//                   disabledBackgroundColor:
//                       Colors.grey.shade300,
//                   shape:
//                       RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius.circular(13),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _selectMapLocation(
//     LatLng location,
//   ) async {
//     if (!mounted) return;

//     setState(() {
//       selectedLocation = location;

//       markers = {
//         Marker(
//           markerId:
//               const MarkerId('selected'),
//           position: location,
//         ),
//       };

//       selectedAddress =
//           'Getting address...';
//     });

//     try {
//       final placemarks =
//           await geocoding.placemarkFromCoordinates(
//         location.latitude,
//         location.longitude,
//       );

//       String address =
//           'Selected location';

//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;

//         final parts = <String>[
//           if ((place.name ?? '').trim().isNotEmpty)
//             place.name!.trim(),

//           if ((place.locality ?? '')
//               .trim()
//               .isNotEmpty)
//             place.locality!.trim(),

//           if ((place.administrativeArea ?? '')
//               .trim()
//               .isNotEmpty)
//             place.administrativeArea!.trim(),

//           if ((place.country ?? '')
//               .trim()
//               .isNotEmpty)
//             place.country!.trim(),
//         ];

//         if (parts.isNotEmpty) {
//           address = parts.join(', ');
//         }
//       }

//       if (!mounted) return;

//       setState(() {
//         selectedAddress = address;
//       });
//     } catch (_) {
//       if (!mounted) return;

//       setState(() {
//         selectedAddress =
//             'Selected location';
//       });
//     }
//   }

//   Future<void> _searchLocation() async {
//     final query =
//         searchController.text.trim();

//     if (query.isEmpty) {
//       return;
//     }

//     if (isSearching) {
//       return;
//     }

//     setState(() {
//       isSearching = true;
//     });

//     try {
//       final locations =
//           await geocoding.locationFromAddress(query);

//       if (locations.isEmpty) {
//         throw Exception(
//           'Location not found',
//         );
//       }

//       final location = locations.first;

//       final latLng = LatLng(
//         location.latitude,
//         location.longitude,
//       );

//       await mapController?.animateCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(
//             target: latLng,
//             zoom: 16,
//           ),
//         ),
//       );

//       await _selectMapLocation(latLng);
//     } catch (_) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Location not found. Try another search.',
//           ),
//         ),
//       );
//     }

//     if (!mounted) return;

//     setState(() {
//       isSearching = false;
//     });
//   }

//   Future<void> _getCurrentLocation() async {
//     if (isGettingCurrentLocation) {
//       return;
//     }

//     setState(() {
//       isGettingCurrentLocation = true;
//     });

//     try {
//       bool serviceEnabled =
//           await Geolocator
//               .isLocationServiceEnabled();

//       if (!serviceEnabled) {
//         if (!mounted) return;

//         ScaffoldMessenger.of(context)
//             .showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Please turn on location services.',
//             ),
//           ),
//         );

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

//       final position =
//           await Geolocator.getCurrentPosition(
//         locationSettings:
//             const LocationSettings(
//           accuracy:
//               LocationAccuracy.high,
//         ),
//       );

//       final location = LatLng(
//         position.latitude,
//         position.longitude,
//       );

//       await mapController?.animateCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(
//             target: location,
//             zoom: 17,
//           ),
//         ),
//       );

//       await _selectMapLocation(location);
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         SnackBar(
//           content: Text(
//             'Unable to get location: $e',
//           ),
//         ),
//       );
//     } finally {
//       if (!mounted) return;

//       setState(() {
//         isGettingCurrentLocation = false;
//       });
//     }
//   }

//   void _confirmLocation() {
//     final location = selectedLocation;

//     if (location == null) {
//       return;
//     }

//     Navigator.of(context).pop(
//       LabBranchLocation(
//         latitude: location.latitude,
//         longitude: location.longitude,
//         address: selectedAddress,
//       ),
//     );
//   }
// }
// import 'dart:async';
// import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:image_picker/image_picker.dart';

// class ScreenLabLogin extends StatefulWidget {
//   const ScreenLabLogin({super.key});

//   @override
//   State<ScreenLabLogin> createState() => _ScreenLabLoginState();
// }

// class _ScreenLabLoginState extends State<ScreenLabLogin> {
//   final _formKey = GlobalKey<FormState>();

//   final TextEditingController usernameController =
//       TextEditingController();

//   final TextEditingController mobileController =
//       TextEditingController();

//   final TextEditingController otpController =
//       TextEditingController();

//   final TextEditingController categorySearchController =
//       TextEditingController();

//   final Geocoding geocoding = Geocoding();

//   final ImagePicker imagePicker = ImagePicker();

//   // --------------------------------------------------
//   // OTP VARIABLES
//   // --------------------------------------------------

//   String? verificationId;

//   bool otpSent = false;
//   bool otpVerified = false;
//   bool isSendingOtp = false;
//   bool isVerifyingOtp = false;

//   int otpSecondsRemaining = 30;

//   Timer? otpTimer;

//   // --------------------------------------------------

//   bool isSubmitting = false;
//   bool isGettingCurrentLocation = false;

//   File? selectedPhoto;

//   Position? currentPosition;
//   String? currentLocationAddress;

//   final List<String> defaultCategories = [
//     'Blood Checking Lab',
//     'Water Checking Lab',
//   ];

//   final List<String> selectedCategories = [];

//   final List<String> customCategories = [];

//   final List<LabBranchLocation> branchLocations = [];

//   String categorySearchText = '';

//   @override
//   void initState() {
//     super.initState();

//     categorySearchController.addListener(() {
//       if (!mounted) return;

//       setState(() {
//         categorySearchText =
//             categorySearchController.text.trim().toLowerCase();
//       });
//     });
//   }

//   @override
//   void dispose() {
//     otpTimer?.cancel();

//     usernameController.dispose();
//     mobileController.dispose();
//     otpController.dispose();
//     categorySearchController.dispose();

//     super.dispose();
//   }

//   List<String> get allCategories {
//     return [
//       ...defaultCategories,
//       ...customCategories,
//     ];
//   }

//   List<String> get filteredCategories {
//     if (categorySearchText.isEmpty) {
//       return allCategories;
//     }

//     return allCategories.where((category) {
//       return category
//           .toLowerCase()
//           .contains(categorySearchText);
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         title: const Text(
//           'Lab Registration',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.green.shade700,
//         foregroundColor: Colors.white,
//       ),
//       body: SafeArea(
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             padding: const EdgeInsets.all(16),
//             children: [
//               _buildHeader(),

//               const SizedBox(height: 20),

//               _buildUsernameField(),

//               const SizedBox(height: 16),

//               _buildMobileField(),

//               // OTP section appears ONLY after Send OTP
//               if (otpSent) ...[
//                 const SizedBox(height: 16),
//                 _buildOtpSection(),
//               ],

//               const SizedBox(height: 24),

//               _buildCategorySection(),

//               const SizedBox(height: 24),

//               _buildPhotoSection(),

//               const SizedBox(height: 24),

//               _buildCurrentLocationSection(),

//               const SizedBox(height: 24),

//               _buildBranchSection(),

//               const SizedBox(height: 30),

//               _buildSubmitButton(),

//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Colors.green.shade700,
//             Colors.green.shade500,
//           ],
//         ),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: const Column(
//         children: [
//           Icon(
//             Icons.biotech,
//             size: 55,
//             color: Colors.white,
//           ),
//           SizedBox(height: 10),
//           Text(
//             'Register Your Laboratory',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 6),
//           Text(
//             'Please provide the required laboratory details',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: Colors.white70,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUsernameField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _sectionTitle(
//           'Username',
//           required: true,
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: usernameController,
//           textInputAction: TextInputAction.next,
//           decoration: InputDecoration(
//             hintText: 'Enter username',
//             prefixIcon: const Icon(Icons.person_outline),
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide.none,
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide(
//                 color: Colors.grey.shade300,
//               ),
//             ),
//           ),
//           validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//               return 'Please enter username';
//             }

//             if (value.trim().length < 3) {
//               return 'Username must contain at least 3 characters';
//             }

//             return null;
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildMobileField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _sectionTitle(
//           'Mobile Number',
//           required: true,
//         ),

//         const SizedBox(height: 8),

//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: TextFormField(
//                 controller: mobileController,
//                 keyboardType: TextInputType.phone,
//                 maxLength: 10,
//                 enabled: !otpVerified && !isSendingOtp,
//                 decoration: InputDecoration(
//                   counterText: '',
//                   hintText: 'Enter 10 digit mobile number',
//                   prefixText: '+91  ',
//                   prefixIcon: const Icon(
//                     Icons.phone_outlined,
//                   ),
//                   filled: true,
//                   fillColor: Colors.white,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide: BorderSide.none,
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide: BorderSide(
//                       color: otpVerified
//                           ? Colors.green
//                           : Colors.grey.shade300,
//                     ),
//                   ),
//                   disabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide: BorderSide(
//                       color: otpVerified
//                           ? Colors.green
//                           : Colors.grey.shade300,
//                     ),
//                   ),
//                 ),
//                 validator: (value) {
//                   final mobile = value?.trim() ?? '';

//                   if (mobile.isEmpty) {
//                     return 'Please enter mobile number';
//                   }

//                   if (!RegExp(r'^[6-9][0-9]{9}$')
//                       .hasMatch(mobile)) {
//                     return 'Enter a valid 10 digit mobile number';
//                   }

//                   return null;
//                 },
//               ),
//             ),

//             const SizedBox(width: 8),

//             SizedBox(
//               height: 56,
//               child: ElevatedButton(
//                 onPressed: otpVerified ||
//                         isSendingOtp ||
//                         isVerifyingOtp
//                     ? null
//                     : _sendOtp,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor:
//                       Colors.green.shade700,
//                   foregroundColor: Colors.white,
//                   disabledBackgroundColor:
//                       Colors.green.shade300,
//                   shape: RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius.circular(14),
//                   ),
//                   padding:
//                       const EdgeInsets.symmetric(
//                     horizontal: 12,
//                   ),
//                 ),
//                 child: isSendingOtp
//                     ? const SizedBox(
//                         height: 20,
//                         width: 20,
//                         child:
//                             CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       )
//                     : Text(
//                         otpSent
//                             ? 'RESEND'
//                             : 'SEND OTP',
//                         style: const TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//               ),
//             ),
//           ],
//         ),

//         if (otpVerified)
//           Padding(
//             padding: const EdgeInsets.only(
//               top: 8,
//               left: 4,
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.verified,
//                   color: Colors.green.shade700,
//                   size: 18,
//                 ),
//                 const SizedBox(width: 5),
//                 Text(
//                   'Mobile number verified',
//                   style: TextStyle(
//                     color: Colors.green.shade700,
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildOtpSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _sectionTitle(
//           'OTP Verification',
//           required: true,
//         ),

//         const SizedBox(height: 5),

//         Text(
//           'Enter the 6-digit OTP sent to your mobile number',
//           style: TextStyle(
//             fontSize: 13,
//             color: Colors.grey.shade600,
//           ),
//         ),

//         const SizedBox(height: 10),

//         TextFormField(
//           controller: otpController,
//           keyboardType: TextInputType.number,
//           maxLength: 6,
//           enabled: !otpVerified && !isVerifyingOtp,
//           decoration: InputDecoration(
//             counterText: '',
//             hintText: 'Enter 6 digit OTP',
//             prefixIcon: const Icon(
//               Icons.lock_outline,
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius:
//                   BorderRadius.circular(14),
//               borderSide: BorderSide.none,
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius:
//                   BorderRadius.circular(14),
//               borderSide: BorderSide(
//                 color: otpVerified
//                     ? Colors.green
//                     : Colors.grey.shade300,
//               ),
//             ),
//             disabledBorder: OutlineInputBorder(
//               borderRadius:
//                   BorderRadius.circular(14),
//               borderSide: BorderSide(
//                 color: otpVerified
//                     ? Colors.green
//                     : Colors.grey.shade300,
//               ),
//             ),
//           ),
//         ),

//         const SizedBox(height: 10),

//         if (!otpVerified)
//           Row(
//             mainAxisAlignment:
//                 MainAxisAlignment.spaceBetween,
//             children: [
//               if (otpSecondsRemaining > 0)
//                 Text(
//                   'Resend OTP in ${otpSecondsRemaining}s',
//                   style: TextStyle(
//                     color: Colors.grey.shade600,
//                     fontSize: 13,
//                   ),
//                 )
//               else
//                 TextButton(
//                   onPressed:
//                       isSendingOtp ? null : _sendOtp,
//                   child: const Text(
//                     'Resend OTP',
//                   ),
//                 ),

//               ElevatedButton(
//                 onPressed: isVerifyingOtp
//                     ? null
//                     : _verifyOtp,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor:
//                       Colors.green.shade700,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: isVerifyingOtp
//                     ? const SizedBox(
//                         height: 18,
//                         width: 18,
//                         child:
//                             CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       )
//                     : const Text(
//                         'VERIFY OTP',
//                       ),
//               ),
//             ],
//           ),

//         if (otpVerified)
//           Container(
//             width: double.infinity,
//             padding:
//                 const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 10,
//             ),
//             decoration: BoxDecoration(
//               color: Colors.green.shade50,
//               borderRadius:
//                   BorderRadius.circular(12),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.check_circle,
//                   color: Colors.green.shade700,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   'OTP verified successfully',
//                   style: TextStyle(
//                     color: Colors.green.shade700,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }
//   // ==================================================
//   // OTP FUNCTIONS
//   // ==================================================

//   Future<void> _sendOtp() async {
//     FocusScope.of(context).unfocus();

//     final mobile = mobileController.text.trim();

//     if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Enter a valid 10 digit mobile number.',
//           ),
//         ),
//       );
//       return;
//     }

//     if (isSendingOtp) {
//       return;
//     }

//     setState(() {
//       isSendingOtp = true;
//       otpVerified = false;
//     });

//     final phoneNumber = '+91$mobile';

//     try {
//       await FirebaseAuth.instance.verifyPhoneNumber(
//         phoneNumber: phoneNumber,

//         timeout: const Duration(seconds: 30),

//         verificationCompleted:
//             (PhoneAuthCredential credential) async {
//           try {
//             await FirebaseAuth.instance
//                 .signInWithCredential(credential);

//             if (!mounted) return;

//             setState(() {
//               otpVerified = true;
//               isSendingOtp = false;
//             });

//             otpTimer?.cancel();
//           } catch (e) {
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

//           ScaffoldMessenger.of(context)
//               .showSnackBar(
//             SnackBar(
//               content: Text(
//                 e.message ??
//                     'Unable to send OTP.',
//               ),
//               backgroundColor: Colors.red,
//             ),
//           );
//         },

//         codeSent: (
//           String newVerificationId,
//           int? resendToken,
//         ) {
//           if (!mounted) return;

//           setState(() {
//             verificationId =
//                 newVerificationId;
//             otpSent = true;
//             otpVerified = false;
//             isSendingOtp = false;
//             otpSecondsRemaining = 30;
//           });

//           _startOtpTimer();

//           ScaffoldMessenger.of(context)
//               .showSnackBar(
//             const SnackBar(
//               content: Text(
//                 'OTP sent successfully.',
//               ),
//               backgroundColor: Colors.green,
//             ),
//           );
//         },

//         codeAutoRetrievalTimeout:
//             (String newVerificationId) {
//           verificationId =
//               newVerificationId;
//         },
//       );
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isSendingOtp = false;
//       });

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         SnackBar(
//           content: Text(
//             'Unable to send OTP: $e',
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   void _startOtpTimer() {
//     otpTimer?.cancel();

//     otpTimer = Timer.periodic(
//       const Duration(seconds: 1),
//       (timer) {
//         if (!mounted) {
//           timer.cancel();
//           return;
//         }

//         if (otpSecondsRemaining <= 1) {
//           timer.cancel();

//           setState(() {
//             otpSecondsRemaining = 0;
//           });
//         } else {
//           setState(() {
//             otpSecondsRemaining--;
//           });
//         }
//       },
//     );
//   }

//   Future<void> _verifyOtp() async {
//     final otp = otpController.text.trim();

//     if (otp.length != 6) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please enter the 6 digit OTP.',
//           ),
//         ),
//       );
//       return;
//     }

//     if (verificationId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please send OTP again.',
//           ),
//         ),
//       );
//       return;
//     }

//     if (isVerifyingOtp) {
//       return;
//     }

//     setState(() {
//       isVerifyingOtp = true;
//     });

//     try {
//       final credential =
//           PhoneAuthProvider.credential(
//         verificationId: verificationId!,
//         smsCode: otp,
//       );

//       await FirebaseAuth.instance
//           .signInWithCredential(credential);

//       if (!mounted) return;

//       otpTimer?.cancel();

//       setState(() {
//         otpVerified = true;
//         isVerifyingOtp = false;
//       });

//       FocusScope.of(context).unfocus();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Mobile number verified successfully.',
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } on FirebaseAuthException catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isVerifyingOtp = false;
//       });

//       String message =
//           'Invalid OTP. Please try again.';

//       if (e.code == 'invalid-verification-code') {
//         message =
//             'Invalid OTP. Please check and try again.';
//       } else if (e.code ==
//           'session-expired') {
//         message =
//             'OTP expired. Please send a new OTP.';
//       }

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isVerifyingOtp = false;
//       });

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         SnackBar(
//           content: Text(
//             'OTP verification failed: $e',
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // ==================================================
//   // CATEGORY SECTION
//   // ==================================================

//   Widget _buildCategorySection() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         _sectionTitle(
//           'Lab Category',
//           required: true,
//         ),

//         const SizedBox(height: 5),

//         Text(
//           'Select at least one category',
//           style: TextStyle(
//             fontSize: 13,
//             color: Colors.grey.shade600,
//           ),
//         ),

//         const SizedBox(height: 12),

//         TextField(
//           controller:
//               categorySearchController,
//           decoration: InputDecoration(
//             hintText: 'Search category',
//             prefixIcon:
//                 const Icon(Icons.search),
//             suffixIcon:
//                 categorySearchController
//                         .text
//                         .isNotEmpty
//                     ? IconButton(
//                         icon:
//                             const Icon(Icons.clear),
//                         onPressed: () {
//                           categorySearchController
//                               .clear();
//                         },
//                       )
//                     : null,
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius:
//                   BorderRadius.circular(14),
//               borderSide: BorderSide.none,
//             ),
//             enabledBorder:
//                 OutlineInputBorder(
//               borderRadius:
//                   BorderRadius.circular(14),
//               borderSide: BorderSide(
//                 color: Colors.grey.shade300,
//               ),
//             ),
//           ),
//         ),

//         const SizedBox(height: 12),

//         if (filteredCategories.isEmpty)
//           Container(
//             padding:
//                 const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius:
//                   BorderRadius.circular(14),
//             ),
//             child: const Text(
//               'No category found.',
//               style: TextStyle(
//                 color: Colors.grey,
//               ),
//             ),
//           ),

//         ...filteredCategories.map(
//           (category) {
//             final isSelected =
//                 selectedCategories
//                     .contains(category);

//             return Container(
//               margin:
//                   const EdgeInsets.only(
//                 bottom: 8,
//               ),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius:
//                     BorderRadius.circular(14),
//                 border: Border.all(
//                   color: isSelected
//                       ? Colors.green
//                       : Colors.grey.shade300,
//                   width:
//                       isSelected ? 1.5 : 1,
//                 ),
//               ),
//               child: CheckboxListTile(
//                 value: isSelected,
//                 activeColor:
//                     Colors.green.shade700,
//                 title: Text(
//                   category,
//                   style:
//                       const TextStyle(
//                     fontWeight:
//                         FontWeight.w500,
//                   ),
//                 ),
//                 onChanged: (value) {
//                   setState(() {
//                     if (value == true) {
//                       selectedCategories
//                           .add(category);
//                     } else {
//                       selectedCategories
//                           .remove(category);
//                     }
//                   });
//                 },
//               ),
//             );
//           },
//         ),

//         const SizedBox(height: 5),

//         OutlinedButton.icon(
//           onPressed: isSubmitting
//               ? null
//               : _showAddCustomCategoryDialog,
//           icon: const Icon(Icons.add),
//           label: const Text(
//             'Add Your Own Category',
//           ),
//           style:
//               OutlinedButton.styleFrom(
//             foregroundColor:
//                 Colors.green.shade700,
//             minimumSize:
//                 const Size(
//               double.infinity,
//               50,
//             ),
//             shape:
//                 RoundedRectangleBorder(
//               borderRadius:
//                   BorderRadius.circular(14),
//             ),
//           ),
//         ),

//         if (selectedCategories.isEmpty)
//           Padding(
//             padding:
//                 const EdgeInsets.only(
//               top: 8,
//               left: 4,
//             ),
//             child: Text(
//               'Please select at least one lab category',
//               style: TextStyle(
//                 color: Colors.red.shade700,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildPhotoSection() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         _sectionTitle(
//           'User Photo',
//           required: false,
//         ),

//         const SizedBox(height: 8),

//         Container(
//           padding:
//               const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius:
//                 BorderRadius.circular(16),
//             border: Border.all(
//               color: Colors.grey.shade300,
//             ),
//           ),
//           child: Row(
//             children: [
//               CircleAvatar(
//                 radius: 32,
//                 backgroundColor:
//                     Colors.green.shade50,
//                 backgroundImage:
//                     selectedPhoto != null
//                         ? FileImage(
//                             selectedPhoto!,
//                           )
//                         : null,
//                 child: selectedPhoto == null
//                     ? Icon(
//                         Icons.person,
//                         size: 35,
//                         color:
//                             Colors.green.shade700,
//                       )
//                     : null,
//               ),

//               const SizedBox(width: 15),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Profile Photo',
//                       style: TextStyle(
//                         fontWeight:
//                             FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Optional',
//                       style: TextStyle(
//                         color:
//                             Colors.grey.shade600,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               ElevatedButton(
//                 onPressed: isSubmitting
//                     ? null
//                     : _pickPhoto,
//                 child: Text(
//                   selectedPhoto == null
//                       ? 'Add Photo'
//                       : 'Change',
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCurrentLocationSection() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         _sectionTitle(
//           'Current Location',
//           required: true,
//         ),

//         const SizedBox(height: 8),

//         Container(
//           padding:
//               const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius:
//                 BorderRadius.circular(16),
//             border: Border.all(
//               color: currentPosition != null
//                   ? Colors.green
//                   : Colors.grey.shade300,
//             ),
//           ),
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                     currentPosition != null
//                         ? Icons.location_on
//                         : Icons.location_off,
//                     color:
//                         currentPosition != null
//                             ? Colors.green.shade700
//                             : Colors.grey,
//                     size: 32,
//                   ),

//                   const SizedBox(width: 12),

//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment:
//                           CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           currentPosition != null
//                               ? 'Current location attached'
//                               : 'Current location required',
//                           style: TextStyle(
//                             fontWeight:
//                                 FontWeight.bold,
//                             color:
//                                 currentPosition !=
//                                         null
//                                     ? Colors.green
//                                         .shade700
//                                     : Colors.black87,
//                           ),
//                         ),

//                         if (currentLocationAddress !=
//                             null)
//                           Padding(
//                             padding:
//                                 const EdgeInsets
//                                     .only(
//                               top: 5,
//                             ),
//                             child: Text(
//                               currentLocationAddress!,
//                               maxLines: 2,
//                               overflow:
//                                   TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 color: Colors
//                                     .grey.shade600,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 14),

//               SizedBox(
//                 width: double.infinity,
//                 child:
//                     ElevatedButton.icon(
//                   onPressed:
//                       isGettingCurrentLocation ||
//                               isSubmitting
//                           ? null
//                           : _attachCurrentLocation,
//                   icon:
//                       isGettingCurrentLocation
//                           ? const SizedBox(
//                               height: 18,
//                               width: 18,
//                               child:
//                                   CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 color: Colors.white,
//                               ),
//                             )
//                           : const Icon(
//                               Icons.my_location,
//                             ),
//                   label: Text(
//                     currentPosition == null
//                         ? 'Attach Current Location'
//                         : 'Update Current Location',
//                   ),
//                   style:
//                       ElevatedButton.styleFrom(
//                     backgroundColor:
//                         Colors.green.shade700,
//                     foregroundColor:
//                         Colors.white,
//                     minimumSize:
//                         const Size(
//                       double.infinity,
//                       50,
//                     ),
//                     shape:
//                         RoundedRectangleBorder(
//                       borderRadius:
//                           BorderRadius.circular(
//                         14,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//   Widget _buildBranchSection() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         _sectionTitle(
//           'Other Branch Locations',
//           required: false,
//         ),

//         const SizedBox(height: 5),

//         Text(
//           'Optional • You can add up to 10 branches',
//           style: TextStyle(
//             color: Colors.grey.shade600,
//             fontSize: 13,
//           ),
//         ),

//         const SizedBox(height: 12),

//         if (branchLocations.isNotEmpty)
//           ...List.generate(
//             branchLocations.length,
//             (index) {
//               final branch =
//                   branchLocations[index];

//               return Container(
//                 margin:
//                     const EdgeInsets.only(
//                   bottom: 10,
//                 ),
//                 padding:
//                     const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius:
//                       BorderRadius.circular(15),
//                   border: Border.all(
//                     color: Colors.grey.shade300,
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       backgroundColor:
//                           Colors.green.shade50,
//                       child: Text(
//                         '${index + 1}',
//                         style: TextStyle(
//                           color: Colors
//                               .green.shade700,
//                           fontWeight:
//                               FontWeight.bold,
//                         ),
//                       ),
//                     ),

//                     const SizedBox(width: 12),

//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment:
//                             CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Branch Location',
//                             style: TextStyle(
//                               fontWeight:
//                                   FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             branch.address,
//                             maxLines: 2,
//                             overflow:
//                                 TextOverflow.ellipsis,
//                             style: TextStyle(
//                               color: Colors
//                                   .grey.shade600,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     IconButton(
//                       onPressed: isSubmitting
//                           ? null
//                           : () {
//                               setState(() {
//                                 branchLocations
//                                     .removeAt(
//                                   index,
//                                 );
//                               });
//                             },
//                       icon: const Icon(
//                         Icons.delete_outline,
//                         color: Colors.red,
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),

//         if (branchLocations.length < 10)
//           OutlinedButton.icon(
//             onPressed: isSubmitting
//                 ? null
//                 : _addBranchLocation,
//             icon: const Icon(
//               Icons.add_location_alt_outlined,
//             ),
//             label: Text(
//               'Add Other Branch Location '
//               '(${branchLocations.length}/10)',
//             ),
//             style:
//                 OutlinedButton.styleFrom(
//               foregroundColor:
//                   Colors.green.shade700,
//               minimumSize:
//                   const Size(
//                 double.infinity,
//                 52,
//               ),
//               shape:
//                   RoundedRectangleBorder(
//                 borderRadius:
//                     BorderRadius.circular(14),
//               ),
//             ),
//           )
//         else
//           Container(
//             width: double.infinity,
//             padding:
//                 const EdgeInsets.all(15),
//             decoration: BoxDecoration(
//               color: Colors.orange.shade50,
//               borderRadius:
//                   BorderRadius.circular(14),
//             ),
//             child: const Text(
//               'Maximum 10 branch locations added.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontWeight:
//                     FontWeight.w600,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildSubmitButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: 56,
//       child: ElevatedButton(
//         onPressed: isSubmitting
//             ? null
//             : _submitLabProfile,
//         style: ElevatedButton.styleFrom(
//           backgroundColor:
//               Colors.green.shade700,
//           foregroundColor: Colors.white,
//           disabledBackgroundColor:
//               Colors.green.shade300,
//           shape:
//               RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(16),
//           ),
//         ),
//         child: isSubmitting
//             ? const Row(
//                 mainAxisAlignment:
//                     MainAxisAlignment.center,
//                 children: [
//                   SizedBox(
//                     height: 22,
//                     width: 22,
//                     child:
//                         CircularProgressIndicator(
//                       strokeWidth: 2.5,
//                       color: Colors.white,
//                     ),
//                   ),
//                   SizedBox(width: 12),
//                   Text(
//                     'Submitting...',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight:
//                           FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               )
//             : const Text(
//                 'SUBMIT PROFILE',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight:
//                       FontWeight.bold,
//                 ),
//               ),
//       ),
//     );
//   }

//   Widget _sectionTitle(
//     String title, {
//     required bool required,
//   }) {
//     return RichText(
//       text: TextSpan(
//         text: title,
//         style: const TextStyle(
//           color: Colors.black87,
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//         ),
//         children: [
//           if (required)
//             const TextSpan(
//               text: ' *',
//               style: TextStyle(
//                 color: Colors.red,
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Future<void>
//       _showAddCustomCategoryDialog() async {
//     final controller =
//         TextEditingController();

//     await showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           title: const Text(
//             'Add Your Own Category',
//           ),
//           content: TextField(
//             controller: controller,
//             textCapitalization:
//                 TextCapitalization.words,
//             decoration:
//                 const InputDecoration(
//               hintText:
//                   'Enter lab category',
//               prefixIcon: Icon(
//                 Icons.category_outlined,
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
//               child:
//                   const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 final category =
//                     controller.text.trim();

//                 if (category.isEmpty) {
//                   return;
//                 }

//                 if (allCategories.any(
//                   (item) =>
//                       item.toLowerCase() ==
//                       category.toLowerCase(),
//                 )) {
//                   ScaffoldMessenger.of(
//                     context,
//                   ).showSnackBar(
//                     const SnackBar(
//                       content: Text(
//                         'This category already exists.',
//                       ),
//                     ),
//                   );
//                   return;
//                 }

//                 setState(() {
//                   customCategories
//                       .add(category);
//                   selectedCategories
//                       .add(category);
//                 });

//                 Navigator.pop(
//                   dialogContext,
//                 );
//               },
//               child: const Text('Add'),
//             ),
//           ],
//         );
//       },
//     );

//     controller.dispose();
//   }

//   Future<void> _pickPhoto() async {
//     try {
//       final XFile? pickedFile =
//           await imagePicker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 70,
//         maxWidth: 1000,
//         maxHeight: 1000,
//       );

//       if (pickedFile == null) {
//         return;
//       }

//       if (!mounted) return;

//       setState(() {
//         selectedPhoto =
//             File(pickedFile.path);
//       });
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         SnackBar(
//           content: Text(
//             'Unable to select photo: $e',
//           ),
//         ),
//       );
//     }
//   }

//   Future<bool>
//       _checkLocationPermission() async {
//     bool serviceEnabled =
//         await Geolocator
//             .isLocationServiceEnabled();

//     if (!serviceEnabled) {
//       if (!mounted) return false;

//       await showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text(
//               'Location is disabled',
//             ),
//             content: const Text(
//               'Please turn on location services '
//               'and try again.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 child: const Text('OK'),
//               ),
//             ],
//           );
//         },
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
//       if (!mounted) return false;

//       await showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text(
//               'Location permission required',
//             ),
//             content: const Text(
//               'Current location is mandatory for '
//               'lab registration. Please allow '
//               'location permission.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 child:
//                     const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   Navigator.pop(context);

//                   await Geolocator
//                       .openAppSettings();
//                 },
//                 child: const Text(
//                   'Open Settings',
//                 ),
//               ),
//             ],
//           );
//         },
//       );

//       return false;
//     }

//     return true;
//   }

//   Future<void>
//       _attachCurrentLocation() async {
//     if (isGettingCurrentLocation) {
//       return;
//     }

//     setState(() {
//       isGettingCurrentLocation = true;
//     });

//     try {
//       final allowed =
//           await _checkLocationPermission();

//       if (!allowed) {
//         if (!mounted) return;

//         setState(() {
//           isGettingCurrentLocation =
//               false;
//         });

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

//       String address =
//           'Location attached';

//       try {
//         final placemarks =
//             await geocoding
//                 .placemarkFromCoordinates(
//           position.latitude,
//           position.longitude,
//         );

//         if (placemarks.isNotEmpty) {
//           final place =
//               placemarks.first;

//           final parts =
//               <String>[
//             if ((place.name ?? '')
//                 .trim()
//                 .isNotEmpty)
//               place.name!.trim(),

//             if ((place.locality ?? '')
//                 .trim()
//                 .isNotEmpty)
//               place.locality!.trim(),

//             if ((place
//                         .administrativeArea ??
//                     '')
//                 .trim()
//                 .isNotEmpty)
//               place.administrativeArea!
//                   .trim(),
//           ];

//           if (parts.isNotEmpty) {
//             address =
//                 parts.join(', ');
//           }
//         }
//       } catch (_) {}

//       if (!mounted) return;

//       setState(() {
//         currentPosition =
//             position;
//         currentLocationAddress =
//             address;
//         isGettingCurrentLocation =
//             false;
//       });
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isGettingCurrentLocation =
//             false;
//       });

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         SnackBar(
//           content: Text(
//             'Unable to get current location: $e',
//           ),
//         ),
//       );
//     }
//   }

//   Future<void>
//       _addBranchLocation() async {
//     if (branchLocations.length >= 10) {
//       return;
//     }

//     final result =
//         await Navigator.of(context)
//             .push<LabBranchLocation>(
//       MaterialPageRoute(
//         builder: (_) =>
//             const LabMapPickerScreen(),
//       ),
//     );

//     if (result == null || !mounted) {
//       return;
//     }

//     setState(() {
//       branchLocations.add(result);
//     });
//   }

//   Future<String?> _uploadPhoto(
//     String labId,
//   ) async {
//     if (selectedPhoto == null) {
//       return null;
//     }

//     final file = selectedPhoto!;

//     final extension = file.path
//         .split('.')
//         .last
//         .toLowerCase();

//     final storageReference =
//         FirebaseStorage.instance
//             .ref()
//             .child('lab_photos')
//             .child(labId)
//             .child(
//                 'profile.$extension');

//     final metadata =
//         SettableMetadata(
//       contentType:
//           extension == 'png'
//               ? 'image/png'
//               : 'image/jpeg',
//     );

//     await storageReference.putFile(
//       file,
//       metadata,
//     );

//     return await storageReference
//         .getDownloadURL();
//   }

//   Future<void>
//       _submitLabProfile() async {
//     if (isSubmitting) {
//       return;
//     }

//     FocusScope.of(context).unfocus();

//     if (!_formKey.currentState!
//         .validate()) {
//       return;
//     }

//     // OTP MUST be verified
//     if (!otpVerified) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please verify your mobile number with OTP.',
//           ),
//         ),
//       );
//       return;
//     }

//     if (selectedCategories.isEmpty) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please select at least one lab category.',
//           ),
//         ),
//       );
//       return;
//     }

//     if (currentPosition == null) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please attach your current location.',
//           ),
//         ),
//       );
//       return;
//     }

//     setState(() {
//       isSubmitting = true;
//     });

//     try {
//       final firestore =
//           FirebaseFirestore.instance;

//       final labReference =
//           firestore.collection('labs').doc();

//       final labId =
//           labReference.id;

//       String? photoUrl;

//       if (selectedPhoto != null) {
//         photoUrl =
//             await _uploadPhoto(labId);
//       }

//       await labReference.set({
//         'username':
//             usernameController.text.trim(),

//         'mobile':
//             '+91${mobileController.text.trim()}',

//         'categories':
//             List<String>.from(
//           selectedCategories,
//         ),

//         'photoUrl':
//             photoUrl,

//         'currentLocation': {
//           'latitude':
//               currentPosition!.latitude,
//           'longitude':
//               currentPosition!.longitude,
//           'address':
//               currentLocationAddress ??
//                   'Current location',
//         },

//         'branchCount':
//             branchLocations.length,

//         'createdAt':
//             FieldValue.serverTimestamp(),

//         'updatedAt':
//             FieldValue.serverTimestamp(),
//       });

//       if (branchLocations.isNotEmpty) {
//         final batch =
//             firestore.batch();

//         for (final branch
//             in branchLocations) {
//           final branchReference =
//               labReference
//                   .collection('locations')
//                   .doc();

//           batch.set(
//             branchReference,
//             {
//               'latitude':
//                   branch.latitude,
//               'longitude':
//                   branch.longitude,
//               'address':
//                   branch.address,
//               'createdAt':
//                   FieldValue.serverTimestamp(),
//             },
//           );
//         }

//         await batch.commit();
//       }

//       if (!mounted) return;

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Lab profile submitted successfully.',
//           ),
//           backgroundColor:
//               Colors.green,
//         ),
//       );

//       Navigator.of(context).pop();
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         SnackBar(
//           content: Text(
//             'Unable to submit lab profile: $e',
//           ),
//           backgroundColor:
//               Colors.red,
//         ),
//       );

//       setState(() {
//         isSubmitting = false;
//       });

//       return;
//     }

//     if (!mounted) return;

//     setState(() {
//       isSubmitting = false;
//     });
//   }
// }

// class LabBranchLocation {
//   final double latitude;
//   final double longitude;
//   final String address;

//   const LabBranchLocation({
//     required this.latitude,
//     required this.longitude,
//     required this.address,
//   });
// }

// class LabMapPickerScreen
//     extends StatefulWidget {
//   const LabMapPickerScreen({
//     super.key,
//   });

//   @override
//   State<LabMapPickerScreen> createState() =>
//       _LabMapPickerScreenState();
// }

// class _LabMapPickerScreenState
//     extends State<LabMapPickerScreen> {
//   GoogleMapController? mapController;

//   final TextEditingController
//       searchController =
//       TextEditingController();

//   final Geocoding geocoding =
//       Geocoding();

//   LatLng? selectedLocation;

//   String selectedAddress =
//       'Select a location on the map';

//   bool isSearching = false;
//   bool isGettingCurrentLocation =
//       false;

//   Set<Marker> markers = {};

//   static const LatLng defaultLocation =
//       LatLng(10.5276, 76.2144);

//   @override
//   void dispose() {
//     searchController.dispose();
//     mapController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Select Branch Location',
//         ),
//         backgroundColor:
//             Colors.green.shade700,
//         foregroundColor: Colors.white,
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition:
//                 const CameraPosition(
//               target: defaultLocation,
//               zoom: 10,
//             ),
//             myLocationEnabled: true,
//             myLocationButtonEnabled:
//                 false,
//             zoomControlsEnabled: false,
//             mapToolbarEnabled: false,
//             markers: markers,
//             onMapCreated:
//                 (controller) {
//               mapController =
//                   controller;
//             },
//             onTap:
//                 _selectMapLocation,
//           ),

//           Positioned(
//             top: 15,
//             left: 15,
//             right: 15,
//             child: _buildSearchBox(),
//           ),

//           Positioned(
//             right: 15,
//             bottom: 145,
//             child: FloatingActionButton(
//               heroTag:
//                   'currentLocation',
//               backgroundColor:
//                   Colors.white,
//               foregroundColor:
//                   Colors.green.shade700,
//               onPressed:
//                   isGettingCurrentLocation
//                       ? null
//                       : _getCurrentLocation,
//               child:
//                   isGettingCurrentLocation
//                       ? const SizedBox(
//                           height: 22,
//                           width: 22,
//                           child:
//                               CircularProgressIndicator(
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : const Icon(
//                           Icons.my_location,
//                         ),
//             ),
//           ),

//           Positioned(
//             left: 15,
//             right: 15,
//             bottom: 15,
//             child:
//                 _buildBottomPanel(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchBox() {
//     return Material(
//       elevation: 5,
//       borderRadius:
//           BorderRadius.circular(15),
//       child: TextField(
//         controller:
//             searchController,
//         textInputAction:
//             TextInputAction.search,
//         onSubmitted: (_) {
//           _searchLocation();
//         },
//         decoration:
//             InputDecoration(
//           hintText:
//               'Search location',
//           prefixIcon:
//               const Icon(Icons.search),
//           suffixIcon: isSearching
//               ? const Padding(
//                   padding:
//                       EdgeInsets.all(12),
//                   child: SizedBox(
//                     height: 20,
//                     width: 20,
//                     child:
//                         CircularProgressIndicator(
//                       strokeWidth: 2,
//                     ),
//                   ),
//                 )
//               : IconButton(
//                   icon: const Icon(
//                     Icons.search,
//                   ),
//                   onPressed:
//                       _searchLocation,
//                 ),
//           filled: true,
//           fillColor: Colors.white,
//           border:
//               OutlineInputBorder(
//             borderRadius:
//                 BorderRadius.circular(15),
//             borderSide:
//                 BorderSide.none,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomPanel() {
//     return Material(
//       elevation: 8,
//       borderRadius:
//           BorderRadius.circular(18),
//       child: Container(
//         padding:
//             const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius:
//               BorderRadius.circular(18),
//         ),
//         child: Column(
//           mainAxisSize:
//               MainAxisSize.min,
//           crossAxisAlignment:
//               CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Selected Location',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight:
//                     FontWeight.bold,
//               ),
//             ),

//             const SizedBox(height: 6),

//             Text(
//               selectedAddress,
//               maxLines: 2,
//               overflow:
//                   TextOverflow.ellipsis,
//               style: TextStyle(
//                 color:
//                     Colors.grey.shade700,
//                 fontSize: 13,
//               ),
//             ),

//             const SizedBox(height: 12),

//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child:
//                   ElevatedButton.icon(
//                 onPressed:
//                     selectedLocation ==
//                             null
//                         ? null
//                         : _confirmLocation,
//                 icon: const Icon(
//                   Icons.check,
//                 ),
//                 label: const Text(
//                   'Confirm Location',
//                 ),
//                 style:
//                     ElevatedButton.styleFrom(
//                   backgroundColor:
//                       Colors.green.shade700,
//                   foregroundColor:
//                       Colors.white,
//                   disabledBackgroundColor:
//                       Colors.grey.shade300,
//                   shape:
//                       RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius.circular(
//                       13,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _selectMapLocation(
//     LatLng location,
//   ) async {
//     if (!mounted) return;

//     setState(() {
//       selectedLocation = location;

//       markers = {
//         Marker(
//           markerId:
//               const MarkerId(
//             'selected',
//           ),
//           position: location,
//         ),
//       };

//       selectedAddress =
//           'Getting address...';
//     });

//     try {
//       final placemarks =
//           await geocoding
//               .placemarkFromCoordinates(
//         location.latitude,
//         location.longitude,
//       );

//       String address =
//           'Selected location';

//       if (placemarks.isNotEmpty) {
//         final place =
//             placemarks.first;

//         final parts =
//             <String>[
//           if ((place.name ?? '')
//               .trim()
//               .isNotEmpty)
//             place.name!.trim(),

//           if ((place.locality ?? '')
//               .trim()
//               .isNotEmpty)
//             place.locality!.trim(),

//           if ((place
//                       .administrativeArea ??
//                   '')
//               .trim()
//               .isNotEmpty)
//             place.administrativeArea!
//                 .trim(),

//           if ((place.country ?? '')
//               .trim()
//               .isNotEmpty)
//             place.country!.trim(),
//         ];

//         if (parts.isNotEmpty) {
//           address =
//               parts.join(', ');
//         }
//       }

//       if (!mounted) return;

//       setState(() {
//         selectedAddress =
//             address;
//       });
//     } catch (_) {
//       if (!mounted) return;

//       setState(() {
//         selectedAddress =
//             'Selected location';
//       });
//     }
//   }

//   Future<void>
//       _searchLocation() async {
//     final query =
//         searchController.text.trim();

//     if (query.isEmpty ||
//         isSearching) {
//       return;
//     }

//     setState(() {
//       isSearching = true;
//     });

//     try {
//       final locations =
//           await geocoding
//               .locationFromAddress(
//         query,
//       );

//       if (locations.isEmpty) {
//         throw Exception(
//           'Location not found',
//         );
//       }

//       final location =
//           locations.first;

//       final latLng = LatLng(
//         location.latitude,
//         location.longitude,
//       );

//       await mapController
//           ?.animateCamera(
//         CameraUpdate
//             .newCameraPosition(
//           CameraPosition(
//             target: latLng,
//             zoom: 16,
//           ),
//         ),
//       );

//       await _selectMapLocation(
//         latLng,
//       );
//     } catch (_) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Location not found. Try another search.',
//           ),
//         ),
//       );
//     }

//     if (!mounted) return;

//     setState(() {
//       isSearching = false;
//     });
//   }

//   Future<void>
//       _getCurrentLocation() async {
//     if (isGettingCurrentLocation) {
//       return;
//     }

//     setState(() {
//       isGettingCurrentLocation =
//           true;
//     });

//     try {
//       final serviceEnabled =
//           await Geolocator
//               .isLocationServiceEnabled();

//       if (!serviceEnabled) {
//         if (!mounted) return;

//         ScaffoldMessenger.of(context)
//             .showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Please turn on location services.',
//             ),
//           ),
//         );

//         return;
//       }

//       LocationPermission permission =
//           await Geolocator
//               .checkPermission();

//       if (permission ==
//           LocationPermission.denied) {
//         permission =
//             await Geolocator
//                 .requestPermission();
//       }

//       if (permission ==
//               LocationPermission.denied ||
//           permission ==
//               LocationPermission
//                   .deniedForever) {
//         if (!mounted) return;

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

//       final position =
//           await Geolocator
//               .getCurrentPosition(
//         locationSettings:
//             const LocationSettings(
//           accuracy:
//               LocationAccuracy.high,
//         ),
//       );

//       final location = LatLng(
//         position.latitude,
//         position.longitude,
//       );

//       await mapController
//           ?.animateCamera(
//         CameraUpdate
//             .newCameraPosition(
//           CameraPosition(
//             target: location,
//             zoom: 17,
//           ),
//         ),
//       );

//       await _selectMapLocation(
//         location,
//       );
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         SnackBar(
//           content: Text(
//             'Unable to get location: $e',
//           ),
//         ),
//       );
//     } finally {
//       if (!mounted) {

//       setState(() {
//         isGettingCurrentLocation =
//             false;
//       });}
//     }
//   }

//   void _confirmLocation() {
//     final location =
//         selectedLocation;

//     if (location == null) {
//       return;
//     }

//     Navigator.of(context).pop(
//       LabBranchLocation(
//         latitude:
//             location.latitude,
//         longitude:
//             location.longitude,
//         address:
//             selectedAddress,
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

// class LaboratoryLocation {
//   final String placeName;
//   final double latitude;
//   final double longitude;

//   LaboratoryLocation({
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

//   factory LaboratoryLocation.fromMap(Map<String, dynamic> map) {
//     return LaboratoryLocation(
//       placeName: map['placeName'] ?? '',
//       latitude: (map['latitude'] ?? 0).toDouble(),
//       longitude: (map['longitude'] ?? 0).toDouble(),
//     );
//   }
// }
class LaboratoryLocation {
  final String placeName;
  final double? latitude;
  final double? longitude;

  LaboratoryLocation({
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

  factory LaboratoryLocation.fromMap(
    Map<String, dynamic> map,
  ) {
    return LaboratoryLocation(
      placeName: map['placeName']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}


class ScreenLabLogin extends StatefulWidget {
  const ScreenLabLogin({super.key});

  @override
  State<ScreenLabLogin> createState() => _ScreenLabLoginState();
}

class _ScreenLabLoginState extends State<ScreenLabLogin> {
  // ============================================================
  // CONTROLLERS
  // ============================================================
  // final Geocoding geocoding = Geocoding();
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController laboratoryNameController =
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
  // IMAGE
  // ============================================================
 File? profilePhoto;
  String? profilePhotoUrl;
bool isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();
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

  bool privacyPolicyAccepted = false;
  String? privacyPolicyError;

  // ============================================================
  // ERROR VARIABLES
  // ============================================================

  bool nameError = false;
  bool laboratoryNameError = false;
  bool mobileError = false;
  bool secondaryMobileError = false;
  bool categoryError = false;
  bool openingTimeError = false;
  bool closingTimeError = false;
  bool locationError = false;

  // ============================================================
  // CATEGORY
  // ============================================================

  // bool isCategoryDropdownOpen = false;

  // final List<String> laboratoryCategories = [
  //   'Blood Checking Lab',
  //   'Water Checking Lab',
  //   'Pathology Lab',
  //   'Clinical Laboratory',
  //   'Diagnostic Laboratory',
  //   'Medical Laboratory',
  //   'Blood Test Laboratory',
  //   'Urine Test Laboratory',
  //   'X-Ray Laboratory',
  //   'CT Scan Laboratory',
  //   'MRI Laboratory',
  //   'Ultrasound Laboratory',
  //   'ECG Laboratory',
  //   'Biochemistry Laboratory',
  //   'Microbiology Laboratory',
  //   'Hematology Laboratory',
  //   'Histopathology Laboratory',
  //   'Hormone Testing Laboratory',
  //   'Diabetes Testing Laboratory',
  //   'Thyroid Testing Laboratory',
  //   'Food Testing Laboratory',
  //   'Drug Testing Laboratory',
  // ];

  // final List<String> selectedCategories = [];
  // final List<String> customCategories = [];

  // List<String> filteredCategories = [];

  // ==========================================================
  // LOCATION
  // ==========================================================
LaboratoryLocation? currentLocation;

bool isGettingLocation = false;
bool isSearchingLocation = false;

// Used to invalidate an older location request
int _locationRequestId = 0;

 // ============================================================
  // SHOP TIMINGS
  // ============================================================

  TimeOfDay? openingTime;
  TimeOfDay? closingTime;
  bool isOpen24Hours = false;
  // ============================================================
  // DISPOSE
  // ============================================================
   @override
  void initState() {

    super.initState();

    filteredCategories =
        List<String>.from(
      laboratoryCategories,
    );

 filteredStates = List<String>.from(indiaStates);

  loadDistricts();
    // categorySearchController.addListener(
    //   filterCategories(),
    // );

  }

  @override
  void dispose() {
    timer?.cancel();

    nameController.dispose();
    laboratoryNameController.dispose();
    mobileController.dispose();
    otpController.dispose();
    secondaryPhoneController.dispose();
    categorySearchController.dispose();
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
  // CATEGORY FILTER UPDATE
  // ============================================================

  // void updateCategorySearch(String value) {
  //   setState(() {});
  // }

  // ============================================================
  // ADD CUSTOM CATEGORY
  // ============================================================

  // Future<void> showAddCustomCategoryDialog() async {
  //   final TextEditingController controller =
  //       TextEditingController();

  //   await showDialog(
  //     context: context,
  //     builder: (dialogContext) {
  //       return AlertDialog(
  //         title: const Text(
  //           'Add Your Own Category',
  //         ),
  //         content: TextField(
  //           controller: controller,
  //           textCapitalization:
  //               TextCapitalization.words,
  //           decoration: const InputDecoration(
  //             hintText:
  //                 'Enter laboratory category',
  //             prefixIcon: Icon(
  //               Icons.category_outlined,
  //             ),
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(dialogContext);
  //             },
  //             child: const Text(
  //               'Cancel',
  //             ),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               final String category =
  //                   controller.text.trim();

  //               if (category.isEmpty) {
  //                 return;
  //               }

  //               final bool exists =
  //                   laboratoryCategories.any(
  //                 (item) =>
  //                     item.toLowerCase() ==
  //                     category.toLowerCase(),
  //               );

  //               if (exists) {
  //                 ScaffoldMessenger.of(context)
  //                     .showSnackBar(
  //                   const SnackBar(
  //                     content: Text(
  //                       'This category already exists.',
  //                     ),
  //                   ),
  //                 );

  //                 return;
  //               }

  //               setState(() {
  //                 laboratoryCategories.add(
  //                   category,
  //                 );

  //                 selectedCategories.add(
  //                   category,
  //                 );

  //                 categoryError = false;
  //               });

  //               Navigator.pop(dialogContext);
  //             },
  //             child: const Text(
  //               'Add',
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   controller.dispose();
  // }

  // ============================================================
  // SAVE BASIC Laboratory DATA TO HIVE
  // ============================================================

  Future<void> saveBasicUserToHive(
    Map<String, dynamic> profileData,
  ) async {
    try {
      Box userBox;

      if (Hive.isBoxOpen('userBox')) {
        userBox = Hive.box('userBox');
      } else {
        userBox =
            await Hive.openBox('userBox');
      }

      await userBox.put(
        'name',
        profileData['name'],
      );

      await userBox.put(
        'mobile',
        profileData['mobile'],
      );

       // State
// await userBox.put(
//   'ambulanceState',
//   selectedState!.trim(),
// );
await userBox.put(
  'laboratoryState',
  profileData['state'],
);

await userBox.put(
  'laboratoryDistrict',
  profileData['district'],
);

await userBox.put(
  'laboratoryNearestTown',
  profileData['nearestTown'],
);

      await userBox.put(
        'role',
        'laboratory',
      );

      await userBox.put(
        'uid',
        profileData['uid'],
      );

      Box labBox;

      if (Hive.isBoxOpen('labProfiles')) {
        labBox =
            Hive.box('labProfiles');
      } else {
        labBox =
            await Hive.openBox(
          'labProfiles',
        );
      }

      await labBox.put(
        'profile',
        profileData,
      );

      debugPrint(
        'Laboratory local profile saved successfully.',
      );
    } catch (e) {
      debugPrint(
        'Laboratory Hive save error: $e',
      );
    }
  }

  // ============================================================
  // FIRESTORE SAVE
  // ============================================================

  Future<void> saveProfileToFirestore(
    Map<String, dynamic> profileData,
    File? photo,
  ) async {
    final String uid =
        profileData['uid'];

    final DocumentReference<Map<String, dynamic>>
        labReference =
        firestore
            .collection('labs')
            .doc(uid);

    final Map<String, dynamic>
        firestoreData =
        <String, dynamic>{
      'uid': uid,

      'name':
          profileData['name'],

      // Optional laboratory name.
      'laboratoryName':
          profileData[
              'laboratoryName'],

      'mobile':
    profileData['mobile'],

'secondaryMobile':
    profileData['secondaryMobile'],

  'state': selectedState!.trim(),

'district': selectedDistrict!.trim(),

'nearestTown':
    nearestCityController.text.trim(),

'role':
    'laboratory',
      
      'profilePhotoUrl': profilePhotoUrl,

      'categories':
          List<String>.from(
        profileData['categories'],
      ),

      'searchKeywords':
          List<String>.from(
        profileData[
            'searchKeywords'],
      ),

     'openingTime':
    profileData['openingTime'],

'closingTime':
    profileData['closingTime'],

'isOpen24Hours':
    profileData['isOpen24Hours'],

    
      'currentLocation': GeoPoint(
  (profileData['latitude'] as num).toDouble(),
  (profileData['longitude'] as num).toDouble(),
),

      'latitude':
          profileData['latitude'],

      'longitude':
          profileData['longitude'],

      'locationAddress':
          profileData[
              'locationAddress'],

      'mobileVerified':
          true,

      'isActive' : true,

      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    // if (photoUrl != null) {
    //   firestoreData['photoUrl'] =
    //       photoUrl;
    // }

    await labReference.set(
      firestoreData,
      SetOptions(
        merge: true,
      ),
    );

    debugPrint(
      'Laboratory Firestore sync successful.',
    );
  }

  // ============================================================
  // SUBMIT PROFILE
  // ============================================================

  Future<void> submitProfile() async {
    if (isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    bool hasError = false;

    // ----------------------------------------------------------
    // FULL NAME
    // ----------------------------------------------------------

    if (nameController.text
        .trim()
        .isEmpty) {
      nameError = true;

      hasError = true;
    } else {
      nameError = false;
    }

    // ----------------------------------------------------------
// LABORATORY NAME
// ----------------------------------------------------------

if (laboratoryNameController.text.trim().isEmpty) {
  laboratoryNameError = true;
  hasError = true;
} else {
  laboratoryNameError = false;
}

    // ----------------------------------------------------------
    // MOBILE
    // ----------------------------------------------------------

    final String mobile =
        mobileController.text.trim();

    if (mobile.isEmpty ||
        !RegExp(
          r'^[6-9][0-9]{9}$',
        ).hasMatch(mobile)) {
      mobileError = true;

      hasError = true;
    } else {
      mobileError = false;
    }

// ----------------------------------------------------------
// SECONDARY MOBILE
// ----------------------------------------------------------

final String secondaryMobile =
    secondaryPhoneController.text.trim();

if (secondaryMobile.isEmpty ||
    !RegExp(
      r'^[6-9][0-9]{9}$',
    ).hasMatch(secondaryMobile)) {
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
    // ----------------------------------------------------------
    // CATEGORY
    // ----------------------------------------------------------

    if (selectedCategories.isEmpty) {
      categoryError = true;

      hasError = true;
    } else {
      categoryError = false;
    }

    // ----------------------------------------------------------
// SHOP TIMING
// ----------------------------------------------------------

if (!isOpen24Hours) {
  if (openingTime == null) {
    openingTimeError = true;
    hasError = true;
  } else {
    openingTimeError = false;
  }

  if (closingTime == null) {
    closingTimeError = true;
    hasError = true;
  } else {
    closingTimeError = false;
  }
} else {
  openingTimeError = false;
  closingTimeError = false;
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
  // TERMS & CONDITION / PRIVACY POLICY
  // ============================================================
 
  if (!privacyPolicyAccepted) {
    privacyPolicyError =
        'Please accept the Privacy Policy and Terms & Conditions.';

    hasError = true;
  } else {
    privacyPolicyError = null;
  }

  
if (!mounted) {
      return;
    }

    setState(() {});

    if (hasError) {
      return;
    }
    // ----------------------------------------------------------
    // OTP SENT
    // ----------------------------------------------------------

    // if (!otpSent) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text(
    //         'Please send OTP first.',
    //       ),
    //     ),
    //   );

    //   return;
    // }

    // ----------------------------------------------------------
    // OTP VERIFIED
    // ----------------------------------------------------------

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

 
    // ----------------------------------------------------------
    // FIREBASE USER
    // ----------------------------------------------------------

    final User? user =
        auth.currentUser;

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

    // ----------------------------------------------------------
    // START LOADING
    // ----------------------------------------------------------

    setState(() {
      isSubmitting = true;
    });

    try {
      final String uid =
          user.uid;

  final String? formattedOpeningTime =
    isOpen24Hours
        ? null
        : openingTime != null
            ? timeToString(openingTime!)
            : null;

final String? formattedClosingTime =
    isOpen24Hours
        ? null
        : closingTime != null
            ? timeToString(closingTime!)
            : null;

      final List<String>
          categories =
          List<String>.from(
        selectedCategories,
      );

      // final List<String>
      //     searchKeywords =
      //     categories
      //         .map(
      //           (category) =>
      //               category
      //                   .trim()
      //                   .toLowerCase(),
      //         )
      //         .toList();
      final List<String> searchKeywords = {
  ...categories.map(
    (category) => category.trim().toLowerCase(),
  ),
  nameController.text.trim().toLowerCase(),
  laboratoryNameController.text.trim().toLowerCase(),
}.where((keyword) => keyword.isNotEmpty).toList();

      // --------------------------------------------------------
      // LOCAL DATA
      // --------------------------------------------------------

      final Map<String, dynamic>
          localProfileData =
          <String, dynamic>{
        'uid': uid,

        'name':
            nameController.text.trim(),

        // Optional.
        'laboratoryName':
            laboratoryNameController
                .text
                .trim(),

        'mobile':
            mobile,
        'secondaryMobile':
      secondaryPhoneController.text.trim(),

      'state': selectedState!.trim(),

'district': selectedDistrict!.trim(),

'nearestTown':
    nearestCityController.text.trim(),


        'role':
            'laboratory',

        'categories':
            categories,

        'searchKeywords':
            searchKeywords,

        'openingTime':
            formattedOpeningTime,

        'closingTime':
            formattedClosingTime,
        'isOpen24Hours': isOpen24Hours,

        'latitude':
            currentLocation!.latitude,

        'longitude':
            currentLocation!.longitude,

        'locationAddress':
            currentLocation! .placeName,

        'mobileVerified':
            true,
      };

      // --------------------------------------------------------
      // SAVE LOCALLY FIRST
      // --------------------------------------------------------

      await saveBasicUserToHive(
        localProfileData,
      );

      // --------------------------------------------------------
      // LOGIN STATUS
      // --------------------------------------------------------

      await CommonProfileService.saveLogin(
  uid: uid,
  name: nameController.text.trim(),
  mobile: mobile,
  role: 'laboratory',
);

      // Capture the photo reference before
      // leaving this screen.
      final File? photoToUpload =
          profilePhoto;

      // --------------------------------------------------------
      // SMOOTH STUDENT-STYLE LOADING
      // --------------------------------------------------------

      await Future.delayed(
        const Duration(
          seconds: 2,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      // --------------------------------------------------------
      // GO TO HOME
      // --------------------------------------------------------

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ScreenHome(),
        ),
        (route) => false,
      );

      // --------------------------------------------------------
      // FIRESTORE IN BACKGROUND
      //
      // The user does NOT wait for this.
      // --------------------------------------------------------

      saveProfileToFirestore(
        localProfileData,
        photoToUpload,
      ).then((_) {
        debugPrint(
          'Laboratory Firestore background sync completed.',
        );
      }).catchError((error) {
        debugPrint(
          'Laboratory Firestore background sync failed: $error',
        );
      });
    } catch (e) {
      debugPrint(
        'Laboratory submit error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save laboratory profile: $e',
          ),
        ),
      );
    }
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

 // ============================================================
  // CATEGORY
  // ============================================================

  bool isCategoryDropdownOpen = false;

  final List<String> laboratoryCategories = [
    'Blood Checking Lab',
    'Water Checking Lab',
    'Pathology Lab',
    'Clinical Laboratory',
    'Diagnostic Laboratory',
    'Medical Laboratory',
    'Blood Test Laboratory',
    'Urine Test Laboratory',
    'X-Ray Laboratory',
    'CT Scan Laboratory',
    'MRI Laboratory',
    'Ultrasound Laboratory',
    'ECG Laboratory',
    'Biochemistry Laboratory',
    'Microbiology Laboratory',
    'Hematology Laboratory',
    'Histopathology Laboratory',
    'Hormone Testing Laboratory',
    'Diabetes Testing Laboratory',
    'Thyroid Testing Laboratory',
    'Food Testing Laboratory',
    'Drug Testing Laboratory',
  ];

  final List<String> selectedCategories = [];
  final List<String> customCategories = [];

  List<String> filteredCategories = [];


 List<String> get allCategories {

    final List<String> result = [];

    for (final category in laboratoryCategories) {

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

              hintText:'Enter Laboratory category',

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
  // CATEGORY SECTION
  // ============================================================

  Widget categorySection() {
    final categories =
        filteredCategories;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        sectionTitle(
          'Laboratory Categories',
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
                                    'Select Laboratory categories',
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
    child: Text( AppLocalizations.of(context)!.enteradigitmobilenumber,
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

//   Widget secondaryMobileSection() {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       const Text(
//         'Secondary Mobile Number',
//         style: TextStyle(
//           color: Color(0xFF252525),
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//         ),
//       ),

//       const SizedBox(height: 8),

//       TextFormField(
//         controller: secondaryPhoneController,
//         keyboardType: TextInputType.phone,
//         maxLength: 10,

//         inputFormatters: [
//           FilteringTextInputFormatter.digitsOnly,
//         ],

//         decoration: fieldDecoration(
//           hint: 'Enter secondary mobile number (optional)',
//           icon: Icons.phone_android_outlined,
//         ).copyWith(
//           counterText: '',
//         ),

//         validator: (value) {
//           final number = value?.trim() ?? '';

//           // Optional field.
//           if (number.isEmpty) {
//             return null;
//           }

//           if (number.length != 10) {
//             return 'Enter a valid 10-digit mobile number';
//           }

//           return null;
//         },
//       ),

//       const SizedBox(height: 5),

//       const Text(
//         'You can add same number,if another number is not available.',
//         style: TextStyle(
//           color: Color(0xFF777777),
//           fontSize: 12,
//         ),
//       ),
//       const  Text(
//         'Note : This number will be shown to users when they choose to call you.',
//         style: TextStyle(
//           color: Color(0xFF777777),
//           fontSize: 12,
//         ),
//       ),
//     ],
//   );
// }
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

        onChanged: (value) {
          if (secondaryMobileError &&
              RegExp(r'^[6-9][0-9]{9}$').hasMatch(value.trim())) {
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
         Padding(
          padding: EdgeInsets.only(
            left: 8,
            top: 5,
          ),
          child: Text( AppLocalizations.of(context)!.enteradigitmobilenumber,
           // 'Enter a valid 10-digit secondary mobile number.',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
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
          'Laboratory Location',
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
                      'Add your Laboratory location',
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
                              : 'Use Laboratory Location',
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
            labelText: 'Laboratory Location',
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
  currentLocation = LaboratoryLocation(
    placeName: placeName.trim(),
    latitude: null,
    longitude: null,
  );
  locationError = false;
  isGettingLocation = false;
  isSearchingLocation = false;
});

showMessage(
  'Laboratory location added.',
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
  currentLocation = LaboratoryLocation(
    placeName: placeName,
    latitude: position.latitude,
    longitude: position.longitude,
  );

  locationError = false;
});

    showMessage(
      'Laboratory location added.',
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
  // PHOTO SECTION
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
  // SUBMIT BUTTON
  // ============================================================

  Widget submitButton() {
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed:
            isSubmitting
                ? null
                : submitProfile,
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF159B16),
          foregroundColor:
              Colors.white,
          disabledBackgroundColor:
              Colors.grey.shade400,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
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
                text: 'Laboratory ',
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
                CrossAxisAlignment.stretch,
            children: [
              // =================================================
              // SUBTITLE
              // =================================================

              const Text(
                'Fill in your details to create your laboratory profile',
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
                  icon:
                      Icons.person,
                ),
              ),

              if (nameError)
                const Padding(
                  padding:
                      EdgeInsets.only(
                    left: 8,
                    top: 5,
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
                height: 22,
              ),

              // =================================================
              // LABORATORY NAME - OPTIONAL
              // =================================================

              sectionTitle(
                'Laboratory Name',
              ),

              const SizedBox(
                height: 9,
              ),

              TextField(
  controller: laboratoryNameController,
  textInputAction: TextInputAction.next,

  onChanged: (value) {
    if (value.trim().isNotEmpty && laboratoryNameError) {
      setState(() {
        laboratoryNameError = false;
      });
    }
  },

  decoration: fieldDecoration(
    hintText: 'Enter laboratory name',
    hasError: laboratoryNameError,
    icon: Icons.biotech_outlined,
  ),
),

if (laboratoryNameError)
  const Padding(
    padding: EdgeInsets.only(
      left: 8,
      top: 5,
    ),
    child: Text(
      'Please enter laboratory name.',
      style: TextStyle(
        color: Colors.red,
        fontSize: 12,
      ),
    ),
  ),

              const Padding(
                padding:
                    EdgeInsets.only(
                  left: 8,
                  top: 5,
                ),
                // child: Text(
                //   'Optional — if you do not have a laboratory name, you can leave this empty.',
                //   style: TextStyle(
                //     color:
                //         Color(0xFF777777),
                //     fontSize: 12,
                //   ),
                // ),
              ),

              const SizedBox(height: 22),
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


              const SizedBox(height: 20),
              // =================================================
              // CATEGORY
              // =================================================
               secondaryMobileSection(),
              const SizedBox(height: 20),

                stateSection(),

const SizedBox(height: 20),

districtSection(),
const SizedBox(height: 20),
sectionTitle('Nearest City'),
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
              
              categorySection(),

              const SizedBox(
                height: 20,
              ),

             

              // // =================================================
              // // CLOSING TIME
              // // =================================================

              // timeBox(
              //   title: 'Closing Time',
              //   hint:
              //       'Select closing time',
              //   value: closingTime,
              //   onTap:
              //       selectClosingTime,
              //   hasError:
              //       closingTimeError,
              // ),
              shopTimingSection(),

              const SizedBox(
                height: 22,
              ),

              // =================================================
              // CURRENT LOCATION
              // =================================================

              locationSection(),

              const SizedBox(
                height: 22,
              ),

              // =================================================
              // PHOTO
              // =================================================
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


              // =================================================
              // SUBMIT
              // =================================================

              submitButton(),

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


  // ============================================================
  // CURRENT LOCATION PERMISSION
  // ============================================================

  // Future<bool> checkLocationPermission() async {
  //   final bool serviceEnabled =
  //       await Geolocator.isLocationServiceEnabled();

  //   if (!serviceEnabled) {
  //     if (!mounted) return false;

  //     await showDialog(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           title: const Text(
  //             'Location is disabled',
  //           ),
  //           content: const Text(
  //             'Please turn on location services '
  //             'and try again.',
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.pop(context);
  //               },
  //               child: const Text(
  //                 'OK',
  //               ),
  //             ),
  //           ],
  //         );
  //       },
  //     );

  //     return false;
  //   }

  //   LocationPermission permission =
  //       await Geolocator.checkPermission();

  //   if (permission ==
  //       LocationPermission.denied) {
  //     permission =
  //         await Geolocator.requestPermission();
  //   }

  //   if (permission ==
  //           LocationPermission.denied ||
  //       permission ==
  //           LocationPermission.deniedForever) {
  //     if (!mounted) return false;

  //     await showDialog(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           title: const Text(
  //             'Location permission required',
  //           ),
  //           content: const Text(
  //             'Current location is required for '
  //             'laboratory registration. Please '
  //             'allow location permission.',
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.pop(context);
  //               },
  //               child: const Text(
  //                 'Cancel',
  //               ),
  //             ),
  //             ElevatedButton(
  //               onPressed: () async {
  //                 Navigator.pop(context);

  //                 await Geolocator
  //                     .openAppSettings();
  //               },
  //               child: const Text(
  //                 'Open Settings',
  //               ),
  //             ),
  //           ],
  //         );
  //       },
  //     );

  //     return false;
  //   }

  //   return true;
  // }

  // InputDecoration fieldDecoration({
  //   required String hintText,
  //   //required bool hasError,
  //   IconData? icon,
  // }) {
  //   return InputDecoration(
  //     hintText: hintText,

  //     prefixIcon: icon != null
  //         ? Icon(
  //             icon,
  //             color:
  //                 const Color(0xFF16803C),
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
  //             : const Color(
  //                 0xFF16803C,
  //               ),
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
   // 'currentLocation':
      //     GeoPoint(
      //   profileData['latitude']
      //       as double,
      //   profileData['longitude']
      //       as double,
      // ),

      // ============================================================
  // // OPENING TIME
  // // ============================================================

  // Future<void> selectOpeningTime() async {
  //   final TimeOfDay? picked =
  //       await showTimePicker(
  //     context: context,
  //     initialTime:
  //         openingTime ??
  //             const TimeOfDay(
  //               hour: 9,
  //               minute: 0,
  //             ),
  //   );

  //   if (picked == null) {
  //     return;
  //   }

  //   if (!mounted) return;

  //   setState(() {
  //     openingTime = picked;

  //     openingTimeError = false;
  //   });
  // }

  // // ============================================================
  // // CLOSING TIME
  // // ============================================================

  // Future<void> selectClosingTime() async {
  //   final TimeOfDay? picked =
  //       await showTimePicker(
  //     context: context,
  //     initialTime:
  //         closingTime ??
  //             const TimeOfDay(
  //           hour: 21,
  //       minute: 0,
  //     ),
  //   );

  //   if (picked == null) {
  //     return;
  //   }

  //   if (!mounted) return;

  //   setState(() {
  //     closingTime = picked;

  //     closingTimeError = false;
  //   });
  // }

  // // ============================================================
  // // FORMAT TIME
  // // ============================================================

  
 // ============================================================
  // TIME BOX
  // ============================================================

  // Widget timeBox({
  //   required String title,
  //   required String hint,
  //   required TimeOfDay? value,
  //   required VoidCallback onTap,
  //   required bool hasError,
  // }) {
  //   return Column(
  //     crossAxisAlignment:
  //         CrossAxisAlignment.start,
  //     children: [
  //       sectionTitle(title),

  //       const SizedBox(height: 9),

  //       InkWell(
  //         borderRadius:
  //             BorderRadius.circular(20),
  //         onTap: onTap,
  //         child: Container(
  //           height: 62,
  //           width: double.infinity,
  //           decoration: BoxDecoration(
  //             color:
  //                 const Color(0xFFF9F9F9),
  //             borderRadius:
  //                 BorderRadius.circular(20),
  //             border: Border.all(
  //               color: hasError
  //                   ? Colors.red
  //                   : Colors.grey.shade300,
  //               width:
  //                   hasError ? 2 : 1.5,
  //             ),
  //           ),
  //           child: Row(
  //             children: [
  //               const SizedBox(
  //                 width: 17,
  //               ),

  //               const Icon(
  //                 Icons.access_time,
  //                 color:
  //                     Color(0xFF16803C),
  //                 size: 27,
  //               ),

  //               const SizedBox(
  //                 width: 12,
  //               ),

  //               Expanded(
  //                 child: Text(
  //                   value == null
  //                       ? hint
  //                       : formatTime(
  //                           value,
  //                         ),
  //                   style: TextStyle(
  //                     color: value == null
  //                         ? Colors.grey
  //                         : Colors.black,
  //                     fontSize: 16,
  //                   ),
  //                 ),
  //               ),

  //               const Icon(
  //                 Icons
  //                     .keyboard_arrow_down,
  //                 color: Colors.grey,
  //               ),

  //               const SizedBox(
  //                 width: 12,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),

  //       if (hasError)
  //         const Padding(
  //           padding: EdgeInsets.only(
  //             left: 8,
  //             top: 5,
  //           ),
  //           child: Text(
  //             'Please select this time.',
  //             style: TextStyle(
  //               color: Colors.red,
  //               fontSize: 12,
  //             ),
  //           ),
  //         ),
  //     ],
  //   );
  // }



              // // =================================================
              // // OPENING TIME
              // // =================================================

              // timeBox(
              //   title: 'Opening Time',
              //   hint:
              //       'Select opening time',
              //   value: openingTime,
              //   onTap:
              //       selectOpeningTime,
              //   hasError:
              //       openingTimeError,
              // ),

              // const SizedBox(
              //   height: 20,
              // ),

               //  void showMessage(
  //   String message, {
  //   bool error = false,
  // }) {
  //   if (!mounted) return;

  //   ScaffoldMessenger.of(context)
  //     ..hideCurrentSnackBar()
  //     ..showSnackBar(
  //       SnackBar(
  //         content: Text(message),
  //         backgroundColor: error
  //             ? Colors.red
  //             : const Color(0xFF12652F),
  //         behavior: SnackBarBehavior.floating,
  //         shape: RoundedRectangleBorder(
  //           borderRadius:
  //               BorderRadius.circular(12),
  //         ),
  //       ),
  //     );
  // }

 // String formatTime(TimeOfDay time) {
  //   final int hour =
  //       time.hourOfPeriod == 0
  //           ? 12
  //           : time.hourOfPeriod;

  //   final String minute =
  //       time.minute.toString().padLeft(
  //             2,
  //             '0',
  //           );

  //   final String period =
  //       time.period == DayPeriod.am
  //           ? 'AM'
  //           : 'PM';

  //   return '$hour:$minute $period';
  // }