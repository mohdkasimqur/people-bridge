import 'package:app_core/app_core.dart';
import 'package:app_design/app_design.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/localizations.dart';
import '../home_screen.dart';
import 'language_names.dart';

/// Lists the 23 app languages. A tap switches the app at once and saves it.
///
/// On the first run ([firstRun]) no language is preselected and the choice
/// replaces this screen with [HomeScreen], so Back cannot return here.
/// Otherwise the current language is selected and the choice pops back.
class LanguageChooserScreen extends StatefulWidget {
  const LanguageChooserScreen({
    super.key,
    required this.localeController,
    required this.firstRun,
  });

  final LocaleController localeController;
  final bool firstRun;

  @override
  State<LanguageChooserScreen> createState() => _LanguageChooserScreenState();
}

class _LanguageChooserScreenState extends State<LanguageChooserScreen> {
  String? _chosen;

  Future<void> _choose(String? languageCode) async {
    // One choice per visit: further taps are ignored while it is applied.
    if (languageCode == null || _chosen != null) return;
    setState(() => _chosen = languageCode);
    // Switches at once; a failed save is reported by the controller and does
    // not stop the switch or the navigation.
    await widget.localeController.setLocale(Locale(languageCode));
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (widget.firstRun) {
      navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HomeScreen(localeController: widget.localeController),
        ),
      );
    } else {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected =
        _chosen ??
        (widget.firstRun ? null : widget.localeController.value.languageCode);
    return Scaffold(
      // The title is in the list, not the app bar: an app bar title is
      // limited to one line and is cut off at large text sizes.
      appBar: AppBar(),
      body: RadioGroup<String>(
        groupValue: selected,
        onChanged: _choose,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSmall),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spaceMedium,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.chooseyourlanguage,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTokens.spaceMedium),
              child: Text(l10n.languageselection),
            ),
            for (final locale in appSupportedLocales)
              RadioListTile<String>(
                value: locale.languageCode,
                title: Text(languageNames[locale.languageCode]!.native),
                subtitle: Text(languageNames[locale.languageCode]!.english),
              ),
          ],
        ),
      ),
    );
  }
}
