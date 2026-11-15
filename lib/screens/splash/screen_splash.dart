import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:jober_india/jober_indiaScreens.dart/screen_home.dart';
import 'package:jober_india/l10n/app_localizations.dart';

// CHANGE THIS IMPORT TO THE ACTUAL FILE
// THAT CONTAINS YOUR CHOOSE YOUR ROLE SCREEN.
//import 'package:jober_india/jober_indiaScreens.dart/choose_your_role.dart';
import 'package:jober_india/screens/owner/screen_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  // ==========================================================
  // ANIMATION
  // ==========================================================

  late AnimationController _controller;

  late Animation<double> _scaleAnimation;

  late Animation<double> _fadeAnimation;

  Timer? _timer;

static const String _permissionAskedKey =
    'startupLocationPermissionAsked';

// ==========================================================
// INIT
// ==========================================================

@override
void initState() {
  super.initState();

  _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  _scaleAnimation = Tween<double>(
    begin: 0.70,
    end: 1.0,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ),
  );

  _fadeAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  );

  _controller.forward();

  // Show splash for 3 seconds.
  _timer = Timer(
    const Duration(seconds: 3),
    () async {
      if (!mounted) return;

      debugPrint('SPLASH TIMER FINISHED');

      // First check location permission.
      await _requestStartupLocationPermission();

      if (!mounted) return;

      // Then continue to the correct screen.
      await _checkLoginAndNavigate();
    },
  );
}

// ==========================================================
// STARTUP LOCATION PERMISSION
// ==========================================================

Future<void> _requestStartupLocationPermission() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Check current permission.
    LocationPermission permission =
        await Geolocator.checkPermission();

    // Already granted.
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      debugPrint('LOCATION PERMISSION ALREADY GRANTED');
      return;
    }

    // Permission permanently denied.
    if (permission == LocationPermission.deniedForever) {
      debugPrint('LOCATION PERMISSION PERMANENTLY DENIED');
      return;
    }

    // Check whether startup permission was already requested.
    final alreadyAsked =
        prefs.getBool(_permissionAskedKey) ?? false;

    if (alreadyAsked) {
      debugPrint('STARTUP LOCATION PERMISSION ALREADY ASKED');
      return;
    }

    if (!mounted) return;

    // Explain why the app needs location.
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Location Permission',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Jober India uses your location to help you find '
            'nearby services and discover service providers '
            'around you.\n\n'
            'Location is also used when you choose to activate '
            'LIVE location.\n\n'
            'You can continue using the app without granting '
            'this permission, but some location-based features '
            'may not work.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Not now'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    // Save that the startup explanation has been shown.
    await prefs.setBool(_permissionAskedKey, true);

    if (shouldRequest != true) {
      debugPrint('USER SKIPPED STARTUP LOCATION PERMISSION');
      return;
    }

    // Request Android foreground location permission.
    permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      debugPrint('LOCATION PERMISSION GRANTED');
    } else {
      debugPrint('LOCATION PERMISSION NOT GRANTED');
    }
  } catch (e) {
    debugPrint('STARTUP LOCATION PERMISSION ERROR: $e');

    // Permission errors must not prevent app startup.
  }
}

// ==========================================================
// CHECK LOGIN STATUS AND NAVIGATE
// ==========================================================

Future<void> _checkLoginAndNavigate() async {
  try {
    final User? user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user != null) {
      debugPrint('USER ALREADY LOGGED IN: ${user.uid}');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ScreenHome(),
        ),
      );

      return;
    }

    debugPrint('NO LOGGED-IN USER');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ScreenChooseRole(),
      ),
    );
  } catch (e) {
    debugPrint('SPLASH LOGIN CHECK ERROR: $e');

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ScreenChooseRole(),
      ),
    );
  }
}

// ==========================================================
// DISPOSE
// ==========================================================

@override
void dispose() {
  _timer?.cancel();
  _controller.dispose();

  super.dispose();
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        width: double.infinity,

        height: double.infinity,

        // ====================================================
        // SPLASH BACKGROUND
        // ====================================================

        decoration: const BoxDecoration(

          gradient: LinearGradient(

            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

            colors: [

              Colors.white,

              Color(0xFFF4FBF6),

              Colors.white,

            ],
          ),
        ),

        child: SafeArea(

          child: Column(

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              const Spacer(),

              // =================================================
              // LOGO
              // =================================================

              ScaleTransition(

                scale: _scaleAnimation,

                child: FadeTransition(

                  opacity: _fadeAnimation,

                  child: Container(

                    width: 230,

                    height: 230,

                    padding:
                        const EdgeInsets.all(10),

                    decoration: BoxDecoration(

                      shape: BoxShape.circle,

                      color: Colors.white,

                      boxShadow: [

                        BoxShadow(

                          color:
                              Colors.black.withValues(
                            alpha: 0.12,
                          ),

                          blurRadius: 30,

                          spreadRadius: 4,

                          offset:
                              const Offset(0, 12),
                        ),
                      ],
                    ),

                    child: ClipOval(

                      child: Image.asset(

                        'assets/images/WhatsApp Image 2026-09-01 at 11.39.01 AM.jpeg',

                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // =================================================
              // PEOPLE BRIDGE
              // =================================================

              FadeTransition(

                opacity: _fadeAnimation,

                child: RichText(

                  text: TextSpan(

                    children: [

                      TextSpan(

                        text:  AppLocalizations.of(context)!.people,

                        style: TextStyle(

                          fontSize: 29,

                          fontWeight:
                              FontWeight.bold,

                          letterSpacing: 2,

                          color: Colors.red,
                        ),
                      ),

                      TextSpan(

                        text:  AppLocalizations.of(context)!.bridge,

                        style: TextStyle(

                          fontSize: 29,

                          fontWeight:
                              FontWeight.bold,

                          letterSpacing: 2,

                          color:
                              Color.fromARGB(
                            190,
                            19,
                            119,
                            6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // =================================================
              // TAGLINE
              // =================================================

              FadeTransition(

                opacity: _fadeAnimation,

                child: const Text(

                  'Connecting People. Connecting India.',

                  textAlign:
                      TextAlign.center,

                  style: TextStyle(

                    fontSize: 14,

                    color: Colors.black54,

                    letterSpacing: 0.4,
                  ),
                ),
              ),

              const Spacer(),

              // =================================================
              // BOTTOM TEXT
              // =================================================

              FadeTransition(

                opacity: _fadeAnimation,

                child: const Padding(

                  padding: EdgeInsets.only(
                    bottom: 30,
                  ),

                  child: Text(

                    'Made for India 🇮🇳',

                    style: TextStyle(

                      fontSize: 13,

                      color: Colors.black45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}