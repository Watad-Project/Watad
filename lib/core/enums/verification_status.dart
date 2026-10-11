/// Mirror of the Postgres enum `verification_status` (ARCHITECTURE.md §4).
enum VerificationStatus {
  unverified('unverified'),
  pending('pending'),
  verified('verified'),
  rejected('rejected'),
  suspended('suspended');

  const VerificationStatus(this.value);

  final String value;
}
