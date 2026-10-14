/// Parameters needed to verify an email OTP code.
class VerifyOtpParams {
  const VerifyOtpParams({required this.email, required this.token});

  final String email;
  final String token;
}
