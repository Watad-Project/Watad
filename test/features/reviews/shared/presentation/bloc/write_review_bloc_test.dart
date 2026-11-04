import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/reviews/shared/domain/entities/my_review.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_draft.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_subject.dart';
import 'package:watad/features/reviews/shared/domain/usecases/get_review_draft_use_case.dart';
import 'package:watad/features/reviews/shared/domain/usecases/save_review_use_case.dart';
import 'package:watad/features/reviews/shared/presentation/bloc/write_review_bloc.dart';

import '../../../../../helpers/fake_reviews_repository.dart';

const _subject = ReviewSubject(targetUserId: 'u-2', projectId: 'p-1');

WriteReviewBloc _bloc(FakeReviewsRepository repository) => WriteReviewBloc(
  GetReviewDraftUseCase(repository),
  SaveReviewUseCase(repository),
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('loads whom I rate, then saves a new review', () async {
    final repository = FakeReviewsRepository();
    final bloc = _bloc(repository)..add(const WriteReviewStarted(_subject));
    await _settle();
    expect(bloc.state.status, WriteReviewStatus.ready);

    bloc.add(const WriteReviewSubmitted(rating: 5, comment: 'عمل متقن'));
    await _settle();

    expect(bloc.state.status, WriteReviewStatus.saved);
    final saved = repository.saved.single;
    expect(saved.existingId, isNull);
    expect(saved.subject.projectId, 'p-1');
    await bloc.close();
  });

  test('my earlier review is edited, not added again', () async {
    final repository = FakeReviewsRepository()
      ..draftResult = const Success(
        ReviewDraft(
          targetName: 'سارة',
          existing: MyReview(id: 'r-9', rating: 2),
        ),
      );
    final bloc = _bloc(repository)..add(const WriteReviewStarted(_subject));
    await _settle();

    bloc.add(const WriteReviewSubmitted(rating: 4, comment: ''));
    await _settle();

    expect(repository.saved.single.existingId, 'r-9');
    await bloc.close();
  });

  test('a sheet that fails to load says why', () async {
    final repository = FakeReviewsRepository()
      ..draftResult = const Failed(NetworkFailure());
    final bloc = _bloc(repository)..add(const WriteReviewStarted(_subject));
    await _settle();

    expect(bloc.state.status, WriteReviewStatus.failure);
    expect(bloc.state.failure, isA<NetworkFailure>());
    await bloc.close();
  });

  test('a refused save keeps the form and says why', () async {
    final repository = FakeReviewsRepository()
      ..saveResult = const Failed(PermissionFailure());
    final bloc = _bloc(repository)..add(const WriteReviewStarted(_subject));
    await _settle();

    bloc.add(const WriteReviewSubmitted(rating: 3, comment: ''));
    await _settle();

    expect(bloc.state.status, WriteReviewStatus.ready);
    expect(bloc.state.saveFailure, isA<PermissionFailure>());
    expect(bloc.state.isSaving, isFalse);
    await bloc.close();
  });
}
