part of 'sign_up_client_bloc.dart';

sealed class SignUpClientEvent {
  const SignUpClientEvent();
}

final class SignUpClientFullNameChanged extends SignUpClientEvent {
  const SignUpClientFullNameChanged(this.fullName);
  final String fullName;
}

final class SignUpClientNationalIdChanged extends SignUpClientEvent {
  const SignUpClientNationalIdChanged(this.nationalId);
  final String nationalId;
}

final class SignUpClientEmailChanged extends SignUpClientEvent {
  const SignUpClientEmailChanged(this.email);
  final String email;
}

final class SignUpClientPhoneChanged extends SignUpClientEvent {
  const SignUpClientPhoneChanged(this.phone);
  final String phone;
}

final class SignUpClientTermsToggled extends SignUpClientEvent {
  const SignUpClientTermsToggled(this.agreed);
  final bool agreed;
}

final class SignUpClientSubmitted extends SignUpClientEvent {
  const SignUpClientSubmitted();
}

final class SignUpClientOtpChanged extends SignUpClientEvent {
  const SignUpClientOtpChanged(this.otp);
  final String otp;
}

final class SignUpClientOtpSubmitted extends SignUpClientEvent {
  const SignUpClientOtpSubmitted();
}

final class SignUpClientOtpResendRequested extends SignUpClientEvent {
  const SignUpClientOtpResendRequested();
}

final class SignUpClientStepBack extends SignUpClientEvent {
  const SignUpClientStepBack();
}

final class SignUpClientResendTick extends SignUpClientEvent {
  const SignUpClientResendTick(this.seconds);
  final int seconds;
}
