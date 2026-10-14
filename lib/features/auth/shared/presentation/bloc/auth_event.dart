part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

/// The user typed in the email field.
final class AuthEmailChanged extends AuthEvent {
  const AuthEmailChanged(this.email);

  final String email;
}

/// The user typed in the code boxes.
final class AuthOtpChanged extends AuthEvent {
  const AuthOtpChanged(this.otp);

  final String otp;
}

/// The user asked for a code: the first one, or again once the countdown
/// has ended.
final class AuthOtpRequested extends AuthEvent {
  const AuthOtpRequested();
}

/// The user filled the code boxes or tapped confirm after a code was sent.
final class AuthOtpSubmitted extends AuthEvent {
  const AuthOtpSubmitted();
}

/// One second of the resend countdown went by.
final class AuthCountdownTicked extends AuthEvent {
  const AuthCountdownTicked();
}
