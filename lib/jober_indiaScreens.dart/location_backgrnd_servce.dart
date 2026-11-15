
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jober_india/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';


@pragma('vm:entry-point')
void startLiveLocationCallback() {
  FlutterForegroundTask.setTaskHandler(
    LiveLocationTaskHandler(),
  );
}


class LiveLocationTaskHandler extends TaskHandler {
  Position? _lastUploadedPosition;

  DateTime? _lastUploadTime;
  bool _isUpdatingLocation = false;

 List<String> _categories = [];

String _providerRole = '';

String _serviceType = '';
 
@override
Future<void> onStart(
  DateTime timestamp,
  TaskStarter starter,
) async {
  debugPrint('LIVE: foreground task onStart entered.');

  try {
    // Initialize Firebase in this background execution context.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    debugPrint('LIVE: Firebase initialized in task.');

    await _loadProviderInformation();

    debugPrint(
      'LIVE: role=$_providerRole, '
      'serviceType=$_serviceType, '
      'categories=$_categories',
    );

    // Do not make service startup wait for GPS or Firestore.
    unawaited(_updateLocation());

    await FlutterForegroundTask.updateService(
      notificationTitle: 'Citizen India',
      notificationText: 'LIVE location service is running',
    );
  } catch (e, stackTrace) {
    debugPrint('LIVE onStart error: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}

  @override
void onRepeatEvent(DateTime timestamp) {
  _updateLocation();
}

 
Future<void> _updateLocation() async {
  if (_isUpdatingLocation) {
    debugPrint(
      'LIVE location update skipped: '
      'previous update is still running.',
    );
    return;
  }

  _isUpdatingLocation = true;

  try {
    // Refresh provider information, including when
    // the foreground service was already running.
    await _loadProviderInformation();

    final bool gpsEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!gpsEnabled) {
      debugPrint('GPS is disabled.');
      return;
    }

    final LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('Location permission unavailable.');
      return;
    }

    final Position position =
        await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).timeout(
      const Duration(seconds: 20),
    );

    // if (!_shouldUpload(position)) {
    //   return;
    // }
    final String? forceUpload =
    await FlutterForegroundTask.getData<String>(
  key: 'forceLiveLocationUpload',
);

final bool mustUpload = forceUpload == 'true';

if (!mustUpload && !_shouldUpload(position)) {
  return;
}

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('No Firebase user in background service.');
      return;
    }

    final DateTime now = DateTime.now();

    final String geohash = _generateGeohash(
      position.latitude,
      position.longitude,
    );

    final DateTime expiresAt =
        now.add(const Duration(minutes: 2));

    await FirebaseFirestore.instance
        .collection('liveLocations')
        .doc(user.uid)
        .set(
      {
        'uid': user.uid,
        'role': _providerRole,
        'serviceType': _serviceType,
        'categories': _categories,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'geohash': geohash,
        'isLive': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      },
      SetOptions(merge: true),
    ).timeout(const Duration(seconds: 15));

    // Update the throttle only after Firestore succeeds.
    _lastUploadedPosition = position;
    _lastUploadTime = now;

    // Tell the main app that a real upload succeeded.
    await FlutterForegroundTask.saveData(
      key: 'lastSuccessfulLiveUploadMs',
      value: now.millisecondsSinceEpoch.toString(),
    );
    await FlutterForegroundTask.saveData(
  key: 'forceLiveLocationUpload',
  value: 'false',
);

    debugPrint(
      'LIVE upload successful: '
      '${position.latitude}, ${position.longitude}; '
      'role=$_providerRole; '
      'serviceType=$_serviceType; '
      'categories=$_categories',
    );
  } catch (e, stackTrace) {
    debugPrint('Background location error: $e');
    debugPrintStack(stackTrace: stackTrace);
  } finally {
    _isUpdatingLocation = false;
  }
}

