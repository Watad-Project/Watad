import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_model.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';

void main() {
  test('fromJson maps a v_my_projects row', () {
    final model = ClientProjectModel.fromJson({
      'id': '3d6f1a2b-8c4e-4f70-9b1a-6e2d5c4b3a21',
      'title': 'فيلا سكنية',
      'status': 'open',
      'city': 'المدينة المنورة',
      'district': 'حي الياسمين',
      'budget': 450000.5,
      'pending_offer_count': 3,
      'created_at': '2026-10-18T08:00:00+00:00',
      'deed_status': 'verified',
      'deed_rejection_reason': null,
    });

    expect(model.id, '3d6f1a2b-8c4e-4f70-9b1a-6e2d5c4b3a21');
    expect(model.title, 'فيلا سكنية');
    expect(model.status, ProjectStatus.open);
    expect(model.city, 'المدينة المنورة');
    expect(model.district, 'حي الياسمين');
    expect(model.budget, const Money.halalas(45000050));
    expect(model.pendingOfferCount, 3);
    expect(model.createdAt, DateTime.utc(2026, 10, 18, 8));
    expect(model.deedStatus, ClientDeedVerificationStatus.verified);
    expect(model.deedRejectionReason, isNull);
  });

  test('a rejected deed keeps the admin\'s reason', () {
    final model = ClientProjectModel.fromJson({
      'id': 'p-3',
      'title': 'new_house',
      'status': 'draft',
      'city': 'جدة',
      'pending_offer_count': 0,
      'created_at': '2026-10-18T08:00:00+00:00',
      'deed_status': 'rejected',
      'deed_rejection_reason': 'الصك غير واضح',
    });

    expect(model.deedStatus, ClientDeedVerificationStatus.rejected);
    expect(model.deedRejectionReason, 'الصك غير واضح');
  });

  test('a project without a deed, or under review', () {
    Map<String, dynamic> row(String? deedStatus) => {
      'id': 'p-4',
      'title': 'repairs',
      'status': 'open',
      'city': 'جدة',
      'pending_offer_count': 0,
      'created_at': '2026-10-18T08:00:00+00:00',
      'deed_status': deedStatus,
    };

    expect(
      ClientProjectModel.fromJson(row(null)).deedStatus,
      ClientDeedVerificationStatus.none,
    );
    expect(
      ClientProjectModel.fromJson(row('under_review')).deedStatus,
      ClientDeedVerificationStatus.underReview,
    );
  });

  test('a draft without a district or a budget', () {
    final model = ClientProjectModel.fromJson({
      'id': 'p-2',
      'title': 'ترميم مطبخ',
      'status': 'draft',
      'city': 'جدة',
      'district': null,
      'budget': null,
      'pending_offer_count': 0,
      'created_at': '2026-10-18T08:00:00+00:00',
    });

    expect(model.status, ProjectStatus.draft);
    expect(model.district, isNull);
    expect(model.budget, isNull);
  });
}
