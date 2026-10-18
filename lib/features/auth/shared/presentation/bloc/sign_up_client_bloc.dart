import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/auth/shared/domain/entities/sign_up_profile.dart';
import 'package:watad/features/auth/shared/domain/entities/verify_otp_params.dart';
import 'package:watad/features/auth/shared/domain/usecases/save_user_profile_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_sign_up_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/sign_out_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_sign_up_otp_use_case.dart';

part 'sign_up_client_event.dart';
part 'sign_up_client_state.dart';

class SignUpClientBloc extends Bloc<SignUpClientEvent, SignUpClientState> {
  SignUpClientBloc({
    required this.sendSignUpOtp,
    required this.verifySignUpOtp,
    required this.saveUserProfile,
    this.signOut,
  }) : super(const SignUpClientState()) {
    on<SignUpClientFullNameChanged>(_onFullNameChanged);
    on<SignUpClientNationalIdChanged>(_onNationalIdChanged);
    on<SignUpClientEmailChanged>(_onEmailChanged);
    on<SignUpClientPhoneChanged>(_onPhoneChanged);
    on<SignUpClientTermsToggled>(_onTermsToggled);
    on<SignUpClientSubmitted>(_onSubmitted);
    on<SignUpClientOtpChanged>(_onOtpChanged);
    on<SignUpClientOtpSubmitted>(_onOtpSubmitted);
    on<SignUpClientOtpResendRequested>(_onOtpResendRequested);
    on<SignUpClientStepBack>(_onStepBack);
    on<SignUpClientResendTick>(_onResendTick);
  }

  final SendSignUpOtpUseCase sendSignUpOtp;
  final VerifySignUpOtpUseCase verifySignUpOtp;
  final SaveUserProfileUseCase saveUserProfile;
  final SignOutUseCase? signOut;

  Timer? _resendTimer;

  static const int resendCooldownSeconds = 30;

  @override
  Future<void> close() {
    _resendTimer?.cancel();
    return super.close();
  }

  void _onFullNameChanged(
    SignUpClientFullNameChanged event,
    Emitter<SignUpClientState> emit,
  ) {
    emit(
      state.copyWith(
        fullName: event.fullName,
        fullNameError: () => null,
        generalError: () => null,
      ),
    );
  }

  void _onNationalIdChanged(
    SignUpClientNationalIdChanged event,
    Emitter<SignUpClientState> emit,
  ) {
    emit(
      state.copyWith(
        nationalId: event.nationalId,
        nationalIdError: () => null,
        generalError: () => null,
      ),
    );
  }

  void _onEmailChanged(
    SignUpClientEmailChanged event,
    Emitter<SignUpClientState> emit,
  ) {
    emit(
      state.copyWith(
        email: event.email,
        emailError: () => null,
        generalError: () => null,
      ),
    );
  }

  void _onPhoneChanged(
    SignUpClientPhoneChanged event,
    Emitter<SignUpClientState> emit,
  ) {
    emit(
      state.copyWith(
        phone: event.phone,
        phoneError: () => null,
        generalError: () => null,
      ),
    );
  }

  void _onTermsToggled(
    SignUpClientTermsToggled event,
    Emitter<SignUpClientState> emit,
  ) {
    emit(
      state.copyWith(
        termsAgreed: event.agreed,
        termsError: () => null,
        generalError: () => null,
      ),
    );
  }

  void _onOtpChanged(
    SignUpClientOtpChanged event,
    Emitter<SignUpClientState> emit,
  ) {
    emit(
      state.copyWith(
        otp: event.otp,
        otpError: () => null,
        generalError: () => null,
      ),
    );
  }

  Future<void> _onSubmitted(
    SignUpClientSubmitted event,
    Emitter<SignUpClientState> emit,
  ) async {
    final name = state.fullName.trim();
    final nationalId = _latinDigits(state.nationalId);
    final email = state.email.trim();
    final phone = _latinDigits(state.phone);

    String? nameError;
    String? idError;
    String? emailError;
    String? phoneError;
    String? termsError;

    if (name.isEmpty) {
      nameError = 'validation.name_required';
    }

    if (nationalId.isEmpty) {
      idError = 'validation.national_id_required';
    } else if (nationalId.length != 10) {
      idError = 'validation.national_id_invalid';
    }

    if (email.isEmpty) {
      emailError = 'validation.email_required';
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email)) {
      emailError = 'validation.email_invalid';
    }

    if (phone.isEmpty) {
      phoneError = 'validation.phone_required';
    } else if (phone.length != 9 || !phone.startsWith('5')) {
      phoneError = 'validation.phone_invalid';
    }

    if (!state.termsAgreed) {
      termsError = 'validation.terms_required';
    }

