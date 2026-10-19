import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/review/admin/admin_review_injection.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_details.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';
import 'package:watad/features/review/admin/domain/repositories/admin_review_repository.dart';

/// A hand-written [AdminReviewRepository]: it answers with the results you
/// set and records every decision (APP_ARCHITECTURE.md §16).
class FakeAdminReviewRepository implements AdminReviewRepository {
  Result<List<AdminReviewRequest>> requestsResult = const Success([]);

  /// The details of each request; a request not in here is not found.
  final Map<AdminReviewTarget, AdminReviewDetails> details = {};
  Result<void> decisionResult = const Success(null);

  /// The requests approved.
  final List<AdminReviewTarget> approved = [];

  /// The requests rejected, as (target, note).
  final List<(AdminReviewTarget, String)> rejected = [];

  @override
  Future<Result<List<AdminReviewRequest>>> getPendingRequests() async =>
      requestsResult;

  @override
  Future<Result<AdminReviewDetails>> getDetails(
    AdminReviewTarget target,
  ) async {
    final found = details[target];
    return found == null ? const Failed(NotFoundFailure()) : Success(found);
  }

  @override
  Future<Result<void>> approve(AdminReviewTarget target) async {
    approved.add(target);
    return decisionResult;
  }

  @override
  Future<Result<void>> reject(AdminReviewTarget target, String note) async {
    rejected.add((target, note));
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
