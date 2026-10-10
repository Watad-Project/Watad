part of 'auth_bloc.dart';

enum AuthStatus {
  /// Waiting for the user.
  idle,

  /// Sending a code to the email.
  sendingCode,

  /// Checking the code.
  verifying,

  /// The code was right: the user is signed in.
  signedIn,
}

/// The login form. Field errors stay until the field changes; the
/// snack bar messages are shown once, so every new state drops them.
final class AuthState {
  const AuthState({
    this.email = '',
    this.otp = '',
    this.status = AuthStatus.idle,
    this.codeSent = false,
    this.resendSeconds = 0,
    this.emailError,
    this.otpError,
    this.successMessage,
    this.errorMessage,
  });

  final String email;
  final String otp;
  final AuthStatus status;

  /// Whether a code went to [email].
  final bool codeSent;

  /// Seconds before another code can be asked for.
  final int resendSeconds;

  /// Translation keys of the field errors.
  final String? emailError;
  final String? otpError;

  /// Translation keys for a snack bar, for this state only.
  final String? successMessage;
  final String? errorMessage;

  bool get isBusy =>
      status == AuthStatus.sendingCode || status == AuthStatus.verifying;

  bool get canResend => codeSent && resendSeconds == 0;

  /// Pass `null` to clear a field error; leave it out to keep it.
  AuthState copyWith({
    String? otp,
    AuthStatus? status,
    bool? codeSent,
    int? resendSeconds,
    Object? emailError = _keep,
    Object? otpError = _keep,
    String? successMessage,
    String? errorMessage,
  }) {
    return AuthState(
      email: email,
      otp: otp ?? this.otp,
      status: status ?? this.status,
      codeSent: codeSent ?? this.codeSent,
      resendSeconds: resendSeconds ?? this.resendSeconds,
      emailError: identical(emailError, _keep)
          ? this.emailError
          : emailError as String?,
      otpError: identical(otpError, _keep)
          ? this.otpError
          : otpError as String?,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

const Object _keep = Object();
