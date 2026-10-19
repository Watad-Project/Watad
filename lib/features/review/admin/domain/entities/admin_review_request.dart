/// A business waiting for its license to be reviewed: a
/// `v_admin_verification_queue` row with `verification_status = 'pending'`.
class AdminReviewRequest {
  const AdminReviewRequest({
    required this.businessId,
    required this.companyName,
    required this.documentCount,
    this.ownerName,
    this.requestedAt,
  });

  final String businessId;
  final String companyName;
  final int documentCount;
  final String? ownerName;

  /// When the business asked for verification (UTC).
  final DateTime? requestedAt;
}
