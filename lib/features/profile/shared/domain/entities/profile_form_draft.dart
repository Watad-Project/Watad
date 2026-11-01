/// The text fields of the edit profile form as typed (GRA-60), before
/// they're cleaned and checked: spaces and Arabic digits are fine here.
/// The business fields are null for a client.
class ProfileFormDraft {
  const ProfileFormDraft({
    required this.fullName,
    this.companyName,
    this.crNumber,
  });

  final String fullName;
  final String? companyName;
  final String? crNumber;
}
