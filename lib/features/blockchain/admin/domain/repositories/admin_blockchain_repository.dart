import 'package:watad/core/error/result.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_overview.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_project.dart';

abstract interface class AdminBlockchainRepository {
  /// The summary and every contracted project, in the view's order.
  Future<Result<AdminBlockchainOverview>> getOverview();

  /// One contracted project; NotFoundFailure when it isn't one.
  Future<Result<AdminBlockchainProject>> getProject(String projectId);

  /// Asks the ledger whether it answers.
  Future<Result<AdminBlockchainHealth>> checkHealth();

  /// Marks [projectId] to sync again.
  Future<Result<void>> resync(String projectId);
}
