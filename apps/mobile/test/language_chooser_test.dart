import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:app_mobile/l10n/app_localizations.dart';
import 'package:app_mobile/l10n/localizations.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/src/home_screen.dart';
import 'package:app_mobile/src/language/language_chooser_screen.dart';
import 'package:app_mobile/src/language/language_names.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Counts writes; [pendingWrite] holds writes open until the test completes it;
/// [failWrites] makes every write throw.
class _TestStore extends InMemoryLocaleStore {
  _TestStore({this.pendingWrite, this.failWrites = false});

  final Completer<void>? pendingWrite;
  final bool failWrites;
  int writes = 0;

  @override
  Future<void> write(String languageCode) async {
    writes++;
    if (failWrites) throw StateError('write failed');
    await pendingWrite?.future;
    await super.write(languageCode);
  }
}

const tall = Size(800, 6000);

Future<void> pumpApp(
  WidgetTester tester,
  LocaleController controller, {
  bool firstRun = false,
  Size size = tall,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    App(localeController: controller, firstRun: firstRun),
  );
  await tester.pumpAndSettle();
}

AppLocalizations l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).last));

bool canPop(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator)).canPop();

void main() {
  test('every app language has a name, and exactly four await review', () {
    expect(
      languageNames.keys.toSet(),
      appSupportedLocales.map((l) => l.languageCode).toSet(),
    );
    expect(
      {
        for (final e in languageNames.entries)
          if (e.value.needsReview) e.key,
      },
      {'brx', 'doi', 'mni', 'sat'},
    );
  });

  group('first run', () {
    testWidgets('shows the chooser with all 23 languages, none selected', (
      tester,
    ) async {
      await pumpApp(tester, LocaleController(_TestStore()), firstRun: true);

      expect(find.byType(LanguageChooserScreen), findsOneWidget);
      expect(find.byType(RadioListTile<String>), findsNWidgets(23));
      for (final name in languageNames.values) {
        expect(find.text(name.native), findsWidgets);
      }
      expect(
        tester
            .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
            .groupValue,
        isNull,
      );
      expect(find.text(l10n(tester).chooseyourlanguage), findsOneWidget);
    });

    testWidgets('a choice switches, saves and replaces the chooser with Home', (
      tester,
    ) async {
      final store = _TestStore();
      final controller = LocaleController(store);
      await pumpApp(tester, controller, firstRun: true);

      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();

      expect(controller.value, const Locale('hi'));
      expect(await store.read(), 'hi');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LanguageChooserScreen), findsNothing);
      expect(canPop(tester), isFalse);
      expect(find.text(l10n(tester).home), findsOneWidget);
    });

    testWidgets('choosing English, the current language, still saves it', (
      tester,
    ) async {
      final store = _TestStore();
      await pumpApp(tester, LocaleController(store), firstRun: true);

      await tester.tap(find.text('English').first);
      await tester.pumpAndSettle();

      expect(await store.read(), 'en');
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('repeated taps during a save are ignored', (tester) async {
      final pending = Completer<void>();
      final store = _TestStore(pendingWrite: pending);
      final controller = LocaleController(store);
      await pumpApp(tester, controller, firstRun: true);

      await tester.tap(find.text('हिन्दी'));
      await tester.pump();
      await tester.tap(find.text('हिन्दी'));
      await tester.tap(find.text('தமிழ்'));
      await tester.pump();

      pending.complete();
      await tester.pumpAndSettle();

      expect(store.writes, 1);
      expect(controller.value, const Locale('hi'));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(canPop(tester), isFalse);
    });

    testWidgets('a failed save still switches the language and moves on', (
      tester,
    ) async {
      final controller = LocaleController(_TestStore(failWrites: true));
      await pumpApp(tester, controller, firstRun: true);

      await tester.tap(find.text('தமிழ்'));
      await tester.pumpAndSettle();

      // The failure is reported, not swallowed.
      expect(tester.takeException(), isA<StateError>());
      expect(controller.value, const Locale('ta'));
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('returning user', () {
    testWidgets('opens Home directly in the saved language', (tester) async {
      final controller = LocaleController(InMemoryLocaleStore('ml'));
      await controller.load(supported: {'ml'});
      await pumpApp(tester, controller);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LanguageChooserScreen), findsNothing);
      expect(
        Localizations.localeOf(tester.element(find.byType(HomeScreen))),
        const Locale('ml'),
      );
    });

    testWidgets('Home opens the chooser with the current language selected, '
        'and a choice returns to Home', (tester) async {
      final store = _TestStore();
      final controller = LocaleController(store);
      await pumpApp(tester, controller);

      await tester.tap(find.byTooltip(l10n(tester).languages));
      await tester.pumpAndSettle();
      expect(find.byType(LanguageChooserScreen), findsOneWidget);
      expect(
        tester
            .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
            .groupValue,
        'en',
      );

      await tester.tap(find.text('ਪੰਜਾਬੀ'));
      await tester.pumpAndSettle();

      expect(find.byType(LanguageChooserScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(controller.value, const Locale('pa'));
      expect(await store.read(), 'pa');
    });
  });

  testWidgets('right-to-left languages lay the chooser out right to left', (
    tester,
  ) async {
    for (final code in ['ur', 'ks', 'sd']) {
      await pumpApp(
        tester,
        LocaleController(_TestStore(), fallback: Locale(code)),
        firstRun: true,
      );
      expect(
        Directionality.of(tester.element(find.byType(LanguageChooserScreen))),
        TextDirection.rtl,
        reason: code,
      );
    }
  });

  group('large text and small screens', () {
    for (final size in [const Size(320, 640), const Size(360, 800)]) {
      testWidgets('no overflow at 200% text on ${size.width.toInt()} x '
          '${size.height.toInt()}', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        for (final code in ['en', 'ta', 'ml', 'sat', 'ur']) {
          final controller = LocaleController(
            _TestStore(),
            fallback: Locale(code),
          );
          await pumpApp(tester, controller, firstRun: true, size: size);
          expect(tester.takeException(), isNull, reason: '$code chooser');

          await pumpApp(tester, controller, size: size);
          expect(tester.takeException(), isNull, reason: '$code home');
        }
      });
    }

    testWidgets('the chooser title is shown in full in every language at '
        '200% text on 320 x 640', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      const size = Size(320, 640);

      for (final locale in appSupportedLocales) {
        final code = locale.languageCode;
        await pumpApp(
          tester,
          LocaleController(_TestStore(), fallback: locale),
          firstRun: true,
          size: size,
        );
        final title = find.text(l10n(tester).chooseyourlanguage);
        final paragraph = tester.renderObject<RenderParagraph>(title);
        // Truncated (ellipsis or line limit) text reports exceeding its lines.
        expect(paragraph.didExceedMaxLines, isFalse, reason: code);
        expect(
          (Offset.zero & size).contains(tester.getRect(title).topLeft) &&
              tester.getRect(title).right <= size.width,
          isTrue,
          reason: code,
        );
      }
    });
  });

  group('accessibility guidelines', () {
    for (final brightness in Brightness.values) {
      testWidgets('chooser and Home pass in ${brightness.name} mode', (
        tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final handle = tester.ensureSemantics();
        // Disposed in `finally`: flutter_test checks for live handles at the
        // end of the test body, before tear-down callbacks run.
        try {
          await pumpApp(
            tester,
            LocaleController(_TestStore()),
            firstRun: true,
            size: const Size(360, 800),
          );
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));

          await pumpApp(
            tester,
            LocaleController(_TestStore()),
            size: const Size(360, 800),
          );
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        } finally {
          handle.dispose();
        }
      });
    }
  });
}
