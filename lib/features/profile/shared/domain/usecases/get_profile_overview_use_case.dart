import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_overview.dart';
import 'package:watad/features/profile/shared/domain/repositories/profile_repository.dart';

/// What the account tabs show (GRA-59): the signed-in user's profile, then
/// their rating. Either failing fails the whole, so the header never shows
/// a rating the server didn't give.
class GetProfileOverviewUseCase implements UseCase<ProfileOverview, NoParams> {
  const GetProfileOverviewUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<ProfileOverview>> call(NoParams params) async {
    switch (await _repository.getMyProfile()) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(data: final profile):
        return switch (await _repository.getRating(profile.id)) {
          Success(data: final rating) => Success(
            ProfileOverview(profile: profile, rating: rating),
          ),
          Failed(:final failure) => Failed(failure),
        };
    }
  }
}
