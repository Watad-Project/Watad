import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';

/// Data model for [AuthSession], mapping from Supabase [AuthResponse].
class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.userId,
    super.accessToken,
    super.email,
  });

  /// Creates an [AuthSessionModel] from a Supabase [AuthResponse].
  factory AuthSessionModel.fromAuthResponse(AuthResponse response) {
    final user = response.user ?? response.session?.user;
    return AuthSessionModel(
      userId: user?.id ?? '',
      accessToken: response.session?.accessToken,
      email: user?.email,
    );
  }
}
