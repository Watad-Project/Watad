import 'package:watad/core/utils/money.dart';

/// One line of the buyer's cart, as kept on the phone: the item, how many,
/// and its price when it was added, so the cart can say «تغيّر السعر».
///
/// Everything shown (name, photo, seller, current price, stock) is read
/// from `v_marketplace_items` again: the stored copy is never trusted for
/// money.
class CartLine {
  const CartLine({
    required this.itemId,
    required this.quantity,
    required this.priceWhenAdded,
  });

  final String itemId;
  final int quantity;
  final Money priceWhenAdded;
}
