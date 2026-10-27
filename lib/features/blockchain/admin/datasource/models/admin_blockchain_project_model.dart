import 'package:watad/core/enums/project_status.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_project.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_sync_status.dart';

class AdminBlockchainProjectModel extends AdminBlockchainProject {
  const AdminBlockchainProjectModel({
    required super.projectId,
    required super.title,
    required super.projectStatus,
    required super.syncStatus,
    required super.version,
    required super.attempts,
    super.ownerName,
    super.contractorName,
    super.lastAttemptAt,
    super.nextAttemptAt,
    super.syncedAt,
    super.lastMessage,
  });

  /// Maps the columns selected in AdminBlockchainRemoteDataSourceImpl.
  factory AdminBlockchainProjectModel.fromJson(Map<String, dynamic> json) {
    return AdminBlockchainProjectModel(
      projectId: json['project_id'] as String,
      title: json['project_title'] as String,
      projectStatus: ProjectStatus.fromJson(json['project_status'] as String),
      syncStatus: syncStatusFromJson(json['sync_status'] as String),
      version: json['version'] as int,
      attempts: json['attempts'] as int,
      ownerName: json['owner_name'] as String?,
      contractorName: json['contractor_name'] as String?,
      lastAttemptAt: _time(json['last_attempt_at']),
      nextAttemptAt: _time(json['next_attempt_at']),
      syncedAt: _time(json['synced_at']),
      lastMessage: json['last_message'] as String?,
    );
  }

  /// The view's `sync_status`. Throws on an unknown value: never guess a
  /// status.
  static AdminBlockchainSyncStatus syncStatusFromJson(String value) =>
      switch (value) {
        'failed' => AdminBlockchainSyncStatus.failed,
        'retrying' => AdminBlockchainSyncStatus.retrying,
        'waiting' => AdminBlockchainSyncStatus.waiting,
        'synced' => AdminBlockchainSyncStatus.synced,
        _ => throw FormatException('Unknown sync_status: $value'),
      };

  static DateTime? _time(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}
