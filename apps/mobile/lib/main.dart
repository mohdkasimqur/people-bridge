import 'package:app_core/app_core.dart';
import 'package:app_design/app_design.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/localizations.dart';
import 'src/home_screen.dart';
import 'src/language/language_chooser_screen.dart';
import 'src/language/shared_preferences_locale_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    await startApp(
      () => SharedPreferencesLocaleStore(SharedPreferencesAsync()),
    ),
  );
}

/// Opens the language store, reads the saved language and builds the app.
///
/// The first screen is decided once, before the first frame, so a late read
/// cannot change it. If the store cannot be created, the error is reported
/// and an in-memory store is used: the app starts in English on the chooser,
/// and the choice lasts for this session only.
Future<App> startApp(LocaleStore Function() openStore) async {
  LocaleStore store;
  try {
    store = openStore();
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'app_mobile',
        context: ErrorDescription(
          'while opening language storage; using memory for this session',
        ),
      ),
    );
    store = InMemoryLocaleStore();
  }
  final localeController = LocaleController(store);
  final result = await localeController.load(
    supported: {for (final locale in appSupportedLocales) locale.languageCode},
  );
  return App(
    localeController: localeController,
    firstRun: result != LocaleLoadResult.saved,
  );
}

final _lightTheme = AppTheme.light();
final _darkTheme = AppTheme.dark();

class App extends StatelessWidget {
  const App({super.key, required this.localeController, this.firstRun = false});

  final LocaleController localeController;

  /// Shows the language chooser first: nothing usable was saved.
  final bool firstRun;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeController,
      builder: (context, locale, _) => MaterialApp(
        title: 'People Bridge',
        theme: _lightTheme,
        darkTheme: _darkTheme,
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: firstRun
            ? LanguageChooserScreen(
                localeController: localeController,
                firstRun: true,
              )
            : HomeScreen(localeController: localeController),
      ),
    );
  }
}
