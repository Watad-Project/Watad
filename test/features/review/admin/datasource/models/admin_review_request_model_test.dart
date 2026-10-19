import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/review/admin/datasource/models/admin_review_request_model.dart';

void main() {
  test('fromJson maps a v_admin_verification_queue row', () {
    final row = {
      'business_id': '7c1d2f0e-0b5a-4f43-9a51-2f3c8e6d1a90',
      'company_name': 'مؤسسة البناء الحديث',
      'owner_name': 'سالم العتيبي',
      'requested_at': '2026-10-18T09:30:00+00:00',
      'document_count': 2,
    };

    final model = AdminReviewRequestModel.fromJson(row);

    expect(model.businessId, '7c1d2f0e-0b5a-4f43-9a51-2f3c8e6d1a90');
    expect(model.companyName, 'مؤسسة البناء الحديث');
    expect(model.ownerName, 'سالم العتيبي');
    expect(model.requestedAt, DateTime.utc(2026, 10, 18, 9, 30));
    expect(model.documentCount, 2);
  });

  test('fromJson accepts a request with no date, owner or documents', () {
    final row = {
      'business_id': 'b-2',
      'company_name': 'Watad Builders',
      'owner_name': null,
      'requested_at': null,
      'document_count': null,
    };

    final model = AdminReviewRequestModel.fromJson(row);

    expect(model.ownerName, isNull);
    expect(model.requestedAt, isNull);
    expect(model.documentCount, 0);
  });
}
