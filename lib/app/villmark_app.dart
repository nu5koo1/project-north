import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/storage/user_session_storage.dart';
import '../core/theme/app_theme.dart';
import '../features/authentication/data/firebase_auth_service.dart';
import '../features/authentication/presentation/screens/email_verification_screen.dart';
import '../features/authentication/presentation/screens/sign_up_screen.dart';
import '../features/authentication/presentation/screens/welcome_screen.dart';
import '../features/navigation/presentation/app_shell.dart';
import '../l10n/app_localizations.dart';
import 'app_controller.dart';

class VillmarkApp extends StatefulWidget {
  const VillmarkApp({
    super.key,
    required this.authService,
    required this.sessionStorage,
    required this.appController,
    required this.initialSession,
    required this.requiresEmailVerification,
  });

  final FirebaseAuthService authService;
  final UserSessionStorage sessionStorage;
  final AppController appController;
  final UserSession? initialSession;
  final bool requiresEmailVerification;

  @override
  State<VillmarkApp> createState() => _VillmarkAppState();
}

class _VillmarkAppState extends State<VillmarkApp> {
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
    Object? signOutError;
    StackTrace? signOutStackTrace;

    try {
      await widget.authService.signOut();
    } catch (error, stackTrace) {
      signOutError = error;
      signOutStackTrace = stackTrace;
    }

    await widget.sessionStorage.clearSession();

    if (mounted) {
      setState(() {
        _currentSession = null;
        _requiresEmailVerification = false;
      });
    }

    if (signOutError != null && signOutStackTrace != null) {
      Error.throwWithStackTrace(signOutError, signOutStackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appController,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) {
            return AppLocalizations.of(context).appName;
          },
          locale: widget.appController.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: _resolveLocale,
          theme: AppTheme.lightTheme,
          home: _buildHome(),
        );
      },
    );
  }

  Locale _resolveLocale(Locale? locale, Iterable<Locale> supportedLocales) {
    if (locale == null) {
      return AppController.englishLocale;
    }

    final languageCode = locale.languageCode.toLowerCase();

    if (languageCode == 'nb' || languageCode == 'no' || languageCode == 'nn') {
      return AppController.norwegianBokmalLocale;
    }

    return AppController.englishLocale;
  }

  Widget _buildHome() {
    final session = _currentSession;
    final firebaseUser = widget.authService.currentUser;

    if (_requiresEmailVerification && firebaseUser != null) {
      return EmailVerificationScreen(
        email: firebaseUser.email ?? '',
        onCheckVerification: _checkEmailVerification,
        onResendEmail: _resendVerificationEmail,
        onSignOut: _signOut,
      );
    }

    if (session != null) {
      return AppShell(
        key: ValueKey('${session.displayName}:${session.email}'),
        displayName: session.displayName,
        email: session.email,
        appController: widget.appController,
        onSignOut: _signOut,
      );
    }

    return _AuthenticationEntry(
      authService: widget.authService,
      onAuthenticated: _completeAuthentication,
      onVerificationRequired: _requireEmailVerification,
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
