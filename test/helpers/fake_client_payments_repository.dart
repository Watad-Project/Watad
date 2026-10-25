import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/payments/client/client_payments_injection.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_details.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt.dart';
import 'package:watad/features/payments/client/domain/repositories/client_payments_repository.dart';

/// A hand-written [ClientPaymentsRepository]: it answers with the results
/// you set, and records every receipt sent (APP_ARCHITECTURE.md §16).
class FakeClientPaymentsRepository implements ClientPaymentsRepository {
  Result<List<ClientPaymentTask>> tasksResult = const Success([]);
  Result<ClientBankDetails?> bankDetailsResult = const Success(null);

  /// The payment stages whose transfer fails, with why.
  final Map<String, Failure> failingPayments = {};

  /// The receipts sent, as (payment id, receipt name), in order.
  final List<(String, String)> submitted = [];

  @override
  Future<Result<List<ClientPaymentTask>>> getTasks(String projectId) async =>
      tasksResult;

  @override
  Future<Result<List<ClientPaymentTask>>> getTasksByIds(
    String projectId,
    List<String> taskIds,
  ) async => switch (tasksResult) {
    Success(:final data) => Success([
      for (final task in data)
        if (taskIds.contains(task.id)) task,
    ]),
    Failed(:final failure) => Failed(failure),
  };

  @override
  Future<Result<ClientBankDetails?>> getBankDetails(String projectId) async =>
      bankDetailsResult;

  /// Like the server: a stage that took a receipt waits for the contractor.
  @override
  Future<Result<void>> submitBankTransfer(
    String paymentId,
    ClientReceipt receipt,
  ) async {
    final failure = failingPayments[paymentId];
    if (failure != null) return Failed(failure);
    submitted.add((paymentId, receipt.name));
    if (tasksResult case Success(:final data)) {
      tasksResult = Success([
        for (final task in data)
          task.paymentId == paymentId
              ? ClientPaymentTask(
                  id: task.id,
                  title: task.title,
                  status: task.status,
                  amount: task.amount,
                  paymentId: task.paymentId,
                  paymentStatus: PaymentStatus.processing,
                )
              : task,
      ]);
    }
    return const Success(null);
  }
}

/// For tests that open the payments routes: the real registrations, with
/// [repository] in place of Supabase. Reset getIt after the test.
void registerFakeClientPayments([FakeClientPaymentsRepository? repository]) {
  registerClientPaymentsDependencies(getIt);
  getIt
    ..unregister<ClientPaymentsRepository>()
    ..registerSingleton<ClientPaymentsRepository>(
      repository ?? FakeClientPaymentsRepository(),
    );
}
