// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:jober_india/jober_indiaScreens.dart/otherBusiness/other_business_login.dart';

// class OtherBusinessData {
//   final String uid;
//   final String username;
//   final String name;
//   final String primaryMobile;
//   final String secondaryMobile;

//   final List<String> categories;
//   final List<String> categoryKeys;

//   final String description;
//   final String? profilePhotoUrl;

//   // final bool hasLocation;
//   // final double? latitude;
//   // final double? longitude;
//  // final Map<String, dynamic>? location;
//  final OtherBusinessLocation? location;

//   final bool isShopType;

//   // Shop timing
//   final String? openingTime;
//   final String? closingTime;
//   final String? isOpen24Hours;

//   final DateTime? createdAt;
//   final DateTime? updatedAt;

//   OtherBusinessData({
//     required this.uid,
//     required this.username,
//     required this.name,
//     required this.primaryMobile,
//     required this.secondaryMobile,
//     required this.categories,
//     required this.categoryKeys,
//     required this.description,
//     this.profilePhotoUrl,
//     // this.hasLocation = false,
//     // this.latitude,
//     // this.longitude,
//     this.location,
//     this.isShopType = false,
//     this.openingTime,
//     this.closingTime,
//     this.isOpen24Hours,
//     this.createdAt,
//     this.updatedAt,
//   });

//   factory OtherBusinessData.fromFirestore(
//     DocumentSnapshot<Map<String, dynamic>> doc,
//   ) {
//     final data = doc.data() ?? {};

//     return OtherBusinessData(
//       uid: data['uid'] ?? doc.id,

//       username: data['username'] ?? '',

//       name: data['name'] ?? '',

//       primaryMobile:
//           data['primaryMobile'] ?? '',

//       secondaryMobile:
//           data['secondaryMobile'] ?? '',

//       categories: List<String>.from(
//         data['categories'] ?? [],
//       ),

//       categoryKeys: List<String>.from(
//         data['categoryKeys'] ?? [],
//       ),

//       description:
//           data['description'] ?? '',

//       profilePhotoUrl:
//           data['profilePhotoUrl'],

//       // hasLocation:
//       //     data['hasLocation'] == true,

//       // latitude:
//       //     (data['latitude'] as num?)?.toDouble(),

    
//     location: data['location'] != null
//     ? OtherBusinessLocation.fromMap(
//         Map<String, dynamic>.from(data['location']),
//       )
//     : null,

//       isShopType:
//           data['isShopType'] == true,

//       // Shop timing
//       openingTime:
//           data['openingTime'] as String?,

//       closingTime:
//           data['closingTime'] as String?,
      
//     isOpen24Hours:data['isOpen24Hours']as String?,
//       createdAt:
//           (data['createdAt'] as Timestamp?)
//               ?.toDate(),

//       updatedAt:
//           (data['updatedAt'] as Timestamp?)
//               ?.toDate(),
//     );
//   }

//   Map<String, dynamic> toFirestore() {
//     return {
//       'uid': uid,

//       'username' : username,

//       'name': name,

//       'primaryMobile':
//           primaryMobile,

//       'secondaryMobile':
//           secondaryMobile,

//       'categories':
//           categories,

//       'categoryKeys':
//           categoryKeys,

//       'description':
//           description,

//       'profilePhotoUrl':
//           profilePhotoUrl,

//       // 'hasLocation':
//       //     hasLocation,

//       // 'latitude':
//       //     latitude,

//       // 'longitude':
//       //     longitude,
//       'location' : location?.toMap(),

//       'isShopType':
//           isShopType,

//       // Shop timing
//       'openingTime':
//           openingTime,

//       'closingTime':
//           closingTime,
//       'isOpen24Hours': isOpen24Hours,

//       'createdAt':
//           createdAt != null
//               ? Timestamp.fromDate(
//                   createdAt!,
//                 )
//               : FieldValue.serverTimestamp(),

//       'updatedAt':
//           FieldValue.serverTimestamp(),
//     };
//   }
// }