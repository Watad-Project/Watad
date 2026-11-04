import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_entry.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_problem.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_address.dart';

/// One seller's group, checked against the server right before paying.
class CheckoutReview {
  const CheckoutReview({
    required this.sellerId,
    required this.sellerName,
    required this.entries,
    required this.addresses,
    required this.unpaidOrderCount,
    this.problem,
  });

  final String sellerId;
  final String sellerName;

  /// The seller's lines at the current prices, cut to the stock.
  final List<CartEntry> entries;

  /// Where the order can go: the buyer's saved addresses.
  final List<MarketplaceAddress> addresses;

  /// The buyer's orders still awaiting payment.
  final int unpaidOrderCount;

  /// Why this group can't check out now; null when it can.
  final CheckoutProblem? problem;

  Money get total =>
      entries.fold(const Money.zero(), (sum, entry) => sum + entry.subtotal);

  /// A quantity or a price changed since the buyer added the item.
  bool get hasChanges =>
      entries.any((entry) => entry.quantityLowered || entry.priceChanged);
}
