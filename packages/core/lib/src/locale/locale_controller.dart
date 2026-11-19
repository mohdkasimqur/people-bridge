import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';

import 'locale_store.dart';

/// Holds the app's current locale.
///
/// D9: built-in [ValueNotifier]; the store is injected through the constructor.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController(this._store, {Locale fallback = const Locale('en')})
    : super(fallback);

  final LocaleStore _store;

  /// Restores the saved locale; keeps the fallback when none is saved.
  Future<void> load() async {
    final languageCode = await _store.read();
    if (languageCode != null) value = Locale(languageCode);
  }

  /// Switches to [locale] and saves it. Does nothing if it is already current.
  Future<void> setLocale(Locale locale) async {
    if (locale == value) return;
    value = locale;
    await _store.write(locale.languageCode);
  }
}
