import 'package:watad/core/enums/verification_status.dart';

/// Business profile data for the contractor dashboard.
class ContractorDashboardProfile {
  const ContractorDashboardProfile({
    required this.companyName,
    required this.verificationStatus,
  });

  final String companyName;
  final VerificationStatus verificationStatus;
}
