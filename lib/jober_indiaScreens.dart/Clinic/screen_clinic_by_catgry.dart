// import 'dart:async';
// import 'dart:math' as math;

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
// import 'package:url_launcher/url_launcher.dart';


//   class ScreenClinicsByCategory extends StatefulWidget {
//   final String selectedCategory;

//   const ScreenClinicsByCategory({
//     super.key,
//     required this.selectedCategory,
//   });

//   @override
//   State<ScreenClinicsByCategory> createState() =>
//       _ScreenClinicsByCategoryState();
// }

// // ============================================================
// // CLINIC MODEL
// // ============================================================

// class ClinicBrowseData {
//   final String uid;
//   final String clinicName;
//   final String username;
//   final String phone;
//   final String secondaryPhone;
//   final String placeName;

//   final double latitude;
//   final double longitude;

//   double distanceKm;

//   ClinicBrowseData({
//     required this.uid,
//     required this.clinicName,
//     required this.username,
//     required this.phone,
//     required this.secondaryPhone,
//     required this.placeName,
//     required this.latitude,
//     required this.longitude,
//     required this.distanceKm,
//   });
// }

// // ============================================================
// // PAGE
// // ============================================================

// class _ScreenClinicsByCategoryState
//     extends State<ScreenClinicsByCategory> {

//   static const Color green =
//       Color(0xFF138808);

//   static const double maxRadiusKm =
//       50.0;

//   final FirebaseFirestore firestore =
//       FirebaseFirestore.instance;

//   final FirebaseAuth auth =
//       FirebaseAuth.instance;

//   final ScrollController _scrollController =
//       ScrollController();

//   // ============================================================
//   // PAGINATION
//   // ============================================================

//   static const int pageSize = 20;

//   DocumentSnapshot<Map<String, dynamic>>? lastClinicDocument;

//   bool hasMoreClinics = true;
//   bool isLoadingMore = false;

//   bool isLoading = true;

//   bool liveLocationOn = false;

//   String? errorMessage;

//   double? userLatitude;
//   double? userLongitude;

