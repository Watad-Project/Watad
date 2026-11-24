import 'package:watad/core/error/result.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_overview.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_project.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_uptime.dart';

abstract interface class AdminBlockchainRepository {
  /// The summary and every contracted project, in the view's order.
  Future<Result<AdminBlockchainOverview>> getOverview();

  /// One contracted project; NotFoundFailure when it isn't one.
  Future<Result<AdminBlockchainProject>> getProject(String projectId);

  /// The network's uptime over the last 24 hours, from the uptime monitor;
  /// NotFoundFailure for a user who isn't an admin.
  Future<Result<AdminBlockchainUptime>> getUptime();

  /// Asks the ledger whether it answers.
  Future<Result<AdminBlockchainHealth>> checkHealth();

  /// Marks [projectId] to sync again.
  Future<Result<void>> resync(String projectId);
}
