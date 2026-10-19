part of 'business_sign_up_bloc.dart';

enum BusinessSignUpStatus { initial, inProgress, success, failure }

enum BusinessSignUpStep { form, otp }

final class BusinessSignUpState {
  const BusinessSignUpState({
    this.step = BusinessSignUpStep.form,
    this.companyName = '',
    this.companyNameError,
    this.crNumber = '',
    this.crNumberError,
    this.email = '',
    this.emailError,
    this.phone = '',
    this.phoneError,
    this.termsAgreed = false,
    this.termsError,
    this.otp = '',
    this.otpError,
    this.resendSeconds = 0,
    this.status = BusinessSignUpStatus.initial,
    this.generalError,
  });

  final BusinessSignUpStep step;
  final String companyName;
  final String? companyNameError;
  final String crNumber;
  final String? crNumberError;
  final String email;
  final String? emailError;
  final String phone;
  final String? phoneError;
  final bool termsAgreed;
  final String? termsError;
  final String otp;
  final String? otpError;
  final int resendSeconds;
  final BusinessSignUpStatus status;
  final String? generalError;

  bool get isSubmitting => status == BusinessSignUpStatus.inProgress;
  bool get isOtpStep => step == BusinessSignUpStep.otp;
  bool get canResend => resendSeconds <= 0;

  BusinessSignUpState copyWith({
    BusinessSignUpStep? step,
    String? companyName,
    String? Function()? companyNameError,
    String? crNumber,
    String? Function()? crNumberError,
    String? email,
    String? Function()? emailError,
    String? phone,
    String? Function()? phoneError,
    bool? termsAgreed,
    String? Function()? termsError,
    String? otp,
    String? Function()? otpError,
    int? resendSeconds,
    BusinessSignUpStatus? status,
    String? Function()? generalError,
  }) {
    return BusinessSignUpState(
      step: step ?? this.step,
      companyName: companyName ?? this.companyName,
      companyNameError: companyNameError != null
          ? companyNameError()
          : this.companyNameError,
      crNumber: crNumber ?? this.crNumber,
      crNumberError: crNumberError != null
          ? crNumberError()
          : this.crNumberError,
      email: email ?? this.email,
      emailError: emailError != null ? emailError() : this.emailError,
      phone: phone ?? this.phone,
      phoneError: phoneError != null ? phoneError() : this.phoneError,
      termsAgreed: termsAgreed ?? this.termsAgreed,
      termsError: termsError != null ? termsError() : this.termsError,
      otp: otp ?? this.otp,
      otpError: otpError != null ? otpError() : this.otpError,
      resendSeconds: resendSeconds ?? this.resendSeconds,
      status: status ?? this.status,
      generalError: generalError != null ? generalError() : this.generalError,
    );
  }
}
