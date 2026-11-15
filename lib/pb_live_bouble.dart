// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:overlay_pop_up/overlay_pop_up.dart';

// @pragma('vm:entry-point')
// void citizenLiveBubbleEntryPoint() {
//   WidgetsFlutterBinding.ensureInitialized();

//   runApp(
//     const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: CitizenLiveBubble(),
//     ),
//   );
// }

// class CitizenLiveBubble extends StatefulWidget {
//   const CitizenLiveBubble({super.key});

//   @override
//   State<CitizenLiveBubble> createState() =>
//       _CitizenLiveBubbleState();
// }

// class _CitizenLiveBubbleState
//     extends State<CitizenLiveBubble> {
// //   bool _expanded = false;
// //  final bool _live = true;
// //   bool _stopping = false;
// bool _expanded = false;
// bool _live = true;
// bool _stopping = false;

// StreamSubscription? _mainAppSubscription;
// Timer? _stopTimeout;

//   // @override
//   // void initState() {
//   //   super.initState();
//   //   OverlayPopUp.initializeOverlayHandler();
//   // }

// // Future<void> _turnOffLive() async {
// //   if (_stopping) return;

// //   setState(() {
// //     _stopping = true;
// //   });

// //   try {
// //     // Use EXACTLY the same stop method as Home page.
// //     final bool stopped =
// //         await LiveLocationService.instance.stop();

// //     if (!stopped) {
// //       if (mounted) {
// //         setState(() {
// //           _stopping = false;
// //         });
// //       }
// //       return;
// //     }

// //     // Close the popup after successful shutdown.
// //     await OverlayPopUp.closeOverlay();

// //   } catch (e) {
// //     if (mounted) {
// //       setState(() {
// //         _stopping = false;
// //       });
// //     }
// //   }
// // }
// @override
// void initState() {
//   super.initState();

//   OverlayPopUp.initializeOverlayHandler();

//   // _mainAppSubscription =
//   //     OverlayPopUp.overlayDataListener?.listen((data) {
//   //   if (!mounted || data is! Map) return;

//   //   if (data['action'] == 'turnOffLiveResult') {
//   //     _stopTimeout?.cancel();

//   //     final bool success = data['success'] == true;

//   //     setState(() {
//   //       _stopping = false;

//   //       if (success) {
//   //         _live = false;
//   //       }
//   //     });

