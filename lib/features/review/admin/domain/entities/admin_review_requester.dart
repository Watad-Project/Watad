/// The person behind a request, as the admin sees them on its details.
class AdminReviewRequester {
  const AdminReviewRequester({
    required this.name,
    this.avatarUrl,
    this.memberSince,
  });

  final String name;
  final String? avatarUrl;

  /// When their account was created (UTC).
  final DateTime? memberSince;
}
