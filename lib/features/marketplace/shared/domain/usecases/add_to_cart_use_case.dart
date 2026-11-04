import 'dart:math';

import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_addition.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/cart_repository.dart';

/// «أضف للسلة»: adds [quantity] of an item to the cart. An item already in
/// the cart gets the quantity added to its line, cut to the stock, and
/// takes the price shown now.
class AddToCartUseCase
    implements UseCase<CartAddition, ({MarketplaceItem item, int quantity})> {
  const AddToCartUseCase(this._repository);

  final CartRepository _repository;

  @override
  Future<Result<CartAddition>> call(
    ({MarketplaceItem item, int quantity}) params,
  ) async {
    final (:item, :quantity) = params;
    if (item.isMine) {
      return const Failed(
        ValidationFailure('marketplace.item_details.error_own_item'),
      );
    }
    if (!item.isActive || item.isRemoved || item.stockQuantity <= 0) {
      return const Failed(
        ValidationFailure('marketplace.item_details.error_unavailable'),
      );
    }
    if (quantity < 1 || quantity > item.stockQuantity) {
      return const Failed(
        ValidationFailure('marketplace.item_details.error_quantity'),
      );
    }

    final current = await _repository.getLines();
    final List<CartLine> lines;
    switch (current) {
      case Success(:final data):
        lines = data;
      case Failed(:final failure):
        return Failed(failure);
    }

    final existing = lines.where((line) => line.itemId == item.id).firstOrNull;
    final wanted = (existing?.quantity ?? 0) + quantity;
    final line = CartLine(
      itemId: item.id,
      quantity: min(wanted, item.stockQuantity),
      priceWhenAdded: item.price,
    );
    final saved = await _repository.saveLines(
      existing == null
          ? [...lines, line]
          : [for (final other in lines) other.itemId == item.id ? line : other],
    );
    return switch (saved) {
      Success() => Success(
        CartAddition(
          quantityInCart: line.quantity,
          isCapped: wanted > item.stockQuantity,
        ),
      ),
      Failed(:final failure) => Failed(failure),
    };
  }
}
