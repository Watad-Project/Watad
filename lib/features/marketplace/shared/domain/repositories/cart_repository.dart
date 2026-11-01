import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';

/// The signed-in buyer's cart, kept on the phone. Another account on the
/// same phone has its own cart.
abstract interface class CartRepository {
  /// The lines in the order they were added; empty when there are none.
  Future<Result<List<CartLine>>> getLines();

  /// Replaces the stored cart with [lines].
  Future<Result<void>> saveLines(List<CartLine> lines);
}
