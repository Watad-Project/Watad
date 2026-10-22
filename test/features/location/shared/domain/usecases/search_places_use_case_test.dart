import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/location/shared/domain/entities/location_suggestion.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';
import 'package:watad/features/location/shared/domain/usecases/search_places_use_case.dart';

import '../../../../../helpers/fake_place_search.dart';

/// Only the search is used here; anything else fails the test.
class _FakeLocationRepository
    with FakePlaceSearch
    implements LocationRepository {
  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _FakeLocationRepository repository;

  setUp(() => repository = _FakeLocationRepository());

  test('searches the trimmed name', () async {
    repository.searchResult = const Success([
      LocationSuggestion(placeId: 'place-jeddah', title: 'جدة'),
    ]);

    final result = await SearchPlacesUseCase(repository)(
      const SearchPlacesParams(query: '  جدة ', language: 'en'),
    );

    expect(
      (result as Success<List<LocationSuggestion>>).data.single.title,
      'جدة',
    );
    expect(repository.searched, [('جدة', 'en')]);
  });

  test('fewer than two letters search nothing', () async {
    final result = await SearchPlacesUseCase(repository)(
      const SearchPlacesParams(query: ' ج '),
    );

    expect((result as Success<List<LocationSuggestion>>).data, isEmpty);
    expect(repository.searched, isEmpty);
  });
}
