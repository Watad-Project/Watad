import 'package:watad/core/error/result.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_draft.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_input.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_subject.dart';

abstract interface class ReviewsRepository {
  /// The name of whom I'm rating and my review of [subject], if any.
  Future<Result<ReviewDraft>> getDraft(ReviewSubject subject);

  /// Inserts a new review, or updates my review `existingId`.
  Future<Result<void>> save(ReviewInput input);
}
