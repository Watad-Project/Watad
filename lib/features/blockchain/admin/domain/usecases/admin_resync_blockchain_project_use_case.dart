import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/blockchain/admin/domain/repositories/admin_blockchain_repository.dart';

/// «إعادة المزامنة الآن»: marks one project to sync again.
class AdminResyncBlockchainProjectUseCase implements UseCase<void, String> {
  const AdminResyncBlockchainProjectUseCase(this._repository);

  final AdminBlockchainRepository _repository;

  @override
  Future<Result<void>> call(String projectId) => _repository.resync(projectId);
}
