part of 'sign_up_client_bloc.dart';

enum SignUpClientStatus {
  initial,
  submittingForm,
  codeSent,
  verifyingCode,
  success,
  failure,
}

enum SignUpClientStep { form, otp }

final class SignUpClientState {
  const SignUpClientState({
    this.fullName = '',
    this.fullNameError,
    this.nationalId = '',
    this.nationalIdError,
    this.email = '',
    this.emailError,
    this.phone = '',
    this.phoneError,
    this.termsAgreed = false,
    this.termsError,
    this.otp = '',
    this.otpError,
    this.step = SignUpClientStep.form,
    this.status = SignUpClientStatus.initial,
    this.resendSeconds = 0,
    this.generalError,
    this.successMessage,
  });

  final String fullName;
  final String? fullNameError;
  final String nationalId;
  final String? nationalIdError;
  final String email;
  final String? emailError;
  final String phone;
  final String? phoneError;
  final bool termsAgreed;
  final String? termsError;
  final String otp;
  final String? otpError;
  final SignUpClientStep step;
  final SignUpClientStatus status;
  final int resendSeconds;
  final String? generalError;
  final String? successMessage;

  bool get isSubmitting =>
      status == SignUpClientStatus.submittingForm ||
      status == SignUpClientStatus.verifyingCode;

  bool get canResend => step == SignUpClientStep.otp && resendSeconds == 0;

  SignUpClientState copyWith({
    String? fullName,
    String? Function()? fullNameError,
    String? nationalId,
    String? Function()? nationalIdError,
    String? email,
    String? Function()? emailError,
    String? phone,
    String? Function()? phoneError,
    bool? termsAgreed,
    String? Function()? termsError,
    String? otp,
    String? Function()? otpError,
    SignUpClientStep? step,
    SignUpClientStatus? status,
    int? resendSeconds,
    String? Function()? generalError,
    String? Function()? successMessage,
  }) {
    return SignUpClientState(
      fullName: fullName ?? this.fullName,
      fullNameError: fullNameError != null
          ? fullNameError()
          : this.fullNameError,
      nationalId: nationalId ?? this.nationalId,
      nationalIdError: nationalIdError != null
          ? nationalIdError()
          : this.nationalIdError,
      email: email ?? this.email,
      emailError: emailError != null ? emailError() : this.emailError,
      phone: phone ?? this.phone,
      phoneError: phoneError != null ? phoneError() : this.phoneError,
      termsAgreed: termsAgreed ?? this.termsAgreed,
      termsError: termsError != null ? termsError() : this.termsError,
      otp: otp ?? this.otp,
      otpError: otpError != null ? otpError() : this.otpError,
      step: step ?? this.step,
      status: status ?? this.status,
      resendSeconds: resendSeconds ?? this.resendSeconds,
      generalError: generalError != null ? generalError() : this.generalError,
      successMessage: successMessage != null
          ? successMessage()
          : this.successMessage,
    );
  }
}
