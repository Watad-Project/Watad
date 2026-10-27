import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/features/blockchain/admin/datasource/models/admin_blockchain_project_model.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_sync_status.dart';

void main() {
  test('fromJson maps a v_admin_blockchain_sync row', () {
    final project = AdminBlockchainProjectModel.fromJson(const {
      'project_id': 'd22a4b79-80a3-4e44-afc2-25e1fedc7e61',
      'project_title': 'بناء ملحق (اختبار)',
      'project_status': 'in_progress',
      'owner_name': null,
      'contractor_name': 'مقاولات الخبر',
      'sync_status': 'failed',
      'version': 19,
      'attempts': 0,
      'last_attempt_at': '2026-10-25T21:30:46.180925+00:00',
      'next_attempt_at': null,
      'synced_at': null,
      'last_message':
          'project created was refused (400): project: "owner" is required',
    });

    expect(project.projectId, 'd22a4b79-80a3-4e44-afc2-25e1fedc7e61');
    expect(project.projectStatus, ProjectStatus.inProgress);
    expect(project.syncStatus, AdminBlockchainSyncStatus.failed);
    expect(project.version, 19);
    expect(project.ownerName, isNull);
    expect(project.contractorName, 'مقاولات الخبر');
    expect(
      project.lastAttemptAt,
      DateTime.utc(2026, 10, 25, 21, 30, 46, 180, 925),
    );
    expect(project.lastAttemptAt!.isUtc, isTrue);
    expect(project.nextAttemptAt, isNull);
    expect(project.syncedAt, isNull);
  });

  test('every sync_status of the view maps to its state', () {
    expect([
      for (final value in ['failed', 'retrying', 'waiting', 'synced'])
        AdminBlockchainProjectModel.syncStatusFromJson(value),
    ], AdminBlockchainSyncStatus.values);
    expect(
      () => AdminBlockchainProjectModel.syncStatusFromJson('done'),
      throwsFormatException,
    );
  });
}
