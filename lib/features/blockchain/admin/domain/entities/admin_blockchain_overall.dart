import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_summary.dart';

/// The one status of the blockchain side, for the status card at the top.
enum AdminBlockchainOverall {
  /// The ledger answers and every project is synced.
  healthy,

  /// Projects are waiting or retrying; nothing needs a person.
  syncing,

  /// The ledger doesn't answer, or a project needs attention.
  attention;

  /// [health] is null until the ledger was checked: then only the sync
  /// counts.
  static AdminBlockchainOverall of(
    AdminBlockchainSummary summary,
    AdminBlockchainHealth? health,
  ) {
    if (summary.failed > 0 || health?.isReachable == false) return attention;
    if (summary.waiting > 0 || summary.retrying > 0) return syncing;
    return healthy;
  }
}
