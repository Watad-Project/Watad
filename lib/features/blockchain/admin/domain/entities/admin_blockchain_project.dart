import 'package:watad/core/enums/project_status.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_sync_status.dart';

/// One contracted project's blockchain sync: a `v_admin_blockchain_sync`
/// row.
class AdminBlockchainProject {
  const AdminBlockchainProject({
    required this.projectId,
    required this.title,
    required this.projectStatus,
    required this.syncStatus,
    required this.version,
    required this.attempts,
    this.ownerName,
    this.contractorName,
    this.lastAttemptAt,
    this.nextAttemptAt,
    this.syncedAt,
    this.lastMessage,
  });

  final String projectId;
  final String title;
  final ProjectStatus projectStatus;
  final AdminBlockchainSyncStatus syncStatus;

  /// Goes up with every change that needs copying.
  final int version;

  /// Failed attempts since the last success or change.
  final int attempts;

  /// The client; null when they have no name.
  final String? ownerName;

  /// The contractor's company.
  final String? contractorName;

  final DateTime? lastAttemptAt;

  /// Only while something waits.
  final DateTime? nextAttemptAt;

  /// The last successful sync.
  final DateTime? syncedAt;

  /// What the last run said, e.g. «applied: project created» or the error.
  final String? lastMessage;
}
