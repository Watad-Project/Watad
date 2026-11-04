import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_input.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_subject.dart';
import 'package:watad/features/reviews/shared/domain/usecases/save_review_use_case.dart';

import '../../../../../helpers/fake_reviews_repository.dart';

const _subject = ReviewSubject(targetUserId: 'u-2', orderId: 'o-1');

void main() {
  test('saves the review with its comment trimmed', () async {
    final repository = FakeReviewsRepository();

    final result = await SaveReviewUseCase(repository)(
      const ReviewInput(subject: _subject, rating: 5, comment: '  ممتاز  '),
    );

    expect(result, isA<Success<void>>());
    expect(repository.saved.single.comment, 'ممتاز');
    expect(repository.saved.single.subject.orderId, 'o-1');
  });

  test('no stars is refused before saving', () async {
    final repository = FakeReviewsRepository();

    final result = await SaveReviewUseCase(repository)(
      const ReviewInput(subject: _subject, rating: 0),
    );

    expect((result as Failed).failure.messageKey, 'reviews.error_rating');
    expect(repository.saved, isEmpty);
  });

  test('a comment over 2000 characters is refused before saving', () async {
    final repository = FakeReviewsRepository();

    final result = await SaveReviewUseCase(repository)(
      ReviewInput(subject: _subject, rating: 4, comment: 'a' * 2001),
    );

    expect((result as Failed).failure.messageKey, 'reviews.error_comment_long');
    expect(repository.saved, isEmpty);
  });
}
