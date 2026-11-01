/// What «أضف للسلة» did: how many of the item the cart holds now, and
/// whether it was cut to the stock.
class CartAddition {
  const CartAddition({required this.quantityInCart, required this.isCapped});

  final int quantityInCart;

  /// The cart and the new quantity together were more than the stock, so
  /// the line holds only what is in stock.
  final bool isCapped;
}
