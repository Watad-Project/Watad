/// The routes of lib/features/reviews/shared/. Any feature navigates to
/// them with these names (APP_ARCHITECTURE.md §11).
abstract final class ReviewsRoutes {
  /// The review sheet, over the screen it opens from. Query parameters:
  /// `user` (whom I'm rating) and either `project` or `order`. It pops
  /// `true` once the review is saved.
  static const String writeReviewName = 'write-review';
  static const String writeReviewPath = '/reviews/write';
}
