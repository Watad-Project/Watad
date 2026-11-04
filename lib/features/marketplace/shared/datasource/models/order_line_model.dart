import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_line.dart';

class OrderLineModel extends OrderLine {
  const OrderLineModel({
    required super.name,
    required super.quantity,
    required super.price,
    required super.subtotal,
    super.itemId,
  });

  /// Maps a `v_order_items` row.
  factory OrderLineModel.fromJson(Map<String, dynamic> json) => OrderLineModel(
    itemId: json['item_id'] as String?,
    name: json['item_name'] as String? ?? '',
    quantity: (json['quantity'] as num).toInt(),
    price: Money.fromJson(json['price_at_purchase'] as num),
    subtotal: Money.fromJson(json['subtotal'] as num),
  );
}
