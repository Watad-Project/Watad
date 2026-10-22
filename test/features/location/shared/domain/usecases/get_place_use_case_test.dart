import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/location/shared/domain/entities/location_place.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';
import 'package:watad/features/location/shared/domain/usecases/get_place_use_case.dart';

import '../../../../../helpers/fake_place_search.dart';

/// Only the place lookup is used here; anything else fails the test.
class _FakeLocationRepository
    with FakePlaceSearch
    implements LocationRepository {
  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  test('finds where the suggested place is', () async {
    final repository = _FakeLocationRepository()
      ..placeResult = const Success(
        LocationPlace(latitude: 21.5433, longitude: 39.1728),
      );

    final result = await GetPlaceUseCase(repository)('place-jeddah');

    expect((result as Success<LocationPlace>).data.latitude, 21.5433);
    expect(repository.placesAsked, ['place-jeddah']);
  });
}
