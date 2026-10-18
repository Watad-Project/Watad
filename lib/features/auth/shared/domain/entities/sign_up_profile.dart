/// The client profile data collected during sign-up to be saved upon
/// successful verification.
class SignUpProfile {
  const SignUpProfile({
    required this.fullName,
    required this.nationalId,
    required this.phone,
    this.role = 'client',
  });

  final String fullName;
  final String nationalId;
  final String phone;
  final String role;
}
