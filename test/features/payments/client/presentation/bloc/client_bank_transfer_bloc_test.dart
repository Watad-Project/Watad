import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_details.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_selection.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt.dart';
import 'package:watad/features/payments/client/domain/usecases/client_check_receipt_use_case.dart';
import 'package:watad/features/payments/client/domain/usecases/client_get_bank_transfer_use_case.dart';
import 'package:watad/features/payments/client/domain/usecases/client_submit_bank_transfer_use_case.dart';
import 'package:watad/features/payments/client/presentation/bloc/client_bank_transfer_bloc.dart';

import '../../../../../helpers/fake_client_payments_repository.dart';

void main() {
  ClientPaymentTask task(String id, int halalas) => ClientPaymentTask(
    id: id,
    title: 'مهمة $id',
    status: TaskStatus.approved,
    amount: Money.halalas(halalas),
    paymentId: 'pay-$id',
    paymentStatus: PaymentStatus.pending,
  );
  const selection = ClientPaymentSelection(
    projectId: 'p-3',
    taskIds: ['t-1', 't-2'],
  );
  final pdf = ClientReceipt(
    bytes: Uint8List.fromList([1, 2, 3]),
    name: 'receipt.pdf',
  );

  late FakeClientPaymentsRepository repository;

  ClientBankTransferBloc buildBloc() => ClientBankTransferBloc(
    ClientGetBankTransferUseCase(repository),
    const ClientCheckReceiptUseCase(),
    ClientSubmitBankTransferUseCase(repository),
  );

  Future<ClientBankTransferBloc> loadedBloc() async {
    final bloc = buildBloc()..add(const ClientBankTransferFetched(selection));
    await bloc.stream.firstWhere(
      (s) => s.status == ClientBankTransferStatus.success,
    );
    return bloc;
  }

  Future<ClientBankTransferBloc> readyBloc() async {
    final bloc = await loadedBloc();
    bloc.add(ClientBankTransferReceiptPicked(pdf));
    await bloc.stream.firstWhere((s) => s.receipt != null);
    return bloc;
  }

  setUp(() {
    repository = FakeClientPaymentsRepository()
      ..tasksResult = Success([task('t-1', 1500000), task('t-2', 2400000)])
      ..bankDetailsResult = const Success(
        ClientBankDetails(
          beneficiaryName: 'مؤسسة البناء المتين',
          bankName: 'مصرف الراجحي',
          iban: 'SA0380000000608010167519',
        ),
      );
  });

  test('loads what to pay and where; nothing to send yet', () async {
    final bloc = await loadedBloc();

    expect(bloc.state.transfer?.tasks, hasLength(2));
    expect(bloc.state.transfer?.total, const Money.halalas(3900000));
    expect(bloc.state.canSend, isFalse);
    await bloc.close();
  });

  test('a picked PDF is attached, and then it can be sent', () async {
    final bloc = await readyBloc();

    expect(bloc.state.receipt?.name, 'receipt.pdf');
    expect(bloc.state.canSend, isTrue);
    await bloc.close();
  });

  test('a HEIC photo is refused with why, and nothing is attached', () async {
    final bloc = await loadedBloc();

    bloc.add(
      ClientBankTransferReceiptPicked(
        ClientReceipt(bytes: Uint8List.fromList([1]), name: 'IMG_0001.HEIC'),
      ),
    );
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(state.message?.key, 'payments.client.receipt_type');
    expect(state.message?.isError, isTrue);
    expect(state.receipt, isNull);
    await bloc.close();
  });

  test('sending for every task says so', () async {
    final bloc = await readyBloc();

    bloc.add(const ClientBankTransferSubmitted());
    final state = await bloc.stream.firstWhere((s) => s.isSent);
    expect(repository.submitted.map((s) => s.$1), ['pay-t-1', 'pay-t-2']);
    expect(state.isSending, isFalse);
    await bloc.close();
  });

  test(
    'a sending that stops part way says what went; again sends the rest',
    () async {
      repository.failingPayments['pay-t-2'] = const NetworkFailure();
      final bloc = await readyBloc();

      bloc.add(const ClientBankTransferSubmitted());
      final partial = await bloc.stream.firstWhere((s) => s.outcome != null);
      expect(partial.outcome?.sent.map((t) => t.id), ['t-1']);
      expect(partial.outcome?.notSent.map((t) => t.id), ['t-2']);
      expect(partial.message?.key, 'errors.network');
      expect(partial.isSent, isFalse);
      // Read again: t-1 waits for the contractor now; only t-2 is to pay.
      expect(partial.transfer?.tasks.map((t) => t.id), ['t-2']);
      expect(partial.transfer?.skippedTasks.map((t) => t.id), ['t-1']);

      repository.failingPayments.clear();
      bloc.add(const ClientBankTransferSubmitted());
      await bloc.stream.firstWhere((s) => s.isSent);
      expect(repository.submitted.map((s) => s.$1), ['pay-t-1', 'pay-t-2']);
      await bloc.close();
    },
  );

  test('fails when the transfer cannot load', () async {
    repository.bankDetailsResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const ClientBankTransferFetched(selection));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == ClientBankTransferStatus.failure,
    );
    expect(state.failure, isA<NetworkFailure>());
    expect(state.transfer, isNull);
    await bloc.close();
  });
}
