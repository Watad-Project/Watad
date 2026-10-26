import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_transfer_outcome.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_transfer_request.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_selection.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt.dart';
import 'package:watad/features/payments/client/domain/usecases/client_submit_bank_transfer_use_case.dart';

import '../../../../../helpers/fake_client_payments_repository.dart';

void main() {
  ClientPaymentTask task(
    String id, {
    PaymentStatus paymentStatus = PaymentStatus.pending,
  }) => ClientPaymentTask(
    id: id,
    title: 'مهمة $id',
    status: TaskStatus.approved,
    amount: const Money.halalas(1500000),
    paymentId: 'pay-$id',
    paymentStatus: paymentStatus,
  );
  // The picked file's name is only shown; the upload gets its own.
  final receipt = ClientReceipt(
    bytes: Uint8List.fromList([1, 2, 3]),
    name: 'إيصال التحويل.PNG',
  );
  const selection = ClientPaymentSelection(
    projectId: 'p-3',
    taskIds: ['t-1', 't-2', 't-3'],
  );

  late FakeClientPaymentsRepository repository;

  Future<ClientBankTransferOutcome> send([ClientReceipt? other]) async {
    final result = await ClientSubmitBankTransferUseCase(repository)(
      ClientBankTransferRequest(
        selection: selection,
        receipt: other ?? receipt,
      ),
    );
    return (result as Success<ClientBankTransferOutcome>).data;
  }

  setUp(() {
    repository = FakeClientPaymentsRepository()
      ..tasksResult = Success([task('t-1'), task('t-2'), task('t-3')]);
  });

  test('sends the receipt once for each stage, in order', () async {
    final outcome = await send();

    expect(repository.submitted, [
      ('pay-t-1', receipt.name),
      ('pay-t-2', receipt.name),
      ('pay-t-3', receipt.name),
    ]);
    expect(outcome.sent.map((t) => t.id), ['t-1', 't-2', 't-3']);
    expect(outcome.isComplete, isTrue);
  });

  test('skips the stages already paid or waiting for the contractor', () async {
    repository.tasksResult = Success([
      task('t-1', paymentStatus: PaymentStatus.processing),
      task('t-2', paymentStatus: PaymentStatus.failed),
      task('t-3', paymentStatus: PaymentStatus.paid),
    ]);

    final outcome = await send();

    expect(repository.submitted.map((s) => s.$1), ['pay-t-2']);
    expect(outcome.sent.map((t) => t.id), ['t-2']);
  });

  test('stops at the first stage that fails, and says what went', () async {
    repository.failingPayments['pay-t-2'] = const NetworkFailure();

    final outcome = await send();

    expect(repository.submitted.map((s) => s.$1), ['pay-t-1']);
    expect(outcome.sent.map((t) => t.id), ['t-1']);
    expect(outcome.notSent.map((t) => t.id), ['t-2', 't-3']);
    expect(outcome.failure, isA<NetworkFailure>());
    expect(outcome.isComplete, isFalse);
  });

  test('sending again sends only the rest, never a stage twice', () async {
    repository.failingPayments['pay-t-2'] = const NetworkFailure();
    await send();
    repository.failingPayments.clear();

    final outcome = await send();

    expect(repository.submitted.map((s) => s.$1), [
      'pay-t-1',
      'pay-t-2',
      'pay-t-3',
    ]);
    expect(outcome.sent.map((t) => t.id), ['t-2', 't-3']);
    expect(outcome.isComplete, isTrue);
  });

  test('nothing waiting sends nothing', () async {
    repository.tasksResult = Success([
      task('t-1', paymentStatus: PaymentStatus.processing),
    ]);

    final outcome = await send();

    expect(repository.submitted, isEmpty);
    expect(outcome.sent, isEmpty);
    expect(outcome.isComplete, isTrue);
  });

  test('a receipt that is not a PDF, JPEG or PNG never leaves', () async {
    final result = await ClientSubmitBankTransferUseCase(repository)(
      ClientBankTransferRequest(
        selection: selection,
        receipt: ClientReceipt(
          bytes: Uint8List.fromList([1]),
          name: 'IMG_0001.HEIC',
        ),
      ),
    );

    expect(
      (result as Failed<ClientBankTransferOutcome>).failure.messageKey,
      'payments.client.receipt_type',
    );
    expect(repository.submitted, isEmpty);
  });

  test('passes a failed read on, sending nothing', () async {
    repository.tasksResult = const Failed(NetworkFailure());

    final result = await ClientSubmitBankTransferUseCase(repository)(
      ClientBankTransferRequest(selection: selection, receipt: receipt),
    );

    expect(
      (result as Failed<ClientBankTransferOutcome>).failure,
      isA<NetworkFailure>(),
    );
    expect(repository.submitted, isEmpty);
  });
}
