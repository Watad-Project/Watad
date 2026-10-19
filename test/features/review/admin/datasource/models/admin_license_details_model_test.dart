import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/features/review/admin/datasource/models/admin_license_details_model.dart';
import 'package:watad/features/review/admin/datasource/models/admin_review_document_model.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';

void main() {
  final document = AdminReviewDocumentModel(
    id: 'doc-1',
    documentType: BusinessDocumentType.commercialRegistration,
    storagePath: 'u-1/cr.pdf',
    createdAt: DateTime.utc(2026, 10, 18),
    url: 'https://example.supabase.co/sign/cr.pdf',
  );

  test('fromJson maps a v_admin_verification_queue row with its files', () {
    final row = {
      'business_id': 'b-1',
      'company_name': 'مؤسسة البناء الحديث',
      'cr_number': '1010123456',
      'specialized_field': 'مقاولات عامة',
      'city': 'المدينة المنورة',
      'owner_name': 'سالم العتيبي',
      'owner_avatar_path': 'u-1/avatar.jpg',
      'member_since': '2026-10-01T12:00:00+00:00',
      'requested_at': '2026-10-18T09:30:00+00:00',
      'owner_national_id': '1012345678',
      'owner_avatar_url': 'https://example.supabase.co/avatars/u-1/avatar.jpg',
      'documents': [document],
    };

    final model = AdminLicenseDetailsModel.fromJson(row);

    expect(model.target.kind, AdminReviewKind.license);
    expect(model.target.id, 'b-1');
    expect(model.companyName, 'مؤسسة البناء الحديث');
    expect(model.crNumber, '1010123456');
    expect(model.specializedField, 'مقاولات عامة');
    expect(model.city, 'المدينة المنورة');
    expect(model.requester.name, 'سالم العتيبي');
    expect(
      model.requester.avatarUrl,
      'https://example.supabase.co/avatars/u-1/avatar.jpg',
    );
    expect(model.requester.memberSince, DateTime.utc(2026, 10, 1, 12));
    expect(model.requester.nationalId, '1012345678');
    expect(model.requestedAt, DateTime.utc(2026, 10, 18, 9, 30));
    expect(model.documents, [document]);
  });

  test('fromJson accepts a business with no specialty, city or photo', () {
    final model = AdminLicenseDetailsModel.fromJson({
      'business_id': 'b-2',
      'company_name': 'Watad Builders',
      'cr_number': '1010654321',
      'specialized_field': null,
      'city': null,
      'owner_name': null,
      'owner_avatar_path': null,
      'member_since': null,
      'requested_at': null,
      // Contractors don't give an ID number at sign-up.
      'owner_national_id': null,
      'owner_avatar_url': null,
      'documents': <AdminReviewDocumentModel>[],
    });

    expect(model.specializedField, isNull);
    expect(model.city, isNull);
    expect(model.requester.name, '');
    expect(model.requester.memberSince, isNull);
    expect(model.requester.nationalId, isNull);
    expect(model.documents, isEmpty);
  });
}
