import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_city_suggestion.dart';
import 'package:watad/features/profile/shared/domain/repositories/profile_repository.dart';

/// The places matching what the contractor typed in the city search
/// (GRA-60). Fewer than 2 letters find nothing; the `geocode` function
/// takes at most 100.
class SearchProfileCitiesUseCase
    implements UseCase<List<ProfileCitySuggestion>, String> {
  const SearchProfileCitiesUseCase(this._repository);

  static const int minQueryLength = 2;
  static const int maxQueryLength = 100;

  final ProfileRepository _repository;

  @override
  Future<Result<List<ProfileCitySuggestion>>> call(String params) {
    final query = params.trim();
    if (query.length < minQueryLength) return Future.value(const Success([]));
    return _repository.searchCities(
      query.length > maxQueryLength
          ? query.substring(0, maxQueryLength)
          : query,
    );
  }
}
