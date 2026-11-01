/// A place suggested while the contractor searches for their city
/// (GRA-60): a city, district or street, from the `geocode` Edge
/// Function's search.
class ProfileCitySuggestion {
  const ProfileCitySuggestion({
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
