import 'package:watad/features/profile/shared/domain/entities/profile_city_suggestion.dart';

class ProfileCitySuggestionModel extends ProfileCitySuggestion {
  const ProfileCitySuggestionModel({
    required super.placeId,
    required super.title,
    super.subtitle,
  });

  /// One of the `suggestions` of the `geocode` Edge Function's search:
  /// `{place_id, title, subtitle}`; the subtitle may be null.
  factory ProfileCitySuggestionModel.fromJson(Map<String, dynamic> json) {
    final subtitle = (json['subtitle'] as String?)?.trim();
    return ProfileCitySuggestionModel(
      placeId: json['place_id'] as String,
      title: (json['title'] as String).trim(),
      subtitle: subtitle == null || subtitle.isEmpty ? null : subtitle,
    );
  }
}
