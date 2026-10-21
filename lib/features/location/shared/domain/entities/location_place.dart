import 'package:watad/features/location/shared/domain/entities/location_viewport.dart';

/// Where a suggested place is, to move the map there.
class LocationPlace {
  const LocationPlace({
    required this.latitude,
    required this.longitude,
    this.viewport,
  });

  final double latitude;
  final double longitude;

  /// The area to show; null shows the point close up.
  final LocationViewport? viewport;
}
