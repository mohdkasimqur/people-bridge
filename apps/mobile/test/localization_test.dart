import 'dart:convert';
import 'dart:io';

import 'package:app_core/app_core.dart';
import 'package:app_mobile/l10n/app_localizations.dart';
import 'package:app_mobile/main.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoLocalizations, GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The ARB files, keyed by their `@@locale`.
final Map<String, Map<String, Object?>> arbs = {
  for (final file in Directory('lib/l10n').listSync().whereType<File>())
    if (file.path.endsWith('.arb'))
      for (final arb in [
        jsonDecode(file.readAsStringSync()) as Map<String, Object?>,
      ])
        arb['@@locale']! as String: arb,
};

// Languages the Material, Cupertino and widget libraries do not translate.
const englishFallback = {
  'brx',
  'doi',
  'kok',
  'ks',
  'mai',
  'mni',
  'sa',
  'sat',
  'sd',
};
const rightToLeft = {'ur', 'ks', 'sd'};

Future<BuildContext> pumpApp(WidgetTester tester, Locale locale) async {
  await tester.pumpWidget(
    App(
      localeController: LocaleController(
        InMemoryLocaleStore(),
        fallback: locale,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.element(find.text('People Bridge'));
}

void main() {
  test('the app supports exactly the 23 ARB languages', () {
    expect(arbs, hasLength(23));
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
      arbs.keys.toSet(),
    );
  });

  test('exactly the nine expected languages need the English fallback', () {
    final unsupported = {
      for (final code in arbs.keys)
        if (!GlobalMaterialLocalizations.delegate.isSupported(Locale(code)) ||
            !GlobalCupertinoLocalizations.delegate.isSupported(Locale(code)) ||
            !GlobalWidgetsLocalizations.delegate.isSupported(Locale(code)))
          code,
    };
    expect(unsupported, englishFallback);
  });

  for (final code in arbs.keys.toList()..sort()) {
    testWidgets('starts in $code without localization errors', (tester) async {
      final context = await pumpApp(tester, Locale(code));

      expect(tester.takeException(), isNull);
      expect(Localizations.localeOf(context), Locale(code));

      final app = AppLocalizations.of(context);
      expect(app.logout, arbs[code]!['logout']);
      expect(app.home, arbs[code]!['home']);

      // Framework widget text: the library's own translation where it has
      // one, English otherwise.
      final frameworkLocale = englishFallback.contains(code)
          ? const Locale('en')
          : Locale(code);
      final material = MaterialLocalizations.of(context);
      final expectedMaterial = await GlobalMaterialLocalizations.delegate.load(
        frameworkLocale,
      );
      expect(material.okButtonLabel, expectedMaterial.okButtonLabel);
      expect(material.backButtonTooltip, expectedMaterial.backButtonTooltip);

      final cupertino = CupertinoLocalizations.of(context);
      final expectedCupertino = await GlobalCupertinoLocalizations.delegate
          .load(frameworkLocale);
      expect(cupertino.alertDialogLabel, expectedCupertino.alertDialogLabel);
      expect(cupertino.todayLabel, expectedCupertino.todayLabel);
      if (englishFallback.contains(code)) {
        expect(material.okButtonLabel, 'OK');
        expect(cupertino.alertDialogLabel, 'Alert');
      }

      expect(
        Directionality.of(context),
        rightToLeft.contains(code) ? TextDirection.rtl : TextDirection.ltr,
      );
    });
  }

  testWidgets('switching language at runtime updates the app text', (
    tester,
  ) async {
    final controller = LocaleController(InMemoryLocaleStore());
    await tester.pumpWidget(App(localeController: controller));
    final element = tester.element(find.text('People Bridge'));
    expect(AppLocalizations.of(element).logout, arbs['en']!['logout']);

    await controller.setLocale(const Locale('sat'));
    await tester.pumpAndSettle();

    final updated = tester.element(find.text('People Bridge'));
    expect(AppLocalizations.of(updated).logout, arbs['sat']!['logout']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unsupported language falls back to English', (tester) async {
    final context = await pumpApp(tester, const Locale('fr'));
    expect(Localizations.localeOf(context), const Locale('en'));
    expect(AppLocalizations.of(context).logout, arbs['en']!['logout']);
  });
}
