import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/blockchain/admin/datasource/models/admin_blockchain_summary_model.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_job_result.dart';

void main() {
  test('fromJson maps the v_admin_blockchain_summary row', () {
    final summary = AdminBlockchainSummaryModel.fromJson(const {
      'projects': 5,
      'synced': 4,
      'waiting': 0,
      'retrying': 0,
      'failed': 1,
      'last_synced_at': '2026-10-22T12:28:03.194767+00:00',
      'retry_job_active': true,
      'retry_job_last_run_at': '2026-10-27T08:32:00.080149+00:00',
      'retry_job_last_status': 'succeeded',
    });

    expect(summary.projects, 5);
    expect(summary.synced, 4);
    expect(summary.failed, 1);
    expect(summary.lastSyncedAt!.isUtc, isTrue);
    expect(summary.retryJobActive, isTrue);
    expect(summary.retryJobLastRunAt, isNotNull);
    expect(summary.retryJobLastResult, AdminBlockchainJobResult.succeeded);
  });

  test('no sync yet and no retry job read as null', () {
    final summary = AdminBlockchainSummaryModel.fromJson(const {
      'projects': 0,
      'synced': 0,
      'waiting': 0,
      'retrying': 0,
      'failed': 0,
      'last_synced_at': null,
      'retry_job_active': null,
      'retry_job_last_run_at': null,
      'retry_job_last_status': null,
    });

    expect(summary.lastSyncedAt, isNull);
    expect(summary.retryJobActive, isNull);
    expect(summary.retryJobLastResult, isNull);
  });

  test("pg_cron's steps of a run still going read as running", () {
    for (final status in ['starting', 'running', 'sending', 'connecting']) {
      final summary = AdminBlockchainSummaryModel.fromJson({
        'projects': 0,
        'synced': 0,
        'waiting': 0,
        'retrying': 0,
        'failed': 0,
        'retry_job_last_status': status,
      });
      expect(summary.retryJobLastResult, AdminBlockchainJobResult.running);
    }
    final failed = AdminBlockchainSummaryModel.fromJson(const {
      'projects': 0,
      'synced': 0,
      'waiting': 0,
      'retrying': 0,
      'failed': 0,
      'retry_job_last_status': 'failed',
    });
    expect(failed.retryJobLastResult, AdminBlockchainJobResult.failed);
  });
}
