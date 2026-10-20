import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/review/admin/datasource/remote/admin_review_remote_data_source.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_details.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';
import 'package:watad/features/review/admin/domain/repositories/admin_review_repository.dart';

class AdminReviewRepositoryImpl implements AdminReviewRepository {
  const AdminReviewRepositoryImpl(this._remote);

  final AdminReviewRemoteDataSource _remote;

  @override
  Future<Result<List<AdminReviewRequest>>> getPendingRequests() =>
      guardSupabaseCall(() async {
        final lists = await Future.wait([
          _remote.getPendingLicenses(),
          _remote.getPendingDeeds(),
        ]);
        return [...lists.first, ...lists.last]..sort(_oldestFirst);
      });

  @override
  Future<Result<AdminReviewDetails>> getDetails(AdminReviewTarget target) =>
      guardSupabaseCall(
        () => switch (target.kind) {
          AdminReviewKind.license => _remote.getLicenseDetails(target.id),
          AdminReviewKind.deed => _remote.getDeedDetails(target.id),
        },
      );

  @override
  Future<Result<void>> approve(AdminReviewTarget target) => guardSupabaseCall(
    () => switch (target.kind) {
      AdminReviewKind.license => _remote.setLicenseVerification(
        businessId: target.id,
        status: VerificationStatus.verified,
      ),
      AdminReviewKind.deed => _remote.setDeedVerification(
        projectId: target.id,
        verified: true,
      ),
    },
  );

  @override
  Future<Result<void>> reject(AdminReviewTarget target, String note) =>
      guardSupabaseCall(
        () => switch (target.kind) {
          AdminReviewKind.license => _remote.setLicenseVerification(
            businessId: target.id,
            status: VerificationStatus.rejected,
            note: note,
          ),
          AdminReviewKind.deed => _remote.setDeedVerification(
            projectId: target.id,
            verified: false,
            reason: note,
          ),
        },
      );

  /// Oldest first across both kinds; a request without a date goes last.
  static int _oldestFirst(AdminReviewRequest a, AdminReviewRequest b) {
    final first = a.requestedAt;
    final second = b.requestedAt;
    if (first == null) return second == null ? 0 : 1;
    if (second == null) return -1;
    return first.compareTo(second);
  }
}
