import 'package:watad/features/review/admin/domain/entities/admin_review_requester.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';

/// What the admin checks before deciding on a request: an
/// [AdminLicenseDetails] or an [AdminDeedDetails].
abstract class AdminReviewDetails {
  const AdminReviewDetails({
    required this.target,
    required this.requester,
    this.requestedAt,
  });

  final AdminReviewTarget target;

  /// Who asked for the verification.
  final AdminReviewRequester requester;

  /// When the request was sent (UTC).
  final DateTime? requestedAt;
}
