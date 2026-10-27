import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/blockchain/admin/datasource/models/admin_blockchain_health_model.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health_problem.dart';

void main() {
  test('fromJson maps a ledger that answered', () {
    final health = AdminBlockchainHealthModel.fromJson(const {
      'reachable': true,
      'http_status': 200,
      'latency_ms': 231,
      'checked_at': '2026-10-27T08:30:00.000Z',
      'details': {'status': 'ok'},
      'error': null,
    });

    expect(health.isReachable, isTrue);
    expect(health.httpStatus, 200);
    expect(health.latency, const Duration(milliseconds: 231));
    expect(health.checkedAt, DateTime.utc(2026, 10, 27, 8, 30));
    expect(health.problem, isNull);
  });

  test('fromJson maps a ledger that did not answer', () {
    final timeout = AdminBlockchainHealthModel.fromJson(const {
      'reachable': false,
      'http_status': null,
      'latency_ms': null,
      'checked_at': '2026-10-27T08:30:00.000Z',
      'details': null,
      'error': 'timeout',
    });
    expect(timeout.isReachable, isFalse);
    expect(timeout.httpStatus, isNull);
    expect(timeout.latency, isNull);
    expect(timeout.problem, AdminBlockchainHealthProblem.timeout);

    final unreachable = AdminBlockchainHealthModel.fromJson(const {
      'reachable': false,
      'checked_at': '2026-10-27T08:30:00.000Z',
      'error': 'unreachable',
    });
    expect(unreachable.problem, AdminBlockchainHealthProblem.unreachable);

    final badStatus = AdminBlockchainHealthModel.fromJson(const {
      'reachable': false,
      'http_status': 503,
      'latency_ms': 40,
      'checked_at': '2026-10-27T08:30:00.000Z',
      'error': 'bad_status',
    });
    expect(badStatus.problem, AdminBlockchainHealthProblem.badStatus);
    expect(badStatus.httpStatus, 503);
  });
}
