import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/blockchain/admin/datasource/models/admin_blockchain_uptime_model.dart';

void main() {
  test('fromJson maps the v_admin_blockchain_uptime row', () {
    final uptime = AdminBlockchainUptimeModel.fromJson(const {
      'checks_24h': 719,
      'healthy_24h': 719,
      'uptime_pct_24h': 100.00,
      'last_check_at': '2026-11-24T20:48:00.106115+00:00',
      'last_check_ok': true,
      'monitor_running': true,
    });

    expect(uptime.checks, 719);
    expect(uptime.healthy, 719);
    expect(uptime.uptimePercent, 100);
    expect(uptime.lastCheckAt, DateTime.utc(2026, 11, 24, 20, 48, 0, 106, 115));
    expect(uptime.lastCheckOk, isTrue);
    expect(uptime.isMonitorRunning, isTrue);
  });

  test('no check yet: no percent and no last check', () {
    final uptime = AdminBlockchainUptimeModel.fromJson(const {
      'checks_24h': 0,
      'healthy_24h': 0,
      'uptime_pct_24h': null,
      'last_check_at': null,
      'last_check_ok': null,
      'monitor_running': false,
    });

    expect(uptime.uptimePercent, isNull);
    expect(uptime.lastCheckAt, isNull);
    expect(uptime.isMonitorRunning, isFalse);
  });
}
