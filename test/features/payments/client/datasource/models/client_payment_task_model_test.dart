import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/features/payments/client/datasource/models/client_payment_task_model.dart';
import 'package:watad/features/payments/client/domain/entities/client_task_payability.dart';

void main() {
  test('fromJson maps an approved task whose stage waits for the money', () {
    final task = ClientPaymentTaskModel.fromJson(const {
      'id': '0b6f8a52-41d3-4c55-9b0e-6a7c2f1e9d10',
      'title': 'اللياسة الداخلية',
      'amount': 15000.5,
      'status': 'approved',
      'payment_id': '9a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d',
      'payment_status': 'pending',
    });

    expect(task.title, 'اللياسة الداخلية');
    expect(task.status, TaskStatus.approved);
    expect(task.amount?.halalas, 1500050);
    expect(task.paymentId, '9a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d');
    expect(task.paymentStatus, PaymentStatus.pending);
    expect(task.payability, ClientTaskPayability.payable);
  });

  test('fromJson maps a task without amount or payment stage', () {
    final task = ClientPaymentTaskModel.fromJson(const {
      'id': '5a2e9c71-8b34-4f6d-a0e2-9c3b7d1f4e85',
      'title': 'تمديدات الكهرباء',
      'amount': null,
      'status': 'accepted',
      'payment_id': null,
      'payment_status': null,
    });

    expect(task.amount, isNull);
    expect(task.paymentId, isNull);
    expect(task.paymentStatus, isNull);
    expect(task.payability, ClientTaskPayability.notApproved);
  });
}
