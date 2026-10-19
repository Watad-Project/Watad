import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/domain/repositories/admin_review_repository.dart';

class AdminGetPendingRequestsUseCase
    implements UseCase<List<AdminReviewRequest>, NoParams> {
  const AdminGetPendingRequestsUseCase(this._repository);

  final AdminReviewRepository _repository;

  @override
  Future<Result<List<AdminReviewRequest>>> call(NoParams params) =>
      _repository.getPendingRequests();
}
