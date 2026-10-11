import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/kyc/contractor/datasource/models/contractor_license_submission_model.dart';

void main() {
  test('fromJson maps a realistic Supabase row to ContractorLicenseSubmissionModel', () {
    final row = {
      'storage_path': 'user-123/1700000000_contractor_license.pdf',
      'status': 'pending',
    };

    final model = ContractorLicenseSubmissionModel.fromJson(row);

    expect(model.storagePath, 'user-123/1700000000_contractor_license.pdf');
    expect(model.status, VerificationStatus.pending);
  });

  test('fromJson maps verified and unknown status strings accurately', () {
    final verifiedRow = {
      'storage_path': 'path/to/file.jpg',
      'status': 'verified',
    };
    final model = ContractorLicenseSubmissionModel.fromJson(verifiedRow);
    expect(model.status, VerificationStatus.verified);

    final fallbackRow = {
      'storage_path': 'path/to/file.jpg',
      'status': 'unexpected_value',
    };
    final fallbackModel = ContractorLicenseSubmissionModel.fromJson(
      fallbackRow,
    );
    expect(fallbackModel.status, VerificationStatus.pending);
  });
}
