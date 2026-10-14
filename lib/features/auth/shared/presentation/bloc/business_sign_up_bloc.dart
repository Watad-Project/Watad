import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';
import 'package:watad/features/auth/shared/domain/entities/email_otp.dart';
import 'package:watad/features/auth/shared/domain/usecases/save_business_sign_up_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_sign_up_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';

part 'business_sign_up_event.dart';
part 'business_sign_up_state.dart';

class BusinessSignUpBloc
    extends Bloc<BusinessSignUpEvent, BusinessSignUpState> {
  BusinessSignUpBloc(
    this._sendSignUpOtp,
    this._verifyOtp,
    this._saveBusinessSignUp,
  ) : super(const BusinessSignUpState()) {
    on<BusinessSignUpCompanyNameChanged>(_onCompanyNameChanged);
    on<BusinessSignUpCrNumberChanged>(_onCrNumberChanged);
    on<BusinessSignUpEmailChanged>(_onEmailChanged);
    on<BusinessSignUpPhoneChanged>(_onPhoneChanged);
    on<BusinessSignUpTermsToggled>(_onTermsToggled);
    on<BusinessSignUpSubmitted>(_onSubmitted);
    on<BusinessSignUpOtpChanged>(_onOtpChanged);
    on<BusinessSignUpOtpSubmitted>(_onOtpSubmitted);
    on<BusinessSignUpOtpResendRequested>(_onOtpResendRequested);
    on<BusinessSignUpResendTick>(_onResendTick);
    on<BusinessSignUpStepBack>(_onStepBack);
  }

  final SendSignUpOtpUseCase _sendSignUpOtp;
  final VerifyOtpUseCase _verifyOtp;
  final SaveBusinessSignUpUseCase _saveBusinessSignUp;

  static const int resendCooldownSeconds = 60;
  Timer? _resendTimer;

  static final RegExp _crRegExp = RegExp(r'^\d{10}$');
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );
  static final RegExp _phoneRegExp = RegExp(r'^5\d{8}$');

  void _onCompanyNameChanged(
    BusinessSignUpCompanyNameChanged event,
    Emitter<BusinessSignUpState> emit,
  ) {
    emit(
      state.copyWith(
        companyName: event.companyName,
        companyNameError: () => null,
        generalError: () => null,
      ),
    );
  }

  void _onCrNumberChanged(
    BusinessSignUpCrNumberChanged event,
    Emitter<BusinessSignUpState> emit,
  ) {
    emit(
      state.copyWith(
        crNumber: event.crNumber,
        crNumberError: () => null,
        generalError: () => null,
      ),
    );
  }

  void _onEmailChanged(
    BusinessSignUpEmailChanged event,
    Emitter<BusinessSignUpState> emit,
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
    BusinessSignUpPhoneChanged event,
    Emitter<BusinessSignUpState> emit,
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
    BusinessSignUpTermsToggled event,
    Emitter<BusinessSignUpState> emit,
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
    BusinessSignUpOtpChanged event,
    Emitter<BusinessSignUpState> emit,
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
    BusinessSignUpSubmitted event,
    Emitter<BusinessSignUpState> emit,
  ) async {
    if (state.isSubmitting) return;
    final companyName = state.companyName.trim();
    final crNumber = _latinDigits(state.crNumber);
    final email = state.email.trim();
    final rawPhone = _latinDigits(state.phone)
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('+966', '');
    final termsAgreed = state.termsAgreed;

    String? companyNameError;
    if (companyName.isEmpty) {
      companyNameError = 'validation.company_name_required';
    }

    String? crNumberError;
    if (crNumber.isEmpty) {
      crNumberError = 'validation.cr_number_required';
    } else if (!_crRegExp.hasMatch(crNumber)) {
      crNumberError = 'validation.cr_number_invalid';
    }

    String? emailError;
    if (email.isEmpty) {
      emailError = 'validation.email_required';
    } else if (!_emailRegExp.hasMatch(email)) {
      emailError = 'validation.email_invalid';
    }

    String? phoneError;
    if (rawPhone.isEmpty) {
      phoneError = 'validation.phone_required';
    } else if (!_phoneRegExp.hasMatch(rawPhone)) {
      phoneError = 'validation.phone_invalid';
    }

    String? termsError;
    if (!termsAgreed) {
      termsError = 'validation.terms_required';
    }

    if (companyNameError != null ||
        crNumberError != null ||
        emailError != null ||
        phoneError != null ||
        termsError != null) {
      emit(
        state.copyWith(
          companyNameError: () => companyNameError,
          crNumberError: () => crNumberError,
          emailError: () => emailError,
          phoneError: () => phoneError,
          termsError: () => termsError,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: BusinessSignUpStatus.inProgress,
        generalError: () => null,
        emailError: () => null,
      ),
    );

    final otpResult = await _sendSignUpOtp(email);
    switch (otpResult) {
      case Success():
        _startResendTimer();
        emit(
          state.copyWith(
            status: BusinessSignUpStatus.initial,
            step: BusinessSignUpStep.otp,
            resendSeconds: resendCooldownSeconds,
            generalError: () => null,
            otpError: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: BusinessSignUpStatus.failure,
            generalError: () => failure.messageKey,
          ),
        );
    }
  }

  Future<void> _onOtpSubmitted(
    BusinessSignUpOtpSubmitted event,
    Emitter<BusinessSignUpState> emit,
  ) async {
    if (state.isSubmitting) return;
    final otp = _latinDigits(state.otp);
    if (otp.length != VerifyOtpUseCase.codeLength) {
      emit(state.copyWith(otpError: () => 'auth.invalid_otp_error'));
      return;
    }

    emit(
      state.copyWith(
        status: BusinessSignUpStatus.inProgress,
        otpError: () => null,
        generalError: () => null,
      ),
    );

    final verifyResult = await _verifyOtp(
      EmailOtp(email: state.email.trim(), token: otp),
    );

    switch (verifyResult) {
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: BusinessSignUpStatus.failure,
            otpError: () => failure.messageKey,
          ),
        );
        return;
      case Success():
        break;
    }

    final rawPhone = _latinDigits(state.phone)
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('+966', '');

    final data = BusinessSignUp(
      companyName: state.companyName.trim(),
      crNumber: _latinDigits(state.crNumber),
      email: state.email.trim(),
      phone: '+966$rawPhone',
      specializedField: 'contractor',
      role: 'contractor',
    );

    final saveResult = await _saveBusinessSignUp(data);
    switch (saveResult) {
      case Success():
        _resendTimer?.cancel();
        emit(state.copyWith(status: BusinessSignUpStatus.success));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: BusinessSignUpStatus.failure,
            generalError: () => failure.messageKey,
          ),
        );
    }
  }

  Future<void> _onOtpResendRequested(
    BusinessSignUpOtpResendRequested event,
    Emitter<BusinessSignUpState> emit,
  ) async {
    if (!state.canResend) return;

    emit(
      state.copyWith(
        status: BusinessSignUpStatus.inProgress,
        generalError: () => null,
        otpError: () => null,
      ),
    );

    final otpResult = await _sendSignUpOtp(state.email.trim());
    switch (otpResult) {
      case Success():
        _startResendTimer();
        emit(
          state.copyWith(
            status: BusinessSignUpStatus.initial,
            resendSeconds: resendCooldownSeconds,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: BusinessSignUpStatus.failure,
            generalError: () => failure.messageKey,
          ),
        );
    }
  }

  void _onStepBack(
    BusinessSignUpStepBack event,
    Emitter<BusinessSignUpState> emit,
  ) {
    if (state.step == BusinessSignUpStep.otp) {
      _resendTimer?.cancel();
      emit(
        state.copyWith(
          step: BusinessSignUpStep.form,
          status: BusinessSignUpStatus.initial,
          otp: '',
          otpError: () => null,
          generalError: () => null,
          resendSeconds: 0,
        ),
      );
    }
  }

  void _onResendTick(
    BusinessSignUpResendTick event,
    Emitter<BusinessSignUpState> emit,
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
        add(const BusinessSignUpResendTick(0));
      } else {
        add(BusinessSignUpResendTick(remaining));
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

  @override
  Future<void> close() {
    _resendTimer?.cancel();
    return super.close();
  }
}
