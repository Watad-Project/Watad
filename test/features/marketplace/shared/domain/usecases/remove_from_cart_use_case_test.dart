import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/remove_from_cart_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/restore_cart_line_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/set_cart_quantity_use_case.dart';

import '../../../../../helpers/fake_cart_repository.dart';

void main() {
  late FakeCartRepository cart;

  CartLine line(String id, [int quantity = 1]) => CartLine(
    itemId: id,
    quantity: quantity,
    priceWhenAdded: const Money.halalas(100),
  );

  setUp(() => cart = FakeCartRepository([line('a'), line('b'), line('c')]));

  test('removing a line, then «تراجع», puts it back in its place', () async {
    final removed = await RemoveFromCartUseCase(cart)('b');

    expect(cart.lines.map((l) => l.itemId), ['a', 'c']);
    final data = (removed as Success<({CartLine line, int index})>).data;
    expect(data.index, 1);

    await RestoreCartLineUseCase(cart)(data);
    expect(cart.lines.map((l) => l.itemId), ['a', 'b', 'c']);
  });

  test('removing a line that is not there is not found', () async {
    final removed = await RemoveFromCartUseCase(cart)('x');

    expect(
      (removed as Failed<({CartLine line, int index})>).failure,
      isA<NotFoundFailure>(),
    );
  });

  test('a quantity changes in place; below 1 is refused', () async {
    final setQuantity = SetCartQuantityUseCase(cart);

    expect(await setQuantity((itemId: 'b', quantity: 4)), isA<Success<void>>());
    expect(cart.lines[1].quantity, 4);

    final refused = await setQuantity((itemId: 'b', quantity: 0));
    expect(
      (refused as Failed<void>).failure.messageKey,
      'marketplace.cart.error_quantity',
    );
  });
}
