import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_project.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_sync_status.dart';

/// The chips above the projects, in their order.
enum AdminBlockchainFilter {
  all(null),
  failed(AdminBlockchainSyncStatus.failed),
  retrying(AdminBlockchainSyncStatus.retrying),
  waiting(AdminBlockchainSyncStatus.waiting),
  synced(AdminBlockchainSyncStatus.synced);

  const AdminBlockchainFilter(this.status);

  /// The status this chip shows; null shows every project.
  final AdminBlockchainSyncStatus? status;

  bool matches(AdminBlockchainProject project) =>
      status == null || project.syncStatus == status;
}
