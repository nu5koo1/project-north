import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationException implements Exception {
  const AuthenticationException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => message;
}

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
  }

  Future<User> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedName = fullName.trim();
    final normalizedEmail = email.trim();

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw const AuthenticationException(
          code: 'user-not-created',
          message: 'The account could not be created.',
        );
      }

      await user.updateDisplayName(normalizedName);
      await user.sendEmailVerification();
      await user.reload();

      return _firebaseAuth.currentUser ?? user;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  Future<User> signIn({required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw const AuthenticationException(
          code: 'user-not-found',
          message: 'The account could not be found.',
        );
      }

      return user;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  Future<void> resendVerificationEmail() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const AuthenticationException(
        code: 'not-signed-in',
        message: 'Sign in again before requesting a new email.',
      );
    }

    if (user.emailVerified) {
      return;
    }

    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  Future<User> reloadCurrentUser() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const AuthenticationException(
        code: 'not-signed-in',
        message: 'Your session has expired. Sign in again.',
      );
    }

    try {
      await user.reload();

      final refreshedUser = _firebaseAuth.currentUser;

      if (refreshedUser == null) {
        throw const AuthenticationException(
          code: 'not-signed-in',
          message: 'Your session has expired. Sign in again.',
        );
      }

      return refreshedUser;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  AuthenticationException _mapFirebaseException(FirebaseAuthException error) {
    final message = switch (error.code) {
      'email-already-in-use' => 'An account with this email already exists.',
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' => 'Use a password with at least 6 characters.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' => 'No account was found for this email.',
      'wrong-password' => 'The password is incorrect.',
      'invalid-credential' => 'The email or password is incorrect.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      'operation-not-allowed' =>
        'Email and password authentication is not enabled.',
      _ => error.message ?? 'Authentication failed. Please try again.',
    };

    return AuthenticationException(code: error.code, message: message);
  }
}
