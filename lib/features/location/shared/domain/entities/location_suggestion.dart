/// A place suggested under the map's search field while the user types: a
/// city, district or street (the `geocode` Edge Function's search).
class LocationSuggestion {
  const LocationSuggestion({
    required this.placeId,
    required this.title,
    this.subtitle,
  });

  /// Google's id of the place, to find where it is.
  final String placeId;

  /// The place's own name, e.g. «العزيزية».
  final String title;

  /// Where it is, e.g. «المدينة المنورة، السعودية».
  final String? subtitle;
}
