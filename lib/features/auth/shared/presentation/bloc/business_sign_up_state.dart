part of 'business_sign_up_bloc.dart';

enum BusinessSignUpStatus { initial, inProgress, success, failure }

final class BusinessSignUpState {
  const BusinessSignUpState({
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
    this.status = BusinessSignUpStatus.initial,
    this.generalError,
  });

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
  final BusinessSignUpStatus status;
  final String? generalError;

  bool get isSubmitting => status == BusinessSignUpStatus.inProgress;

  BusinessSignUpState copyWith({
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
    BusinessSignUpStatus? status,
    String? Function()? generalError,
  }) {
    return BusinessSignUpState(
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
      status: status ?? this.status,
      generalError: generalError != null ? generalError() : this.generalError,
    );
  }
}
