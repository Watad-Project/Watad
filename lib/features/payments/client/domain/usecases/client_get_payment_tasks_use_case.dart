import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/repositories/client_payments_repository.dart';

/// The tasks of one of the client's projects with their payment stages, in
/// timeline order; the parameter is the project's id. Rejected tasks are
/// left out: they aren't part of the work, so they're never paid.
class ClientGetPaymentTasksUseCase
    implements UseCase<List<ClientPaymentTask>, String> {
  const ClientGetPaymentTasksUseCase(this._repository);

  final ClientPaymentsRepository _repository;

  @override
  Future<Result<List<ClientPaymentTask>>> call(String params) async {
    final result = await _repository.getTasks(params);
    return switch (result) {
      Success(:final data) => Success([
        for (final task in data)
          if (task.status != TaskStatus.rejected) task,
      ]),
      Failed(:final failure) => Failed(failure),
    };
  }
}
