part of 'business_sign_up_bloc.dart';

sealed class BusinessSignUpEvent {
  const BusinessSignUpEvent();
}

final class BusinessSignUpCompanyNameChanged extends BusinessSignUpEvent {
  const BusinessSignUpCompanyNameChanged(this.companyName);

  final String companyName;
}

final class BusinessSignUpCrNumberChanged extends BusinessSignUpEvent {
  const BusinessSignUpCrNumberChanged(this.crNumber);

  final String crNumber;
}

final class BusinessSignUpEmailChanged extends BusinessSignUpEvent {
  const BusinessSignUpEmailChanged(this.email);

  final String email;
}

final class BusinessSignUpPhoneChanged extends BusinessSignUpEvent {
  const BusinessSignUpPhoneChanged(this.phone);

  final String phone;
}

final class BusinessSignUpTermsToggled extends BusinessSignUpEvent {
  const BusinessSignUpTermsToggled(this.agreed);

  final bool agreed;
}

final class BusinessSignUpSubmitted extends BusinessSignUpEvent {
  const BusinessSignUpSubmitted();
}
