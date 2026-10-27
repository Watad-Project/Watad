import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_job_result.dart';

/// The contracted projects per sync status, the last successful sync and
/// the retry job: the `v_admin_blockchain_summary` row.
class AdminBlockchainSummary {
  const AdminBlockchainSummary({
    required this.projects,
    required this.synced,
    required this.waiting,
    required this.retrying,
    required this.failed,
    this.lastSyncedAt,
    this.retryJobActive,
    this.retryJobLastRunAt,
    this.retryJobLastResult,
  });

  /// Every contracted project, and how many are in each sync status.
  final int projects;
  final int synced;
  final int waiting;
  final int retrying;
  final int failed;

  /// The last successful sync of any project; null when none ever was.
  final DateTime? lastSyncedAt;

  /// Whether the retry job is scheduled; null when it doesn't exist.
  final bool? retryJobActive;

  /// Its last run; null when it never ran.
  final DateTime? retryJobLastRunAt;
  final AdminBlockchainJobResult? retryJobLastResult;
}
