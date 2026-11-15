import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jober_india/jober_indiaScreens.dart/Ambulance/ambulance_nearby.dart';
import 'package:jober_india/jober_indiaScreens.dart/Clinic/screen_clinic_categories.dart';
import 'package:jober_india/jober_indiaScreens.dart/Doctors/screen_doctor_categories.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_chat.dart';
import 'package:jober_india/jober_indiaScreens.dart/Recovery/recovery_drivers.dart';
import 'package:jober_india/jober_indiaScreens.dart/TaxiCommercial/screen_taxicomrcial_catgory.dart';
import 'package:jober_india/jober_indiaScreens.dart/Tea_Shops/screen_tea_shopcategory.dart';
import 'package:jober_india/jober_indiaScreens.dart/distance_plan.dart';
import 'package:jober_india/jober_indiaScreens.dart/foodDelivery/food_delivery_category.dart';
import 'package:jober_india/jober_indiaScreens.dart/freelancers/freelancer_categoru.dart';
import 'package:jober_india/jober_indiaScreens.dart/location_backgrnd_servce.dart';
import 'package:jober_india/jober_indiaScreens.dart/otherBusiness/categories.dart';
import 'package:jober_india/jober_indiaScreens.dart/profile_page.dart';
import 'package:jober_india/jober_indiaScreens.dart/selfEmployi/self_employee_category.dart';
import 'package:jober_india/jober_indiaScreens.dart/workers/screen_worker_category.dart';
import 'package:jober_india/worker_data.dart';
import 'package:overlay_pop_up/overlay_pop_up.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:jober_india/screens/owner/screen_user.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_more.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_help_support.dart';
import 'package:jober_india/jober_indiaScreens.dart/medical%20shop/screen_medcl_shop_list.dart';
import 'package:jober_india/jober_indiaScreens.dart/speech_services.dart';
import 'package:jober_india/l10n/app_localizations.dart';
import 'package:jober_india/screens/screen_language.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';

class ScreenHome extends StatefulWidget {
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String currentRole = '';
 
 final workerBox = Hive.box<WorkerData>('workerBox');

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final SpeechToText speech = SpeechToText();
  final SpeechServices speechService = SpeechServices();
  final ScrollController _workerScrollController = ScrollController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

 
  final LiveLocationService _liveLocationService =
    LiveLocationService.instance;
  Position? currentPosition;

  bool locationEnabled = false;
  bool _loadingLocation = false;
  bool _liveLocationRequested = false;

  // ==========================================================
  // GOOGLE MAP
  // ==========================================================

  StreamSubscription<
      QuerySnapshot<Map<String, dynamic>>>?
      _liveLocationsSubscription;


  bool searchingService = false;

  //String? _workerError;

  List<Map<String, dynamic>>
      searchResults = [];
// ==========================================================
// NEW USER OFFER
// ==========================================================

DateTime? firstInstallDate;

static const int newUserOfferDays = 30;

bool get isNewUserOfferActive {

  if (firstInstallDate == null) {
    return false;
  }

  final expiry = firstInstallDate!.add(
    const Duration(
      days: newUserOfferDays,
    ),
  );

  return DateTime.now().isBefore(expiry);
}

  String selectedServiceId = '';

  String selectedServiceName = '';

final Map<String, int> _serviceCounts = {
  'Doctor': 0,
  'Ambulance': 0,
  'Clinic': 0,
  'Medical Shop': 0,

  'Company': 0,
  'Recovery': 0,
  'Taxis': 0,
  'Food Delivery': 0,
  'Fish Delivery': 0,
  'Hotel / Tea Shops': 0,

  'Worker': 0,
  'Freelancer': 0,
  'Self Employed': 0,

  'Garage / Workshop': 0,
  'Spare Parts': 0,
  'Tea / Coffee': 0,
  'Grocery Stores': 0,
  'Rentals': 0,
  'broker': 0,
  'Individual Sellers': 0,
};

  bool isListening = false;


 
final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
    _onlineCountSubscriptions = {};

StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _doctorAvailabilitySubscription;
StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _ambulanceCountSubscription;
StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _taxiCommercialSubscription;

  Future<void> initializeSpeech() async {

    try {

      await speech.initialize();

    } catch (e) {

      debugPrint(
        'Speech initialization error: $e',
      );
    }
  }

String _getProviderRole() {
  final String role = currentRole
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s-]+'), '_');

  switch (role) {
    case 'food_delivery':
    case 'food_deliveries':
      return 'food_delivery';

    case 'worker':
    case 'workers':
      return 'worker';

    case 'recovery':
    case 'recovery_driver':
    case 'recovery_drivers':
      return 'recovery';

    case 'broker':
    case 'brokers':
      return 'broker';

    case 'freelancer':
    case 'freelancers':
      return 'freelancer';

    case 'self_employee':
    case 'self_employed':
      return 'self_employee';

    case 'taxi_commercial':
      return 'taxi_commercial';

    case 'individual_sellers':
    case 'individual_seller':
      return 'individual_sellers';

    case 'doctor':
    case 'doctors':
      return 'doctor';

    case 'ambulance':
    case 'ambulances':
      return 'ambulance';

    case 'clinic':
    case 'clinics':
      return 'clinic';

    case 'medicalshop':
    case 'medical_shop':
    case 'medical_shops':
      return 'medical_shop';

    case 'company':
    case 'companies':
      return 'company';

    case 'garage':
    case 'garages':
      return 'garage';

    case 'courier':
    case 'couriers':
      return 'courier';

    default:
      return role;
  }
}

String _getProviderServiceType() {
  return _getProviderRole();
}

Future<bool> _checkLiveLocationBeforeNavigation() async {
  final bool serviceRunning =
      await FlutterForegroundTask.isRunningService;

  final bool savedLiveState =
      await _liveLocationService.savedLiveLocationState;

  if (!mounted) return false;

  // Refresh the UI state using the actual saved state
  // and foreground service status.
  final bool isEnabled = serviceRunning && savedLiveState;

  setState(() {
    _liveLocationRequested = isEnabled;
    locationEnabled = isEnabled;
  });

  return isEnabled;
}

Future<void> _restoreLiveLocationState() async {
  // Check whether the foreground location service is running.
  final bool serviceRunning =
      await FlutterForegroundTask.isRunningService;

  // Read the previously saved LIVE location state.
  final bool savedLiveState = await
      _liveLocationService.savedLiveLocationState;

  if (!mounted) return;

  setState(() {
    _liveLocationRequested = savedLiveState && serviceRunning;
    locationEnabled = savedLiveState && serviceRunning;
  });
}
 
 void _liveLocationStatusListener() {
  if (!mounted) return;

  final bool isLive = liveLocationStatus.value;

  if (_liveLocationRequested == isLive &&
      locationEnabled == isLive) {
    return;
  }

  setState(() {
    _liveLocationRequested = isLive;
    locationEnabled = isLive;
  });
}

Future<void> startLiveLocation() async {
  if (_loadingLocation) return;

  setState(() {
    _loadingLocation = true;
    _liveLocationRequested = true;
  });

  try {
    bool overlayPermission =
    await OverlayPopUp.checkPermission();

if (!overlayPermission) {
  await OverlayPopUp.requestPermission();

  if (!mounted) return;

  // Recheck after returning from Android settings.
  overlayPermission =
      await OverlayPopUp.checkPermission();
}

if (!overlayPermission) {
  if (mounted) {
    setState(() {
      _liveLocationRequested = false;
      locationEnabled = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
        content: Text(
        //  'Please allow Display over other apps '
         AppLocalizations.of(context)!.pleaseallowdisplayoverotherapps,
          //'to use the LIVE bubble.',
        ),
      ),
    );
  }

  return;
}
 
    final bool gpsEnabled =
        await _liveLocationService.isGpsEnabled();

    if (!gpsEnabled) {
      if (!mounted) return;

      setState(() {
        _liveLocationRequested = false;
        locationEnabled = false;
      });

      await Geolocator.openLocationSettings();
      return;
    }

   
    final bool started =
    await _liveLocationService.start(
  categories: await _getProviderCategories(),

  role: _getProviderRole(),

  serviceType: _getProviderServiceType(),
);

    if (!mounted) return;

    if (!started) {
      setState(() {
        _liveLocationRequested = false;
        locationEnabled = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(
           // 'Could not start LIVE location.',
           AppLocalizations.of(context)!.couldnotstartlivelocation
          ),
        ),
      );

      return;
    }

    try {
  final bool bubbleShown =
      await OverlayPopUp.showOverlay(
    // width: 280,
    // height: 190,
      width: 300,
    height: 280,
    isDraggable: true,
    swipeToDismiss: false,
    closeWhenTapBackButton: false,
    // entryPointMethodName:
    //     'citizenLiveBubbleEntryPoint',
    entryPointMethodName: 'overlayMain',
    notificationIcon: 'ic_launcher',
    notificationTitle: 'Citizen India LIVE',
    notificationText:
        'Your LIVE location is active.',
  );

  if (!bubbleShown) {
    debugPrint(
      'LIVE started, but the floating bubble '
      'could not be displayed.',
    );
  }
} catch (e) {
  debugPrint('Could not show LIVE bubble: $e');
}
  
if (!mounted) return;
    setState(() {
      _liveLocationRequested = true;
      locationEnabled = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'LIVE location turned ON.',
        ),
      ),
    );
  } catch (e) {
    debugPrint(
      'Start LIVE location error: $e',
    );

    if (!mounted) return;

    setState(() {
      _liveLocationRequested = false;
      locationEnabled = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not start LIVE location.',
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _loadingLocation = false;
      });
    }
  }
}

Future<List<String>> _getProviderCategories() async {
  final Box userBox = await Hive.openBox('userBox');

  final dynamic savedCategories = userBox.get('categories');

  if (savedCategories is List) {
    final categories = savedCategories
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    if (categories.isNotEmpty) {
      return categories;
    }
  }

  // Compatibility with profiles that saved only one category.
  final String savedCategory =
      (userBox.get('category') ?? '').toString().trim();

  if (savedCategory.isNotEmpty) {
    return [savedCategory];
  }

  return [];
}

 Future<void> stopLiveLocation() async {
  if (_loadingLocation) return;

  setState(() {
    _loadingLocation = true;
    _liveLocationRequested = false;
    locationEnabled = false;
  });

  try {
    final bool stopped =
        await _liveLocationService.stop();

    if (!mounted) return;

    if (!stopped) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(
            //'Could not stop LIVE location.',
            AppLocalizations.of(context)!.couldnotstoplivelocation
          ),
        ),
      );

      return;
    }

    await OverlayPopUp.closeOverlay();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'LIVE location turned OFF.',
        ),
      ),
    );
  } catch (e) {
    debugPrint(
      'Stop LIVE location error: $e',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not stop LIVE location.',
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _loadingLocation = false;
      });
    }
  }
}

  // ==========================================================
  // CANONICAL SERVICE ID
  // ==========================================================

  String? _canonicalServiceId(
    String input,
  ) {

    final value =
        input
            .trim()
            .toLowerCase();

    if (value.isEmpty) {
      return null;
    }


    final l10n =
        AppLocalizations.of(context);


    if (l10n == null) {
      return value;
    }


    final serviceMap =
        <String, String>{

      'electrician':
          'electrician',

      l10n.electrician
          .toLowerCase():
          'electrician',


      'plumber':
          'plumber',

      l10n.plumber
          .toLowerCase():
          'plumber',


      'carpenter':
          'carpenter',

      l10n.carpenter
          .toLowerCase():
          'carpenter',


      'painter':
          'painter',

      l10n.painter
          .toLowerCase():
          'painter',


      'mechanic':
          'mechanic',

      l10n.mechanic
          .toLowerCase():
          'mechanic',


      'cleaner':
          'cleaner',

      l10n.cleaner
          .toLowerCase():
          'cleaner',


      'mason':
          'mason',

      l10n.mason
          .toLowerCase():
          'mason',


      'doctors':
          'doctors',

      l10n.doctor
          .toLowerCase():
          'doctors',


      'ac technician':
          'ac_technician',
    };


    return serviceMap[value];
  }


  // ==========================================================
  // SERVICE SEARCH
  // ==========================================================

  Future<void> searchForService(
    String serviceId, {
    required String displayName,
  }) async {

    final canonicalId =
        _canonicalServiceId(
              serviceId,
            ) ??
            serviceId
                .trim()
                .toLowerCase();


    if (canonicalId.isEmpty) {
      return;
    }


    if (!mounted) {
      return;
    }


    setState(() {

      selectedServiceId =
          canonicalId;

      selectedServiceName =
          displayName;

      searchResults = [];

      searchingService =
          true;

    });
  }

   // ==========================================================
  // PAYMENT / DISTANCE
  // ==========================================================

  bool paymentBoxVisible = false;

  double selectedDistance = 3;

  double paidDistance = 5;

  DateTime?
      paymentExpiry;


  // ==========================================================
  // PAYMENT AMOUNT
  // ==========================================================

  int get paymentAmount {

    if (selectedDistance <= 3) {
      return 0;
    }

    return ((selectedDistance - 3).round()) *
        1;
  }

  // ==========================================================
  // PAYMENT VALIDITY
  // ==========================================================

  bool get hasValidPayment {

    if (paymentExpiry == null) {
      return false;
    }

    if (DateTime.now()
        .isAfter(paymentExpiry!)) {
      return false;
    }

    return paidDistance >=
        selectedDistance;
  }

// ==========================================================
// LOAD SUBSCRIPTION
// ==========================================================

Future<void> loadPaymentData() async {

  final box =
      Hive.box('settings');

  final savedDistance =
      box.get('activeDistance');

  final savedExpiry =
      box.get('subscriptionExpiry');

  // final savedStart =
  //     box.get('subscriptionStart');

  if (savedDistance != null) {

    paidDistance =
        (savedDistance as num).toDouble();
  }

  if (savedExpiry != null) {

    paymentExpiry =
        DateTime.tryParse(
      savedExpiry.toString(),
    );
  }

  if (paymentExpiry != null &&
      DateTime.now().isAfter(
        paymentExpiry!,
      )) {

    await expireSubscription();
  }

  if (!mounted) {
    return;
  }

  setState(() {});
}

// ==========================================================
// EXPIRE SUBSCRIPTION
// ==========================================================

Future<void> expireSubscription() async {

  final box =
      Hive.box('settings');

  await box.delete(
    'activeDistance',
  );

  await box.delete(
    'subscriptionStart',
  );

  await box.delete(
    'subscriptionExpiry',
  );

  await box.delete(
    'subscriptionDuration',
  );

  await box.delete(
    'subscriptionPaidAmount',
  );

  await box.delete(
    'subscriptionActive',
  );

  paidDistance = 1;

  paymentExpiry = null;

  selectedDistance = 1;
}

// ==========================================================
// ACTIVE SUBSCRIPTION CARD
// ==========================================================

Widget _activeSubscriptionCard() {

  if (!hasActiveSubscription) {
    return const SizedBox.shrink();
  }

  final remaining =
      paymentExpiry!
          .difference(DateTime.now());

  final hours =
      remaining.inHours;

  final minutes =
      remaining.inMinutes % 60;

  return Container(
    width: double.infinity,

    padding:
        const EdgeInsets.all(15),

    decoration: BoxDecoration(
      color:
          const Color(0xFFE8F5E9),

      borderRadius:
          BorderRadius.circular(16),

      border: Border.all(
        color:
            const Color(0xFF138808),
      ),
    ),

    child: Row(
      children: [

        const Icon(
          Icons.verified,
          color:
              Color(0xFF138808),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                '${paidDistance.round()} KM unlocked',
                 // AppLocalizations.of(context)!.kmunlocked,
                
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF138808),
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Remaining: '
                '${hours}h ${minutes}m',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ==========================================================
// START SUBSCRIPTION PAYMENT
// ==========================================================

Future<void> startSubscriptionPayment(
  DistancePlan plan,
) async {

  final amount =
      getPlanPrice(plan);

  /*
   ==========================================================
   FUTURE RAZORPAY CONNECTION
   ==========================================================

   Later you can connect Razorpay here.

   Example structure:

   final options = {
     'key': 'YOUR_RAZORPAY_KEY',
     'amount': (amount * 100).round(),
     'name': 'Citizen India',
     'description':
         '${plan.distance.round()} KM - ${plan.duration}',
     'prefill': {
       'contact': '',
       'email': '',
     },
   };

   razorpay.open(options);

   IMPORTANT:
   DO NOT unlock the distance here.

   Unlock it only from the Razorpay success callback.

   ==========================================================
  */

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Payment gateway will be connected here. '
        'Amount: ₹${amount.toStringAsFixed(
          amount % 1 == 0 ? 0 : 2,
        )}',
      ),
    ),
  );
}

  // ==========================================================
  // PAYMENT
  // ==========================================================
//    Future<void> startPayment() async {
//   // Razorpay payment will be connected here later.

//   ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(
//       content: Text(
//         'Payment gateway will be available soon.',
//       ),
//     ),
//   );
// }

  Future<void> payForDistance() async {

    final amount =
        paymentAmount;


    if (amount <= 0) {
      return;
    }


    final paymentSuccessful =
        await showDialog<bool>(

      context: context,

      builder: (context) {

        return AlertDialog(

          title:
               Text(
           // 'Confirm Payment',
            AppLocalizations.of(context)!.confirmPayment
          ),

          content:
              Text(
            'Pay ₹$amount to unlock '
            '${selectedDistance.round()} km '
            'for 1 day?',
          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(
                  context,
                  false,
                );
              },

              child:
                   Text(
                    AppLocalizations.of(context)!.cancel
               // 'Cancel',
              ),
            ),


            ElevatedButton(

              onPressed: () {

                Navigator.pop(
                  context,
                  true,
                );
              },

              child:
                   Text(
                AppLocalizations.of(context)!.pay
              //  'Pay',
              ),
            ),
          ],
        );
      },
    );


    if (paymentSuccessful != true) {
      return;
    }


    final expiry =
        DateTime.now().add(
      const Duration(
        days: 1,
      ),
    );


    final box =
        Hive.box('settings');


    await box.put(
      'paidDistance',
      selectedDistance,
    );


    await box.put(
      'paymentExpiry',
      expiry.toIso8601String(),
    );


    paidDistance =
        selectedDistance;

    paymentExpiry =
        expiry;


    if (!mounted) {
      return;
    }


    setState(() {

      paymentBoxVisible =
          false;
    });


    ScaffoldMessenger.of(
      context,
    ).showSnackBar(

      SnackBar(

        content:
            Text(
          '${selectedDistance.round()} km '
          'Yor paid KM Valid for 1 days.',
        ),
      ),
    );


    if (selectedServiceId.isNotEmpty) {

      await searchForService(
        selectedServiceId,
        displayName:
            selectedServiceName,
      );
    }
  }
 
void selectDistance(double distance) {

  if (distance == 1) {

    setState(() {
      selectedDistance = 1;
    });

    return;
  }

  if (hasValidPaymentForDistance(distance)) {

    setState(() {
      selectedDistance = distance;
    });

    if (selectedServiceId.isNotEmpty) {
      searchForService(
        selectedServiceId,
        displayName: selectedServiceName,
      );
    }

    return;
  }

  showSubscriptionPopup(distance);
}

Widget paymentButtonSection() {
  const green = Color(0xFF138808);

final distances = <double>[
  1,
  5,
  10,
  20,
  40,
  50,
  100,
  150,
  200,
  300,
];

  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 10,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
                          AppLocalizations.of(context)!.chooseyourdistance,
        //  'Choose your distance',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

         Text(
          AppLocalizations.of(context)!.showprofessionalswithinyourselecteddistance,
        //  'Show professionals within your selected distance.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 15),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: distances.map((distance) {

            final isSelected =
                selectedDistance == distance;

            final isFree =
                distance == 1;

            final isUnlocked =
                distance == 1 ||
                hasValidPaymentForDistance(distance);

            return GestureDetector(
              onTap: () {
                selectDistance(distance);
              },

              child: Container(
               // width: 145,
               width: (MediaQuery.of(context).size.width - 64) / 3,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? green
                      : Colors.white,

                  borderRadius:
                      BorderRadius.circular(30),

                  border: Border.all(
                    color: isSelected
                        ? green
                        : const Color(0xFFE0E0E0),
                    width: 1.2,
                  ),

                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [

                    Text(
                      '${distance.round()} km',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),

                    if (isFree) ...[
                      const SizedBox(width: 5),
                      Text(
AppLocalizations.of(context)!.free,
                       // 'FREE',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : green,
                        ),
                      ),
                    ],

                    if (!isFree &&
                        !isUnlocked) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 15),

        if (hasActiveSubscription)
          _activeSubscriptionCard(),
      ],
    ),
  );
}


