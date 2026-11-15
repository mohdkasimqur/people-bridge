import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jober_india/jober_indiaScreens.dart/Clinic/screen_clinic_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/CorierService/corrier_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/Doctors/screen_doctor_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/FishFruit%20Delivery/fish_delivery_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/Groceries/screen_grocery_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/IndividualSellers/individual_sellers_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/Laboratory/screen_laboratory_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/Recovery/screen_recovery_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/TaxiCommercial/screen_taxicomrcial_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/Tea_Shops/screen_tea_shop_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/broker/screen_broker_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/common_profile_services.dart';
import 'package:jober_india/jober_indiaScreens.dart/companies/company_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/foodDelivery/food_delivery_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/freelancers/freelancer_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/garage/screen_garage_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/medical%20shop/screen_mediclshp_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/otherBusiness/other_business_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/rentals/screen_rentals_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/selfEmployi/self_employee_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/spareparts/spare_parts_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/workers/screen_worker_login.dart';
import 'package:jober_india/screens/owner/screen_houseowner.dart';
import 'package:jober_india/screens/owner/screen_student.dart';

import 'Ambulance/ambulance_login.dart';

class CommonProfileScreen extends StatefulWidget {
  const CommonProfileScreen({super.key});

  @override
  State<CommonProfileScreen> createState() => _CommonProfileScreenState();
}
 
class ProfileField {
  final String key;
  final String label;
  final String value;
  final bool editable;
  final String type;

  ProfileField({
    required this.key,
    required this.label,
    required this.value,
    bool editable = true,
    this.type = 'text',
  }) : editable = _isPrivacyField(key) ? false : editable;

  static bool _isPrivacyField(String key) {
    final normalized = key
        .replaceAll('_', '')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .toLowerCase();

    return normalized.contains('privacypolicy') ||
        normalized.contains('privacyagreement') ||
        normalized.contains('termsandconditions') ||
        normalized.contains('termsconditions');
  }
}
class _CommonProfileScreenState extends State<CommonProfileScreen> {

  // ============================================================
  // HIVE
  // ============================================================

  late Box userBox;
  String profileExperience = '';

  // ============================================================
  // GENDER
  // ============================================================
  String currentRole = '';
  bool showGender = true;
String profileName = '';
String profileMobile = '';
String profileGender = '';
String profilePhotoUrl = '';

Map<String, dynamic> profileData = {};

String profileCollection = '';

List<ProfileField> roleFields = [];

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    userBox = Hive.box('userBox');

    _loadProfileData();
  }

  List<ProfileField> buildTimingFields({
    required bool hasTiming,
    required bool isOpen24Hours,
    required String openingTime,
    required String closingTime,
  }) {

if (!hasTiming){
  return [];
}

    if (isOpen24Hours) {
      return [
        ProfileField(
          key: 'timing',
          label: 'Timing',
          value: 'Open 24 Hours',
        ),
      ];
    }

    return [
      if (openingTime.trim().isNotEmpty)
        ProfileField(
          key: 'openingTime',
          label: 'Opening Time',
          value: openingTime.trim(),
        ),

      if (closingTime.trim().isNotEmpty)
        ProfileField(
          key: 'closingTime',
          label: 'Closing Time',
          value: closingTime.trim(),
        ),
    ];
  }

  bool _roleUsesGender(String role) {
  switch (role) {
    case 'doctor':
    case 'garage':
    case 'medicalShop':
    case 'worker':
    case 'freelancer':
    case 'taxi_commercial':
    case 'houseOwner':
    case 'student':
    case 'grocery':
      return true;

    default:
      return false;
  }
}

// ============================================================
// LOAD PROFILE DATA
// ============================================================

Future<void> _loadProfileData() async {
  try {
    final roleFromStorage =
        await CommonProfileService.getRole();

    final uid = CommonProfileService.getUid();

    if (roleFromStorage == null ||
        roleFromStorage.trim().isEmpty ||
        uid == null ||
        uid.trim().isEmpty) {
      return;
    }

    final roleInfo = _getRoleInfo(roleFromStorage);

    final normalizedRole = roleInfo['role']!;
    final collection = roleInfo['collection']!;

    final loadedData = await _loadRoleProfileFromFirestore(
      uid: uid,
      role: normalizedRole,
    );

    final localUserBox = userBox;

    final localName = localUserBox.get(
      'name',
      defaultValue: '',
    ).toString();

    final localMobile = localUserBox.get(
      'mobile',
      defaultValue: '',
    ).toString();

    if (!mounted) return;

    setState(() {
      currentRole = normalizedRole;

      profileCollection = collection;

      profileData = loadedData;

      showGender = _roleUsesGender(normalizedRole);

      // ======================================================
      // PROFILE NAME
      // ======================================================

      profileName = _firstNonEmpty(
        loadedData,
        [
          'name',
          'username',
          'ownerName',
          'doctorName',
          'clinicName',
          'laboratoryName',
          'businessName',
          'companyName',
          'shopName',
        ],
        fallback: localName,
      );

      // ======================================================
      // PROFILE MOBILE
      // ======================================================

      profileMobile = _firstNonEmpty(
        loadedData,
        [
          'mobile',
          'phone',
          'phoneNumber',
          'primaryMobile',
          'primaryMobileNumber',
          'mobileNumber',
          'primaryPhone',
          'doctorPhone',
          'ambulanceMobile',
        ],
        fallback: localMobile,
      );

      // ======================================================
      // PROFILE GENDER
      // ======================================================

      profileGender = _firstNonEmpty(
        loadedData,
        [
          'gender',
          'doctorGender',
        ],
        fallback: localUserBox.get(
          'gender',
          defaultValue: '',
        ).toString(),
      );

      // ======================================================
      // PROFILE PHOTO
      // ======================================================

      profilePhotoUrl = _firstNonEmpty(
        loadedData,
        [
          'profilePhotoUrl',
          'profilePhoto',
        ],
        fallback: localUserBox.get(
          'profilePhotoUrl',
          defaultValue: '',
        ).toString(),
      );

      // ======================================================
      // COMMON CONTROLLERS
      // ======================================================

      // nameController.text = profileName;

      // mobileController.text = _extractIndianMobile(
      //   profileMobile,
      // );

      // selectedGender = profileGender.isEmpty
      //     ? null
      //     : profileGender;

      // ======================================================
      // ROLE-SPECIFIC PROFILE FIELDS
      // ======================================================

      roleFields = _buildRoleFields(loadedData);
    });

    debugPrint(
      'Profile loaded successfully: '
      '$normalizedRole / $uid',
    );
  } catch (e, stackTrace) {
    debugPrint('Profile loading error: $e');
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not load profile: $e',
        ),
      ),
    );
  }
}


