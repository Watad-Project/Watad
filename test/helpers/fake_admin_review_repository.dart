import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/review/admin/admin_review_injection.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_document.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/domain/repositories/admin_review_repository.dart';

/// A hand-written [AdminReviewRepository]: it answers with the results you
/// set and records every decision (APP_ARCHITECTURE.md §16).
class FakeAdminReviewRepository implements AdminReviewRepository {
  Result<List<AdminReviewRequest>> requestsResult = const Success([]);
  Result<List<AdminReviewDocument>> documentsResult = const Success([]);
  Result<void> decisionResult = const Success(null);

  /// The businesses approved.
  final List<String> approved = [];

  /// The businesses rejected, as (businessId, note).
  final List<(String, String)> rejected = [];

  @override
  Future<Result<List<AdminReviewRequest>>> getPendingRequests() async =>
      requestsResult;

  @override
  Future<Result<List<AdminReviewDocument>>> getDocuments(
    String businessId,
  ) async => documentsResult;

  @override
  Future<Result<void>> approve(String businessId) async {
    approved.add(businessId);
    return decisionResult;
  }

  @override
  Future<Result<void>> reject(String businessId, String note) async {
    rejected.add((businessId, note));
    return decisionResult;
  }
}

/// For tests that open the admin's navigation (its «التوثيق» tab) or the
/// review routes: the real registrations, with [repository] in place of
/// Supabase. Reset getIt after the test.
void registerFakeAdminReview(FakeAdminReviewRepository repository) {
  registerAdminReviewDependencies(getIt);
  getIt
    ..unregister<AdminReviewRepository>()
    ..registerSingleton<AdminReviewRepository>(repository);
}
