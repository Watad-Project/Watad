import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_details.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_transfer.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_selection.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/entities/client_task_payability.dart';
import 'package:watad/features/payments/client/domain/repositories/client_payments_repository.dart';

/// What the bank transfer screen shows (GRA-52): the selected tasks read
/// again, so the ones paid or sent meanwhile drop out of the payment; what
/// the others add up to, in halalas; and the contractor's account.
class ClientGetBankTransferUseCase
    implements UseCase<ClientBankTransfer, ClientPaymentSelection> {
  const ClientGetBankTransferUseCase(this._repository);

  final ClientPaymentsRepository _repository;

  @override
  Future<Result<ClientBankTransfer>> call(ClientPaymentSelection params) async {
    if (params.taskIds.isEmpty) {
      return const Failed(ValidationFailure('validation.invalid'));
    }
    final (tasks, bankDetails) = await (
      _repository.getTasksByIds(params.projectId, params.taskIds),
      _repository.getBankDetails(params.projectId),
    ).wait;
    return switch ((tasks, bankDetails)) {
      (Success(data: final tasks), Success(data: final bankDetails)) => Success(
        _transfer(tasks, bankDetails),
      ),
      (Failed(:final failure), _) ||
      (_, Failed(:final failure)) => Failed(failure),
    };
  }

  static ClientBankTransfer _transfer(
    List<ClientPaymentTask> tasks,
    ClientBankDetails? bankDetails,
  ) {
    final payable = [
      for (final task in tasks)
        if (task.payability == ClientTaskPayability.payable) task,
    ];
    var total = const Money.zero();
    for (final task in payable) {
      total += task.amount ?? const Money.zero();
    }
    return ClientBankTransfer(
      tasks: payable,
      skippedTasks: [
        for (final task in tasks)
          if (task.payability != ClientTaskPayability.payable) task,
      ],
      total: total,
      bankDetails: bankDetails,
    );
  }
}