Future<void> _loadProviderInformation() async {
  final String? savedCategories =
      await FlutterForegroundTask.getData<String>(
    key: 'providerCategories',
  );

  final String? savedRole =
      await FlutterForegroundTask.getData<String>(
    key: 'providerRole',
  );

  final String? savedServiceType =
      await FlutterForegroundTask.getData<String>(
    key: 'providerServiceType',
  );

  _categories = (savedCategories ?? '')
      .split('|')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();

  _providerRole = savedRole?.trim() ?? '';
  _serviceType = savedServiceType?.trim() ?? '';
}

  bool _shouldUpload(Position position) {
  // First upload
  if (_lastUploadTime == null ||
      _lastUploadedPosition == null) {
    return true;
  }

  final DateTime now = DateTime.now();

  final int seconds =
      now.difference(_lastUploadTime!).inSeconds;

  if (seconds >= 20) {
    return true;
  }

 
  final double distance =
      Geolocator.distanceBetween(
    _lastUploadedPosition!.latitude,
    _lastUploadedPosition!.longitude,
    position.latitude,
    position.longitude,
  );

  if (distance >= 30) {
    return true;
  }

  return false;
}

  String _generateGeohash(
    double latitude,
    double longitude, {
    int precision = 9,
  }) {
    const String base32 =
        '0123456789bcdefghjkmnpqrstuvwxyz';

    double minLat = -90.0;
    double maxLat = 90.0;

    double minLon = -180.0;
    double maxLon = 180.0;

    bool evenBit = true;

    int bit = 0;
    int ch = 0;

    final StringBuffer hash =
        StringBuffer();

    while (hash.length < precision) {
      if (evenBit) {
        final double mid =
            (minLon + maxLon) / 2;

        if (longitude >= mid) {
          ch =
              (ch << 1) + 1;
          minLon = mid;
        } else {
          ch = ch << 1;
          maxLon = mid;
        }
      } else {
        final double mid =
            (minLat + maxLat) / 2;

        if (latitude >= mid) {
          ch =
              (ch << 1) + 1;
          minLat = mid;
        } else {
          ch = ch << 1;
          maxLat = mid;
        }
      }

      evenBit = !evenBit;

      if (bit < 4) {
        bit++;
      } else {
        hash.write(
          base32[ch],
        );

        bit = 0;
        ch = 0;
      }
    }

    return hash.toString();
  }

  @override
  Future<void> onDestroy(
    DateTime timestamp,
    bool isTimeout,
  ) async {
    debugPrint(
      'LIVE LOCATION FOREGROUND SERVICE DESTROYED',
    );

   
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {
    debugPrint(
      'LIVE location notification dismissed.',
    );
  }
}
final ValueNotifier<bool> liveLocationStatus =
    ValueNotifier<bool>(false);
// ============================================================
// LIVE LOCATION SERVICE
// ============================================================

class LiveLocationService {
  // ==========================================================
  // SINGLETON
  // ==========================================================

  static final LiveLocationService instance =
      LiveLocationService._internal();

  factory LiveLocationService() {
    return instance;
  }

  LiveLocationService._internal();

  // ==========================================================
  // CONSTANTS
  // ==========================================================

  static const String
      _liveLocationEnabledKey =
      'liveLocationEnabled';

  // ==========================================================
  // FIREBASE
  // ==========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ==========================================================
  // STATE
  // ==========================================================

  bool _isRunning = false;

  bool get isRunning =>
      _isRunning;

  bool _starting = false;

  bool _stopping = false;

  // ==========================================================
  // INITIALIZE FOREGROUND SERVICE
  // ==========================================================
  //
  // Call this ONCE from main.dart before runApp().
  //
  // Part 3 will show the exact main.dart placement.
  // ==========================================================

