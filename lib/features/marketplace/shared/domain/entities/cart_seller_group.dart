import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_entry.dart';

/// One seller's available cart lines. An order has one seller
/// (`orders.seller_id`), so each group checks out on its own.
class CartSellerGroup {
  const CartSellerGroup({
    required this.sellerId,
    required this.sellerName,
    required this.entries,
    this.sellerAvatarUrl,
    this.sellerIsVerified = false,
  });

  final String sellerId;
  final String sellerName;
  final String? sellerAvatarUrl;
  final bool sellerIsVerified;
  final List<CartEntry> entries;

  /// The seller's total at the current prices.
  Money get total =>
      entries.fold(const Money.zero(), (sum, entry) => sum + entry.subtotal);
}
