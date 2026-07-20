import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesStorage {
  AppPreferencesStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _languageCodeKey = 'app_language_code';

  final SharedPreferencesAsync _preferences;

  Future<String?> loadLanguageCode() async {
    final languageCode = await _preferences.getString(_languageCodeKey);

    if (languageCode == null) {
      return null;
    }

    final normalizedLanguageCode = languageCode.trim().toLowerCase();

    if (normalizedLanguageCode != 'en' && normalizedLanguageCode != 'nb') {
      await _preferences.remove(_languageCodeKey);
      return null;
    }

    return normalizedLanguageCode;
  }

  Future<void> saveLanguageCode(String languageCode) async {
    final normalizedLanguageCode = languageCode.trim().toLowerCase();

    if (normalizedLanguageCode != 'en' && normalizedLanguageCode != 'nb') {
      throw ArgumentError.value(
        languageCode,
        'languageCode',
        'Supported language codes are en and nb.',
      );
    }

    await _preferences.setString(_languageCodeKey, normalizedLanguageCode);
  }

  Future<void> clearLanguageCode() async {
    await _preferences.remove(_languageCodeKey);
  }
}