// ==========================================================
// DISTANCE PLANS
// ==========================================================

List<DistancePlan> getPlansForDistance(
  double distance,
) {

  switch (distance.round()) {

    case 5:
      return const [

        DistancePlan(
          distance: 5,
          duration: '24 Hours',
          durationHours: 24,
          originalPrice: 5,
          offerPercent: 0,
        ),

        DistancePlan(
          distance: 5,
          duration: '10 Days',
          durationHours: 240,
          originalPrice: 50,
          offerPercent: 25,
        ),

        DistancePlan(
          distance: 5,
          duration: '30 Days',
          durationHours: 720,
          originalPrice: 150,
          offerPercent: 25,
        ),
      ];

    case 10:
      return const [

        DistancePlan(
          distance: 10,
          duration: '24 Hours',
          durationHours: 24,
          originalPrice: 10,
          offerPercent: 0,
        ),

        DistancePlan(
          distance: 10,
          duration: '10 Days',
          durationHours: 240,
          originalPrice: 100,
          offerPercent: 25,
        ),

        DistancePlan(
          distance: 10,
          duration: '30 Days',
          durationHours: 720,
          originalPrice: 300,
          offerPercent: 30,
        ),
      ];

    case 20:
      return const [

        DistancePlan(
          distance: 20,
          duration: '24 Hours',
          durationHours: 24,
          originalPrice: 20,
          offerPercent: 0,
        ),

        DistancePlan(
          distance: 20,
          duration: '10 Days',
          durationHours: 240,
          originalPrice: 200,
          offerPercent: 25,
        ),

        DistancePlan(
          distance: 20,
          duration: '30 Days',
          durationHours: 720,
          originalPrice: 600,
          offerPercent: 30,
        ),
      ];

    case 40:
      return const [

        DistancePlan(
          distance: 40,
          duration: '24 Hours',
          durationHours: 24,
          originalPrice: 40,
          offerPercent: 0,
        ),

        DistancePlan(
          distance: 40,
          duration: '10 Days',
          durationHours: 240,
          originalPrice: 400,
          offerPercent: 30,
        ),

        DistancePlan(
          distance: 40,
          duration: '30 Days',
          durationHours: 720,
          originalPrice: 1200,
          offerPercent: 40,
        ),
      ];

    case 50:
      return const [

        DistancePlan(
          distance: 50,
          duration: '24 Hours',
          durationHours: 24,
          originalPrice: 50,
          offerPercent: 0,
        ),

        DistancePlan(
          distance: 50,
          duration: '10 Days',
          durationHours: 240,
          originalPrice: 500,
          offerPercent: 35,
        ),

        DistancePlan(
          distance: 50,
          duration: '30 Days',
          durationHours: 720,
          originalPrice: 1500,
          offerPercent: 50,
        ),
      ];

    default:
      return [];
  }
}

Future<void> loadFirstInstallDate() async {

  final box = Hive.box('settings');

  final savedDate =
      box.get('firstInstallDate');

  if (savedDate == null) {

    final now =
        DateTime.now();

    await box.put(
      'firstInstallDate',
      now.toIso8601String(),
    );

    firstInstallDate = now;

  } else {

    firstInstallDate =
        DateTime.tryParse(
      savedDate.toString(),
    );
  }

  if (mounted) {
    setState(() {});
  }
}


Future<void> activateSubscription(
  DistancePlan plan,
) async {

  final box =
      Hive.box('settings');

  final start =
      DateTime.now();

  final expiry =
      start.add(
    Duration(
      hours: plan.durationHours,
    ),
  );

  await box.put(
    'activeDistance',
    plan.distance,
  );

  await box.put(
    'subscriptionStart',
    start.toIso8601String(),
  );

  await box.put(
    'subscriptionExpiry',
    expiry.toIso8601String(),
  );

  await box.put(
    'subscriptionDuration',
    plan.duration,
  );

  await box.put(
    'subscriptionPaidAmount',
    getPlanPrice(plan),
  );

  await box.put(
    'subscriptionActive',
    true,
  );

  paidDistance =
      plan.distance;

  selectedDistance =
      plan.distance;

  paymentExpiry =
      expiry;

  if (!mounted) {
    return;
  }

  setState(() {});

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${plan.distance.round()} KM unlocked '
        'for ${plan.duration}.',
      ),
    ),
  );

  if (selectedServiceId.isNotEmpty) {

    await searchForService(
      selectedServiceId,
      displayName:
          selectedServiceName,
    );
  }
}

bool hasValidPaymentForDistance(
  double distance,
) {

  if (paymentExpiry == null) {
    return false;
  }

  if (DateTime.now().isAfter(paymentExpiry!)) {
    return false;
  }

  return paidDistance >= distance;
}

bool get hasActiveSubscription {

  if (paymentExpiry == null) {
    return false;
  }

  return DateTime.now().isBefore(
    paymentExpiry!,
  );
}

// ==========================================================
// RAZORPAY PAYMENT SUCCESS
// ==========================================================
// void _handlePaymentSuccess(
//   PaymentSuccessResponse response,
// ) {

//   if (selectedPlan == null) {
//     return;
//   }

//   onPaymentSuccess(
//     response.paymentId ?? '',
//     selectedPlan!,
//   );
// }

Future<void> onPaymentSuccess(
  String paymentId,
  DistancePlan plan,
) async {

  await activateSubscription(plan);

  if (!mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Payment successful. '
        '${plan.distance.round()} KM unlocked '
        'for ${plan.duration}.',
      ),
    ),
  );
}

double getPlanPrice(
  DistancePlan plan,
) {

  if (!isNewUserOfferActive) {
    return plan.originalPrice;
  }

  return plan.finalPrice;
}

int getPlanOffer(
  DistancePlan plan,
) {

  if (!isNewUserOfferActive) {
    return 0;
  }

  return plan.offerPercent;
}

// ==========================================================
// SUBSCRIPTION POPUP
// ==========================================================

void showSubscriptionPopup(
  double distance,
) {

  final plans =
      getPlansForDistance(distance);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(28),
      ),
    ),
    builder: (context) {

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            10,
          ),

          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  '${distance.round()} KM Range',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                 Text(
                      AppLocalizations.of(context)!.chooseyourpaymentvalidity,
                 // 'Choose your payment validity',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 15),

                if (isNewUserOfferActive)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [

                        const Icon(
                          Icons.local_offer,
                          color: Color(0xFF138808),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'New user offer active. '
                            'Special discounted prices '
                            'are available.',
                            style: const TextStyle(
                              color:
                                  Color(0xFF138808),
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 15),

                ...plans.map(
                  (plan) =>
                      _subscriptionPlanButton(
                    plan,
                  ),
                ),

                const SizedBox(height: 10),

                const Center(
                  child: Text(
                    'Secure payment will be connected later.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ==========================================================
// SUBSCRIPTION PLAN BUTTON
// ==========================================================

Widget _subscriptionPlanButton(
  DistancePlan plan,
) {

  final offer =
      getPlanOffer(plan);

  final price =
      getPlanPrice(plan);

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(
      bottom: 12,
    ),

    decoration: BoxDecoration(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(18),

      border: Border.all(
        color: const Color(0xFFE0E0E0),
      ),

      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 5,
          offset: Offset(0, 2),
        ),
      ],
    ),

    child: Padding(
      padding: const EdgeInsets.all(15),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              Expanded(
                child: Text(
                  '${plan.distance.round()} KM - '
                  '${plan.duration}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              if (offer > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFE8F5E9,
                    ),
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Text(
                    'OFFER $offer%',
                    style: const TextStyle(
                      color:
                          Color(0xFF138808),
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [

              if (offer > 0)
                Text(
                  '₹${plan.originalPrice.toStringAsFixed(
                    plan.originalPrice % 1 == 0
                        ? 0
                        : 2,
                  )}',
                  style: const TextStyle(
                    color: Colors.grey,
                    decoration:
                        TextDecoration.lineThrough,
                    fontSize: 14,
                  ),
                ),

              if (offer > 0)
                const SizedBox(width: 8),

              Text(
                '₹${price.toStringAsFixed(
                  price % 1 == 0 ? 0 : 2,
                )}',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF138808),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              onPressed: () {

                Navigator.pop(context);

                startSubscriptionPayment(
                  plan,
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF138808),
                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                ),
              ),

              child: Text(
                'Pay ₹${price.toStringAsFixed(
                  price % 1 == 0 ? 0 : 2,
                )}',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // ==========================================================
  // VOICE SEARCH
  // ==========================================================

  Future<void> startVoiceSearch() async {

    if (isListening) {
      return;
    }


    final available =
        await speechService
            .speech
            .initialize();


    if (!available ||
        !mounted) {
      return;
    }


    setState(() {

      isListening = true;
    });


    await speechService
        .speech
        .listen(

      onResult: (result) {

        if (!result.finalResult ||
            !mounted) {
          return;
        }


        final job =
            speechService.detectJob(
          result.recognizedWords,
        );


        if (job.isNotEmpty) {

          speechService
              .speech
              .stop();


          setState(() {

            isListening =
                false;
          });


          speechService.findWorker(
            context,
            job,
          );
        }
      },
    );
  }


  // ==========================================================
  // STOP VOICE SEARCH
  // ==========================================================

  Future<void> stopVoiceSearch() async {

    await speechService
        .speech
        .stop();


    if (!mounted) {
      return;
    }


    setState(() {

      isListening =
          false;
    });
  }


  // ==========================================================
  // SEARCH SECTION
  // ==========================================================

  Widget searchSection() {

    return Padding(

      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),

      child:
          TextField(

        controller:
            searchController,

        focusNode:
            searchFocusNode,

        textInputAction:
            TextInputAction.search,


        onSubmitted: (value) {

          final text =
              value.trim();


          if (text.isNotEmpty) {

            final serviceId =
                _canonicalServiceId(
              text,
            );


            searchForService(

              serviceId ?? text,

              displayName:
                  text,
            );
          }
        },


        decoration:
            InputDecoration(

          hintText:
                     AppLocalizations.of(context)!.searchforaservice,
            //  'Search for a service',
          prefixIcon:
              const Icon(
            Icons.search,
          ),


          suffixIcon:
              IconButton(

            icon:
                Icon(

              isListening
                  ? Icons.mic
                  : Icons.mic_none,

              color:
                  const Color(
                0xFF830202,
              ),
            ),


            onPressed: () {

              if (isListening) {

                stopVoiceSearch();

              } else {

                startVoiceSearch();
              }
            },
          ),


          filled:
              true,

          fillColor:
              Colors.grey.shade100,


          border:
              OutlineInputBorder(

            borderRadius:
                BorderRadius.circular(
              30,
            ),

            borderSide:
                BorderSide.none,
          ),
        ),
      ),
    );
  }


  // ==========================================================
  // HOME HERO BANNER
  // ==========================================================

  Widget homeHeroBanner() {

    return Container(
      margin:
          const EdgeInsets.fromLTRB(5,10,5,15),
      height: 185,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),
      clipBehavior:
          Clip.antiAlias,
      child: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              'assets/images/WhatsApp Image 2026-09-04 at 9.26.20 PM.jpeg',
              fit: BoxFit.fill,
            ),
          ),


          Positioned(
            left: 5,
            right: 5,
            bottom: 5,
            child: Transform.scale(
              scale: 0.78,
              child:
                  searchSection(),
            ),
          ),
        ],
      ),
    );
  }

Widget categorySection() {
  final List<Map<String, dynamic>> categories = [
    // ==========================================================
    // ROW 1
    // ==========================================================

{
  'id': 'doctor',
  'title': AppLocalizations.of(context)!.doctor,
  'icon': Icons.medical_services,
  'iconColor': Colors.red,
  'backgroundColor': const Color(0xFFFFF7EF),
},
{
  'id': 'ambulance',
  'title': AppLocalizations.of(context)!.ambulance,
  'icon': Icons.emergency,
  'iconColor': Colors.red,
  'backgroundColor': const Color(0xFFFFF7EF),
},
{
  'id': 'clinic',
  'title': AppLocalizations.of(context)!.clinic,
  'icon': Icons.local_hospital_outlined,
  'iconColor': Colors.red,
  'backgroundColor': const Color(0xFFFFF7EF),
},
{
  'id': 'medicalShop',
  'title': AppLocalizations.of(context)!.medicalShop,
  'icon': Icons.local_pharmacy,
  'iconColor': Colors.red,
  'backgroundColor': const Color(0xFFFFF7EF),
},

    // ==========================================================
    // ROW 2
    // ==========================================================

    {
       'id': 'recovery',
      'title': AppLocalizations.of(context)!.recovery,
      // 'Recovery',
      'icon': Icons.car_repair,
      'iconColor': Colors.red,
      'backgroundColor': const Color(0xFFFFF7EF),
    },

    {
  'id': 'taxi',
  'title': AppLocalizations.of(context)!.taxi,
  'icon': Icons.local_taxi,
  'secondIcon': Icons.local_shipping,
  'iconColor': Colors.red,
  'backgroundColor': const Color(0xFFFFF7EF),
},

    {
      'id': 'foodDelivery',
      'title':  AppLocalizations.of(context)!.foodDelivery,
      // 'Food Delivery',
      'icon': Icons.delivery_dining,
      'iconColor': Colors.red,
      'backgroundColor': const Color(0xFFFFF7EF),
    },

    {
      'id': 'hotelTeaShops',
      'title': AppLocalizations.of(context)!.hotelTeaShops,
      // 'Hotel / Tea Shops',
      'icon': Icons.restaurant,
      'iconColor': Colors.red,
      'backgroundColor': const Color(0xFFFFF7EF),
    },

    // ==========================================================
    // ROW 3
    // ==========================================================

    {
      'id': 'workers',
      'title': AppLocalizations.of(context)!.worker,
      //'Workers',
      'icon': Icons.engineering,
      'iconColor': Colors.red,
      'backgroundColor': const Color(0xFFFFF7EF),
    },

    {
      'id': 'freelancers',
      'title': AppLocalizations.of(context)!.freelancers,
      //'Freelancers',
      'icon': Icons.work_outline,
      'iconColor': Colors.red,
      'backgroundColor': const Color(0xFFFFF7EF),
    },

    {
      'id': 'selfEmployed',
      'title': AppLocalizations.of(context)!.selfEmployed,
      //'Self Employed',
      'icon': Icons.person_outline,
      'iconColor': Colors.red,
      'backgroundColor': const Color(0xFFFFF7EF),
    },

    {
      'id': 'more',
      'title': AppLocalizations.of(context)!.more,
      //'More',
      'icon': Icons.more_horiz,
      'iconColor': Colors.white,
      'backgroundColor': Color(0xFF138808),
      'isMore': true,
    },
  ];

  return Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          AppLocalizations.of(context)!.findaservice,
         // 'Find a Service',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: categories.length,

          // ======================================================
          // 4 BUTTONS PER ROW
          // ======================================================

          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 15,
            childAspectRatio: 0.65,
          ),

          itemBuilder: (context, index) {
            final category = categories[index];
final String categoryId =
    category['id']?.toString() ?? '';

            final String title =
                category['title'] as String;

            final IconData icon =
                category['icon'] as IconData;

            final Color iconColor =
                category['iconColor'] as Color;

            final Color backgroundColor =
                category['backgroundColor'] as Color;

            final IconData? secondIcon =
                category['secondIcon'] as IconData?;

            final bool isMore =
                category['isMore'] == true;

final Widget? countBadge = switch (categoryId) {
  'medicalShop' => buildOnlineCountBadge(
      _serviceCounts['Medical Shop'] ?? 0,
    ),

  'doctor' => availableDoctorsBadge(),

  'ambulance' => buildAmbulanceCountBadge(),

  'clinic' => buildOnlineCountBadge(
      _serviceCounts['Clinic'] ?? 0,
    ),

  'taxi' => buildTaxiCountBadge(),

  'foodDelivery' => buildFoodDeliveryCountBadge(),

  'workers' => buildWorkerCountBadge(),

  'freelancers' => buildFreelancerCountBadge(),

  'hotelTeaShops' => buildOnlineCountBadge(
      _serviceCounts['Hotel / Tea Shops'] ?? 0,
    ),

  'recovery' => buildOnlineCountBadge(
      _serviceCounts['Recovery'] ?? 0,
    ),

  'selfEmployed' => buildOnlineCountBadge(
      _serviceCounts['Self Employed'] ?? 0,
    ),

  _ => null,
};

            return GestureDetector(

onTap: () async {
  // Capture these BEFORE the asynchronous gap.
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final bool isEnabled =
      await _checkLiveLocationBeforeNavigation();

  if (!mounted) return;

  if (!isEnabled) {
    messenger.showSnackBar(
       SnackBar(
        content: Text(
           AppLocalizations.of(context)!.liveLocationonButton
         // 'Please turn Red ON LIVE location from this page first.',
        ),
      ),
    );
    return;
  }

  if (isMore) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => const ScreenMore(),
      ),
    );
    return;
  }

//_openHomeCategory(title);
_openHomeCategory(categoryId);
 // _openHomeCategory(title);
},
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          icon,
                          size: isMore ? 34 : 30,
                          color: iconColor,
                        ),

                        if (secondIcon != null)
                          Positioned(
                            right: 5,
                            bottom: 5,
                            child: Icon(
                              secondIcon,
                              size: 19,
                              color: iconColor,
                            ),
                          ),

                        // ==================================================
                        // AVAILABILITY COUNT
                        // ==================================================

                    if (!isMore && countBadge != null)
  Positioned(
    top: -7,
    right: -7,
    child: countBadge,
  ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    softWrap: true,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  );
}

@override
void initState() {
  super.initState();
  liveLocationStatus.addListener(
  _liveLocationStatusListener,
);

  loadPaymentData();
  loadFirstInstallDate();
  initializeSpeech();
  _listenToSelfEmployeeRegisteredCount();
  _listenToMedicalShopCount();
  _listenToClinicTotalCount();

  _restoreLiveLocationState();

  _listenToOnlineCount(
  collection: 'doctors',
  countKey: 'Doctor',
);

_listenToOnlineCount(
  collection: 'ambulances',
  countKey: 'Ambulance',
);

// _listenToOnlineCount(
//   collection: 'clinics',
//   countKey: 'Clinic',
// );

  _listenToOnlineCount(
  collection: 'foodDeliveryGuys',
  countKey: 'Food Delivery',
);

_listenToOnlineCount(
  collection: 'tea_shops',
  countKey: 'Hotel / Tea Shops',
);

  _listenToOnlineCount(
    collection: 'taxi_commercial',
    countKey: 'Taxis',
  );

  _listenToOnlineCount(
    collection: 'workers',
    countKey: 'Worker',
  );

  _listenToOnlineCount(
    collection: 'freelancers',
    countKey: 'Freelancer',
  );

  _listenToOnlineCount(
  collection: 'companies',
  countKey: 'Company',
);

_listenToOnlineCount(
  collection: 'recoveryDrivers',
  countKey: 'Recovery',
);

_listenToOnlineCount(
  collection: 'fishDeliveryGuys',
  countKey: 'Fish Delivery',
);
}

void _listenToClinicTotalCount() {
  _onlineCountSubscriptions['Clinic']?.cancel();

  _onlineCountSubscriptions['Clinic'] =
      firestore.collection('clinics').snapshots().listen(
    (snapshot) {
      if (!mounted) return;

      setState(() {
        _serviceCounts['Clinic'] = snapshot.docs.length;
      });

      debugPrint(
        'HOME TOTAL CLINIC COUNT: ${snapshot.docs.length}',
      );
    },
    onError: (error) {
      debugPrint('CLINIC TOTAL COUNT ERROR: $error');
    },
  );
}

Widget buildTaxiCountBadge() {
  return buildOnlineCountBadge(
    _serviceCounts['Taxis'] ?? 0,
  );
}

