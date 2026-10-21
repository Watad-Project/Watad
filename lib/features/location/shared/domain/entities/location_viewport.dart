/// The area of the map that shows a whole place: wide for a city, narrow
/// for a street.
class LocationViewport {
  const LocationViewport({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;
}
