import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';
import 'package:watad/features/review/admin/domain/repositories/admin_review_repository.dart';

/// Approves a license or a deed.
class AdminApproveRequestUseCase implements UseCase<void, AdminReviewTarget> {
  const AdminApproveRequestUseCase(this._repository);

  final AdminReviewRepository _repository;

  @override
  Future<Result<void>> call(AdminReviewTarget params) =>
      _repository.approve(params);
}
