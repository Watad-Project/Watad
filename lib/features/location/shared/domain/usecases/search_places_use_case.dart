import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/location/shared/domain/entities/location_suggestion.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';

/// Parameters for [SearchPlacesUseCase].
class SearchPlacesParams {
  const SearchPlacesParams({
    required this.query,
    this.language = 'ar',
    this.nearLatitude,
    this.nearLongitude,
  });

  /// What the user typed: a city, district or street.
  final String query;

  /// The app's language, `ar` or `en`, for the suggestions' names.
  final String language;

  /// Where the map is: places near it come first.
  final double? nearLatitude;
  final double? nearLongitude;
}

/// The places matching what the user typed in the map's search field.
class SearchPlacesUseCase
    implements UseCase<List<LocationSuggestion>, SearchPlacesParams> {
  const SearchPlacesUseCase(this._repository);

  /// Fewer letters than this match too much to be useful.
  static const int minQueryLength = 2;

  final LocationRepository _repository;

  @override
  Future<Result<List<LocationSuggestion>>> call(SearchPlacesParams params) {
    final query = params.query.trim();
    if (query.length < minQueryLength) return Future.value(const Success([]));
    return _repository.searchPlaces(
      query: query,
      language: params.language,
      nearLatitude: params.nearLatitude,
      nearLongitude: params.nearLongitude,
    );
  }
}
