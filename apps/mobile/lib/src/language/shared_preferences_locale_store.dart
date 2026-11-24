import 'package:app_core/app_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves the chosen language code on the device with [SharedPreferencesAsync].
class SharedPreferencesLocaleStore implements LocaleStore {
  SharedPreferencesLocaleStore(this._preferences);

  static const key = 'app.locale';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(key);

  @override
  Future<void> write(String languageCode) =>
      _preferences.setString(key, languageCode);
}