  static void initialize() {
    FlutterForegroundTask.initCommunicationPort();

    FlutterForegroundTask.init(
      androidNotificationOptions:
          AndroidNotificationOptions(
        channelId:
            'citizen_india_live_location',

        channelName:
            'Citizen India LIVE Location',

        channelDescription:
            'Keeps provider LIVE location active.',

        channelImportance:
            NotificationChannelImportance.LOW,

        priority:
            NotificationPriority.LOW,

        onlyAlertOnce: true,
      ),

      iosNotificationOptions:
          const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),

      foregroundTaskOptions:
          ForegroundTaskOptions(
        eventAction:
            ForegroundTaskEventAction.repeat(
          20000,
        ),

        autoRunOnBoot: false,

        autoRunOnMyPackageReplaced: false,

        allowWakeLock: true,

        allowWifiLock: true,

        allowAutoRestart: true,

        // IMPORTANT:
        // Do NOT stop the service simply because
        // the Flutter app task disappears.
        stopWithTask: false,
      ),
    );
  }

  // ==========================================================
  // SAVED LIVE STATE
  // ==========================================================

  Future<bool> get savedLiveLocationState async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(
          _liveLocationEnabledKey,
        ) ??
        false;
  }

  // ==========================================================
  // SAVE LIVE STATE
  // ==========================================================

  Future<void> _saveLiveLocationState(
    bool enabled,
  ) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _liveLocationEnabledKey,
      enabled,
    );
  }

  // ==========================================================
  // SAVE CATEGORIES FOR BACKGROUND ISOLATE
  // ==========================================================

  Future<void> _saveCategories(
    List<String> categories,
  ) async {
    final String value =
        categories
            .map(
              (category) =>
                  category.trim(),
            )
            .where(
              (category) =>
                  category.isNotEmpty,
            )
            .join('|');

    await FlutterForegroundTask.saveData(
      key: 'providerCategories',
      value: value,
    );
  }

  Future<void> _saveProviderInformation({
  required String role,
  required String serviceType,
}) async {
  await FlutterForegroundTask.saveData(
    key: 'providerRole',
    value: role,
  );

  await FlutterForegroundTask.saveData(
    key: 'providerServiceType',
    value: serviceType,
  );
}  

  // ==========================================================
  // GPS CHECK
  // ==========================================================

  Future<bool> isGpsEnabled() async {
    return await Geolocator
        .isLocationServiceEnabled();
  }

  Future<LocationPermission>
      requestPermission() async {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission ==
        LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    return permission;
  }

  // ==========================================================
  // CURRENT POSITION
  // ==========================================================

  Future<Position>
      getCurrentPosition() async {
    return await Geolocator
        .getCurrentPosition(
      locationSettings:
          const LocationSettings(
        accuracy:
            LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).timeout(
      const Duration(
        seconds: 20,
      ),
      onTimeout: () {
        throw TimeoutException(
          'Getting current location timed out.',
        );
      },
    );
  }

Future<bool> start({
  List<String> categories = const [],
  required String role,
  required String serviceType,
}) async {
  if (_starting || _stopping) {
    debugPrint('LIVE: start or stop is already in progress.');
    return false;
  }

  _starting = true;

  try {
    // 1. Check GPS.
    final bool gpsEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!gpsEnabled) {
      debugPrint('LIVE ERROR: GPS is disabled.');
      return false;
    }

    // 2. Check/request location permission.
    final LocationPermission permission =
        await requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('LIVE ERROR: Location permission is $permission.');
      return false;
    }

    // 3. Check Firebase sign-in.
    if (_auth.currentUser == null) {
      debugPrint('LIVE ERROR: No signed-in Firebase user.');
      return false;
    }

    // 4. Save provider information.
    await _saveCategories(categories);

    await _saveProviderInformation(
      role: role,
      serviceType: serviceType,
    );

    await FlutterForegroundTask.saveData(
      key: 'forceLiveLocationUpload',
      value: 'true',
    );

    await FlutterForegroundTask.saveData(
      key: 'lastSuccessfulLiveUploadMs',
      value: '0',
    );

    // 5. Start service if not already running.
    bool serviceRunning =
        await FlutterForegroundTask.isRunningService;

    if (!serviceRunning) {
      final ServiceRequestResult result =
          await FlutterForegroundTask.startService(
        serviceId: 1001,
        serviceTypes: const [
          ForegroundServiceTypes.location,
        ],
        notificationTitle: 'Citizen India',
        notificationText: 'Starting LIVE location...',
        callback: startLiveLocationCallback,
      ).timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          throw TimeoutException(
            'Android did not confirm service startup within 12 seconds.',
          );
        },
      );

      if (result is! ServiceRequestSuccess) {
        _isRunning = false;
        await _saveLiveLocationState(false);
        liveLocationStatus.value = false;
        return false;
      }
    }

    // 6. Confirm service is running.
    serviceRunning =
        await FlutterForegroundTask.isRunningService;

    if (!serviceRunning) {
      _isRunning = false;
      await _saveLiveLocationState(false);
      liveLocationStatus.value = false;
      return false;
    }

    // 7. Startup succeeded.
    _isRunning = true;
    await _saveLiveLocationState(true);
    liveLocationStatus.value = true;

    debugPrint(
      'LIVE SERVICE STARTED. Waiting for background location upload.',
    );

    return true;
  } on TimeoutException catch (e) {
    debugPrint('LIVE START TIMEOUT: $e');
    _isRunning = false;
    await _saveLiveLocationState(false);
    liveLocationStatus.value = false;
    return false;
  } catch (e, stackTrace) {
    debugPrint('LIVE START ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);

    _isRunning = false;
    await _saveLiveLocationState(false);
    liveLocationStatus.value = false;
    return false;
  } finally {
    _starting = false;
  }
}

