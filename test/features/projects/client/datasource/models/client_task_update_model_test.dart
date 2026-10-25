import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/features/projects/client/datasource/models/client_task_update_model.dart';

void main() {
  test('fromJson maps a pending update with its photos and contractor', () {
    final update = ClientTaskUpdateModel.fromJson(const {
      'id': 'd3c1e4a8-7f52-4b0e-9a61-2e8f5c7b9a04',
      'project_id': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
      'task_title': 'اللياسة الداخلية',
      'task_amount': 24000,
      'proposed_state': 'done',
      'note': 'انتهت لياسة الدور الأرضي كاملة',
      'photo_paths': ['b-1/1729750800000_a.jpg'],
      'decision': 'pending',
      'rejection_reason': null,
      'rejection_details': null,
      'created_at': '2026-10-24T06:40:00+00:00',
      'photo_urls': [
        'https://example.supabase.co/storage/v1/object/sign/task-evidence/b-1/1729750800000_a.jpg?token=t',
      ],
      'project_status': 'in_progress',
      'contractor_name': 'مؤسسة البناء المتين',
      'contractor_avatar_url': 'https://example.supabase.co/storage/v1/object/public/avatars/b-1/me.png',
    });

    expect(update.taskTitle, 'اللياسة الداخلية');
    expect(update.taskAmount?.halalas, 2400000);
    expect(update.proposedState, TaskUpdateState.done);
    expect(update.decision, TaskUpdateDecision.pending);
    expect(update.photoUrls.single, endsWith('token=t'));
    expect(update.projectStatus, ProjectStatus.inProgress);
    expect(update.contractorName, 'مؤسسة البناء المتين');
    expect(update.createdAt.isUtc, isTrue);
    expect(update.canDecide, isTrue);
  });

  test('fromJson maps a rejected update without amount, note or photos', () {
    final update = ClientTaskUpdateModel.fromJson(const {
      'id': 'a7b2c9d4-1e3f-4a5b-8c6d-7e8f9a0b1c2d',
      'project_id': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
      'task_title': 'تمديدات الكهرباء',
      'task_amount': null,
      'proposed_state': 'done',
      'note': null,
      'photo_paths': ['b-1/1729750800000_b.jpg'],
      'decision': 'rejected',
      'rejection_reason': 'الأدلة غير كافية',
      'rejection_details': 'لا تظهر زوايا السقف في الصور.',
      'created_at': '2026-10-24T06:40:00+00:00',
      'photo_urls': <String>[],
      'project_status': 'in_progress',
      'contractor_name': null,
      'contractor_avatar_url': null,
    });

    expect(update.taskAmount, isNull);
    expect(update.note, isNull);
    expect(update.photoUrls, isEmpty);
    expect(update.decision, TaskUpdateDecision.rejected);
    expect(update.rejectionReason, 'الأدلة غير كافية');
    expect(update.rejectionDetails, 'لا تظهر زوايا السقف في الصور.');
    expect(update.contractorName, isNull);
    expect(update.canDecide, isFalse);
  });

  test('a pending update waits once the project is no longer in progress', () {
    final update = ClientTaskUpdateModel.fromJson(const {
      'id': 'f1e2d3c4-b5a6-4978-8a9b-0c1d2e3f4a5b',
      'task_title': 'الدهانات',
      'proposed_state': 'done',
      'decision': 'pending',
      'created_at': '2026-10-24T06:40:00+00:00',
      'project_status': 'completed',
    });

    expect(update.decision, TaskUpdateDecision.pending);
    expect(update.canDecide, isFalse);
  });
}
