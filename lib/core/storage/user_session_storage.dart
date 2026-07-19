import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  const UserSession({required this.displayName, required this.email});

  final String displayName;
  final String email;
}

class UserSessionStorage {
  UserSessionStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _isSignedInKey = 'user_is_signed_in';
  static const String _displayNameKey = 'user_display_name';
  static const String _emailKey = 'user_email';

  final SharedPreferencesAsync _preferences;

  Future<UserSession?> loadSession() async {
    final isSignedIn = await _preferences.getBool(_isSignedInKey) ?? false;

    if (!isSignedIn) {
      return null;
    }

    final displayName =
        (await _preferences.getString(_displayNameKey))?.trim() ?? '';

    final email = (await _preferences.getString(_emailKey))?.trim() ?? '';

    if (displayName.isEmpty) {
      await clearSession();
      return null;
    }

    return UserSession(displayName: displayName, email: email);
  }

  Future<void> saveSession({
    required String displayName,
    required String email,
  }) async {
    final normalizedDisplayName = displayName.trim();
    final normalizedEmail = email.trim();

    if (normalizedDisplayName.isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'Display name must not be empty.',
      );
    }

    await _preferences.setString(_displayNameKey, normalizedDisplayName);

    await _preferences.setString(_emailKey, normalizedEmail);

    await _preferences.setBool(_isSignedInKey, true);
  }

  Future<void> clearSession() async {
    await _preferences.remove(_isSignedInKey);
    await _preferences.remove(_displayNameKey);
    await _preferences.remove(_emailKey);
  }
}
