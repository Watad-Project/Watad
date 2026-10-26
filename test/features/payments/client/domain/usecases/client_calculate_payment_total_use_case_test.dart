import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/usecases/client_calculate_payment_total_use_case.dart';

void main() {
  ClientPaymentTask task(
    String id,
    int halalas, {
    PaymentStatus paymentStatus = PaymentStatus.pending,
  }) => ClientPaymentTask(
    id: id,
    title: 'مهمة $id',
    status: TaskStatus.approved,
    amount: Money.halalas(halalas),
    paymentId: 'pay-$id',
    paymentStatus: paymentStatus,
  );

  const calculate = ClientCalculatePaymentTotalUseCase();

  test('adds the selected tasks up in halalas', () async {
    final result = await calculate([
      task('t-1', 1500050),
      task('t-2', 2400025),
    ]);

    expect((result as Success<Money>).data, const Money.halalas(3900075));
  });

  test('nothing selected adds up to zero', () async {
    final result = await calculate(const []);

    expect((result as Success<Money>).data, const Money.zero());
  });

  test('refuses a task that can\'t be paid', () async {
    final result = await calculate([
      task('t-1', 1500000),
      task('t-2', 2400000, paymentStatus: PaymentStatus.processing),
    ]);

    expect((result as Failed<Money>).failure, isA<ValidationFailure>());
  });
}
