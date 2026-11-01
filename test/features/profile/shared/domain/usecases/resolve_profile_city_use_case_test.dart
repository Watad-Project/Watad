import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_city_suggestion.dart';
import 'package:watad/features/profile/shared/domain/usecases/resolve_profile_city_use_case.dart';

import '../../../../../helpers/fake_profile_repository.dart';

void main() {
  const district = ProfileCitySuggestion(
    placeId: 'ChIJ-aziziyah',
    title: 'العزيزية',
    subtitle: 'المدينة المنورة، السعودية',
  );

  late FakeProfileRepository repository;

  setUp(() => repository = FakeProfileRepository());

  test("a district gives its city: the place's point, then its city", () async {
    final result = await ResolveProfileCityUseCase(repository)(district);

    expect(repository.calls, [
      'getPlace(ChIJ-aziziyah)',
      'cityAt(24.4672, 39.6111)',
    ]);
    switch (result) {
      case Success(:final data):
        expect(data, 'المدينة المنورة');
      case Failed():
        fail('Expected the city');
    }
  });

  test('a place where Google knows no city says so', () async {
    repository.cityResult = const Success(null);

    final result = await ResolveProfileCityUseCase(repository)(district);

    switch (result) {
      case Failed(:final failure):
        expect(failure, isA<ValidationFailure>());
        expect(failure.messageKey, 'profile.edit.city_not_found');
      case Success():
        fail('Expected no city');
    }
  });

  test(
    'a place that cannot be found fails, without asking for a city',
    () async {
      repository.placeResult = const Failed(NetworkFailure());

      final result = await ResolveProfileCityUseCase(repository)(district);

      expect(result, isA<Failed<String>>());
      expect(repository.calls, ['getPlace(ChIJ-aziziyah)']);
    },
  );
}
