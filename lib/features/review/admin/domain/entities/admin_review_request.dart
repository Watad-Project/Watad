import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';

/// One request waiting for an admin, as the queue shows it: a pending license
/// (`v_admin_verification_queue`) or a deed under review
/// (`v_admin_deed_queue`).
class AdminReviewRequest {
  const AdminReviewRequest({
    required this.kind,
    required this.id,
    required this.requesterName,
    this.requesterAvatarUrl,
    this.requestedAt,
  });

  final AdminReviewKind kind;

  /// The business id for a license, the project id for a deed.
  final String id;

  /// Who asked: the company for a license, the client for a deed.
  final String requesterName;
  final String? requesterAvatarUrl;

  /// When the request was sent (UTC).
  final DateTime? requestedAt;

  AdminReviewTarget get target => AdminReviewTarget(kind: kind, id: id);
}
