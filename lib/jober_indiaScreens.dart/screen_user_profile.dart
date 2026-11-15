// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';

// class ScreenUserProfile extends StatelessWidget {
//   const ScreenUserProfile({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final Box userBox = Hive.box('userBox');

//     return ValueListenableBuilder(
//       valueListenable: userBox.listenable(),
//       builder: (
//         context,
//         Box box,
//         _, 
//       ) {
//         final String name =
//             box.get('name', defaultValue: 'User');

//         final String mobile =
//             box.get('mobile', defaultValue: '');

//         final String gender =
//             box.get('gender', defaultValue: '');

//         final String role =
//             box.get('role', defaultValue: 'User');

//         return Scaffold(
//           backgroundColor:
//               const Color(0xFFF7F8F7),

//           appBar: AppBar(
//             backgroundColor:
//                 const Color(0xFFF7F8F7),

//             elevation: 0,

//             leading: IconButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               icon: const Icon(
//                 Icons.arrow_back,
//                 color: Color(0xFF202124),
//               ),
//             ),

//             title: const Text(
//               'My Profile',
//               style: TextStyle(
//                 color: Color(0xFF202124),
//                 fontWeight: FontWeight.bold,
//               ),
//             ),

//             centerTitle: true,
//           ),

//           body: SingleChildScrollView(
//             padding:
//                 const EdgeInsets.all(20),

//             child: Column(
//               children: [

//                 // ==========================================
//                 // PROFILE IMAGE
//                 // ==========================================

//                 Container(
//                   height: 120,
//                   width: 120,

//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,

//                     color:
//                         const Color(0xFFEDE5F4),

//                     border: Border.all(
//                       color:
//                           const Color(0xFF6A3D8C),
//                       width: 2,
//                     ),
//                   ),

//                   child: const Icon(
//                     Icons.person,
//                     size: 65,
//                     color: Color(0xFF6A3D8C),
//                   ),
//                 ),

//                 const SizedBox(height: 18),

//                 // ==========================================
//                 // NAME
//                 // ==========================================

//                 Text(
//                   name,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     fontSize: 25,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF202124),
//                   ),
//                 ),

//                 const SizedBox(height: 6),

//                 // ==========================================
//                 // ROLE
//                 // ==========================================

//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(
//                     horizontal: 15,
//                     vertical: 7,
//                   ),

//                   decoration: BoxDecoration(
//                     color:
//                         const Color(0xFFE8F5E9),

//                     borderRadius:
//                         BorderRadius.circular(20),
//                   ),

//                   child: Text(
//                     _formatRole(role),
//                     style: const TextStyle(
//                       color: Color(0xFF137333),
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 30),

//                 // ==========================================
//                 // PROFILE DETAILS
//                 // ==========================================

//                 _profileCard(
//                   icon: Icons.person_outline,
//                   title: 'Full Name',
//                   value: name,
//                 ),

//                 const SizedBox(height: 15),

//                 _profileCard(
//                   icon: Icons.phone_outlined,
//                   title: 'Mobile Number',
//                   value: mobile,
//                 ),

//                 const SizedBox(height: 15),

//                 _profileCard(
//                   icon: Icons.person_outline,
//                   title: 'Gender',
//                   value: gender.isEmpty
//                       ? 'Not specified'
//                       : gender,
//                 ),

//                 const SizedBox(height: 15),

//                 _profileCard(
//                   icon: Icons.badge_outlined,
//                   title: 'Role',
//                   value: _formatRole(role),
//                 ),

//                 const SizedBox(height: 35),

//                 // ==========================================
//                 // EDIT PROFILE BUTTON
//                 // ==========================================

//                 SizedBox(
//                   width: double.infinity,
//                   height: 55,

//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       // We will add Edit Profile later
//                     },

//                     icon: const Icon(
//                       Icons.edit,
//                     ),

//                     label: const Text(
//                       'Edit Profile',
//                       style: TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),

//                     style:
//                         ElevatedButton.styleFrom(
//                       backgroundColor:
//                           const Color(0xFF137333),

//                       foregroundColor:
//                           Colors.white,

//                       shape:
//                           RoundedRectangleBorder(
//                         borderRadius:
//                             BorderRadius.circular(16),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // ============================================================
//   // PROFILE CARD
//   // ============================================================

//   Widget _profileCard({
//     required IconData icon,
//     required String title,
//     required String value,
//   }) {
//     return Container(
//       width: double.infinity,

//       padding:
//           const EdgeInsets.symmetric(
//         horizontal: 18,
//         vertical: 18,
//       ),

//       decoration: BoxDecoration(
//         color: Colors.white,

//         borderRadius:
//             BorderRadius.circular(18),

//         boxShadow: [
//           BoxShadow(
//             color:
//                 Colors.black.withValues(alpha: 0.05),

//             blurRadius: 10,

//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),

//       child: Row(
//         children: [

//           Container(
//             height: 48,
//             width: 48,

//             decoration: BoxDecoration(
//               color:
//                   const Color(0xFFFFEAEA),

//               borderRadius:
//                   BorderRadius.circular(14),
//             ),

//             child: Icon(
//               icon,
//               color: Colors.red,
//             ),
//           ),

//           const SizedBox(width: 15),

//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,

//               children: [

//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey,
//                   ),
//                 ),

//                 const SizedBox(height: 5),

//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 17,
//                     fontWeight:
//                         FontWeight.w600,
//                     color:
//                         Color(0xFF202124),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // FORMAT ROLE
//   // ============================================================

//   String _formatRole(String role) {
//     switch (role) {
//       case 'houseOwner':
//         return 'House Owner';

//       case 'worker':
//         return 'Worker';

//       case 'doctor':
//         return 'Doctor';

//       case 'medicalShop':
//         return 'Medical Shop';

//       case 'freelancer':
//         return 'Freelancer';

//       case 'individualSellers':
//         return 'Individual Sellers';

//       default:
//         return 'User';
//     }
//   }
// }