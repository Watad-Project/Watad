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

/// The admin decided on [target] from its details.
final class AdminReviewDecided extends AdminReviewEvent {
  const AdminReviewDecided(this.target);

  final AdminReviewTarget target;
}
