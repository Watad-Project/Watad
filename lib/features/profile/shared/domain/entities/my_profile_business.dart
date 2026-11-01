import 'package:watad/core/enums/verification_status.dart';

/// The signed-in contractor's business, from their `v_my_profile` row.
class MyProfileBusiness {
  const MyProfileBusiness({
    required this.companyName,
    required this.crNumber,
    required this.specializedField,
    required this.verificationStatus,
    this.city,
  });

  final String companyName;

  /// The commercial registration number: 10 digits. It can't change once
  /// the business is verified (migration 86).
  final String crNumber;

  /// The specialty as it was saved: one of GRA-16's labels in the language
  /// the app had then, or older text (see `ProfileSpecialty`).
  final String specializedField;
  final VerificationStatus verificationStatus;

  /// Where the business works; null until the contractor sets it.
  final String? city;
}
