/// Why a seller's group can't check out. The app finds these itself before
/// calling `checkout()`, whose errors for them have no code
/// (APP_ARCHITECTURE.md §13).
enum CheckoutProblem {
  /// Nothing of this seller's is in the cart.
  empty('marketplace.checkout.error_empty'),

  /// A line is hidden, deleted, removed or sold out.
  unavailable('marketplace.checkout.error_unavailable'),

  /// A line asks for more than the stock.
  notEnoughStock('marketplace.checkout.error_not_enough_stock'),

  /// A line is the buyer's own item.
  ownItem('marketplace.checkout.error_own_item'),

  /// The lines come from more than one seller.
  mixedSellers('marketplace.checkout.error_mixed_sellers'),

  /// More than 50 lines.
  tooManyLines('marketplace.checkout.error_too_many_lines'),

  /// 5 unpaid orders already.
  tooManyUnpaidOrders('marketplace.checkout.error_too_many_unpaid'),

  /// A price or the stock changed after the checkout page loaded it.
  changed('marketplace.checkout.error_changed');

  const CheckoutProblem(this.messageKey);

  /// The translation key that explains it.
  final String messageKey;
}
