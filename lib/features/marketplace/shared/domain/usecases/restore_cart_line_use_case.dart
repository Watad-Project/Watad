import 'dart:math';

import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/cart_repository.dart';

/// «تراجع» after «إزالة»: puts the line back where it was, unless the item
/// is in the cart again already.
class RestoreCartLineUseCase
    implements UseCase<void, ({CartLine line, int index})> {
  const RestoreCartLineUseCase(this._cart);

  final CartRepository _cart;

  @override
  Future<Result<void>> call(({CartLine line, int index}) params) async {
    final List<CartLine> lines;
    switch (await _cart.getLines()) {
      case Success(:final data):
        lines = data;
      case Failed(:final failure):
        return Failed(failure);
    }
    if (lines.any((line) => line.itemId == params.line.itemId)) {
      return const Success(null);
    }
    return _cart.saveLines(
      [...lines]..insert(min(params.index, lines.length), params.line),
    );
  }
}
