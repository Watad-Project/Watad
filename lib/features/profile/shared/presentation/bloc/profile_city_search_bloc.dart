import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_city_suggestion.dart';
import 'package:watad/features/profile/shared/domain/usecases/resolve_profile_city_use_case.dart';
import 'package:watad/features/profile/shared/domain/usecases/search_profile_cities_use_case.dart';

part 'profile_city_search_event.dart';
part 'profile_city_search_state.dart';

/// The city search of the edit profile screen (GRA-60): the places that
/// match what the contractor types, then the city of the one they pick.
class ProfileCitySearchBloc
    extends Bloc<ProfileCitySearchEvent, ProfileCitySearchState> {
  /// [searchDelay] is how long typing must pause before the search runs.
  ProfileCitySearchBloc(
    this._searchCities,
    this._resolveCity, {
    this.searchDelay = const Duration(milliseconds: 350),
  }) : super(const ProfileCitySearchState()) {
    on<ProfileCitySearchOpened>(_onOpened);
    on<ProfileCitySearchQueryChanged>(_onQueryChanged);
    on<ProfileCitySearchSuggestionPicked>(_onSuggestionPicked);
  }

  final SearchProfileCitiesUseCase _searchCities;
  final ResolveProfileCityUseCase _resolveCity;

  /// One search per pause in typing, not one per letter.
  final Duration searchDelay;

  void _onOpened(
    ProfileCitySearchOpened event,
    Emitter<ProfileCitySearchState> emit,
  ) => emit(const ProfileCitySearchState());

  Future<void> _onQueryChanged(
    ProfileCitySearchQueryChanged event,
    Emitter<ProfileCitySearchState> emit,
  ) async {
    if (state.isResolving) return;
    final searches =
        event.query.trim().length >= SearchProfileCitiesUseCase.minQueryLength;
    // The last suggestions stay until the new ones arrive.
    emit(
      ProfileCitySearchState(
        query: event.query,
        suggestions: searches ? state.suggestions : const [],
        isSearching: searches,
      ),
    );
    if (!searches) return;

    await Future<void>.delayed(searchDelay);
    // A newer letter, or a picked suggestion, replaces this search.
    if (emit.isDone || state.query != event.query || state.isResolving) {
      return;
    }
    final result = await _searchCities(event.query);
    if (emit.isDone || state.query != event.query || state.isResolving) {
      return;
    }
    emit(switch (result) {
      Success(:final data) => ProfileCitySearchState(
        query: event.query,
        suggestions: data,
        messageKey: data.isEmpty ? 'profile.edit.city_no_results' : null,
      ),
      Failed(:final failure) => ProfileCitySearchState(
        query: event.query,
        messageKey: failure.messageKey,
      ),
    });
  }

  Future<void> _onSuggestionPicked(
    ProfileCitySearchSuggestionPicked event,
    Emitter<ProfileCitySearchState> emit,
  ) async {
    if (state.isResolving) return;
    emit(
      state.copyWith(
        isSearching: false,
        isResolving: true,
        messageKey: () => null,
      ),
    );
    final result = await _resolveCity(event.suggestion);
    emit(switch (result) {
      Success(:final data) => state.copyWith(
        isResolving: false,
        city: () => data,
      ),
      Failed(:final failure) => state.copyWith(
        isResolving: false,
        messageKey: () => failure.messageKey,
      ),
    });
  }
}
