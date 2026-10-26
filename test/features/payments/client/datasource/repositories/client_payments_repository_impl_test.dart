import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/payments/client/datasource/models/client_bank_details_model.dart';
import 'package:watad/features/payments/client/datasource/models/client_payment_task_model.dart';
import 'package:watad/features/payments/client/datasource/remote/client_payments_remote_data_source.dart';
import 'package:watad/features/payments/client/datasource/repositories/client_payments_repository_impl.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_details.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt.dart';

class _FakeClientPaymentsRemoteDataSource
    implements ClientPaymentsRemoteDataSource {
  Object? error;
  List<ClientPaymentTaskModel> tasks = [];
  ClientBankDetailsModel? bankDetails;

  /// The receipts sent, as (payment id, receipt name).
  final List<(String, String)> submitted = [];

  @override
  Future<List<ClientPaymentTaskModel>> getTasks(String projectId) async {
    final err = error;
    if (err != null) throw err;
    return tasks;
  }

  @override
  Future<List<ClientPaymentTaskModel>> getTasksByIds(
    String projectId,
    List<String> taskIds,
  ) async {
    final err = error;
    if (err != null) throw err;
    return [
      for (final task in tasks)
        if (taskIds.contains(task.id)) task,
    ];
  }

  @override
  Future<ClientBankDetailsModel?> getBankDetails(String projectId) async {
    final err = error;
    if (err != null) throw err;
    return bankDetails;
  }

  @override
  Future<String> submitBankTransfer(
    String paymentId,
    ClientReceipt receipt,
  ) async {
    final err = error;
    if (err != null) throw err;
    submitted.add((paymentId, receipt.name));
    return 'bt-1';
  }
}

void main() {
  final receipt = ClientReceipt(
    bytes: Uint8List.fromList([1, 2, 3]),
    name: 'receipt.pdf',
  );
  final task = ClientPaymentTaskModel.fromJson(const {
    'id': 't-1',
    'title': 'اللياسة الداخلية',
    'amount': 15000,
    'status': 'approved',
    'payment_id': 'pay-1',
    'payment_status': 'pending',
  });

  test('getTasksByIds returns the selected tasks only', () async {
    final remote = _FakeClientPaymentsRemoteDataSource()..tasks = [task];

    final result = await ClientPaymentsRepositoryImpl(remote)
        .getTasksByIds('p-3', ['t-1', 't-9']);

    expect((result as Success<List<ClientPaymentTask>>).data.single.id, 't-1');
  });

  test('getBankDetails returns null when the contractor has none', () async {
    final result = await ClientPaymentsRepositoryImpl(
      _FakeClientPaymentsRemoteDataSource(),
    ).getBankDetails('p-3');

    expect((result as Success<ClientBankDetails?>).data, isNull);
  });

  test('submitBankTransfer sends the receipt for the stage', () async {
    final remote = _FakeClientPaymentsRemoteDataSource();

    final result = await ClientPaymentsRepositoryImpl(remote)
        .submitBankTransfer('pay-1', receipt);

    expect(result, isA<Success<void>>());
    expect(remote.submitted, [('pay-1', 'receipt.pdf')]);
  });

  test('submitBankTransfer returns Failed when the server refuses', () async {
    final remote = _FakeClientPaymentsRemoteDataSource()
      ..error = Exception(
        'This stage is already paid, cancelled or being paid',
      );

    final result = await ClientPaymentsRepositoryImpl(remote)
        .submitBankTransfer('pay-1', receipt);

    expect(result, isA<Failed<void>>());
  });
}
