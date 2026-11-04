import 'package:watad/features/reviews/shared/domain/entities/review_subject.dart';

/// A review to save: a new one, or my review [existingId] edited.
class ReviewInput {
  const ReviewInput({
    required this.subject,
    required this.rating,
    this.comment = '',
    this.existingId,
  });

  final ReviewSubject subject;
  final int rating;
  final String comment;
  final String? existingId;

  /// The database's rules: 1 to 5 stars, a comment of up to 2000
  /// characters.
  static const int minRating = 1;
  static const int maxRating = 5;
  static const int maxCommentLength = 2000;
}
