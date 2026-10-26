import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/entities/client_task_payability.dart';

/// The total of the tasks the client selected to pay (GRA-50), added up in
/// halalas so it never drifts. Only tasks that can be paid count: a list
/// with one that can't is refused.
class ClientCalculatePaymentTotalUseCase
    implements UseCase<Money, List<ClientPaymentTask>> {
  const ClientCalculatePaymentTotalUseCase();

  @override
  Future<Result<Money>> call(List<ClientPaymentTask> params) async {
    var total = const Money.zero();
    for (final task in params) {
      final amount = task.amount;
      if (task.payability != ClientTaskPayability.payable || amount == null) {
        return const Failed(ValidationFailure('validation.invalid'));
      }
      total += amount;
    }
    return Success(total);
  }
}
