import 'package:watad/features/kyc/contractor/domain/entities/contractor_license_submission.dart';

/// Datasource model for [ContractorLicenseSubmission].
class ContractorLicenseSubmissionModel extends ContractorLicenseSubmission {
  const ContractorLicenseSubmissionModel({required super.storagePath});

  factory ContractorLicenseSubmissionModel.fromJson(Map<String, dynamic> json) {
    return ContractorLicenseSubmissionModel(
      storagePath: json['storage_path'] as String? ?? '',
    );
  }
}
