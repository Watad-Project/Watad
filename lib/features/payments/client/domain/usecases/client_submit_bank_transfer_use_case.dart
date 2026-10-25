import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_transfer_outcome.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_transfer_request.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/entities/client_task_payability.dart';
import 'package:watad/features/payments/client/domain/repositories/client_payments_repository.dart';

/// Sends the receipt for the selected tasks (GRA-52). Each task's payment
/// stage takes its own bank transfer, so the same receipt is uploaded for
/// each stage and submitted, one after the other.
///
/// It reads the tasks again first and sends only the stages still waiting
/// for money, so sending again after a failure never sends a stage twice.
/// It stops at the first stage that fails; the outcome says which tasks
/// were sent and which weren't.
class ClientSubmitBankTransferUseCase
    implements UseCase<ClientBankTransferOutcome, ClientBankTransferRequest> {
  const ClientSubmitBankTransferUseCase(this._repository);

  final ClientPaymentsRepository _repository;

  @override
  Future<Result<ClientBankTransferOutcome>> call(
    ClientBankTransferRequest params,
  ) async {
    final receipt = params.receipt;
    if (receipt.problem case final problem?) {
      return Failed(ValidationFailure(problem.messageKey));
    }
    final selection = params.selection;
    final List<ClientPaymentTask> tasks;
    switch (await _repository.getTasksByIds(
      selection.projectId,
      selection.taskIds,
    )) {
      case Success(:final data):
        tasks = data;
      case Failed(:final failure):
        return Failed(failure);
    }

    final waiting = [
      for (final task in tasks)
        if (task.payability == ClientTaskPayability.payable) task,
    ];
    final sent = <ClientPaymentTask>[];
    for (var i = 0; i < waiting.length; i++) {
      final paymentId = waiting[i].paymentId;
      if (paymentId == null) continue;
      final result = await _repository.submitBankTransfer(paymentId, receipt);
      if (result case Failed(:final failure)) {
        return Success(
          ClientBankTransferOutcome(
            sent: sent,
            notSent: waiting.sublist(i),
            failure: failure,
          ),
        );
      }
      sent.add(waiting[i]);
    }
    return Success(ClientBankTransferOutcome(sent: sent, notSent: const []));
  }
}
