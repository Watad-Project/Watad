import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/profile/shared/datasource/models/profile_review_model.dart';

void main() {
  test('fromJson maps a v_reviews row about a project', () {
    final review = ProfileReviewModel.fromJson(const {
      'id': 'r-1',
      'reviewer_name': 'سارة العتيبي',
      'reviewer_avatar_path': null,
      'reviewer_avatar_url': null,
      'rating': 4,
      'comment': ' عمل متقن ',
      'context_type': 'project',
      'created_at': '2026-10-28T12:00:00+00:00',
    });

    expect(review.reviewerName, 'سارة العتيبي');
    expect(review.reviewerAvatarUrl, isNull);
    expect(review.rating, 4);
    expect(review.comment, 'عمل متقن');
    expect(review.isFromProject, isTrue);
    expect(review.createdAt, DateTime.utc(2026, 10, 28, 12));
  });

  test('a review about an order, without a comment', () {
    final review = ProfileReviewModel.fromJson(const {
      'id': 'r-2',
      'reviewer_name': 'خالد',
      'rating': 5,
      'comment': '  ',
      'context_type': 'order',
      'created_at': '2026-10-20T12:00:00+00:00',
    });

    expect(review.comment, isNull);
    expect(review.isFromProject, isFalse);
  });
}
