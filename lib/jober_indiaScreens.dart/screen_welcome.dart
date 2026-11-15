import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/indian_languages.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> welcomeTexst = [
  "Welcome",
  "സ്വാഗതം",
  "स्वागत",
  "வரவேற்கிறோம்",
  "ಸ್ವಾಗತ",
  "స్వాగతం",
  "স্বাগতম",
  "خوش آمدید",
];

final List<String> languageNames = [
  'English',
  ...indianLanguages.keys,
];

final Map<String, String> languageCodes = {
  'English': defaultLanguageCode,
  ...indianLanguages,
};

class ScreenWelcome extends StatefulWidget {
 final Future<bool> Function(String) onLanguageChanged;

  const ScreenWelcome({
    super.key,
    required this.onLanguageChanged,
  });

  @override
  State<ScreenWelcome> createState() => _ScreenWelcomeState();
}

class _ScreenWelcomeState extends State<ScreenWelcome> {
  int currentIndex = 0;

  bool visible = true;

  late Timer timer;

  String selectedLanguage = "English";

  bool isSavingLanguage = false;

  Future<void> selectedLanguae(String code) async {
  if (isSavingLanguage) return;

  setState(() {
    isSavingLanguage = true;
  });

  try {
    // Change the language through the single global function.
    final bool changed =
        await widget.onLanguageChanged(code);

    if (!mounted) return;

    if (!changed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This language is not available yet.',
          ),
        ),
      );
      return;
    }

    // Save that the welcome screen has been completed.
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('hasSeenWelcome', true);

  } catch (e) {
    debugPrint('Language selection error: $e');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to change language. Please try again.',
          ),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        isSavingLanguage = false;
      });
    }
  }
}

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    loadLanguage();

    timer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        if (!mounted) return;

        setState(() {
          currentIndex =
              (currentIndex + 1) % welcomeTexst.length;
        });
      },
    );
  }

  // ==========================================================
  // LOAD LANGUAGE
  // ==========================================================

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    final String languageCode =
        prefs.getString("language") ?? "en";

    final entry = languageCodes.entries.firstWhere(
      (e) => e.value == languageCode,
      orElse: () => const MapEntry("English", "en"),
    );

    if (!mounted) return;

    setState(() {
      selectedLanguage = entry.key;
    });
  }

  // ==========================================================
  // LANGUAGE BUTTON
  // ==========================================================

  Widget languageButton(String language) {
    final bool isSelected = selectedLanguage == language;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isSavingLanguage
            ? null
            : () async {
                setState(() {
                  selectedLanguage = language;
                });

                await selectedLanguae(
                  languageCodes[language]!,
                );
              },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF138808)
                : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF138808)
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  language,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.check_circle,
                  size: 17,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 25,
          ),
          child: Column(
            children: [
              const SizedBox(height: 25),

              SizedBox(
  height: 85,
  width: double.infinity,
  child: Center(
    child: AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      child: Text(
        welcomeTexst[currentIndex],
        textAlign: TextAlign.center,
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.2,
          height: 1.3,
        ),
      ),
    ),
  ),
),

              const SizedBox(height: 35),

              const Text(
                "Select Your Language",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Choose your preferred language to continue",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // ALL 23 LANGUAGE BUTTON BOXES
              // ==================================================

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: languageNames.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemBuilder: (context, index) {
                  final language = languageNames[index];

                  return languageButton(language);
                },
              ),

              const SizedBox(height: 25),

              if (isSavingLanguage)
                const CircularProgressIndicator(
                  color: Color(0xFF138808),
                ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}