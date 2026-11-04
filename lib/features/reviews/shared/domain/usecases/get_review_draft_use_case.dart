import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_draft.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_subject.dart';
import 'package:watad/features/reviews/shared/domain/repositories/reviews_repository.dart';

class GetReviewDraftUseCase implements UseCase<ReviewDraft, ReviewSubject> {
  const GetReviewDraftUseCase(this._repository);

  final ReviewsRepository _repository;

  @override
  Future<Result<ReviewDraft>> call(ReviewSubject subject) =>
      _repository.getDraft(subject);
}
