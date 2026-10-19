/// An admin's rejection of a license: the reason picked from the list and
/// the details written for the contractor.
class AdminReviewRejection {
  const AdminReviewRejection({
    required this.businessId,
    required this.reason,
    required this.details,
  });

  final String businessId;

  /// The reason as the admin saw it in the list.
  final String reason;
  final String details;
}
