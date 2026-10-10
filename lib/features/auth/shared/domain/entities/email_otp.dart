/// A sign-in code and the email it was sent to: the input of
/// `VerifyOtpUseCase`.
class EmailOtp {
  const EmailOtp({required this.email, required this.token});

  final String email;

  /// The code from the email, e.g. `'482910'`.
  final String token;
}
