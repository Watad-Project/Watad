import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';

/// One cart line next to its listing as the server has it now.
class CartEntry {
  const CartEntry({
    required this.line,
    this.item,
    this.previousQuantity,
    this.previousPrice,
  });

  /// For an available item: its quantity cut to the stock and the current
  /// price. Otherwise: the line as it was stored.
  final CartLine line;

  /// Null when the view has no row any more (hidden or deleted).
  final MarketplaceItem? item;

  /// The quantity before this refresh cut it to the new stock.
  final int? previousQuantity;

  /// The price when the item was added, when it has changed since.
  final Money? previousPrice;

  /// Still on the market, in stock, and not mine.
  bool get isAvailable {
    final item = this.item;
    return item != null &&
        item.isActive &&
        !item.isRemoved &&
        item.stockQuantity > 0 &&
        !item.isMine;
  }

  bool get quantityLowered => previousQuantity != null;
  bool get priceChanged => previousPrice != null;

  /// The line's amount at the current price.
  Money get subtotal => Money.halalas(
    (item?.price ?? line.priceWhenAdded).halalas * line.quantity,
  );

  /// This entry with another quantity; the "lowered" note goes away.
  CartEntry withQuantity(int quantity) => CartEntry(
    line: CartLine(
      itemId: line.itemId,
      quantity: quantity,
      priceWhenAdded: line.priceWhenAdded,
    ),
    item: item,
    previousPrice: previousPrice,
  );
}
