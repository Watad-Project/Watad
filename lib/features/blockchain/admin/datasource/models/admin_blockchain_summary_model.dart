import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_job_result.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_summary.dart';

class AdminBlockchainSummaryModel extends AdminBlockchainSummary {
  const AdminBlockchainSummaryModel({
    required super.projects,
    required super.synced,
    required super.waiting,
    required super.retrying,
    required super.failed,
    super.lastSyncedAt,
    super.retryJobActive,
    super.retryJobLastRunAt,
    super.retryJobLastResult,
  });

  /// Maps the columns selected in AdminBlockchainRemoteDataSourceImpl.
  factory AdminBlockchainSummaryModel.fromJson(Map<String, dynamic> json) {
    final lastSyncedAt = json['last_synced_at'] as String?;
    final lastRunAt = json['retry_job_last_run_at'] as String?;
    final lastStatus = json['retry_job_last_status'] as String?;
    return AdminBlockchainSummaryModel(
      projects: json['projects'] as int,
      synced: json['synced'] as int,
      waiting: json['waiting'] as int,
      retrying: json['retrying'] as int,
      failed: json['failed'] as int,
      lastSyncedAt: lastSyncedAt == null ? null : DateTime.parse(lastSyncedAt),
      retryJobActive: json['retry_job_active'] as bool?,
      retryJobLastRunAt: lastRunAt == null ? null : DateTime.parse(lastRunAt),
      retryJobLastResult: lastStatus == null ? null : _result(lastStatus),
    );
  }

  /// pg_cron's status of a run: `succeeded`, `failed`, or one of the
  /// steps of a run still going (`starting`, `running`, `sending`,
  /// `connecting`).
  static AdminBlockchainJobResult _result(String status) => switch (status) {
    'succeeded' => AdminBlockchainJobResult.succeeded,
    'failed' => AdminBlockchainJobResult.failed,
    _ => AdminBlockchainJobResult.running,
  };
}
