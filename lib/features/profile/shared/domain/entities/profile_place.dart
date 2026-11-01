/// Where a suggested place is (GRA-60): its point, to ask `geocode` for the
/// city there.
class ProfilePlace {
  const ProfilePlace({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}
