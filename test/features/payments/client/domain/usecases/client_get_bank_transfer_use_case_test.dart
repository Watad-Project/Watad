import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_details.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_transfer.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_selection.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/usecases/client_get_bank_transfer_use_case.dart';

import '../../../../../helpers/fake_client_payments_repository.dart';

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
  const bankDetails = ClientBankDetails(
    beneficiaryName: 'مؤسسة البناء المتين',
    bankName: 'مصرف الراجحي',
    iban: 'SA0380000000608010167519',
  );
  const selection = ClientPaymentSelection(
    projectId: 'p-3',
    taskIds: ['t-1', 't-2', 't-3'],
  );

  late FakeClientPaymentsRepository repository;

  setUp(() {
    repository = FakeClientPaymentsRepository()
      ..tasksResult = Success([
        task('t-1', 1500000),
        task('t-2', 3000000, paymentStatus: PaymentStatus.processing),
        task('t-3', 2400050, paymentStatus: PaymentStatus.failed),
        task('t-4', 900000),
      ])
      ..bankDetailsResult = const Success(bankDetails);
  });

  test('pays the selected tasks still waiting, with their total', () async {
    final result = await ClientGetBankTransferUseCase(repository)(selection);

    final transfer = (result as Success<ClientBankTransfer>).data;
    expect(transfer.tasks.map((t) => t.id), ['t-1', 't-3']);
    expect(transfer.skippedTasks.map((t) => t.id), ['t-2']);
    expect(transfer.total, const Money.halalas(3900050));
    expect(transfer.bankDetails?.iban, 'SA0380000000608010167519');
  });

  test('says when the contractor has no bank details yet', () async {
    repository.bankDetailsResult = const Success(null);

    final result = await ClientGetBankTransferUseCase(repository)(selection);

    expect((result as Success<ClientBankTransfer>).data.bankDetails, isNull);
  });

  test('refuses an empty selection', () async {
    final result = await ClientGetBankTransferUseCase(repository)(
      const ClientPaymentSelection(projectId: 'p-3', taskIds: []),
    );

    expect(
      (result as Failed<ClientBankTransfer>).failure,
      isA<ValidationFailure>(),
    );
  });

  test('passes a failed read on', () async {
    repository.bankDetailsResult = const Failed(NotFoundFailure());

    final result = await ClientGetBankTransferUseCase(repository)(selection);

    expect(
      (result as Failed<ClientBankTransfer>).failure,
      isA<NotFoundFailure>(),
    );
  });
}
