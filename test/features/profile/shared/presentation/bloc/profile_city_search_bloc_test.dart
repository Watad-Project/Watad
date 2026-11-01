import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_city_suggestion.dart';
import 'package:watad/features/profile/shared/domain/usecases/resolve_profile_city_use_case.dart';
import 'package:watad/features/profile/shared/domain/usecases/search_profile_cities_use_case.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_city_search_bloc.dart';

import '../../../../../helpers/fake_profile_repository.dart';

void main() {
  const district = ProfileCitySuggestion(
    placeId: 'ChIJ-aziziyah',
    title: 'العزيزية',
    subtitle: 'المدينة المنورة، السعودية',
  );

  late FakeProfileRepository repository;

  setUp(() {
    repository = FakeProfileRepository()
      ..searchResult = const Success([district]);
  });

  ProfileCitySearchBloc buildBloc() => ProfileCitySearchBloc(
    SearchProfileCitiesUseCase(repository),
    ResolveProfileCityUseCase(repository),
    searchDelay: Duration.zero,
  );

  /// Adds [event] and waits for the first state that passes [test].
  Future<ProfileCitySearchState> after(
    ProfileCitySearchBloc bloc,
    ProfileCitySearchEvent event,
    bool Function(ProfileCitySearchState state) test,
  ) {
    final state = bloc.stream.firstWhere(test);
    bloc.add(event);
    return state;
  }

  test('2 letters or more find places', () async {
    final bloc = buildBloc();

    final state = await after(
      bloc,
      const ProfileCitySearchQueryChanged('العزيز'),
      (s) => !s.isSearching && s.suggestions.isNotEmpty,
    );

    expect(state.suggestions.single.title, 'العزيزية');
    expect(state.messageKey, isNull);
    expect(repository.calls, ['searchCities(العزيز)']);
    await bloc.close();
  });

  test('1 letter clears the places, without a search', () async {
    final bloc = buildBloc();

    final state = await after(
      bloc,
      const ProfileCitySearchQueryChanged('ع'),
      (s) => s.query == 'ع',
    );

    expect(state.isSearching, isFalse);
    expect(state.suggestions, isEmpty);
    expect(repository.calls, isEmpty);
    await bloc.close();
  });

  test('no place has that name: it says so', () async {
    repository.searchResult = const Success([]);
    final bloc = buildBloc();

    final state = await after(
      bloc,
      const ProfileCitySearchQueryChanged('ءءء'),
      (s) => !s.isSearching && s.messageKey != null,
    );

    expect(state.messageKey, 'profile.edit.city_no_results');
    await bloc.close();
  });

  test('a failed search says why', () async {
    repository.searchResult = const Failed(NetworkFailure());
    final bloc = buildBloc();

    final state = await after(
      bloc,
      const ProfileCitySearchQueryChanged('العزيز'),
      (s) => !s.isSearching && s.messageKey != null,
    );

    expect(state.messageKey, 'errors.network');
    await bloc.close();
  });

  test('a picked place gives its city, in Arabic', () async {
    final bloc = buildBloc();

    final state = await after(
      bloc,
      const ProfileCitySearchSuggestionPicked(district),
      (s) => s.city != null,
    );

    expect(state.city, 'المدينة المنورة');
    expect(state.isResolving, isFalse);
    await bloc.close();
  });

  test('a place without a city says so, and gives none', () async {
    repository.cityResult = const Success(null);
    final bloc = buildBloc();

    final state = await after(
      bloc,
      const ProfileCitySearchSuggestionPicked(district),
      (s) => !s.isResolving && s.messageKey != null,
    );

    expect(state.messageKey, 'profile.edit.city_not_found');
    expect(state.city, isNull);
    await bloc.close();
  });

  test('opening the sheet again starts empty', () async {
    final bloc = buildBloc();
    await after(
      bloc,
      const ProfileCitySearchSuggestionPicked(district),
      (s) => s.city != null,
    );

    final state = await after(
      bloc,
      const ProfileCitySearchOpened(),
      (s) => s.city == null,
    );

    expect(state.query, isEmpty);
    expect(state.suggestions, isEmpty);
    await bloc.close();
  });
}
