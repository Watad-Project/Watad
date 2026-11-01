import 'package:watad/core/utils/money.dart';

/// One product of an order, as it was bought (`v_order_items`): the name
/// and price are copies, so editing the listing never changes them.
class OrderLine {
  const OrderLine({
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.itemId,
  });

  /// The listing it came from.
  final String? itemId;
  final String name;
  final int quantity;

  /// The price of one unit at checkout.
  final Money price;
  final Money subtotal;
}
