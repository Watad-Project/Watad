import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_rejection.dart';
import 'package:watad/features/review/admin/domain/repositories/admin_review_repository.dart';

/// Rejects a license or a deed. The requester reads the note: a reason from the list
/// (with the details, if any), or with «أخرى» (no reason) the details alone,
/// which are then required.
class AdminRejectRequestUseCase implements UseCase<void, AdminReviewRejection> {
  const AdminRejectRequestUseCase(this._repository);

  final AdminReviewRepository _repository;

  @override
  Future<Result<void>> call(AdminReviewRejection params) async {
    final reason = params.reason?.trim() ?? '';
    final details = params.details.trim();
    if (reason.isEmpty && details.isEmpty) {
      return const Failed(ValidationFailure('common.reason_required'));
    }
    final note = switch ((reason.isEmpty, details.isEmpty)) {
      (true, _) => details,
      (_, true) => reason,
      _ => '$reason: $details',
    };
    return _repository.reject(params.target, note);
  }
}
