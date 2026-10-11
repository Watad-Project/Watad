import 'package:watad/core/enums/verification_status.dart';

/// The result of submitting a contractor license document.
class ContractorLicenseSubmission {
  const ContractorLicenseSubmission({
    required this.storagePath,
    required this.status,
  });

  final String storagePath;
  final VerificationStatus status;
}
