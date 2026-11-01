import 'package:watad/features/profile/shared/domain/entities/profile_market_item.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_review.dart';
import 'package:watad/features/profile/shared/domain/entities/public_profile.dart';

/// Everything the public profile shows (GRA-58): the header, the user's
/// items on the market, and the first page of the reviews about them.
class PublicProfileOverview {
  const PublicProfileOverview({
    required this.profile,
    required this.items,
    required this.reviews,
    required this.hasMoreReviews,
  });

  final PublicProfile profile;
  final List<ProfileMarketItem> items;
  final List<ProfileReview> reviews;

  /// Another page of reviews may follow.
  final bool hasMoreReviews;

  PublicProfileOverview withMoreReviews(
    List<ProfileReview> more, {
    required bool hasMore,
  }) => PublicProfileOverview(
    profile: profile,
    items: items,
    reviews: [...reviews, ...more],
    hasMoreReviews: hasMore,
  );
}
