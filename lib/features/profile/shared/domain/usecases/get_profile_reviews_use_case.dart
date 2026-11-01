import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_review.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_reviews_query.dart';
import 'package:watad/features/profile/shared/domain/repositories/profile_repository.dart';

/// The next page of reviews on the public profile (GRA-58).
class GetProfileReviewsUseCase
    implements UseCase<List<ProfileReview>, ProfileReviewsQuery> {
  const GetProfileReviewsUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<List<ProfileReview>>> call(ProfileReviewsQuery query) =>
      _repository.getReviews(query);
}
