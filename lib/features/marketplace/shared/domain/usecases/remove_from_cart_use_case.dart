import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/cart_repository.dart';

/// «إزالة»: takes a line out of the cart, and returns it with its place so
/// «تراجع» can put it back.
class RemoveFromCartUseCase
    implements UseCase<({CartLine line, int index}), String> {
  const RemoveFromCartUseCase(this._cart);

  final CartRepository _cart;

  @override
  Future<Result<({CartLine line, int index})>> call(String itemId) async {
    final List<CartLine> lines;
    switch (await _cart.getLines()) {
      case Success(:final data):
        lines = data;
      case Failed(:final failure):
        return Failed(failure);
    }
    final index = lines.indexWhere((line) => line.itemId == itemId);
    if (index == -1) return const Failed(NotFoundFailure());
    final removed = (line: lines[index], index: index);
    return switch (await _cart.saveLines([...lines]..removeAt(index))) {
      Success() => Success(removed),
      Failed(:final failure) => Failed(failure),
    };
  }
}
