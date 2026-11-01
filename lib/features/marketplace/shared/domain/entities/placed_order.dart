/// A new order from `checkout()`.
class PlacedOrder {
  const PlacedOrder({required this.orderId, required this.cartCleared});

  final String orderId;

  /// Whether its lines left the cart. The order exists either way; when it
  /// is false the buyer removes them by hand.
  final bool cartCleared;
}
