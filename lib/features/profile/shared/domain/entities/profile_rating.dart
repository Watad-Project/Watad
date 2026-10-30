/// What others think of a user: the average of the reviews about them and
/// how many there are, from `v_public_profiles`.
class ProfileRating {
  const ProfileRating({required this.count, this.average});

  /// From 1 to 5; null while nobody has rated them ([count] is 0).
  final double? average;
  final int count;
}
