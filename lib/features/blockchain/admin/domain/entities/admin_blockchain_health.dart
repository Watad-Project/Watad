import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health_problem.dart';

/// Whether the blockchain (the Fabric REST API) answered: the result of the
/// `blockchain-health` Edge Function.
class AdminBlockchainHealth {
  const AdminBlockchainHealth({
    required this.isReachable,
    required this.checkedAt,
    this.httpStatus,
    this.latency,
    this.problem,
  });

  /// It answered 200.
  final bool isReachable;

  /// When the check ran.
  final DateTime checkedAt;

  /// The API's status; null when it didn't answer.
  final int? httpStatus;

  /// How long the answer took; null when it didn't answer.
  final Duration? latency;

  /// Null when [isReachable].
  final AdminBlockchainHealthProblem? problem;
}
