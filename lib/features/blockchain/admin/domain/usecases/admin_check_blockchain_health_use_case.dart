import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health.dart';
import 'package:watad/features/blockchain/admin/domain/repositories/admin_blockchain_repository.dart';

class AdminCheckBlockchainHealthUseCase
    implements UseCase<AdminBlockchainHealth, NoParams> {
  const AdminCheckBlockchainHealthUseCase(this._repository);

  final AdminBlockchainRepository _repository;

  @override
  Future<Result<AdminBlockchainHealth>> call(NoParams params) =>
      _repository.checkHealth();
}
