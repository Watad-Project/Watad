import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_rejection.dart';
import 'package:watad/features/review/admin/domain/repositories/admin_review_repository.dart';

/// Rejects a license. The contractor reads the note: the reason, then the
/// details. The details are always required; with «أخرى» (no reason) they
/// are the whole note.
class AdminRejectRequestUseCase implements UseCase<void, AdminReviewRejection> {
  const AdminRejectRequestUseCase(this._repository);

  final AdminReviewRepository _repository;

  @override
  Future<Result<void>> call(AdminReviewRejection params) async {
    final reason = params.reason?.trim() ?? '';
    final details = params.details.trim();
    if (details.isEmpty) {
      return const Failed(ValidationFailure('common.reason_required'));
    }
    final note = reason.isEmpty ? details : '$reason: $details';
    return _repository.reject(params.businessId, note);
  }
}
