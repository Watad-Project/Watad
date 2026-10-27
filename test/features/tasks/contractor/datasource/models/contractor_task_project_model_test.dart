import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/features/tasks/contractor/datasource/models/contractor_task_project_model.dart';

void main() {
  test('fromJson maps an in-progress v_my_projects row with agreed amount and photo', () {
    final project = ContractorTaskProjectModel.fromJson(const {
      'id': 'p-1',
      'title': 'فيلا سكنية',
      'status': 'in_progress',
      'owner_id': 'u-client',
      'owner_name': 'عبدالله الحربي',
      'city': 'الرياض',
      'district': 'حي الياسمين',
      'agreed_amount': 480000,
      'budget': 450000,
      'total_paid': 90000,
      'total_scheduled': 210000,
      'photo_url':
          'https://example.supabase.co/storage/v1/object/public/images/p-1.jpg',
      'created_at': '2026-01-05T10:00:00Z',
      'completed_at': null,
    });

    expect(project.id, 'p-1');
    expect(project.title, 'فيلا سكنية');
    expect(project.displayTitle, 'فيلا سكنية — حي الياسمين');
    expect(project.status, ProjectStatus.inProgress);
    expect(project.isInProgress, isTrue);
    expect(project.ownerName, 'عبدالله الحربي');
    expect(project.ownerId, 'u-client');
    expect(project.agreedAmount?.halalas, 48000000);
    expect(project.budget?.halalas, 45000000);
    expect(project.contractAmount?.halalas, 48000000);
    expect(project.totalPaid.halalas, 9000000);
    expect(project.totalScheduled.halalas, 21000000);
    expect(
      project.photoUrl,
      'https://example.supabase.co/storage/v1/object/public/images/p-1.jpg',
    );
    expect(project.completedAt, isNull);
  });

  test('fromJson falls back to budget when agreed_amount is null and marks completed read-only', () {
    final project = ContractorTaskProjectModel.fromJson(const {
      'id': 'p-2',
      'title': 'فيلا سكنية — حي الياسمين',
      'status': 'completed',
      'owner_name': 'عبدالله الحربي',
      'city': null,
      'district': 'حي الياسمين',
      'agreed_amount': null,
      'budget': 320000,
      'total_paid': null,
      'total_scheduled': null,
      'photo_url': null,
      'created_at': '2026-01-05T10:00:00Z',
      'completed_at': '2026-03-01T12:00:00Z',
    });

    expect(project.displayTitle, 'فيلا سكنية — حي الياسمين');
    expect(project.isInProgress, isFalse);
    expect(project.contractAmount?.halalas, 32000000);
    expect(project.totalPaid.halalas, 0);
    expect(project.totalScheduled.halalas, 0);
    expect(project.photoUrl, isNull);
    expect(project.completedAt, DateTime.utc(2026, 3, 1, 12));
  });
}
