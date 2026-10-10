part of 'auth_bloc.dart';

/// Events for the login-with-OTP flow.
sealed class AuthEvent {
  const AuthEvent();
}

/// The user changed the email text field.
final class AuthEmailChanged extends AuthEvent {
  const AuthEmailChanged(this.email);

  /// The current email text.
  final String email;
}

/// The user changed the OTP input.
final class AuthOtpChanged extends AuthEvent {
  const AuthOtpChanged(this.otp);

  /// The current OTP text.
  final String otp;
}

/// The user tapped the confirm button or completed the OTP input.
final class AuthOtpSubmitted extends AuthEvent {
  const AuthOtpSubmitted();
}

/// The user tapped the resend code button.
final class AuthResendRequested extends AuthEvent {
  const AuthResendRequested();
}

/// One second of the resend countdown elapsed.
final class AuthCountdownTicked extends AuthEvent {
  const AuthCountdownTicked();
}
