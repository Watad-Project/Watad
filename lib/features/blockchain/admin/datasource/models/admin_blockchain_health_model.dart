import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health_problem.dart';

class AdminBlockchainHealthModel extends AdminBlockchainHealth {
  const AdminBlockchainHealthModel({
    required super.isReachable,
    required super.checkedAt,
    super.httpStatus,
    super.latency,
    super.problem,
  });

  /// Maps the answer of the `blockchain-health` Edge Function
  /// (ARCHITECTURE.md §6).
  factory AdminBlockchainHealthModel.fromJson(Map<String, dynamic> json) {
    final latencyMs = json['latency_ms'] as int?;
    final error = json['error'] as String?;
    return AdminBlockchainHealthModel(
      isReachable: json['reachable'] as bool,
      checkedAt: DateTime.parse(json['checked_at'] as String),
      httpStatus: json['http_status'] as int?,
      latency: latencyMs == null ? null : Duration(milliseconds: latencyMs),
      problem: switch (error) {
        null => null,
        'timeout' => AdminBlockchainHealthProblem.timeout,
        'unreachable' => AdminBlockchainHealthProblem.unreachable,
        _ => AdminBlockchainHealthProblem.badStatus,
      },
    );
  }
}
