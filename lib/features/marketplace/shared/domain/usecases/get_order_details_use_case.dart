import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_details.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/orders_repository.dart';

/// One of my orders with its products and timeline, for its buyer and its
/// seller alike; not found when I'm neither.
class GetOrderDetailsUseCase implements UseCase<OrderDetails, String> {
  const GetOrderDetailsUseCase(this._orders);

  final OrdersRepository _orders;

  @override
  Future<Result<OrderDetails>> call(String orderId) async {
    final (order, lines, history) = await (
      _orders.getOrder(orderId),
      _orders.getOrderLines(orderId),
      _orders.getStatusHistory(orderId),
    ).wait;
    return switch ((order, lines, history)) {
      (Failed(:final failure), _, _) ||
      (_, Failed(:final failure), _) ||
      (_, _, Failed(:final failure)) => Failed(failure),
      (Success(data: null), _, _) => const Failed(NotFoundFailure()),
      (
        Success(data: final order?),
        Success(data: final lines),
        Success(data: final history),
      ) =>
        Success(OrderDetails(order: order, lines: lines, history: history)),
    };
  }
}
