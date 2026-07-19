import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project_north/core/storage/user_session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
  late MockSharedPreferencesAsync preferences;
  late UserSessionStorage storage;

  setUp(() {
    preferences = MockSharedPreferencesAsync();

    storage = UserSessionStorage(preferences: preferences);
  });

  group('UserSessionStorage.loadSession', () {
    test('returns null when signed-in flag is false', () async {
      when(
        () => preferences.getBool('user_is_signed_in'),
      ).thenAnswer((_) async => false);

      final session = await storage.loadSession();

      expect(session, isNull);

      verify(() => preferences.getBool('user_is_signed_in')).called(1);

      verifyNever(() => preferences.getString('user_display_name'));

      verifyNever(() => preferences.getString('user_email'));
    });

    test('returns saved session', () async {
      when(
        () => preferences.getBool('user_is_signed_in'),
      ).thenAnswer((_) async => true);

      when(
        () => preferences.getString('user_display_name'),
      ).thenAnswer((_) async => '  Alex North  ');

      when(
        () => preferences.getString('user_email'),
      ).thenAnswer((_) async => '  alex@example.com  ');

      final session = await storage.loadSession();

      expect(session, isNotNull);
      expect(session?.displayName, 'Alex North');
      expect(session?.email, 'alex@example.com');
    });

    test('clears invalid session without display name', () async {
      when(
        () => preferences.getBool('user_is_signed_in'),
      ).thenAnswer((_) async => true);

      when(
        () => preferences.getString('user_display_name'),
      ).thenAnswer((_) async => '   ');

      when(
        () => preferences.getString('user_email'),
      ).thenAnswer((_) async => 'alex@example.com');

      when(() => preferences.remove(any())).thenAnswer((_) async {});

      final session = await storage.loadSession();

      expect(session, isNull);

      verify(() => preferences.remove('user_is_signed_in')).called(1);

      verify(() => preferences.remove('user_display_name')).called(1);

      verify(() => preferences.remove('user_email')).called(1);
    });
  });

  group('UserSessionStorage.saveSession', () {
    test('saves normalized display name and email', () async {
      when(() => preferences.setString(any(), any())).thenAnswer((_) async {});

      when(() => preferences.setBool(any(), any())).thenAnswer((_) async {});

      await storage.saveSession(
        displayName: '  Alex North  ',
        email: '  alex@example.com  ',
      );

      verify(
        () => preferences.setString('user_display_name', 'Alex North'),
      ).called(1);

      verify(
        () => preferences.setString('user_email', 'alex@example.com'),
      ).called(1);

      verify(() => preferences.setBool('user_is_signed_in', true)).called(1);
    });

    test('throws when display name is empty', () async {
      await expectLater(
        storage.saveSession(displayName: '   ', email: 'alex@example.com'),
        throwsArgumentError,
      );

      verifyNever(() => preferences.setString(any(), any()));

      verifyNever(() => preferences.setBool(any(), any()));
    });
  });

  group('UserSessionStorage.clearSession', () {
    test('removes all session values', () async {
      when(() => preferences.remove(any())).thenAnswer((_) async {});

      await storage.clearSession();

      verify(() => preferences.remove('user_is_signed_in')).called(1);

      verify(() => preferences.remove('user_display_name')).called(1);

      verify(() => preferences.remove('user_email')).called(1);
    });
  });
}
