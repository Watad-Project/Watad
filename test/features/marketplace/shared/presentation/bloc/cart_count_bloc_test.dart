import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_cart_count_use_case.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/cart_count_bloc.dart';

import '../../../../../helpers/fake_cart_repository.dart';

void main() {
  test('counts the lines of the cart', () async {
    final cart = FakeCartRepository([
      const CartLine(
        itemId: 'a',
        quantity: 5,
        priceWhenAdded: Money.halalas(1),
      ),
      const CartLine(
        itemId: 'b',
        quantity: 1,
        priceWhenAdded: Money.halalas(1),
      ),
    ]);
    final bloc = CartCountBloc(GetCartCountUseCase(cart))
      ..add(const CartCountRefreshed());

    final state = await bloc.stream.first;
    expect(state.count, 2);
    expect(state.failure, isNull);
    await bloc.close();
  });

  test('a failure keeps the last count and says why', () async {
    final cart = FakeCartRepository([
      const CartLine(
        itemId: 'a',
        quantity: 1,
        priceWhenAdded: Money.halalas(1),
      ),
    ]);
    final bloc = CartCountBloc(GetCartCountUseCase(cart))
      ..add(const CartCountRefreshed());
    await bloc.stream.first;

    cart.linesResult = const Failed(UnknownFailure());
    bloc.add(const CartCountRefreshed());
    final state = await bloc.stream.first;
    expect(state.count, 1);
    expect(state.failure, isA<UnknownFailure>());
    await bloc.close();
  });
}
