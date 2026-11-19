import 'dart:ui' show Locale;

import 'package:app_core/app_core.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingStore extends InMemoryLocaleStore {
  int writes = 0;

  @override
  Future<void> write(String languageCode) {
    writes++;
    return super.write(languageCode);
  }
}

void main() {
  test('starts at the fallback locale', () {
    final controller = LocaleController(InMemoryLocaleStore());
    expect(controller.value, const Locale('en'));
  });

  test('load restores the saved locale', () async {
    final controller = LocaleController(InMemoryLocaleStore('hi'));
    await controller.load();
    expect(controller.value, const Locale('hi'));
  });

  test('load keeps the fallback when nothing is saved', () async {
    final controller = LocaleController(
      InMemoryLocaleStore(),
      fallback: const Locale('ml'),
    );
    await controller.load();
    expect(controller.value, const Locale('ml'));
  });

  test('setLocale notifies listeners once and saves the language', () async {
    final store = _CountingStore();
    final controller = LocaleController(store);
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setLocale(const Locale('ta'));

    expect(controller.value, const Locale('ta'));
    expect(notifications, 1);
    expect(store.writes, 1);
    expect(await store.read(), 'ta');
  });

  test(
    'setLocale with the current locale neither notifies nor saves',
    () async {
      final store = _CountingStore();
      final controller = LocaleController(store);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setLocale(const Locale('en'));

      expect(notifications, 0);
      expect(store.writes, 0);
    },
  );
}
