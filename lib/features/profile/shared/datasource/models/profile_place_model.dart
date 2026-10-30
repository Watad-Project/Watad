import 'package:watad/features/profile/shared/domain/entities/profile_place.dart';

class ProfilePlaceModel extends ProfilePlace {
  const ProfilePlaceModel({required super.latitude, required super.longitude});

  /// The `geocode` Edge Function's answer for a `place_id`:
  /// `{lat, lng, viewport}`. Only the point is used.
  factory ProfilePlaceModel.fromJson(Map<String, dynamic> json) =>
      ProfilePlaceModel(
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lng'] as num).toDouble(),
      );
}
