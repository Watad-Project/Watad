import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/entities/client_task_payability.dart';

void main() {
  ClientPaymentTask task({
    TaskStatus status = TaskStatus.approved,
    Money? amount = const Money.halalas(1500000),
    String? paymentId = 'pay-1',
    PaymentStatus? paymentStatus = PaymentStatus.pending,
  }) => ClientPaymentTask(
    id: 't-1',
    title: 'اللياسة الداخلية',
    status: status,
    amount: amount,
    paymentId: paymentId,
    paymentStatus: paymentStatus,
  );

  test('an approved, priced task whose stage waits can be paid', () {
    expect(task().payability, ClientTaskPayability.payable);
    expect(
      task(paymentStatus: PaymentStatus.failed).payability,
      ClientTaskPayability.payable,
    );
  });

  test(
    'a paid stage, or one waiting for the contractor, is not paid again',
    () {
      expect(
        task(paymentStatus: PaymentStatus.paid).payability,
        ClientTaskPayability.paid,
      );
      expect(
        task(paymentStatus: PaymentStatus.processing).payability,
        ClientTaskPayability.awaitingConfirmation,
      );
    },
  );

  test('a task not approved yet, or without an amount, is not paid', () {
    for (final status in [
      TaskStatus.proposed,
      TaskStatus.accepted,
      TaskStatus.done,
      TaskStatus.rejected,
    ]) {
      expect(task(status: status).payability, ClientTaskPayability.notApproved);
    }
    expect(task(amount: null).payability, ClientTaskPayability.noAmount);
  });

  test('a cancelled or refunded stage, or none at all, can\'t be paid', () {
    expect(
      task(paymentStatus: PaymentStatus.cancelled).payability,
      ClientTaskPayability.unavailable,
    );
    expect(
      task(paymentStatus: PaymentStatus.refunded).payability,
      ClientTaskPayability.unavailable,
    );
    expect(
      task(paymentId: null, paymentStatus: null).payability,
      ClientTaskPayability.unavailable,
    );
  });
}
