import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_entry.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_problem.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_review.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_address.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/cart_repository.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/orders_repository.dart';

/// The checkout page for one seller's group: its lines re-read from the
/// server (current prices, quantities cut to the stock, saved to the cart),
/// the buyer's addresses, and anything that stops the checkout. The app
/// checks what `checkout()` would refuse without a code, so it can say why
/// (APP_ARCHITECTURE.md §13).
class ReviewCheckoutUseCase implements UseCase<CheckoutReview, String> {
  const ReviewCheckoutUseCase(this._cart, this._items, this._orders);

  final CartRepository _cart;
  final MarketplaceRepository _items;
  final OrdersRepository _orders;

  /// `checkout()`'s own limits.
  static const int maxLines = 50;
  static const int maxUnpaidOrders = 5;

  @override
  Future<Result<CheckoutReview>> call(String sellerId) async {
    final List<CartLine> lines;
    switch (await _cart.getLines()) {
      case Success(:final data):
        lines = data;
      case Failed(:final failure):
        return Failed(failure);
    }

    final List<MarketplaceItem> items;
    switch (lines.isEmpty
        ? const Success(<MarketplaceItem>[])
        : await _items.getItemsByIds([for (final line in lines) line.itemId])) {
      case Success(:final data):
        items = data;
      case Failed(:final failure):
        return Failed(failure);
    }

    final cart = Cart.of(lines, items);
    if (cart.hasChanges) {
      if (await _cart.saveLines(cart.lines) case Failed(:final failure)) {
        return Failed(failure);
      }
    }

    final List<MarketplaceAddress> addresses;
    switch (await _orders.getMyAddresses()) {
      case Success(:final data):
        addresses = data;
      case Failed(:final failure):
        return Failed(failure);
    }
    final int unpaid;
    switch (await _orders.countMyUnpaidOrders()) {
      case Success(:final data):
        unpaid = data;
      case Failed(:final failure):
        return Failed(failure);
    }

    final group = cart.groupOf(sellerId);
    final entries = group?.entries ?? const <CartEntry>[];
    final blocked = [
      for (final entry in cart.unavailable)
        if (entry.item?.sellerId == sellerId) entry,
    ];
    return Success(
      CheckoutReview(
        sellerId: sellerId,
        sellerName:
            group?.sellerName ?? blocked.firstOrNull?.item?.sellerName ?? '',
        entries: entries,
        addresses: addresses,
        unpaidOrderCount: unpaid,
        problem: _problemOf(entries, blocked, unpaid),
      ),
    );
  }

  static CheckoutProblem? _problemOf(
    List<CartEntry> entries,
    List<CartEntry> blocked,
    int unpaid,
  ) {
    if (blocked.any((entry) => entry.item?.isMine ?? false)) {
      return CheckoutProblem.ownItem;
    }
    if (blocked.isNotEmpty) return CheckoutProblem.unavailable;
    if (entries.isEmpty) return CheckoutProblem.empty;
    if (entries.length > maxLines) return CheckoutProblem.tooManyLines;
    if (unpaid >= maxUnpaidOrders) return CheckoutProblem.tooManyUnpaidOrders;
    return null;
  }
}
