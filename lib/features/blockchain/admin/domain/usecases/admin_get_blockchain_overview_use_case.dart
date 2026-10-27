import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_overview.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_project.dart';
import 'package:watad/features/blockchain/admin/domain/repositories/admin_blockchain_repository.dart';

/// The summary and the projects, those that need a person first: failed,
/// then retrying, then waiting, then synced; inside each, the latest
/// attempt first.
class AdminGetBlockchainOverviewUseCase
    implements UseCase<AdminBlockchainOverview, NoParams> {
  const AdminGetBlockchainOverviewUseCase(this._repository);

  final AdminBlockchainRepository _repository;

  @override
  Future<Result<AdminBlockchainOverview>> call(NoParams params) async {
    final result = await _repository.getOverview();
    return switch (result) {
      Success(:final data) => Success(
        AdminBlockchainOverview(
          summary: data.summary,
          projects: [...data.projects]..sort(_attentionFirst),
        ),
      ),
      Failed(:final failure) => Failed(failure),
    };
  }

  static int _attentionFirst(
    AdminBlockchainProject a,
    AdminBlockchainProject b,
  ) {
    final byStatus = a.syncStatus.index.compareTo(b.syncStatus.index);
    if (byStatus != 0) return byStatus;
    final aTime = a.lastAttemptAt;
    final bTime = b.lastAttemptAt;
    if (aTime == null || bTime == null) {
      // Never attempted goes last.
      return (aTime == null ? 1 : 0) - (bTime == null ? 1 : 0);
    }
    return bTime.compareTo(aTime);
  }
}
