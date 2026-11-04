import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/cart_repository.dart';

/// A hand-written [CartRepository] that keeps the cart in [lines]
/// (APP_ARCHITECTURE.md §16).
class FakeCartRepository implements CartRepository {
  FakeCartRepository([List<CartLine>? lines]) : lines = lines ?? [];

  List<CartLine> lines;

  /// Answers [getLines] instead, when set.
  Result<List<CartLine>>? linesResult;

  /// Answers [saveLines] instead, when set; the cart then stays as it was.
  Result<void>? saveResult;

  /// Every cart [saveLines] was given, in order.
  final List<List<CartLine>> saved = [];

  @override
  Future<Result<List<CartLine>>> getLines() async =>
      linesResult ?? Success(List<CartLine>.unmodifiable(lines));

  @override
  Future<Result<void>> saveLines(List<CartLine> lines) async {
    if (saveResult case final result?) return result;
    this.lines = List.of(lines);
    saved.add(List.unmodifiable(lines));
    return const Success(null);
  }
}
