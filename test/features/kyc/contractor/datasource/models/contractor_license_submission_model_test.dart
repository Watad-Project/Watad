import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/kyc/contractor/datasource/models/contractor_license_submission_model.dart';

void main() {
  test('fromJson maps a realistic business_documents row to ContractorLicenseSubmissionModel', () {
    final row = {
      'storage_path': 'user-123/1700000000_contractor_license.pdf',
      'document_type': 'commercial_registration',
    };

    final model = ContractorLicenseSubmissionModel.fromJson(row);

    expect(model.storagePath, 'user-123/1700000000_contractor_license.pdf');
  });

  test('fromJson handles missing or fallback storage_path gracefully', () {
    final row = <String, dynamic>{};
    final model = ContractorLicenseSubmissionModel.fromJson(row);

    expect(model.storagePath, '');
  });
}
