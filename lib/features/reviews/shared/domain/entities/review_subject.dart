/// What a review is about: the other party of a completed project or a
/// delivered order.
class ReviewSubject {
  const ReviewSubject({
    required this.targetUserId,
    this.projectId,
    this.orderId,
  });

  final String targetUserId;

  /// Exactly one of [projectId] and [orderId] is set.
  final String? projectId;
  final String? orderId;

  bool get isProject => projectId != null;
}
