import 'dart:async';
import 'dart:ui' show Locale;

import 'package:app_core/app_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const supported = {'en', 'hi', 'ta'};
const short = Duration(milliseconds: 20);

class _CountingStore extends InMemoryLocaleStore {
  int writes = 0;

  @override
  Future<void> write(String languageCode) {
    writes++;
    return super.write(languageCode);
  }
}

/// A store whose read and write are controlled by the test.
class _ControlledStore implements LocaleStore {
  _ControlledStore({this.readResult, this.writeError});

  final Future<String?>? readResult;
  final Object? writeError;

  @override
  Future<String?> read() => readResult ?? Future.value();

  @override
  Future<void> write(String languageCode) async {
    if (writeError != null) throw writeError!;
  }
}

/// Collects errors sent to [FlutterError.reportError] during [body].
Future<List<FlutterErrorDetails>> reported(Future<void> Function() body) async {
  final errors = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = errors.add;
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

void main() {
  test('starts at the fallback locale', () {
    final controller = LocaleController(InMemoryLocaleStore());
    expect(controller.value, const Locale('en'));
  });

  group('load', () {
    test('restores a saved supported locale', () async {
      final controller = LocaleController(InMemoryLocaleStore('hi'));
      expect(
        await controller.load(supported: supported),
        LocaleLoadResult.saved,
      );
      expect(controller.value, const Locale('hi'));
    });

    test('keeps the fallback when nothing is saved', () async {
      final controller = LocaleController(
        InMemoryLocaleStore(),
        fallback: const Locale('ta'),
      );
      expect(
        await controller.load(supported: supported),
        LocaleLoadResult.none,
      );
      expect(controller.value, const Locale('ta'));
    });

    test('ignores an unsupported saved value', () async {
      final controller = LocaleController(InMemoryLocaleStore('xx'));
      expect(
        await controller.load(supported: supported),
        LocaleLoadResult.unsupported,
      );
      expect(controller.value, const Locale('en'));
    });

    test('reports a read error and keeps the fallback', () async {
      final controller = LocaleController(
        _ControlledStore(readResult: Future.error(StateError('corrupt'))),
      );
      late LocaleLoadResult result;
      final errors = await reported(
        () async => result = await controller.load(supported: supported),
      );
      expect(result, LocaleLoadResult.failed);
      expect(controller.value, const Locale('en'));
      expect(errors.single.exception, isA<StateError>());
    });

    test('times out, and a late read never changes the locale', () async {
      final slowRead = Completer<String?>();
      final controller = LocaleController(
        _ControlledStore(readResult: slowRead.future),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      late LocaleLoadResult result;
      final errors = await reported(
        () async => result = await controller.load(
          supported: supported,
          timeout: short,
        ),
      );
      expect(result, LocaleLoadResult.failed);
      expect(errors.single.exception, isA<TimeoutException>());

      slowRead.complete('hi');
      await Future<void>.delayed(short);
      expect(controller.value, const Locale('en'));
      expect(notifications, 0);
    });
  });

  group('setLocale', () {
    test('notifies listeners once and saves the language', () async {
      final store = _CountingStore();
      final controller = LocaleController(store);
      var notifications = 0;
      controller.addListener(() => notifications++);

      expect(await controller.setLocale(const Locale('ta')), isTrue);

      expect(controller.value, const Locale('ta'));
      expect(notifications, 1);
      expect(store.writes, 1);
      expect(await store.read(), 'ta');
    });

    test('with the current locale saves it without notifying', () async {
      final store = _CountingStore();
      final controller = LocaleController(store);
      var notifications = 0;
      controller.addListener(() => notifications++);

      expect(await controller.setLocale(const Locale('en')), isTrue);

      expect(notifications, 0);
      expect(store.writes, 1);
      expect(await store.read(), 'en');
    });

    test('keeps the switch when saving fails, and reports it', () async {
      final controller = LocaleController(
        _ControlledStore(writeError: StateError('disk full')),
      );
      late bool saved;
      final errors = await reported(
        () async => saved = await controller.setLocale(const Locale('hi')),
      );
      expect(saved, isFalse);
      expect(controller.value, const Locale('hi'));
      expect(errors.single.exception, isA<StateError>());
    });
  });
}
