import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';

/// The request a decision is about.
class AdminReviewTarget {
  const AdminReviewTarget({required this.kind, required this.id});

  final AdminReviewKind kind;

  /// The business id for a license, the project id for a deed.
  final String id;

  @override
  bool operator ==(Object other) =>
      other is AdminReviewTarget && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}
