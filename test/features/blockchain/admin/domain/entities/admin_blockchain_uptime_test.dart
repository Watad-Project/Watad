import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_network_state.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_uptime.dart';

void main() {
  final now = DateTime.utc(2026, 11, 24, 21);

  AdminBlockchainUptime uptime({
    Duration ago = const Duration(minutes: 2),
    bool? ok = true,
    bool running = true,
  }) => AdminBlockchainUptime(
    checks: 718,
    healthy: 717,
    lastCheckAt: now.subtract(ago),
    lastCheckOk: ok,
    isMonitorRunning: running,
  );

  test('a recent healthy check: up', () {
    expect(uptime().networkAt(now), AdminBlockchainNetworkState.up);
  });

  test('a recent failed check: down', () {
    expect(uptime(ok: false).networkAt(now), AdminBlockchainNetworkState.down);
  });

  test('a stopped monitor or an old check says nothing about now', () {
    expect(
      uptime(running: false).networkAt(now),
      AdminBlockchainNetworkState.unknown,
    );
    expect(
      uptime(ago: const Duration(minutes: 11)).networkAt(now),
      AdminBlockchainNetworkState.unknown,
    );
    expect(
      uptime(ok: null).networkAt(now),
      AdminBlockchainNetworkState.unknown,
    );
  });
}
