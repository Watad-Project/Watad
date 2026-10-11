import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/kyc/contractor/domain/entities/contractor_license_submission.dart';

/// Datasource model for [ContractorLicenseSubmission].
class ContractorLicenseSubmissionModel extends ContractorLicenseSubmission {
  const ContractorLicenseSubmissionModel({
    required super.storagePath,
    required super.status,
  });

  factory ContractorLicenseSubmissionModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'pending';
    final status = switch (statusStr) {
      'verified' => VerificationStatus.verified,
      'rejected' => VerificationStatus.rejected,
      'suspended' => VerificationStatus.suspended,
      'unverified' => VerificationStatus.unverified,
      _ => VerificationStatus.pending,
    };

    return ContractorLicenseSubmissionModel(
      storagePath: json['storage_path'] as String? ?? '',
      status: status,
    );
  }
}
