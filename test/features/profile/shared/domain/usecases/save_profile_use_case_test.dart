import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile_business.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_form_check.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo_change.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo_type.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_save_outcome.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_save_part.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_save_request.dart';
import 'package:watad/features/profile/shared/domain/usecases/save_profile_use_case.dart';

import '../../../../../helpers/fake_profile_repository.dart';

void main() {
  const oldPhoto = '3f2a1b4c-5d6e-4f70-8a9b-0c1d2e3f4a5b/avatar_9.jpg';

  /// An unverified contractor with a saved photo.
  const contractor = MyProfile(
    id: '3f2a1b4c-5d6e-4f70-8a9b-0c1d2e3f4a5b',
    fullName: 'خالد الحربي',
    isSuspended: false,
    avatarPath: oldPhoto,
    avatarUrl: 'https://cdn.example/avatars/$oldPhoto',
    business: MyProfileBusiness(
      companyName: 'مؤسسة البناء المتين',
      crNumber: '1010123456',
      specializedField: 'مقاولات عامة',
      verificationStatus: VerificationStatus.unverified,
    ),
  );

  final photo = ProfilePhoto(
    bytes: Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xE0]),
    type: ProfilePhotoType.jpeg,
  );

  late FakeProfileRepository repository;

  setUp(() {
    repository = FakeProfileRepository(
      profileResult: const Success(contractor),
    );
  });

  /// The form as typed: the saved values unless one is given.
  ProfileFormCheck form({
    String fullName = 'خالد الحربي',
    String crNumber = '1010123456',
  }) => ProfileFormCheck(
    fullName: fullName,
    companyName: 'مؤسسة البناء المتين',
    crNumber: crNumber,
  );

  Future<ProfileSaveOutcome> save(ProfileSaveRequest request) async =>
      switch (await SaveProfileUseCase(repository)(request)) {
        Success(:final data) => data,
        Failed(:final failure) => throw StateError('Refused: $failure'),
      };

  test(
    'only the name changed: one update of users, with only the name',
    () async {
      final outcome = await save(
        ProfileSaveRequest(
          profile: contractor,
          check: form(fullName: 'خالد سعد الحربي'),
        ),
      );

      expect(repository.calls, ['updateUser', 'getMyProfile']);
      final write = repository.userWrites.single;
      expect(write.fullName, 'خالد سعد الحربي');
      expect(write.changesAvatar, isFalse);
      expect(outcome.user, isA<ProfileSavePartSaved>());
      expect(outcome.business, isA<ProfileSavePartUnchanged>());
      expect(outcome.profile?.fullName, 'خالد سعد الحربي');
    },
  );

  test('only business fields changed: only those columns are sent', () async {
    await save(
      ProfileSaveRequest(
        profile: contractor,
        check: form(),
        specializedField: 'تشطيبات',
        city: 'جدة',
      ),
    );

    expect(repository.calls, ['updateBusiness', 'getMyProfile']);
    final write = repository.businessWrites.single;
    expect(write.specializedField, 'تشطيبات');
    expect(write.city, 'جدة');
    expect(write.companyName, isNull);
    expect(write.crNumber, isNull);
  });

  test(
    'a new photo: uploaded, then the row points to it, then the old file goes',
    () async {
      final outcome = await save(
        ProfileSaveRequest(
          profile: contractor,
          check: form(),
          photo: ProfilePhotoReplaced(photo),
        ),
      );

      expect(repository.calls, [
        'uploadAvatar',
        'updateUser',
        'deleteAvatar($oldPhoto)',
        'getMyProfile',
      ]);
      final write = repository.userWrites.single;
      expect(write.changesAvatar, isTrue);
      expect(write.avatarPath, '${contractor.id}/avatar_1.jpg');
      expect(write.fullName, isNull);
      expect(outcome.profile?.avatarPath, '${contractor.id}/avatar_1.jpg');
    },
  );

  test('removing the photo clears the path, then deletes the file', () async {
    await save(
      ProfileSaveRequest(
        profile: contractor,
        check: form(),
        photo: const ProfilePhotoRemoved(),
      ),
    );

    expect(repository.calls, [
      'updateUser',
      'deleteAvatar($oldPhoto)',
      'getMyProfile',
    ]);
    final write = repository.userWrites.single;
    expect(write.changesAvatar, isTrue);
    expect(write.avatarPath, isNull);
  });

  test(
    'a refused users update deletes the new upload, keeps the old photo',
    () async {
      repository.updateUserResult = const Failed(PermissionFailure());

      final outcome = await save(
        ProfileSaveRequest(
          profile: contractor,
          check: form(fullName: 'خالد سعد الحربي'),
          photo: ProfilePhotoReplaced(photo),
        ),
      );

      expect(repository.calls, [
        'uploadAvatar',
        'updateUser',
        'deleteAvatar(${contractor.id}/avatar_1.jpg)',
        'getMyProfile',
      ]);
      expect(
        outcome.user,
        isA<ProfileSavePartFailed>().having(
          (part) => part.failure,
          'failure',
          isA<PermissionFailure>(),
        ),
      );
      expect(outcome.isComplete, isFalse);
      expect(outcome.savedAnything, isFalse);
    },
  );

  test('a failed upload sends nothing else for the account', () async {
    repository.uploadResult = const Failed(NetworkFailure());

    final outcome = await save(
      ProfileSaveRequest(
        profile: contractor,
        check: form(fullName: 'خالد سعد الحربي'),
        photo: ProfilePhotoReplaced(photo),
      ),
    );

    expect(repository.calls, ['uploadAvatar', 'getMyProfile']);
    expect(outcome.user, isA<ProfileSavePartFailed>());
  });

  test(
    'an old photo that fails to go away still leaves a saved profile',
    () async {
      repository.deleteResult = const Failed(ServerFailure());

      final outcome = await save(
        ProfileSaveRequest(
          profile: contractor,
          check: form(),
          photo: ProfilePhotoReplaced(photo),
        ),
      );

      expect(outcome.user, isA<ProfileSavePartSaved>());
      expect(outcome.isComplete, isTrue);
    },
  );

  test(
    'a partial failure: the name is saved, the CR number is taken',
    () async {
      repository.updateBusinessResult = const Failed(ConflictFailure());

      final outcome = await save(
        ProfileSaveRequest(
          profile: contractor,
          check: form(fullName: 'خالد سعد الحربي', crNumber: '2050123456'),
        ),
      );

      expect(repository.calls, [
        'updateUser',
        'updateBusiness',
        'getMyProfile',
      ]);
      expect(outcome.user, isA<ProfileSavePartSaved>());
      expect(
        outcome.business,
        isA<ProfileSavePartFailed>().having(
          (part) => part.failure,
          'failure',
          isA<ConflictFailure>(),
        ),
      );
      expect(outcome.isComplete, isFalse);
      expect(outcome.savedAnything, isTrue);
      // Read back: the new name, the old CR number.
      expect(outcome.profile?.fullName, 'خالد سعد الحربي');
      expect(outcome.profile?.business?.crNumber, '1010123456');
    },
  );

  test('a form with a problem is refused before anything is sent', () async {
    final result = await SaveProfileUseCase(repository)(
      const ProfileSaveRequest(
        profile: contractor,
        check: ProfileFormCheck(
          fullName: 'خ',
          fullNameError: 'profile.edit.name_invalid',
        ),
      ),
    );

    switch (result) {
      case Failed(:final failure):
        expect(failure, isA<ValidationFailure>());
        expect(failure.messageKey, 'profile.edit.name_invalid');
      case Success():
        fail('Expected a refusal');
    }
    expect(repository.calls, isEmpty);
  });

  test('a failed read-back still reports what was saved', () async {
    final outcome = await SaveProfileUseCase(_FailingReads(repository))(
      ProfileSaveRequest(
        profile: contractor,
        check: form(fullName: 'خالد سعد الحربي'),
      ),
    );

    switch (outcome) {
      case Success(:final data):
        expect(data.user, isA<ProfileSavePartSaved>());
        expect(data.profile, isNull);
      case Failed():
        fail('Expected the outcome');
    }
  });
}

/// [FakeProfileRepository] whose reads of the profile fail.
class _FailingReads extends FakeProfileRepository {
  _FailingReads(FakeProfileRepository source)
    : super(profileResult: source.profileResult);

  @override
  Future<Result<MyProfile>> getMyProfile() async =>
      const Failed(NetworkFailure());
}
