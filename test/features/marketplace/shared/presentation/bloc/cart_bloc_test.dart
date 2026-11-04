import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_cart_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/remove_from_cart_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/restore_cart_line_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/set_cart_quantity_use_case.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/cart_bloc.dart';

import '../../../../../helpers/fake_cart_repository.dart';
import '../../../../../helpers/fake_marketplace_repository.dart';

void main() {
  late FakeMarketplaceRepository items;
  late FakeCartRepository cart;

  CartBloc buildBloc() => CartBloc(
    GetCartUseCase(cart, items),
    SetCartQuantityUseCase(cart),
    RemoveFromCartUseCase(cart),
    RestoreCartLineUseCase(cart),
  );

  Future<CartState> loaded(CartBloc bloc) => bloc.stream.firstWhere(
    (s) => s.status == CartStatus.success || s.status == CartStatus.failure,
  );

  setUp(() {
    items = FakeMarketplaceRepository()..items = [fakeSteelItem, fakeTilesItem];
    cart = FakeCartRepository([
      const CartLine(
        itemId: 'i-steel',
        quantity: 1,
        priceWhenAdded: Money.halalas(250000),
      ),
      const CartLine(
        itemId: 'i-tiles',
        quantity: 2,
        priceWhenAdded: Money.halalas(6500),
      ),
    ]);
  });

  test('loads two seller groups', () async {
    final bloc = buildBloc()..add(const CartFetched());

    final state = await loaded(bloc);
    expect(state.status, CartStatus.success);
    expect(state.cart.groups, hasLength(2));
    await bloc.close();
  });

  test('changes a quantity, removes a line, and undoes it', () async {
    final bloc = buildBloc()..add(const CartFetched());
    await loaded(bloc);

    bloc.add(const CartQuantityChanged('i-tiles', 5));
    final changed = await bloc.stream.first;
    expect(changed.cart.groupOf('u-tiles')?.total, const Money.halalas(32500));
    // The screen changes at once; the save follows.
    await pumpEventQueue();
    expect(cart.lines.last.quantity, 5);

    bloc.add(const CartLineRemoved('i-steel'));
    final removed = await bloc.stream.firstWhere((s) => s.lastRemoved != null);
    expect(removed.cart.groupOf('u-seller'), isNull);
    expect(cart.lines.map((l) => l.itemId), ['i-tiles']);

    bloc.add(const CartLineRestored());
    final restored = await bloc.stream.firstWhere(
      (s) => s.status == CartStatus.success && s.cart.groups.length == 2,
    );
    expect(restored.lastRemoved, isNull);
    expect(cart.lines.map((l) => l.itemId), ['i-steel', 'i-tiles']);
    await bloc.close();
  });

  test('a first load that fails shows the error', () async {
    items.itemsByIdsResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const CartFetched());

    final state = await loaded(bloc);
    expect(state.status, CartStatus.failure);
    expect(state.failure, isA<NetworkFailure>());
    await bloc.close();
  });

  test('a failed change puts the quantity back and says why', () async {
    final bloc = buildBloc()..add(const CartFetched());
    await loaded(bloc);

    cart.saveResult = const Failed(UnknownFailure());
    bloc.add(const CartQuantityChanged('i-tiles', 5));
    final state = await bloc.stream.firstWhere((s) => s.actionFailure != null);
    expect(state.cart.groupOf('u-tiles')?.entries.single.line.quantity, 2);
    await bloc.close();
  });
}
