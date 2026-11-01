import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_actions.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/orders_repository.dart';

/// «إلغاء الطلب»: the buyer cancels an unpaid order, and its stock goes
/// back to the listings. Anything else is refused here, before
/// `cancel_order()`, whose refusals have no code.
class CancelOrderUseCase implements UseCase<void, MarketplaceOrder> {
  const CancelOrderUseCase(this._orders);

  final OrdersRepository _orders;

  @override
  Future<Result<void>> call(MarketplaceOrder order) async {
    if (!OrderActions.of(order).canCancel) {
      return const Failed(
        ValidationFailure('marketplace.order_details.error_cannot_cancel'),
      );
    }
    return _orders.cancelOrder(order.id);
  }
}
