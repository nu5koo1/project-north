import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project_north/features/authentication/data/firebase_auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth firebaseAuth;
  late MockUserCredential userCredential;
  late MockUser user;
  late FirebaseAuthService service;

  setUp(() {
    firebaseAuth = MockFirebaseAuth();
    userCredential = MockUserCredential();
    user = MockUser();

    service = FirebaseAuthService(firebaseAuth: firebaseAuth);
  });

  group('FirebaseAuthService.signUp', () {
    test(
      'creates user, updates display name and sends verification email',
      () async {
        when(
          () => firebaseAuth.createUserWithEmailAndPassword(
            email: 'alex@example.com',
            password: 'password123',
          ),
        ).thenAnswer((_) async => userCredential);

        when(() => userCredential.user).thenReturn(user);

        when(
          () => user.updateDisplayName('Alex North'),
        ).thenAnswer((_) async {});

        when(() => user.sendEmailVerification()).thenAnswer((_) async {});

        when(() => user.reload()).thenAnswer((_) async {});

        when(() => firebaseAuth.currentUser).thenReturn(user);

        final result = await service.signUp(
          fullName: '  Alex North  ',
          email: '  alex@example.com  ',
          password: 'password123',
        );

        expect(result, same(user));

        verify(
          () => firebaseAuth.createUserWithEmailAndPassword(
            email: 'alex@example.com',
            password: 'password123',
          ),
        ).called(1);

        verify(() => user.updateDisplayName('Alex North')).called(1);

        verify(() => user.sendEmailVerification()).called(1);

        verify(() => user.reload()).called(1);
      },
    );

    test('throws when Firebase does not return a user', () async {
      when(
        () => firebaseAuth.createUserWithEmailAndPassword(
          email: 'alex@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => userCredential);

      when(() => userCredential.user).thenReturn(null);

      await expectLater(
        service.signUp(
          fullName: 'Alex North',
          email: 'alex@example.com',
          password: 'password123',
        ),
        throwsA(
          isA<AuthenticationException>()
              .having((exception) => exception.code, 'code', 'user-not-created')
              .having(
                (exception) => exception.message,
                'message',
                'The account could not be created.',
              ),
        ),
      );
    });

    test('maps email-already-in-use error', () async {
      when(
        () => firebaseAuth.createUserWithEmailAndPassword(
          email: 'alex@example.com',
          password: 'password123',
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      await expectLater(
        service.signUp(
          fullName: 'Alex North',
          email: 'alex@example.com',
          password: 'password123',
        ),
        throwsA(
          isA<AuthenticationException>()
              .having(
                (exception) => exception.code,
                'code',
                'email-already-in-use',
              )
              .having(
                (exception) => exception.message,
                'message',
                'An account with this email already exists.',
              ),
        ),
      );
    });
  });

  group('FirebaseAuthService.signIn', () {
    test('signs in using normalized email', () async {
      when(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: 'alex@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => userCredential);

      when(() => userCredential.user).thenReturn(user);

      final result = await service.signIn(
        email: '  alex@example.com  ',
        password: 'password123',
      );

      expect(result, same(user));

      verify(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: 'alex@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('maps invalid credential error', () async {
      when(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: 'alex@example.com',
          password: 'wrong-password',
        ),
      ).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

      await expectLater(
        service.signIn(email: 'alex@example.com', password: 'wrong-password'),
        throwsA(
          isA<AuthenticationException>()
              .having(
                (exception) => exception.code,
                'code',
                'invalid-credential',
              )
              .having(
                (exception) => exception.message,
                'message',
                'The email or password is incorrect.',
              ),
        ),
      );
    });

    test('maps network error', () async {
      when(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: 'alex@example.com',
          password: 'password123',
        ),
      ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      await expectLater(
        service.signIn(email: 'alex@example.com', password: 'password123'),
        throwsA(
          isA<AuthenticationException>().having(
            (exception) => exception.message,
            'message',
            'Check your internet connection and try again.',
          ),
        ),
      );
    });
  });

  group('FirebaseAuthService.reloadCurrentUser', () {
    test('reloads and returns refreshed user', () async {
      final refreshedUser = MockUser();
      var currentUserCallCount = 0;

      when(() => firebaseAuth.currentUser).thenAnswer((_) {
        currentUserCallCount++;

        if (currentUserCallCount == 1) {
          return user;
        }

        return refreshedUser;
      });

      when(() => user.reload()).thenAnswer((_) async {});

      final result = await service.reloadCurrentUser();

      expect(result, same(refreshedUser));

      verify(() => user.reload()).called(1);
    });

    test('throws when no user is signed in', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);

      await expectLater(
        service.reloadCurrentUser(),
        throwsA(
          isA<AuthenticationException>()
              .having((exception) => exception.code, 'code', 'not-signed-in')
              .having(
                (exception) => exception.message,
                'message',
                'Your session has expired. Sign in again.',
              ),
        ),
      );
    });
  });

  group('FirebaseAuthService.resendVerificationEmail', () {
    test('sends email for unverified user', () async {
      when(() => firebaseAuth.currentUser).thenReturn(user);

      when(() => user.emailVerified).thenReturn(false);

      when(() => user.sendEmailVerification()).thenAnswer((_) async {});

      await service.resendVerificationEmail();

      verify(() => user.sendEmailVerification()).called(1);
    });

    test('does not send email for verified user', () async {
      when(() => firebaseAuth.currentUser).thenReturn(user);

      when(() => user.emailVerified).thenReturn(true);

      await service.resendVerificationEmail();

      verifyNever(() => user.sendEmailVerification());
    });

    test('throws when no user is signed in', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);

      await expectLater(
        service.resendVerificationEmail(),
        throwsA(
          isA<AuthenticationException>().having(
            (exception) => exception.code,
            'code',
            'not-signed-in',
          ),
        ),
      );
    });
  });

  group('FirebaseAuthService.sendPasswordResetEmail', () {
    test('sends password reset email', () async {
      when(
        () => firebaseAuth.sendPasswordResetEmail(email: 'alex@example.com'),
      ).thenAnswer((_) async {});

      await service.sendPasswordResetEmail(email: '  alex@example.com  ');

      verify(
        () => firebaseAuth.sendPasswordResetEmail(email: 'alex@example.com'),
      ).called(1);
    });
  });

  group('FirebaseAuthService.signOut', () {
    test('signs out from Firebase', () async {
      when(() => firebaseAuth.signOut()).thenAnswer((_) async {});

      await service.signOut();

      verify(() => firebaseAuth.signOut()).called(1);
    });
  });
}
