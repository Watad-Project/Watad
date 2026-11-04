import 'package:watad/core/enums/order_status.dart';

/// One step of an order's timeline (`v_order_status_history`). The
/// change's note and who made it are never read.
class OrderStatusChange {
  const OrderStatusChange({
    required this.newStatus,
    required this.changedAt,
    this.oldStatus,
  });

  /// Null on the first row, when the order was created.
  final OrderStatus? oldStatus;
  final OrderStatus newStatus;
  final DateTime changedAt;
}
