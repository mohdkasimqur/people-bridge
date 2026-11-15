import 'package:cloud_firestore/cloud_firestore.dart';

class TaxiCommercialVehicleCategory {
  final String name;
  final String image;
  final String imageUrl;
  final String type;
  final bool isCustom;

  const TaxiCommercialVehicleCategory({
    required this.name,
    required this.image,
    required this.type,
    this.imageUrl = '',
    this.isCustom = false,
  });
}

// ============================================================
// TAXI VEHICLES
// ============================================================

const List<TaxiCommercialVehicleCategory> taxiVehicleCategories = [
   TaxiCommercialVehicleCategory(
    name: 'Sedan',
    image: 'assets/vehicles/dezire-silver.png',
    type: 'Taxi',
  ),
 
   TaxiCommercialVehicleCategory(
    name: 'Mini Cab',
    image:
        'assets/vehicles/tata-magic-iris-van-500x500.webp',
    type: 'Taxi',
  ),
  TaxiCommercialVehicleCategory(
    name: 'Auto Rickshaw',
    image:
        'assets/vehicles/bajaj-re-cng-auto-rickshaw.png',
    type: 'Taxi',
  ),
  TaxiCommercialVehicleCategory(
    name: 'Bike',
    image:
        'assets/vehicles/WhatsApp Image 2026-09-18 at 11.45.43 PM.jpeg',
    type: 'Taxi',
  ),
  TaxiCommercialVehicleCategory(
    name: 'Compact SUV',
    image: 'assets/vehicles/images.jpeg',
    type: 'Taxi',
  ),
  TaxiCommercialVehicleCategory(
    name: 'Subcompact Crossover SUV',
    image: 'assets/vehicles/0528.jpg',
    type: 'Taxi',
  ),
  TaxiCommercialVehicleCategory(
    name: 'HATCHBACK',
    image: 'assets/vehicles/celerio.jpeg',
    type: 'Taxi',
  ),
  TaxiCommercialVehicleCategory(
    name: 'MPV',
    image:
        'assets/vehicles/WhatsApp Image 2026-08-31 at 2.03.24 PM.jpeg',
    type: 'Taxi',
  ),
 
];

// ============================================================
// COMMERCIAL VEHICLES
// ============================================================

const List<TaxiCommercialVehicleCategory>
    commercialVehicleCategories = [
  TaxiCommercialVehicleCategory(
    name: 'Mini Pickup',
    image: 'assets/comercials/_APL9701.png',
    type: 'Commercial',
  ),
  TaxiCommercialVehicleCategory(
    name: 'Small Pickup',
    image: 'assets/comercials/Ace.jpeg',
    type: 'Commercial',
  ),
  TaxiCommercialVehicleCategory(
    name: 'Medium Pickup',
    image: 'assets/comercials/TATA407.jpeg',
    type: 'Commercial',
  ),
   TaxiCommercialVehicleCategory(
    name: 'Medium Tipper',
    image: 'assets/comercials/overview-1.jpg',
    type: 'Commercial',
  ),
  TaxiCommercialVehicleCategory(
    name: 'Lorry',
    image: 'assets/comercials/Indian Lorry.jpeg',
    type: 'Commercial',
  ),
  TaxiCommercialVehicleCategory(
    name: 'Tipper',
    image: 'assets/comercials/Tipper.jpeg',
    type: 'Commercial',
  ),
  TaxiCommercialVehicleCategory(
    name: 'JCB',
    image: 'assets/comercials/JCB.jpeg',
    type: 'Commercial',
  ),
  TaxiCommercialVehicleCategory(
    name: 'Tanker',
    image: 'assets/comercials/Oil Tanker.jpeg',
    type: 'Commercial',
  ),
  TaxiCommercialVehicleCategory(
    name: 'Trailer',
    image: 'assets/comercials/Trailer.jpeg',
    type: 'Commercial',
  ),
  TaxiCommercialVehicleCategory(
    name: 'Bus',
    image:
        'assets/comercials/blue-bus-white-background-simple-374089112.webp',
    type: 'Commercial',
  ),
];

// ============================================================
// GET PREDEFINED CATEGORIES
// ============================================================

List<TaxiCommercialVehicleCategory> getPredefinedVehicleCategories(
  String type,
) {
  if (type == 'Commercial') {
    return commercialVehicleCategories;
  }

  return taxiVehicleCategories;
}

// ============================================================
// FIRESTORE COLLECTION
// ============================================================

const String taxiCommercialCategoryCollection =
    'taxi_vehicle_categories';

// ============================================================
// SAFE FIRESTORE DOCUMENT ID
// ============================================================

String taxiCommercialCategoryId(
  String type,
  String name,
) {
  final String cleanType = type
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  final String cleanName = name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  return '${cleanType}_$cleanName';
}

