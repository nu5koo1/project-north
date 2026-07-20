import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app_controller.dart';
import 'app/villmark_app.dart';
import 'core/storage/app_preferences_storage.dart';
import 'core/storage/user_session_storage.dart';
import 'features/authentication/data/firebase_auth_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authService = FirebaseAuthService();
  final sessionStorage = UserSessionStorage();

  final appController = AppController(AppPreferencesStorage());

  await appController.initialize();

  final firebaseUser = await _loadCurrentFirebaseUser(authService);

  final initialSession = await _restoreVerifiedSession(
    firebaseUser: firebaseUser,
    sessionStorage: sessionStorage,
  );

  runApp(
    VillmarkApp(
      authService: authService,
      sessionStorage: sessionStorage,
      appController: appController,
      initialSession: initialSession,
      requiresEmailVerification:
          firebaseUser != null && !firebaseUser.emailVerified,
    ),
  );
}

Future<User?> _loadCurrentFirebaseUser(FirebaseAuthService authService) async {
  final cachedUser = authService.currentUser;

  if (cachedUser == null) {
    return null;
  }

  try {
    return await authService.reloadCurrentUser();
  } on AuthenticationException catch (error) {
    if (error.code == 'network-request-failed') {
      return authService.currentUser;
    }

    if (error.code == 'not-signed-in' ||
        error.code == 'user-token-expired' ||
        error.code == 'invalid-user-token') {
      return null;
    }

    return authService.currentUser;
  }
}

Future<UserSession?> _restoreVerifiedSession({
  required User? firebaseUser,
  required UserSessionStorage sessionStorage,
}) async {
  if (firebaseUser == null || !firebaseUser.emailVerified) {
    await sessionStorage.clearSession();
    return null;
  }

  final savedSession = await sessionStorage.loadSession();

  final email = (firebaseUser.email ?? savedSession?.email ?? '').trim();

  final firebaseDisplayName = (firebaseUser.displayName ?? '').trim();

  final savedDisplayName = (savedSession?.displayName ?? '').trim();

  final displayName = firebaseDisplayName.isNotEmpty
      ? firebaseDisplayName
      : savedDisplayName.isNotEmpty
      ? savedDisplayName
      : _displayNameFromEmail(email);

  await sessionStorage.saveSession(displayName: displayName, email: email);

  return UserSession(displayName: displayName, email: email);
}

String _displayNameFromEmail(String email) {
  final normalizedEmail = email.trim();

  if (!normalizedEmail.contains('@')) {
    return 'Traveler';
  }

  final emailName = normalizedEmail.split('@').first.trim();

  if (emailName.isEmpty) {
    return 'Traveler';
  }

  final displayName = emailName
      .split(RegExp(r'[._-]+'))
      .where((part) => part.isNotEmpty)
      .map(_capitalize)
      .join(' ');

  if (displayName.isEmpty) {
    return 'Traveler';
  }

  return displayName;
}

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }

  return '${value[0].toUpperCase()}${value.substring(1)}';
}
