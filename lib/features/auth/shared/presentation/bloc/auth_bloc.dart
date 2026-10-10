import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Manages the login-with-OTP flow: validation, resend countdown, and Supabase auth.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._sendOtp, this._verifyOtp)
    : super(const AuthState(resendSeconds: _resendCooldownSeconds)) {
    on<AuthEmailChanged>(
      (e, emit) => emit(state.copyWith(email: e.email, emailError: null)),
    );
    on<AuthOtpChanged>(
      (e, emit) => emit(state.copyWith(otp: e.otp, otpError: null)),
    );
    on<AuthOtpSubmitted>(_onOtpSubmitted);
    on<AuthResendRequested>(_onResendRequested);
    on<AuthCountdownTicked>(_onCountdownTicked);
    _startCountdown();
  }

  final SendOtpUseCase _sendOtp;
  final VerifyOtpUseCase _verifyOtp;

  static const int _resendCooldownSeconds = 28;
  Timer? _countdownTimer;

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const AuthCountdownTicked());
    });
  }

  Future<void> _onOtpSubmitted(
    AuthOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.verifyingOtp,
        emailError: null,
        otpError: null,
      ),
    );

    final result = await _verifyOtp(
      VerifyOtpParams(email: state.email, token: state.otp),
    );
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: AuthStatus.verified, session: data));
      case Failed(:final failure):
        final isEmail =
            failure is ValidationFailure &&
            failure.messageKey.contains('email');
        final isOtp =
            failure is ValidationFailure && failure.messageKey.contains('otp');
        emit(
          state.copyWith(
            status: AuthStatus.initial,
            emailError: isEmail ? failure.messageKey : null,
            otpError: isOtp ? failure.messageKey : null,
            message: (!isEmail && !isOtp) ? failure.messageKey : null,
          ),
        );
    }
  }

  Future<void> _onResendRequested(
    AuthResendRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.resendSeconds > 0) return;
    emit(state.copyWith(status: AuthStatus.sendingOtp, emailError: null));

    final result = await _sendOtp(state.email);
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            status: AuthStatus.otpSent,
            message: 'auth.otp_sent_success',
            resendSeconds: _resendCooldownSeconds,
          ),
        );
        _startCountdown();
      case Failed(:final failure):
        final isEmail =
            failure is ValidationFailure &&
            failure.messageKey.contains('email');
        emit(
          state.copyWith(
            status: AuthStatus.initial,
            emailError: isEmail ? failure.messageKey : null,
            message: !isEmail ? failure.messageKey : null,
          ),
        );
    }
  }

  void _onCountdownTicked(AuthCountdownTicked event, Emitter<AuthState> emit) {
    final s = state.resendSeconds - 1;
    emit(state.copyWith(resendSeconds: s < 0 ? 0 : s, message: null));
    if (s <= 0) _countdownTimer?.cancel();
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}
