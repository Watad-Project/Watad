import 'package:flutter_test/flutter_test.dart';
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

    test('fromJson handles null values gracefully', () {
      final json = <String, dynamic>{};

      final model = AuthSessionModel.fromJson(json);

      expect(model.userId, '');
      expect(model.email, '');
    });
  });
}
