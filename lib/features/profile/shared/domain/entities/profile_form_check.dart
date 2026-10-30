/// The text fields of the edit profile form checked by the rules the
/// database applies (GRA-60): the values as they would be saved, and
/// what's wrong with each field as a translation key, null when it's fine.
class ProfileFormCheck {
  const ProfileFormCheck({
    required this.fullName,
    this.companyName,
    this.crNumber,
    this.fullNameError,
    this.companyNameError,
    this.crNumberError,
  });

  /// Trimmed.
  final String fullName;

  /// Trimmed; null for a client.
  final String? companyName;

  /// Latin digits only; null for a client.
  final String? crNumber;

  final String? fullNameError;
  final String? companyNameError;
  final String? crNumberError;

  /// The first problem, in the order of the form; null when there is none.
  String? get firstError => fullNameError ?? companyNameError ?? crNumberError;

  bool get isValid => firstError == null;
}
