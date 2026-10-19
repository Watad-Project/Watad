import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/review/admin/domain/repositories/admin_review_repository.dart';

/// Approves a license; the parameter is the business id.
class AdminApproveRequestUseCase implements UseCase<void, String> {
  const AdminApproveRequestUseCase(this._repository);

  final AdminReviewRepository _repository;

  @override
  Future<Result<void>> call(String params) => _repository.approve(params);
}
