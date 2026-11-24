import 'package:app_core/app_core.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'language/language_chooser_screen.dart';

/// The app's placeholder home until the Phase 4 screens exist; its one action
/// opens the language chooser.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.home),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: l10n.languages,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LanguageChooserScreen(
                  localeController: localeController,
                  firstRun: false,
                ),
              ),
            ),
          ),
        ],
      ),
      body: const Center(child: Text('People Bridge')),
    );
  }
}
