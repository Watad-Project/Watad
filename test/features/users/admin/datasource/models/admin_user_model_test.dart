import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/user_role.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/users/admin/datasource/models/admin_user_model.dart';

void main() {
  test('fromJson maps a suspended business from v_admin_users', () {
    final model = AdminUserModel.fromJson(const {
      'id': '5f0c7a52-3d1e-4c8b-9b7a-1e2d3c4b5a69',
      'full_name': 'خالد الحربي',
      'avatar_path': 'u-1/avatar.jpg',
      'avatar_url': 'https://example.supabase.co/storage/v1/object/public/avatars/u-1/avatar.jpg',
      'role': 'user',
      'member_since': '2026-08-20T09:00:00+00:00',
      'is_deleted': false,
      'is_me': false,
      'last_seen_at': '2026-10-21T18:05:23+00:00',
      'is_online': false,
      'is_business': true,
      'company_name': 'مقاولات الخبر',
      'specialized_field': 'ترميم',
      'business_city': 'الخبر',
      'verification_status': 'verified',
      'is_suspended': true,
      'suspension_reason': 'إعلانات مضللة',
      'suspended_at': '2026-10-22T10:00:00+00:00',
      'suspended_by_name': 'عمر ملا',
      'client_project_count': 1,
      'contractor_project_count': 4,
      'listing_count': 6,
      'open_report_count': 2,
    });

    expect(model.name, 'خالد الحربي');
    expect(model.avatarUrl, endsWith('u-1/avatar.jpg'));
    expect(model.role, UserRole.user);
    expect(model.memberSince, DateTime.utc(2026, 8, 20, 9));
    expect(model.lastSeenAt, DateTime.utc(2026, 10, 21, 18, 5, 23));
    expect(model.isBusiness, isTrue);
    expect(model.isVerifiedBusiness, isTrue);
    expect(model.verificationStatus, VerificationStatus.verified);
    expect(model.specialty, 'ترميم');
    expect(model.businessCity, 'الخبر');
    expect(model.isSuspended, isTrue);
    expect(model.suspensionReason, 'إعلانات مضللة');
    expect(model.suspendedAt, DateTime.utc(2026, 10, 22, 10));
    expect(model.suspendedByName, 'عمر ملا');
    expect(model.clientProjectCount, 1);
    expect(model.contractorProjectCount, 4);
    expect(model.listingCount, 6);
    expect(model.openReportCount, 2);
  });

  test('a client without a photo, a business or a suspension', () {
    final model = AdminUserModel.fromJson(const {
      'id': 'u-2',
      'full_name': 'سارة',
      'avatar_path': null,
      'avatar_url': null,
      'role': 'admin',
      'member_since': '2026-07-01T00:00:00+00:00',
      'is_deleted': true,
      'is_me': true,
      'last_seen_at': null,
      'is_online': false,
      'is_business': false,
      'verification_status': null,
      'is_suspended': false,
      'client_project_count': 0,
      'contractor_project_count': 0,
      'listing_count': 0,
      'open_report_count': 0,
    });

    expect(model.avatarUrl, isNull);
    expect(model.isAdmin, isTrue);
    expect(model.isMe, isTrue);
    expect(model.isDeleted, isTrue);
    expect(model.lastSeenAt, isNull);
    expect(model.verificationStatus, isNull);
    expect(model.isSuspended, isFalse);
    expect(model.suspendedAt, isNull);
  });
}
