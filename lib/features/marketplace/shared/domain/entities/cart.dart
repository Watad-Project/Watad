import 'dart:math';

import 'package:watad/features/marketplace/shared/domain/entities/cart_entry.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_seller_group.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';

/// The cart as the buyer sees it: the available lines grouped by seller,
/// in the order they were added, and the lines that can't be bought now.
class Cart {
  const Cart({this.groups = const [], this.unavailable = const []});

  /// The stored [lines] next to the listings the server has now ([items]):
  /// a quantity above the stock is cut to it, and a line takes the current
  /// price, noting the old quantity and price so the screen can say so.
  factory Cart.of(List<CartLine> lines, List<MarketplaceItem> items) {
    final byId = {for (final item in items) item.id: item};
    final bySeller = <String, List<CartEntry>>{};
    final sellers = <String, MarketplaceItem>{};
    final unavailable = <CartEntry>[];
    for (final line in lines) {
      final item = byId[line.itemId];
      final stored = CartEntry(line: line, item: item);
      if (item == null || !stored.isAvailable) {
        unavailable.add(stored);
        continue;
      }
      final quantity = min(line.quantity, item.stockQuantity);
      sellers[item.sellerId] ??= item;
      (bySeller[item.sellerId] ??= []).add(
        CartEntry(
          line: CartLine(
            itemId: line.itemId,
            quantity: quantity,
            priceWhenAdded: item.price,
          ),
          item: item,
          previousQuantity: quantity < line.quantity ? line.quantity : null,
          previousPrice: item.price == line.priceWhenAdded
              ? null
              : line.priceWhenAdded,
        ),
      );
    }
    return Cart(
      groups: [
        for (final MapEntry(key: sellerId, value: entries) in bySeller.entries)
          CartSellerGroup(
            sellerId: sellerId,
            sellerName: sellers[sellerId]!.sellerName,
            sellerAvatarUrl: sellers[sellerId]!.sellerAvatarUrl,
            sellerIsVerified: sellers[sellerId]!.sellerIsVerifiedBusiness,
            entries: entries,
          ),
      ],
      unavailable: unavailable,
    );
  }

  final List<CartSellerGroup> groups;

  /// Hidden, deleted, removed, sold out, or my own: shown with «إزالة» and
  /// never counted.
  final List<CartEntry> unavailable;

  List<CartEntry> get entries => [
    for (final group in groups) ...group.entries,
    ...unavailable,
  ];

  /// What to store: the available lines with their new quantity and
  /// price, and the unavailable ones as they were.
  List<CartLine> get lines => [for (final entry in entries) entry.line];

  bool get isEmpty => groups.isEmpty && unavailable.isEmpty;

  /// A quantity or a price changed since the lines were stored.
  bool get hasChanges =>
      entries.any((entry) => entry.quantityLowered || entry.priceChanged);

  CartSellerGroup? groupOf(String sellerId) =>
      groups.where((group) => group.sellerId == sellerId).firstOrNull;

  /// This cart with [itemId] set to [quantity].
  Cart withQuantity(String itemId, int quantity) => Cart(
    groups: [
      for (final group in groups)
        CartSellerGroup(
          sellerId: group.sellerId,
          sellerName: group.sellerName,
          sellerAvatarUrl: group.sellerAvatarUrl,
          sellerIsVerified: group.sellerIsVerified,
          entries: [
            for (final entry in group.entries)
              entry.line.itemId == itemId
                  ? entry.withQuantity(quantity)
                  : entry,
          ],
        ),
    ],
    unavailable: unavailable,
  );

  /// This cart without [itemId]; a seller left with nothing goes.
  Cart without(String itemId) => Cart(
    groups: [
      for (final group in groups)
        if (group.entries.any((entry) => entry.line.itemId != itemId))
          CartSellerGroup(
            sellerId: group.sellerId,
            sellerName: group.sellerName,
            sellerAvatarUrl: group.sellerAvatarUrl,
            sellerIsVerified: group.sellerIsVerified,
            entries: [
              for (final entry in group.entries)
                if (entry.line.itemId != itemId) entry,
            ],
          ),
    ],
    unavailable: [
      for (final entry in unavailable)
        if (entry.line.itemId != itemId) entry,
    ],
  );
}
