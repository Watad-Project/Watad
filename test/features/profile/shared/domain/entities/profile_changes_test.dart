import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile_business.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_changes.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_form_check.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo_change.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo_type.dart';

void main() {
  MyProfile contractor(
    VerificationStatus status, {
    String companyName = 'مؤسسة البناء المتين',
  }) => MyProfile(
    id: '3f2a1b4c-5d6e-4f70-8a9b-0c1d2e3f4a5b',
    fullName: 'خالد الحربي',
    isSuspended: false,
    business: MyProfileBusiness(
      companyName: companyName,
      crNumber: '1010123456',
      specializedField: 'مقاولات عامة',
      verificationStatus: status,
      city: 'المدينة المنورة',
    ),
  );

  ProfileFormCheck form({
    String fullName = 'خالد الحربي',
    String companyName = 'مؤسسة البناء المتين',
    String crNumber = '1010123456',
  }) => ProfileFormCheck(
    fullName: fullName,
    companyName: companyName,
    crNumber: crNumber,
  );

  group('the business loses its verification', () {
    test('verified, and a new company name: yes', () {
      final changes = ProfileChanges.between(
        profile: contractor(VerificationStatus.verified),
        check: form(companyName: 'مؤسسة البناء الحديث'),
      );

      expect(changes.unverifiesBusiness, isTrue);
    });

    test('pending, and a new CR number: yes', () {
      final changes = ProfileChanges.between(
        profile: contractor(VerificationStatus.pending),
        check: form(crNumber: '2050123456'),
      );

      expect(changes.business.crNumber, '2050123456');
      expect(changes.unverifiesBusiness, isTrue);
    });

    test('unverified, whatever changes: no', () {
      final changes = ProfileChanges.between(
        profile: contractor(VerificationStatus.unverified),
        check: form(companyName: 'مؤسسة البناء الحديث', crNumber: '2050123456'),
        specializedField: 'تشطيبات',
        city: 'جدة',
      );

      expect(changes.isEmpty, isFalse);
      expect(changes.unverifiesBusiness, isFalse);
    });

    test('verified, and only the city: no', () {
      final changes = ProfileChanges.between(
        profile: contractor(VerificationStatus.verified),
        check: form(),
        city: 'جدة',
      );

      expect(changes.business.city, 'جدة');
      expect(changes.unverifiesBusiness, isFalse);
    });

    test('rejected, and a new company name: no', () {
      final changes = ProfileChanges.between(
        profile: contractor(VerificationStatus.rejected),
        check: form(companyName: 'مؤسسة البناء الحديث'),
      );

      expect(changes.unverifiesBusiness, isFalse);
    });
  });

  test("a verified business's CR number never counts as changed", () {
    final changes = ProfileChanges.between(
      profile: contractor(VerificationStatus.verified),
      check: form(crNumber: '2050123456'),
    );

    expect(changes.business.crNumber, isNull);
    expect(changes.isEmpty, isTrue);
  });

  test('values are compared trimmed: spaces alone are no change', () {
    final changes = ProfileChanges.between(
      profile: contractor(
        VerificationStatus.verified,
        companyName: ' مؤسسة البناء المتين ',
      ),
      check: form(),
      specializedField: 'مقاولات عامة',
      city: ' المدينة المنورة',
    );

    expect(changes.isEmpty, isTrue);
    expect(changes.unverifiesBusiness, isFalse);
  });

  test('only what differs is in the changes', () {
    final changes = ProfileChanges.between(
      profile: contractor(VerificationStatus.unverified),
      check: form(fullName: 'خالد سعد الحربي'),
      specializedField: 'تشطيبات',
    );

    expect(changes.user.fullName, 'خالد سعد الحربي');
    expect(changes.business.specializedField, 'تشطيبات');
    expect(changes.business.companyName, isNull);
    expect(changes.business.crNumber, isNull);
    expect(changes.business.city, isNull);
  });

  test('a client has no business part, and a new photo is a change', () {
    const client = MyProfile(
      id: '7c9e6679-7425-40de-944b-e07fc1f90ae7',
      fullName: 'سارة العتيبي',
      isSuspended: false,
    );
    final photo = ProfilePhoto(
      bytes: Uint8List.fromList(const [0xFF, 0xD8, 0xFF]),
      type: ProfilePhotoType.jpeg,
    );

    final kept = ProfileChanges.between(
      profile: client,
      check: const ProfileFormCheck(fullName: 'سارة العتيبي'),
    );
    final replaced = ProfileChanges.between(
      profile: client,
      check: const ProfileFormCheck(fullName: 'سارة العتيبي'),
      photo: ProfilePhotoReplaced(photo),
    );

    expect(kept.isEmpty, isTrue);
    expect(kept.verificationStatus, isNull);
    expect(replaced.isEmpty, isFalse);
    expect(replaced.business.isEmpty, isTrue);
  });
}
