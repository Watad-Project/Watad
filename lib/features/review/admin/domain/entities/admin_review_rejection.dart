import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';

/// An admin's rejection of a request: the reason picked from the list, or
/// for «أخرى» the details the admin wrote for the requester.
class AdminReviewRejection {
  const AdminReviewRejection({
    required this.target,
    required this.details,
    this.reason,
  });

  final AdminReviewTarget target;

  /// The reason as the admin saw it in the list. Null for «أخرى»: the
  /// details alone explain it.
  final String? reason;

  /// Empty for a reason from the list.
  final String details;
}
