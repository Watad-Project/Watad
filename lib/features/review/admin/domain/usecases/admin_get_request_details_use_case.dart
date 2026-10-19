import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_details.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';
import 'package:watad/features/review/admin/domain/repositories/admin_review_repository.dart';

/// One request with its requester and files.
class AdminGetRequestDetailsUseCase
    implements UseCase<AdminReviewDetails, AdminReviewTarget> {
  const AdminGetRequestDetailsUseCase(this._repository);

  final AdminReviewRepository _repository;

  @override
  Future<Result<AdminReviewDetails>> call(AdminReviewTarget params) =>
      _repository.getDetails(params);
}
