import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_actions.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/orders_repository.dart';

/// «تم الشحن»: the seller marks a paid order as shipped. Anything else is
/// refused here, before `mark_order_shipped()`, whose refusal has no code.
class MarkOrderShippedUseCase implements UseCase<void, MarketplaceOrder> {
  const MarkOrderShippedUseCase(this._orders);

  final OrdersRepository _orders;

  @override
  Future<Result<void>> call(MarketplaceOrder order) async {
    if (!OrderActions.of(order).canShip) {
      return const Failed(
        ValidationFailure('marketplace.order_details.error_cannot_ship'),
      );
    }
    return _orders.markShipped(order.id);
  }
}
