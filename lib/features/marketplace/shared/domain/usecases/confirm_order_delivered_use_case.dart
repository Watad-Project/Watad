import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_actions.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/orders_repository.dart';

/// «تم الاستلام»: the buyer says a paid or shipped order arrived. Anything
/// else is refused here, before `confirm_order_delivered()`, whose refusal
/// has no code.
class ConfirmOrderDeliveredUseCase implements UseCase<void, MarketplaceOrder> {
  const ConfirmOrderDeliveredUseCase(this._orders);

  final OrdersRepository _orders;

  @override
  Future<Result<void>> call(MarketplaceOrder order) async {
    if (!OrderActions.of(order).canConfirmDelivery) {
      return const Failed(
        ValidationFailure('marketplace.order_details.error_cannot_confirm'),
      );
    }
    return _orders.confirmDelivered(order.id);
  }
}
