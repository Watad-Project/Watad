import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_actions.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_line.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_status_change.dart';

/// Everything the order details page shows: the order, its products and
/// its timeline, oldest change first.
class OrderDetails {
  const OrderDetails({
    required this.order,
    this.lines = const [],
    this.history = const [],
  });

  final MarketplaceOrder order;
  final List<OrderLine> lines;
  final List<OrderStatusChange> history;

  OrderActions get actions => OrderActions.of(order);
}
