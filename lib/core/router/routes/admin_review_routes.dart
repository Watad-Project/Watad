/// The routes of lib/features/review/admin/. Any feature navigates to them
/// with these names (APP_ARCHITECTURE.md §11).
abstract final class AdminReviewRoutes {
  static const String reviewName = 'admin-review';
  static const String reviewPath = '/admin/review';

  static const String reviewDocumentsName = 'admin-review-documents';
  static const String reviewDocumentsPath = '/admin/review/:businessId';
}
