import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_overall.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_summary.dart';

AdminBlockchainSummary _summary({
  int waiting = 0,
  int retrying = 0,
  int failed = 0,
}) => AdminBlockchainSummary(
  projects: 4,
  synced: 4 - waiting - retrying - failed,
  waiting: waiting,
  retrying: retrying,
  failed: failed,
);

AdminBlockchainHealth _health({required bool isReachable}) =>
    AdminBlockchainHealth(
      isReachable: isReachable,
      checkedAt: DateTime.utc(2026, 10, 27),
    );

void main() {
  test('green when the ledger answers and everything is synced', () {
    expect(
      AdminBlockchainOverall.of(_summary(), _health(isReachable: true)),
      AdminBlockchainOverall.healthy,
    );
  });

  test('orange while projects wait or retry', () {
    expect(
      AdminBlockchainOverall.of(
        _summary(waiting: 1),
        _health(isReachable: true),
      ),
      AdminBlockchainOverall.syncing,
    );
    expect(
      AdminBlockchainOverall.of(_summary(retrying: 1), null),
      AdminBlockchainOverall.syncing,
    );
  });

  test('red when the ledger does not answer or a project needs attention', () {
    expect(
      AdminBlockchainOverall.of(_summary(), _health(isReachable: false)),
      AdminBlockchainOverall.attention,
    );
    expect(
      AdminBlockchainOverall.of(
        _summary(failed: 1, waiting: 1),
        _health(isReachable: true),
      ),
      AdminBlockchainOverall.attention,
    );
  });

  test('before the ledger is checked, only the sync counts', () {
    expect(
      AdminBlockchainOverall.of(_summary(), null),
      AdminBlockchainOverall.healthy,
    );
  });
}
