import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_network_state.dart';

/// How reliable the blockchain network is (GRA-75): the uptime monitor's
/// checks of the last 24 hours, every 2 minutes, from
/// `v_admin_blockchain_uptime`.
class AdminBlockchainUptime {
  const AdminBlockchainUptime({
    required this.checks,
    required this.healthy,
    required this.isMonitorRunning,
    this.uptimePercent,
    this.lastCheckAt,
    this.lastCheckOk,
  });

  /// The answered checks of the last 24 hours.
  final int checks;

  /// How many of them found the network healthy.
  final int healthy;

  /// [healthy] out of [checks], in percent; null without a check.
  final double? uptimePercent;

  /// When the last answered check was sent; null before the first one.
  final DateTime? lastCheckAt;
  final bool? lastCheckOk;

  /// The monitor checks every 2 minutes.
  final bool isMonitorRunning;

  /// A check older than this says nothing about now: the monitor checks
  /// every 2 minutes and counts a check with no answer after 10 minutes as
  /// failed.
  static const Duration staleAfter = Duration(minutes: 10);

  /// Whether the network is up at [now], by the last check.
  AdminBlockchainNetworkState networkAt(DateTime now) {
    final lastCheckAt = this.lastCheckAt;
    final lastCheckOk = this.lastCheckOk;
    if (!isMonitorRunning ||
        lastCheckAt == null ||
        lastCheckOk == null ||
        now.difference(lastCheckAt) > staleAfter) {
      return AdminBlockchainNetworkState.unknown;
    }
    return lastCheckOk
        ? AdminBlockchainNetworkState.up
        : AdminBlockchainNetworkState.down;
  }
}
