import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_city_suggestion.dart';
import 'package:watad/features/profile/shared/domain/usecases/search_profile_cities_use_case.dart';

import '../../../../../helpers/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repository;

  setUp(() => repository = FakeProfileRepository());

  test('fewer than 2 letters find nothing, without a search', () async {
    final result = await SearchProfileCitiesUseCase(repository)(' م ');

    switch (result) {
      case Success(:final data):
        expect(data, isEmpty);
      case Failed():
        fail('Expected no places');
    }
    expect(repository.calls, isEmpty);
  });

  test('searches what was typed, trimmed', () async {
    repository.searchResult = const Success([
      ProfileCitySuggestion(
        placeId: 'ChIJs4Zbxrm9vhURk3Jr2y3Bc-0',
        title: 'المدينة المنورة',
        subtitle: 'السعودية',
      ),
    ]);

    final result = await SearchProfileCitiesUseCase(repository)(' المدينة ');

    expect(repository.calls, ['searchCities(المدينة)']);
    switch (result) {
      case Success(:final data):
        expect(data.single.title, 'المدينة المنورة');
      case Failed():
        fail('Expected the places');
    }
  });

  test('a long query is cut to the 100 letters geocode takes', () async {
    await SearchProfileCitiesUseCase(repository)('م' * 120);

    expect(repository.calls, ['searchCities(${'م' * 100})']);
  });
}
