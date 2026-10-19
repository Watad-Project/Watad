import 'package:watad/core/error/result.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_details.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';

abstract interface class AdminReviewRepository {
  /// Pending licenses and deeds under review, oldest first.
  Future<Result<List<AdminReviewRequest>>> getPendingRequests();

  /// The request with its requester and files. A request another admin
  /// already decided is a NotFoundFailure.
  Future<Result<AdminReviewDetails>> getDetails(AdminReviewTarget target);

  /// Verifies the business, or the deed (which publishes its project).
  Future<Result<void>> approve(AdminReviewTarget target);

  /// Rejects with [note], which the requester reads.
  Future<Result<void>> reject(AdminReviewTarget target, String note);
}
