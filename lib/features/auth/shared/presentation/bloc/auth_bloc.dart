import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Manages the login-with-OTP flow: email validation, OTP validation,
/// resend countdown, and Supabase authentication.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._sendOtp, this._verifyOtp)
    : super(const AuthState(resendSeconds: _resendCooldownSeconds)) {
    on<AuthEmailChanged>(_onEmailChanged);
    on<AuthOtpChanged>(_onOtpChanged);
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

  void _onEmailChanged(AuthEmailChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(email: event.email, emailError: null));
  }

  void _onOtpChanged(AuthOtpChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(otp: event.otp, otpError: null));
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
        if (failure is ValidationFailure) {
          if (failure.messageKey == 'auth.email_required_error' ||
              failure.messageKey == 'auth.invalid_email_error') {
            emit(
              state.copyWith(
                status: AuthStatus.initial,
                emailError: failure.messageKey,
              ),
            );
          } else {
            emit(
              state.copyWith(
                status: AuthStatus.initial,
                otpError: failure.messageKey,
              ),
            );
          }
        } else {
          emit(
            state.copyWith(
              status: AuthStatus.initial,
              message: failure.messageKey,
            ),
          );
        }
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
        if (failure is ValidationFailure) {
          emit(
            state.copyWith(
              status: AuthStatus.initial,
              emailError: failure.messageKey,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: AuthStatus.initial,
              message: failure.messageKey,
            ),
          );
        }
    }
  }

  void _onCountdownTicked(AuthCountdownTicked event, Emitter<AuthState> emit) {
    final newSeconds = state.resendSeconds - 1;
    emit(
      state.copyWith(
        resendSeconds: newSeconds < 0 ? 0 : newSeconds,
        message: null,
      ),
    );
    if (newSeconds <= 0) {
      _countdownTimer?.cancel();
    }
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}
