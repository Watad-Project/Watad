import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_profile.dart';

class ContractorDashboardProfileModel extends ContractorDashboardProfile {
  const ContractorDashboardProfileModel({
    required super.companyName,
    required super.verificationStatus,
  });

  factory ContractorDashboardProfileModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['verification_status'] as String? ?? 'unverified';
    return ContractorDashboardProfileModel(
      companyName: json['company_name'] as String? ?? '',
      verificationStatus: VerificationStatus.fromJson(statusStr),
    );
  }
}
