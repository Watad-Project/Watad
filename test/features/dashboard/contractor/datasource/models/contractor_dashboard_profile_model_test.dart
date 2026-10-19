import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_profile_model.dart';

void main() {
  test('fromJson maps v_my_profile row correctly', () {
    final json = {
      'company_name': 'مؤسسة البناء المتين',
      'verification_status': 'verified',
    };

    final model = ContractorDashboardProfileModel.fromJson(json);

    expect(model.companyName, 'مؤسسة البناء المتين');
    expect(model.verificationStatus, VerificationStatus.verified);
  });

  test('fromJson handles null or missing fields gracefully', () {
    final model = ContractorDashboardProfileModel.fromJson({});

    expect(model.companyName, isEmpty);
    expect(model.verificationStatus, VerificationStatus.unverified);
  });
}
