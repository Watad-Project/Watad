import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_document.dart';
import 'package:watad/features/review/admin/domain/repositories/admin_review_repository.dart';

/// The files of one request; the parameter is the business id.
class AdminGetRequestDocumentsUseCase
    implements UseCase<List<AdminReviewDocument>, String> {
  const AdminGetRequestDocumentsUseCase(this._repository);

  final AdminReviewRepository _repository;

  @override
  Future<Result<List<AdminReviewDocument>>> call(String params) =>
      _repository.getDocuments(params);
}
