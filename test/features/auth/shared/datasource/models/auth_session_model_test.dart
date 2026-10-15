import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/auth/shared/datasource/models/auth_session_model.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';

void main() {
  group('AuthSessionModel', () {
    test('fromJson instantiates correctly with id and email', () {
      final json = {'id': 'user-123-uuid', 'email': 'client@example.com'};

      final model = AuthSessionModel.fromJson(json);

      expect(model, isA<AuthSession>());
      expect(model.userId, 'user-123-uuid');
      expect(model.email, 'client@example.com');
    });

    test('fromJson fallback to user_id when id is absent', () {
      final json = {'user_id': 'user-456-uuid', 'email': 'client2@example.com'};

      final model = AuthSessionModel.fromJson(json);

      expect(model.userId, 'user-456-uuid');
      expect(model.email, 'client2@example.com');
    });

    test('fromJson handles empty json gracefully', () {
      final json = <String, dynamic>{};

      final model = AuthSessionModel.fromJson(json);

      expect(model.userId, '');
      expect(model.email, isNull);
    });

    test('fromJson maps the auth user that verifyOTP returns', () {
      const user = User(
        id: '7c9e6679-7425-40de-944b-e07fc1f90ae7',
        appMetadata: {'provider': 'email'},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-10T08:00:00.000Z',
        email: 'user@watad.sa',
      );

      final model = AuthSessionModel.fromJson(user.toJson());

      expect(model.userId, '7c9e6679-7425-40de-944b-e07fc1f90ae7');
      expect(model.email, 'user@watad.sa');
    });

    test('a user without an email maps to a null email', () {
      final model = AuthSessionModel.fromJson(const {
        'id': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
        'email': null,
      });

      expect(model.email, isNull);
    });
  });
}
