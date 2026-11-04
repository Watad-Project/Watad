import 'package:watad/core/enums/order_status.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_status_change.dart';

class OrderStatusChangeModel extends OrderStatusChange {
  const OrderStatusChangeModel({
    required super.newStatus,
    required super.changedAt,
    super.oldStatus,
  });

  /// Maps a `v_order_status_history` row.
  factory OrderStatusChangeModel.fromJson(Map<String, dynamic> json) {
    final oldStatus = json['old_status'] as String?;
    return OrderStatusChangeModel(
      oldStatus: oldStatus == null ? null : OrderStatus.fromJson(oldStatus),
      newStatus: OrderStatus.fromJson(json['new_status'] as String),
      changedAt: DateTime.parse(json['changed_at'] as String),
    );
  }
}
