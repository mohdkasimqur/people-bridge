import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_home.dart';
import 'package:jober_india/jober_indiaScreens.dart/screen_welcome.dart';
import 'package:jober_india/owner_data.dart';
import 'package:jober_india/screens/owner/screen_user.dart';
import 'package:jober_india/screens/splash/screen_splash.dart';
import 'package:jober_india/screens/app_language.dart';
import 'package:jober_india/worker_data.dart';
import 'package:overlay_pop_up/overlay_pop_up.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

import 'package:jober_india/l10n/app_localizations.dart';

final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

StreamSubscription? _citizenBubbleSubscription;


@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(                                  
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      routes: {
        '/chooseRole': (context) => ScreenChooseRole(),
      },
      home: const Material(
        color: Colors.transparent,
        child: Center(
          child: FloatingWorkerCircle(),
        ),
      ),
    ),
  );
}

class FloatingWorkerCircle extends StatelessWidget {
  const FloatingWorkerCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        onTap: () async {
  try {
    debugPrint('Citizen India bubble tapped.');

    // Send navigation request to main app.
    await OverlayPopUp.sendToMainApp({
      'action': 'open_people_bridge',
    });

    // Request Android to launch/bring the main app forward.
     FlutterForegroundTask.launchApp();

  } catch (e, stackTrace) {
    debugPrint('Bubble tap error: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
},

        child: Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF16803C),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
'assets/images/WhatsApp Image 2026-09-01 at 11.39.01 AM.jpeg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.home,
                  color: Color(0xFF16803C),
                  size: 34,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid){
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  }

  await loadAppLanguage();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
  Hive.registerAdapter(OwnerDataAdapter());
}
  
  if (!Hive.isAdapterRegistered(1)) {
  Hive.registerAdapter(WorkerDataAdapter());
}
  
  await Hive.openBox<OwnerData>('ownerBox');
  await Hive.openBox<WorkerData>('workerBox');
  await Hive.openBox('userBox');
  await Hive.openBox('workerProfiles');
  await Hive.openBox('workerLocation');
  await Hive.openBox('settings');     
  await Hive.openBox('grocery');
  await Hive.openBox('appBox');
  await Hive.openBox('garageProfiles');
  await Hive.openBox('medical_shop_local');
  await Hive.openBox('brokerProfiles');

final prefs = await SharedPreferences.getInstance();

final bool hasSeenWelcome =
    prefs.getBool('hasSeenWelcome') ?? false;

final bool isLoggedIn =
    prefs.getBool('isLoggedIn') ?? false;

// Use the language validated by loadAppLanguage().
final String languageCode = appLocale.value.languageCode;

debugPrint('==============================');
debugPrint('HAS SEEN WELCOME: $hasSeenWelcome');
debugPrint('IS LOGGED IN: $isLoggedIn');
debugPrint('LANGUAGE: $languageCode');
debugPrint('==============================');

OverlayPopUp.initializeMainAppHandler();

_citizenBubbleSubscription?.cancel();

_citizenBubbleSubscription =
    OverlayPopUp.dataListener?.listen((data) async {
  if (data is! Map) return;

  final String action =
      (data['action'] ?? '').toString();

  if (action == 'open_people_bridge') {
    debugPrint('MAIN: Floating bubble tapped.');

    final prefs = await SharedPreferences.getInstance();

    final bool hasSeenWelcome =
        prefs.getBool('hasSeenWelcome') ?? false;

    final navigator = appNavigatorKey.currentState;

    if (navigator == null) {
      debugPrint('MAIN: Navigator is not ready.');
      return;
    }

    if (!hasSeenWelcome) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => ScreenWelcome(
            onLanguageChanged: (newLanguage) async {
              final bool changed =
                  await changeAppLanguage(newLanguage);

              if (!changed) return false;

              await prefs.setBool('hasSeenWelcome', true);

              appNavigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const SplashScreen(),
                ),
                (route) => false,
              );

              return true;
            },
          ),
        ),
        (route) => false,
      );
    } else {
      final user = FirebaseAuth.instance.currentUser;

      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => user != null
              ? const ScreenHome()
              : const ScreenChooseRole(),
        ),
        (route) => false,
      );
    }
  }
});

  runApp(
    MyApp(
      hasSeenWelcome: hasSeenWelcome,
      isLoggedIn: isLoggedIn,
      languageCode: languageCode,
    ),
  );
}


class MyApp extends StatefulWidget {
  final bool hasSeenWelcome;
  final bool isLoggedIn;
  final String languageCode;

  const MyApp({
    super.key,
    required this.hasSeenWelcome,
    required this.isLoggedIn,
    required this.languageCode,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool hasSeenWelcome;
  late bool isLoggedIn;

  @override
  void initState() {
    super.initState();

    hasSeenWelcome = widget.hasSeenWelcome;
    isLoggedIn = widget.isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'People Bridge',

          locale: locale,

localizationsDelegates: const [
  AppLocalizations.delegate,

  // Native Flutter Material translations.
  GlobalMaterialLocalizations.delegate,

  // English fallback for unsupported Material languages.
  FallbackMaterialLocalizationsDelegate(),

  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],

supportedLocales: AppLocalizations.supportedLocales,

          theme: ThemeData(
            primarySwatch: Colors.amber,
          ),

          home: _getStartingScreen(),
        );
      },
    );
  }

Widget _getStartingScreen() {
  if (!hasSeenWelcome) {
    return ScreenWelcome(
      onLanguageChanged: (newLanguage) async {
        // Change and validate the selected language.
        final bool changed =
            await changeAppLanguage(newLanguage);

        if (!changed) return false;

        // Save welcome completion before rebuilding the screen.
        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool('hasSeenWelcome', true);

        if (!mounted) return true;

        setState(() {
          hasSeenWelcome = true;
        });

        return true;
      },
    );
  }

  return const SplashScreen();
}
}

class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {

  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return true;
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return GlobalMaterialLocalizations.delegate.load(
      const Locale('en'),
    );
  }

  @override
  bool shouldReload(
    FallbackMaterialLocalizationsDelegate old,
  ) {
    return false;
  }
}