// ============================================================
// SAVE CUSTOM CATEGORY
// ============================================================
Future<void> saveCustomTaxiCommercialCategory({
  required String name,
  required String type,
  required String uid,
  String imageUrl = '',
}) async {
  final String cleanName = name.trim();

  if (cleanName.isEmpty) return;
  if (type != 'Taxi' && type != 'Commercial') return;

  final String documentId =
      taxiCommercialCategoryId(type, cleanName);

  final DocumentReference<Map<String, dynamic>> ref =
      FirebaseFirestore.instance
          .collection(taxiCommercialCategoryCollection)
          .doc(documentId);

  final Map<String, dynamic> data = {
    'name': cleanName,
    'vehicleType': type,
    'isCustom': true,
    'createdBy': uid,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  // Update the photo URL only when a new URL is supplied.
  // Otherwise, preserve any previously saved photo URL.
  if (imageUrl.trim().isNotEmpty) {
    data['imageUrl'] = imageUrl.trim();
  }

  await ref.set(
    data,
    SetOptions(merge: true),
  );
}

// ============================================================
// LOAD CUSTOM CATEGORIES
// ============================================================

Future<List<TaxiCommercialVehicleCategory>>
    loadCustomTaxiCommercialCategories(String type) async {
  final snapshot = await FirebaseFirestore.instance
      .collection(taxiCommercialCategoryCollection)
      .where('vehicleType', isEqualTo: type)
      .get();

  final List<TaxiCommercialVehicleCategory> result = [];

  for (final doc in snapshot.docs) {
    final data = doc.data();

    final String name =
        data['name']?.toString().trim() ?? '';

    if (name.isEmpty) continue;

    result.add(
      TaxiCommercialVehicleCategory(
        name: name,
        image: '',
       // imageUrl: data['imageUrl']?.toString() ?? '',
       imageUrl: (data['imageUrl'] ?? '').toString(),
        type: type,
        isCustom: true,
      ),
    );
  }

  return result;
}

// ============================================================
// LOAD ALL CATEGORIES
// PREDEFINED + CUSTOM
// ============================================================

Future<List<TaxiCommercialVehicleCategory>>
    loadAllTaxiCommercialCategories(
  String type,
) async {
  final List<TaxiCommercialVehicleCategory> predefined =
      List<TaxiCommercialVehicleCategory>.from(
    getPredefinedVehicleCategories(type),
  );

  final List<TaxiCommercialVehicleCategory> custom =
      await loadCustomTaxiCommercialCategories(type);

  final List<TaxiCommercialVehicleCategory> result = [];

  final Set<String> existingNames = {};

  for (final TaxiCommercialVehicleCategory item
      in predefined) {
    final String key = item.name.trim().toLowerCase();

    if (existingNames.add(key)) {
      result.add(item);
    }
  }

  for (final TaxiCommercialVehicleCategory item
      in custom) {
    final String key = item.name.trim().toLowerCase();

    if (existingNames.add(key)) {
      result.add(item);
    }
  }

  return result;
}


// Future<List<TaxiCommercialVehicleCategory>>
//     loadCustomTaxiCommercialCategories(
//   String type,
// ) async {
//   final QuerySnapshot<Map<String, dynamic>> snapshot =
//       await FirebaseFirestore.instance
//           .collection(taxiCommercialCategoryCollection)
//           .where('vehicleType', isEqualTo: type)
//           .get();

//   final List<TaxiCommercialVehicleCategory> result = [];

//   for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
//       in snapshot.docs) {
//     final Map<String, dynamic> data = doc.data();

//     final String name =
//         data['name']?.toString().trim() ?? '';

//     if (name.isEmpty) {
//       continue;
//     }

//     result.add(
//       TaxiCommercialVehicleCategory(
//         name: name,
//         image: '',
//         type: type,
//         isCustom: true,
//       ),
//     );
//   }

//   return result;
// }


// Future<void> saveCustomTaxiCommercialCategory({
//   required String name,
//   required String type,
//   required String uid,
// }) async {
//   final String cleanName = name.trim();

//   if (cleanName.isEmpty) {
//     return;
//   }

//   if (type != 'Taxi' && type != 'Commercial') {
//     return;
//   }

//   final String documentId =
//       taxiCommercialCategoryId(type, cleanName);

//   final DocumentReference<Map<String, dynamic>> ref =
//       FirebaseFirestore.instance
//           .collection(taxiCommercialCategoryCollection)
//           .doc(documentId);

//   await ref.set(
//     {
//       'name': cleanName,
//       'vehicleType': type,
//       'isCustom': true,
//       'createdBy': uid,
//       'createdAt': FieldValue.serverTimestamp(),
//       'updatedAt': FieldValue.serverTimestamp(),
//     },
//     SetOptions(merge: true),
//   );
// }
// Future<void> saveCustomTaxiCommercialCategory({
//   required String name,
//   required String type,
//   required String uid,
//   String imageUrl = '',
// }) async {
//   final String cleanName = name.trim();

//   if (cleanName.isEmpty) return;

//   if (type != 'Taxi' && type != 'Commercial') {
//     throw ArgumentError('Invalid vehicle type.');
//   }

//   final String documentId =
//       taxiCommercialCategoryId(type, cleanName);

//   final DocumentReference<Map<String, dynamic>> ref =
//       FirebaseFirestore.instance
//           .collection(taxiCommercialCategoryCollection)
//           .doc(documentId);

//   await ref.set({
//     'name': cleanName,
//     'vehicleType': type,
//     'isCustom': true,
//     'createdBy': uid,
//     'imageUrl': imageUrl.trim(),
//     'createdAt': FieldValue.serverTimestamp(),
//     'updatedAt': FieldValue.serverTimestamp(),
//   }, SetOptions(merge: true));
// }