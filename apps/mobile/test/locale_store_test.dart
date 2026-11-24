import 'package:app_mobile/src/language/shared_preferences_locale_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fakes only the two methods the store uses; any other call fails the test.
class _FakePreferences implements SharedPreferencesAsync {
  _FakePreferences({this.failReads = false, this.failWrites = false});

  final bool failReads;
  final bool failWrites;
  final Map<String, String> values = {};

  @override
  Future<String?> getString(String key) async {
    if (failReads) throw StateError('read failed');
    return values[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    if (failWrites) throw StateError('write failed');
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('reads nothing before a language is saved', () async {
    final store = SharedPreferencesLocaleStore(_FakePreferences());
    expect(await store.read(), isNull);
  });

  test('saves the language code under its key and reads it back', () async {
    final preferences = _FakePreferences();
    final store = SharedPreferencesLocaleStore(preferences);

    await store.write('sat');

    expect(preferences.values, {SharedPreferencesLocaleStore.key: 'sat'});
    expect(await store.read(), 'sat');
  });

  test('passes read and write failures to the caller', () async {
    expect(
      SharedPreferencesLocaleStore(_FakePreferences(failReads: true)).read(),
      throwsStateError,
    );
    expect(
      SharedPreferencesLocaleStore(_FakePreferences(failWrites: true))
          .write('hi'),
      throwsStateError,
    );
  });
}
