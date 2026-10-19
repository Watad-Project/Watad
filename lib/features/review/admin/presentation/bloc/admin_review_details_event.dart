part of 'admin_review_details_bloc.dart';

sealed class AdminReviewDetailsEvent {
  const AdminReviewDetailsEvent();
}

/// Load the request, when the page opens and on «حاول مرة أخرى».
final class AdminReviewDetailsFetched extends AdminReviewDetailsEvent {
  const AdminReviewDetailsFetched(this.target);

  final AdminReviewTarget target;
}

final class AdminReviewDetailsApproved extends AdminReviewDetailsEvent {
  const AdminReviewDetailsApproved();
}

/// Reject with a [reason] from the list, or for «أخرى» (no reason) the
/// [details] alone.
final class AdminReviewDetailsRejected extends AdminReviewDetailsEvent {
  const AdminReviewDetailsRejected({required this.details, this.reason});

  final String? reason;
  final String details;
}
