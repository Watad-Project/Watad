import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile_business.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_form_draft.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo_change.dart';
import 'package:watad/features/profile/shared/domain/usecases/check_profile_form_use_case.dart';
import 'package:watad/features/profile/shared/domain/usecases/get_profile_edit_data_use_case.dart';
import 'package:watad/features/profile/shared/domain/usecases/prepare_profile_photo_use_case.dart';
import 'package:watad/features/profile/shared/domain/usecases/save_profile_use_case.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_edit_bloc.dart';

import '../../../../../helpers/fake_profile_repository.dart';

void main() {
  final jpeg = Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xE0, 0, 0]);
  final gif = Uint8List.fromList(const [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]);

  MyProfile contractor({
    VerificationStatus status = VerificationStatus.verified,
    bool isSuspended = false,
  }) => MyProfile(
    id: fakeContractorProfile.id,
    fullName: 'خالد الحربي',
    isSuspended: isSuspended,
    business: MyProfileBusiness(
      companyName: 'مؤسسة البناء المتين',
      crNumber: '1010123456',
      specializedField: 'مقاولات عامة',
      verificationStatus: status,
    ),
  );

  ProfileFormDraft contractorForm({
    String fullName = 'خالد الحربي',
    String companyName = 'مؤسسة البناء المتين',
    String crNumber = '1010123456',
  }) => ProfileFormDraft(
    fullName: fullName,
    companyName: companyName,
    crNumber: crNumber,
  );

  late FakeProfileRepository repository;

  setUp(() => repository = FakeProfileRepository());

  ProfileEditBloc buildBloc() => ProfileEditBloc(
    GetProfileEditDataUseCase(repository),
    const CheckProfileFormUseCase(),
    const PrepareProfilePhotoUseCase(),
    SaveProfileUseCase(repository),
  );

  Future<ProfileEditBloc> loadedBloc() async {
    final bloc = buildBloc()..add(const ProfileEditFetched());
    await bloc.stream.firstWhere(
      (s) =>
          s.status == ProfileEditStatus.ready ||
          s.status == ProfileEditStatus.failure,
    );
    return bloc;
  }

  /// Adds [event] and waits for the first state that passes [test].
  Future<ProfileEditState> after(
    ProfileEditBloc bloc,
    ProfileEditEvent event,
    bool Function(ProfileEditState state) test,
  ) {
    final state = bloc.stream.firstWhere(test);
    bloc.add(event);
    return state;
  }

  /// Adds «حفظ» and waits for its answer.
  Future<ProfileEditState> submit(ProfileEditBloc bloc) => after(
    bloc,
    const ProfileEditSubmitted(),
    (s) => !s.isSaving && s.message != null,
  );

  test('opens on the saved values, with nothing to save', () async {
    final bloc = await loadedBloc();

    expect(bloc.state.status, ProfileEditStatus.ready);
    expect(bloc.state.check?.fullName, fakeClientProfile.fullName);
    expect(bloc.state.data?.identity?.phone, fakeIdentity.phone);
    expect(bloc.state.hasChanges, isFalse);
    expect(bloc.state.canSave, isFalse);
    await bloc.close();
  });

  test('a contractor without a v_my_identity row opens without it', () async {
    repository
      ..profileResult = Success(contractor())
      ..identityResult = const Success(null);
    final bloc = await loadedBloc();

    expect(bloc.state.data?.identity, isNull);
    expect(bloc.state.isCrNumberLocked, isTrue);
    await bloc.close();
  });

  test('a profile that fails to load shows the failure', () async {
    repository.profileResult = const Failed(NetworkFailure());
    final bloc = await loadedBloc();

    expect(bloc.state.status, ProfileEditStatus.failure);
    expect(bloc.state.failure, isA<NetworkFailure>());
    await bloc.close();
  });

  test('a new valid name can be saved; a name of 1 letter cannot', () async {
    final bloc = await loadedBloc();

    final valid = await after(
      bloc,
      const ProfileEditFormChanged(ProfileFormDraft(fullName: 'سارة محمد')),
      (s) => s.check?.fullName == 'سارة محمد',
    );
    expect(valid.canSave, isTrue);

    final invalid = await after(
      bloc,
      const ProfileEditFormChanged(ProfileFormDraft(fullName: 'س')),
      (s) => s.check?.fullName == 'س',
    );
    expect(invalid.canSave, isFalse);
    expect(invalid.fullNameError, 'profile.edit.name_invalid');
    await bloc.close();
  });

  test('saving stores the new name and finishes', () async {
    final bloc = await loadedBloc();
    await after(
      bloc,
      const ProfileEditFormChanged(ProfileFormDraft(fullName: 'سارة محمد')),
      (s) => s.canSave,
    );

    final state = await submit(bloc);

    expect(state.status, ProfileEditStatus.saved);
    expect(state.message?.key, 'profile.edit.saved');
    expect(state.message?.kind, ProfileEditMessageKind.success);
    expect(repository.userWrites.single.fullName, 'سارة محمد');
    expect(state.profile?.fullName, 'سارة محمد');
    await bloc.close();
  });

  test(
    'a new company name on a verified business un-verifies it, and says so',
    () async {
      repository.profileResult = Success(contractor());
      final bloc = await loadedBloc();
      final changed = await after(
        bloc,
        ProfileEditFormChanged(
          contractorForm(companyName: 'مؤسسة البناء الحديث'),
        ),
        (s) => s.canSave,
      );
      expect(changed.unverifiesBusiness, isTrue);

      final state = await submit(bloc);

      expect(state.status, ProfileEditStatus.saved);
      expect(state.message?.key, 'profile.edit.saved_unverified');
      expect(
        state.profile?.business?.verificationStatus,
        VerificationStatus.unverified,
      );
      await bloc.close();
    },
  );

  test(
    'a taken CR number (23505) shows under the field; the form stays',
    () async {
      repository
        ..profileResult = Success(
          contractor(status: VerificationStatus.unverified),
        )
        ..updateBusinessResult = const Failed(ConflictFailure());
      final bloc = await loadedBloc();
      await after(
        bloc,
        ProfileEditFormChanged(contractorForm(crNumber: '2050123456')),
        (s) => s.canSave,
      );

      final state = await submit(bloc);

      expect(state.status, ProfileEditStatus.ready);
      expect(state.crNumberTaken, isTrue);
      expect(state.crNumberError, 'profile.edit.cr_number_taken');
      expect(state.message?.key, 'profile.edit.cr_number_taken');
      // Nothing was stored, so there's no part to report, and it's still
      // a change.
      expect(state.outcome, isNull);
      expect(state.hasChanges, isTrue);

      // Another number may be free: the field stops saying it's taken.
      final retyped = await after(
        bloc,
        ProfileEditFormChanged(contractorForm(crNumber: '2050123457')),
        (s) => s.check?.crNumber == '2050123457',
      );
      expect(retyped.crNumberTaken, isFalse);
      await bloc.close();
    },
  );

  test('a suspended account can change nothing', () async {
    repository.profileResult = const Success(
      MyProfile(
        id: '7c9e6679-7425-40de-944b-e07fc1f90ae7',
        fullName: 'سارة العتيبي',
        isSuspended: true,
        suspensionReason: 'مخالفة شروط الاستخدام',
      ),
    );
    final bloc = await loadedBloc();

    expect(bloc.state.isEditable, isFalse);
    bloc
      ..add(const ProfileEditFormChanged(ProfileFormDraft(fullName: 'سارة')))
      ..add(ProfileEditPhotoPicked(jpeg));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.check?.fullName, 'سارة العتيبي');
    expect(bloc.state.photo, isA<ProfilePhotoKept>());
    expect(bloc.state.canSave, isFalse);
    await bloc.close();
  });

  test(
    'the server refusing the account (42501) says so; nothing is saved',
    () async {
      repository.updateUserResult = const Failed(PermissionFailure());
      final bloc = await loadedBloc();
      await after(
        bloc,
        const ProfileEditFormChanged(ProfileFormDraft(fullName: 'سارة محمد')),
        (s) => s.canSave,
      );

      final state = await submit(bloc);

      expect(state.status, ProfileEditStatus.ready);
      expect(state.message?.key, 'errors.permission');
      expect(state.message?.kind, ProfileEditMessageKind.error);
      expect(state.outcome, isNull);
      expect(state.profile?.fullName, 'سارة العتيبي');
      await bloc.close();
    },
  );

  test(
    'a partial save: the name is stored, the business part is not',
    () async {
      repository
        ..profileResult = Success(
          contractor(status: VerificationStatus.unverified),
        )
        ..updateBusinessResult = const Failed(ServerFailure());
      final bloc = await loadedBloc();
      await after(
        bloc,
        ProfileEditFormChanged(contractorForm(fullName: 'خالد سعد الحربي')),
        (s) => s.check?.fullName == 'خالد سعد الحربي',
      );
      await after(
        bloc,
        const ProfileEditSpecialtyPicked('تشطيبات'),
        (s) => s.specializedField == 'تشطيبات',
      );

      final state = await submit(bloc);

      expect(state.status, ProfileEditStatus.ready);
      expect(state.message?.key, 'errors.server');
      expect(state.outcome?.savedAnything, isTrue);
      // Measured against the server now: the name is no longer a change,
      // the specialty still is.
      expect(state.profile?.fullName, 'خالد سعد الحربي');
      expect(state.changes.user.isEmpty, isTrue);
      expect(state.changes.business.specializedField, 'تشطيبات');
      expect(state.canSave, isTrue);
      await bloc.close();
    },
  );

  test(
    'a picked file that is no image is refused; a JPEG waits for «حفظ»',
    () async {
      final bloc = await loadedBloc();

      final refused = await after(
        bloc,
        ProfileEditPhotoPicked(gif),
        (s) => s.message != null,
      );
      expect(refused.message?.key, 'profile.edit.photo_type_invalid');
      expect(refused.photo, isA<ProfilePhotoKept>());

      final picked = await after(
        bloc,
        ProfileEditPhotoPicked(jpeg),
        (s) => s.photo is ProfilePhotoReplaced,
      );
      expect(picked.hasChanges, isTrue);
      expect(repository.calls, isNot(contains('uploadAvatar')));
      await bloc.close();
    },
  );

  test(
    'removing: a saved photo goes on «حفظ», a picked one just goes',
    () async {
      repository.profileResult = const Success(
        MyProfile(
          id: '7c9e6679-7425-40de-944b-e07fc1f90ae7',
          fullName: 'سارة العتيبي',
          isSuspended: false,
          avatarPath: '7c9e6679-7425-40de-944b-e07fc1f90ae7/avatar_9.jpg',
        ),
      );
      final withPhoto = await loadedBloc();
      final removed = await after(
        withPhoto,
        const ProfileEditPhotoRemoved(),
        (s) => s.photo is ProfilePhotoRemoved,
      );
      expect(removed.hasChanges, isTrue);
      await withPhoto.close();

      repository.profileResult = const Success(fakeClientProfile);
      final withoutPhoto = await loadedBloc();
      await after(
        withoutPhoto,
        ProfileEditPhotoPicked(jpeg),
        (s) => s.photo is ProfilePhotoReplaced,
      );
      final dropped = await after(
        withoutPhoto,
        const ProfileEditPhotoRemoved(),
        (s) => s.photo is ProfilePhotoKept,
      );
      expect(dropped.hasChanges, isFalse);
      await withoutPhoto.close();
    },
  );

  test(
    'a picked specialty or city is a change; the saved specialty is not',
    () async {
      repository.profileResult = Success(contractor());
      final bloc = await loadedBloc();

      final specialty = await after(
        bloc,
        const ProfileEditSpecialtyPicked('تشطيبات'),
        (s) => s.hasChanges,
      );
      expect(specialty.unverifiesBusiness, isFalse);

      final back = await after(
        bloc,
        const ProfileEditSpecialtyPicked(null),
        (s) => !s.hasChanges,
      );
      expect(back.specializedField, isNull);

      final city = await after(
        bloc,
        const ProfileEditCityPicked('جدة'),
        (s) => s.hasChanges,
      );
      expect(city.changes.business.city, 'جدة');
      await bloc.close();
    },
  );
}
