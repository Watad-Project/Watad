import 'package:watad/core/error/result.dart';
import 'package:watad/features/location/shared/domain/entities/location_place.dart';
import 'package:watad/features/location/shared/domain/entities/location_suggestion.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';

/// The map search of a [LocationRepository] fake: it answers with the
/// results you set and records what was asked (APP_ARCHITECTURE.md §16).
///
/// ```dart
/// class _FakeLocationRepository with FakePlaceSearch
///     implements LocationRepository { … }
/// ```
mixin FakePlaceSearch implements LocationRepository {
  Result<List<LocationSuggestion>> searchResult = const Success([]);
  Result<LocationPlace> placeResult = const Success(
    LocationPlace(latitude: 24.4672, longitude: 39.6111),
  );

  /// The searches sent, as (query, language).
  final List<(String, String)> searched = [];

  /// The place ids looked up.
  final List<String> placesAsked = [];

  @override
  Future<Result<List<LocationSuggestion>>> searchPlaces({
    required String query,
    required String language,
    double? nearLatitude,
    double? nearLongitude,
  }) async {
    searched.add((query, language));
    return searchResult;
  }

  @override
  Future<Result<LocationPlace>> getPlace(String placeId) async {
    placesAsked.add(placeId);
    return placeResult;
  }
}
