/// A review about a user (GRA-58): a `v_reviews` row.
class ProfileReview {
  const ProfileReview({
    required this.id,
    required this.reviewerName,
    this.reviewerId,
    required this.rating,
    required this.isFromProject,
    required this.createdAt,
    this.reviewerAvatarUrl,
    this.comment,
  });

  final String id;
  final String reviewerName;

  /// Opens their public profile; null for an account closed since.
  final String? reviewerId;
  final String? reviewerAvatarUrl;

  /// From 1 to 5.
  final int rating;
  final String? comment;

  /// About a project (`context_type` `project`), or else an order.
  final bool isFromProject;
  final DateTime createdAt;
}
