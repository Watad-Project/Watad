import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/auth/shared/datasource/models/auth_session_model.dart';

void main() {
  test('fromAuthResponse maps User and Session properly', () {
    const user = User(
      id: 'usr-123',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-10-10T00:00:00.000Z',
      email: 'user@watad.sa',
    );
    final session = Session(
      accessToken: 'jwt-access-token',
      tokenType: 'bearer',
      user: user,
    );
    final response = AuthResponse(session: session, user: user);

    final model = AuthSessionModel.fromAuthResponse(response);

    expect(model.userId, 'usr-123');
    expect(model.accessToken, 'jwt-access-token');
    expect(model.email, 'user@watad.sa');
  });
}
