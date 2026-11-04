import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_draft.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_input.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_subject.dart';
import 'package:watad/features/reviews/shared/domain/repositories/reviews_repository.dart';
import 'package:watad/features/reviews/shared/reviews_injection.dart';

/// A hand-written [ReviewsRepository]: it answers with the results you set
/// and records every review saved (APP_ARCHITECTURE.md §16). By default,
/// nothing written yet about «مؤسسة البناء المتين».
class FakeReviewsRepository implements ReviewsRepository {
  Result<ReviewDraft> draftResult = const Success(
    ReviewDraft(targetName: 'مؤسسة البناء المتين'),
  );
  Result<void> saveResult = const Success(null);

  final List<ReviewSubject> drafts = [];
  final List<ReviewInput> saved = [];

  @override
  Future<Result<ReviewDraft>> getDraft(ReviewSubject subject) async {
    drafts.add(subject);
    return draftResult;
  }

  @override
  Future<Result<void>> save(ReviewInput input) async {
    saved.add(input);
    return saveResult;
  }
}

/// For tests that open the review sheet: the real registrations, with
/// [repository] in place of Supabase. Reset getIt after the test.
void registerFakeReviews([FakeReviewsRepository? repository]) {
  registerReviewsDependencies(getIt);
  getIt
    ..unregister<ReviewsRepository>()
    ..registerSingleton<ReviewsRepository>(
      repository ?? FakeReviewsRepository(),
    );
}
