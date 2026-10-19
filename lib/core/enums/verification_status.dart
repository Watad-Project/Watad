/// Mirror of the Postgres enum `verification_status` (ARCHITECTURE.md §4).
enum VerificationStatus {
  unverified('unverified'),
  pending('pending'),
  verified('verified'),
  rejected('rejected'),
  suspended('suspended');

  const VerificationStatus(this.value);

  final String value;

  static VerificationStatus fromJson(String value) {
    return VerificationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VerificationStatus.unverified,
    );
  }

  String toJson() => value;
}
