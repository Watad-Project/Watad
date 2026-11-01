/// A page of the reviews about [userId], newest first, from [offset].
class ProfileReviewsQuery {
  const ProfileReviewsQuery({required this.userId, this.offset = 0});

  final String userId;
  final int offset;

  /// How many reviews a page holds.
  static const int pageSize = 10;
}
