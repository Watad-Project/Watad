import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/cart_repository.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';

/// The cart screen: the stored lines next to the listings as the server has
/// them now, grouped by seller. A quantity above the new stock is lowered,
/// and a line takes the new price; both are saved, and the returned cart
/// says what changed.
class GetCartUseCase implements UseCase<Cart, NoParams> {
  const GetCartUseCase(this._cart, this._items);

  final CartRepository _cart;
  final MarketplaceRepository _items;

  @override
  Future<Result<Cart>> call([NoParams params = const NoParams()]) async {
    final List<CartLine> lines;
    switch (await _cart.getLines()) {
      case Success(:final data):
        lines = data;
      case Failed(:final failure):
        return Failed(failure);
    }
    if (lines.isEmpty) return const Success(Cart());

    final List<MarketplaceItem> items;
    switch (await _items.getItemsByIds([
      for (final line in lines) line.itemId,
    ])) {
      case Success(:final data):
        items = data;
      case Failed(:final failure):
        return Failed(failure);
    }

    final cart = Cart.of(lines, items);
    if (!cart.hasChanges) return Success(cart);
    return switch (await _cart.saveLines(cart.lines)) {
      Success() => Success(cart),
      Failed(:final failure) => Failed(failure),
    };
  }
}
