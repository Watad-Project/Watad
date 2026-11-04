import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/card_payment.dart';
import 'package:watad/features/marketplace/shared/domain/entities/payment_outcome.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/orders_repository.dart';

/// DEMO ONLY: pays an order with `simulate_order_payment()`. [succeed] is
/// false only for the decline test card; the server then refuses it as
/// `payment_declined` with no code, so it reaches the app as a
/// [ServerFailure]. The app sent false itself, so it knows that is a
/// decline, without reading the message (APP_ARCHITECTURE.md §13). Any
/// other failure stays a failure.
class PayOrderUseCase
    implements
        UseCase<
          PaymentOutcome,
          ({String orderId, CardPayment payment, bool succeed})
        > {
  const PayOrderUseCase(this._orders);

  final OrdersRepository _orders;

  @override
  Future<Result<PaymentOutcome>> call(
    ({String orderId, CardPayment payment, bool succeed}) params,
  ) async {
    final result = await _orders.simulatePayment(
      params.orderId,
      params.payment,
      succeed: params.succeed,
    );
    return switch (result) {
      Success() => const Success(PaymentOutcome.paid),
      Failed(failure: ServerFailure()) when !params.succeed => const Success(
        PaymentOutcome.declined,
      ),
      Failed(:final failure) => Failed(failure),
    };
  }
}