Widget buildAmbulanceCountBadge() {
  return buildOnlineCountBadge(
    _serviceCounts['Ambulance'] ?? 0,
  );
}

Widget availableDoctorsBadge() {
  return buildOnlineCountBadge(
    _serviceCounts['Doctor'] ?? 0,
  );
}

Widget buildWorkerCountBadge() {
  return buildOnlineCountBadge(
    _serviceCounts['Worker'] ?? 0,
  );
}

Widget buildFreelancerCountBadge() {
  return buildOnlineCountBadge(
    _serviceCounts['Freelancer'] ?? 0,
  );
}

Widget buildFoodDeliveryCountBadge() {
  return buildOnlineCountBadge(
    _serviceCounts['Food Delivery'] ?? 0,
  );
  }


void _listenToMedicalShopCount() {
  _onlineCountSubscriptions['Medical Shop']?.cancel();

  _onlineCountSubscriptions['Medical Shop'] =
      firestore
          .collection('medicalShops')
          .snapshots()
          .listen(
    (snapshot) {
      if (!mounted) return;

      setState(() {
        _serviceCounts['Medical Shop'] =
            snapshot.docs.length;
      });

      debugPrint(
        'HOME MEDICAL SHOP COUNT: ${snapshot.docs.length}',
      );
    },
    onError: (error) {
      debugPrint(
        'MEDICAL SHOP COUNT ERROR: $error',
      );
    },
  );
}

Widget buildOnlineCountBadge(int count) {
  if (count <= 0) {
    return const SizedBox.shrink();
  }

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 7,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFF16803C),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      count > 99 ? '99+' : count.toString(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

void _listenToOnlineCount({
  required String collection,
  required String countKey,
}) {
  _onlineCountSubscriptions[countKey]?.cancel();

  // const onlineCountCollections = {
  //   'doctors',
  //   'ambulances',
  //   'clinics',
  //   'freelancers',
  //   'workers',
  // };
  const onlineCountCollections = {
  'doctors',
  'ambulances',
  'clinics',
  'companies',
  'recoveryDrivers',
  'taxi_commercial',
  'foodDeliveryGuys',
  'fishDeliveryGuys',
  'tea_shops',
  'freelancers',
  'workers',
};

  final bool countOnlineOnly =
      onlineCountCollections.contains(collection);

  Query<Map<String, dynamic>> query =
      firestore.collection(collection);

  if (countOnlineOnly) {
    query = query.where(
      'isOnline',
      isEqualTo: true,
    );
  }

  _onlineCountSubscriptions[countKey] =
      query.snapshots().listen(
    (snapshot) {
      if (!mounted) return;

      final int count = snapshot.docs.length;

      setState(() {
        _serviceCounts[countKey] = count;
      });

      debugPrint(
        'HOME COUNT [$collection] '
        'onlineOnly=$countOnlineOnly count=$count',
      );
    },
    onError: (Object error) {
      debugPrint(
        'HOME COUNT ERROR [$collection]: $error',
      );
    },
  );
}

// ==========================================================
// OPEN HOME CATEGORY USING STABLE ID
// ==========================================================

void _openHomeCategory(String categoryId) {
  switch (categoryId) {

    // ========================================================
    // DOCTOR
    // ========================================================

    case 'doctor':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScreenDoctorCategories(),
        ),
      );
      break;

    // ========================================================
    // AMBULANCE
    // ========================================================

    case 'ambulance':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AmbulanceNearbyPage(
            ambulanceCategory: '',
          ),
        ),
      );
      break;

    // ========================================================
    // CLINIC
    // ========================================================

    case 'clinic':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScreenClinicCategories(),
        ),
      );
      break;

    // ========================================================
    // MEDICAL SHOP
    // ========================================================

    case 'medicalShop':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MedicalShopCategoryScreen(),
        ),
      );
      break;

    // ========================================================
    // RECOVERY
    // ========================================================

    case 'recovery':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ScreenRecoveryDrivers(),
        ),
      );
      break;

    // ========================================================
    // TAXI
    // ========================================================

    case 'taxi':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ScreenTaxiCommercialCategories(),
        ),
      );
      break;

    // ========================================================
    // FOOD DELIVERY
    // ========================================================

    case 'foodDelivery':
      _openFoodDelivery();
      break;

    // ========================================================
    // HOTEL / TEA SHOPS
    // ========================================================

    case 'hotelTeaShops':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScreenTeaShopCategories(),
        ),
      );
      break;

    // ========================================================
    // WORKERS
    // ========================================================

    case 'workers':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScreenWorkerCategories(),
        ),
      );
      break;

    // ========================================================
    // FREELANCERS
    // ========================================================

    case 'freelancers':
      _openFreelancers();
      break;

    // ========================================================
    // SELF EMPLOYED
    // ========================================================

    case 'selfEmployed':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ScreenSelfEmployeesCategories(),
        ),
      );
      break;

    default:
      debugPrint(
        'HOME CATEGORY ERROR: Unknown category ID: $categoryId',
      );
      break;
  }
}

void _openFoodDelivery() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const ScreenFoodDeliveryCategories(
        userLatitude: 0.0,
        userLongitude: 0.0,
      ),
    ),
  );
}

Future<void> _openFreelancers() async {
  try {
    // 1. Check whether phone GPS is enabled.
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(
            AppLocalizations.of(context)!.pleaseenableyourphonelocation
            //'Please enable your phone location.'
            ),
        ),
      );
      return;
    }

    // 2. Check location permission.
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please allow location permission in app settings.',
          ),
        ),
      );
      return;
    }

    // 3. Reuse the homepage position if available.
    // Otherwise, request a fresh position from the phone.
    currentPosition ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    if (!mounted) return;

    // 4. Verify the position before opening Freelancer.
    final position = currentPosition;

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to get your location. Please try again.',
          ),
        ),
      );
      return;
    }

    // 5. Open Freelancer with valid coordinates.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenFreelancerCategories(
          userLatitude: position.latitude,
          userLongitude: position.longitude,
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to get location: $e'),
      ),
    );
  }
}

  // ==========================================================
  // LOGOUT DIALOG
  // ==========================================================

  void showLogoutDialog() {

    showDialog(

      context: context,

      barrierDismissible:
          false,

      builder:
          (dialogContext) {

        return AlertDialog(

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
 backgroundColor: Colors.white,
          title:
               Row(
            children: [

              Icon(
                Icons.logout,
                color: Colors.red,
              ),

              SizedBox(
                width: 10,
              ),

              Text(AppLocalizations.of(context)!.logout,
               // 'Logout',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          content:
               Text(AppLocalizations.of(context)!.areyousureyouWantTologout
           // 'Are you sure you want to logout?',
          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(
                  dialogContext,
                );
              },

              child:
                   Text(AppLocalizations.of(context)!.cancel,
               // 'Cancel',
                style: TextStyle(color: Colors.green),
              ),
            ),


            ElevatedButton(

              style:
                  ElevatedButton.styleFrom(

                backgroundColor:
                    Colors.red,

                foregroundColor:
                    Colors.white,
              ),

              onPressed: () async {

                Navigator.pop(
                  dialogContext,
                );

                await logoutUser();
              },

              child:
                   Text(AppLocalizations.of(context)!.logout
               // 'Logout',
              ),
            ),
          ],
        );
      },
    );
  }
  // final String userBoxRole =
//     (userBox.get('role') ?? '')
//         .toString()
//         .trim()
//         .toLowerCase();

// final String settingsRole =
//     (settingsBox.get('userRole') ?? '')
//         .toString()
//         .trim()
//         .toLowerCase();

// final String role = userBoxRole.isNotEmpty
//     ? userBoxRole
//     : settingsRole;

// Also check the rental registration saved for this UID.
// final String rentalUid =
//     (settingsBox.get('rentalUid') ?? '').toString();

// final bool isRentalAccount =
//     role == 'rental' ||
//     role == 'rentals' ||
//     (
//       settingsBox.get('isRentalRegistered') == true &&
//       rentalUid == (user?.uid ?? '')
//     );

// bulanceOnLogout(user.uid).timeout(
//       const Duration(seconds: 15),
//     );

//     debugPrint('Ambulance logout cleanup completed.');
//   } catch (e) {
//     debugPrint('Ambulance logout cleanup failed: $e');
//   }
// }

// // ========================================================
// // RECOVERY DRIVER CLEANUP
// // ========================================================

// if (role == 'recovery' ||
//     role == 'recoverydriver' ||
//     role == 'recovery_driver' ||
//     role == 'recoverydrivers') {
//   try {
//     await cleanupRecoveryOnLogout(user.uid).timeout(
//       const Duration(seconds: 15),
//     );

//     debugPrint('Recovery Driver logout cleanup completed.');
//   } catch (e) {
//     debugPrint('Recovery Driver logout cleanup failed: $e');
//   }
// }

// // ========================================================
// // STUDENT CLEANUP
// // ========================================================

// if (role == 'student' || role == 'students') {
//   try {
//     await cleanupStudentOnLogout(user.uid).timeout(
//       const Duration(seconds: 15),
//     );

//     debugPrint('Student logout cleanup completed.');
//   } catch (e) {
//     debugPrint('Student logout cleanup failed: $e');
//   }
// }

// if (role == 'company' || role == 'companies') {
//   try {
//     await cleanupCompanyOnLogout(user.uid).timeout(
//       const Duration(seconds: 15),
//     );
//   } catch (e) {
//     debugPrint('Company logout cleanup failed: $e');
//   }
// }
// // ========================================================
// // CLINIC CATEGORY CLEANUP
// // ========================================================
// if (role == 'clinic') {
//   try {
//     await cleanupClinicOnLogout(user.uid).timeout(
//       const Duration(seconds: 15),
//     );
//   } catch (e) {
//     debugPrint('Clinic logout cleanup error: $e');
//   }
// }

// // ========================================================
// // LABORATORY PROFILE AND CATEGORY CLEANUP
// // ========================================================

// if (role == 'laboratory' ||
//     role == 'laboratories') {
//   try {
//     await cleanupLaboratoryOnLogout(
//       user.uid,
//     ).timeout(
//       const Duration(seconds: 15),
//     );

//     debugPrint(
//       'Laboratory profile and category cleanup completed.',
//     );
//   } catch (e, stackTrace) {
//     debugPrint(
//       'Laboratory logout cleanup failed: $e',
//     );

//     debugPrint('$stackTrace');
//   }
// }

// // if (role == 'clinic') {
// //   try {
// //     await cleanupClinicOnLogout(user.uid).timeout(
// //       const Duration(seconds: 15),
// //     );
// //   } catch (e) {
// //     debugPrint('Clinic logout cleanup error: $e');
// //   }
// // }

// if (role == 'worker' || role == 'workers') {
//   try {
//     await cleanupWorkerOnLogout(user.uid).timeout(
//       const Duration(seconds: 15),
//     );

//     debugPrint('Worker profile and category cleanup completed.');
//   } catch (e, stackTrace) {
//     debugPrint('Worker logout cleanup failed: $e');
//     debugPrint('$stackTrace');
//   }
// }

// // ========================================================
// // AUTO SPARE PARTS PROFILE CLEANUP
// // ========================================================

// if (role == 'autospareparts' ||
//     role == 'auto_spare_parts' ||
//     role == 'auto spare parts') {
//   try {
//     await cleanupAutoSparePartsOnLogout(
//       user.uid,
//     ).timeout(
//       const Duration(seconds: 20),
//     );

//     debugPrint(
//       'Auto Spare Parts profile and local data cleanup completed.',
//     );
//   } catch (e, stackTrace) {
//     debugPrint(
//       'Auto Spare Parts logout cleanup failed: $e',
//     );
//     debugPrint('$stackTrace');
//   }
// }

// // ========================================================
//     // FOOD DELIVERY PROFILE AND CATEGORY CLEANUP
//     // ========================================================

//     if (role == 'food_delivery' ||
//         role == 'fooddelivery' ||
//         role == 'food delivery') {
//       try {
//         await cleanupFoodDeliveryOnLogout(user.uid).timeout(
//           const Duration(seconds: 30),
//         );

//         debugPrint(
//           'Food Delivery profile and category cleanup completed.',
//         );
//       } catch (e, stackTrace) {
//         debugPrint('Food Delivery cleanup failed: $e');
//         debugPrint('$stackTrace');
//       }
//     }

//     // ==========================================================
// // FISH DELIVERY CLEANUP
// // ==========================================================

// if (role == 'fish_delivery' ||
//     role == 'fishdelivery' ||
//     role == 'fish delivery') {
//   try {
//     await cleanupFishDeliveryOnLogout(user.uid).timeout(
//       const Duration(seconds: 30),
//     );

//     debugPrint('Fish Delivery logout cleanup completed.');
//   } catch (e, stackTrace) {
//     debugPrint('Fish Delivery cleanup failed: $e');
//     debugPrint('$stackTrace');
//   }
// }

// if (role == 'freelancer' || role == 'freelancers') {
//   try {
//     await cleanupFreelancerOnLogout(user.uid).timeout(
//       const Duration(seconds: 15),
//     );

//     debugPrint(
//       'Freelancer profile cleanup completed.',
//     );
//   } catch (e, stackTrace) {
//     debugPrint('Freelancer cleanup failed: $e');
//     debugPrint('$stackTrace');
//   }
// }

// // ========================================================
// // BROKER PROFILE AND CATEGORY CLEANUP
// // ========================================================

// if (role == 'broker' || role == 'brokers') {
//   try {
//     await cleanupBrokerOnLogout(user.uid).timeout(
//       const Duration(seconds: 15),
//     );

//     debugPrint(
//       'Broker profile and category cleanup completed.',
//     );
//   } catch (e, stackTrace) {
//     debugPrint('Broker logout cleanup failed: $e');
//     debugPrint('$stackTrace');
//   }
// }

// // ========================================================
// // GARAGE PROFILE AND CATEGORY CLEANUP
// // ========================================================

// if (role == 'garage' || role == 'garages') {
//   try {
//     await cleanupGarageOnLogout(user.uid).timeout(
//       const Duration(seconds: 20),
//     );

//     debugPrint(
//       'Garage profile and category cleanup completed.',
//     );

//   } catch (e, stackTrace) {

//     debugPrint('Garage logout cleanup failed: $e');
//     debugPrint('$stackTrace');
//   }
// }

// // ========================================================
// // COURIER PROFILE AND CATEGORY CLEANUP
// // ========================================================

// if (role == 'courier' ||
//     role == 'couriers') {
//   try {
//     await cleanupCourierOnLogout(user.uid).timeout(
//       const Duration(seconds: 20),
//     );

//     debugPrint(
//       'Courier profile and category cleanup completed.',
//     );
//   } catch (e, stackTrace) {
//     debugPrint(
//       'Courier logout cleanup failed: $e',
//     );

//     debugPrint('$stackTrace');
//   }
// }

// // ========================================================
//     // SELF EMPLOYEE PROFILE AND CATEGORY CLEANUP
//     // ========================================================

//     if (role == 'self_employee' ||
//         role == 'self employed' ||
//         role == 'self-employed') {
//       try {
//         await cleanupSelfEmployeeOnLogout(user.uid).timeout(
//           const Duration(seconds: 15),
//         );

//         debugPrint(
//           'Self-employed profile and local data cleanup completed.',
//         );
//       } catch (e, stackTrace) {
//         debugPrint('Self-employed logout cleanup failed: $e');
//         debugPrint('$stackTrace');
//       }
//     }

// // ========================================================
//     // TEA SHOP PROFILE AND CATEGORY CLEANUP
//     // ========================================================

//     if (role == 'tea_shop' ||
//         role == 'tea shop' ||
//         role == 'teashop') {
//       try {
//         await cleanupTeaShopOnLogout(user.uid).timeout(
//           const Duration(seconds: 15),
//         );

//         debugPrint('Tea shop profile and category cleanup completed.');
//       } catch (e, stackTrace) {
//         debugPrint('Tea shop logout cleanup failed: $e');
//         debugPrint('$stackTrace');
//       }
//     }
//     // ========================================================
//     // 2. FIND THE CORRECT PROFILE COLLECTION
//     // ========================================================

//     String? collection;

//     switch (role) {

//       case 'company':
// case 'companies':
//   collection = 'companies';
//   break;

// case 'recovery':
// case 'recoverydriver':
// case 'recovery_driver':
// case 'recoverydrivers':
//   collection = 'recoveryDrivers';
//   break;

//       case 'ambulance':
//       case 'ambulances':
//         collection = 'ambulances';
//         break;

//       case 'taxi':
//       case 'taxi_commercial':
//         collection = 'taxi_commercial';
//         break;

//     }

//     // ========================================================
//     // 3. MARK PROFILE OFFLINE
//     // ========================================================

//     if (collection != null) {
//       try {
//         await firestore
//             .collection(collection)
//             .doc(user.uid)
//             .set({
//           'isOnline': false,
//           'onlineUpdatedAt': FieldValue.serverTimestamp(),
//         }, SetOptions(merge: true))
//             .timeout(const Duration(seconds: 5));

//         debugPrint(
//           'Provider marked offline: $role, ${user.uid}',
//         );
//       } catch (e) {
//         debugPrint(
//           'Failed to mark $role offline: $e',
//         );
//       }
//     }

//     // ========================================================
//     // 4. DELETE LIVE LOCATION
//     // ========================================================

//     try {
//       await firestore
//           .collection('liveLocations')
//           .doc(user.uid)
//           .delete()
//           .timeout(const Duration(seconds: 5));

//       debugPrint('Live location deleted for ${user.uid}');
//     } catch (e) {
//       debugPrint('Live location cleanup failed: $e');
//     }
//   }
// } catch (e) {
//   debugPrint('Logout cleanup failed: $e');
// }

// bool _isLoggingOut = false;

// Future<void> logoutUser() async {
//   if (_isLoggingOut) return;
//   _isLoggingOut = true;

//   final user = FirebaseAuth.instance.currentUser;
//   final userBox = Hive.box('userBox');


// final Box settingsBox = Hive.isBoxOpen('appSettings')
//     ? Hive.box('appSettings')
//     : await Hive.openBox('appSettings');

// final role = (
//   userBox.get('role') ??
//   settingsBox.get('userRole') ??
//   ''
// )
//     .toString()
//     .trim()
//     .toLowerCase();


// if (user != null) {
//   await markCurrentProviderOfflineOnLogout(
//     uid: user.uid,
//     role: role,
//   );
// }

// // Now navigate away from Home.
// if (mounted) {
//   setState(() {
//     _liveLocationRequested = false;
//     locationEnabled = false;
//   });

//   Navigator.of(context).pushAndRemoveUntil(
//     MaterialPageRoute(
//       builder: (_) => const ScreenChooseRole(),
//     ),
//     (route) => false,
//   );
// }

//   // Continue cleanup without blocking navigation.

// Future<void>(() async {

//   // ========================================================
//   // 1. CLOSE THE FLOATING LIVE BUBBLE
//   // ========================================================

//   try {
//     await OverlayPopUp.closeOverlay();

//     debugPrint('LIVE bubble closed during logout.');
//   } catch (e) {
//     debugPrint('Could not close LIVE bubble: $e');
//   }

//   // ========================================================
//   // 2. STOP LIVE LOCATION BEFORE SIGNING OUT
//   // ========================================================

//   try {
//     final bool stopped =
//         await _liveLocationService.stop();

//     debugPrint(
//       'LIVE service stop during logout: $stopped',
//     );
//   } catch (e) {
//     debugPrint(
//       'Live-location service stop failed: $e',
//     );
//   }

//   final firestore = FirebaseFirestore.instance;

// try {
//   if (user != null) {
//     // ========================================================
//     // 1. WORKER CATEGORY CLEANUP
//     // ========================================================

//     if (role == 'worker') {
//       try {
//         await removeWorkerCategoriesOnLogout(user.uid)
//             .timeout(const Duration(seconds: 5));
//       } catch (e) {
//         debugPrint('Worker logout cleanup failed: $e');
//       }
//     }

//     // ========================================================
// // RENTAL PROFILE AND CATEGORY CLEANUP
// // ========================================================

// if (role == 'rental' ||
//     role == 'rentals') {
//   try {
//     await cleanupRentalOnLogout(
//       user.uid,
//     ).timeout(
//       const Duration(seconds: 20),
//     );

//     debugPrint(
//       'Rental profile and category cleanup completed.',
//     );
//   } catch (e, stackTrace) {
//     debugPrint(
//       'Rental logout cleanup failed: $e',
//     );

//     debugPrint('$stackTrace');
//   }
// }

//     // ========================================================
// // COMPANY CATEGORY CLEANUP
// // ========================================================

// if (role == 'company' || role == 'companies') {
//   try {
//     await removeCompanyCategoriesOnLogout(user.uid)
//         .timeout(const Duration(seconds: 5));
//   } catch (e) {
//     debugPrint(
//       'Company category logout cleanup failed: $e',
//     );
//   }
// }

// // ========================================================
// // RENTAL PROFILE AND CATEGORY CLEANUP
// // ========================================================

// // ========================================================
// // OTHER BUSINESS PROFILE AND CATEGORY CLEANUP
// // ========================================================

// if (role == 'other_business' ||
//     role == 'otherbusiness' ||
//     role == 'other business') {
//   try {
//     await cleanupOtherBusinessOnLogout(
//       user.uid,
//     ).timeout(
//       const Duration(seconds: 20),
//     );

//     debugPrint(
//       'Other Business profile and category cleanup completed.',
//     );
//   } catch (e, stackTrace) {
//     debugPrint(
//       'Other Business logout cleanup failed: $e',
//     );
//     debugPrint('$stackTrace');
//   }
// }

// // ========================================================
// // DOCTOR PROFILE AND CATEGORY CLEANUP
// // ========================================================

// if (role == 'doctor' || role == 'doctors') {
//   try {
//     await cleanupDoctorOnLogout(user.uid).timeout(
//       const Duration(seconds: 10),
//     );
//   } catch (e) {
//     debugPrint(
//       'Doctor logout cleanup failed: $e',
//     );
//   }
// }

// // ========================================================
// // MEDICAL SHOP PROFILE CLEANUP
// // ========================================================

// if (role == 'medicalshop' ||
//     role == 'medical_shop' ||
//     role == 'medical shop') {
//   try {
//     await cleanupMedicalShopOnLogout(user.uid).timeout(
//       const Duration(seconds: 20),
//     );

//     debugPrint(
//       'Medical Shop profile and local data cleanup completed.',
//     );
//   } catch (e, stackTrace) {
//     debugPrint('Medical Shop logout cleanup failed: $e');
//     debugPrint('$stackTrace');
//   }
// }

// // ========================================================
// // HOUSE OWNER CLEANUP
// // ========================================================

// if (role == 'houseowner' ||
//     role == 'house_owner' ||
//     role == 'house owner') {
//   try {
//     await cleanupHouseOwnerOnLogout(user.uid).timeout(
//       const Duration(seconds: 15),
//     );

//     debugPrint('House Owner logout cleanup completed.');
//   } catch (e) {
//     debugPrint('House Owner logout cleanup failed: $e');
//   }
// }

// // ========================================================
// // AMBULANCE CLEANUP
// // ========================================================

// if (role == 'ambulance' || role == 'ambulances') {
//   try {
//     await cleanupAm
//     // Sign out of Firebase.
//     try {
//       await FirebaseAuth.instance.signOut();
//     } catch (e) {
//       debugPrint('Firebase sign-out failed: $e');
//     }

//     // Cancel subscriptions.
//     try {
//       await _liveLocationsSubscription?.cancel();
//     } catch (_) {}
//     _liveLocationsSubscription = null;

//     try {
//       await _doctorAvailabilitySubscription?.cancel();
//     } catch (_) {}
//     _doctorAvailabilitySubscription = null;

//     try {
//       await _taxiCommercialSubscription?.cancel();
//     } catch (_) {}
//     _taxiCommercialSubscription = null;

//     try {
//       await _ambulanceCountSubscription?.cancel();
//     } catch (_) {}
//     _ambulanceCountSubscription = null;

//     for (final subscription
//         in _onlineCountSubscriptions.values.toList()) {
//       try {
//         await subscription.cancel();
//       } catch (_) {}
//     }
//     _onlineCountSubscriptions.clear();

// // Live location has already been stopped above.
// try {
//   await speechService.speech.stop();
// } catch (_) {}

// try {
//   await speech.stop();
// } catch (_) {}

//     try {
//       await speech.stop();
//     } catch (_) {}

//     _isLoggingOut = false;
//   });
// }

bool _isLoggingOut = false;

Future<void> logoutUser() async {
  if (_isLoggingOut) return;
  _isLoggingOut = true;

  final user = FirebaseAuth.instance.currentUser;
  final userBox = Hive.box('userBox');


final Box settingsBox = Hive.isBoxOpen('appSettings')
    ? Hive.box('appSettings')
    : await Hive.openBox('appSettings');

final role = (
  userBox.get('role') ??
  settingsBox.get('userRole') ??
  ''
)
    .toString()
    .trim()
    .toLowerCase();


if (user != null) {
  await markCurrentProviderOfflineOnLogout(
    uid: user.uid,
    role: role,
  );
}

// Now navigate away from Home.
if (mounted) {
  setState(() {
    _liveLocationRequested = false;
    locationEnabled = false;
  });

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => const ScreenChooseRole(),
    ),
    (route) => false,
  );
}

  // Continue cleanup without blocking navigation.

