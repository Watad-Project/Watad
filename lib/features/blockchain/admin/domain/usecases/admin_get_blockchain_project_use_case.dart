import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_project.dart';
import 'package:watad/features/blockchain/admin/domain/repositories/admin_blockchain_repository.dart';

class AdminGetBlockchainProjectUseCase
    implements UseCase<AdminBlockchainProject, String> {
  const AdminGetBlockchainProjectUseCase(this._repository);

  final AdminBlockchainRepository _repository;

  @override
  Future<Result<AdminBlockchainProject>> call(String projectId) =>
      _repository.getProject(projectId);
}
