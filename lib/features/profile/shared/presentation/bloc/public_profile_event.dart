part of 'public_profile_bloc.dart';

sealed class PublicProfileEvent {
  const PublicProfileEvent();
}

/// Load the profile of [userId]: when the page opens, on retry and pull
/// to refresh.
final class PublicProfileFetched extends PublicProfileEvent {
  const PublicProfileFetched(this.userId);

  final String userId;
}

/// «عرض المزيد» under the reviews.
final class PublicProfileMoreReviewsRequested extends PublicProfileEvent {
  const PublicProfileMoreReviewsRequested();
}
