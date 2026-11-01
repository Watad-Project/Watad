import 'dart:developer';

import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo_change.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_save_outcome.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_save_part.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_save_request.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_user_changes.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_user_write.dart';
import 'package:watad/features/profile/shared/domain/repositories/profile_repository.dart';

/// «حفظ» on the edit profile screen (GRA-60). It sends only what changed,
/// in two parts, then reads the profile back, so the screen shows what the
/// server stored:
///
/// 1. The account, in one update of `users`: the name and the photo. A new
///    photo is uploaded first, then the row points to it, and only then is
///    the old file deleted.
/// 2. The business, in one update of `businesses`.
///
/// One part can fail while the other is saved; the outcome says which. A
/// form whose check found a problem is refused with that problem's key, so
/// nothing invalid is sent.
class SaveProfileUseCase
    implements UseCase<ProfileSaveOutcome, ProfileSaveRequest> {
  const SaveProfileUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<ProfileSaveOutcome>> call(ProfileSaveRequest params) async {
    if (params.check.firstError case final key?) {
      return Failed(ValidationFailure(key));
    }
    final changes = params.changes;
    final user = await _saveUser(params.profile, changes.user);
    final business = changes.business.isEmpty
        ? const ProfileSavePartUnchanged()
        : switch (await _repository.updateBusiness(changes.business)) {
            Success() => const ProfileSavePartSaved(),
            Failed(:final failure) => ProfileSavePartFailed(failure),
          };
    final profile = switch (await _repository.getMyProfile()) {
      Success(:final data) => data,
      Failed() => null,
    };
    return Success(
      ProfileSaveOutcome(user: user, business: business, profile: profile),
    );
  }

  Future<ProfileSavePart> _saveUser(
    MyProfile profile,
    ProfileUserChanges changes,
  ) async {
    if (changes.isEmpty) return const ProfileSavePartUnchanged();
    final photoChange = changes.photo;
    String? uploaded;
    if (photoChange case ProfilePhotoReplaced(:final photo)) {
      switch (await _repository.uploadAvatar(photo)) {
        case Success(:final data):
          uploaded = data;
        case Failed(:final failure):
          return ProfileSavePartFailed(failure);
      }
    }
    final written = await _repository.updateUser(
      ProfileUserWrite(
        fullName: changes.fullName,
        changesAvatar: photoChange is! ProfilePhotoKept,
        avatarPath: uploaded,
      ),
    );
    if (written case Failed(:final failure)) {
      // The row doesn't point to the new file: don't leave it behind.
      if (uploaded != null) await _repository.deleteAvatar(uploaded);
      return ProfileSavePartFailed(failure);
    }
    // The row points elsewhere now, so the profile never shows a missing
    // photo. If deleting the old file fails, the profile is right anyway.
    final old = profile.avatarPath;
    if (photoChange is! ProfilePhotoKept && old != null) {
      if (await _repository.deleteAvatar(old) case Failed()) {
        log('The old profile photo stayed in avatars', name: 'watad.profile');
      }
    }
    return const ProfileSavePartSaved();
  }
}
