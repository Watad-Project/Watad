import 'package:watad/features/location/shared/domain/entities/location_place.dart';
import 'package:watad/features/location/shared/domain/entities/location_viewport.dart';

/// Where a place is, from the `geocode` Edge Function's place request.
class LocationPlaceModel extends LocationPlace {
  const LocationPlaceModel({
    required super.latitude,
    required super.longitude,
    super.viewport,
  });

  /// From `{lat, lng, viewport: {south, west, north, east} | null}`.
  factory LocationPlaceModel.fromJson(Map<String, dynamic> json) {
    final area = json['viewport'];
    return LocationPlaceModel(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      viewport: area is Map<String, dynamic>
          ? LocationViewport(
              south: (area['south'] as num).toDouble(),
              west: (area['west'] as num).toDouble(),
              north: (area['north'] as num).toDouble(),
              east: (area['east'] as num).toDouble(),
            )
          : null,
    );
  }
}
