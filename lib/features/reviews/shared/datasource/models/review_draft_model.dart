import 'package:watad/features/reviews/shared/datasource/models/my_review_model.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_draft.dart';

class ReviewDraftModel extends ReviewDraft {
  const ReviewDraftModel({required super.targetName, super.existing});

  /// Maps the `v_public_profiles` row of whom I'm rating (`display_name`),
  /// with my `v_reviews` row under `my_review` (null when I have none),
  /// as ReviewsRemoteDataSourceImpl puts them together.
  factory ReviewDraftModel.fromJson(Map<String, dynamic> json) {
    final review = json['my_review'];
    return ReviewDraftModel(
      targetName: (json['display_name'] as String?)?.trim() ?? '',
      existing: review is Map
          ? MyReviewModel.fromJson(Map<String, dynamic>.from(review))
          : null,
    );
  }
}
