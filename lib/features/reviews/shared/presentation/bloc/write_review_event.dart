part of 'write_review_bloc.dart';

sealed class WriteReviewEvent {
  const WriteReviewEvent();
}

/// The sheet opened, or «إعادة المحاولة».
final class WriteReviewStarted extends WriteReviewEvent {
  const WriteReviewStarted(this.subject);

  final ReviewSubject subject;
}

/// «حفظ التقييم».
final class WriteReviewSubmitted extends WriteReviewEvent {
  const WriteReviewSubmitted({required this.rating, required this.comment});

  final int rating;
  final String comment;
}
