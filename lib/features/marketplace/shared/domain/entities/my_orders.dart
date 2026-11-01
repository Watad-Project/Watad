import 'package:watad/core/enums/order_status.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';

/// «طلباتي»: the orders I bought, newest first, and how many each filter
/// chip holds. A null status is «الكل».
class MyOrders {
  const MyOrders([this.orders = const []]);

  /// «الكل», then one chip per status, in the order an order goes.
  static const List<OrderStatus?> filters = [null, ...OrderStatus.values];

  final List<MarketplaceOrder> orders;

  bool get isEmpty => orders.isEmpty;

  /// The orders under [status]; all of them when it is null.
  List<MarketplaceOrder> of(OrderStatus? status) => status == null
      ? orders
      : [
          for (final order in orders)
            if (order.status == status) order,
        ];

  int countOf(OrderStatus? status) => of(status).length;
}
