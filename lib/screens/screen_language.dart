import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/indian_languages.dart';
import 'package:jober_india/l10n/app_localizations.dart';
import 'package:jober_india/screens/app_language.dart';

class ScreenLanguage extends StatelessWidget {
  const ScreenLanguage({super.key});

  @override
  Widget build(BuildContext context) {
    final languages = <String, String>{
      'English': 'en',
      ...indianLanguages,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Language',
          style: TextStyle(
            color: Color(0xFF171717),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ValueListenableBuilder<Locale>(
        valueListenable: appLocale,
        builder: (context, currentLocale, child) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                AppLocalizations.of(context)!.chooseyourlanguage,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF171717),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                AppLocalizations.of(context)!.languageselection,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF9E9E9E),
                ),
              ),

              const SizedBox(height: 25),

              ...languages.entries.map((entry) {
                final isSelected =
                    currentLocale.languageCode == entry.value;

                return Card(
                  elevation: 0,
                  color: isSelected
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF7EF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF138808)
                          : Colors.transparent,
                    ),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),

                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),

                    title: Text(
                      entry.key,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF138808)
                            : Colors.black87,
                      ),
                    ),

                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF138808),
                          )
                        : null,

                    onTap: () async {
                      final changed =
                          await changeAppLanguage(entry.value);

                      if (!context.mounted) return;

                      if (!changed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${entry.key} is not available yet.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}