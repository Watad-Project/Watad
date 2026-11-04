import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/cart_repository.dart';

/// The − or + of a cart line. The screen keeps it between 1 and the stock.
class SetCartQuantityUseCase
    implements UseCase<void, ({String itemId, int quantity})> {
  const SetCartQuantityUseCase(this._cart);

  final CartRepository _cart;

  @override
  Future<Result<void>> call(({String itemId, int quantity}) params) async {
    final (:itemId, :quantity) = params;
    if (quantity < 1) {
      return const Failed(ValidationFailure('marketplace.cart.error_quantity'));
    }
    final List<CartLine> lines;
    switch (await _cart.getLines()) {
      case Success(:final data):
        lines = data;
      case Failed(:final failure):
        return Failed(failure);
    }
    if (!lines.any((line) => line.itemId == itemId)) {
      return const Failed(NotFoundFailure());
    }
    return _cart.saveLines([
      for (final line in lines)
        line.itemId == itemId
            ? CartLine(
                itemId: itemId,
                quantity: quantity,
                priceWhenAdded: line.priceWhenAdded,
              )
            : line,
    ]);
  }
}
