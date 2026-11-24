import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_uptime.dart';
import 'package:watad/features/blockchain/admin/domain/repositories/admin_blockchain_repository.dart';

/// The network's uptime over the last 24 hours (GRA-75).
class AdminGetBlockchainUptimeUseCase
    implements UseCase<AdminBlockchainUptime, NoParams> {
  const AdminGetBlockchainUptimeUseCase(this._repository);

  final AdminBlockchainRepository _repository;

  @override
  Future<Result<AdminBlockchainUptime>> call(NoParams params) =>
      _repository.getUptime();
}
