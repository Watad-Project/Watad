part of 'admin_review_bloc.dart';

sealed class AdminReviewEvent {
  const AdminReviewEvent();
}

/// Load the queue, at the start and on pull to refresh.
final class AdminReviewFetched extends AdminReviewEvent {
  const AdminReviewFetched();
}

final class AdminReviewFilterChanged extends AdminReviewEvent {
  const AdminReviewFilterChanged(this.filter);

  final AdminReviewFilter filter;
}

final class AdminReviewApproved extends AdminReviewEvent {
  const AdminReviewApproved(this.businessId);

  final String businessId;
}

final class AdminReviewRejected extends AdminReviewEvent {
  const AdminReviewRejected(this.rejection);

  final AdminReviewRejection rejection;
}
