import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_profile.dart';

class ContractorDashboardProfileModel extends ContractorDashboardProfile {
  const ContractorDashboardProfileModel({
    required super.companyName,
    required super.verificationStatus,
  });

  factory ContractorDashboardProfileModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['verification_status'] as String? ?? 'unverified';
    final status = VerificationStatus.values.firstWhere(
      (e) => e.value == statusStr,
      orElse: () => VerificationStatus.unverified,
    );

    final company =
        (json['company_name'] ?? json['business_name'] ?? json['name'])
            as String? ??
        '';

    return ContractorDashboardProfileModel(
      companyName: company,
      verificationStatus: status,
    );
  }
}
