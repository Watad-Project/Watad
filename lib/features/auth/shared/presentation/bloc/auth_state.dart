part of 'auth_bloc.dart';

/// Status phases of the login-with-OTP flow.
enum AuthStatus {
  /// No backend call in progress.
  initial,

  /// Sending the OTP email.
  sendingOtp,

  /// OTP email sent successfully.
  otpSent,

  /// Verifying the entered OTP.
  verifyingOtp,

  /// OTP verified; user is authenticated.
  verified,
}

/// State of the login-with-OTP form.
final class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.email = '',
    this.otp = '',
    this.emailError,
    this.otpError,
    this.resendSeconds = 0,
    this.message,
    this.session,
  });

  /// Current phase of the authentication flow.
  final AuthStatus status;

  /// Current email text.
  final String email;

  /// Current OTP text.
  final String otp;

  /// Translation key for the email field error, or `null` when valid.
  final String? emailError;

  /// Translation key for the OTP field error, or `null` when valid.
  final String? otpError;

  /// Seconds remaining before the resend button becomes active.
  final int resendSeconds;

  /// A one-shot translation key shown as a snackbar (e.g. error or feedback).
  final String? message;

  /// The authenticated user session once verified.
  final AuthSession? session;

  /// Whether the resend button is enabled.
  bool get canResend => resendSeconds == 0;

  /// Whether a backend call is in progress.
  bool get isLoading =>
      status == AuthStatus.sendingOtp || status == AuthStatus.verifyingOtp;

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? otp,
    Object? emailError = _sentinel,
    Object? otpError = _sentinel,
    int? resendSeconds,
    Object? message = _sentinel,
    Object? session = _sentinel,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      otp: otp ?? this.otp,
      emailError: identical(emailError, _sentinel)
          ? this.emailError
          : emailError as String?,
      otpError: identical(otpError, _sentinel)
          ? this.otpError
          : otpError as String?,
      resendSeconds: resendSeconds ?? this.resendSeconds,
      message: identical(message, _sentinel)
          ? this.message
          : message as String?,
      session: identical(session, _sentinel)
          ? this.session
          : session as AuthSession?,
    );
  }
}

const Object _sentinel = Object();