Future<void>(() async {

  // ========================================================
  // 1. CLOSE THE FLOATING LIVE BUBBLE
  // ========================================================

  try {
    await OverlayPopUp.closeOverlay();

    debugPrint('LIVE bubble closed during logout.');
  } catch (e) {
    debugPrint('Could not close LIVE bubble: $e');
  }

  // ========================================================
  // 2. STOP LIVE LOCATION BEFORE SIGNING OUT
  // ========================================================

  try {
    final bool stopped =
        await _liveLocationService.stop();

    debugPrint(
      'LIVE service stop during logout: $stopped',
    );
  } catch (e) {
    debugPrint(
      'Live-location service stop failed: $e',
    );
  }

  final firestore = FirebaseFirestore.instance;

try {
  if (user != null) {
    // ========================================================
    // 1. WORKER CATEGORY CLEANUP
    // ========================================================

    if (role == 'worker') {
      try {
        await removeWorkerCategoriesOnLogout(user.uid)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Worker logout cleanup failed: $e');
      }
    }

    // ========================================================
// COMPANY CATEGORY CLEANUP
// ========================================================

if (role == 'company' || role == 'companies') {
  try {
    await removeCompanyCategoriesOnLogout(user.uid)
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint(
      'Company category logout cleanup failed: $e',
    );
  }
}

// ========================================================
// RENTAL PROFILE AND CATEGORY CLEANUP
// ========================================================

// ========================================================
// OTHER BUSINESS PROFILE AND CATEGORY CLEANUP
// ========================================================

if (role == 'other_business' ||
    role == 'otherbusiness' ||
    role == 'other business') {
  try {
    await cleanupOtherBusinessOnLogout(
      user.uid,
    ).timeout(
      const Duration(seconds: 20),
    );

    debugPrint(
      'Other Business profile and category cleanup completed.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'Other Business logout cleanup failed: $e',
    );
    debugPrint('$stackTrace');
  }
}

// ========================================================
// DOCTOR PROFILE AND CATEGORY CLEANUP
// ========================================================

if (role == 'doctor' || role == 'doctors') {
  try {
    await cleanupDoctorOnLogout(user.uid).timeout(
      const Duration(seconds: 10),
    );
  } catch (e) {
    debugPrint(
      'Doctor logout cleanup failed: $e',
    );
  }
}

// ========================================================
// MEDICAL SHOP PROFILE CLEANUP
// ========================================================

if (role == 'medicalshop' ||
    role == 'medical_shop' ||
    role == 'medical shop') {
  try {
    await cleanupMedicalShopOnLogout(user.uid).timeout(
      const Duration(seconds: 20),
    );

    debugPrint(
      'Medical Shop profile and local data cleanup completed.',
    );
  } catch (e, stackTrace) {
    debugPrint('Medical Shop logout cleanup failed: $e');
    debugPrint('$stackTrace');
  }
}

// ========================================================
// RENTAL PROFILE AND CATEGORY CLEANUP
// ========================================================

if (role == 'rental' ||
    role == 'rentals') {
  try {
    await cleanupRentalOnLogout(
      user.uid,
    ).timeout(
      const Duration(seconds: 20),
    );

    debugPrint(
      'Rental profile and category cleanup completed.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'Rental logout cleanup failed: $e',
    );

    debugPrint('$stackTrace');
  }
}

// ========================================================
// HOUSE OWNER CLEANUP
// ========================================================

if (role == 'houseowner' ||
    role == 'house_owner' ||
    role == 'house owner') {
  try {
    await cleanupHouseOwnerOnLogout(user.uid).timeout(
      const Duration(seconds: 15),
    );

    debugPrint('House Owner logout cleanup completed.');
  } catch (e) {
    debugPrint('House Owner logout cleanup failed: $e');
  }
}

// ========================================================
// AMBULANCE CLEANUP
// ========================================================

if (role == 'ambulance' || role == 'ambulances') {
  try {
    await cleanupAmbulanceOnLogout(user.uid).timeout(
      const Duration(seconds: 15),
    );

    debugPrint('Ambulance logout cleanup completed.');
  } catch (e) {
    debugPrint('Ambulance logout cleanup failed: $e');
  }
}

// ========================================================
// RECOVERY DRIVER CLEANUP
// ========================================================

if (role == 'recovery' ||
    role == 'recoverydriver' ||
    role == 'recovery_driver' ||
    role == 'recoverydrivers') {
  try {
    await cleanupRecoveryOnLogout(user.uid).timeout(
      const Duration(seconds: 15),
    );

    debugPrint('Recovery Driver logout cleanup completed.');
  } catch (e) {
    debugPrint('Recovery Driver logout cleanup failed: $e');
  }
}

// ========================================================
// STUDENT CLEANUP
// ========================================================

if (role == 'student' || role == 'students') {
  try {
    await cleanupStudentOnLogout(user.uid).timeout(
      const Duration(seconds: 15),
    );

    debugPrint('Student logout cleanup completed.');
  } catch (e) {
    debugPrint('Student logout cleanup failed: $e');
  }
}

if (role == 'company' || role == 'companies') {
  try {
    await cleanupCompanyOnLogout(user.uid).timeout(
      const Duration(seconds: 15),
    );
  } catch (e) {
    debugPrint('Company logout cleanup failed: $e');
  }
}
// ========================================================
// CLINIC CATEGORY CLEANUP
// ========================================================
if (role == 'clinic') {
  try {
    await cleanupClinicOnLogout(user.uid).timeout(
      const Duration(seconds: 15),
    );
  } catch (e) {
    debugPrint('Clinic logout cleanup error: $e');
  }
}

// ========================================================
// LABORATORY PROFILE AND CATEGORY CLEANUP
// ========================================================

if (role == 'laboratory' ||
    role == 'laboratories') {
  try {
    await cleanupLaboratoryOnLogout(
      user.uid,
    ).timeout(
      const Duration(seconds: 15),
    );

    debugPrint(
      'Laboratory profile and category cleanup completed.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'Laboratory logout cleanup failed: $e',
    );

    debugPrint('$stackTrace');
  }
}

// if (role == 'clinic') {
//   try {
//     await cleanupClinicOnLogout(user.uid).timeout(
//       const Duration(seconds: 15),
//     );
//   } catch (e) {
//     debugPrint('Clinic logout cleanup error: $e');
//   }
// }

if (role == 'worker' || role == 'workers') {
  try {
    await cleanupWorkerOnLogout(user.uid).timeout(
      const Duration(seconds: 15),
    );

    debugPrint('Worker profile and category cleanup completed.');
  } catch (e, stackTrace) {
    debugPrint('Worker logout cleanup failed: $e');
    debugPrint('$stackTrace');
  }
}

// ========================================================
// AUTO SPARE PARTS PROFILE CLEANUP
// ========================================================

if (role == 'autospareparts' ||
    role == 'auto_spare_parts' ||
    role == 'auto spare parts') {
  try {
    await cleanupAutoSparePartsOnLogout(
      user.uid,
    ).timeout(
      const Duration(seconds: 20),
    );

    debugPrint(
      'Auto Spare Parts profile and local data cleanup completed.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'Auto Spare Parts logout cleanup failed: $e',
    );
    debugPrint('$stackTrace');
  }
}

// ========================================================
    // FOOD DELIVERY PROFILE AND CATEGORY CLEANUP
    // ========================================================

    if (role == 'food_delivery' ||
        role == 'fooddelivery' ||
        role == 'food delivery') {
      try {
        await cleanupFoodDeliveryOnLogout(user.uid).timeout(
          const Duration(seconds: 30),
        );

        debugPrint(
          'Food Delivery profile and category cleanup completed.',
        );
      } catch (e, stackTrace) {
        debugPrint('Food Delivery cleanup failed: $e');
        debugPrint('$stackTrace');
      }
    }

    // ==========================================================
// FISH DELIVERY CLEANUP
// ==========================================================

if (role == 'fish_delivery' ||
    role == 'fishdelivery' ||
    role == 'fish delivery') {
  try {
    await cleanupFishDeliveryOnLogout(user.uid).timeout(
      const Duration(seconds: 30),
    );

    debugPrint('Fish Delivery logout cleanup completed.');
  } catch (e, stackTrace) {
    debugPrint('Fish Delivery cleanup failed: $e');
    debugPrint('$stackTrace');
  }
}

if (role == 'freelancer' || role == 'freelancers') {
  try {
    await cleanupFreelancerOnLogout(user.uid).timeout(
      const Duration(seconds: 15),
    );

    debugPrint(
      'Freelancer profile cleanup completed.',
    );
  } catch (e, stackTrace) {
    debugPrint('Freelancer cleanup failed: $e');
    debugPrint('$stackTrace');
  }
}

// ========================================================
// BROKER PROFILE AND CATEGORY CLEANUP
// ========================================================

if (role == 'broker' || role == 'brokers') {
  try {
    await cleanupBrokerOnLogout(user.uid).timeout(
      const Duration(seconds: 15),
    );

    debugPrint(
      'Broker profile and category cleanup completed.',
    );
  } catch (e, stackTrace) {
    debugPrint('Broker logout cleanup failed: $e');
    debugPrint('$stackTrace');
  }
}

// ========================================================
// GARAGE PROFILE AND CATEGORY CLEANUP
// ========================================================

if (role == 'garage' || role == 'garages') {
  try {
    await cleanupGarageOnLogout(user.uid).timeout(
      const Duration(seconds: 20),
    );

    debugPrint(
      'Garage profile and category cleanup completed.',
    );

  } catch (e, stackTrace) {

    debugPrint('Garage logout cleanup failed: $e');
    debugPrint('$stackTrace');
  }
}

// ========================================================
// COURIER PROFILE AND CATEGORY CLEANUP
// ========================================================

if (role == 'courier' ||
    role == 'couriers') {
  try {
    await cleanupCourierOnLogout(user.uid).timeout(
      const Duration(seconds: 20),
    );

    debugPrint(
      'Courier profile and category cleanup completed.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'Courier logout cleanup failed: $e',
    );

    debugPrint('$stackTrace');
  }
}

// ========================================================
    // SELF EMPLOYEE PROFILE AND CATEGORY CLEANUP
    // ========================================================

    if (role == 'self_employee' ||
        role == 'self employed' ||
        role == 'self-employed') {
      try {
        await cleanupSelfEmployeeOnLogout(user.uid).timeout(
          const Duration(seconds: 15),
        );

        debugPrint(
          'Self-employed profile and local data cleanup completed.',
        );
      } catch (e, stackTrace) {
        debugPrint('Self-employed logout cleanup failed: $e');
        debugPrint('$stackTrace');
      }
    }

// ========================================================
    // TEA SHOP PROFILE AND CATEGORY CLEANUP
    // ========================================================

    if (role == 'tea_shop' ||
        role == 'tea shop' ||
        role == 'teashop') {
      try {
        await cleanupTeaShopOnLogout(user.uid).timeout(
          const Duration(seconds: 15),
        );

        debugPrint('Tea shop profile and category cleanup completed.');
      } catch (e, stackTrace) {
        debugPrint('Tea shop logout cleanup failed: $e');
        debugPrint('$stackTrace');
      }
    }
    // ========================================================
    // 2. FIND THE CORRECT PROFILE COLLECTION
    // ========================================================

    String? collection;

    switch (role) {

      case 'company':
case 'companies':
  collection = 'companies';
  break;

case 'recovery':
case 'recoverydriver':
case 'recovery_driver':
case 'recoverydrivers':
  collection = 'recoveryDrivers';
  break;

      case 'ambulance':
      case 'ambulances':
        collection = 'ambulances';
        break;

      case 'taxi':
      case 'taxi_commercial':
        collection = 'taxi_commercial';
        break;

    }

    // ========================================================
    // 3. MARK PROFILE OFFLINE
    // ========================================================

    if (collection != null) {
      try {
        await firestore
            .collection(collection)
            .doc(user.uid)
            .set({
          'isOnline': false,
          'onlineUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 5));

        debugPrint(
          'Provider marked offline: $role, ${user.uid}',
        );
      } catch (e) {
        debugPrint(
          'Failed to mark $role offline: $e',
        );
      }
    }

    // ========================================================
    // 4. DELETE LIVE LOCATION
    // ========================================================

    try {
      await firestore
          .collection('liveLocations')
          .doc(user.uid)
          .delete()
          .timeout(const Duration(seconds: 5));

      debugPrint('Live location deleted for ${user.uid}');
    } catch (e) {
      debugPrint('Live location cleanup failed: $e');
    }
  }
} catch (e) {
  debugPrint('Logout cleanup failed: $e');
}

    // Sign out of Firebase.
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Firebase sign-out failed: $e');
    }

    // Cancel subscriptions.
    try {
      await _liveLocationsSubscription?.cancel();
    } catch (_) {}
    _liveLocationsSubscription = null;

    try {
      await _doctorAvailabilitySubscription?.cancel();
    } catch (_) {}
    _doctorAvailabilitySubscription = null;

    try {
      await _taxiCommercialSubscription?.cancel();
    } catch (_) {}
    _taxiCommercialSubscription = null;

    try {
      await _ambulanceCountSubscription?.cancel();
    } catch (_) {}
    _ambulanceCountSubscription = null;

    for (final subscription
        in _onlineCountSubscriptions.values.toList()) {
      try {
        await subscription.cancel();
      } catch (_) {}
    }
    _onlineCountSubscriptions.clear();

// Live location has already been stopped above.
try {
  await speechService.speech.stop();
} catch (_) {}

try {
  await speech.stop();
} catch (_) {}

    try {
      await speech.stop();
    } catch (_) {}

    _isLoggingOut = false;
  });
}

// Future<void> markCurrentProviderOfflineOnLogout({
//   required String uid,
//   required String? role,
// }) async {
//   final String normalizedRole =
//       (role ?? '').trim().toLowerCase();

//   final String? collection;

//   switch (normalizedRole) {
//     case 'doctor':
//     case 'doctors':
//       collection = 'doctors';
//       break;

//     case 'ambulance':
//     case 'ambulances':
//       collection = 'ambulances';
//       break;

//     case 'clinic':
//     case 'clinics':
//       collection = 'clinics';
//       break;

//     default:
//       collection = null;
//   }

//   if (collection == null) return;

//   try {
//     await FirebaseFirestore.instance
//         .collection(collection)
//         .doc(uid)
//         .set({
//       'isOnline': false,
//       'onlineUpdatedAt': FieldValue.serverTimestamp(),
//     }, SetOptions(merge: true))
//         .timeout(const Duration(seconds: 5));

//     debugPrint(
//       'Provider marked offline: $collection/$uid',
//     );
//   } catch (e) {
//     debugPrint(
//       'Could not mark provider offline: $collection/$e',
//     );
//   }
// }

// Future<void> cleanupOtherBusinessOnLogout(String uid) async {
//   final FirebaseFirestore firestore =
//       FirebaseFirestore.instance;

//   final Box settingsBox = Hive.box('settings');

//   final DocumentReference<Map<String, dynamic>> businessRef =
//       firestore.collection('otherBusinesses').doc(uid);

//   try {
//     // 1. Read the business before deleting it.
//     final businessSnapshot = await businessRef.get();

