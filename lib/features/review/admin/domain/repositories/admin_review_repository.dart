import 'package:watad/core/error/result.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_document.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';

abstract interface class AdminReviewRepository {
  /// Pending license requests, oldest first.
  Future<Result<List<AdminReviewRequest>>> getPendingRequests();

  Future<Result<List<AdminReviewDocument>>> getDocuments(String businessId);

  Future<Result<void>> approve(String businessId);

  /// Rejects with [note], which the contractor reads.
  Future<Result<void>> reject(String businessId, String note);
}
