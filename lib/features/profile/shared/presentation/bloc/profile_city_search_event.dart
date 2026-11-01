part of 'profile_city_search_bloc.dart';

sealed class ProfileCitySearchEvent {
  const ProfileCitySearchEvent();
}

/// The search sheet opened: it starts empty.
final class ProfileCitySearchOpened extends ProfileCitySearchEvent {
  const ProfileCitySearchOpened();
}

/// The contractor typed in the search field.
final class ProfileCitySearchQueryChanged extends ProfileCitySearchEvent {
  const ProfileCitySearchQueryChanged(this.query);

  final String query;
}

/// The contractor tapped a suggestion: its city is looked up.
final class ProfileCitySearchSuggestionPicked extends ProfileCitySearchEvent {
  const ProfileCitySearchSuggestionPicked(this.suggestion);

  final ProfileCitySuggestion suggestion;
}
