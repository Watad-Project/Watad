import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/review/admin/datasource/models/admin_deed_details_model.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';

void main() {
  test('fromJson maps a v_admin_deed_queue row', () {
    final row = {
      'project_id': 'p-1',
      'title': 'بناء فيلا',
      'description': 'فيلا من دورين',
      'budget': 450000,
      'city': 'المدينة المنورة',
      'district': 'العزيزية',
      'photo_paths': ['u-1/projects/site.jpg'],
      'deed_storage_path': 'u-1/deed.pdf',
      'requested_at': '2026-10-19T08:00:00+00:00',
      'owner_name': 'سالم العتيبي',
      'owner_avatar_path': null,
      'member_since': '2026-09-30T10:00:00+00:00',
      'owner_national_id': '2098765432',
      'deed_url': 'https://example.supabase.co/sign/deed.pdf',
      'photo_urls': ['https://example.supabase.co/images/site.jpg'],
      'owner_avatar_url': null,
    };

    final model = AdminDeedDetailsModel.fromJson(row);

    expect(model.target.kind, AdminReviewKind.deed);
    expect(model.target.id, 'p-1');
    expect(model.title, 'بناء فيلا');
    expect(model.description, 'فيلا من دورين');
    expect(model.budget, Money.fromSar(450000));
    expect(model.city, 'المدينة المنورة');
    expect(model.district, 'العزيزية');
    expect(model.photoUrls, ['https://example.supabase.co/images/site.jpg']);
    expect(model.deedUrl, 'https://example.supabase.co/sign/deed.pdf');
    expect(model.isDeedPdf, isTrue);
    expect(model.hasFiles, isTrue);
    expect(model.requester.name, 'سالم العتيبي');
    expect(model.requester.avatarUrl, isNull);
    expect(model.requester.memberSince, DateTime.utc(2026, 9, 30, 10));
    expect(model.requester.nationalId, '2098765432');
    expect(model.requestedAt, DateTime.utc(2026, 10, 19, 8));
  });

  test('fromJson accepts a project with no budget, place or photos', () {
    final model = AdminDeedDetailsModel.fromJson({
      'project_id': 'p-2',
      'title': null,
      'description': null,
      'budget': null,
      'city': null,
      'district': null,
      'photo_paths': null,
      'deed_storage_path': 'u-2/deed.jpg',
      'requested_at': null,
      'owner_name': 'Sara',
      'owner_avatar_path': null,
      'member_since': null,
      // The file isn't in storage: no link.
      'deed_url': null,
      'photo_urls': <String>[],
      'owner_avatar_url': null,
    });

    expect(model.title, '');
    expect(model.budget, isNull);
    expect(model.photoUrls, isEmpty);
    expect(model.isDeedPdf, isFalse);
    expect(model.deedUrl, isNull);
    expect(model.hasFiles, isFalse);
    expect(model.requestedAt, isNull);
  });
}
