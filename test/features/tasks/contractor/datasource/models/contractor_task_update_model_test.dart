import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/tasks/contractor/datasource/models/contractor_task_update_model.dart';

void main() {
  test(
    'parses v_project_task_updates JSON row with payment and rejection details',
    () {
      final model = ContractorTaskUpdateModel.fromJson({
        'id': 'upd-1',
        'task_id': 'task-1',
        'task_title': 'اللياسة الداخلية',
        'task_amount': 24000,
        'project_id': 'proj-1',
        'project_title': 'فيلا سكنية',
        'project_district': 'حي الياسمين',
        'project_status': 'in_progress',
        'proposed_state': 'done',
        'decision': 'rejected',
        'note': 'اكتملت لياسة الجدران',
        'rejection_reason': 'الأدلة غير كافية',
        'rejection_details':
            'لا تظهر زوايا السقف، والتشقق عند النافذة الشرقية ما زال ظاهراً.',
        'rejection_photo_urls': ['https://example.com/reject1.jpg'],
        'payment_amount': null,
        'decided_at': '2026-10-28T07:00:00Z',
        'created_at': '2026-10-28T06:40:00Z',
      });

      expect(model.id, 'upd-1');
      expect(model.taskId, 'task-1');
      expect(model.taskTitle, 'اللياسة الداخلية');
      expect(model.projectId, 'proj-1');
      expect(model.displayProjectTitle, 'فيلا سكنية — حي الياسمين');
      expect(model.projectStatus, ProjectStatus.inProgress);
      expect(model.proposedState, TaskUpdateState.done);
      expect(model.decision, TaskUpdateDecision.rejected);
      expect(model.taskAmount, const Money.halalas(2400000));
      expect(model.createdPaymentAmount, const Money.halalas(2400000));
      expect(model.rejectionReason, 'الأدلة غير كافية');
      expect(
        model.rejectionDetails,
        'لا تظهر زوايا السقف، والتشقق عند النافذة الشرقية ما زال ظاهراً.',
      );
      expect(model.rejectionPhotoUrls, ['https://example.com/reject1.jpg']);
      expect(model.canSendNewUpdate, isTrue);
    },
  );

  test('prefers payment_amount when present and disables retry on completed project', () {
    final model = ContractorTaskUpdateModel.fromJson({
      'id': 'upd-2',
      'task_id': 'task-2',
      'task_title': 'الدهان الداخلي',
      'task_amount': 15000,
      'payment_amount': 24000,
      'project_id': 'proj-1',
      'project_title': 'فيلا سكنية — حي الياسمين',
      'project_district': 'حي الياسمين',
      'project_status': 'completed',
      'proposed_state': 'done',
      'decision': 'accepted',
      'created_at': '2026-10-28T06:40:00Z',
    });

    expect(model.displayProjectTitle, 'فيلا سكنية — حي الياسمين');
    expect(model.createdPaymentAmount, const Money.halalas(2400000));
    expect(model.canSendNewUpdate, isFalse);
  });
}
