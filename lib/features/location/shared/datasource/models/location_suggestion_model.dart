import 'package:watad/features/location/shared/domain/entities/location_suggestion.dart';

/// A suggestion of the `geocode` Edge Function's search.
class LocationSuggestionModel extends LocationSuggestion {
  const LocationSuggestionModel({
    required super.placeId,
    required super.title,
    super.subtitle,
  });

  /// From one of `suggestions`: `{place_id, title, subtitle}`.
  factory LocationSuggestionModel.fromJson(Map<String, dynamic> json) {
    final subtitle = (json['subtitle'] as String?)?.trim();
    return LocationSuggestionModel(
      placeId: json['place_id'] as String,
      title: (json['title'] as String).trim(),
      subtitle: subtitle == null || subtitle.isEmpty ? null : subtitle,
    );
  }
}
