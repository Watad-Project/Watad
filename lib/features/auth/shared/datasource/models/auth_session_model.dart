import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({required super.userId, super.email});

  /// Maps the auth user that `verifyOTP` returns (`User.toJson()`).
  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      userId: json['id'] as String,
      email: json['email'] as String?,
    );
  }
}