//   //     if (!success) {
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         const SnackBar(
//   //           content: Text(
//   //             'Could not stop LIVE. Please try again.',
//   //           ),
//   //         ),
//   //       );
//   //     }
//   //   }
//   // });
//   _mainAppSubscription =
//     OverlayPopUp.overlayDataListener?.listen((data) {
//   if (!mounted || data is! Map) return;

//   // STEP 1: Check whether main.dart received the request.
//   if (data['action'] == 'turnOffLiveProgress') {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           data['message']?.toString() ?? '',
//         ),
//       ),
//     );

//     return;
//   }

//   // STEP 2: Receive the final stop result.
//   if (data['action'] == 'turnOffLiveResult') {
//     _stopTimeout?.cancel();

//     final bool success = data['success'] == true;

//     setState(() {
//       _stopping = false;

//       if (success) {
//         _live = false;
//       }
//     });

//     if (!success) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Could not stop LIVE. Please try again.',
//           ),
//         ),
//       );
//     }
//   }
// });
// }

// @override
// void dispose() {
//   _stopTimeout?.cancel();
//   _mainAppSubscription?.cancel();
//   super.dispose();
// }

// // Future<void> _turnOffLive() async {
// //   if (_stopping || !_live) return;

// //   setState(() {
// //     _stopping = true;
// //   });

// //   try {
// //     await OverlayPopUp.sendToMainApp({
// //       'action': 'turnOffLive',
// //     });

// //     // If the main app does not respond, allow another attempt.
// //     _stopTimeout?.cancel();
// //     _stopTimeout = Timer(
// //       const Duration(seconds: 20),
// //       () {
// //         if (!mounted || !_stopping) return;

// //         setState(() {
// //           _stopping = false;
// //         });

// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text(
// //               'LIVE stop request timed out. Please try again.',
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   } catch (e) {
// //     _stopTimeout?.cancel();

// //     if (!mounted) return;

// //     setState(() {
// //       _stopping = false;
// //     });

// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text('Could not send stop request: $e'),
// //       ),
// //     );
// //   }
// // }
// Future<void> _turnOffLive() async {
//   if (_stopping || !_live) return;

//   setState(() {
//     _stopping = true;
//   });

//   // Start timeout BEFORE sending the message.
//   _stopTimeout?.cancel();

//   _stopTimeout = Timer(
//     const Duration(seconds: 10),
//     () {
//       if (!mounted || !_stopping) return;

//       setState(() {
//         _stopping = false;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Main app did not respond. Please try again.',
//           ),
//         ),
//       );
//     },
//   );

//   try {
//     await OverlayPopUp.sendToMainApp({
//       'action': 'turnOffLive',
//     });
//   } catch (e) {
//     _stopTimeout?.cancel();

//     if (!mounted) return;

//     setState(() {
//       _stopping = false;
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Stop request failed: $e'),
//       ),
//     );
//   }
// }

//   @override
// Widget build(BuildContext context) {
//   //final screenWidth = MediaQuery.of(context).size.width;
//   // final bubbleWidth = _expanded
//   //     ? (screenWidth - 16).clamp(220.0, 250.0)
//   //     : 68.0;

//   return Material(
//     color: Colors.transparent,
//     child: Align(
//       alignment: Alignment.centerRight,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         //width: bubbleWidth,
//         width:  _expanded ? 280 : 68,
//         height: _expanded ? 210 : 68,
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(
//             _expanded ? 18 : 50,
//           ),
//           border: Border.all(
//             color: const Color(0xFF16803C),
//             width: 2,
//           ),
//           boxShadow: const [
//             BoxShadow(
//               color: Colors.black26,
//               blurRadius: 8,
//               spreadRadius: 1,
//             ),
//           ],
//         ),
//         child: _expanded
//             ? Column(
//                 mainAxisSize: MainAxisSize.min,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text(
//                     'PEOPLE BRIDGE',
//                     style: TextStyle(
//                       color: Color(0xFF12652F),
//                       fontWeight: FontWeight.bold,
//                       fontSize: 13,
//                     ),
//                   ),
//                   const SizedBox(height: 5),

//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         width: 8,
//                         height: 8,
//                         decoration: BoxDecoration(
//                           color: _live
//                               ? Colors.green
//                               : Colors.grey,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                       const SizedBox(width: 5),
//                       Flexible(
//                         child: Text(
//                           _live
//                               ? 'LIVE LOCATION ON'
//                               : 'OFF',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(
//                             color: Colors.black87,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 5),

//                   SizedBox(
//                     width: double.infinity,
//                     height: 36,
//                     child: ElevatedButton(
//                       // onPressed:
//                       //     _stopping ? null : _turnOffLive,
//                       // style: ElevatedButton.styleFrom(
//                       //   padding: const EdgeInsets.symmetric(
//                       //     horizontal: 8,
//                       //   ),
//                       //   backgroundColor:
//                       //       const Color(0xFF16803C),
//                       //   foregroundColor: Colors.white,
//                       //   tapTargetSize:
//                       //       MaterialTapTargetSize.shrinkWrap,
//                       // ),
//                       // child: Text(
//                       //   _stopping
//                       //       ? 'Stopping...'
//                       //       : 'Turn OFF LIVE',
//                       //   style: const TextStyle(fontSize: 12),
//                       // ),
//                           onPressed: _stopping || !_live ? null : _turnOffLive,
//  style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                         ),
//                         backgroundColor:
//                             const Color(0xFF16803C),
//                         foregroundColor: Colors.white,
//                         tapTargetSize:
//                             MaterialTapTargetSize.shrinkWrap,
//                       ),
//                       child: Text(
//                         _stopping
//                             ? 'Stopping...'
//                             : 'Turn OFF LIVE',
//                         style: const TextStyle(fontSize: 12),
//                       ),
//                     ),
//                   ),

//                   SizedBox(
//                     height: 32,
//                     child: TextButton(
//                       onPressed: () {
//                         setState(() {
//                           _expanded = false;
//                         });
//                       },
//                       style: TextButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                         ),
//                         tapTargetSize:
//                             MaterialTapTargetSize.shrinkWrap,
//                       ),
//                       child: const Text(
//                         'Minimize bubble',
//                         style: TextStyle(
//                           color: Color(0xFF12652F),
//                           fontSize: 11,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               )
//             // : InkWell(
//             //     customBorder: const CircleBorder(),
//             //     onTap: () {
//             //       setState(() {
//             //         _expanded = true;
//             //       });
//             //     },
//             //     child: const Center(
//             //       child: Column(
//             //         mainAxisSize: MainAxisSize.min,
//             //         mainAxisAlignment: MainAxisAlignment.center,
//             //         children: [
//             //           Icon(
//             //             Icons.location_on,
//             //             color: Color(0xFF16803C),
//             //             size: 25,
//             //           ),
//             //           Text(
//             //             'LIVE',
//             //             style: TextStyle(
//             //               color: Color(0xFF12652F),
//             //               fontSize: 9,
//             //               fontWeight: FontWeight.bold,
//             //             ),
//             //           ),
//             //         ],
//             //       ),
//             //     ),
//             //   ),
//             : InkWell(
//     customBorder: const CircleBorder(),
//     onTap: () {
//       setState(() {
//         _expanded = true;
//       });
//     },
//     child: ClipOval(
//       child: Padding(
//         padding: const EdgeInsets.all(3),
//         child: Image.asset(
//           'assets/images/WhatsApp Image 2026-09-01 at 11.39.01 AM.jpeg',
//           width: 58,
//           height: 58,
//           fit: BoxFit.contain,
//           errorBuilder: (context, error, stackTrace) {
//             return const Icon(
//               Icons.home,
//               color: Color(0xFF16803C),
//               size: 34,
//             );
//           },
//         ),
//       ),
//     ),
//   ),
//       ),
//     ),
//   );
// }
// }


  // Future<void> _turnOffLive() async {
  //   if (_stopping) return;

  //   setState(() {
  //     _stopping = true;
  //   });

  //   try {
  //     // Ask the main app to stop the real location service.
  //     await OverlayPopUp.sendToMainApp({
  //       'action': 'turnOffLive',
  //     });

  //     // The main app will close this overlay after
  //     // it has processed the stop request.
  //   } catch (e) {
  //     debugPrint('Bubble stop request failed: $e');

  //     if (mounted) {
  //       setState(() {
  //         _stopping = false;
  //       });
  //     }
  //   }
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Material(
  //     color: Colors.transparent,
  //     child: Align(
  //       alignment: Alignment.centerRight,
  //       child: AnimatedContainer(
  //         duration: const Duration(milliseconds: 180),
  //         width: _expanded ? 270 : 78,
  //         height: _expanded ? 170 : 78,
  //         padding: const EdgeInsets.all(6),
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(
  //             _expanded ? 22 : 50,
  //           ),
  //           border: Border.all(
  //             color: const Color(0xFF16803C),
  //             width: 2,
  //           ),
  //           boxShadow: const [
  //             BoxShadow(
  //               color: Colors.black26,
  //               blurRadius: 12,
  //               spreadRadius: 1,
  //             ),
  //           ],
  //         ),
  //         child: _expanded
  //             ? Column(
  //                 mainAxisAlignment:
  //                     MainAxisAlignment.center,
  //                 children: [
  //                   const Text(
  //                     'CITIZEN INDIA',
  //                     style: TextStyle(
  //                       color: Color(0xFF12652F),
  //                       fontWeight: FontWeight.bold,
  //                       fontSize: 14,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   Row(
  //                     mainAxisAlignment:
  //                         MainAxisAlignment.center,
  //                     children: [
  //                       Container(
  //                         width: 9,
  //                         height: 9,
  //                         decoration: BoxDecoration(
  //                           color: _live
  //                               ? Colors.green
  //                               : Colors.grey,
  //                           shape: BoxShape.circle,
  //                         ),
  //                       ),
  //                       const SizedBox(width: 6),
  //                       Text(
  //                         _live ? 'LIVE LOCATION ON' : 'OFF',
  //                         style: const TextStyle(
  //                           color: Colors.black87,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 12),
  //                   SizedBox(
  //                     width: double.infinity,
  //                     child: ElevatedButton(
  //                       onPressed:
  //                           _stopping ? null : _turnOffLive,
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor:
  //                             const Color(0xFF16803C),
  //                         foregroundColor: Colors.white,
  //                       ),
  //                       child: Text(
  //                         _stopping
  //                             ? 'Stopping...'
  //                             : 'Turn OFF LIVE',
  //                       ),
  //                     ),
  //                   ),
  //                   TextButton(
  //                     onPressed: () {
  //                       setState(() {
  //                         _expanded = false;
  //                       });
  //                     },
  //                     child: const Text(
  //                       'Minimize bubble',
  //                       style: TextStyle(
  //                         color: Color(0xFF12652F),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               )
  //             : InkWell(
  //                 customBorder: const CircleBorder(),
  //                 onTap: () {
  //                   setState(() {
  //                     _expanded = true;
  //                   });
  //                 },
  //                 child: const Center(
  //                   child: Column(
  //                     mainAxisAlignment:
  //                         MainAxisAlignment.center,
  //                     children: [
  //                       Icon(
  //                         Icons.location_on,
  //                         color: Color(0xFF16803C),
  //                         size: 30,
  //                       ),
  //                       Text(
  //                         'LIVE',
  //                         style: TextStyle(
  //                           color: Color(0xFF12652F),
  //                           fontSize: 10,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //       ),
  //     ),
  //   );
  // }