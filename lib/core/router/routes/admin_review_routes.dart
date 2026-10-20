/// The routes of lib/features/review/admin/. Any feature navigates to them
/// with these names (APP_ARCHITECTURE.md §11).
abstract final class AdminReviewRoutes {
  static const String reviewName = 'admin-review';
  static const String reviewPath = '/admin/review';

  /// One request: `kind` is `license` (the id is the business's) or `deed`
  /// (the id is the project's).
  static const String reviewDetailsName = 'admin-review-details';
  static const String reviewDetailsPath = '/admin/review/:kind/:id';
}
