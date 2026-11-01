import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_edit_data.dart';
import 'package:watad/features/profile/shared/domain/repositories/profile_repository.dart';

/// What the edit profile screen opens on (GRA-60): the signed-in user's
/// profile, then their identity, which may not exist.
class GetProfileEditDataUseCase implements UseCase<ProfileEditData, NoParams> {
  const GetProfileEditDataUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<ProfileEditData>> call(NoParams params) async {
    switch (await _repository.getMyProfile()) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(data: final profile):
        return switch (await _repository.getMyIdentity()) {
          Success(data: final identity) => Success(
            ProfileEditData(profile: profile, identity: identity),
          ),
          Failed(:final failure) => Failed(failure),
        };
    }
  }
}
