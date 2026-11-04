import 'package:watad/features/reviews/shared/domain/entities/my_review.dart';

/// What the review sheet opens with: whom I'm rating, and my review if I
/// already wrote one (it's then edited).
class ReviewDraft {
  const ReviewDraft({required this.targetName, this.existing});

  final String targetName;
  final MyReview? existing;
}