//   List<ClinicBrowseData> clinics = [];

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   void initState() {
//     super.initState();
//      _scrollController.addListener(
//       _onScroll,
//     );
//     _loadClinics();
//   }

//   // ============================================================
//   // PAGINATION SCROLL LISTENER
//   // ============================================================

//   void _onScroll() {
//     if (!_scrollController.hasClients) {
//       return;
//     }

//     final double position =
//         _scrollController.position.pixels;

//     final double maxExtent =
//         _scrollController.position.maxScrollExtent;

//     // Start loading when user is about 300 pixels
//     // away from the bottom.
//     if (maxExtent - position <= 300) {
//       _loadMoreClinics();
//     }
//   }
//   // ============================================================
//   // LOAD USER LIVE LOCATION
//   // ============================================================

//   Future<bool> _loadUserLiveLocation() async {
//     final User? user =
//         auth.currentUser;

//     if (user == null) {
//       errorMessage =
//           'Please login to find nearby clinics.';

//       return false;
//     }

//     final DocumentSnapshot<
//         Map<String, dynamic>> locationDoc =
//         await firestore
//             .collection('liveLocations')
//             .doc(user.uid)
//             .get();

//     if (!locationDoc.exists) {
//       errorMessage =
//           'Please turn ON LIVE Location from Home to find clinics within 50 km.';

//       return false;
//     }

//     final Map<String, dynamic>? data =
//         locationDoc.data();

//     if (data == null) {
//       errorMessage =
//           'Please turn ON LIVE Location from Home.';

//       return false;
//     }

//     final bool isLive =
//         data['isLive'] == true;

//     if (!isLive) {
//       errorMessage =
//           'Please turn ON LIVE Location from Home to find clinics within 50 km.';

//       return false;
//     }

//     final dynamic latValue =
//         data['latitude'];

//     final dynamic lngValue =
//         data['longitude'];

//     if (latValue == null ||
//         lngValue == null) {
//       errorMessage =
//           'Your live location is not available yet.';

//       return false;
//     }

//     final double? latitude =
//         double.tryParse(
//       latValue.toString(),
//     );

//     final double? longitude =
//         double.tryParse(
//       lngValue.toString(),
//     );

//     if (latitude == null ||
//         longitude == null) {
//       errorMessage =
//           'Unable to read your live location.';

//       return false;
//     }

//     userLatitude = latitude;
//     userLongitude = longitude;

//     liveLocationOn = true;

//     return true;
//   }

//   // ============================================================
//   // LOAD CLINICS
//   // ============================================================

//  // ============================================================
//   // LOAD FIRST PAGE
//   // ============================================================

//   Future<void> _loadClinics() async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//       isLoadingMore = false;
//       errorMessage = null;
//       clinics = [];
//       liveLocationOn = false;

//       lastClinicDocument = null;
//       hasMoreClinics = true;
//     });

//     try {
//       final bool locationAvailable =
//           await _loadUserLiveLocation();

//       if (!locationAvailable) {
//         if (!mounted) return;

//         setState(() {
//           isLoading = false;
//         });

//         return;
//       }

//       await _loadMoreClinics(
//         isFirstPage: true,
//       );
//     } catch (e) {
//       debugPrint(
//         'Clinic nearby loading error: $e',
//       );

//       if (!mounted) return;

//       setState(() {
//         isLoading = false;
//         errorMessage =
//             'Unable to load nearby clinics.';
//       });
//     }
//   }

//   // ============================================================
//   // LOAD MORE CLINICS
//   // ============================================================

//   Future<void> _loadMoreClinics({
//     bool isFirstPage = false,
//   }) async {
//     if (!hasMoreClinics ||
//         isLoadingMore ||
//         userLatitude == null ||
//         userLongitude == null) {
//       return;
//     }

//     if (!isFirstPage && !mounted) {
//       return;
//     }

//     if (mounted) {
//       setState(() {
//         isLoadingMore = true;
//       });
//     }

//     try {
//       Query<Map<String, dynamic>> query =
//           firestore
//               .collection('clinics')
//               .where(
//                 'categories',
//                 arrayContains:
//                     widget.selectedCategory,
//               )
//               .where(
//                 'isActive',
//                 isEqualTo: true,
//               )
//               .orderBy(
//                 'updatedAt',
//                 descending: true,
//               )
//               .limit(pageSize);

//       if (lastClinicDocument != null) {
//         query = query.startAfterDocument(
//           lastClinicDocument!,
//         );
//       }

//       final QuerySnapshot<
//           Map<String, dynamic>> snapshot =
//           await query.get();

//       if (snapshot.docs.isEmpty) {
//         if (!mounted) return;

//         setState(() {
//           hasMoreClinics = false;
//           isLoading = false;
//           isLoadingMore = false;
//         });

//         return;
//       }

//       // ----------------------------------------------------------
//       // SAVE PAGINATION CURSOR
//       // ----------------------------------------------------------

//       lastClinicDocument =
//           snapshot.docs.last;

//       if (snapshot.docs.length < pageSize) {
//         hasMoreClinics = false;
//       }

//       final List<ClinicBrowseData> newClinics = [];

//       // ----------------------------------------------------------
//       // PROCESS CLINICS
//       // ----------------------------------------------------------

//       for (final document in snapshot.docs) {
//         final Map<String, dynamic> data =
//             document.data();

//         // --------------------------------------------------------
//         // LOCATION
//         // --------------------------------------------------------

//         final dynamic latValue =
//             data['latitude'];

//         final dynamic lngValue =
//             data['longitude'];

//         if (latValue == null ||
//             lngValue == null) {
//           continue;
//         }

//         final double? latitude =
//             double.tryParse(
//           latValue.toString(),
//         );

//         final double? longitude =
//             double.tryParse(
//           lngValue.toString(),
//         );

//         if (latitude == null ||
//             longitude == null) {
//           continue;
//         }

//         // --------------------------------------------------------
//         // DISTANCE
//         // --------------------------------------------------------

//         final double distanceKm =
//             _calculateDistanceKm(
//           userLatitude!,
//           userLongitude!,
//           latitude,
//           longitude,
//         );

//         // --------------------------------------------------------
//         // 50 KM LIMIT
//         // --------------------------------------------------------

//         if (distanceKm > maxRadiusKm) {
//           continue;
//         }

//         // --------------------------------------------------------
//         // SECONDARY PHONE
//         // --------------------------------------------------------

//         String secondaryPhone =
//             data['secondaryPhone']
//                     ?.toString()
//                     .trim() ??
//                 '';

//         if (secondaryPhone.isEmpty) {
//           secondaryPhone =
//               data['secondaryMobile']
//                       ?.toString()
//                       .trim() ??
//                   '';
//         }

//         newClinics.add(
//           ClinicBrowseData(
//             uid: data['uid']
//                     ?.toString() ??
//                 document.id,

//             clinicName:
//                 data['clinicName']
//                         ?.toString()
//                         .trim() ??
//                     'clinic',

//             username:
//                 data['username']
//                         ?.toString()
//                         .trim() ??
//                     '',

//             phone:
//                 data['phone']
//                         ?.toString()
//                         .trim() ??
//                     '',

//             secondaryPhone:
//                 secondaryPhone,

//             placeName:
//                 data['placeName']
//                         ?.toString()
//                         .trim() ??
//                     'Clinic location',

//             latitude:
//                 latitude,

//             longitude:
//                 longitude,

//             distanceKm:
//                 distanceKm,
//           ),
//         );
//       }

//       // ----------------------------------------------------------
//       // ADD TO EXISTING RESULTS
//       // ----------------------------------------------------------

//       clinics.addAll(newClinics);

//       // ----------------------------------------------------------
//       // SORT ALL LOADED CLINICS
//       // NEAREST → FARTHEST
//       // ----------------------------------------------------------

//       clinics.sort(
//         (a, b) =>
//             a.distanceKm.compareTo(
//           b.distanceKm,
//         ),
//       );

//       if (!mounted) return;

//       setState(() {
//         isLoading = false;
//         isLoadingMore = false;
//       });

//       // ----------------------------------------------------------
//       // IMPORTANT
//       //
//       // A Firestore page can contain 20 clinics, but after
//       // the 50 km filtering maybe only 2 are nearby.
//       //
//       // If there are still more Firestore documents, automatically
//       // fetch the next page so the user gets enough nearby clinics.
//       // ----------------------------------------------------------

//       if (newClinics.isEmpty &&
//           hasMoreClinics &&
//           mounted) {
//         await _loadMoreClinics();
//       }
//     } catch (e) {
//       debugPrint(
//         'Load more clinics error: $e',
//       );

//       if (!mounted) return;

//       setState(() {
//         isLoading = false;
//         isLoadingMore = false;
//         errorMessage =
//             'Unable to load more clinics.';
//       });
//     }
//   }
//   // ============================================================
//   // DISTANCE
//   // ============================================================

//   double _calculateDistanceKm(
//     double lat1,
//     double lon1,
//     double lat2,
//     double lon2,
//   ) {
//     const double earthRadiusKm =
//         6371.0;

//     final double dLat =
//         _degreesToRadians(
//       lat2 - lat1,
//     );

//     final double dLon =
//         _degreesToRadians(
//       lon2 - lon1,
//     );

//     final double a =
//         math.sin(dLat / 2) *
//                 math.sin(dLat / 2) +
//             math.cos(
//                   _degreesToRadians(lat1),
//                 ) *
//                 math.cos(
//                   _degreesToRadians(lat2),
//                 ) *
//                 math.sin(dLon / 2) *
//                 math.sin(dLon / 2);

//     final double c =
//         2 *
//             math.atan2(
//               math.sqrt(a),
//               math.sqrt(1 - a),
//             );

//     return earthRadiusKm * c;
//   }

//   double _degreesToRadians(
//     double degrees,
//   ) {
//     return degrees *
//         math.pi /
//         180.0;
//   }

//   // ============================================================
//   // DISTANCE TEXT
//   // ============================================================

//   String _distanceText(
//     double distanceKm,
//   ) {
//     final double meters =
//         distanceKm * 1000;

//     if (meters < 1000) {
//       if (meters < 10) {
//         return '${meters.round()} meters';
//       }

//       return '${meters.round()} meters';
//     }

//     if (distanceKm < 10) {
//       return '${distanceKm.toStringAsFixed(1)} kilometers';
//     }

//     return '${distanceKm.toStringAsFixed(0)} kilometers';
//   }

//   // ============================================================
//   // CHAT
//   // ============================================================

//   void _openChat(
//     ClinicBrowseData clinic,
//   ) {
//     final Map<String, dynamic> chatUser =
//         {
//       'uid': clinic.uid,

//       'name': clinic.clinicName,

//       'clinicName':
//           clinic.clinicName,

//       'username':
//           clinic.username,

//       'phone':
//           clinic.phone,

//       'secondaryPhone':
//           clinic.secondaryPhone,

//       'role':
//           'clinic',

//       'profession':
//           'clinic',

//       'locationName':
//           clinic.placeName,

//       'latitude':
//           clinic.latitude,

//       'longitude':
//           clinic.longitude,

//       'distance':
//           clinic.distanceKm,

//       'isActive':
//           true,
//     };

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             ScreenMessage(
//           chatUser: chatUser,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // CALL
//   // ============================================================

//   Future<void> _callClinic(
//     ClinicBrowseData clinic,
//   ) async {
//     final String number =
//         clinic.secondaryPhone.trim();

//     if (number.isEmpty) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context)
//         .showSnackBar(
//           const SnackBar(
//             content: Text(
//               'This clinic has not added a secondary phone number.',
//             ),
//           ),
//         );

//       return;
//     }

//     final Uri uri =
//         Uri(
//       scheme: 'tel',
//       path: number,
//     );

//     try {
//       final bool canCall =
//           await canLaunchUrl(uri);

//       if (!canCall) {
//         if (!mounted) return;

//         ScaffoldMessenger.of(context)
//             .showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Unable to open the phone dialer.',
//             ),
//           ),
//         );

//         return;
//       }

//       await launchUrl(uri);
//     } catch (e) {
//       debugPrint(
//         'Clinic call error: $e',
//       );
//     }
//   }

//   // ============================================================
//   // OPEN CLINIC LOCATION
//   // ============================================================

//   Future<void> _openLocation(
//     ClinicBrowseData clinic,
//   ) async {
//     final Uri googleMapsUri =
//         Uri.parse(
//       'https://www.google.com/maps/search/?api=1'
//       '&query=${clinic.latitude},${clinic.longitude}',
//     );

//     try {
//       final bool launched =
//           await launchUrl(
//         googleMapsUri,
//         mode: LaunchMode.externalApplication,
//       );

//       if (!launched &&
//           mounted) {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Unable to open the clinic location.',
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       debugPrint(
//         'Clinic location error: $e',
//       );
//     }
//   }

//   // ============================================================
//   // CLINIC CARD
//   // ============================================================

//   Widget _clinicCard(
//     ClinicBrowseData clinic,
//   ) {
//     return Container(
//       margin: const EdgeInsets.only(
//         bottom: 12,
//       ),

//       padding: const EdgeInsets.all(15),

//       decoration: BoxDecoration(
//         color: Colors.white,

//         borderRadius:
//             BorderRadius.circular(18),

//         border: Border.all(
//           color: Colors.grey.shade200,
//         ),

//         boxShadow: [
//           BoxShadow(
//             color:
//                 Colors.black.withValues(
//               alpha: 0.04,
//             ),
//             blurRadius: 8,
//             offset:
//                 const Offset(0, 3),
//           ),
//         ],
//       ),

//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,

//         children: [

//           // ======================================================
//           // NAME + DISTANCE
//           // ======================================================

//           Row(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,

//             children: [

//               Container(
//                 width: 48,
//                 height: 48,

//                 decoration:
//                     BoxDecoration(
//                   color:
//                       green.withValues(
//                     alpha: 0.10,
//                   ),
//                   shape:
//                       BoxShape.circle,
//                 ),

//                 child: const Icon(
//                   Icons.local_hospital_outlined,
//                   color: green,
//                   size: 26,
//                 ),
//               ),

//               const SizedBox(
//                 width: 12,
//               ),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,

//                   children: [

//                     Text(
//                       clinic.clinicName,
//                       maxLines: 2,
//                       overflow:
//                           TextOverflow.ellipsis,

//                       style:
//                           const TextStyle(
//                         fontSize: 17,
//                         fontWeight:
//                             FontWeight.w700,
//                         color:
//                             Color(0xFF202124),
//                       ),
//                     ),

//                     if (clinic.username.isNotEmpty)
//                       Padding(
//                         padding:
//                             const EdgeInsets.only(
//                           top: 3,
//                         ),
//                         child: Text(
//                           '@${clinic.username}',
//                           style:
//                               TextStyle(
//                             fontSize: 12,
//                             color:
//                                 Colors.grey.shade600,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),

//               // --------------------------------------------------
//               // DISTANCE
//               // --------------------------------------------------

//               if (liveLocationOn)
//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(
//                     horizontal: 9,
//                     vertical: 6,
//                   ),

//                   decoration:
//                       BoxDecoration(
//                     color:
//                         green.withValues(
//                       alpha: 0.09,
//                     ),

//                     borderRadius:
//                         BorderRadius.circular(
//                       10,
//                     ),
//                   ),

//                   child: Text(
//                     _distanceText(
//                       clinic.distanceKm,
//                     ),

//                     style:
//                         const TextStyle(
//                       color: green,
//                       fontSize: 12,
//                       fontWeight:
//                           FontWeight.w700,
//                     ),
//                   ),
//                 ),
//             ],
//           ),

//           const SizedBox(
//             height: 12,
//           ),

//           // ======================================================
//           // LOCATION
//           // ======================================================

//           Row(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,

//             children: [

//               const Icon(
//                 Icons.location_on_outlined,
//                 size: 18,
//                 color: Colors.red,
//               ),

//               const SizedBox(
//                 width: 6,
//               ),

//               Expanded(
//                 child: Text(
//                   clinic.placeName.isEmpty
//                       ? 'Location available'
//                       : clinic.placeName,

//                   maxLines: 2,

//                   overflow:
//                       TextOverflow.ellipsis,

//                   style: TextStyle(
//                     fontSize: 13,
//                     color:
//                         Colors.grey.shade700,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(
//             height: 14,
//           ),

//           // ======================================================
//           // THREE BUTTONS
//           // ======================================================

//           Row(
//             children: [

//               Expanded(
//                 child: _actionButton(
//                   icon:
//                       Icons.chat_bubble_outline,
//                   label: 'Chat',
//                   onPressed: () {
//                     _openChat(clinic);
//                   },
//                 ),
//               ),

//               const SizedBox(
//                 width: 8,
//               ),

//               Expanded(
//                 child: _actionButton(
//                   icon:
//                       Icons.phone_outlined,
//                   label: 'Call',
//                   onPressed: () {
//                     _callClinic(clinic);
//                   },
//                 ),
//               ),

//               const SizedBox(
//                 width: 8,
//               ),

//               Expanded(
//                 child: _actionButton(
//                   icon:
//                       Icons.location_on_outlined,
//                   label: 'Location',
//                   onPressed: () {
//                     _openLocation(clinic);
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // ACTION BUTTON
//   // ============================================================

//   Widget _actionButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return SizedBox(
//       height: 42,

//       child: OutlinedButton.icon(
//         onPressed: onPressed,

//         icon: Icon(
//           icon,
//           size: 18,
//         ),

//         label: Text(
//           label,
//           style: const TextStyle(
//             fontSize: 12,
//             fontWeight:
//                 FontWeight.w600,
//           ),
//         ),

//         style:
//             OutlinedButton.styleFrom(
//           foregroundColor: green,

//           side: BorderSide(
//             color:
//                 green.withValues(
//               alpha: 0.45,
//             ),
//           ),

//           padding:
//               const EdgeInsets.symmetric(
//             horizontal: 5,
//           ),

//           shape:
//               RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(12),
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // LOCATION OFF SCREEN
//   // ============================================================

//   Widget _locationRequired() {
//     return Center(
//       child: Padding(
//         padding:
//             const EdgeInsets.all(28),

//         child: Column(
//           mainAxisSize:
//               MainAxisSize.min,

//           children: [

//             Container(
//               width: 72,
//               height: 72,

//               decoration:
//                   BoxDecoration(
//                 color:
//                     Colors.red.withValues(
//                   alpha: 0.08,
//                 ),
//                 shape:
//                     BoxShape.circle,
//               ),

//               child: const Icon(
//                 Icons.location_off_outlined,
//                 color: Colors.red,
//                 size: 36,
//               ),
//             ),

//             const SizedBox(
//               height: 18,
//             ),

//             const Text(
//               'LIVE Location is OFF',
//               textAlign:
//                   TextAlign.center,

//               style: TextStyle(
//                 fontSize: 19,
//                 fontWeight:
//                     FontWeight.w700,
//               ),
//             ),

//             const SizedBox(
//               height: 8,
//             ),

//             Text(
//               errorMessage ??
//                   'Turn ON LIVE Location from Home to see clinics within 50 km.',

//               textAlign:
//                   TextAlign.center,

//               style: TextStyle(
//                 fontSize: 14,
//                 color:
//                     Colors.grey.shade700,
//               ),
//             ),

//             const SizedBox(
//               height: 20,
//             ),

//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.pop(context);
//               },

//               icon: const Icon(
//                 Icons.arrow_back,
//               ),

//               label: const Text(
//                 'Go to Home',
//               ),

//               style:
//                   ElevatedButton.styleFrom(
//                 backgroundColor:
//                     green,
//                 foregroundColor:
//                     Colors.white,
//                 elevation: 0,
//                 shape:
//                     RoundedRectangleBorder(
//                   borderRadius:
//                       BorderRadius.circular(
//                     14,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // EMPTY
//   // ============================================================

//   Widget _emptyClinics() {
//     return Center(
//       child: Padding(
//         padding:
//             const EdgeInsets.all(28),

//         child: Column(
//           mainAxisSize:
//               MainAxisSize.min,

//           children: [

//             const Icon(
//               Icons.local_hospital_outlined,
//               size: 60,
//               color: Colors.grey,
//             ),

//             const SizedBox(
//               height: 14,
//             ),

//             const Text(
//               'No clinics found nearby',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight:
//                     FontWeight.w700,
//               ),
//             ),

//             const SizedBox(
//               height: 7,
//             ),

//             Text(
//               'There are no active clinics in this category within 50 km of your location.',

//               textAlign:
//                   TextAlign.center,

//               style: TextStyle(
//                 color:
//                     Colors.grey.shade600,
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor:
//           const Color(0xFFF8F9F8),

//       appBar: AppBar(
//         backgroundColor:
//             Colors.white,

//         foregroundColor:
//             Colors.black,

//         elevation: 0,

//         title: Text(
//           widget.selectedCategory,
//           maxLines: 2,
//           overflow:
//               TextOverflow.ellipsis,

//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight:
//                 FontWeight.w700,
//           ),
//         ),

//         centerTitle: true,

//         actions: [
//           IconButton(
//             onPressed:
//                 isLoading
//                     ? null
//                     : _loadClinics,
//             icon:
//                 const Icon(
//               Icons.refresh,
//             ),
//           ),
//         ],
//       ),

//       body: isLoading
//           ? const Center(
//               child:
//                   CircularProgressIndicator(
//                 color: green,
//               ),
//             )

//           : !liveLocationOn
//               ? _locationRequired()

//               : clinics.isEmpty
//                   ? _emptyClinics()

//                   : RefreshIndicator(
//                       onRefresh:
//                           _loadClinics,

//                       color: green,

//                      child: ListView.builder(
//   controller: _scrollController,

//   padding: const EdgeInsets.fromLTRB(
//     14,
//     14,
//     14,
//     30,
//   ),

//   itemCount:
//       clinics.length +
//       (isLoadingMore ? 1 : 0),

//   itemBuilder: (
//     context,
//     index,
//   ) {
//     // ----------------------------------------------------------
//     // BOTTOM LOADING INDICATOR
//     // ----------------------------------------------------------

//     if (index >= clinics.length) {
//       return const Padding(
//         padding: EdgeInsets.symmetric(
//           vertical: 20,
//         ),
//         child: Center(
//           child: CircularProgressIndicator(
//             color: green,
//           ),
//         ),
//       );
//     }

//     return _clinicCard(
//       clinics[index],
//     );
//   },
// ),
//                     ),
//     );
//   }
// }