List<ProfileField> _buildRoleFields(
  Map<String, dynamic> data,
) {
  final fields = <ProfileField>[];

  void addField(
    String key,
    String label, {
    String? value,
    String type = 'text',
    bool editable = true,
  }) {
    fields.add(
      ProfileField(
        key: key,
        label: label,
        value: value ?? data[key]?.toString() ?? '',
        type: type,
        editable: editable,
      ),
    );
  }

  String getValue(
    List<String> keys, {
    String fallback = '',
  }) {
    return _firstNonEmpty(
      data,
      keys,
      fallback: fallback,
    );
  }

 
  String getNestedValue(
  String mapKey,
  List<String> possibleKeys,
) {
  final nested = data[mapKey];

  if (nested is String) {
    return nested.trim();
  }

  if (nested is! Map) {
    return '';
  }

  for (final key in possibleKeys) {
    final value = nested[key];

    if (value != null &&
        value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }

  return '';
}

  switch (currentRole) {
    // ========================================================
    // 1. AMBULANCE
    // ========================================================

    case 'ambulance':
      addField(
        'secondaryMobile',
        'Secondary Mobile Number',
        value: getValue([
          'secondaryMobile',
          'ambulanceSecondaryMobile',
        ]),
      );

      addField(
        'state',
        'State',
        value: getValue([
          'state',
          'ambulanceState',
        ]),
      );

      addField(
        'district',
        'District',
        value: getValue([
          'district',
          'ambulanceDistrict',
        ]),
      );

      addField(
        'nearestTown',
        'Nearest City / Town',
        value: getValue([
          'nearestTown',
          'nearestCity',
          'ambulanceNearestTown',
        ]),
      );

      addField(
        'vehicleName',
        'Vehicle Name',
      );

      addField(
        'vehicleNumber',
        'Vehicle Number',
      );

      addField(
        'placeName',
        'Ambulance Location',
        value: getValue(
          ['placeName'],
          fallback: getNestedValue(
            'location',
            ['placeName', 'address', 'name'],
          ),
        ),
      );

      break;

    // ========================================================
    // 2. BROKER
    // ========================================================

    case 'broker':
      addField(
        'secondaryMobile',
        'Secondary Mobile Number',
      );

      addField(
        'state',
        'State',
      );

      addField(
        'district',
        'District',
      );

      addField(
        'nearestTown',
        'Nearest City / Town',
        value: getValue([
          'nearestTown',
          'nearestCity',
        ]),
      );

      addField(
        'categories',
        'Categories',
        value: data['categories'] is List
            ? (data['categories'] as List).join(', ')
            : getValue(['categories']),
        type: 'multiline',
      );

      break;

    // ========================================================
    // 3. CLINIC
    // ========================================================

    case 'clinic':
      addField(
        'username',
        'Username',
        editable: false,
      );

      addField(
        'secondaryPhone',
        'Secondary Mobile Number',
        value: getValue([
          'secondaryPhone',
          'secondaryMobile',
        ]),
      );

      addField(
        'state',
        'State',
      );

      addField(
        'district',
        'District',
      );

      addField(
        'nearestTown',
        'Nearest City / Town',
        value: getValue([
          'nearestTown',
          'nearestCity',
        ]),
      );

      addField(
        'categories',
        'Clinic Categories',
        value: data['categories'] is List
            ? (data['categories'] as List).join(', ')
            : getValue(['categories']),
        type: 'multiline',
      );

     
      addField(
  '__clinicLocationAddress',
  'Clinic Location',
  value: getNestedValue(
    'locationAddress',
    [
      'address',
      'placeName',
      'name',
      'place',
      'formattedAddress',
      'locationName',
    ],
  ),
);

      if (data['isOpen24Hours'] == true) {
  addField(
    'timing',
    'Clinic Timing',
    value: 'Open 24 Hours',
    editable: false,
  );
} else {
  addField(
    '__openingTime',
    'Opening Time',
    value: getValue(['openingTime']),
  );

  addField(
    '__closingTime',
    'Closing Time',
    value: getValue(['closingTime']),
  );
}

      break;

    // ========================================================
    // WORKER
    // ========================================================

    case 'worker':
      addField(
        'secondaryMobile',
        'Secondary Mobile Number',
        value: getValue([
          'secondaryMobile',
          'secondaryPhone',
          'workerSecondaryMobile',
        ]),
      );

      addField(
        'state',
        'State',
        value: getValue([
          'state',
          'workerState',
        ]),
      );

      addField(
        'district',
        'District',
        value: getValue([
          'district',
          'workerDistrict',
        ]),
      );

      addField(
        'nearestTown',
        'Nearest City / Town',
        value: getValue([
          'nearestTown',
          'nearestCity',
          'workerNearestTown',
        ]),
      );

      addField(
        'categories',
        'Worker Categories',
        value: data['categories'] is List
            ? (data['categories'] as List).join(', ')
            : getValue([
                'categories',
                'workerCategories',
              ]),
        type: 'multiline',
      );

      addField(
        'experience',
        'Experience',
        value: getValue([
          'experience',
          'workerExperience',
        ]),
      );

      break;

    // ========================================================
    // 4. COMPANY
    // ========================================================

    case 'company':
      addField(
        'ownerName',
        'Owner Name',
        value: getValue([
          'ownerName',
          'name',
        ]),
      );

      addField(
        'companyName',
        'Company Name',
      );

      addField(
        'secondaryMobile',
        'Secondary Mobile Number',
      );

      addField(
        'state',
        'State',
      );

      addField(
        'district',
        'District',
      );

      addField(
        'nearestTown',
        'Nearest City / Town',
        value: getValue([
          'nearestTown',
          'nearestCity',
        ]),
      );

      addField(
        'categories',
        'Company Categories',
        value: data['categories'] is List
            ? (data['categories'] as List).join(', ')
            : getValue(['categories']),
        type: 'multiline',
      );

      addField(
        'category',
        'Main Category',
      );

      addField(
        'experience',
        'Experience',
      );

      addField(
        '__companyLocation',
        'Company Location',
        value: getNestedValue(
          'location',
          ['address', 'placeName', 'name'],
        ),
      );

      addField(
        '__openingTime',
        'Opening Time',
        value: getValue(['openingTime']),
      );

      addField(
        '__closingTime',
        'Closing Time',
        value: getValue(['closingTime']),
      );

      addField(
        '__isOpen24Hours',
        'Open 24 Hours',
        value: data['isOpen24Hours'] == true
            ? 'Yes'
            : 'No',
      );

      break;

    // ========================================================
    // 5. COURIER
    // ========================================================

    case 'courier':
      addField(
        'username',
        'Username',
        editable: false,
      );

      addField(
        'secondaryMobile',
        'Secondary Mobile Number',
      );

      addField(
        'state',
        'State',
        value: getValue([
          'state',
          'courierState',
        ]),
      );

      addField(
        'district',
        'District',
        value: getValue([
          'district',
          'courierDistrict',
        ]),
      );

      addField(
        'nearestTown',
        'Nearest City / Town',
        value: getValue([
          'nearestTown',
          'courierNearestTown',
        ]),
      );

      addField(
        'vehicleCategoryIds',
        'Vehicle Categories',
        value: data['vehicleCategoryIds'] is List
            ? (data['vehicleCategoryIds'] as List)
                .join(', ')
            : getValue(['vehicleCategoryIds']),
        type: 'multiline',
      );

      addField(
        'description',
        'Description',
        type: 'multiline',
      );

      addField(
        '__openingTime',
        'Opening Time',
        value: getValue(['openingTime']),
      );

      addField(
        '__closingTime',
        'Closing Time',
        value: getValue(['closingTime']),
      );

      addField(
        '__isOpen24Hours',
        'Open 24 Hours',
        value: data['isOpen24Hours'] == true
            ? 'Yes'
            : 'No',
      );

      break;

    // ========================================================
    // 6. DOCTOR
    // ========================================================

    case 'doctor':
      addField(
        'secondaryPhone',
        'Secondary Mobile Number',
        value: getValue([
          'secondaryPhone',
          'secondaryMobile',
        ]),
      );

      addField(
        'gender',
        'Gender',
        value: getValue([
          'gender',
          'doctorGender',
        ]),
      );

      addField(
        'experience',
        'Experience',
        value: getValue([
          'experience',
          'doctorExperienceYears',
        ]),
      );

      addField(
        'categories',
        'Medical Category',
        value: data['categories'] is List
            ? (data['categories'] as List).join(', ')
            : getValue([
                'categories',
                'doctorCategories',
              ]),
        type: 'multiline',
      );

      addField(
        'specializations',
        'Specializations',
        value: data['specializations'] is List
            ? (data['specializations'] as List).join(', ')
            : getValue([
                'specializations',
                'doctorSpecializations',
              ]),
        type: 'multiline',
      );

      addField(
        'state',
        'State',
      );

      addField(
        'district',
        'District',
      );

      addField(
        'nearestTown',
        'Nearest City / Town',
        value: getValue([
          'nearestTown',
          'nearestCity',
        ]),
      );

      addField(
        '__doctorLocationAddress',
        'Doctor Location',
        value: getNestedValue(
          'location',
          ['address', 'placeName', 'name'],
        ),
      );

      addField(
        '__consultationFrom',
        'Consultation From',
        value: getNestedValue(
          'consultationTime',
          ['from'],
        ),
      );

      addField(
        '__consultationTo',
        'Consultation To',
        value: getNestedValue(
          'consultationTime',
          ['to'],
        ),
      );

      addField(
        'workingDays',
        'Working Days',
        value: data['workingDays'] is List
            ? (data['workingDays'] as List).join(', ')
            : getValue(['workingDays']),
        type: 'multiline',
      );

      break;

    // ========================================================
// FISH DELIVERY
// ========================================================

case 'fish_delivery':
  addField(
    'secondaryMobileNumber',
    'Secondary Mobile Number',
    value: getValue([
      'secondaryMobileNumber',
      'secondaryMobile',
    ]),
  );

  addField('state', 'State');
  addField('district', 'District');

  addField(
    'nearestTown',
    'Nearest City / Town',
    value: getValue([
      'nearestTown',
      'nearestCity',
    ]),
  );

  addField(
    'categories',
    'Vehicle Categories',
    value: data['categories'] is List
        ? (data['categories'] as List).join(', ')
        : getValue(['categories']),
    type: 'multiline',
  );

  addField(
    'vehicleNumberDisplay',
    'Vehicle Number',
    value: getValue([
      'vehicleNumberDisplay',
      'vehicleNumber',
    ]),
  );

  addField(
    'vehicleNumberColor',
    'Vehicle Number Plate Colour',
  );

  break;


// ========================================================
// FOOD DELIVERY
// ========================================================

case 'food_delivery':
  addField(
    'secondaryMobileNumber',
    'Secondary Mobile Number',
    value: getValue([
      'secondaryMobileNumber',
      'secondaryMobile',
    ]),
  );

  addField('state', 'State');
  addField('district', 'District');

  addField(
    'nearestTown',
    'Nearest City / Town',
    value: getValue([
      'nearestTown',
      'nearestCity',
    ]),
  );

  addField(
    'categories',
    'Vehicle Categories',
    value: data['categories'] is List
        ? (data['categories'] as List).join(', ')
        : getValue(['categories']),
    type: 'multiline',
  );

  addField(
    'vehicleNumberDisplay',
    'Vehicle Number',
    value: getValue([
      'vehicleNumberDisplay',
      'vehicleNumber',
    ]),
  );

  addField(
    'vehicleNumberColor',
    'Vehicle Number Plate Colour',
  );

  break;


// ========================================================
// FREELANCER
// ========================================================

case 'freelancer':
  addField('state', 'State');
  addField('district', 'District');

  addField(
    'nearestTown',
    'Nearest City / Town',
    value: getValue([
      'nearestTown',
      'nearestCity',
    ]),
  );

  addField(
    'categories',
    'Categories',
    value: data['categories'] is List
        ? (data['categories'] as List).join(', ')
        : getValue(['categories']),
    type: 'multiline',
  );

  addField(
    'experience',
    'Experience',
  );

  break;


// ========================================================
// GARAGE
// ========================================================

case 'garage':
  addField(
    'ownerName',
    'Owner Name',
  );

  addField(
    'garageName',
    'Garage Name',
  );

  addField(
    'secondaryPhone',
    'Secondary Mobile Number',
    value: getValue([
      'secondaryPhone',
      'secondaryMobile',
    ]),
  );

  addField('state', 'State');
  addField('district', 'District');

  addField(
    'nearestTown',
    'Nearest City / Town',
    value: getValue([
      'nearestTown',
      'nearestCity',
    ]),
  );

  addField(
    'categories',
    'Garage Categories',
    value: data['categories'] is List
        ? (data['categories'] as List).join(', ')
        : getValue(['categories']),
    type: 'multiline',
  );

  addField(
    'description',
    'Description',
    type: 'multiline',
  );

  addField(
    '__openingTime',
    'Opening Time',
    value: getValue(['openingTime']),
  );

  addField(
    '__closingTime',
    'Closing Time',
    value: getValue(['closingTime']),
  );

  addField(
    '__isOpen24Hours',
    'Open 24 Hours',
    value: data['isOpen24Hours'] == true
        ? 'Yes'
        : 'No',
  );

  addField(
    '__garageLocation',
    'Garage Location',
    value: getNestedValue(
      'location',
      ['placeName', 'address', 'name'],
    ),
  );

  break;


// ========================================================
// GROCERY
// ========================================================

case 'grocery':
  addField(
    'shopName',
    'Shop Name',
  );

  addField(
    'secondaryMobile',
    'Secondary Mobile Number',
    value: getValue([
      'secondaryMobile',
      'secondaryMobileNumber',
    ]),
  );

  addField('state', 'State');
  addField('district', 'District');

  addField(
    'nearestTown',
    'Nearest City / Town',
    value: getValue([
      'nearestTown',
      'nearestCity',
    ]),
  );

  addField(
    'categories',
    'Categories',
    value: data['categories'] is List
        ? (data['categories'] as List).join(', ')
        : getValue(['categories']),
    type: 'multiline',
  );

  addField(
    'customCategories',
    'Custom Categories',
    value: data['customCategories'] is List
        ? (data['customCategories'] as List).join(', ')
        : getValue(['customCategories']),
    type: 'multiline',
  );

  addField(
    'homeDelivery',
    'Home Delivery',
    value: data['homeDelivery'] == true
        ? 'Yes'
        : 'No',
  );

  addField(
    'description',
    'Description',
    type: 'multiline',
  );

  addField(
    '__openingTime',
    'Opening Time',
    value: getValue(['openingTime']),
  );

  addField(
    '__closingTime',
    'Closing Time',
    value: getValue(['closingTime']),
  );

  addField(
    '__isOpen24Hours',
    'Open 24 Hours',
    value: data['isOpen24Hours'] == true
        ? 'Yes'
        : 'No',
  );

  addField(
    'locationName',
    'Shop Location',
  );

  break;


// ========================================================
// INDIVIDUAL SELLERS
// ========================================================

case 'individual_sellers':
  addField(
    'companyName',
    'Business Name',
  );

  addField(
    'secondaryMobile',
    'Secondary Mobile Number',
    value: getValue([
      'secondaryMobile',
      'secondaryMobileNumber',
    ]),
  );

  addField('state', 'State');
  addField('district', 'District');

  addField(
    'nearestTown',
    'Nearest City / Town',
    value: getValue([
      'nearestTown',
      'nearestCity',
    ]),
  );

  addField(
    'categories',
    'Categories',
    value: data['categories'] is List
        ? (data['categories'] as List).join(', ')
        : getValue(['categories']),
    type: 'multiline',
  );

  addField(
    'description',
    'Description',
    type: 'multiline',
  );

  addField(
    '__openingTime',
    'Opening Time',
    value: getValue(['openingTime']),
  );

  addField(
    '__closingTime',
    'Closing Time',
    value: getValue(['closingTime']),
  );

  addField(
    '__isOpen24Hours',
    'Open 24 Hours',
    value: data['isOpen24Hours'] == true
        ? 'Yes'
        : 'No',
  );

  break;


// ========================================================
// LABORATORY
// ========================================================

case 'laboratory':
  addField(
    'laboratoryName',
    'Laboratory Name',
  );

  addField(
    'secondaryMobile',
    'Secondary Mobile Number',
    value: getValue([
      'secondaryMobile',
      'secondaryPhone',
    ]),
  );

  addField('state', 'State');
  addField('district', 'District');

  addField(
    'nearestTown',
    'Nearest City / Town',
    value: getValue([
      'nearestTown',
      'nearestCity',
    ]),
  );

  addField(
    'categories',
    'Laboratory Categories',
    value: data['categories'] is List
        ? (data['categories'] as List).join(', ')
        : getValue(['categories']),
    type: 'multiline',
  );

  addField(
    'locationAddress',
    'Laboratory Location',
  );

  addField(
    '__openingTime',
    'Opening Time',
    value: getValue(['openingTime']),
  );

  addField(
    '__closingTime',
    'Closing Time',
    value: getValue(['closingTime']),
  );

  addField(
    '__isOpen24Hours',
    'Open 24 Hours',
    value: data['isOpen24Hours'] == true
        ? 'Yes'
        : 'No',
  );

  break;


// ========================================================
// MEDICAL SHOP
// ========================================================

case 'medicalShop':
  addField(
    'shopName',
    'Shop Name',
  );

  addField(
    'secondaryPhone',
    'Secondary Mobile Number',
    value: getValue([
      'secondaryPhone',
      'secondaryMobile',
    ]),
  );

  addField('state', 'State');
  addField('district', 'District');

  addField(
    'nearestTown',
    'Nearest City / Town',
    value: getValue([
      'nearestTown',
      'nearestCity',
    ]),
  );

  addField(
    'categories',
    'Medical Shop Categories',
    value: data['categories'] is List
        ? (data['categories'] as List).join(', ')
        : getValue(['categories']),
    type: 'multiline',
  );

  addField(
    'gender',
    'Gender',
  );

  addField(
    '__openingTime',
    'Opening Time',
    value: getValue([
      'openingTime',
      'medicalShop_openingTime',
    ]),
  );

  addField(
    '__closingTime',
    'Closing Time',
    value: getValue([
      'closingTime',
      'medicalShop_closingTime',
    ]),
  );

  addField(
    '__isOpen24Hours',
    'Open 24 Hours',
    value: data['isOpen24Hours'] == true ||
            data['medicalShop_isOpen24Hours'] == true
        ? 'Yes'
        : 'No',
  );

  addField(
    '__medicalShopLocation',
    'Medical Shop Location',
    value: getNestedValue(
      'currentLocation',
      ['placeName', 'address', 'name'],
    ),
  );

  break;

case 'taxi_commercial':

  addField(
    'secondaryMobile',
    'Secondary Mobile Number',
  );

  addField('state', 'State');

  addField('district', 'District');

  addField(
    'nearestTown',
    'Nearest City / Town',
  );

  addField(
    'vehicleType',
    'Vehicle Type',
  );

  addField(
    'vehicle',
    'Vehicle Category',
  );

  addField(
    'vehicleName',
    'Vehicle Name',
  );

  addField(
    'vehicleNumber',
    'Vehicle Number',
  );

  break;

  // ========================================================
// AUTO SPARE PARTS
// ========================================================

case 'autoSpareParts':
case 'auto_spare_parts':

  addField(
    'secondaryMobile',
    'Secondary Mobile Number',
    value: getValue([
      'secondaryMobile',
      'autoSparePartsSecondaryMobile',
    ]),
  );

  addField(
    'state',
    'State',
    value: getValue([
      'state',
      'autoSparePartsState',
    ]),
  );

  addField(
    'district',
    'District',
    value: getValue([
      'district',
      'autoSparePartsDistrict',
    ]),
  );

  addField(
    'nearestTown',
    'Nearest City / Town',
    value: getValue([
      'nearestTown',
      'autoSparePartsNearestTown',
    ]),
  );

  addField(
    'shopName',
    'Shop Name',
    value: getValue([
      'shopName',
      'autoSparePartsShopName',
    ]),
  );

  addField(
    'categories',
    'Spare Parts Categories',
    value: data['categories'] is List
        ? (data['categories'] as List).join(', ')
        : getValue([
            'categories',
            'autoSparePartsCategories',
            'category',
            'autoSparePartsCategory',
          ]),
    type: 'multiline',
  );

  addField(
    'customCategories',
    'Custom Categories',
    value: data['customCategories'] is List
        ? (data['customCategories'] as List).join(', ')
        : '',
    type: 'multiline',
  );

  if (data['isOpen24Hours'] == true) {
    addField(
      'timing',
      'Shop Timing',
      value: 'Open 24 Hours',
      editable: false,
    );
  } else {
    addField(
      '__openingTime',
      'Opening Time',
      value: getValue([
        'openingTime',
        'autoSparePartsOpeningTime',
      ]),
    );

    addField(
      '__closingTime',
      'Closing Time',
      value: getValue([
        'closingTime',
        'autoSparePartsClosingTime',
      ]),
    );
  }

  break;

// ========================================================
// OTHER BUSINESS
// ========================================================

case 'other_business':
  addField(
    'businessName',
    'Business Name',
    value: getValue([
      'businessName',
      'otherBusinessName',
      'name',
    ]),
  );

  addField(
    'secondaryMobile',
    'Secondary Mobile Number',
    value: getValue([
      'secondaryMobile',
      'secondaryMobileNumber',
    ]),
  );

  addField('state', 'State');
  addField('district', 'District');

  addField(
    'nearestTown',
    'Nearest City / Town',
    value: getValue([
      'nearestTown',
      'nearestCity',
    ]),
  );

  addField(
    'categories',
    'Categories',
    value: data['categories'] is List
        ? (data['categories'] as List).join(', ')
        : getValue(['categories']),
    type: 'multiline',
  );

  addField(
    'description',
    'Description',
    type: 'multiline',
  );

  addField(
    '__openingTime',
    'Opening Time',
    value: getValue(['openingTime']),
  );

  addField(
    '__closingTime',
    'Closing Time',
    value: getValue(['closingTime']),
  );

  addField(
    '__isOpen24Hours',
    'Open 24 Hours',
    value: data['isOpen24Hours'] == true
        ? 'Yes'
        : 'No',
  );

  break;



    default:
      break;
  }

  return fields;
}

String _firstNonEmpty(
  Map<String, dynamic> data,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = data[key];

    if (value != null &&
        value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }

  return fallback;
}

  // ============================================================
  // BUILD
  // ============================================================

IconData _getProfileFieldIcon(String key) {
  switch (key) {
    // Personal details
    case 'name':
    case 'ownerName':
    case 'doctorName':
    case 'clinicName':
    case 'companyName':
    case 'username':
      return Icons.person_outline;

    case 'mobile':
    case 'phone':
    case 'primaryMobile':
    case 'secondaryMobile':
    case 'secondaryPhone':
      return Icons.phone_outlined;

    case 'gender':
    case 'doctorGender':
      return Icons.wc_outlined;

    // Location
    case 'state':
    case 'district':
    case 'nearestTown':
    case 'nearestCity':
    case 'placeName':
    case '__clinicLocationAddress':
    case '__companyLocation':
    case '__doctorLocationAddress':
    case 'location':
      return Icons.location_on_outlined;

    // Vehicle details
    case 'vehicleType':
    case 'vehicle':
    case 'vehicleName':
      return Icons.directions_car_outlined;

    case 'vehicleNumber':
      return Icons.confirmation_number_outlined;

    case 'vehicleCategoryIds':
      return Icons.local_shipping_outlined;

    // Work and business
    case 'role':
      return Icons.badge_outlined;

case 'customCategories':
  return Icons.category_outlined;

    case 'categories':
    case 'category':
    case 'specializations':
      return Icons.category_outlined;

    case 'experience':
    case 'doctorExperienceYears':
    case 'companyExperience':
      return Icons.work_outline;

    case 'description':
      return Icons.description_outlined;

    // Timing
    case 'openingTime':
    case 'closingTime':
    case '__openingTime':
    case '__closingTime':
    case '__consultationFrom':
    case '__consultationTo':
    case 'timing':
      return Icons.access_time_outlined;

    case 'workingDays':
      return Icons.calendar_month_outlined;

    case '__isOpen24Hours':
      return Icons.schedule_outlined;

    // Other existing fields
    case 'garageName':
      return Icons.garage_outlined;

    case 'shopName':
      return Icons.store_outlined;

    case 'laboratoryName':
      return Icons.biotech_outlined;

    case 'homeDelivery':
      return Icons.delivery_dining_outlined;

    case 'shopAge':
      return Icons.storefront_outlined;

    default:
      return Icons.label_outline;
  }
}

Future<void> _openRegistrationScreen() async {
  final role = await CommonProfileService.getRole();

  if (!mounted) return;

  Widget? page;

  switch (role) {
    case 'doctor':
    case 'doctors':
      page = ScreenDoctorLogin();
      break;

    case 'ambulance':
      page = AmbulanceLogin();
      break;

    case 'clinic':
      page = ScreenClinicLogin();
      break;

    case 'medicalShop':
    case 'medical_shop':
      page = ScreenMedicalShpLogin();
      break;

    case 'laboratory':
    case 'lab':
      page = ScreenLabLogin();
      break;

    case 'student':
      page = ScreenStudent();
      break;

    case 'houseOwner':
    case 'house_owner':
      page = ScreenHouseOwner();
      break;

    case 'company':
      page = CompanyLoginPage();
      break;

    case 'worker':
      page = ScreenWorker();
      break;

    case 'freelancer':
      page = ScreenFreelancerLogin();
      break;

    case 'self_employee':
    case 'selfEmployee':
      page = ScreenSelfEmployeesLogin();
      break;

    case 'courier':
      page = ScreenCourierLogin();
      break;

    case 'tea_shop':
    case 'teaShop':
    case 'tea_shops':
      page = ScreenTeaShopLogin();
      break;

    case 'food_delivery':
      page = ScreenFoodDeliveryLogin();
      break;

    case 'fish_delivery':
      page = ScreenFishDeliveryLogin();
      break;

    case 'taxi_commercial':
    case 'taxiCommercial':
      page = ScreenTaxicomrcialLogin();
      break;

    case 'garage':
      page = ScreenGarageLogin();
      break;

    case 'recovery':
      page = ScreenRecoveryLogin();
      break;

    case 'auto_spare_parts':
    case 'autoSpareParts':
      page = AutoSparePartsLoginPage();
      break;

    case 'broker':
      page = ScreenBrokerLogin();
      break;

    case 'rental':
      page = RentalLoginScreen();
      break;

    case 'individual_sellers':
    case 'individualSellers':
      page = ScreenSelfBusinessLogin();
      break;

    case 'grocery':
      page = ScreenGroceryLogin();
      break;

    case 'other_business':
    case 'otherBusiness':
      page = ScreenOtherBusinessLogin();
      break;

    default:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile page not found.'),
        ),
      );
      return;
  }

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => page!,
    ),
  );

  if (!mounted) return;

  await _loadProfileData();
}
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable:
          userBox.listenable(),

      builder: (
        BuildContext context,
        Box box,
        Widget? child,
      ) {

        final String name =
            box.get(
          'name',
          defaultValue: 'User',
        );

        final String mobile =
            box.get(
          'mobile',
          defaultValue: 'Not available',
        );

        final String role =
            box.get(
          'role',
          defaultValue: 'houseOwner',
        );

        return Scaffold(
          backgroundColor:
              const Color(0xFFF7F8F7),

appBar: AppBar(
  title: const Text('Profile'),
  backgroundColor: const Color(0xFF138808),
  foregroundColor: Colors.white,
  centerTitle: true,
  actions: [
    IconButton(
      onPressed: _openRegistrationScreen,
      icon: const Icon(Icons.edit),
    ),
  ],
),

          body: SingleChildScrollView(
            padding:
                const EdgeInsets.all(20),

            child: Column(
              children: [

                const SizedBox(height: 15),

CircleAvatar(
  radius: 55,
  backgroundColor: const Color(0xFFE8F5E9),
  child: ClipOval(
    child: profilePhotoUrl.trim().isNotEmpty
        ? Image.network(
            profilePhotoUrl.trim(),
            width: 110,
            height: 110,
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              debugPrint(
                'PROFILE PHOTO ERROR: $error',
              );
              debugPrint(
                'PROFILE PHOTO URL: $profilePhotoUrl',
              );

              return const Icon(
                Icons.person,
                size: 50,
                color: Color(0xFF138808),
              );
            },
          )
        : const Icon(
            Icons.person,
            size: 50,
            color: Color(0xFF138808),
          ),
  ),
),

                const SizedBox(height: 18),

                // ================================================
                // VIEW MODE
                // ================================================

                //if (!isEditing) 
                ...[

                  // NAME

                  Text(
                    name,

                    textAlign:
                        TextAlign.center,

                    style:
                        const TextStyle(
                      fontSize: 27,

                      fontWeight:
                          FontWeight.bold,

                      color:
                          Color(0xFF202124),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ROLE

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(0xFFE8F5E9),

                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),

                    child: Text(
                      _getRoleInfo(role)['displayName']!,

                      style:
                          const TextStyle(
                        fontSize: 15,

                        fontWeight:
                            FontWeight.bold,

                        color:
                            Color(0xFF138808),
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

// the name is already displayed at the top.

if (currentRole != 'clinic' &&
    role != 'clinic') ...[
  _profileItem(
    icon: Icons.person_outline,
    title: 'Full Name',
    value: name,
  ),

  const SizedBox(height: 15),
],

                  // MOBILE

                  _profileItem(
                    icon:
                        Icons.phone_outlined,

                    title:
                        'Mobile Number',

                    value:
                        mobile,
                  ),

                  const SizedBox(height: 15),

if (showGender &&
    profileGender.trim().isNotEmpty) ...[
  _profileItem(
    icon: Icons.wc_outlined,
    title: 'Gender',
    value: profileGender,
  ),
  const SizedBox(height: 15),
],

                  const SizedBox(height: 15),

                 // ROLE

                  _profileItem(
                    icon: Icons.badge_outlined,
                    title: 'Role',
                    value: _getRoleInfo(
                      currentRole.isNotEmpty
                          ? currentRole
                          : role,
                    )['displayName']!
                  ),

                  const SizedBox(height: 25),

                  // ============================================
                  // ROLE-SPECIFIC DETAILS IN VIEW MODE
                  // ============================================

                  if (roleFields.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
  '${_getRoleInfo(
    currentRole.isNotEmpty ? currentRole : role,
  )['displayName']!} Details',
  style: const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Color(0xFF202124),
  ),
),
                    ),

                    const SizedBox(height: 15),

                    ...roleFields
                        .where(
                          (field) =>
                              field.value.trim().isNotEmpty,
                        )
                        .map(
                          (field) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: 15,
                            ),
                            child: _profileItem(
                              icon: _getProfileFieldIcon(
                                field.key,
                              ),
                              title: field.label,
                              value: field.value,
                            ),
                          ),
                        ),

                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 15),

                  SizedBox(
  width: double.infinity,
  height: 56,
  child: ElevatedButton.icon(
    onPressed: _openRegistrationScreen,
    icon: const Icon(Icons.edit),
    label: const Text(
      'Edit Profile',
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF138808),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PROFILE INFORMATION ITEM
  // ============================================================

  Widget _profileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 
              0.05,
            ),

            blurRadius: 10,

            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child: Row(
        children: [

          Container(
            height: 50,
            width: 50,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFFFECEC,
              ),

              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),

            child: Icon(
              icon,

              color:
                  Colors.red,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  title,

                  style:
                      const TextStyle(
                    fontSize: 13,

                    color:
                        Colors.grey,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,

                  style:
                      const TextStyle(
                    fontSize: 17,

                    fontWeight:
                        FontWeight.w600,

                    color:
                        Color(
                      0xFF202124,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ============================================================
// LOAD ROLE PROFILE FROM HIVE + FIRESTORE
// ============================================================

Future<Map<String, dynamic>> _loadRoleProfileFromFirestore({
  required String uid,
  required String role,
}) async {
  final roleInfo = _getRoleInfo(role);

  final String normalizedRole = roleInfo['role']!;
  final String collection = roleInfo['collection']!;

  final Map<String, dynamic> localData = {};

  // ==========================================================
  // HELPER: READ HIVE BOX
  // ==========================================================

  Future<Box> getBox(String boxName) async {
    return Hive.isBoxOpen(boxName)
        ? Hive.box(boxName)
        : await Hive.openBox(boxName);
  }

  // ==========================================================
  // HELPER: COPY MAP
  // ==========================================================

  void copyMap(dynamic saved) {
    if (saved is Map) {
      localData.addAll(
        Map<String, dynamic>.from(saved),
      );
    }
  }

  // ==========================================================
  // COURIER
  // ==========================================================

  if (normalizedRole == 'courier') {
    final box = await getBox('settings');

    final keyMapping = <String, List<String>>{
      'uid': ['courierUid'],
      'username': ['courierUsername', 'username'],
      'primaryMobile': [
        'courierPrimaryMobile',
        'primaryMobile',
        'mobile',
      ],
      'secondaryMobile': [
        'courierSecondaryMobile',
        'secondaryMobile',
      ],
      'state': ['courierState', 'state'],
      'district': ['courierDistrict', 'district'],
      'nearestTown': [
        'courierNearestTown',
        'nearestTown',
        'nearestCity',
      ],
      'vehicleCategoryIds': [
        'courierVehicleCategoryIds',
        'vehicleCategoryIds',
      ],
      'openingTime': [
        'courierOpeningTime',
        'openingTime',
      ],
      'closingTime': [
        'courierClosingTime',
        'closingTime',
      ],
      'description': [
        'courierDescription',
        'description',
      ],
      'profilePhotoUrl': [
        'courierProfilePhotoUrl',
        'profilePhotoUrl',
      ],
      'role': ['courierRole', 'role'],
    };

    for (final entry in keyMapping.entries) {
      for (final key in entry.value) {
        final value = box.get(key);

        if (value != null &&
            value.toString().trim().isNotEmpty) {
          localData[entry.key] = value;
          break;
        }
      }
    }

    final open24 = box.get('isOpen24Hours') ??
        box.get('courierIsOpen24Hours');

    if (open24 != null) {
      localData['isOpen24Hours'] = open24;
    }
  }

  // ==========================================================
  // CLINIC
  // ==========================================================

  if (normalizedRole == 'clinic') {
    final box = userBox;

    localData.addAll({
      'uid': box.get('uid', defaultValue: uid),
      'username': box.get('username', defaultValue: ''),
      'clinicName': box.get('clinicName', defaultValue: ''),
      'name': box.get('clinicName', defaultValue: ''),
      'phone': box.get('mobile', defaultValue: ''),
      'secondaryPhone':
          box.get('secondaryMobile', defaultValue: ''),
      'state': box.get('ambulanceState', defaultValue: ''),
      'district':
          box.get('ambulanceDistrict', defaultValue: ''),
      'nearestTown':
          box.get('ambulanceNearestTown', defaultValue: ''),
      'categories':
          box.get('categories', defaultValue: <String>[]),
      'openingTime':
          box.get('openingTime', defaultValue: ''),
      'closingTime':
          box.get('closingTime', defaultValue: ''),
      'isOpen24Hours':
          box.get('isOpen24Hours', defaultValue: false),
      'locationAddress': box.get('garageLocation'),
    });
  }

  // ==========================================================
  // FISH DELIVERY
  // ==========================================================

  if (normalizedRole == 'fish_delivery') {
    final box = await getBox('fishDeliveryProfiles');

    copyMap(box.get('currentProfile'));
  }

  // ==========================================================
  // FOOD DELIVERY
  // ==========================================================

  if (normalizedRole == 'food_delivery') {
    final box = await getBox('foodDeliveryProfiles');

    copyMap(box.get('currentProfile'));
  }

  // ==========================================================
  // FREELANCER
  // ==========================================================

  if (normalizedRole == 'freelancer') {
    for (final key in [
      'uid',
      'name',
      'mobile',
      'secondaryMobile',
      'state',
      'district',
      'nearestTown',
      'role',
      'categories',
      'experience',
      'latitude',
      'longitude',
      'profilePhotoUrl',
    ]) {
      final value = userBox.get(key);

      if (value != null) {
        localData[key] = value;
      }
    }
  }

  // ==========================================================
  // GARAGE
  // ==========================================================

  if (normalizedRole == 'garage') {
    final box = await getBox('garageProfiles');

    copyMap(box.get(uid));
  }

  // ==========================================================
  // GROCERY
  // ==========================================================

  if (normalizedRole == 'grocery') {
    final box = await getBox('grocery');

    for (final key in [
      'uid',
      'name',
      'shopName',
      'mobile',
      'secondaryMobile',
      'state',
      'district',
      'nearestTown',
      'role',
      'categories',
      'customCategories',
      'homeDelivery',
      'isOpen24Hours',
      'openingTime',
      'closingTime',
      'description',
      'locationName',
      'latitude',
      'longitude',
      'profilePhotoUrl',
    ]) {
      final value = box.get(key);

      if (value != null) {
        localData[key] = value;
      }
    }
  }

  // ==========================================================
  // INDIVIDUAL SELLERS
  // ==========================================================

  if (normalizedRole == 'individual_sellers') {
    final box = await getBox('selfBusinessProfiles');

    copyMap(box.get(uid));
  }

  // ==========================================================
  // LABORATORY
  // ==========================================================

  if (normalizedRole == 'laboratory') {
    final box = await getBox('labProfiles');

    copyMap(box.get('profile'));
  }

  // ==========================================================
  // MEDICAL SHOP
  // ==========================================================

  if (normalizedRole == 'medicalShop' ||
      normalizedRole == 'medical_shop') {
    final box = await getBox('settings');

    final keyMapping = <String, String>{
      'name': 'medicalShop_name',
      'phone': 'medicalShop_phone',
      'secondaryPhone': 'medicalShop_secondaryPhone',
      'state': 'medicalShop_state',
      'district': 'medicalShop_district',
      'nearestTown': 'medicalShop_nearestTown',
      'shopName': 'medicalShop_shopName',
      'categories': 'medicalShop_categories',
      'isOpen24Hours': 'medicalShop_isOpen24Hours',
      'openingTime': 'medicalShop_openingTime',
      'closingTime': 'medicalShop_closingTime',
      'gender': 'medicalShop_gender',
      'currentLocation': 'medicalShop_currentLocation',
      'profilePhotoUrl': 'medicalShop_profilePhotoUrl',
    };

    for (final entry in keyMapping.entries) {
      final value = box.get(entry.value);

      if (value != null) {
        localData[entry.key] = value;
      }
    }
  }

  // ==========================================================
  // OTHER BUSINESS
  // ==========================================================

  if (normalizedRole == 'other_business') {
    final box = await getBox('settings');

    final keyMapping = <String, String>{
      'uid': 'otherBusinessUid',
      'username': 'otherBusinessUsername',
      'name': 'otherBusinessName',
      'mobile': 'otherBusinessMobile',
      'secondaryMobile': 'otherBusinessSecondaryMobile',
      'state': 'otherBusinessState',
      'district': 'otherBusinessDistrict',
      'nearestTown': 'otherBusinessNearestTown',
      'categories': 'otherBusinessCategories',
      'categoryKeys': 'otherBusinessCategoryKeys',
      'description': 'otherBusinessDescription',
      'openingTime': 'otherBusinessOpeningTime',
      'closingTime': 'otherBusinessClosingTime',
      'isOpen24Hours': 'otherBusinessIsOpen24Hours',
      'profilePhotoUrl': 'otherBusinessProfilePhoto',
      'hasLocation': 'otherBusinessHasLocation',
      'location': 'otherBusinessLocation',
    };

    for (final entry in keyMapping.entries) {
      final value = box.get(entry.value);

      if (value != null) {
        localData[entry.key] = value;
      }
    }
  }

  // ==========================================================
  // 1. RECOVERY → SETTINGS / recoveryProfile
  // ==========================================================

  if (normalizedRole == 'recovery') {
    final box = await getBox('settings');

    copyMap(box.get('recoveryProfile'));

    localData['uid'] ??= box.get('recoveryUid');
    localData['role'] ??= box.get('recoveryProfile') is Map
        ? box.get('recoveryProfile')['role']
        : 'recovery';

    // Recovery registration uses "phone".
    localData['phone'] ??= userBox.get('mobile');
    localData['profilePhotoUrl'] ??=
        userBox.get('profilePhotoUrl');
  }

  // ==========================================================
  // 2. RENTAL → rentalProfiles
  // ==========================================================

  if (normalizedRole == 'rental') {
    final box = await getBox('rentalProfiles');

    copyMap(box.get(uid));

    // Support existing userBox common-profile data.
    localData['uid'] ??= uid;
    localData['name'] ??= userBox.get('name');
    localData['mobile'] ??= userBox.get('mobile');
    localData['profilePhotoUrl'] ??=
        userBox.get('profilePhotoUrl');

    final settings = await getBox('appSettings');

    localData['role'] ??= settings.get('userRole');
  }

  // ==========================================================
  // 3. SELF EMPLOYEE → USER BOX
  // ==========================================================

  if (normalizedRole == 'self_employee') {
    for (final key in [
      'uid',
      'name',
      'mobile',
      'secondaryMobile',
      'state',
      'district',
      'nearestTown',
      'categories',
      'category',
      'experience',
      'latitude',
      'longitude',
      'profilePhotoUrl',
      'role',
    ]) {
      final value = userBox.get(key);

      if (value != null) {
        localData[key] = value;
      }
    }

    localData['uid'] ??= uid;
    localData['role'] ??= 'self_employee';
  }

  // ==========================================================
  // 4. AUTO SPARE PARTS → SETTINGS
  // ==========================================================

  if (normalizedRole == 'auto_spare_parts' ||
      normalizedRole == 'autoSpareParts') {
    final box = await getBox('settings');

    final keyMapping = <String, String>{
      'uid': 'autoSparePartsUid',
      'name': 'autoSparePartsName',
      'mobile': 'autoSparePartsMobile',
      'secondaryMobile': 'autoSparePartsSecondaryMobile',
      'state': 'autoSparePartsState',
      'district': 'autoSparePartsDistrict',
      'nearestTown': 'autoSparePartsNearestTown',
      'shopName': 'autoSparePartsShopName',
      'categories': 'autoSparePartsCategories',
      'category': 'autoSparePartsCategory',
      'openingTime': 'autoSparePartsOpeningTime',
      'closingTime': 'autoSparePartsClosingTime',
      'isOpen24Hours': 'autoSparePartsIsOpen24Hours',
      'latitude': 'autoSparePartsLatitude',
      'longitude': 'autoSparePartsLongitude',
      'role': 'autoSparePartsRole',
    };

    for (final entry in keyMapping.entries) {
      final value = box.get(entry.value);

      if (value != null) {
        localData[entry.key] = value;
      }
    }

    localData['profilePhotoUrl'] ??=
        userBox.get('profilePhotoUrl');
  }

  // ==========================================================
  // 5. TAXI / COMMERCIAL → USER BOX
  // ==========================================================

  if (normalizedRole == 'taxi_commercial') {
    final keyMapping = <String, String>{
      'uid': 'uid',
      'name': 'name',
      'mobile': 'mobile',
      'secondaryMobile': 'secondaryMobile',
      'state': 'taxiCommercialState',
      'district': 'taxiCommercialDistrict',
      'nearestTown': 'taxiCommercialNearestTown',
      'vehicleType': 'vehicleType',
      'vehicle': 'vehicle',
      'vehicleName': 'vehicleName',
      'vehicleNumber': 'vehicleNumber',
      'profilePhotoUrl': 'profilePhotoUrl',
      'gender': 'gender',
      'role': 'role',
    };

    for (final entry in keyMapping.entries) {
      final value = userBox.get(entry.value);

      if (value != null) {
        localData[entry.key] = value;
      }
    }

    localData['uid'] ??= uid;
  }

  // ==========================================================
  // 6. TEA SHOP → SETTINGS
  // ==========================================================

  if (normalizedRole == 'tea_shop') {
    final box = await getBox('settings');

    final keyMapping = <String, String>{
      'uid': 'teaShopUid',
      'username': 'teaShopUsername',
      'shopName': 'teaShopName',
      'mobile': 'teaShopMobile',
      'secondaryMobile': 'teaShopSecondaryMobile',
      'state': 'ambulanceState',
      'district': 'ambulanceDistrict',
      'nearestTown': 'ambulanceNearestTown',
      'category': 'teaShopCategory',
      'openingTime': 'teaShopOpeningTime',
      'closingTime': 'teaShopClosingTime',
      'isOpen24Hours': 'teaShopIsOpen24Hours',
      'description': 'teaShopDescription',
      'role': 'teaShopRole',
      'latitude': 'teaShopLatitude',
      'longitude': 'teaShopLongitude',
    };

    for (final entry in keyMapping.entries) {
      final value = box.get(entry.value);

      if (value != null) {
        localData[entry.key] = value;
      }
    }

    localData['profilePhotoUrl'] ??=
        userBox.get('profilePhotoUrl');
  }

  // ==========================================================
  // 7. WORKER → workerProfiles
  // ==========================================================

  if (normalizedRole == 'worker') {
    final box = await getBox('workerProfiles');

    copyMap(box.get(uid));

    localData['uid'] ??= uid;
    localData['name'] ??= userBox.get('name');
    localData['phone'] ??= userBox.get('mobile');
    localData['gender'] ??= userBox.get('gender');
    localData['categories'] ??= userBox.get('categories');
    localData['experience'] ??= userBox.get('experience');

    localData['state'] ??= userBox.get('workerState');
    localData['district'] ??= userBox.get('workerDistrict');
    localData['nearestTown'] ??=
        userBox.get('workerNearestTown');

    localData['role'] ??= 'worker';
  }

  // ==========================================================
  // SECOND: TRY FIRESTORE
  // ==========================================================

  if (collection.isNotEmpty) {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .doc(uid)
          .get();

      if (snapshot.exists) {
        final firestoreData = Map<String, dynamic>.from(
          snapshot.data() ?? <String, dynamic>{},
        );

        // Firestore values override local values.
        return {
          ...localData,
          ...firestoreData,
        };
      }

      debugPrint(
        'Profile document does not exist: '
        '$collection/$uid',
      );
    } catch (e) {
      debugPrint(
        'Could not load $normalizedRole from Firestore: $e',
      );
    }
  }

  // ==========================================================
  // THIRD: RETURN LOCAL DATA
  // ==========================================================

  return localData;
}

Map<String, String> _getRoleInfo(String role) {
  switch (role.trim()) {
    case 'ambulance':
      return {
        'role': 'ambulance',
        'displayName': 'Ambulance',
        'collection': 'ambulances',
      };

    case 'broker':
      return {
        'role': 'broker',
        'displayName': 'Broker',
        'collection': 'brokers',
      };

    case 'clinic':
      return {
        'role': 'clinic',
        'displayName': 'Clinic Owner',
        'collection': 'clinics',
      };

    case 'company':
      return {
        'role': 'company',
        'displayName': 'Company',
        'collection': 'companies',
      };

    case 'courier':
      return {
        'role': 'courier',
        'displayName': 'Courier Service',
        'collection': 'couriers',
      };

    case 'doctor':
    case 'doctors':
      return {
        'role': 'doctor',
        'displayName': 'Doctor',
        'collection': 'doctors',
      };

    case 'laboratory':
    case 'lab':
      return {
        'role': 'laboratory',
        'displayName': 'Laboratory',
        'collection': 'labs',
      };

    case 'medicalShop':
    case 'medical_shop':
      return {
        'role': 'medicalShop',
        'displayName': 'Medical Shop',
        'collection': 'medicalShops',
      };

    case 'houseOwner':
    case 'house_owner':
      return {
        'role': 'houseOwner',
        'displayName': 'House Owner',
        'collection': 'houseOwners',
      };

    case 'student':
      return {
        'role': 'student',
        'displayName': 'Student',
        'collection': 'students',
      };

    case 'worker':
      return {
        'role': 'worker',
        'displayName': 'Worker',
        'collection': 'workers',
      };

    case 'freelancer':
      return {
        'role': 'freelancer',
        'displayName': 'Freelancer',
        'collection': 'freelancers',
      };

    case 'fish_delivery':
      return {
        'role': 'fish_delivery',
        'displayName': 'Fish Delivery',
        'collection': 'fishDeliveryGuys',
      };

    case 'food_delivery':
      return {
        'role': 'food_delivery',
        'displayName': 'Food Delivery',
        'collection': 'foodDeliveryGuys',
      };

    case 'self_employee':
    case 'selfEmployee':
      return {
        'role': 'self_employee',
        'displayName': 'Self Employee',
        'collection': 'selfEmployees',
      };

    case 'individual_sellers':
    case 'individualSellers':
      return {
        'role': 'individual_sellers',
        'displayName': 'Individual Sellers',
        'collection': 'selfBusinesses',
      };

    case 'taxi_commercial':
    case 'taxiCommercial':
      return {
        'role': 'taxi_commercial',
        'displayName': 'Taxi / Commercial',
        'collection': 'taxi_commercial',
      };

    case 'rental':
      return {
        'role': 'rental',
        'displayName': 'Rental',
        'collection': 'rentals',
      };

    case 'grocery':
      return {
        'role': 'grocery',
        'displayName': 'Grocery',
        'collection': 'groceryShops',
      };

    case 'tea_shop':
    case 'tea_shops':
    case 'teaShop':
      return {
        'role': 'tea_shop',
        'displayName': 'Tea Shop',
        'collection': 'tea_shops',
      };

    case 'garage':
      return {
        'role': 'garage',
        'displayName': 'Garage',
        'collection': 'garageOwners',
      };

    case 'autoSpareParts':
    case 'auto_spare_parts':
      return {
        'role': 'autoSpareParts',
        'displayName': 'Auto Spare Parts',
        'collection': 'auto_spare_parts_shops',
      };

    case 'recovery':
      return {
        'role': 'recovery',
        'displayName': 'Recovery Service',
        'collection': 'recoveryDrivers',
      };

    case 'other_business':
    case 'otherBusiness':
      return {
        'role': 'other_business',
        'displayName': 'Other Business',
        'collection': 'otherBusinesses',
      };

    default:
      throw UnsupportedError(
        'Unsupported profile role: $role',
      );
  }
}
}
