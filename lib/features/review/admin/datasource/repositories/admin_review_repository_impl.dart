import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/review/admin/datasource/remote/admin_review_remote_data_source.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_document.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/domain/repositories/admin_review_repository.dart';

class AdminReviewRepositoryImpl implements AdminReviewRepository {
  const AdminReviewRepositoryImpl(this._remote);

  final AdminReviewRemoteDataSource _remote;

  @override
  Future<Result<List<AdminReviewRequest>>> getPendingRequests() =>
      guardSupabaseCall(_remote.getPendingRequests);

  @override
  Future<Result<List<AdminReviewDocument>>> getDocuments(String businessId) =>
      guardSupabaseCall(() => _remote.getDocuments(businessId));

  @override
  Future<Result<void>> approve(String businessId) => guardSupabaseCall(
    () => _remote.setVerification(
      businessId: businessId,
      status: VerificationStatus.verified,
    ),
  );

  @override
  Future<Result<void>> reject(String businessId, String note) =>
      guardSupabaseCall(
        () => _remote.setVerification(
          businessId: businessId,
          status: VerificationStatus.rejected,
          note: note,
        ),
      );
}
