/// An admin's rejection of a license: the reason picked from the list, or
/// for «أخرى» the details the admin wrote for the contractor.
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

  /// Empty for a reason from the list.
  final String details;
}