    if (nameError != null ||
        idError != null ||
        emailError != null ||
        phoneError != null ||
        termsError != null) {
      emit(
        state.copyWith(
          fullNameError: () => nameError,
          nationalIdError: () => idError,
          emailError: () => emailError,
          phoneError: () => phoneError,
          termsError: () => termsError,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SignUpClientStatus.submittingForm,
        generalError: () => null,
        emailError: () => null,
      ),
    );

    final otpResult = await sendSignUpOtp(email);
    switch (otpResult) {
      case Success():
        _startResendTimer();
        emit(
          state.copyWith(
            status: SignUpClientStatus.codeSent,
            step: SignUpClientStep.otp,
            resendSeconds: resendCooldownSeconds,
            generalError: () => null,
            otpError: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: SignUpClientStatus.failure,
            generalError: () => failure.messageKey,
          ),
        );
    }
  }

  Future<void> _onOtpSubmitted(
    SignUpClientOtpSubmitted event,
    Emitter<SignUpClientState> emit,
  ) async {
    final otp = _latinDigits(state.otp);
    if (otp.length != 6) {
      emit(state.copyWith(otpError: () => 'validation.otp_invalid'));
      return;
    }

    emit(
      state.copyWith(
        status: SignUpClientStatus.verifyingCode,
        otpError: () => null,
        generalError: () => null,
      ),
    );

    final verifyResult = await verifySignUpOtp(
      VerifyOtpParams(email: state.email.trim(), token: otp),
    );

    switch (verifyResult) {
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: SignUpClientStatus.failure,
            otpError: () => failure.messageKey,
          ),
        );
        return;
      case Success():
        break;
    }

    final phoneDigits = _latinDigits(state.phone);
    final profile = SignUpProfile(
      fullName: state.fullName.trim(),
      nationalId: _latinDigits(state.nationalId),
      phone: '+966$phoneDigits',
      role: 'client',
    );

    final saveResult = await saveUserProfile(profile);
    switch (saveResult) {
      case Success(:final data):
        if (data == 'already_registered') {
          if (signOut != null) {
            await signOut!(const NoParams());
          }
          emit(
            state.copyWith(
              status: SignUpClientStatus.failure,
              generalError: () => 'validation.email_already_registered',
              otpError: () => 'validation.email_already_registered',
              emailError: () => 'validation.email_already_registered',
            ),
          );
          return;
        }
        if (data == 'created') {
          _resendTimer?.cancel();
          emit(
            state.copyWith(
              status: SignUpClientStatus.success,
              successMessage: () => 'auth.signup_success',
              generalError: () => null,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            status: SignUpClientStatus.failure,
            generalError: () => 'errors.unknown',
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: SignUpClientStatus.failure,
            generalError: () => failure.messageKey,
          ),
        );
    }
  }

  Future<void> _onOtpResendRequested(
    SignUpClientOtpResendRequested event,
    Emitter<SignUpClientState> emit,
  ) async {
    if (!state.canResend) return;

    emit(
      state.copyWith(
        status: SignUpClientStatus.submittingForm,
        generalError: () => null,
        otpError: () => null,
      ),
    );

    final otpResult = await sendSignUpOtp(state.email.trim());
    switch (otpResult) {
      case Success():
        _startResendTimer();
        emit(
          state.copyWith(
            status: SignUpClientStatus.codeSent,
            resendSeconds: resendCooldownSeconds,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: SignUpClientStatus.failure,
            generalError: () => failure.messageKey,
          ),
        );
    }
  }

  void _onStepBack(
    SignUpClientStepBack event,
    Emitter<SignUpClientState> emit,
  ) {
    if (state.step == SignUpClientStep.otp) {
      _resendTimer?.cancel();
      emit(
        state.copyWith(
          step: SignUpClientStep.form,
          status: SignUpClientStatus.initial,
          otp: '',
          otpError: () => null,
          generalError: () => null,
          resendSeconds: 0,
        ),
      );
    }
  }

  void _onResendTick(
    SignUpClientResendTick event,
    Emitter<SignUpClientState> emit,
  ) {
    emit(state.copyWith(resendSeconds: event.seconds));
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    var remaining = resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining <= 0) {
        timer.cancel();
        add(const SignUpClientResendTick(0));
      } else {
        add(SignUpClientResendTick(remaining));
      }
    });
  }

  static String _latinDigits(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        buffer.writeCharCode(rune);
      } else if (rune >= 0x660 && rune <= 0x669) {
        buffer.writeCharCode(rune - 0x660 + 0x30);
      } else if (rune >= 0x6F0 && rune <= 0x6F9) {
        buffer.writeCharCode(rune - 0x6F0 + 0x30);
      }
    }
    return buffer.toString();
  }
}
