import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_market_item.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_reviews_query.dart';
import 'package:watad/features/profile/shared/domain/entities/public_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/public_profile_overview.dart';
import 'package:watad/features/profile/shared/domain/repositories/profile_repository.dart';

/// What the public profile shows (GRA-58): the user, their items on the
/// market and the first page of reviews about them. Any part failing fails
/// the whole, so the screen never shows half a profile as if it were all.
class GetPublicProfileUseCase
    implements UseCase<PublicProfileOverview, String> {
  const GetPublicProfileUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<PublicProfileOverview>> call(String userId) async {
    final profileResult = await _repository.getPublicProfile(userId);
    if (profileResult case Failed(:final failure)) return Failed(failure);
    final itemsResult = await _repository.getMarketItems(userId);
    if (itemsResult case Failed(:final failure)) return Failed(failure);
    final profile = (profileResult as Success<PublicProfile>).data;
    final items = (itemsResult as Success<List<ProfileMarketItem>>).data;
    final query = ProfileReviewsQuery(userId: userId);
    return switch (await _repository.getReviews(query)) {
      Success(data: final reviews) => Success(
        PublicProfileOverview(
          profile: profile,
          items: items,
          reviews: reviews,
          hasMoreReviews: reviews.length == ProfileReviewsQuery.pageSize,
        ),
      ),
      Failed(:final failure) => Failed(failure),
    };
  }
}
