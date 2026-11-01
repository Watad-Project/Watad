part of 'profile_city_search_bloc.dart';

final class ProfileCitySearchState {
  const ProfileCitySearchState({
    this.query = '',
    this.suggestions = const [],
    this.isSearching = false,
    this.isResolving = false,
    this.messageKey,
    this.city,
  });

  /// What the contractor typed.
  final String query;
  final List<ProfileCitySuggestion> suggestions;

  /// A search is on its way.
  final bool isSearching;

  /// The city of a picked suggestion is being looked up.
  final bool isResolving;

  /// Shown instead of the suggestions: no place has that name, the search
  /// failed, or the picked place has no city.
  final String? messageKey;

  /// The city of the picked suggestion; the sheet closes with it.
  final String? city;

  ProfileCitySearchState copyWith({
    bool? isSearching,
    bool? isResolving,
    String? Function()? messageKey,
    String? Function()? city,
  }) {
    return ProfileCitySearchState(
      query: query,
      suggestions: suggestions,
      isSearching: isSearching ?? this.isSearching,
      isResolving: isResolving ?? this.isResolving,
      messageKey: messageKey == null ? this.messageKey : messageKey(),
      city: city == null ? this.city : city(),
    );
  }
}
