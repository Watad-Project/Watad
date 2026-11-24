import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_uptime.dart';

class AdminBlockchainUptimeModel extends AdminBlockchainUptime {
  const AdminBlockchainUptimeModel({
    required super.checks,
    required super.healthy,
    required super.isMonitorRunning,
    super.uptimePercent,
    super.lastCheckAt,
    super.lastCheckOk,
  });

  /// Maps the `v_admin_blockchain_uptime` columns selected in
  /// AdminBlockchainRemoteDataSourceImpl.
  factory AdminBlockchainUptimeModel.fromJson(Map<String, dynamic> json) {
    final lastCheckAt = json['last_check_at'] as String?;
    return AdminBlockchainUptimeModel(
      checks: json['checks_24h'] as int? ?? 0,
      healthy: json['healthy_24h'] as int? ?? 0,
      uptimePercent: (json['uptime_pct_24h'] as num?)?.toDouble(),
      lastCheckAt: lastCheckAt == null ? null : DateTime.parse(lastCheckAt),
      lastCheckOk: json['last_check_ok'] as bool?,
      isMonitorRunning: json['monitor_running'] as bool? ?? false,
    );
  }
}