//     final Map<String, dynamic> businessData =
//         businessSnapshot.data() ?? {};

//     final List<String> categoryKeys =
//         List<String>.from(
//       businessData['categoryKeys'] ?? [],
//     );

//     // 2. Delete the business profile.
//     await businessRef.delete();

//     // 3. Check every category separately.
//     for (final key in categoryKeys.toSet()) {
//       // Built-in categories must never be deleted.
//       final bool isDefault =
//           defaultOtherBusinessCategories.any(
//         (item) => item.key == key,
//       );

//       if (isDefault) continue;

//       // Check whether another business still uses this category.
//       final remainingBusinesses = await firestore
//           .collection('otherBusinesses')
//           .where(
//             'categoryKeys',
//             arrayContains: key,
//           )
//           .limit(1)
//           .get();

//       // Delete only if nobody else uses it.
//       if (remainingBusinesses.docs.isEmpty) {
//         await firestore
//             .collection('otherBusinessCategories')
//             .doc(key)
//             .delete();

//         debugPrint(
//           'Unused custom Other Business category deleted: $key',
//         );
//       }
//     }

//     // 4. Remove local registration data.
//     // Do not clear another account's local registration.
//     final String savedUid =
//         (settingsBox.get('otherBusinessUid') ?? '')
//             .toString();

//     if (savedUid == uid) {
//       final List<String> keysToRemove = [
//         'otherBusinessRegistered',
//         'otherBusinessUid',
//         'otherBusinessUsername',
//         'otherBusinessName',
//         'otherBusinessMobile',
//         'otherBusinessSecondaryMobile',
//         'otherBusinessState',
//         'otherBusinessDistrict',
//         'otherBusinessNearestTown',
//         'otherBusinessCategories',
//         'otherBusinessCategoryKeys',
//         'otherBusinessDescription',
//         'otherBusinessOpeningTime',
//         'otherBusinessClosingTime',
//         'otherBusinessIsOpen24Hours',
//         'otherBusinessProfilePhoto',
//         'otherBusinessHasLocation',
//         'otherBusinessPrivacyPolicyAccepted',
//         'otherBusinessIsShopType',
//         'otherBusinessLocation',
//       ];

//       for (final key in keysToRemove) {
//         await settingsBox.delete(key);
//       }
//     }

//     debugPrint(
//       'Other Business profile and unused custom categories cleaned up.',
//     );
//   } catch (e, stackTrace) {
//     debugPrint(
//       'Other Business cleanup failed: $e',
//     );
//     debugPrint('$stackTrace');

//     rethrow;
//   }
// }

