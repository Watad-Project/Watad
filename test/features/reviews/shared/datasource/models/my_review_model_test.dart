import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/reviews/shared/datasource/models/my_review_model.dart';

void main() {
  test('fromJson maps my v_reviews row', () {
    final review = MyReviewModel.fromJson(const {
      'id': '8a7b6c5d-0000-4000-8000-000000000001',
      'rating': 4,
      'comment': ' التزام بالمواعيد ',
    });

    expect(review.id, '8a7b6c5d-0000-4000-8000-000000000001');
    expect(review.rating, 4);
    expect(review.comment, 'التزام بالمواعيد');
  });

  test('an empty comment is no comment', () {
    final review = MyReviewModel.fromJson(const {
      'id': 'r-1',
      'rating': 5,
      'comment': '   ',
    });

    expect(review.comment, isNull);
  });
}
