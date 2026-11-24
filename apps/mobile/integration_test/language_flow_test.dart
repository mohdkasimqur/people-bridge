// Runs on a device only (authorisation B): `flutter test integration_test`.
// It removes and then writes this app's saved language.
import 'package:app_core/app_core.dart';
import 'package:app_mobile/l10n/localizations.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/src/home_screen.dart';
import 'package:app_mobile/src/language/shared_preferences_locale_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch: choosing Santali persists in device storage', (
    tester,
  ) async {
    final preferences = SharedPreferencesAsync();
    await preferences.remove(SharedPreferencesLocaleStore.key);
    final supported = {for (final l in appSupportedLocales) l.languageCode};
    LocaleController newController() =>
        LocaleController(SharedPreferencesLocaleStore(preferences));

    final firstLaunch = newController();
    expect(await firstLaunch.load(supported: supported), LocaleLoadResult.none);
    await tester.pumpWidget(App(localeController: firstLaunch, firstRun: true));
    await tester.pumpAndSettle();

    final santali = find.text('ᱥᱟᱱᱛᱟᱲᱤ');
    await tester.scrollUntilVisible(santali, 200);
    await tester.tap(santali);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    // A fresh controller reads what the device stored, as a restart would.
    final nextLaunch = newController();
    expect(await nextLaunch.load(supported: supported), LocaleLoadResult.saved);
    expect(nextLaunch.value, const Locale('sat'));
  });
}
