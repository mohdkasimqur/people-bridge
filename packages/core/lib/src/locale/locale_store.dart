/// Persists the user's chosen language code.
abstract interface class LocaleStore {
  Future<String?> read();

  Future<void> write(String languageCode);
}

/// Keeps the language code in memory only (tests, and until persistence is chosen).
class InMemoryLocaleStore implements LocaleStore {
  InMemoryLocaleStore([this._languageCode]);

  String? _languageCode;

  @override
  Future<String?> read() async => _languageCode;

  @override
  Future<void> write(String languageCode) async => _languageCode = languageCode;
}
