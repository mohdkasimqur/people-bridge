import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoLocalizations, GlobalCupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

import 'app_localizations.dart';

/// All localization delegates for the app, in lookup order.
///
/// The generated `AppLocalizations.localizationsDelegates` is not used: it
/// names the deprecated `flutter_localizations` Material and Cupertino
/// delegates, while this app uses `material_ui` and `cupertino_ui`.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  // Owner decision (2026-11-20): Flutter's own widget text is English for the
  // languages Flutter does not translate; the app's text stays translated.
  _EnglishFallback<MaterialLocalizations>(GlobalMaterialLocalizations.delegate),
  _EnglishFallback<CupertinoLocalizations>(
    GlobalCupertinoLocalizations.delegate,
  ),
  _EnglishWidgetsFallback(),
];

/// The 23 app languages with English first: Flutter falls back to the first
/// entry for a language the app does not support.
final List<Locale> appSupportedLocales = [
  const Locale('en'),
  ...AppLocalizations.supportedLocales.where((l) => l.languageCode != 'en'),
];

class _EnglishFallback<T> extends LocalizationsDelegate<T> {
  const _EnglishFallback(this._framework);

  final LocalizationsDelegate<T> _framework;

  @override
  bool isSupported(Locale locale) => !_framework.isSupported(locale);

  @override
  Future<T> load(Locale locale) => _framework.load(const Locale('en'));

  @override
  bool shouldReload(_EnglishFallback<T> old) => false;
}

class _EnglishWidgetsFallback
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _EnglishWidgetsFallback();

  // Kashmiri and Sindhi are written right to left, but Flutter has no widget
  // localizations for them, so the direction is set here.
  static const _rightToLeft = {'ks', 'sd'};

  @override
  bool isSupported(Locale locale) =>
      !GlobalWidgetsLocalizations.delegate.isSupported(locale);

  @override
  Future<WidgetsLocalizations> load(Locale locale) => SynchronousFuture(
    _EnglishWidgetsLocalizations(
      _rightToLeft.contains(locale.languageCode)
          ? TextDirection.rtl
          : TextDirection.ltr,
    ),
  );

  @override
  bool shouldReload(_EnglishWidgetsFallback old) => false;
}

class _EnglishWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const _EnglishWidgetsLocalizations(this.textDirection);

  @override
  final TextDirection textDirection;
}
