import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';

import 'locale_store.dart';

/// What [LocaleController.load] found.
enum LocaleLoadResult {
  /// A supported language was saved and is now current.
  saved,

  /// Nothing was saved: a first run.
  none,

  /// A language was saved that the app does not support.
  unsupported,

  /// Reading failed or took longer than the timeout.
  failed,
}

/// Holds the app's current locale.
///
/// D9: built-in [ValueNotifier]; the store is injected through the constructor.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController(this._store, {Locale fallback = const Locale('en')})
    : super(fallback);

  final LocaleStore _store;

  /// Restores the saved locale if it is one of [supported].
  ///
  /// Otherwise the fallback stays current. A read that is still running when
  /// [timeout] expires is ignored, so it can never change the locale later.
  /// Read errors and timeouts are reported to [FlutterError.reportError].
  Future<LocaleLoadResult> load({
    required Set<String> supported,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final String? languageCode;
    try {
      languageCode = await _store.read().timeout(timeout);
    } catch (error, stack) {
      _report(error, stack, 'while reading the saved language');
      return LocaleLoadResult.failed;
    }
    if (languageCode == null) return LocaleLoadResult.none;
    if (!supported.contains(languageCode)) return LocaleLoadResult.unsupported;
    value = Locale(languageCode);
    return LocaleLoadResult.saved;
  }

  /// Switches to [locale] at once, then saves it.
  ///
  /// Listeners are notified only if the locale changed, but the choice is
  /// always saved, so a first-run choice of the current language persists.
  /// Returns false if saving failed or timed out; the switch still stands for
  /// this session and the error is reported to [FlutterError.reportError].
  Future<bool> setLocale(
    Locale locale, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    value = locale;
    try {
      await _store.write(locale.languageCode).timeout(timeout);
      return true;
    } catch (error, stack) {
      _report(error, stack, 'while saving the chosen language');
      return false;
    }
  }

  void _report(Object error, StackTrace stack, String context) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'app_core',
        context: ErrorDescription(context),
      ),
    );
  }
}
