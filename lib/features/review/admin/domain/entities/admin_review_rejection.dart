/// An admin's rejection of a license: the reason picked from the list and
/// the details written for the contractor.
class AdminReviewRejection {
  const AdminReviewRejection({
    required this.businessId,
    required this.details,
    this.reason,
  });

  final String businessId;

  /// The reason as the admin saw it in the list. Null for «أخرى»: the
  /// details alone explain it.
  final String? reason;
  final String details;
}
