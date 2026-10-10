import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/email_otp.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Login with an email code: send a code to the email, wait before it can
/// be sent again, then check the code.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._sendOtp, this._verifyOtp) : super(const AuthState()) {
    on<AuthEmailChanged>(_onEmailChanged);
    on<AuthOtpChanged>(_onOtpChanged);
    on<AuthOtpRequested>(_onOtpRequested);
    on<AuthOtpSubmitted>(_onOtpSubmitted);
    on<AuthCountdownTicked>(_onCountdownTicked);
  }

  /// Supabase sends a new code to the same email at most once a minute.
  static const int resendCooldownSeconds = 60;

  final SendOtpUseCase _sendOtp;
  final VerifyOtpUseCase _verifyOtp;
  Timer? _countdown;

  void _onEmailChanged(AuthEmailChanged event, Emitter<AuthState> emit) {
    // A code belongs to one email: another email starts over.
    _countdown?.cancel();
    emit(AuthState(email: event.email));
  }

  void _onOtpChanged(AuthOtpChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(otp: event.otp, otpError: null));
  }

  Future<void> _onOtpRequested(
    AuthOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.isBusy || (state.codeSent && !state.canResend)) return;
    emit(state.copyWith(status: AuthStatus.sendingCode, emailError: null));

    final result = await _sendOtp(state.email);
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            status: AuthStatus.idle,
            codeSent: true,
            resendSeconds: resendCooldownSeconds,
            successMessage: 'auth.otp_sent_success',
          ),
        );
        _startCountdown();
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.idle,
            emailError: failure is ValidationFailure
                ? failure.messageKey
                : null,
            errorMessage: switch (failure) {
              ValidationFailure() => null,
              // Login does not create accounts, so an unknown email fails.
              AuthFailure() => 'auth.no_account_error',
              _ => failure.messageKey,
            },
          ),
        );
    }
  }

  Future<void> _onOtpSubmitted(
    AuthOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (state.isBusy || !state.codeSent) return;
    emit(state.copyWith(status: AuthStatus.verifying, otpError: null));

    final result = await _verifyOtp(
      EmailOtp(email: state.email, token: state.otp),
    );
    switch (result) {
      case Success():
        _countdown?.cancel();
        emit(
          state.copyWith(
            status: AuthStatus.signedIn,
            successMessage: 'auth.signed_in',
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.idle,
            otpError: switch (failure) {
              ValidationFailure(:final messageKey) => messageKey,
              AuthFailure() => 'auth.otp_expired_or_invalid',
              _ => null,
            },
            errorMessage: switch (failure) {
              ValidationFailure() || AuthFailure() => null,
              _ => failure.messageKey,
            },
          ),
        );
    }
  }

  void _onCountdownTicked(AuthCountdownTicked event, Emitter<AuthState> emit) {
    final seconds = state.resendSeconds - 1;
    if (seconds <= 0) _countdown?.cancel();
    emit(state.copyWith(resendSeconds: seconds < 0 ? 0 : seconds));
  }

  void _startCountdown() {
    _countdown?.cancel();
    _countdown = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const AuthCountdownTicked()),
    );
  }

  @override
  Future<void> close() {
    _countdown?.cancel();
    return super.close();
  }
}
