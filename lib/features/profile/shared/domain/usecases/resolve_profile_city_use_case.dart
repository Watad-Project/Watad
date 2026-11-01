import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_city_suggestion.dart';
import 'package:watad/features/profile/shared/domain/repositories/profile_repository.dart';

/// The city of a picked search suggestion (GRA-60), spelled the way the
/// cities of saved addresses are: where the suggestion is, then the city
/// `geocode` names at that point in Arabic. So a district or a street gives
/// its city, and `v_contractors.is_in_my_city` can match clients in it.
///
/// Fails with `profile.edit.city_not_found` when Google knows no city
/// there.
class ResolveProfileCityUseCase
    implements UseCase<String, ProfileCitySuggestion> {
  const ResolveProfileCityUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<String>> call(ProfileCitySuggestion params) async {
    switch (await _repository.getPlace(params.placeId)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(data: final place):
        return switch (await _repository.cityAt(place)) {
          Success(data: final city?) => Success(city),
          Success() => const Failed(
            ValidationFailure('profile.edit.city_not_found'),
          ),
          Failed(:final failure) => Failed(failure),
        };
    }
  }
}
