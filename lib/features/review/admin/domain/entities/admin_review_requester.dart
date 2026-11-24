/// The person behind a request, as the admin sees them on its details.
class AdminReviewRequester {
  const AdminReviewRequester({
    required this.name,
    this.userId,
    this.avatarUrl,
    this.memberSince,
    this.nationalId,
  });

  final String name;

  /// Opens their public profile (GRA-58).
  final String? userId;
  final String? avatarUrl;

  /// When their account was created (UTC).
  final DateTime? memberSince;

  /// Their ID/iqama number, to match against the documents. Null when they
  /// never gave one (contractors don't at sign-up). Personal data: never
  /// log it.
  final String? nationalId;
}
