import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/storage/user_session_storage.dart';
import 'features/authentication/data/firebase_auth_service.dart';
import 'features/authentication/presentation/screens/email_verification_screen.dart';
import 'features/authentication/presentation/screens/sign_up_screen.dart';
import 'features/authentication/presentation/screens/welcome_screen.dart';
import 'features/navigation/presentation/app_shell.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authService = FirebaseAuthService();
  final sessionStorage = UserSessionStorage();
  final firebaseUser = await _loadCurrentFirebaseUser(authService);

  final initialSession = await _restoreVerifiedSession(
    firebaseUser: firebaseUser,
    sessionStorage: sessionStorage,
  );

  runApp(
    ProjectNorthApp(
      authService: authService,
      sessionStorage: sessionStorage,
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
  } on AuthenticationException {
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

  return emailName
      .split(RegExp(r'[._-]+'))
      .where((part) => part.isNotEmpty)
      .map(_capitalize)
      .join(' ');
}

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }

  return '${value[0].toUpperCase()}${value.substring(1)}';
}

class ProjectNorthApp extends StatefulWidget {
  const ProjectNorthApp({
    super.key,
    required this.authService,
    required this.sessionStorage,
    required this.initialSession,
    required this.requiresEmailVerification,
  });

  final FirebaseAuthService authService;
  final UserSessionStorage sessionStorage;
  final UserSession? initialSession;
  final bool requiresEmailVerification;

  @override
  State<ProjectNorthApp> createState() => _ProjectNorthAppState();
}

class _ProjectNorthAppState extends State<ProjectNorthApp> {
  UserSession? _currentSession;
  late bool _requiresEmailVerification;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.initialSession;
    _requiresEmailVerification = widget.requiresEmailVerification;
  }

  Future<void> _completeAuthentication(User user) async {
    final email = (user.email ?? '').trim();
    final firebaseDisplayName = (user.displayName ?? '').trim();

    final displayName = firebaseDisplayName.isNotEmpty
        ? firebaseDisplayName
        : _displayNameFromEmail(email);

    await widget.sessionStorage.saveSession(
      displayName: displayName,
      email: email,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _currentSession = UserSession(displayName: displayName, email: email);
      _requiresEmailVerification = false;
    });
  }

  void _requireEmailVerification() {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentSession = null;
      _requiresEmailVerification = true;
    });
  }

  Future<bool> _checkEmailVerification() async {
    final user = await widget.authService.reloadCurrentUser();

    if (!user.emailVerified) {
      return false;
    }

    await _completeAuthentication(user);
    return true;
  }

  Future<void> _resendVerificationEmail() async {
    await widget.authService.resendVerificationEmail();
  }

  Future<void> _signOut() async {
    try {
      await widget.authService.signOut();
    } finally {
      await widget.sessionStorage.clearSession();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _currentSession = null;
      _requiresEmailVerification = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _currentSession;
    final firebaseUser = widget.authService.currentUser;

    Widget home;

    if (_requiresEmailVerification && firebaseUser != null) {
      home = EmailVerificationScreen(
        email: firebaseUser.email ?? '',
        onCheckVerification: _checkEmailVerification,
        onResendEmail: _resendVerificationEmail,
        onSignOut: _signOut,
      );
    } else if (session != null) {
      home = AppShell(
        key: ValueKey('${session.displayName}:${session.email}'),
        displayName: session.displayName,
        email: session.email,
        onSignOut: _signOut,
      );
    } else {
      home = _AuthenticationEntry(
        authService: widget.authService,
        onAuthenticated: _completeAuthentication,
        onVerificationRequired: _requireEmailVerification,
      );
    }

    return MaterialApp(
      title: 'VILLMARK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E2C1B)),
      ),
      home: home,
    );
  }
}

class _AuthenticationEntry extends StatelessWidget {
  const _AuthenticationEntry({
    required this.authService,
    required this.onAuthenticated,
    required this.onVerificationRequired,
  });

  final FirebaseAuthService authService;
  final Future<void> Function(User user) onAuthenticated;
  final VoidCallback onVerificationRequired;

  void _openSignUp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (signUpContext) {
          return SignUpScreen(
            onAccountCreated: (result) async {
              final user = await authService.signUp(
                fullName: result.fullName,
                email: result.email,
                password: result.password,
              );

              if (user.emailVerified) {
                await onAuthenticated(user);
              } else {
                onVerificationRequired();
              }

              if (!signUpContext.mounted) {
                return;
              }

              Navigator.of(signUpContext).popUntil((route) => route.isFirst);
            },
          );
        },
      ),
    );
  }

  Future<void> _signIn({
    required String email,
    required String password,
  }) async {
    final user = await authService.signIn(email: email, password: password);

    if (!user.emailVerified) {
      onVerificationRequired();
      return;
    }

    await onAuthenticated(user);
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    await authService.sendPasswordResetEmail(email: email);
  }

  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      onSignInPressed: _signIn,
      onSignUpPressed: () {
        _openSignUp(context);
      },
      onForgotPasswordPressed: _sendPasswordResetEmail,
    );
  }
}