Future<void> markCurrentProviderOfflineOnLogout({
  required String uid,
  required String? role,
}) async {
  final String normalizedRole =
      (role ?? '').trim().toLowerCase();

  final String? collection;

  switch (normalizedRole) {
    case 'doctor':
    case 'doctors':
      collection = 'doctors';
      break;

    case 'ambulance':
    case 'ambulances':
      collection = 'ambulances';
      break;

    case 'clinic':
    case 'clinics':
      collection = 'clinics';
      break;

    default:
      collection = null;
  }

  if (collection == null) return;

  try {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(uid)
        .set({
      'isOnline': false,
      'onlineUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true))
        .timeout(const Duration(seconds: 5));

    debugPrint(
      'Provider marked offline: $collection/$uid',
    );
  } catch (e) {
    debugPrint(
      'Could not mark provider offline: $collection/$e',
    );
  }
}

Future<void> cleanupOtherBusinessOnLogout(String uid) async {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final Box settingsBox = Hive.box('settings');

  final DocumentReference<Map<String, dynamic>> businessRef =
      firestore.collection('otherBusinesses').doc(uid);

  try {
    // 1. Read the business before deleting it.
    final businessSnapshot = await businessRef.get();

    final Map<String, dynamic> businessData =
        businessSnapshot.data() ?? {};

    final List<String> categoryKeys =
        List<String>.from(
      businessData['categoryKeys'] ?? [],
    );

    // 2. Delete the business profile.
    await businessRef.delete();

    // 3. Check every category separately.
    for (final key in categoryKeys.toSet()) {
      // Built-in categories must never be deleted.
      final bool isDefault =
          defaultOtherBusinessCategories.any(
        (item) => item.key == key,
      );

      if (isDefault) continue;

      // Check whether another business still uses this category.
      final remainingBusinesses = await firestore
          .collection('otherBusinesses')
          .where(
            'categoryKeys',
            arrayContains: key,
          )
          .limit(1)
          .get();

      // Delete only if nobody else uses it.
      if (remainingBusinesses.docs.isEmpty) {
        await firestore
            .collection('otherBusinessCategories')
            .doc(key)
            .delete();

        debugPrint(
          'Unused custom Other Business category deleted: $key',
        );
      }
    }

    // 4. Remove local registration data.
    // Do not clear another account's local registration.
    final String savedUid =
        (settingsBox.get('otherBusinessUid') ?? '')
            .toString();

    if (savedUid == uid) {
      final List<String> keysToRemove = [
        'otherBusinessRegistered',
        'otherBusinessUid',
        'otherBusinessUsername',
        'otherBusinessName',
        'otherBusinessMobile',
        'otherBusinessSecondaryMobile',
        'otherBusinessState',
        'otherBusinessDistrict',
        'otherBusinessNearestTown',
        'otherBusinessCategories',
        'otherBusinessCategoryKeys',
        'otherBusinessDescription',
        'otherBusinessOpeningTime',
        'otherBusinessClosingTime',
        'otherBusinessIsOpen24Hours',
        'otherBusinessProfilePhoto',
        'otherBusinessHasLocation',
        'otherBusinessPrivacyPolicyAccepted',
        'otherBusinessIsShopType',
        'otherBusinessLocation',
      ];

      for (final key in keysToRemove) {
        await settingsBox.delete(key);
      }
    }

    debugPrint(
      'Other Business profile and unused custom categories cleaned up.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'Other Business cleanup failed: $e',
    );
    debugPrint('$stackTrace');

    rethrow;
  }
}

Future<void> cleanupRentalOnLogout(String uid) async {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  // Open the same boxes used during rental registration.
  final Box rentalBox = Hive.isBoxOpen('rentalProfiles')
      ? Hive.box('rentalProfiles')
      : await Hive.openBox('rentalProfiles');

  final Box settingsBox = Hive.isBoxOpen('appSettings')
      ? Hive.box('appSettings')
      : await Hive.openBox('appSettings');

  final DocumentReference<Map<String, dynamic>> rentalRef =
      firestore.collection('rentals').doc(uid);

  try {
    // ========================================================
    // 1. READ RENTAL PROFILE BEFORE DELETING
    // ========================================================

    final rentalSnapshot = await rentalRef.get();

    if (rentalSnapshot.exists) {
     // final data = rentalSnapshot.data() ?? {};

      debugPrint(
        'Rental profile found before logout: $uid',
      );

      // ======================================================
      // 2. DELETE RENTAL FIRESTORE PROFILE
      // ======================================================

      await rentalRef.delete();

      debugPrint(
        'Rental Firestore profile deleted: $uid',
      );
    }

    // ========================================================
    // 3. DELETE LOCAL RENTAL PROFILE
    // ========================================================

    if (rentalBox.containsKey(uid)) {
      await rentalBox.delete(uid);

      debugPrint(
        'Local rental profile deleted: $uid',
      );
    }

    // ========================================================
    // 4. REMOVE RENTAL APP SETTINGS
    // Only remove settings belonging to this account.
    // ========================================================

    final String savedRentalUid =
        (settingsBox.get('rentalUid') ?? '')
            .toString();

    if (savedRentalUid == uid) {
      final List<String> keysToRemove = [
        'isRentalRegistered',
        'rentalUid',
      ];

      for (final key in keysToRemove) {
        await settingsBox.delete(key);
      }

      // Clear the role only if it still belongs to rental.
      final String currentRole =
          (settingsBox.get('userRole') ?? '')
              .toString()
              .trim()
              .toLowerCase();

      if (currentRole == 'rental' ||
          currentRole == 'rentals') {
        await settingsBox.delete('userRole');
      }
    }

    debugPrint(
      'Rental profile and local data cleanup completed.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'Rental logout cleanup failed: $e',
    );

    debugPrint('$stackTrace');

    rethrow;
  }
}

// if (role == 'rental' ||
//     role == 'rentals') {
//   try {
//     await cleanupRentalOnLogout(user.uid).timeout(
//       const Duration(seconds: 20),
//     );

//     debugPrint(
//       'Rental profile and category cleanup completed.',
//     );
//   } catch (e, stackTrace) {
//     debugPrint('Rental logout cleanup failed: $e');
//     debugPrint('$stackTrace');
//   }
// }
// ========================================================
// RENTAL PROFILE AND CATEGORY CLEANUP
// ========================================================

// if (isRentalAccount) {
//   try {
//     await cleanupRentalOnLogout(user.uid).timeout(
//       const Duration(seconds: 20),
//     );

//     debugPrint(
//       'Rental profile and category cleanup completed.',
//     );
//   } catch (e, stackTrace) {
//     debugPrint(
//       'Rental logout cleanup failed: $e',
//     );

//     debugPrint('$stackTrace');
//   }
// }
// if (role == 'rental' ||
//     role == 'rentals') {
//   try {
//     await cleanupRentalOnLogout(user.uid).timeout(
//       const Duration(seconds: 20),
//     );

//     debugPrint(
//       'Rental profile and category cleanup completed.',
//     );
//   } catch (e, stackTrace) {
//     debugPrint(
//       'Rental logout cleanup failed: $e',
//     );

//     debugPrint('$stackTrace');
//   }
// }


// Future<void> cleanupRentalOnLogout(String uid) async {
//   final FirebaseFirestore firestore =
//       FirebaseFirestore.instance;

//   Object? firestoreError;
//   StackTrace? firestoreStackTrace;

//   // ==========================================================
//   // 1. DELETE RENTAL PROFILE FROM FIRESTORE
//   // ==========================================================

//   try {
//     await firestore
//         .collection('rentals')
//         .doc(uid)
//         .delete();

//     debugPrint(
//       'Rental Firestore profile deleted: $uid',
//     );
//   } catch (e, stackTrace) {
//     firestoreError = e;
//     firestoreStackTrace = stackTrace;

//     debugPrint(
//       'Rental Firestore deletion failed: $e',
//     );
//   }

//   // ==========================================================
//   // 2. DELETE RENTAL PROFILE FROM HIVE
//   // ==========================================================

//   try {
//     final Box rentalBox =
//         Hive.isBoxOpen('rentalProfiles')
//             ? Hive.box('rentalProfiles')
//             : await Hive.openBox('rentalProfiles');

//     await rentalBox.delete(uid);

//     debugPrint('Rental Hive profile deleted.');
//   } catch (e) {
//     debugPrint('Rental Hive cleanup failed: $e');
//   }

//   // ==========================================================
//   // 3. CLEAR RENTAL APP SETTINGS
//   // ==========================================================

//   try {
//     final Box settingsBox =
//         Hive.isBoxOpen('appSettings')
//             ? Hive.box('appSettings')
//             : await Hive.openBox('appSettings');

//     final savedRentalUid =
//         settingsBox.get('rentalUid')?.toString();

//     if (savedRentalUid == uid) {
//       await settingsBox.delete('isRentalRegistered');
//       await settingsBox.delete('rentalUid');

//       if (settingsBox
//               .get('userRole')
//               ?.toString()
//               .trim()
//               .toLowerCase() ==
//           'rental') {
//         await settingsBox.delete('userRole');
//       }
//     }

//     debugPrint('Rental app settings cleared.');
//   } catch (e) {
//     debugPrint('Rental settings cleanup failed: $e');
//   }

//   // ==========================================================
//   // 4. CLEAR COMMON LOGIN DATA IF IT BELONGS TO THIS RENTAL
//   // ==========================================================

//   try {
//     final Box userBox =
//         Hive.isBoxOpen('userBox')
//             ? Hive.box('userBox')
//             : await Hive.openBox('userBox');

//     final savedUid =
//         userBox.get('uid')?.toString();

//     final savedRole = userBox
//         .get('role')
//         ?.toString()
//         .trim()
//         .toLowerCase();

//     if (savedUid == uid &&
//         (savedRole == 'rental' ||
//             savedRole == 'rentals')) {
//       const keys = [
//         'uid',
//         'name',
//         'mobile',
//         'secondaryMobile',
//         'role',
//         'categories',
//       ];

//       for (final key in keys) {
//         await userBox.delete(key);
//       }
//     }

//     debugPrint('Rental common login data cleared.');
//   } catch (e) {
//     debugPrint('Rental common login cleanup failed: $e');
//   }

//   // ==========================================================
//   // 5. REPORT FIRESTORE FAILURE
//   // ==========================================================

//   if (firestoreError != null) {
//     Error.throwWithStackTrace(
//       firestoreError,
//       firestoreStackTrace!,
//     );
//   }

//   debugPrint(
//     'RENTAL LOGOUT CLEANUP COMPLETE: $uid',
//   );
// }

Future<void> cleanupAutoSparePartsOnLogout(
  String uid,
) async {
  const List<String> builtInCategories = [
    'All Auto Spare Parts',
    '4 Wheeler Spare Parts',
    '3 Wheeler Spare Parts',
    '2 Wheeler Spare Parts',
    '6 Wheeler Spare Parts',
    'JCB Spare Parts',
  ];

  final Map<String, String> builtInMap = {
    for (final category in builtInCategories)
      category.toLowerCase(): category,
  };

  final settings = Hive.box('settings');

  // ========================================================
  // 1. CLEAN LOCAL CATEGORIES
  // ========================================================

  final List<dynamic> savedCategories =
      settings.get(
    'autoSparePartsCategories',
    defaultValue: <dynamic>[],
  );

  final List<String> remainingCategories =
      savedCategories
          .map((item) => item.toString().trim())
          .where((item) =>
              builtInMap.containsKey(item.toLowerCase()))
          .map((item) => builtInMap[item.toLowerCase()]!)
          .toSet()
          .toList();

  await settings.put(
    'autoSparePartsCategories',
    remainingCategories,
  );

  await settings.put(
    'autoSparePartsCategory',
    remainingCategories.join(', '),
  );

  // ========================================================
  // 2. REMOVE ALL LOCAL CUSTOM CATEGORIES
  // ========================================================

  await settings.put(
    'autoSparePartsCustomCategories',
    <String>[],
  );

  // ========================================================
  // 3. MARK FIRESTORE SYNC PENDING
  // ========================================================

  await settings.put(
    'autoSparePartsSyncPending',
    true,
  );

  // ========================================================
  // 4. CLEAN FIRESTORE
  // ========================================================

  try {
    final docRef = FirebaseFirestore.instance
        .collection('auto_spare_parts_shops')
        .doc(uid);

    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await settings.put(
        'autoSparePartsSyncPending',
        false,
      );

      return;
    }

    final data = snapshot.data() ?? {};

    final List<dynamic> firestoreCategories =
        data['categories'] is List
            ? data['categories'] as List
            : [];

    final List<String> remainingFirestoreCategories =
        firestoreCategories
            .map((item) => item.toString().trim())
            .where((item) =>
                builtInMap.containsKey(item.toLowerCase()))
            .map((item) => builtInMap[item.toLowerCase()]!)
            .toSet()
            .toList();

    // ======================================================
    // 5. REBUILD SEARCH KEYWORDS
    // ======================================================

    final String name =
        (data['name'] ?? '').toString().trim();

    final String shopName =
        (data['shopName'] ?? '').toString().trim();

    final Set<String> searchKeywords = {
      if (name.isNotEmpty) name.toLowerCase(),
      if (shopName.isNotEmpty) shopName.toLowerCase(),
      'auto spare parts',
      ...remainingFirestoreCategories.map(
        (category) => category.toLowerCase(),
      ),
    };

    // ======================================================
    // 6. REMOVE FIRESTORE CUSTOM CATEGORIES
    // ======================================================

    await docRef.update({
      'categories': remainingFirestoreCategories,
      'customCategories': <String>[],
      'category': remainingFirestoreCategories.join(', '),
      'searchKeywords': searchKeywords.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(
      const Duration(seconds: 15),
    );

    await settings.put(
      'autoSparePartsSyncPending',
      false,
    );

    debugPrint(
      'AUTO SPARE PARTS: Custom category cleanup successful.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'AUTO SPARE PARTS LOGOUT CLEANUP ERROR: $e',
    );

    debugPrint('$stackTrace');

    // Keep pending true so cleanup can be retried.
    await settings.put(
      'autoSparePartsSyncPending',
      true,
    );
  }
}

Future<void> cleanupBrokerOnLogout(String uid) async {
  final firestore = FirebaseFirestore.instance;

  debugPrint('BROKER CLEANUP START: $uid');

  await firestore
      .collection('brokers')
      .doc(uid)
      .delete();

  debugPrint('Broker Firestore profile deleted.');

  try {
    await firestore
        .collection('liveLocations')
        .doc(uid)
        .delete();

    debugPrint('Broker live location deleted.');
  } catch (e) {
    debugPrint('Broker live location cleanup failed: $e');
  }

  final brokerBox = await Hive.openBox('brokerProfiles');

  await brokerBox.delete(uid);

  final savedBrokerUid =
      brokerBox.get('currentUid')?.toString();

  if (savedBrokerUid == uid) {
    await brokerBox.delete('currentUid');
  }

  debugPrint('Broker Hive profile deleted.');

  final userBox = await Hive.openBox('userBox');

  final savedUid = userBox.get('uid')?.toString();

  final savedRole = userBox
      .get('role')
      ?.toString()
      .trim()
      .toLowerCase();

  if (savedUid == uid &&
      (savedRole == 'broker' || savedRole == 'brokers')) {
    const commonKeys = [
      'uid',
      'name',
      'mobile',
      'secondaryMobile',
      'role',
      'categories',
      'brokerState',
      'brokerDistrict',
      'brokerNearestTown',
    ];

    for (final key in commonKeys) {
      await userBox.delete(key);
    }
  }

  debugPrint('BROKER CLEANUP COMPLETE: $uid');
}


Future<void> cleanupCourierOnLogout(String uid) async {
  final firestore = FirebaseFirestore.instance;

  final courierRef = firestore
      .collection('couriers')
      .doc(uid);

  final categorySnapshot = await firestore
      .collection('courierVehicleCategories')
      .where('createdBy', isEqualTo: uid)
      .get();

  await courierRef.delete();

  debugPrint(
    'Courier profile deleted: $uid',
  );

  for (final categoryDoc in categorySnapshot.docs) {
    final categoryData = categoryDoc.data();

    // Never delete built-in categories.
    if (categoryData['isCustom'] != true) {
      continue;
    }

    // Check whether another courier uses this category.
    final usersSnapshot = await firestore
        .collection('couriers')
        .where(
          'vehicleCategoryIds',
          arrayContains: categoryDoc.id,
        )
        .limit(1)
        .get();

    if (usersSnapshot.docs.isEmpty) {
      await categoryDoc.reference.delete();

      debugPrint(
        'Unused custom courier category deleted: '
        '${categoryDoc.id}',
      );
    } else {
      debugPrint(
        'Custom courier category retained because '
        'another courier uses it: ${categoryDoc.id}',
      );
    }
  }

  // ============================================================
  // 4. DELETE LIVE LOCATION
  // ============================================================

  await firestore
      .collection('liveLocations')
      .doc(uid)
      .delete();

  // ============================================================
  // 5. DELETE LOCAL COURIER REGISTRATION DETAILS
  // ============================================================

  final settings = Hive.box('settings');

  final courierKeys = [
    'courierRegistered',
    'courierSyncPending',
    'courierUid',
    'courierUsername',
    'courierPrimaryMobile',
    'courierSecondaryMobile',
    'courierState',
    'courierDistrict',
    'courierNearestTown',
    'courierVehicleCategoryIds',
    'courierOpeningTime',
    'courierClosingTime',
    'courierDescription',
    'courierProfilePhotoUrl',
    'courierRole',
    'courierProfile',
  ];

  for (final key in courierKeys) {
    await settings.delete(key);
  }

  debugPrint(
    'Courier local registration details deleted.',
  );
}

// ============================================================
// LABORATORY PROFILE CLEANUP ON LOGOUT
// ============================================================

Future<void> cleanupLaboratoryOnLogout(
  String uid,
) async {
  final firestore = FirebaseFirestore.instance;

  debugPrint(
    'LABORATORY CLEANUP START: $uid',
  );

  await firestore
      .collection('labs')
      .doc(uid)
      .delete();

  debugPrint(
    'Laboratory Firestore profile deleted.',
  );

  try {
    await firestore
        .collection('liveLocations')
        .doc(uid)
        .delete();

    debugPrint(
      'Laboratory live location deleted.',
    );
  } catch (e) {
    debugPrint(
      'Laboratory live location cleanup failed: $e',
    );
  }


  final labBox = await Hive.openBox(
    'labProfiles',
  );

  await labBox.delete('profile');

  final userBox = await Hive.openBox(
    'userBox',
  );

  final savedUid =
      userBox.get('uid')?.toString();

  final savedRole = userBox
      .get('role')
      ?.toString()
      .trim()
      .toLowerCase();

  if (savedUid == uid &&
      savedRole == 'laboratory') {
    const keys = [
      'uid',
      'name',
      'mobile',
      'secondaryMobile',
      'role',
      'laboratoryState',
      'laboratoryDistrict',
      'laboratoryNearestTown',
      'categories',
    ];

    for (final key in keys) {
      await userBox.delete(key);
    }
  }

  debugPrint(
    'LABORATORY CLEANUP COMPLETE: $uid',
  );
}

Future<void> cleanupGarageOnLogout(String uid) async {

  final firestore = FirebaseFirestore.instance;

  debugPrint('GARAGE CLEANUP START: $uid');

  await firestore
      .collection('garageOwners')
      .doc(uid)
      .delete();

  debugPrint('Garage Firestore profile deleted.');

  try {
    await firestore
        .collection('liveLocations')
        .doc(uid)
        .delete();
  } catch (e) {
    debugPrint('Garage live location cleanup failed: $e');
  }

  final garageBox =
      await Hive.openBox('garageProfiles');

  await garageBox.delete(uid);

  final savedGarageUid =
      garageBox.get('currentUid')?.toString();

  if (savedGarageUid == uid) {
    await garageBox.delete('currentUid');
  }

  final userBox = await Hive.openBox('userBox');

  final savedUid =
      userBox.get('uid')?.toString();

  final savedRole = userBox
      .get('role')
      ?.toString()
      .trim()
      .toLowerCase();

  if (savedUid == uid &&
      (savedRole == 'garage' ||
       savedRole == 'garages')) {

    const keys = [
      'uid',
      'name',
      'mobile',
      'secondaryPhone',
      'role',
      'garageName',
      'garageState',
      'garageDistrict',
      'garageNearestTown',
      'garageIsOpen24Hours',
      'garageOpeningTime',
      'garageClosingTime',
      'garageLocation',
      'garageDescription',
      'categories',
    ];

    for (final key in keys) {
      await userBox.delete(key);
    }
  }

  debugPrint('GARAGE CLEANUP COMPLETE: $uid');
}

Future<void> cleanupMedicalShopOnLogout(String uid) async {
  final firestore = FirebaseFirestore.instance;

  debugPrint('MEDICAL SHOP CLEANUP START: $uid');

  // 1. Delete the Medical Shop Firestore profile.
  await firestore
      .collection('medicalShops')
      .doc(uid)
      .delete();

  debugPrint('Medical Shop Firestore profile deleted.');

  // 2. Delete its live location, if one exists.
  await firestore
      .collection('liveLocations')
      .doc(uid)
      .delete();

  // 3. Clear Medical Shop registration data from Hive.
  // Use the actual box names from your registration code.
  final settingsBox = await Hive.openBox('settings');
  final appBox = await Hive.openBox('appBox');

  const medicalShopKeys = [
    'medicalShop_name',
    'medicalShop_phone',
    'medicalShop_secondaryPhone',
    'medicalShop_shopName',
    'medicalShop_categories',
    'medicalShop_currentLocation',
    'medicalShop_state',
    'medicalShop_district',
    'medicalShop_nearestTown',
    'medicalShop_openingTime',
    'medicalShop_closingTime',
    'medicalShop_isOpen24Hours',
    'medicalShop_profilePhotoUrl',
    'medicalShop_uid',
    'medicalShopUid',
    'medicalShopProfile',
    'medicalShopProfileCompleted',
  ];

  for (final key in medicalShopKeys) {
    await settingsBox.delete(key);
    await appBox.delete(key);
  }

  // 4. Clear common login information only if it belongs
  // to this exact user and Medical Shop role.
  final userBox = await Hive.openBox('userBox');

  final savedUid = userBox.get('uid')?.toString();

  final savedRole = userBox
      .get('role')
      ?.toString()
      .trim()
      .toLowerCase();

  if (savedUid == uid &&
      (savedRole == 'medicalshop' ||
       savedRole == 'medical_shop' ||
       savedRole == 'medical shop')) {
    for (final key in [
      'uid',
      'name',
      'mobile',
      'role',
      'shopName',
      'categories',
    ]) {
      await userBox.delete(key);
    }
  }

  debugPrint('MEDICAL SHOP CLEANUP COMPLETE: $uid');
}

Future<void> cleanupAmbulanceOnLogout(String uid) async {
  final firestore = FirebaseFirestore.instance;
  final settingsBox = Hive.box('settings');

  // 1. Delete Ambulance Firestore profile.
  await firestore
      .collection('ambulances')
      .doc(uid)
      .delete();

  debugPrint('Ambulance Firestore profile deleted.');

  // 2. Delete Ambulance live location.
  try {
    await firestore
        .collection('liveLocations')
        .doc(uid)
        .delete();

    debugPrint('Ambulance live location deleted.');
  } catch (e) {
    debugPrint('Ambulance live location cleanup failed: $e');
  }

  // 3. Clear Ambulance-specific Hive data.
  const keys = [
    'ambulanceUid',
    'ambulanceName',
    'ambulanceMobile',
    'ambulanceSecondaryMobile',
    'ambulanceState',
    'ambulanceDistrict',
    'ambulanceNearestTown',
    'ambulanceRole',
    'ambulanceVehicleName',
    'ambulanceVehicleNumber',
    'ambulanceLocation',
    'ambulanceProfilePhotoUrl',
  ];

  for (final key in keys) {
    await settingsBox.delete(key);
  }

  debugPrint('Ambulance Hive profile data cleared.');
}

Future<void> cleanupRecoveryOnLogout(String uid) async {
  final firestore = FirebaseFirestore.instance;
  final settingsBox = await Hive.openBox('settings');

  // 1. Delete Recovery Driver Firestore profile.
  await firestore
      .collection('recoveryDrivers')
      .doc(uid)
      .delete();

  debugPrint('Recovery Driver Firestore profile deleted.');

  // 2. Delete Recovery Driver live location.
  try {
    await firestore
        .collection('liveLocations')
        .doc(uid)
        .delete();

    debugPrint('Recovery Driver live location deleted.');
  } catch (e) {
    debugPrint('Recovery live location cleanup failed: $e');
  }

  // 3. Clear Recovery-specific Hive data.
  const keys = [
    'recoveryProfile',
    'recoveryUid',
    'recoveryProfileCompleted',
  ];

  for (final key in keys) {
    await settingsBox.delete(key);
  }

  debugPrint('Recovery Driver Hive profile data cleared.');
}

Future<void> cleanupHouseOwnerOnLogout(String uid) async {
  final firestore = FirebaseFirestore.instance;
  final userBox = Hive.box('userBox');

  // 1. Delete House Owner's Firestore profile.
  await firestore
      .collection('houseOwners')
      .doc(uid)
      .delete();

  debugPrint('House Owner Firestore profile deleted.');

  // 2. Clear House Owner's local Hive profile data.
  const keys = [
    'name',
    'mobile',
    'gender',
    'uid',
    'role',
    'ambulanceState',
    'ambulanceDistrict',
    'ambulanceNearestTown',
  ];

  for (final key in keys) {
    await userBox.delete(key);
  }

  debugPrint('House Owner Hive profile data cleared.');
}

Future<void> cleanupStudentOnLogout(String uid) async {
  final firestore = FirebaseFirestore.instance;
  final userBox = Hive.box('userBox');

  // 1. Delete Student's Firestore profile.
  await firestore
      .collection('students')
      .doc(uid)
      .delete();

  debugPrint('Student Firestore profile deleted.');

  // 2. Clear Student's local Hive profile data.
  const keys = [
    'name',
    'mobile',
    'gender',
    'uid',
    'role',
    'ambulanceState',
    'ambulanceDistrict',
    'ambulanceNearestTown',
  ];

  for (final key in keys) {
    await userBox.delete(key);
  }

  debugPrint('Student Hive profile data cleared.');
}

// ==========================================================
// FISH DELIVERY LOGOUT CLEANUP
// Delete the user's profile and remove unused custom categories.
// ==========================================================

Future<void> cleanupFishDeliveryOnLogout(String uid) async {
  final firestore = FirebaseFirestore.instance;

  final profileRef = firestore
      .collection('fishDeliveryGuys')
      .doc(uid);

  // 1. Delete this user's Firestore profile.
  await profileRef.delete();

  // 2. Read all remaining Fish Delivery profiles.
  final remainingProfiles = await firestore
      .collection('fishDeliveryGuys')
      .get();

  // Collect specializations still used by other profiles.
  final Set<String> categoriesStillUsed = {};

  for (final profile in remainingProfiles.docs) {
    final data = profile.data();

    void addNames(dynamic values) {
      if (values is! List) return;

      for (final value in values) {
        final name = value.toString().trim().toLowerCase();
        if (name.isNotEmpty) {
          categoriesStillUsed.add(name);
        }
      }
    }

    addNames(data['specializations']);
    addNames(data['customSpecializations']);

    // Compatibility with older saved profiles.
    addNames(data['selectedItemList']);
  }

  // 3. These five categories must always remain visible.
  const Set<String> defaultCategories = {
    'fish',
    'fruits',
    'vegetables',
    'fruits & vegetables',
    'foods',
  };

  // 4. Delete unused custom specialization definitions.
  final categorySnapshot = await firestore
      .collection('fishDeliverySpecializations')
      .get();

  for (final categoryDoc in categorySnapshot.docs) {
    final data = categoryDoc.data();
    final name = (data['name'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (name.isEmpty) continue;

    // Never delete the five built-in categories.
    if (defaultCategories.contains(name)) continue;

    // Keep this category if another profile still uses it.
    if (categoriesStillUsed.contains(name)) continue;

    // No remaining profile uses this custom category.
    await categoryDoc.reference.delete();
  }

  // 5. Clear the local Fish Delivery profile.
  final fishBox = await Hive.openBox('fishDeliveryProfiles');
  final savedProfile = fishBox.get('currentProfile');

  if (savedProfile is Map &&
      savedProfile['uid']?.toString() == uid) {
    await fishBox.delete('currentProfile');
  }

  // 6. Clear shared login details only if they belong
  // to this Fish Delivery user.
  final userBox = await Hive.openBox('userBox');

  final savedUid = userBox.get('uid')?.toString();
  final savedRole = userBox
      .get('role')
      ?.toString()
      .trim()
      .toLowerCase();

  const fishDeliveryRoles = {
    'fish_delivery',
    'fishdelivery',
    'fish delivery',
  };

  if (savedUid == uid &&
      fishDeliveryRoles.contains(savedRole)) {
    for (final key in [
      'uid',
      'name',
      'username',
      'mobile',
      'mobileNumber',
      'role',
      'state',
      'district',
      'nearestTown',
      'categories',
      'profilePhotoUrl',
    ]) {
      await userBox.delete(key);
    }
  }

  debugPrint(
    'Fish Delivery profile and unused custom categories cleaned up.',
  );
}

Future<void> cleanupFoodDeliveryOnLogout(String uid) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  final DocumentReference<Map<String, dynamic>> profileRef =
      db.collection('foodDeliveryGuys').doc(uid);

  debugPrint('FOOD DELIVERY CLEANUP START: $uid');

  // Built-in category IDs must NEVER be deleted.
  const Set<String> builtInCategoryIds = {
    'bike',
    'auto',
    'car',
    'van',
    'mini_truck',
    'truck',
    'cycle',
  };

  final profileSnapshot = await profileRef.get();
  final profileData = profileSnapshot.data() ?? {};

  final Set<String> categoryIds = {};

  // Current profile format: categories contains category IDs.
  final rawCategories = profileData['categories'];

  if (rawCategories is List) {
    for (final value in rawCategories) {
      final id = value.toString().trim();
      if (id.isNotEmpty) categoryIds.add(id);
    }
  }

  // Also support categoryDetails.
  final rawDetails = profileData['categoryDetails'];

  if (rawDetails is List) {
    for (final value in rawDetails) {
      if (value is Map) {
        final id = value['id']?.toString().trim() ?? '';
        if (id.isNotEmpty) categoryIds.add(id);
      }
    }
  }

  final categoryCollection =
      db.collection('foodDeliveryVehicleCategories');

  final ownedCategories = await categoryCollection
      .where('providerUids', arrayContains: uid)
      .get();

 
  for (final doc in ownedCategories.docs) {
    categoryIds.add(doc.id);
  }

  await profileRef.delete();

  debugPrint('Deleted foodDeliveryGuys/$uid');

  final remainingProfiles = await db
      .collection('foodDeliveryGuys')
      .get();

  final Set<String> categoriesStillUsed = {};

  for (final doc in remainingProfiles.docs) {
    final data = doc.data();

    final profileCategories = data['categories'];

    if (profileCategories is List) {
      for (final value in profileCategories) {
        final id = value.toString().trim();
        if (id.isNotEmpty) categoriesStillUsed.add(id);
      }
    }

    final details = data['categoryDetails'];

    if (details is List) {
      for (final value in details) {
        if (value is Map) {
          final id = value['id']?.toString().trim() ?? '';
          if (id.isNotEmpty) categoriesStillUsed.add(id);
        }
      }
    }
  }

  for (final categoryId in categoryIds) {
    try {
      final categoryRef = categoryCollection.doc(categoryId);
      final categorySnapshot = await categoryRef.get();

      if (!categorySnapshot.exists) continue;

      final data = categorySnapshot.data() ?? {};

      final rawOwners = data['providerUids'];
      final Set<String> remainingOwners = {};

      if (rawOwners is List) {
        for (final owner in rawOwners) {
          final ownerUid = owner.toString().trim();

          if (ownerUid.isNotEmpty && ownerUid != uid) {
            remainingOwners.add(ownerUid);
          }
        }
      }

      final bool isBuiltIn =
          builtInCategoryIds.contains(categoryId);

      if (isBuiltIn) {
        // Keep built-in category documents permanently.
        await categoryRef.set({
          'providerUids': FieldValue.arrayRemove([uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('Preserved built-in category: $categoryId');
        continue;
      }

      final bool usedByAnotherProfile =
          categoriesStillUsed.contains(categoryId);

      if (remainingOwners.isEmpty && !usedByAnotherProfile) {
        await categoryRef.delete();

        debugPrint('Deleted unused custom category: $categoryId');
      } else {
        await categoryRef.set({
          'providerUids': FieldValue.arrayRemove([uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('Preserved category still in use: $categoryId');
      }
    } catch (e) {
      debugPrint(
        'Category cleanup failed for $categoryId: $e',
      );
    }
  }

  final Box profileBox = await Hive.openBox('foodDeliveryProfiles');

  final currentProfile = profileBox.get('currentProfile');

  if (currentProfile is Map &&
      currentProfile['uid']?.toString() == uid) {
    await profileBox.delete('currentProfile');
  }

  // Clear role-specific common login fields only when this
  // Hive userBox belongs to the same Food Delivery rider.
  final Box userBox = await Hive.openBox('userBox');

  final savedUid = userBox.get('uid')?.toString() ?? '';
  final savedRole =
      userBox.get('role')?.toString().trim().toLowerCase() ?? '';

  if (savedUid == uid &&
      ['food_delivery', 'fooddelivery', 'food delivery']
          .contains(savedRole)) {
    const keysToDelete = [
      'uid',
      'name',
      'username',
      'mobile',
      'mobileNumber',
      'secondaryMobileNumber',
      'role',
      'serviceType',
      'state',
      'district',
      'nearestTown',
      'categories',
      'categoryDetails',
      'vehicleNumber',
      'vehicleNumberDisplay',
      'vehicleNumberColor',
      'profilePhotoUrl',
      'currentLocationName',
      'currentLocationLatitude',
      'currentLocationLongitude',
    ];

    for (final key in keysToDelete) {
      await userBox.delete(key);
    }
  }

  debugPrint('FOOD DELIVERY CLEANUP COMPLETE: $uid');
}

Future<void> cleanupSelfEmployeeOnLogout(String uid) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  debugPrint('SELF EMPLOYEE CLEANUP START: $uid');

  // 1. Delete this user's self-employed Firestore profile.
  await db.collection('selfEmployees').doc(uid).delete();

  // 2. Clear self-employed data from Hive, but only for this user.
  final Box userBox = await Hive.openBox('userBox');

  final String savedUid = userBox.get('uid')?.toString() ?? '';
  final String savedRole =
      userBox.get('role')?.toString().trim().toLowerCase() ?? '';

  if (savedUid == uid && savedRole == 'self_employee') {
    const List<String> keysToDelete = [
      'uid',
      'name',
      'mobile',
      'role',
      'state',
      'district',
      'nearestTown',
      'categories',
      'category',
      'experience',
      'profilePhotoUrl',
      'selfEmployeeCurrentLocationName',
      'selfEmployeeCurrentLocationLatitude',
      'selfEmployeeCurrentLocationLongitude',
    ];

    for (final String key in keysToDelete) {
      await userBox.delete(key);
    }
  }

  debugPrint('SELF EMPLOYEE CLEANUP COMPLETE: $uid');
}

Future<void> cleanupFreelancerOnLogout(String uid) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  debugPrint('FREELANCER CLEANUP START: $uid');

  // 1. Delete the complete public freelancer profile.
  await db.collection('freelancers').doc(uid).delete();

  // 2. Clear freelancer-specific local data only
  //    if this UID belongs to the current local profile.
  final Box userBox = await Hive.openBox('userBox');

  final String? savedUid = userBox.get('uid')?.toString();
  final String savedRole =
      userBox.get('role')?.toString().trim().toLowerCase() ?? '';

  if (savedUid == uid && savedRole == 'freelancer') {
    const List<String> keysToDelete = [
      'uid',
      'name',
      'mobile',
      'state',
      'district',
      'nearestTown',
      'role',
      'categories',
      'experience',
      'profilePhotoUrl',
      'currentLocationName',
      'currentLocationLatitude',
      'currentLocationLongitude',
    ];

    for (final key in keysToDelete) {
      await userBox.delete(key);
    }
  }

  debugPrint('FREELANCER CLEANUP COMPLETE: $uid');
}

Future<void> cleanupWorkerOnLogout(String uid) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final workerRef = db.collection('workers').doc(uid);

  // Standard categories must remain available even when unused.
  const Set<String> standardCategories = {
    'ac technician',
    'aluminium worker',
    'appliance repair',
    'baker',
    'beautician',
    'bike mechanic',
    'car mechanic',
    'carpenter',
    'care taker',
    'cctv technician',
    'chef',
    'computer technician',
    'construction worker',
    'cook',
    'delivery worker',
    'driver',
    'electrician',
    'electrician helper',
    'fabricator',
    'flooring worker',
    'glass worker',
    'gardener',
    'hairdresser',
    'house cleaner',
    'interior worker',
    'laundry worker',
    'maid',
    'mason',
    'mechanic',
    'mobile repair technician',
    'network technician',
    'nurse',
    'office cleaner',
    'painter',
    'pest control technician',
    'physiotherapist',
    'plaster worker',
    'plumber',
    'plumber helper',
    'refrigerator technician',
    'roofer',
    'ro water purifier technician',
    'security guard',
    'solar technician',
    'tailor',
    'tile worker',
    'tv technician',
    'watchman',
    'welder',
  };

  debugPrint('WORKER CLEANUP START: $uid');

  // Read the profile first so we can find its categories.
  final workerSnapshot = await workerRef.get();
  final workerData =
      workerSnapshot.data() ?? <String, dynamic>{};

  final Set<String> categoryNames = {};

  final dynamic savedCategories = workerData['categories'];
  if (savedCategories is List) {
    for (final value in savedCategories) {
      final name = value.toString().trim();
      if (name.isNotEmpty) categoryNames.add(name);
    }
  }

  // Find category documents explicitly owned by this worker.
  final ownedSnapshot = await db
      .collection('workerCategories')
      .where('workerUids', arrayContains: uid)
      .get();

  final Map<String, DocumentReference<Map<String, dynamic>>>
      categoryRefs = {};

  for (final doc in ownedSnapshot.docs) {
    categoryRefs[doc.id] = doc.reference;
    final name = doc.data()['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) categoryNames.add(name);
  }

  // Include categories from the profile in case the registry
  // does not contain this worker's UID yet.
  for (final name in categoryNames) {
    final id = Uri.encodeComponent(name.toLowerCase().trim());
    categoryRefs.putIfAbsent(
      id,
      () => db.collection('workerCategories').doc(id),
    );
  }

  // Delete the public worker profile.
  await workerRef.delete();

  // Remove this worker from each category registry.
//   for (final entry in categoryRefs.entries) {
//     await db.runTransaction((transaction) async {
//       final ref = entry.value;
//       final snapshot = await transaction.get(ref);

//       if (!snapshot.exists) return;

//       final data = snapshot.data() ?? <String, dynamic>{};

//       final List<String> owners =
//           (data['workerUids'] as List?)
//                   ?.map((value) => value.toString())
//                   .toList() ??
//               <String>[];

//       owners.removeWhere((ownerUid) => ownerUid == uid);

//       final String name =
//           (data['name'] ?? '').toString().trim();

//       final bool isStandard =
//           standardCategories.contains(name.toLowerCase());

//       // Delete unused custom categories. Preserve standard ones.
//       // if (!isStandard && owners.isEmpty) {
//       //   transaction.delete(ref);
//       // } 
//       if (!isStandard &&
//     owners.isEmpty &&
//     !categoriesStillUsed.contains(name.toLowerCase())) {
//   transaction.delete(ref);
// }else {
//         transaction.set(
//           ref,
//           {
//             'workerUids': owners,
//             'updatedAt': FieldValue.serverTimestamp(),
//           },
//           SetOptions(merge: true),
//         );
//       }
//     });
//   }
// Get categories still used by the remaining workers.
final remainingWorkers =
    await db.collection('workers').get();

final Set<String> categoriesStillUsed = {};

for (final doc in remainingWorkers.docs) {
  final data = doc.data();
  final dynamic categories = data['categories'];

  if (categories is List) {
    for (final category in categories) {
      final normalizedName =
          category.toString().trim().toLowerCase();

      if (normalizedName.isNotEmpty) {
        categoriesStillUsed.add(normalizedName);
      }
    }
  }
}

// Remove this worker from category ownership.
// Delete only unused custom categories.
for (final entry in categoryRefs.entries) {
  await db.runTransaction((transaction) async {
    final ref = entry.value;
    final snapshot = await transaction.get(ref);

    if (!snapshot.exists) return;

    final data = snapshot.data() ?? <String, dynamic>{};

    final String name =
        (data['name'] ?? '').toString().trim();

    final String normalizedName = name.toLowerCase();

    final List<String> owners =
        (data['workerUids'] as List?)
                ?.map((value) => value.toString())
                .toList() ??
            <String>[];

    owners.removeWhere((ownerUid) => ownerUid == uid);

    final bool isDefaultCategory =
        standardCategories.contains(normalizedName);

    final bool isUsedByAnotherWorker =
        categoriesStillUsed.contains(normalizedName);

    if (!isDefaultCategory &&
        owners.isEmpty &&
        !isUsedByAnotherWorker) {
      transaction.delete(ref);
    } else {
      transaction.set(
        ref,
        {
          'workerUids': owners,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  });
}

  // Clear worker-specific local profile data.
  final Box workerBox = await Hive.openBox('workerProfiles');
  await workerBox.delete(uid);

  if (workerBox.get('currentUid') == uid) {
    await workerBox.delete('currentUid');
  }

  final Box userBox = await Hive.openBox('userBox');

  // if (userBox.get('uid')?.toString() == uid ||
  //     userBox.get('role')?.toString().toLowerCase() == 'worker') {
  if (userBox.get('uid')?.toString() == uid &&
    userBox.get('role')?.toString().trim().toLowerCase() ==
        'worker') {
    const keys = [
      'uid',
      'name',
      'mobile',
      'workerSecondaryPhone',
      'workerState',
      'workerDistrict',
      'workerNearestTown',
      'workerCurrentLocationName',
      'workerCurrentLocationLatitude',
      'workerCurrentLocationLongitude',
      'role',
      'gender',
      'categories',
      'experience',
    ];

    for (final key in keys) {
      await userBox.delete(key);
    }
  }

  debugPrint('WORKER CLEANUP COMPLETE: $uid');
}

Future<void> cleanupTeaShopOnLogout(String uid) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  debugPrint('TEA SHOP CLEANUP START: $uid');

  const Set<String> builtInCategories = {
    'coffee shops',
    'tea shops',
    'hotel',
    'restaurants',
    'thattukada',
  };

  final profileRef = db.collection('tea_shops').doc(uid);

  final profileSnapshot = await profileRef.get();

  final Set<String> profileCategories = {};

  void collectCategories(dynamic value) {
    if (value is List) {
      for (final item in value) {
        final name = item.toString().trim();
        if (name.isNotEmpty) {
          profileCategories.add(name);
        }
      }
    } else if (value is String) {
      for (final item in value.split(',')) {
        final name = item.trim();
        if (name.isNotEmpty) {
          profileCategories.add(name);
        }
      }
    }
  }

  if (profileSnapshot.exists) {
    final data = profileSnapshot.data() ?? {};

    collectCategories(data['categories']);
    collectCategories(data['category']);
  }

  final ownedSnapshot = await db
      .collection('teaShopCategories')
      .where('teaShopUids', arrayContains: uid)
      .get();

  final Map<String, DocumentReference<Map<String, dynamic>>>
      categoriesToClean = {};

  for (final doc in ownedSnapshot.docs) {
    categoriesToClean[doc.id] = doc.reference;
  }

  // Also include categories from the user's profile.
  for (final name in profileCategories) {
    final categoryId =
        Uri.encodeComponent(name.trim().toLowerCase());

    final categoryRef =
        db.collection('teaShopCategories').doc(categoryId);

    categoriesToClean[categoryId] = categoryRef;
  }

  if (profileSnapshot.exists) {
    await profileRef.delete();

    debugPrint('Deleted tea_shops/$uid');
  }

  final remainingShops = await db
      .collection('tea_shops')
      .get();

  final Set<String> categoriesStillUsed = {};

  for (final shop in remainingShops.docs) {
    final data = shop.data();

    final dynamic categories = data['categories'];

    if (categories is List) {
      for (final item in categories) {
        final name = item.toString().trim().toLowerCase();

        if (name.isNotEmpty) {
          categoriesStillUsed.add(name);
        }
      }
    }

    final dynamic oldCategory = data['category'];

    if (oldCategory is String) {
      for (final item in oldCategory.split(',')) {
        final name = item.trim().toLowerCase();

        if (name.isNotEmpty) {
          categoriesStillUsed.add(name);
        }
      }
    } else if (oldCategory is List) {
      for (final item in oldCategory) {
        final name = item.toString().trim().toLowerCase();

        if (name.isNotEmpty) {
          categoriesStillUsed.add(name);
        }
      }
    }
  }

  for (final entry in categoriesToClean.entries) {
    await db.runTransaction((transaction) async {
      final ref = entry.value;

      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) return;

      final data = snapshot.data() ?? {};

      final List<String> owners =
          (data['teaShopUids'] as List?)
                  ?.map((item) => item.toString())
                  .toList() ??
              <String>[];

      // Remove only the current user's UID.
      owners.removeWhere((ownerUid) => ownerUid == uid);

      final String categoryName =
          (data['name'] ?? '').toString().trim();

      final String normalizedName =
          categoryName.toLowerCase();

      final bool isBuiltIn =
          builtInCategories.contains(normalizedName);

      final bool isCustom =
          data['isCustom'] == true && !isBuiltIn;

      final bool usedByAnotherShop =
          categoriesStillUsed.contains(normalizedName);

      if (isCustom &&
          owners.isEmpty &&
          !usedByAnotherShop) {
        transaction.delete(ref);

        debugPrint(
          'Deleted unused custom category: $categoryName',
        );
      } else {
        // Preserve built-in categories and categories
        // belonging to or used by other Tea Shops.

        transaction.set(
          ref,
          {
            'teaShopUids': owners,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        debugPrint(
          'Preserved category: $categoryName',
        );
      }
    });
  }


  final Box box = Hive.isBoxOpen('appSettings')
      ? Hive.box('appSettings')
      : await Hive.openBox('appSettings');

  const List<String> keysToDelete = [
    'teaShopRegistered'
    'teaShopUsername',
    'teaShopName',
    'teaShopMobile',
    'teaShopSecondaryMobile',
    'teaShopState',
    'teaShopDistrict',
    'teaShopNearestTown',
    'teaShopCategory',
    'teaShopCategories',
    'teaShopOpeningTime',
    'teaShopClosingTime',
    'teaShopIsOpen24Hours',
    'teaShopDescription',
    'teaShopRole',
    'teaShopUid',
    'teaShopLatitude',
    'teaShopLongitude',
    'teaShopProfilePhotoUrl',
  ];

  for (final key in keysToDelete) {
    await box.delete(key);
  }

  debugPrint('TEA SHOP HIVE DATA CLEARED.');

  debugPrint(
    'TEA SHOP CLEANUP SUCCESS: $uid',
  );
}

Future<void> cleanupCompanyOnLogout(String uid) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  try {
    debugPrint('COMPANY LOGOUT CLEANUP START: $uid');

    final categoryCollection =
        db.collection('company_categories');

    final ownedCategories = await categoryCollection
        .where('companyUids', arrayContains: uid)
        .get();

    for (final doc in ownedCategories.docs) {
      await db.runTransaction((transaction) async {
        final current = await transaction.get(doc.reference);

        if (!current.exists) return;

        final data = current.data() ?? <String, dynamic>{};

        final List<String> owners = List<String>.from(
          (data['companyUids'] as List? ?? const [])
              .map((item) => item.toString()),
        );

        // Remove only this company.
        owners.removeWhere((companyUid) => companyUid == uid);

        if (data['isCustom'] == true && owners.isEmpty) {
          // Delete the custom category only when nobody uses it.
          transaction.delete(doc.reference);
        } else {
          // Keep built-in categories and shared custom categories.
          transaction.update(doc.reference, {
            'companyUids': owners,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    }

    await db.collection('companies').doc(uid).delete();

    final Box settingsBox = Hive.box('settings');

    const List<String> companyKeys = [
      'companyName',
      'companyOwnerName',
      'companyMobile',
      'companySecondaryMobile',
      'companyState',
      'companyDistrict',
      'companyNearestTown',
      'companyRole',
      'companyCategories',
      'companyCategory',
      'companyExperience',
      'companyIsOpen24Hours',
      'companyOpeningTime',
      'companyClosingTime',
      'companyUid',
      'companyLocation',
      'companyProfilePhotoUrl',
    ];

    for (final key in companyKeys) {
      await settingsBox.delete(key);
    }

    debugPrint('COMPANY LOGOUT CLEANUP SUCCESS: $uid');
  } catch (e, stackTrace) {
    debugPrint('COMPANY LOGOUT CLEANUP ERROR: $e');
    debugPrint('$stackTrace');
    rethrow;
  }
}

Future<void> cleanupClinicOnLogout(String uid) async {
  final db = FirebaseFirestore.instance;

  debugPrint('CLINIC CLEANUP START: $uid');

  final clinicRef = db.collection('clinics').doc(uid);

  // Read the profile before deleting it.
  final clinicSnapshot = await clinicRef.get();

  if (clinicSnapshot.exists) {
    final data = clinicSnapshot.data() ?? {};


    final username =
        (data['username'] ?? '').toString().trim().toLowerCase();

    if (username.isNotEmpty) {
      final usernameRef =
          db.collection('clinicUsernames').doc(username);

      await db.runTransaction((transaction) async {
        final usernameSnapshot =
            await transaction.get(usernameRef);

        if (!usernameSnapshot.exists) return;

        final usernameData = usernameSnapshot.data();

        if (usernameData?['clinicId']?.toString() == uid) {
          transaction.delete(usernameRef);
        }
      });
    }
  }
  final categoryCollection =
      db.collection('clinic_categories');

  final ownedCategories = await categoryCollection
      .where('clinicUids', arrayContains: uid)
      .get();

  for (final categoryDoc in ownedCategories.docs) {
    await db.runTransaction((transaction) async {
      final current =
          await transaction.get(categoryDoc.reference);

      if (!current.exists) return;

      final categoryData = current.data();

      if (categoryData == null) return;

      final owners = List<String>.from(
        categoryData['clinicUids'] ?? const <String>[],
      );

      owners.removeWhere((owner) => owner == uid);

      final bool isCustom =
          categoryData['isCustom'] == true;

      if (isCustom && owners.isEmpty) {
        // Delete a custom category when its last clinic leaves.
        transaction.delete(categoryDoc.reference);
      } else {
        // Keep built-in categories even when their count is zero.
        transaction.set(
          categoryDoc.reference,
          {
            'clinicUids': owners,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  await clinicRef.delete();

  await db.collection('liveLocations').doc(uid).delete();

  final userBox = await Hive.openBox('userBox');

  final savedUid = userBox.get('uid')?.toString() ?? '';

  final savedRole = userBox
      .get('role')
      ?.toString()
      .trim()
      .toLowerCase();

  if (savedUid == uid && savedRole == 'clinic') {
    const keys = [
      'username',
      'clinicName',
      'mobile',
      'secondaryMobile',
      'ambulanceState',
      'ambulanceDistrict',
      'ambulanceNearestTown',
      'role',
      'categories',
      'openingTime',
      'closingTime',
      'isOpen24Hours',
      'garageLocation',
      'uid',
    ];

    for (final key in keys) {
      await userBox.delete(key);
    }
  }

  debugPrint('CLINIC CLEANUP COMPLETE: $uid');
}

Future<void> cleanupDoctorOnLogout(String uid) async {
  final firestore = FirebaseFirestore.instance;
  final doctorRef = firestore.collection('doctors').doc(uid);

  const builtInCategories = <String>{
    'allopathy',
    'ayurvedic',
    'homeopathy',
    'unani',
  };

  try {

    final doctorSnapshot = await doctorRef.get();

    if (doctorSnapshot.exists) {
      final data = doctorSnapshot.data() ?? {};

      final rawCategories = data['categories'];
      final categories = rawCategories is List
          ? rawCategories.whereType<String>().toList()
          : <String>[];

      await doctorRef.delete();
      for (final category in categories) {
        final categoryName = category.trim();

        if (categoryName.isEmpty ||
            builtInCategories.contains(
              categoryName.toLowerCase(),
            )) {
          continue;
        }

        final categoryId = Uri.encodeComponent(
          categoryName.toLowerCase(),
        );

        final categoryRef = firestore
            .collection('doctorCategories')
            .doc(categoryId);

        final categorySnapshot = await categoryRef.get();

        if (!categorySnapshot.exists) continue;

        final categoryData = categorySnapshot.data() ?? {};

        // Only delete a category whose creator is this doctor.
        // Legacy documents without createdByUid are preserved.
        if (categoryData['createdByUid'] != uid) continue;

        // Check whether any remaining doctor still uses it.
        final remainingDoctors = await firestore
            .collection('doctors')
            .where(
              'categories',
              arrayContains: categoryName,
            )
            .limit(1)
            .get();

        if (remainingDoctors.docs.isNotEmpty) {
          debugPrint(
            'Keeping shared category: $categoryName',
          );
          continue;
        }


        final specializationSnapshot = await firestore
            .collection('doctorSpecializations')
            .where(
              'categoryId',
              isEqualTo: categoryId,
            )
            .get();

        // Delete in batches to stay below Firestore's write limit.
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


        await categoryRef.delete();

        debugPrint(
          'Deleted doctor-created category: $categoryName',
        );
      }
    }

    final appBox = Hive.box('appBox');

    const doctorKeys = <String>[
      'doctorName',
      'doctorPhone',
      'doctorSecondaryPhone',
      'doctorGender',
      'doctorCategories',
      'doctorSpecializations',
      'doctorSpecializationsByCategory',
      'doctorState',
      'doctorDistrict',
      'doctorNearestCity',
      'doctorConsultationTime',
      'doctorLatitude',
      'doctorLongitude',
      'doctorLocationAddress',
      'doctorWorkingDays',
      'doctorFirestoreData',
      'doctorSyncPending',
      'doctorSyncUid',
    ];

    for (final key in doctorKeys) {
      await appBox.delete(key);
    }

    debugPrint(
      'Doctor profile and local cache cleanup completed: $uid',
    );
  } catch (e, stackTrace) {
    debugPrint('DOCTOR LOGOUT CLEANUP ERROR: $e');
    debugPrint('$stackTrace');

    // Do not silently report cleanup as successful.
    rethrow;
  }
}
// ============================================================
// REMOVE COMPANY CATEGORY OWNERSHIP ON LOGOUT
// ============================================================

Future<void> removeCompanyCategoriesOnLogout(
  String uid,
) async {
  final firestore = FirebaseFirestore.instance;

  final snapshot = await firestore
      .collection('company_categories')
      .where('companyUids', arrayContains: uid)
      .get();

  for (final categoryDocument in snapshot.docs) {
    await firestore.runTransaction((transaction) async {
      final current = await transaction.get(
        categoryDocument.reference,
      );

      if (!current.exists) return;

      final data = current.data();

      if (data == null) return;

      final owners = List<String>.from(
        data['companyUids'] ?? const <String>[],
      );

      owners.removeWhere((owner) => owner == uid);

      final bool isCustom = data['isCustom'] == true;

      if (isCustom && owners.isEmpty) {
        // Delete only an unused custom category.
        transaction.delete(categoryDocument.reference);
      } else {
        // Preserve default categories and categories
        // that still have other registered owners.
        transaction.update(categoryDocument.reference, {
          'companyUids': owners,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  debugPrint(
    'Company category ownership cleanup completed: $uid',
  );
}

// ============================================================
// REMOVE THIS WORKER'S CUSTOM CATEGORY OWNERSHIP ON LOGOUT
// ============================================================

Future<void> removeWorkerCategoriesOnLogout(
  String uid,
) async {
  final workerRef =
      FirebaseFirestore.instance.collection('workers').doc(uid);

  // Read the worker's categories before changing the profile.
  final workerSnapshot = await workerRef.get();

  if (!workerSnapshot.exists) return;

  final data = workerSnapshot.data();
  if (data == null) return;

  final categories = List<String>.from(
    data['categories'] ?? [],
  );

  // Mark this worker offline first.
  await workerRef.update({
    'isOnline': false,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  for (final category in categories) {
    final categoryId =
        Uri.encodeComponent(category.toLowerCase().trim());

    final categoryRef = FirebaseFirestore.instance
        .collection('workerCategories')
        .doc(categoryId);

    await FirebaseFirestore.instance.runTransaction(
      (transaction) async {
        final snapshot = await transaction.get(categoryRef);

        if (!snapshot.exists) return;

        final categoryData = snapshot.data();
        if (categoryData == null) return;

        // Older category documents may not have ownership tracking.
        if (!categoryData.containsKey('workerUids')) return;

        final owners = List<String>.from(
          categoryData['workerUids'] ?? [],
        );

        // Remove only the worker who is logging out.
        owners.removeWhere((ownerUid) => ownerUid == uid);

        if (owners.isEmpty) {
          // No workers remain associated with this category.
          transaction.delete(categoryRef);
        } else {
          // Keep the category for its other owners.
          transaction.update(categoryRef, {
            'workerUids': owners,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      },
    );
  }

  debugPrint(
    'Worker logged out; unused category ownership cleaned up.',
  );
}

// ==========================================================
// DELETE FOOD DELIVERY PROFILE
// ==========================================================

Future<void> deleteFoodDeliveryProfile(String uid) async {
  final firestore = FirebaseFirestore.instance;

  final profileRef =
      firestore.collection('foodDeliveryGuys').doc(uid);

  final categoryCollection =
      firestore.collection('foodDeliveryVehicleCategories');

  final profileSnapshot = await profileRef.get();

  if (!profileSnapshot.exists) return;

  final data = profileSnapshot.data();

  final categories = List<String>.from(
    data?['categories'] ?? const [],
  );

  // Remove the provider profile first so the counts update.
  await profileRef.delete();

  // Remove this provider's ownership from each category.
  for (final categoryId in categories.toSet()) {
    final categoryRef = categoryCollection.doc(categoryId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(categoryRef);

      if (!snapshot.exists) return;

      final categoryData = snapshot.data();

      if (categoryData == null) return;

      final owners = List<String>.from(
        categoryData['providerUids'] ?? const [],
      );

      if (!owners.contains(uid)) return;

      owners.remove(uid);

      if (owners.isEmpty &&
          categoryData['isCustom'] == true) {
        transaction.delete(categoryRef);
      } else {
        transaction.update(categoryRef, {
          'providerUids': owners,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // Remove the provider's live-location document too.
  await firestore
      .collection('liveLocations')
      .doc(uid)
      .delete();

  debugPrint('Food Delivery profile deleted: $uid');
}

// ============================================================
// REAL-TIME COUNT OF AVAILABLE DOCTORS
// ============================================================

Stream<int> getAvailableDoctorsCount() {
  return FirebaseFirestore.instance
      .collection('doctors')
      .where('isOnline', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}

void _listenToSelfEmployeeRegisteredCount() {
  _onlineCountSubscriptions['Self Employed']?.cancel();

  _onlineCountSubscriptions['Self Employed'] =
      firestore
          .collection('selfEmployees')
          .where('isOnline', isEqualTo: true)
          .snapshots()
          .listen(
    (snapshot) {
      if (!mounted) return;

      setState(() {
        _serviceCounts['Self Employed'] =
            snapshot.docs.length;
      });

      debugPrint(
        'ONLINE SELF EMPLOYEE COUNT: ${snapshot.docs.length}',
      );
    },
    onError: (Object error) {
      debugPrint(
        'Self Employed count error: $error',
      );
    },
  );
}
  // ==========================================================
  // MENU ITEM
  // ==========================================================

  Widget _menuItem({
  required IconData icon,
  required String title,
  required VoidCallback onTap,

  Color? iconColor,
  Color? textColor,
}) {
  final Color finalIconColor =
      iconColor ?? Colors.red;

  final Color finalTextColor =
      textColor ?? const Color(0xFF1A1A1A);

  return Material(
    color: Colors.transparent,

    child: InkWell(
      borderRadius:
          BorderRadius.circular(20),

      onTap: onTap,

      child: Ink(
        height: 70,

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(20),

          border: Border.all(
            color: Colors.grey.shade200,
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: 0.035),

              blurRadius: 12,

              offset:
                  const Offset(0, 4),
            ),
          ],
        ),

        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 22,
          ),

          child: Row(
            children: [

              // =========================================
              // ICON BACKGROUND
              // =========================================

              Container(
                width: 60,
                height: 60,

                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFF0F0),

                  borderRadius:
                      BorderRadius.circular(20),
                ),

                child: Icon(
                  icon,

                  size: 25,

                  color:
                      finalIconColor,
                ),
              ),

              const SizedBox(width: 28),


              // =========================================
              // TITLE
              // =========================================

              Expanded(
                child: Text(
                  title,

                  style: TextStyle(
                    fontSize: 15,

                    fontWeight:
                        FontWeight.w500,

                    color:
                        finalTextColor,
                  ),
                ),
              ),


              // =========================================
              // RIGHT ARROW
              // =========================================

              const Icon(
                Icons.chevron_right,

                size: 34,

                color:
                    Color(0xFF777777),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  // ==========================================================
  // SIDE MENU
  // ==========================================================

 Widget sideMenu() {
  return Drawer(
    width: MediaQuery.of(context).size.width * 0.88,
    backgroundColor: const Color(0xFFF7F7F7),

    child: SafeArea(
      child: Column(
        children: [

          // =====================================================
          // MAIN CONTENT
          // =====================================================

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                22,
                16,
                22,
                16,
              ),

              children: [

                // =================================================
                // PROFILE HEADER CARD
                // =================================================

                _profileHeaderCard(),

                const SizedBox(height: 24),


                // =================================================
                // PROFILE
                // =================================================

                _menuItem(
                  icon: Icons.person_outline,
                  title: AppLocalizations.of(context)!.profile,
                  //'Profile',

                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                             CommonProfileScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),


                // =================================================
                // MY BOOKINGS
                // =================================================

                _menuItem(
                  icon: Icons.calendar_month_outlined,
                  title: 'My Bookings',

                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const MenuInformationScreen(
                          title: 'My Bookings',
                          icon: Icons.calendar_month,
                          message:
                              'Your bookings will appear here.',
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),


                // =================================================
                // MESSAGES
                // =================================================

                _menuItem(
                  icon: Icons.chat_bubble_outline,
                  title: 'Messages',

                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ScreenMessage(
                          chatUser: {
                            'name': 'User',
                            'locationName':
                                'Location not available',
                            'profession': '',
                            'experience': '',
                            'distance': 0.0,
                            'isActive': false,
                          },
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),


                // =================================================
                // NOTIFICATIONS
                // =================================================

                _menuItem(
                  icon: Icons.notifications_none,
                  title: 'Notifications',

                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const MenuInformationScreen(
                          title: 'Notifications',
                          icon: Icons.notifications_none,
                          message:
                              'Your notifications will appear here.',
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),


                // =================================================
                // SETTINGS
                // =================================================

                _menuItem(
                  icon: Icons.settings_outlined,
                  title:    AppLocalizations.of(context)!.settings,
                  //'Settings',
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SettingsMenuScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),


                // =================================================
                // LANGUAGE
                // =================================================

                _menuItem(
                  icon: Icons.language,
                  title: 
                  AppLocalizations.of(context)!.languages,
                  //'Languages',
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ScreenLanguage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),


                // =================================================
                // HELP & SUPPORT
                // =================================================

                _menuItem(
                  icon: Icons.help_outline,
                  title: AppLocalizations.of(context)!.helpSupport,
                  //'Help & Support',
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const HelpSupportScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),


                // =================================================
                // ABOUT PEOPLE BRIDGE
                // =================================================

                _menuItem(
                  icon: Icons.info_outline,
                  title: AppLocalizations.of(context)!.aboutPeopleBridge,
                  // 'About People Bridge',

                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AboutCitizenIndiaScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),


                // =================================================
                // LOGOUT
                // =================================================

                _menuItem(
                  icon: Icons.logout,
                  title:AppLocalizations.of(context)!.logout,
                  //'Logout',

                  iconColor: Colors.red,
                  textColor: Colors.red,

                  onTap: showLogoutDialog,
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
Widget _profileHeaderCard() {
  return Container(
    width: double.infinity,

    padding: const EdgeInsets.all(20),

    decoration: BoxDecoration(
      color: Colors.white,

      borderRadius: BorderRadius.circular(22),

      border: Border.all(
        color: Colors.grey.shade200,
      ),

      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha:  0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),

    child: Row(
      children: [

        // ===============================================
        // PROFILE ICON BOX
        // ===============================================

        Container(
          width: 72,
          height: 72,

          decoration: BoxDecoration(
            color: const Color(0xFFFFEEEE),

            borderRadius: BorderRadius.circular(22),
          ),

          child: const Icon(
            Icons.person,
            color: Colors.red,
            size: 40,
          ),
        ),

        const SizedBox(width: 18),


        // ===============================================
        // PROFILE TEXT
        // ===============================================

         Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text( AppLocalizations.of(context)!.yourProfile,
              //  'Your Profile',

                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF161616),
                ),
              ),

              SizedBox(height: 7),

              Text(
                'View or edit your profile',

                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  // ==========================================================
  // TOP SECTION
  // ==========================================================

  Widget topSection() {

    return Padding(

      padding:
          const EdgeInsets.fromLTRB(
        20,
        15,
        20,
        10,
      ),

      child: Column(
        children: [

          Row(
            children: [

              IconButton(

                icon:
                    const Icon(
                  Icons.menu,
                  size: 30,
                ),

                onPressed: () {

                  _scaffoldKey.currentState
                      ?.openDrawer();
                },
              ),


              const SizedBox(
                width: 10,
              ),


              Expanded(
                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    RichText(

                      text:
                           TextSpan(

                        children: [

                          TextSpan(

                            text:
                                'PEOPLE\n',

                            style:
                                TextStyle(

                              fontSize:
                                  28,

                              fontWeight:
                                  FontWeight.bold,

                              color:
                                  Colors.red,
                            ),
                          ),

                          TextSpan(

                            text:
                                'BRIDGE',

                            style:
                                TextStyle(

                              fontSize:
                                  20,

                              fontWeight:
                                  FontWeight.bold,

                              color:
                                  Color(0xFF138808),
                            ),
                          ),
                        ],
                      ),
                    ),


                     Text(
                      AppLocalizations.of(context)!.opportunitiesforEveryone,
                     // 'Opportunities for Everyone',
                      style:
                          TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),


              IconButton(

                icon:
                    const Icon(
                  Icons.notifications_none,
                  size: 30,
                ),

                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const MenuInformationScreen(
                        title:
                            'Notifications',
                        icon:
                            Icons.notifications_none,
                        message:
                            'Your notifications will appear here.',
                      ),
                    ),
                  );
                },
              ),


              GestureDetector(

                onTap: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const CommonProfileScreen(),
                    ),
                  );
                },

              
                child: ValueListenableBuilder(
  valueListenable: Hive.box('userBox').listenable(),
  builder: (
    context,
    Box box,
    _,
  ) {
    final photoUrl = box
        .get(
          'profilePhotoUrl',
          defaultValue: '',
        )
        .toString()
        .trim();

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFFFF7EF),
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Icon(
                    Icons.person,
                    color: Color(0xFF138808),
                  );
                },
              )
            : const Icon(
                Icons.person,
                color: Color(0xFF138808),
              ),
      ),
    );
  },
),
               
              ),
            ],
          ),


          const SizedBox(
            height: 15,
          ),


          // ==================================================
// LIVE LOCATION BUTTON
// ==================================================

Align(
  alignment: Alignment.centerLeft,
  child: ElevatedButton.icon(
    onPressed: _loadingLocation
        ? null
        : () {
            if (_liveLocationRequested) {
              stopLiveLocation();
            } else {
              startLiveLocation();
            }
          },

    icon: _loadingLocation
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Icon(
            _liveLocationRequested
                ? Icons.location_on
                : Icons.location_off,
          ),

    label: Text(
      _loadingLocation
          ?  AppLocalizations.of(context)!.pleasewait
         // 'Please wait...'
          : _liveLocationRequested
              ? AppLocalizations.of(context)!.liveLocationON
             // 'LIVE Location ON'
              : AppLocalizations.of(context)!.turnOnLiveLocation
              //'Turn ON LIVE Location',
    ),

    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,

      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 16,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
  ),
),

        ],
      ),
    );
  }

// ==========================================================
// FLOATING BOTTOM NAVIGATION
// ==========================================================

Widget bottomNavigationBar() {
  return Positioned(
    left: 16,
    right: 14,
    bottom: 8,
    child: SafeArea(
      top: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // THREE BUTTON CURVED SECTION
          Expanded(
            child: Container(
              height: 63,
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x28000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // HOME
                  Expanded(
                    child: bottomItem(
                      Icons.home_outlined,
                       AppLocalizations.of(context)!.home,
                   //   'Home',
                      true,
                    ),
                  ),

                  // MESSAGES
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                    
                      onTap: () async {
  final bool isEnabled =
      await _checkLiveLocationBeforeNavigation();

  if (!mounted) return;

  if (!isEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
        content: Text(
           AppLocalizations.of(context)!.liveLocationonButton
         // 'Please turn ON LIVE location from the Home page first.',
        ),
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const ScreenChat(),
    ),
  );
},
                      child: bottomItem(
                        Icons.chat_bubble_outline,
                        AppLocalizations.of(context)!.messages,
                       // 'Messages',
                        false,
                      ),
                    ),
                  ),

                  // LANGUAGE
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                    
                      onTap: () async {
  final bool isEnabled =
      await _checkLiveLocationBeforeNavigation();

  if (!mounted) return;

  if (!isEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
        content: Text( AppLocalizations.of(context)!.liveLocationonButton,
         // 'Please turn ON LIVE location from the Home page first.',
        ),
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const ScreenLanguage(),
    ),
  );
},
                      child: bottomItem(
                        Icons.language_outlined,
                        AppLocalizations.of(context)!.languages,
                      //  'Language',
                        false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // PLUS BUTTON
          GestureDetector(
            behavior: HitTestBehavior.opaque,
           
            onTap: () async {
  final bool isEnabled =
      await _checkLiveLocationBeforeNavigation();

  if (!mounted) return;

  if (!isEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
        content: Text( AppLocalizations.of(context)!.liveLocationonButton
      //    'Please turn ON LIVE location from the Home page first.',
        ),
      ),
    );
    return;
  }

  //  Add your Post Job screen navigation here.
},
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF138808),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x30000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ==========================================================
// BOTTOM ITEM
// ==========================================================

Widget bottomItem(
  IconData icon,
  String text,
  bool selected,
) {
  return Container(
    height: 48,

    margin: const EdgeInsets.symmetric(
      horizontal: 2,
    ),

    decoration: BoxDecoration(
      color: selected
          ? const Color(0xFFE8F5E9)
          : Colors.transparent,

      borderRadius:
          BorderRadius.circular(24),
    ),

    child: Column(
      mainAxisAlignment:
          MainAxisAlignment.center,

      mainAxisSize:
          MainAxisSize.min,

      children: [

        Icon(
          icon,
          size: 21,

          color: selected
              ? const Color(0xFF138808)
              : Colors.black87,
        ),

        const SizedBox(height: 1),

        Text(
          text,

          maxLines: 1,

          overflow:
              TextOverflow.ellipsis,

          textAlign:
              TextAlign.center,

          style: TextStyle(
            fontSize: 10,

            fontWeight: selected
                ? FontWeight.w600
                : FontWeight.w500,

            color: selected
                ? const Color(0xFF138808)
                : Colors.black87,
          ),
        ),
      ],
    ),
  );
}

@override
Widget build(
  BuildContext context,
) {
  return Scaffold(
    key: _scaffoldKey,

    drawer: sideMenu(),

    backgroundColor: Colors.white,

    body: SafeArea(
      child: Stack(
        children: [

          // ==================================================
          // HOME PAGE
          // ==================================================

          CustomScrollView(
            controller:
                _workerScrollController,

            slivers: [

              // ================================================
              // TOP
              // ================================================

              SliverToBoxAdapter(
                child: topSection(),
              ),

              // ================================================
              // HERO
              // ================================================

              SliverToBoxAdapter(
                child: homeHeroBanner(),
              ),

              // ================================================
              // SEARCH LOADING
              // ================================================

              if (searchingService)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(
                      vertical: 30,
                    ),
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  ),
                ),

              // ================================================
              // DISTANCE
              // ================================================

              if (!searchingService)
                SliverToBoxAdapter(
                  child:
                      paymentButtonSection(),
                ),

              const SliverToBoxAdapter(
                child:
                    SizedBox(height: 20),
              ),

              // ================================================
              // CATEGORIES
              // ================================================

              SliverToBoxAdapter(
                child:
                    categorySection(),
              ),

              // ================================================
              // BOTTOM SPACE
              // ================================================

              const SliverToBoxAdapter(
                child:
                    SizedBox(height: 110),
              ),
            ],
          ),

          // ==================================================
          // FLOATING BOTTOM NAVIGATION
          // ==================================================
Positioned(
  left: 0,
  right: 0,
  bottom: 0,
  child: bottomNavigationBar(),
)
        ],
      ),
    ),

    bottomNavigationBar: null,
  );
}


  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    liveLocationStatus.removeListener(
  _liveLocationStatusListener,
);

    _workerScrollController.dispose();
   // locationSubscription?.cancel();
    _liveLocationsSubscription?.cancel();
    searchController .dispose();
    searchFocusNode .dispose();
    speech.stop();
    speechService .speech.stop();
    _doctorAvailabilitySubscription?.cancel();
    _taxiCommercialSubscription?.cancel();
    _ambulanceCountSubscription?.cancel();

for (final subscription in
    _onlineCountSubscriptions.values) {
  subscription.cancel();
}
_onlineCountSubscriptions.clear();
    super.dispose();
  }
}

// ============================================================
// MENU INFORMATION SCREEN
// ============================================================

class MenuInformationScreen
    extends StatelessWidget {

  final String title;

  final IconData icon;

  final String message;


  const MenuInformationScreen({

    super.key,

    required this.title,

    required this.icon,

    required this.message,
  });


  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      appBar:
          AppBar(

        title:
            Text(title),

        backgroundColor:
            const Color(
          0xFF138808,
        ),

        foregroundColor:
            Colors.white,
      ),

      body:
          Center(

        child:
            Padding(

          padding:
              const EdgeInsets.all(
            24,
          ),

          child:
              Column(

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              Icon(

                icon,

                size: 70,

                color:
                    const Color(
                  0xFF138808,
                ),
              ),


              const SizedBox(
                height: 20,
              ),


              Text(title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),


              const SizedBox(height: 12),

              Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class AboutCitizenIndiaScreen
    extends StatelessWidget {

  const AboutCitizenIndiaScreen({
    super.key,
  });


  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      appBar:
          AppBar(

        title:
             Text(
              AppLocalizations.of(context)!.aboutPeopleBridge
         // 'About People Bridge',
        ),

        backgroundColor:
            const Color(
          0xFF138808,
        ),

        foregroundColor:
            Colors.white,
      ),


      body:
          SingleChildScrollView(

        padding:
            const EdgeInsets.all(
          24,
        ),

        child:
            Column(

          children: [

            const Icon(

              Icons.people_alt_outlined,

              size: 80,

              color:
                  Color(
                0xFF138808,
              ),
            ),


            const SizedBox( height: 20),

            const Text('PEOPLE BRIDGE',
              style: TextStyle(
                fontSize: 26,
                fontWeight:FontWeight.bold,
                color: Color(0xFF063B32),
              ),
            ),


            const SizedBox(height: 8),


             Text(AppLocalizations.of(context)!.opportunitiesforEveryone,
            //  'Opportunities for Everyone',
              style: TextStyle(fontSize: 15,
                color: Colors.grey),
            ),


            const SizedBox(height: 30),

             Text(AppLocalizations.of(context)!.aboutText,
              // 'People Bridge is designed to connect people '
              // 'with workers, professionals, services and '
              // 'businesses in their area.',

              textAlign: TextAlign.center,
              style:  TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),


            const SizedBox(
              height: 25,
            ),


            const Text(

              'Version 1.0.0',

              style:
                  TextStyle(
                color:
                    Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class SettingsMenuScreen
    extends StatelessWidget {

  const SettingsMenuScreen({
    super.key,
  });
  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      appBar:
          AppBar(

        title:
             Text(
              AppLocalizations.of(context)!.settings
         // 'Settings',
        ),

        backgroundColor:
            const Color(
          0xFF138808,
        ),

        foregroundColor:
            Colors.white,
      ),


      body:
          ListView(

        children: [

          ListTile(

            leading:
                const Icon(

              Icons.notifications_outlined,

              color:
                  Color(
                0xFF138808,
              ),
            ),

            title:
                 Text(
AppLocalizations.of(context)!.notifications,
             // 'Notifications',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            trailing:
                const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),

            onTap: () {},
          ),


          ListTile(

            leading:
                const Icon(

              Icons.location_on_outlined,

              color:
                  Color(
                0xFF138808,
              ),
            ),

            title:
                const Text(

              'Location',

              style:
                  TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            trailing:
                const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),

            onTap: () {},
          ),


          ListTile(

            leading:
                const Icon(

              Icons.privacy_tip_outlined,

              color:
                  Color(
                0xFF138808,
              ),
            ),

            title:
                const Text(

              'Privacy',

              style:
                  TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            trailing:
                const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),

            onTap: () {},
          ),
        ],
      ),
    );
  }
}
