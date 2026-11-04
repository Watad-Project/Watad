import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_input.dart';
import 'package:watad/features/reviews/shared/domain/repositories/reviews_repository.dart';

/// Saves a review after the database's own rules: 1 to 5 stars, and a
/// comment, trimmed, of up to 2000 characters.
class SaveReviewUseCase implements UseCase<void, ReviewInput> {
  const SaveReviewUseCase(this._repository);

  final ReviewsRepository _repository;

  @override
  Future<Result<void>> call(ReviewInput input) {
    if (input.rating < ReviewInput.minRating ||
        input.rating > ReviewInput.maxRating) {
      return Future.value(
        const Failed(ValidationFailure('reviews.error_rating')),
      );
    }
    final comment = input.comment.trim();
    if (comment.length > ReviewInput.maxCommentLength) {
      return Future.value(
        const Failed(ValidationFailure('reviews.error_comment_long')),
      );
    }
    return _repository.save(
      ReviewInput(
        subject: input.subject,
        rating: input.rating,
        comment: comment,
        existingId: input.existingId,
      ),
    );
  }
}