Future<bool> stop() async {
  if (_stopping) {
    debugPrint('LIVE stop is already in progress');
    return false;
  }

  if (_starting) {
    debugPrint('LIVE start is still in progress');
    return false;
  }

  _stopping = true;

  try {
    final bool serviceRunning =
        await FlutterForegroundTask.isRunningService.timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TimeoutException(
        'Could not check foreground service status.',
      ),
    );

    if (serviceRunning) {
      final ServiceRequestResult result =
          await FlutterForegroundTask.stopService().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException(
          'Foreground service stop timed out.',
        ),
      );

      if (result is! ServiceRequestSuccess) {
        debugPrint('Foreground service stop failed: $result');
        return false;
      }

      // Verify that the foreground service really stopped.
      final bool stillRunning =
          await FlutterForegroundTask.isRunningService.timeout(
        const Duration(seconds: 5),
        onTimeout: () => true,
      );

      if (stillRunning) {
        debugPrint('Foreground service is still running');
        return false;
      }
    }

    // Service has stopped. Now mark the provider offline.
    try {
      await markOffline().timeout(
        const Duration(seconds: 8),
      );
    } catch (e) {
      debugPrint('Could not confirm Firestore offline status: $e');
    }

    // Save OFF only after service shutdown.
    await _saveLiveLocationState(false);

    _isRunning = false;
    liveLocationStatus.value = false;

    debugPrint('LIVE LOCATION STOPPED SUCCESSFULLY');

    return true;
  } catch (e, stackTrace) {
    debugPrint('LIVE stop error: $e');
    debugPrintStack(stackTrace: stackTrace);
    return false;
  } finally {
    _stopping = false;
  }
}

Future<void> markOffline() async {
  final User? user = _auth.currentUser;

  if (user == null) return;

  try {
    await _firestore
        .collection('liveLocations')
        .doc(user.uid)
        .set(
      {
        'uid': user.uid,
        'isLive': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'expiresAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    ).timeout(
      const Duration(seconds: 5),
    );

    debugPrint('Provider marked OFFLINE.');
  } catch (e) {
    debugPrint('Could not mark provider offline: $e');
  }
}

}
