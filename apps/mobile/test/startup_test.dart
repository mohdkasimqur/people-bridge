import 'package:app_core/app_core.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/src/home_screen.dart';
import 'package:app_mobile/src/language/language_chooser_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A store whose read always fails.
class _FailingStore implements LocaleStore {
  @override
  Future<String?> read() async => throw StateError('read failed');

  @override
  Future<void> write(String languageCode) async {}
}

/// Runs the production startup with [openStore] and pumps the resulting app.
Future<App> start(WidgetTester tester, LocaleStore Function() openStore) async {
  tester.view.physicalSize = const Size(800, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final app = await startApp(openStore);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  return app;
}

Locale shownLocale(WidgetTester tester) =>
    Localizations.localeOf(tester.element(find.byType(Scaffold).last));

void main() {
  testWidgets('a saved supported language opens Home in that language', (
    tester,
  ) async {
    final app = await start(tester, () => InMemoryLocaleStore('hi'));

    expect(app.firstRun, isFalse);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LanguageChooserScreen), findsNothing);
    expect(shownLocale(tester), const Locale('hi'));
  });

  testWidgets('nothing saved (first run) opens the chooser in English', (
    tester,
  ) async {
    final app = await start(tester, InMemoryLocaleStore.new);

    expect(app.firstRun, isTrue);
    expect(find.byType(LanguageChooserScreen), findsOneWidget);
    expect(shownLocale(tester), const Locale('en'));
  });

  testWidgets('an unsupported saved value opens the chooser in English', (
    tester,
  ) async {
    final app = await start(tester, () => InMemoryLocaleStore('xx'));

    expect(app.firstRun, isTrue);
    expect(find.byType(LanguageChooserScreen), findsOneWidget);
    expect(shownLocale(tester), const Locale('en'));
  });

  testWidgets('a failed read opens the chooser in English and is reported', (
    tester,
  ) async {
    final app = await start(tester, _FailingStore.new);

    expect(tester.takeException(), isA<StateError>());
    expect(app.firstRun, isTrue);
    expect(find.byType(LanguageChooserScreen), findsOneWidget);
    expect(shownLocale(tester), const Locale('en'));
  });

  testWidgets('storage that cannot be opened is reported; the app still starts '
      'on the chooser and a choice works for the session', (tester) async {
    final app = await start(
      tester,
      () => throw StateError('no platform implementation'),
    );

    expect(tester.takeException(), isA<StateError>());
    expect(app.firstRun, isTrue);
    expect(find.byType(LanguageChooserScreen), findsOneWidget);
    expect(shownLocale(tester), const Locale('en'));

    await tester.tap(find.text('தமிழ்'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(app.localeController.value, const Locale('ta'));
  });
}
