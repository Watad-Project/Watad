import 'package:watad/features/reviews/shared/domain/entities/my_review.dart';

class MyReviewModel extends MyReview {
  const MyReviewModel({
    required super.id,
    required super.rating,
    super.comment,
  });

  /// Maps the `v_reviews` columns selected in ReviewsRemoteDataSourceImpl.
  factory MyReviewModel.fromJson(Map<String, dynamic> json) {
    final comment = (json['comment'] as String?)?.trim();
    return MyReviewModel(
      id: json['id'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: comment == null || comment.isEmpty ? null : comment,
    );
  }
}
