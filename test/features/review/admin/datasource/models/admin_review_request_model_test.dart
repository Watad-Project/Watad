import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/review/admin/datasource/models/admin_review_request_model.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';

void main() {
  test('fromJson maps a v_admin_verification_queue row to a license', () {
    final row = {
      'business_id': '7c1d2f0e-0b5a-4f43-9a51-2f3c8e6d1a90',
      'company_name': 'مؤسسة البناء الحديث',
      'owner_avatar_path': 'u-1/avatar.jpg',
      'requested_at': '2026-10-18T09:30:00+00:00',
      'avatar_url': 'https://example.supabase.co/avatars/u-1/avatar.jpg',
    };

    final model = AdminReviewRequestModel.fromJson(row);

    expect(model.kind, AdminReviewKind.license);
    expect(model.id, '7c1d2f0e-0b5a-4f43-9a51-2f3c8e6d1a90');
    expect(model.requesterName, 'مؤسسة البناء الحديث');
    expect(
      model.requesterAvatarUrl,
      'https://example.supabase.co/avatars/u-1/avatar.jpg',
    );
    expect(model.requestedAt, DateTime.utc(2026, 10, 18, 9, 30));
  });

  test('fromJson maps a v_admin_deed_queue row to a deed', () {
    final row = {
      'project_id': '3b2a1c0d-5e6f-4a7b-8c9d-0e1f2a3b4c5d',
      'owner_name': 'سالم العتيبي',
      'owner_avatar_path': null,
      'requested_at': '2026-10-19T08:00:00+00:00',
      'avatar_url': null,
    };

    final model = AdminReviewRequestModel.fromJson(row);

    expect(model.kind, AdminReviewKind.deed);
    expect(model.id, '3b2a1c0d-5e6f-4a7b-8c9d-0e1f2a3b4c5d');
    expect(model.requesterName, 'سالم العتيبي');
    expect(model.requesterAvatarUrl, isNull);
    expect(model.requestedAt, DateTime.utc(2026, 10, 19, 8));
  });

  test('fromJson accepts a request with no date or photo', () {
    final model = AdminReviewRequestModel.fromJson({
      'business_id': 'b-2',
      'company_name': 'Watad Builders',
      'owner_avatar_path': null,
      'requested_at': null,
    });

    expect(model.requestedAt, isNull);
    expect(model.requesterAvatarUrl, isNull);
  });
}
