import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/profile/shared/datasource/models/my_profile_model.dart';

void main() {
  /// A `v_my_profile` row as the data source passes it on, with the photo's
  /// public URL added. A client's business columns are all null.
  Map<String, dynamic> row({
    bool isBusiness = false,
    String status = 'verified',
    String specialty = 'مقاولات عامة',
    String? city,
    bool isSuspended = false,
    String? reason,
    String? avatarPath,
  }) => {
    'id': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
    'full_name': 'سارة العتيبي',
    'avatar_path': avatarPath,
    'avatar_url': avatarPath == null
        ? null
        : 'https://cdn.example/storage/v1/object/public/avatars/$avatarPath',
    'is_business': isBusiness,
    'company_name': isBusiness ? 'مؤسسة البناء المتين' : null,
    'cr_number': isBusiness ? '1010123456' : null,
    'specialized_field': isBusiness ? specialty : null,
    'verification_status': isBusiness ? status : null,
    'city': city,
    'is_suspended': isSuspended,
    'suspension_reason': reason,
  };

  test('a client: no business, no photo, not suspended', () {
    final profile = MyProfileModel.fromJson(row());

    expect(profile.id, '7c9e6679-7425-40de-944b-e07fc1f90ae7');
    expect(profile.fullName, 'سارة العتيبي');
    expect(profile.business, isNull);
    expect(profile.avatarPath, isNull);
    expect(profile.avatarUrl, isNull);
    expect(profile.isSuspended, isFalse);
    expect(profile.suspensionReason, isNull);
  });

  test('a contractor in each verification status', () {
    for (final status in VerificationStatus.values) {
      final profile = MyProfileModel.fromJson(
        row(isBusiness: true, status: status.value),
      );

      final business = profile.business;
      expect(business, isNotNull);
      expect(business?.verificationStatus, status);
      expect(business?.companyName, 'مؤسسة البناء المتين');
      expect(business?.crNumber, '1010123456');
    }
  });

  test('a suspended user carries the reason', () {
    final profile = MyProfileModel.fromJson(
      row(isSuspended: true, reason: 'مخالفة شروط الاستخدام'),
    );

    expect(profile.isSuspended, isTrue);
    expect(profile.suspensionReason, 'مخالفة شروط الاستخدام');
  });

  test("a business's city is kept, and null until it's set", () {
    final noCity = MyProfileModel.fromJson(row(isBusiness: true));
    final withCity = MyProfileModel.fromJson(
      row(isBusiness: true, city: 'المدينة المنورة'),
    );

    expect(noCity.business?.city, isNull);
    expect(withCity.business?.city, 'المدينة المنورة');
  });

  test('a specialty that is no choice is kept as stored', () {
    for (final stored in ['contractor', 'fdfds']) {
      final profile = MyProfileModel.fromJson(
        row(isBusiness: true, specialty: stored),
      );

      expect(profile.business?.specializedField, stored);
    }
  });

  test('the photo comes with its path and its public URL', () {
    final profile = MyProfileModel.fromJson(
      row(avatarPath: '7c9e6679-7425-40de-944b-e07fc1f90ae7/avatar_1.jpg'),
    );

    expect(
      profile.avatarPath,
      '7c9e6679-7425-40de-944b-e07fc1f90ae7/avatar_1.jpg',
    );
    expect(profile.avatarUrl, endsWith('/avatars/${profile.avatarPath}'));
  });
}
