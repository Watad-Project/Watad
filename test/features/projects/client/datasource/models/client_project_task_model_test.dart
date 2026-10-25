import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_task_model.dart';

void main() {
  test('fromJson maps an approved, priced v_project_tasks row', () {
    final task = ClientProjectTaskModel.fromJson(const {
      'id': '0b6f8a52-41d3-4c55-9b0e-6a7c2f1e9d10',
      'title': 'اللياسة الداخلية',
      'description': 'لياسة الجدران الداخلية للدور الأرضي',
      'amount': 24000.5,
      'status': 'approved',
      'payment_status': 'processing',
      'start_date': '2026-10-12',
      'finish_date': '2026-10-20',
      'last_update_id': 'd3c1e4a8-7f52-4b0e-9a61-2e8f5c7b9a04',
    });

    expect(task.title, 'اللياسة الداخلية');
    expect(task.status, TaskStatus.approved);
    expect(task.amount?.halalas, 2400050);
    expect(task.paymentStatus, PaymentStatus.processing);
    // A calendar day stays the same day, whatever the phone's time zone.
    expect(task.startDate, DateTime.utc(2026, 10, 12));
    expect(task.finishDate, DateTime.utc(2026, 10, 20));
    expect(task.lastUpdateId, 'd3c1e4a8-7f52-4b0e-9a61-2e8f5c7b9a04');
  });

  test('fromJson maps a proposed task without amount, dates or updates', () {
    final task = ClientProjectTaskModel.fromJson(const {
      'id': '5a2e9c71-8b34-4f6d-a0e2-9c3b7d1f4e85',
      'title': 'تمديدات الكهرباء',
      'description': 'تمديد نقاط الكهرباء في الملحق',
      'amount': null,
      'status': 'proposed',
      'payment_status': null,
      'start_date': null,
      'finish_date': null,
      'last_update_id': null,
    });

    expect(task.status, TaskStatus.proposed);
    expect(task.amount, isNull);
    expect(task.paymentStatus, isNull);
    expect(task.startDate, isNull);
    expect(task.finishDate, isNull);
    expect(task.lastUpdateId, isNull);
  });
}
