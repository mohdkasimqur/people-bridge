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
import 'package:multi_select_flutter/multi_select_flutter.dart';


class DoctorLocation {
  final String placeName;
  final double? latitude;
  final double? longitude;

  DoctorLocation({
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

  factory DoctorLocation.fromMap(
    Map<String, dynamic> map,
  ) {
    return DoctorLocation(
      placeName: map['placeName']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

class ScreenDoctorLogin extends StatefulWidget {
  const ScreenDoctorLogin({super.key});

  @override
  State<ScreenDoctorLogin> createState() => _ScreenDoctorLoginState();
}

class _ScreenDoctorLoginState extends State<ScreenDoctorLogin> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController secondaryPhoneController =
    TextEditingController();
  final TextEditingController _shopLocationController =
    TextEditingController();


  final TextEditingController categoryController =
      TextEditingController();

  final TextEditingController experienceController =
      TextEditingController();

  final TextEditingController placeNameController =
      TextEditingController();

  final TextEditingController categorySearchController =
      TextEditingController();

  final TextEditingController customCategoryController =
      TextEditingController();

  final TextEditingController specializedSearchController =
      TextEditingController();

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

  final List<String> customSpecializations = [];

List<String> filteredSpecializations = [];

bool isSpecializationDropdownOpen = false;

bool specializationError = false;

final TextEditingController specializationSearchController =
    TextEditingController();

final TextEditingController customSpecializationController =
    TextEditingController();
  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth auth = FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  static const Color green =
      Color(0xFF138808);

  static const Color darkText =
      Color(0xFF202124);

  static const Color lightFill =
      Color(0xFFF9F9F9);

   File? profilePhoto;
  String? profilePhotoUrl;
bool isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();

  //String? verificationId;

  bool privacyPolicyAccepted = false;


  // ============================================================
  // OTP STATE
  // ============================================================

//  bool otpSent = false;
//   bool otpVerified = false;

//   bool isSendingOtp = false;
//   bool isVerifying = false;
//   bool isSubmitting = false;

//   bool otpError = false;

//  String otpErrorMessage = '';

//   int secondsRemaining = 30;

//   Timer? timer;

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
// CONSULTATION TIME
// ============================================================

TimeOfDay? consultationFrom;
TimeOfDay? consultationTo;

String consultationTimeError = '';
  // ============================================================
  // VALIDATION
  // ============================================================

  String nameError = '';
String phoneErrorMessage = '';
bool mobileError = false;
bool secondaryMobileError = false;

String secondaryPhoneError = '';
String genderError = '';
String experienceError = '';
bool categoryError = false;

//bool districtError = false;

    String? privacyPolicyError;


  // ============================================================
  // GENDER
  // ============================================================

  String? selectedGender;

  // ============================================================
  // MEDICAL CATEGORIES
  // ============================================================

  final List<String> doctorCategories = [
    'Allopathy',
    'Ayurvedic',
    'Homeopathy',
    'Unani',
  ];

  List<String> selectedCategories = [];
  bool isCategoryDropdownOpen = false;
 // bool isStateDropdownOpen = false;

  final List<String> customCategories = [];
  List<String> filteredCategories = [];

  // ============================================================
  // SPECIALIZATIONS
  // ============================================================

  // final List<String> specializations = [
  //   'Cardiology',
  //   'Neurology',
  //   'Nephrology',
  //   'Dermatology',
  //   'Pediatrics',
  //   'Gynecology',
  //   'Obstetrics',
  //   'Orthopedics',
  //   'Psychiatry',
  //   'Psychology',
  //   'ENT',
  //   'Ophthalmology',
  //   'Dentistry',
  //   'Urology',
  //   'Gastroenterology',
  //   'Pulmonology',
  //   'Endocrinology',
  //   'Oncology',
  //   'Radiology',
  //   'Pathology',
   
  // 'Anesthesiology',
  //   'General Surgery',
  //   'Plastic Surgery',
  //   'Neurosurgery',
  //   'Cardiac Surgery',
  //   'Diabetology',
  // ];

  List<String> selectedSpecialCategories = [];

  // ============================================================
// ============================================================
  // BUILT-IN SPECIALIZATIONS BY CATEGORY
  // ============================================================

  final Map<String, List<String>>
      _builtInSpecializationsByCategory = {
    'Allopathy': [
      'Cardiology',
      'Neurology',
      'Nephrology',
      'Dermatology',
      'Pediatrics',
      'Gynecology',
      'Obstetrics',
      'Orthopedics',
   
    ],
    'Ayurvedic': [
      'Kayachikitsa (General Medicine)',
      'Panchakarma',
      'Shalya Tantra (Surgery)',
      'Shalakya Tantra (ENT and Eye Care)',
      'Prasuti Tantra (Obstetrics)',
      'Stri Roga (Women’s Health)',
      'Kaumarabhritya (Pediatrics)',
      'Agada Tantra (Toxicology)',
   
    ],
    'Homeopathy': [
      'General Homeopathy',
      'Acute Disease Care',
      'Chronic Disease Care',
      'Pediatrics',
      'Women’s Health',
      'Skin and Hair Disorders',
      'Digestive Disorders',
      'Respiratory Disorders',
    
    ],
    'Unani': [
      'General Unani Medicine',
      'Kulliyat (Basic Principles)',
      'Ilaj-bid-Dawa (Pharmacotherapy)',
      'Ilaj-bil-Ghiza (Dietotherapy)',
      'Ilaj-bit-Tadbeer (Regimenal Therapy)',
      'Jarahat (Surgery)',
      'Amraz-e-Jild (Skin Disorders)',
    
    ],
  };

  // The category whose specializations are currently displayed.
  String? activeSpecializationCategory;

  // Shared custom specializations, separated by category.
  final Map<String, Set<String>>
      _sharedSpecializationsByCategory = {};

  // Selected specializations, separated by category.
  final Map<String, Set<String>>
      selectedSpecializationsByCategory = {};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _sharedDoctorCategoriesSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _sharedDoctorSpecializationsSubscription;
  // ============================================================
  // WORKING DAYS
  // ============================================================

  final List<String> workingDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  List<String> selectedDays = [];

  // ==========================================================
  // LOCATION
  // ==========================================================
DoctorLocation? currentLocation;

bool isGettingLocation = false;
bool isSearchingLocation = false;

// Used to invalidate an older location request
int _locationRequestId = 0;
bool locationError = false;
  // ============================================================
  // INIT
  // ============================================================

@override
  void initState() {
    super.initState();

    filteredCategories = List<String>.from(
      allCategories,
    );

    filteredStates = List<String>.from(indiaStates);

    loadDistricts();

    stateSearchController.addListener(() {
      filterStates(stateSearchController.text);
    });

    // Load shared categories and specializations.
    _listenToSharedDoctorCategories();
    _listenToSharedDoctorSpecializations();
  }
  
  // ============================================================
  // LISTEN TO GLOBALLY SHARED DOCTOR CATEGORIES
  // ============================================================

  void _listenToSharedDoctorCategories() {
    _sharedDoctorCategoriesSubscription?.cancel();

    _sharedDoctorCategoriesSubscription =
        FirebaseFirestore.instance
            .collection('doctorCategories')
            .snapshots()
            .listen(
      (snapshot) {
        final builtInNames = doctorCategories
            .map((e) => e.trim().toLowerCase())
            .toSet();

        final Map<String, String> sharedNames = {};

        for (final doc in snapshot.docs) {
          final name =
              (doc.data()['name'] ?? '').toString().trim();

          if (name.isEmpty) continue;

          sharedNames.putIfAbsent(
            name.toLowerCase(),
            () => name,
          );
        }

        if (!mounted) return;

        setState(() {
          customCategories
            ..clear()
            ..addAll(
              sharedNames.values.where(
                (name) =>
                    !builtInNames.contains(name.toLowerCase()),
              ),
            );

          filterCategories(categorySearchController.text);
        });
      },
      onError: (Object error) {
        debugPrint(
          'SHARED DOCTOR CATEGORIES ERROR: $error',
        );
      },
    );
  }

  // ============================================================
  // LISTEN TO GLOBALLY SHARED SPECIALIZATIONS
  // ============================================================

  void _listenToSharedDoctorSpecializations() {
    _sharedDoctorSpecializationsSubscription?.cancel();

    _sharedDoctorSpecializationsSubscription =
        FirebaseFirestore.instance
            .collection('doctorSpecializations')
            .snapshots()
            .listen(
      (snapshot) {
        final Map<String, Set<String>> result = {};

        for (final doc in snapshot.docs) {
          final data = doc.data();

          final name =
              (data['name'] ?? '').toString().trim();

          final category =
              (data['categoryName'] ?? '').toString().trim();

          // Ignore old records without a category.
          if (name.isEmpty || category.isEmpty) continue;

          final key = category.toLowerCase();

          result.putIfAbsent(key, () => <String>{});
          result[key]!.add(name);
        }

        if (!mounted) return;

        setState(() {
          _sharedSpecializationsByCategory
            ..clear()
            ..addAll(result);

          filterSpecializations(
            specializationSearchController.text,
          );
        });
      },
      onError: (Object error) {
        debugPrint(
          'SHARED DOCTOR SPECIALIZATIONS ERROR: $error',
        );
      },
    );
  }

   List<String> get allCategories {

    final List<String> result = [];

    for (final category in doctorCategories) {

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

Future<void> addCustomCategory() async {
  final String category =
      customCategoryController.text.trim();

  if (category.isEmpty) {
    showMessage('Please enter a category.');
    return;
  }

  // Prevent duplicate category names.
  final existingIndex = allCategories.indexWhere(
    (item) =>
        item.trim().toLowerCase() ==
        category.toLowerCase(),
  );

  if (existingIndex != -1) {
    final actualCategory = allCategories[existingIndex];

    if (!selectedCategories.contains(actualCategory)) {
      setState(() {
        selectedCategories
          ..clear()
          ..add(actualCategory);

        activeSpecializationCategory = actualCategory;
        categoryError = false;
      });
    }

    customCategoryController.clear();

    if (mounted) {
      Navigator.of(context).pop();
    }

    showMessage('$actualCategory already exists. Selected it.');
    return;
  }

  try {
    final String categoryKey =
        Uri.encodeComponent(category.toLowerCase());

    // Save globally in Firestore.
    // await FirebaseFirestore.instance
    //     .collection('doctorCategories')
    //     .doc(categoryKey)
    //     .set({
    //   'name': category,
    //   'isUserAdded': true,
    //   'createdAt': FieldValue.serverTimestamp(),
    // });
    await FirebaseFirestore.instance
    .collection('doctorCategories')
    .doc(categoryKey)
    .set({
  'name': category,
  'isUserAdded': true,

  // NEW: Record who created this category.
  'createdByUid': FirebaseAuth.instance.currentUser?.uid,

  'createdAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

    if (!mounted) return;

    // Select the new category on this user's screen.
    setState(() {
      selectedCategories
        ..clear()
        ..add(category);

      activeSpecializationCategory = category;

      categoryError = false;
    });

    customCategoryController.clear();
    categorySearchController.clear();

    filterCategories('');

    // Close the Add Category popup.
    Navigator.of(context).pop();

    showMessage('$category added successfully.');

  } on FirebaseException catch (e) {
    debugPrint(
      'ADD DOCTOR CATEGORY ERROR ${e.code}: ${e.message}',
    );

    showMessage(
      'Could not save category. Please try again.',
      error: true,
    );
  } catch (e) {
    debugPrint('ADD DOCTOR CATEGORY ERROR: $e');

    showMessage(
      'An error occurred while adding the category.',
      error: true,
    );
  }
}


  // =============================================================
  // SHOW ADD CATEGORY DIALOG
  // =============================================================

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

              hintText:'Enter Clinic category',

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

              onPressed:()async{ addCustomCategory();},

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

Future<void> deleteCustomDoctorCategory(
String category,
) async {
// Never allow built-in categories to be deleted.
final isBuiltIn = doctorCategories.any(
(item) => item.toLowerCase() == category.toLowerCase(),
);

if (isBuiltIn) {
showMessage(
'Built-in categories cannot be deleted.',
error: true,
);
return;
}

// Ask for confirmation.
final confirmed = await showDialog<bool>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('Delete category?'),
content: Text(
'Delete "$category" for everyone? '
'Its shared custom specializations will also be deleted. '
'This action cannot be undone.',
),
actions: [
TextButton(
onPressed: () => Navigator.of(dialogContext).pop(false),
child: const Text('CANCEL'),
),
ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red,
foregroundColor: Colors.white,
),
onPressed: () => Navigator.of(dialogContext).pop(true),
child: const Text('DELETE'),
),
],
),
);

if (confirmed != true || !mounted) return;

final categoryKey = category.trim().toLowerCase();
final firestore = FirebaseFirestore.instance;

try {
// Find shared custom specializations belonging to this category.
final specializationSnapshot = await firestore
.collection('doctorSpecializations')
.where(
'categoryId',
isEqualTo: Uri.encodeComponent(categoryKey),
)
.get();

// Delete the shared specialization documents in batches.
for (var start = 0;
    start < specializationSnapshot.docs.length;
    start += 450) {
  final chunk = specializationSnapshot.docs
      .skip(start)
      .take(450)
      .toList();

  final batch = firestore.batch();

  for (final doc in chunk) {
    batch.delete(doc.reference);
  }

  await batch.commit();
}

// Remove this category from existing doctor profiles.
final doctorSnapshot = await firestore
    .collection('doctors')
    .where(
      'categories',
      arrayContains: category,
    )
    .get();

for (var start = 0;
    start < doctorSnapshot.docs.length;
    start += 450) {
  final chunk = doctorSnapshot.docs
      .skip(start)
      .take(450)
      .toList();

  final batch = firestore.batch();

  for (final doc in chunk) {
    final data = doc.data();

    final categories = List<String>.from(
      (data['categories'] as List? ?? [])
          .map((item) => item.toString()),
    );

    categories.removeWhere(
      (item) => item.toLowerCase() == categoryKey,
    );

    final rawMapping = data['specializationsByCategory'];

    final mapping = <String, dynamic>{};

    if (rawMapping is Map) {
      rawMapping.forEach((key, value) {
        if (key.toString().toLowerCase() != categoryKey) {
          mapping[key.toString()] = value;
        }
      });
    }

    final updates = <String, dynamic>{
      'categories': categories,
      'specializationsByCategory': mapping,
    };

    // Rebuild the flat list when the category mapping exists.
    if (rawMapping is Map) {
      final remainingSpecializations = <String, String>{};

      for (final value in mapping.values) {
        if (value is List) {
          for (final item in value) {
            final name = item.toString().trim();

            if (name.isNotEmpty) {
              remainingSpecializations.putIfAbsent(
                name.toLowerCase(),
                () => name,
              );
            }
          }
        }
      }

      updates['specializations'] =
          remainingSpecializations.values.toList();
    }

    batch.update(doc.reference, updates);
  }

  await batch.commit();
}

// Finally, remove the category from the global catalog.
await firestore
    .collection('doctorCategories')
    .doc(Uri.encodeComponent(categoryKey))
    .delete();

if (!mounted) return;

setState(() {
  customCategories.removeWhere(
    (item) => item.toLowerCase() == categoryKey,
  );

  selectedCategories.removeWhere(
    (item) => item.toLowerCase() == categoryKey,
  );

  selectedSpecializationsByCategory.remove(categoryKey);

  if (activeSpecializationCategory?.toLowerCase() ==
      categoryKey) {
    activeSpecializationCategory =
        selectedCategories.isEmpty
            ? null
            : selectedCategories.first;
  }

  _syncSelectedSpecializations();

  filteredCategories = allCategories;
  filteredSpecializations = allSpecializations;

  categoryError = selectedCategories.isEmpty;
});

showMessage('"$category" was deleted globally.');

} on FirebaseException catch (e) {
debugPrint(
'DELETE CATEGORY ERROR ${e.code}: ${e.message}',
);

showMessage(
  'Could not complete deletion. Please try again.',
  error: true,
);

} catch (e) {
debugPrint('DELETE CATEGORY ERROR: $e');

showMessage(
  'An error occurred while deleting the category.',
  error: true,
);

}
}

// ============================================================
  // SPECIALIZATIONS FOR THE CURRENTLY SELECTED CATEGORY
  // ============================================================

  List<String> get allSpecializations {
    final category = activeSpecializationCategory;

    if (category == null || category.trim().isEmpty) {
      return [];
    }

    final Map<String, String> unique = {};

    // Built-in specializations for this category.
    for (final entry
        in _builtInSpecializationsByCategory.entries) {
      if (entry.key.toLowerCase() !=
          category.trim().toLowerCase()) {
        continue;
      }

      for (final name in entry.value) {
        unique.putIfAbsent(
          name.toLowerCase(),
          () => name,
        );
      }

      break;
    }

    // Shared custom specializations for this category.
    final shared = _sharedSpecializationsByCategory[
            category.trim().toLowerCase()] ??
        <String>{};

    for (final name in shared) {
      unique.putIfAbsent(
        name.toLowerCase(),
        () => name,
      );
    }

    final result = unique.values.toList()
      ..sort(
        (a, b) => a.toLowerCase().compareTo(
              b.toLowerCase(),
            ),
      );

    return result;
  }

  // ============================================================
  // FILTER SPECIALIZATIONS
  // ============================================================

  void filterSpecializations(String value) {
    final search = value.trim().toLowerCase();

    final result = allSpecializations.where((name) {
      return search.isEmpty ||
          name.toLowerCase().contains(search);
    }).toList();

    if (!mounted) return;

    setState(() {
      filteredSpecializations = result;
    });
  }

  // ============================================================
  // KEEP FLAT SPECIALIZATION LIST IN SYNC
  // ============================================================

  void _syncSelectedSpecializations() {
    final Map<String, String> unique = {};

    for (final category in selectedCategories) {
      final selected =
          selectedSpecializationsByCategory[
                  category.toLowerCase()] ??
              <String>{};

      for (final name in selected) {
        unique.putIfAbsent(
          name.toLowerCase(),
          () => name,
        );
      }
    }

    selectedSpecialCategories = unique.values.toList();
  }

Future<bool> addCustomSpecialization() async {
final specialization =
customSpecializationController.text.trim();

final category = activeSpecializationCategory?.trim();

if (selectedCategories.isEmpty || category == null) {
showMessage(
'Select a doctor category before adding a specialization.',
error: true,
);
return false;
}

if (!selectedCategories.any(
(item) => item.toLowerCase() == category.toLowerCase(),
)) {
showMessage(
'Please select this category first.',
error: true,
);
return false;
}

if (specialization.isEmpty) {
showMessage('Please enter a specialization.');
return false;
}

final existing = allSpecializations.where(
(item) => item.trim().toLowerCase() == specialization.toLowerCase(),
);

if (existing.isNotEmpty) {
showMessage('This specialization already exists in this category.');
return false;
}

final actualSpecialization = specialization;
final categoryKey = category.toLowerCase();

try {
final documentId = Uri.encodeComponent(
'${categoryKey}__${actualSpecialization.toLowerCase()}',
);

// await FirebaseFirestore.instance
//     .collection('doctorSpecializations')
//     .doc(documentId)
//     .set({
//   'name': actualSpecialization,
//   'categoryName': category,
//   'categoryId': Uri.encodeComponent(categoryKey),
//   'isUserAdded': true,
//   'createdAt': FieldValue.serverTimestamp(),
// }, SetOptions(merge: true));
await FirebaseFirestore.instance
    .collection('doctorSpecializations')
    .doc(documentId)
    .set({
  'name': actualSpecialization,
  'categoryName': category,
  'categoryId': Uri.encodeComponent(categoryKey),
  'isUserAdded': true,

  // NEW: Record who created this specialization.
  'createdByUid': FirebaseAuth.instance.currentUser?.uid,

  'createdAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

if (!mounted) return false;

setState(() {
  _sharedSpecializationsByCategory.putIfAbsent(
    categoryKey,
    () => <String>{},
  );

  isSpecializationDropdownOpen = false;

  _sharedSpecializationsByCategory[categoryKey]!
      .add(actualSpecialization);

  selectedSpecializationsByCategory.putIfAbsent(
    categoryKey,
    () => <String>{},
  );

  selectedSpecializationsByCategory[categoryKey]!
      .add(actualSpecialization);

  _syncSelectedSpecializations();

  specializationError = false;
  filteredSpecializations = allSpecializations;
});

customSpecializationController.clear();
specializationSearchController.clear();

showMessage('$actualSpecialization added under $category.');

return true;

} on FirebaseException catch (e) {
debugPrint(
'SPECIALIZATION SAVE ERROR ${e.code}: ${e.message}',
);

showMessage(
  'Could not save specialization. Check Firestore permissions.',
  error: true,
);

return false;

} catch (e) {
debugPrint('SPECIALIZATION SAVE ERROR: $e');

showMessage(
  'Could not save specialization.',
  error: true,
);

return false;

}
}

  void showAddSpecializationDialog() {
  customSpecializationController.clear();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),
        title: const Text(
          'Add Your Own Specialization',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller:
              customSpecializationController,
          textCapitalization:
              TextCapitalization.words,
          maxLength: 50,
          decoration: InputDecoration(
            hintText:
                'Enter specialization',
            prefixIcon: const Icon(
              Icons.medical_services_outlined,
              color: green,
            ),
            filled: true,
            fillColor: lightFill,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
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
            child: const Text(
              'CANCEL',
            ),
          ),
          ElevatedButton(
       onPressed: () async {
final saved = await addCustomSpecialization();

if (!saved) return;

if (dialogContext.mounted) {
Navigator.of(dialogContext).pop();
}
},
            style:
                ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor:
                  Colors.white,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'ADD',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}

  @override
  void dispose() {
    timer?.cancel();

    nameController.dispose();
    phoneController.dispose();
    otpController.dispose();
    secondaryPhoneController.dispose();
    categoryController.dispose();
    experienceController.dispose();
    placeNameController.dispose();
    categorySearchController.dispose();
    specializationSearchController.dispose();
    customSpecializationController.dispose();
    specializedSearchController.dispose();
    stateSearchController.dispose();
    districtSearchController.dispose();
   _sharedDoctorCategoriesSubscription?.cancel();
_sharedDoctorSpecializationsSubscription?.cancel();

    super.dispose();
  }

 void showMessage(
  String message, {
  bool error = false,
}) {
  if (!mounted) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),

        backgroundColor: error
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

  final phone = phoneController.text.trim();

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
  // FORM VALIDATION
  // ============================================================

 bool validateDoctorForm() {
  bool valid = true;

  setState(() {
    nameError = '';
    phoneErrorMessage = '';
    secondaryPhoneError = '';
    stateError = '';
    districtError = '';
    nearestCityError = '';
    //genderError = '';
    experienceError = '';
    otpErrorMessage = '';
    consultationTimeError = '';
    categoryError = false;
    specializationError = false;
    privacyPolicyError = null;
  });

  final name = nameController.text.trim();
  final phone = phoneController.text.trim();
  final secondaryPhone =
      secondaryPhoneController.text.trim();
  final experienceText =
      experienceController.text.trim();

  // ============================================================
  // NAME - REQUIRED
  // ============================================================

  if (name.isEmpty) {
    nameError = 'Enter your name';
    valid = false;
  }

  // ============================================================
  // PRIMARY MOBILE - REQUIRED
  // ============================================================

  if (phone.length != 10 ||
      !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
    phoneErrorMessage =AppLocalizations.of(context)!.enteradigitmobilenumber;
      //  'Enter a valid 10-digit mobile number';
    valid = false;
  }

  // ============================================================
  // SECONDARY MOBILE - REQUIRED
  // ============================================================

  if (secondaryPhone.length != 10 ||
      !RegExp(r'^[0-9]{10}$')
          .hasMatch(secondaryPhone)) {
    secondaryPhoneError =AppLocalizations.of(context)!.enteradigitmobilenumber;
      //  'Enter a valid 10-digit mobile number';
    valid = false;
  }

  // ============================================================
  // OTP - REQUIRED
  // ============================================================

  if (!otpVerified) {
    otpErrorMessage =
        'Please verify your mobile number';
    valid = false;
  }

 // ============================================================
// STATE - REQUIRED
// ============================================================

if (selectedState == null ||
    selectedState!.trim().isEmpty) {
  stateError = 'Please select a state.';
  valid = false;
} else {
  stateError = '';
}

// ============================================================
// DISTRICT - REQUIRED
// ============================================================

if (selectedDistrict == null ||
    selectedDistrict!.trim().isEmpty) {
  districtError = 'Please select a district.';
  valid = false;
} else {
  districtError = '';
}

// ============================================================
// NEAREST TOWN - REQUIRED
// ============================================================

if (nearestCityController.text.trim().isEmpty) {
  nearestCityError =
      'Please enter the nearest town or city.';
  valid = false;
} else {
  nearestCityError = '';
}

  // ============================================================
  // MEDICAL CATEGORY - REQUIRED
  // ============================================================

  if (selectedCategories.isEmpty) {
    categoryError = true;
    valid = false;
  }

  // ============================================================
  // SPECIALIZATION - REQUIRED
  // ============================================================

  if (selectedSpecialCategories.isEmpty) {
    specializationError = true;
    valid = false;
  }

  // ============================================================
  // CONSULTATION TIME - REQUIRED
  // ============================================================

  if (consultationFrom == null) {
    consultationTimeError =
        'Select consultation start time';
    valid = false;
  }

  if (consultationTo == null) {
    consultationTimeError =
        'Select consultation end time';
    valid = false;
  }

  // ============================================================
  // CURRENT LOCATION - REQUIRED
  // ============================================================

  // if (currentLocation == null) {
  //   valid = false;
  // }

  if (currentLocation == null) {
    locationError = true;
    valid = true;
  }

  // ============================================================
  // EXPERIENCE - OPTIONAL
  // ============================================================

  if (experienceText.isNotEmpty) {
    final experience =
        int.tryParse(experienceText);

    if (experience == null) {
      experienceError =
          'Enter experience in complete years';
      valid = false;
    } else if (experience < 0 ||
        experience > 80) {
      experienceError =
          'Experience must be between 0 and 80 years';
      valid = false;
    }
  }

  // ============================================================
  // GENDER - OPTIONAL
  // ============================================================
  // No validation needed.

  // ============================================================
  // WORKING DAYS - OPTIONAL
  // ============================================================
  // No validation needed.

  // ============================================================
  // PRIVACY + TERMS - REQUIRED
  // ============================================================

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
  // ============================================================
 

  // ============================================================
  // FIRESTORE ERROR MESSAGE
  // ============================================================

  String firestoreErrorMessage(
    FirebaseException error,
  ) {
    switch (error.code) {
      case 'permission-denied':
        return 'Registration was blocked by server permissions. '
            'Please contact support.';

      case 'unauthenticated':
        return 'Your login session expired. '
            'Please verify your mobile number again.';

      case 'unavailable':
        return 'Server is temporarily unavailable. '
            'Please check your internet connection and try again.';

      case 'deadline-exceeded':
        return 'The server took too long to respond. '
            'Please try again.';

      case 'resource-exhausted':
        return 'The service is temporarily busy. '
            'Please try again shortly.';

      default:
        return 'Unable to save your profile right now. '
            'Please try again.';
    }
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
// PICK CONSULTATION FROM TIME
// ============================================================

Future<void> pickConsultationFromTime() async {
  final picked = await showTimePicker(
    context: context,
    initialTime:
        consultationFrom ?? const TimeOfDay(hour: 9, minute: 0),
  );

  if (picked == null) return;

  setState(() {
    consultationFrom = picked;
    consultationTimeError = '';
  });
}

// ============================================================
// PICK CONSULTATION TO TIME
// ============================================================

Future<void> pickConsultationToTime() async {
  final picked = await showTimePicker(
    context: context,
    initialTime:
        consultationTo ?? const TimeOfDay(hour: 17, minute: 0),
  );

  if (picked == null) return;

  setState(() {
    consultationTo = picked;
    consultationTimeError = '';
  });
}

// ============================================================
// FORMAT TIME
// ============================================================

String formatConsultationTime(TimeOfDay? time) {
  if (time == null) return '';

  final hour = time.hourOfPeriod == 0
      ? 12
      : time.hourOfPeriod;

  final minute = time.minute.toString().padLeft(2, '0');

  final period =
      time.period == DayPeriod.am ? 'AM' : 'PM';

  return '$hour:$minute $period';
}

  // ============================================================
// CONSULTATION TIME SECTION
// ============================================================

Widget consultationTimeSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sectionTitle(
        'Consultation Time ',
      ),

      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: pickConsultationFromTime,
              style: OutlinedButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Text(
                    'From',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    consultationFrom == null
                        ? 'Select time'
                        : formatConsultationTime(
                            consultationFrom,
                          ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,color: Colors.black
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: OutlinedButton(
              onPressed: pickConsultationToTime,
              style: OutlinedButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Text(
                    'To',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    consultationTo == null
                        ? 'Select time'
                        : formatConsultationTime(
                            consultationTo,
                          ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,color: Colors.black
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      if (consultationTimeError.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(
            top: 6,
            left: 12,
          ),
          child: Text(
            consultationTimeError,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ),
    ],
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

   TextField(
  controller: secondaryPhoneController,
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
    icon: Icons.phone_android_outlined,
    hasError: secondaryMobileError,
  ).copyWith(
    counterText: '',
  ),
),

if (secondaryMobileError)
  const Padding(
    padding: EdgeInsets.only(left: 12, top: 5),
    child: Text(
      'Please enter a valid 10-digit secondary mobile number.',
      style: TextStyle(
        color: Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),

      const SizedBox(height: 5),

      const Text(
        'You can use same Number,if another Number is not available.',
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

  // ============================================================
  // SAVE BASIC LOCAL DOCTOR DATA
  // ============================================================

  Future<void> saveBasicDoctorData() async {
    try {
      final box = Hive.box('appBox');

      await box.put(
        'doctorName',
        nameController.text.trim(),
      );

      await box.put(
        'doctorPhone',
        phoneController.text.trim(),
      );

      await box.put(
        'doctorGender',
        selectedGender,
      );
    } catch (_) {
      // Local cache failure should not stop OTP verification.
    }
  }

  // ============================================================
// CREATE FIRESTORE DOCTOR DATA
  // ============================================================

  Map<String, dynamic> createDoctorFirestoreData(
    User user,
  ) {
 
return {
  'uid': user.uid,

  'doctorName':
      nameController.text.trim(),

  'phone':
      phoneController.text.trim(),

  'secondaryPhone':
      secondaryPhoneController.text.trim(),

 
  // OPTIONAL
  'gender':
      selectedGender,

  // OPTIONAL
  'experience':
      experienceController.text.trim().isEmpty
          ? null
          : int.tryParse(
              experienceController.text.trim(),
            ),

  // REQUIRED
  'categories':
      List<String>.from(
    selectedCategories,
  ),

  // REQUIRED
  'specializations':
      List<String>.from(
    selectedSpecialCategories,
  ),

  'specializationsByCategory': {
    for (final category in selectedCategories)
      category: (
        selectedSpecializationsByCategory[
                category.toLowerCase()] ??
            <String>{}
      ).toList(),
  },

  'profilePhotoUrl':
      profilePhotoUrl,

  'location': {
    'latitude':
        currentLocation!.latitude,
    'longitude':
        currentLocation!.longitude,
    'address':
        currentLocation!.placeName,
  },

  // STATE, DISTRICT AND NEAREST TOWN
  'state': selectedState!.trim(),

'district': selectedDistrict!.trim(),

'nearestTown':
    nearestCityController.text.trim(),


  'consultationTime': {
    'from':
        formatConsultationTime(
      consultationFrom,
    ),
    'to':
        formatConsultationTime(
      consultationTo,
    ),
  },

  // OPTIONAL
  'workingDays':
      List<String>.from(
    selectedDays,
  ),

  // 'isActive': true,

  // 'updatedAt':
  //     FieldValue.serverTimestamp(),

  // 'profileCompleted':
  //     true,
  'isActive': true,

  // Provider is online after registration.
  'isOnline': true,
  'onlineUpdatedAt':
      FieldValue.serverTimestamp(),

  'updatedAt':
      FieldValue.serverTimestamp(),

  'profileCompleted':
      true,
};
  }

  // ============================================================
  // SAVE DOCTOR PROFILE TO FIRESTORE

  Future<void> saveDoctorProfileToFirestore(
  String uid,
  Map<String, dynamic> doctorData,
) async {
  try {
    debugPrint('========================================');
    debugPrint('DOCTOR FIRESTORE SAVE START');
    debugPrint('UID: $uid');
    debugPrint('========================================');

    await firestore
        .collection('doctors')
        .doc(uid)
        .set(
          doctorData,
          SetOptions(merge: true),
        );

    debugPrint('========================================');
    debugPrint('DOCTOR FIRESTORE SAVE SUCCESS');
    debugPrint('UID: $uid');
    debugPrint('========================================');
  } on FirebaseException catch (e) {
    debugPrint('========================================');
    debugPrint('DOCTOR FIRESTORE ERROR');
    debugPrint('CODE: ${e.code}');
    debugPrint('MESSAGE: ${e.message}');
    debugPrint('========================================');

    rethrow;
  } catch (e) {
    debugPrint('========================================');
    debugPrint('DOCTOR FIRESTORE UNKNOWN ERROR');
    debugPrint('$e');
    debugPrint('========================================');

    rethrow;
  }
}

  // ============================================================
  // SAVE DOCTOR LOCALLY
  // ============================================================

  Future<void> saveDoctorLocallyinHive() async {
    try {
      final box = Hive.box('appBox');

      // final experience =
      //     getExperienceYears();

      await box.put(
        'doctorName',
        nameController.text.trim(),
      );

      await box.put(
        'doctorPhone',
        phoneController.text.trim(),
      );

await box.put(
  'doctorSecondaryPhone',
  secondaryPhoneController.text.trim(),
);
// ============================================================
// SAVE STATE, DISTRICT AND NEAREST TOWN TO HIVE
// ============================================================

await box.put(
  'doctorState',
  selectedState!.trim(),
);

await box.put(
  'doctorDistrict',
  selectedDistrict!.trim(),
);

await box.put(
  'doctorNearestCity',
  nearestCityController.text.trim(),
);

      await box.put(
        'doctorGender',
        selectedGender,
      );

      await box.put(
        'doctorCategories',
        List<String>.from(
          selectedCategories,
        ),
      );

      await box.put(
        'doctorSpecializations',
        List<String>.from(
          selectedSpecialCategories,
        ),
      );

      await box.put(
  'doctorSpecializationsByCategory',
  {
    for (final category in selectedCategories)
      category: (
        selectedSpecializationsByCategory[
                category.toLowerCase()] ??
            <String>{}
      ).toList(),
  },
);

      await box.put(
  'doctorConsultationTime',
  {
    'from': formatConsultationTime(
      consultationFrom,
    ),
    'to': formatConsultationTime(
      consultationTo,
    ),
  },
);

      if (currentLocation != null) {
  await box.put(
    'doctorLatitude',
    currentLocation!.latitude,
  );

  await box.put(
    'doctorLongitude',
    currentLocation!.longitude,
  );

  await box.put(
    'doctorLocationAddress',
    currentLocation!.placeName,
  );
}

      await box.put(
        'doctorWorkingDays',
        List<String>.from(
          selectedDays,
        ),
      );
    } catch (_) {
      // Firestore remains the important global registration copy.
    }
  }

  bool _isValidIndianMobile(
    String mobile,
  ) {

    return RegExp(
      r'^[6-9][0-9]{9}$',
    ).hasMatch(
      mobile,
    );
  }
 Future submitProfile() async {
  if (isSubmitting) return;

  FocusScope.of(context).unfocus();

  bool hasError = false;

  // ============================================================
  // CLEAR OLD ERRORS
  // ============================================================

  setState(() {
    nameError = '';
    phoneErrorMessage = '';
    secondaryPhoneError = '';
    stateError = '';
districtError = '';
nearestCityError = '';
    genderError = '';
    experienceError = '';
    otpErrorMessage = '';
    consultationTimeError = '';
    categoryError = false;
    specializationError = false;
    privacyPolicyError = null;
  });

  // ============================================================
  // NAME - REQUIRED
  // ============================================================

  if (nameController.text.trim().isEmpty) {
    nameError = 'Enter your name';
    hasError = true;
  }

  // ============================================================
  // PRIMARY MOBILE - REQUIRED
  // ============================================================

  final String phone =
      phoneController.text.trim();

  // if (phone.isEmpty ||
  //     phone.length != 10 ||
  //     !RegExp(r'^[0-9]{10}$')
  //         .hasMatch(phone)) {
  //   phoneErrorMessage =
  //       'Enter a valid 10-digit mobile number';
  //   hasError = true;
  // }

  mobileError =
      !_isValidIndianMobile(phone);

  if (mobileError) {
    hasError = true;
  }

  // ============================================================
  // SECONDARY MOBILE - REQUIRED
  // ============================================================

  final String secondaryMobile =
      secondaryPhoneController.text.trim();

  secondaryMobileError =
      !_isValidIndianMobile(secondaryMobile);

  if (secondaryMobileError) {
    hasError = true;
  }

  // ============================================================
  // OTP - REQUIRED
  // ============================================================

  if (!otpVerified) {
    otpErrorMessage =
        'Please verify your mobile number.';
    hasError = true;
  }

  // ============================================================
  // MEDICAL CATEGORY - REQUIRED
  // ============================================================

  if (selectedCategories.isEmpty) {
    categoryError = true;
    hasError = true;
  }

  // ============================================================
  // SPECIALIZATION - REQUIRED
  // ============================================================

  if (selectedSpecialCategories.isEmpty) {
    specializationError = true;
    hasError = true;
  }

  // ============================================================
  // CONSULTATION TIME - REQUIRED
  // ============================================================

  if (consultationFrom == null) {
    consultationTimeError =
        'Select consultation start time';
    hasError = true;
  }

  if (consultationTo == null) {
    consultationTimeError =
        'Select consultation end time';
    hasError = true;
  }

 // ============================================================
// STATE, DISTRICT AND NEAREST TOWN - REQUIRED
// ============================================================

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
  // CURRENT LOCATION - REQUIRED
  // ============================================================

  // if (currentLocation == null) {
  //   hasError = true;
  // }

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
  // EXPERIENCE - OPTIONAL
  // ============================================================

  final experienceText =
      experienceController.text.trim();

  if (experienceText.isNotEmpty) {
    final experience =
        int.tryParse(experienceText);

    if (experience == null) {
      experienceError =
          'Enter experience in complete years';
      hasError = true;
    } else if (experience < 0 ||
        experience > 80) {
      experienceError =
          'Experience must be between 0 and 80 years';
      hasError = true;
    }
  }

  // ============================================================
  // WORKING DAYS - OPTIONAL
  // ============================================================
  // No validation.

  // ============================================================
  // PRIVACY + TERMS - REQUIRED
  // ============================================================

  if (!privacyPolicyAccepted) {
    privacyPolicyError =
        'Please accept the Privacy Policy and Terms & Conditions.';
    hasError = true;
  }

  // ============================================================
  // REFRESH VALIDATION UI
  // ============================================================

  if (!mounted) return;

  setState(() {});

  // ============================================================
  // STOP IF ANY REQUIRED FIELD IS INVALID
  // ============================================================

  if (hasError) {
    return;
  }

  // ============================================================
  // OTP VERIFIED
  // ============================================================

  if (!otpVerified) {
    return;
  }

  // ============================================================
  // FIREBASE USER
  // ============================================================

  final User? user =
      auth.currentUser;

  if (user == null) {
    showMessage(
      'Authentication failed. Please verify your mobile number again.',
      error: true,
    );
    return;
  }

  // ============================================================
  // START SUBMITTING
  // ============================================================

  setState(() {
    isSubmitting = true;
  });

  try {
    final doctorData =
        createDoctorFirestoreData(user);

    // SAVE LOCALLY
    await saveDoctorLocallyinHive();

    // SAVE SYNC DATA
    final box = Hive.box('appBox');

    await box.put(
      'doctorSyncPending',
      true,
    );

    await box.put(
      'doctorSyncUid',
      user.uid,
    );

    final hiveDoctorData =
        Map<String, dynamic>.from(
      doctorData,
    );

    hiveDoctorData['updatedAt'] =
        DateTime.now().toIso8601String();

    await box.put(
      'doctorFirestoreData',
      hiveDoctorData,
    );

    // LOGIN STATUS
    await CommonProfileService.saveLogin(
      uid: user.uid,
      name: nameController.text.trim(),
      mobile: phoneController.text.trim(),
      role: 'doctors',
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

      // FIRESTORE SAVE
    await saveDoctorProfileToFirestore(
      user.uid,
      doctorData,
    );
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const ScreenHome(),
      ),
      (route) => false,
    );

  
  } catch (e, stackTrace) {
    debugPrint(
      'DOCTOR REGISTRATION ERROR: $e',
    );

    debugPrint(
      'STACK TRACE: $stackTrace',
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    showMessage(
      'Could not save doctor profile. Please try again.',
      error: true,
    );
  }
}

  Future<void> syncDoctorInBackground(
  String uid,
  Map<String, dynamic> doctorData,
) async {
  try {
    debugPrint(
      'DOCTOR BACKGROUND SYNC START',
    );

    await saveDoctorProfileToFirestore(
      uid,
      doctorData,
    );

    // ----------------------------------------------------------
    // Firestore upload succeeded.
    // ----------------------------------------------------------

    final box = Hive.box('appBox');

    await box.put(
      'doctorSyncPending',
      false,
    );

    await box.delete(
      'doctorFirestoreData',
    );

    await box.delete(
      'doctorSyncUid',
    );

    debugPrint(
      'DOCTOR BACKGROUND SYNC SUCCESS',
    );
  } catch (e) {
    // ----------------------------------------------------------
    // Firestore failed.
    //
    // IMPORTANT:
    // We DO NOT delete the local profile.
    //
    // The profile remains marked as pending so it can be
    // uploaded again later.
    // ----------------------------------------------------------

    final box = Hive.box('appBox');

    await box.put(
      'doctorSyncPending',
      true,
    );

    debugPrint(
      'DOCTOR BACKGROUND SYNC FAILED: $e',
    );

    debugPrint(
      'DOCTOR PROFILE REMAINED LOCALLY FOR RETRY',
    );
  }
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
  // GENDER BUTTON
  // ============================================================

   Widget _genderButton({
    required String title,
    required String value,
    // required IconData icon,
  }) {
    final bool selected =
        selectedGender == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = value;
         // genderError = false;
        });
      },

      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 200,
        ),

        height: 58,

        decoration:
            BoxDecoration(
          color: selected
              ? const Color(
                  0xFFEFF8EF,
                )
              : const Color(
                  0xFFF8F9FA,
                ),

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          border: Border.all(
            color: selected
                ? const Color(
                    0xFF159B16,
                  )
                : Colors.grey.shade300,

            width:
                selected ? 2 : 1,
          ),
        ),

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            // Icon(
            //   icon,

            //   color: selected
            //       ? const Color(
            //           0xFF159B16,
            //         )
            //       : Colors.grey.shade700,
            // ),

            const SizedBox(width: 8),

            Text(title,style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selected ? const Color(0xFF159B16):const Color(0xFF202124)
              ),
            ),
          ],
        ),
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
  currentLocation = DoctorLocation(
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
  currentLocation = DoctorLocation(
    placeName: placeName,
    latitude: position.latitude,
    longitude: position.longitude,
  );

  locationError = false;
});

    showMessage(
      'Consultation location added.',
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
                                    'Select Doctor categories',
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
style: TextStyle(
color: Colors.grey.shade600,
),
),
)
: RadioGroup<String>(
groupValue: selectedCategories.isEmpty
? null
: selectedCategories.first,
onChanged: (String? value) {
if (value == null) return;

        setState(() {
          selectedCategories
            ..clear()
            ..add(value);

          activeSpecializationCategory = value;

          // Clear old selections when changing categories.
          selectedSpecializationsByCategory.clear();
          selectedSpecialCategories.clear();

          categoryError = false;
          filteredSpecializations = allSpecializations;
        });
      },
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];

          final isBuiltIn = doctorCategories.any(
(item) => item.toLowerCase() == category.toLowerCase(),
);

return RadioListTile<String>(
value: category,
dense: true,
contentPadding: const EdgeInsets.symmetric(
horizontal: 2,
),
activeColor: green,
title: Text(
category,
style: const TextStyle(
color: darkText,
fontSize: 14,
),
),

// Show delete only for user-added categories.
secondary: isBuiltIn
? null
: IconButton(
tooltip: 'Delete $category globally',
icon: const Icon(
Icons.delete_outline,
color: Colors.red,
size: 21,
),
onPressed: () {
deleteCustomDoctorCategory(category);
},
),
);

          // return RadioListTile<String>(
          //   value: category,
          //   dense: true,
          //   contentPadding: const EdgeInsets.symmetric(
          //     horizontal: 2,
          //   ),
          //   activeColor: green,
          //   title: Text(
          //     category,
          //     style: const TextStyle(
          //       color: darkText,
          //       fontSize: 14,
          //     ),
          //   ),
          // );
        },
      ),
    ),

)
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
  // SPECIALIZATION SELECTOR
  // ============================================================

 Widget specializationSection() {
  final specializationsList =
      filteredSpecializations;

  return Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: lightFill,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: specializationError
                ? Colors.red
                : isSpecializationDropdownOpen
                    ? green
                    : Colors.grey.shade300,
            width:
                specializationError ||
                        isSpecializationDropdownOpen
                    ? 1.5
                    : 1,
          ),
        ),
        child: Column(
          children: [
            // ------------------------------------------------
            // SPECIALIZATION HEADER
            // ------------------------------------------------

            InkWell(
              borderRadius:
                  BorderRadius.circular(20),
              onTap: () {
                FocusScope.of(context)
                    .unfocus();

                setState(() {
                  isSpecializationDropdownOpen =
                      !isSpecializationDropdownOpen;

                  specializationError = false;
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
                      Icons
                          .medical_services_outlined,
                      color: green,
                      size: 22,
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child:
                          selectedSpecialCategories
                                  .isEmpty
                              ? Text(
                                  'Select Specialization',
                                  style:
                                      TextStyle(
                                    color: Colors
                                        .grey
                                        .shade500,
                                    fontSize: 15,
                                  ),
                                )
                              : Text(
                                  selectedSpecialCategories
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
                      isSpecializationDropdownOpen
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

            if (isSpecializationDropdownOpen)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  12,
                ),
                child: Column(
                  // SELECT WHICH CATEGORY THESE SPECIALIZATIONS BELONG TO
                  children: [
                     if (selectedCategories.isEmpty)
    const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Select a doctor category first.',
        style: TextStyle(
          color: Colors.red,
          fontSize: 12,
        ),
      ),
    )
  else
    DropdownButtonFormField<String>(
      initialValue: selectedCategories.contains(
        activeSpecializationCategory,
      )
          ? activeSpecializationCategory
          : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Specializations for category',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      items: selectedCategories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (category) {
        if (category == null) return;

        setState(() {
          activeSpecializationCategory = category;
          specializationSearchController.clear();
          filteredSpecializations = allSpecializations;
        });
      },
    ),

  const SizedBox(height: 10),
                    // SEARCH
                    TextField(
                      controller:
                          specializationSearchController,
                      onChanged:
                          filterSpecializations,
                      decoration:
                          InputDecoration(
                        hintText:
                            'Search specialization...',
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

                    // ADD CUSTOM SPECIALIZATION
                    InkWell(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      onTap:
                          showAddSpecializationDialog,
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
                                    .withValues(
                                  alpha: 0.10,
                                ),
                                shape:
                                    BoxShape.circle,
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
                                'Add your own specialization',
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

                    // SPECIALIZATION LIST
                    SizedBox(
                      height: 320,
                      child:
                          specializationsList
                                  .isEmpty
                              ? Center(
                                  child: Text(
                                    'No specialization found',
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
                                      specializationsList
                                          .length,
                                  itemBuilder:
                                      (
                                    context,
                                    index,
                                  ) {
                                    final specialization =
                                        specializationsList[
                                            index];

 
  final isSelected =
activeSpecializationCategory != null &&
(selectedSpecializationsByCategory[
activeSpecializationCategory!.toLowerCase()] ??
<String>{})
.any(
(item) =>
item.toLowerCase() ==
specialization.toLowerCase(),
);

return CheckboxListTile(
dense: true,
contentPadding: const EdgeInsets.symmetric(
horizontal: 2,
),
activeColor: green,
checkColor: Colors.white,
value: isSelected,
title: Text(
specialization,
style: const TextStyle(
color: darkText,
fontSize: 14,
),
),
onChanged: (bool? checked) {
final activeCategory = activeSpecializationCategory;

if (activeCategory == null) return;

setState(() {
  final categoryKey = activeCategory.toLowerCase();

  final categorySpecializations =
      selectedSpecializationsByCategory.putIfAbsent(
    categoryKey,
    () => <String>{},
  );

  if (checked == true) {
    categorySpecializations.add(specialization);
  } else {
    categorySpecializations.removeWhere(
      (item) =>
          item.toLowerCase() ==
          specialization.toLowerCase(),
    );
  }

  _syncSelectedSpecializations();

  specializationError = false;
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

      if (specializationError)
        const Padding(
          padding:
              EdgeInsets.only(
            left: 12,
            top: 5,
          ),
          child: Text(
            'Please select at least one specialization.',
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
  // WORKING DAYS SELECTOR
  // ============================================================

  Widget workingDaysSection() {
    return MultiSelectDialogField<String>(
      items: workingDays
          .map(
            (item) => MultiSelectItem<String>(
              item,
              item,
            ),
          )
          .toList(),
      initialValue:
          List<String>.from(selectedDays),
      title: const Text('Working Days'),
      buttonText:
          const Text('Select Working Days'),
      searchable: false,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade400,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      onConfirm: (values) {
        setState(() {
          selectedDays =
              List<String>.from(values);
        });
      },
    );
  }

  // ============================================================
  // MOBILE SECTION
  // ============================================================

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
                      phoneController,

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

  // ============================================================
  // SUBMIT BUTTON
  // ============================================================

  Widget submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed:
            isSubmitting
                ? null
                : submitProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
        child: isSubmitting
            ? const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 21,
                    height: 21,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Creating Profile...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const Text(
                'Submit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
      ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white,

      // ==========================================================
      // STUDENT-STYLE APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        elevation: 0,

        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
            color: Colors.black,
          ),

          onPressed: () {
            Navigator.pop(
              context,
            );
          },
        ),

        titleSpacing: 0,

        title: RichText(
          text:
               TextSpan(
            style:
                TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.w800,
            ),

            children: [

              TextSpan(
                text: 'Doctor ',
                style:
                    TextStyle(
                  color:
                      Color(0xFF08744F),
                ),
              ),

              TextSpan(
                text: AppLocalizations.of(context)!.registration,
                  //  'Registration',
                style:
                    TextStyle(
                 color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),


      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // NAME
              // --------------------------------------------------

              TextField(
                controller:
                    nameController,
                textCapitalization:
                    TextCapitalization.words,
                decoration: fieldDecoration(
  hintText: 'Enter your name',
  icon: Icons.person_outline,
  hasError: nameError.isNotEmpty,
),

              ),

              if (nameError.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 6,
                    left: 12,
                  ),
                  child: Text(
                    nameError,
                    style:
                        const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // --------------------------------------------------
              // GENDER
              // --------------------------------------------------

             // genderButton(),
               Row(
                children: [
                  Expanded(
                    child:
                        _genderButton(
                      title: 'Male',
                      // icon:
                      //     Icons.male,
                      value: 'Male',
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                        _genderButton(
                      title: 'Female',
                      // icon:
                      //     Icons.female,
                      value:
                          'Female',
                    ),
                  ),
                ],
              ),

              // --------------------------------------------------
              // EXPERIENCE
              // --------------------------------------------------

            // experienceSection(),

              const SizedBox(height: 16),
 sectionTitle('Mobile Number'),
              const SizedBox(height: 6),
              // --------------------------------------------------
              // PHONE
              // --------------------------------------------------
                mobileSection(),

                // ==================================================
                // MOBILE VALIDATION MESSAGE
                // ==================================================

                if (!otpVerified &&
                    phoneController
                        .text
                        .isNotEmpty &&
                    phoneController
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
                    //  'Enter a valid 10-digit number',
AppLocalizations.of(context)!.enteradigitmobilenumber,
                      style:
                          TextStyle(
                        color:
                            Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),

              // const SizedBox(height: 16),

              // --------------------------------------------------
              // OTP
              // --------------------------------------------------

              otpSection(),

              const SizedBox(height: 20),
              secondaryMobileSection(),

if (secondaryPhoneError.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(
      top: 6,
      left: 12,
    ),
    child: Text(
      secondaryPhoneError,
      style: const TextStyle(
        color: Colors.red,
        fontSize: 12,
      ),
    ),
  ),
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

              // --------------------------------------------------
              // MEDICAL CATEGORY
              // --------------------------------------------------

              const Text(
                'Medical Category',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              categorySection(),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // SPECIALIZATION
              // --------------------------------------------------

              const Text(
                'Specialization',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              specializationSection(),

              const SizedBox(height: 20),
              _profilePhotoSection(),
              // --------------------------------------------------
              // LOCATION
              // --------------------------------------------------
              const SizedBox(height: 20),

              locationSection(),

              const SizedBox(height: 20),

              consultationTimeSection(),

              const SizedBox(height: 20),
              // --------------------------------------------------
              // WORKING DAYS
              // --------------------------------------------------

              const Text(
                'Working Days',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              workingDaysSection(),

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

              // --------------------------------------------------
              // SUBMIT
              // --------------------------------------------------

              submitButton(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}


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
//   currentLocation = DoctorLocation(
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

  // final experience = getExperienceYears();

//     return {
//       'uid': user.uid,

//       'doctorName':
//           nameController.text.trim(),

//       'phone':
//           phoneController.text.trim(),

//       'gender':
//           selectedGender,

//       'categories':
//           List<String>.from(selectedCategories),

//       'specializations':
//           List<String>.from(
//         selectedSpecialCategories,
//       ),
      
//       'profilePhotoUrl': profilePhotoUrl,
//      'location': {
//   'latitude': currentLocation!.latitude,
//   'longitude': currentLocation!.longitude,
//   'address': currentLocation!.placeName,
// },

//       'consultationTime': {
//   'from': formatConsultationTime(
//     consultationFrom,
//   ),
//   'to': formatConsultationTime(
//     consultationTo,
//   ),
// },

//       'workingDays':
//           List<String>.from(selectedDays),

//       'isActive':true,

//       'updatedAt':
//           FieldValue.serverTimestamp(),

//       'profileCompleted':
//           true,
//     };

// class DoctorLocation {
//   final String placeName;
//   final double latitude;
//   final double longitude;

//   DoctorLocation({
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

//   factory DoctorLocation.fromMap(Map<String, dynamic> map) {
//     return DoctorLocation(
//       placeName: map['placeName'] ?? '',
//       latitude: (map['latitude'] ?? 0).toDouble(),
//       longitude: (map['longitude'] ?? 0).toDouble(),
//     );}
// }


//   Future<void> verifyOTP() async {
//     if (isVerifying) return;

//     final otp =
//         otpController.text.trim();

//     // ----------------------------------------------------------
//     // OTP SESSION
//     // ----------------------------------------------------------

//     if (verificationId == null ||
//         verificationId!.isEmpty) {
//       setState(() {
//         otpError = true;
//         otpErrorMessage =
//             'Please send OTP first.';
//       });
//       return;
//     }

//     // ----------------------------------------------------------
//     // OTP LENGTH
//     // ----------------------------------------------------------

//     if (otp.length != 6) {
//       setState(() {
//         otpError = true;
//         otpErrorMessage =
//             'Enter the complete 6-digit OTP.';
//       });
//       return;
//     }

//     // ----------------------------------------------------------
//     // EXPIRED OTP
//     // ----------------------------------------------------------

//     if (secondsRemaining <= 0) {
//       setState(() {
//         otpError = true;
//         otpErrorMessage =
//             'OTP expired. Please resend OTP.';
//       });
//       return;
//     }

//     FocusScope.of(context).unfocus();

//     setState(() {
//       isVerifying = true;
//       otpError = false;
//       otpErrorMessage = '';
//     });

//     try {
//       final credential =
//           PhoneAuthProvider.credential(
//         verificationId:
//             verificationId!,
//         smsCode: otp,
//       );

//       // await auth.signInWithCredential(
//       //   credential,
//       // );

//       // if (!mounted) return;
//       final userCredential =
//     await auth.signInWithCredential(
//   credential,
// );

// final signedInUser = userCredential.user;

// if (signedInUser != null) {
//   await markExistingDoctorOnline(
//     signedInUser.uid,
//   );
// }

// if (!mounted) return;

//       timer?.cancel();

//       setState(() {
//         isVerifying = false;
//         otpVerified = true;
//         otpSent = false;
//         otpError = false;
//         otpErrorMessage = '';
//       });

//       otpController.clear();

//       showMessage(
//         'Mobile number verified successfully.',
//       );
//     } on FirebaseAuthException catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isVerifying = false;
//         otpError = true;
//       });

//       switch (e.code) {
//         case 'invalid-verification-code':
//           otpErrorMessage =
//               'Incorrect OTP. Please check and try again.';
//           break;

//         case 'session-expired':
//           otpErrorMessage =
//               'OTP expired. Please request a new OTP.';
//           break;

//         case 'invalid-verification-id':
//           otpErrorMessage =
//               'Verification session expired. Please send OTP again.';
//           break;

//         case 'credential-already-in-use':
//           otpErrorMessage =
//               'This mobile number is already registered.';
//           break;

//         case 'network-request-failed':
//           otpErrorMessage =
//               'Network error. Check your internet connection.';
//           break;

//         default:
//           otpErrorMessage =
//               e.message ??
//               'OTP verification failed.';
//       }

//       setState(() {});

//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isVerifying = false;
//         otpError = true;
//         otpErrorMessage =
//             'OTP verification failed. Please try again.';
//       });

//       debugPrint(
//         'verifyOTP error: $e',
//       );
//     }
//   }

//  void addCustomCategory() {
//     final String category =
//         customCategoryController.text.trim();

//     if (category.isEmpty) {
//       showMessage(
//         'Please enter a category.',
//       );
//       return;
//     }

//     final int existingIndex =
//         allCategories.indexWhere(
//       (item) =>
//           item.toLowerCase() ==
//           category.toLowerCase(),
//     );

//     String actualCategory;

//     if (existingIndex != -1) {

//       actualCategory =
//           allCategories[existingIndex];

//     } else {

//       customCategories.add(
//         category,
//       );
//       actualCategory = category;
//     }

//     if (!selectedCategories.contains(
//       actualCategory,
//     )) {

//       selectedCategories.add(
//         actualCategory,
//       );

//     }

//     customCategoryController.clear();
//     categorySearchController.clear();

// filterCategories(categorySearchController.text);

//     if (mounted) {

//       setState(() {
//         categoryError = false;
//       });

//     }

//     Navigator.of(context).pop();

//     showMessage(
//       '$actualCategory added.',
//     );

//   }


//   void addCustomCategory() {
//     final String category =
//         customCategoryController.text.trim();

//     if (category.isEmpty) {
//       showMessage(
//         'Please enter a category.',
//       );
//       return;
//     }

//     final int existingIndex =
//         allCategories.indexWhere(
//       (item) =>
//           item.toLowerCase() ==
//           category.toLowerCase(),
//     );

//     String actualCategory;

//     if (existingIndex != -1) {

//       actualCategory =
//           allCategories[existingIndex];

//     } else {

//       customCategories.add(
//         category,
//       );
//       actualCategory = category;
//     }

//     if (!selectedCategories.contains(
//       actualCategory,
//     )) {

//       selectedCategories.add(
//         actualCategory,
//       );

//     }

//     customCategoryController.clear();
//     categorySearchController.clear();

// filterCategories(categorySearchController.text);

//     if (mounted) {

//       setState(() {

//         categoryError = false;

//       });

//     }

//     Navigator.of(context).pop();

//     showMessage(
//       '$actualCategory added.',
//     );

//   }