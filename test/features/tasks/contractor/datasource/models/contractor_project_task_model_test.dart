import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/features/tasks/contractor/datasource/models/contractor_project_task_model.dart';

void main() {
  test('fromJson maps an approved and paid v_project_tasks row with Riyadh calendar dates', () {
    final task = ContractorProjectTaskModel.fromJson(const {
      'id': 't-1',
      'project_id': 'p-1',
      'title': 'صب الأساسات والخرسانة',
      'description': 'حفر القواعد وصب الخرسانة',
      'amount': 90000,
      'status': 'approved',
      'payment_id': 'pay-1',
      'payment_status': 'paid',
      'start_date': '2026-01-10',
      'finish_date': '2026-01-18',
      'decided_at': '2026-01-19T08:30:00Z',
      'created_at': '2026-01-09T10:00:00Z',
      'last_update_id': 'upd-1',
      'last_update_proposed_state': 'done',
      'last_update_decision': 'accepted',
      'last_update_at': '2026-01-18T16:00:00Z',
      'has_pending_update': false,
    });

    expect(task.id, 't-1');
    expect(task.projectId, 'p-1');
    expect(task.title, 'صب الأساسات والخرسانة');
    expect(task.status, TaskStatus.approved);
    expect(task.amount?.halalas, 9000000);
    expect(task.paymentStatus, PaymentStatus.paid);
    expect(task.startDate, DateTime.utc(2026, 1, 10));
    expect(task.finishDate, DateTime.utc(2026, 1, 18));
    expect(task.lastUpdateId, 'upd-1');
    expect(task.lastUpdateProposedState, TaskStatus.done);
    expect(task.lastUpdateDecision, TaskUpdateDecision.accepted);
    expect(task.hasPendingUpdate, isFalse);
    expect(task.canSendUpdate, isFalse);
    expect(task.hasLatestUpdate, isTrue);
  });

  test(
    'fromJson maps an accepted task without pending update as open for update',
    () {
      final task = ContractorProjectTaskModel.fromJson(const {
        'id': 't-2',
        'project_id': 'p-1',
        'title': 'تمديد الكهرباء والسباكة',
        'description': null,
        'amount': null,
        'status': 'accepted',
        'payment_id': null,
        'payment_status': null,
        'start_date': null,
        'finish_date': null,
        'decided_at': null,
        'created_at': '2026-01-20T10:00:00Z',
        'last_update_id': null,
        'last_update_proposed_state': null,
        'last_update_decision': null,
        'last_update_at': null,
        'has_pending_update': false,
      });

      expect(task.status, TaskStatus.accepted);
      expect(task.amount, isNull);
      expect(task.startDate, isNull);
      expect(task.finishDate, isNull);
      expect(task.canSendUpdate, isTrue);
      expect(task.hasLatestUpdate, isFalse);
    },
  );
}
