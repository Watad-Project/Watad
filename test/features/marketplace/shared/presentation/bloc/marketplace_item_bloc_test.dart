import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/add_to_cart_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_item_bloc.dart';

import '../../../../../helpers/fake_cart_repository.dart';
import '../../../../../helpers/fake_marketplace_repository.dart';

void main() {
  late FakeMarketplaceRepository repository;
  late FakeCartRepository cart;

  MarketplaceItemBloc buildBloc() => MarketplaceItemBloc(
    GetMarketplaceItemUseCase(repository),
    AddToCartUseCase(cart),
  );

  Future<MarketplaceItemState> loaded(MarketplaceItemBloc bloc) => bloc.stream
      .firstWhere((s) => s.status != MarketplaceItemLoadStatus.loading);

  setUp(() {
    repository = FakeMarketplaceRepository();
    cart = FakeCartRepository();
  });

  test('loads an item, then adds the chosen quantity to the cart', () async {
    final bloc = buildBloc()..add(const MarketplaceItemFetched('i-steel'));
    final state = await loaded(bloc);
    expect(state.status, MarketplaceItemLoadStatus.success);
    expect(state.item?.id, 'i-steel');
    expect(state.quantity, 1);

    // The quantity stays between 1 and the stock (10).
    bloc.add(const MarketplaceItemQuantityChanged(15));
    await bloc.stream.first;
    expect(bloc.state.quantity, 10);
    bloc.add(const MarketplaceItemQuantityChanged(3));
    await bloc.stream.first;

    bloc.add(const MarketplaceItemAddedToCart());
    final added = await bloc.stream.firstWhere(
      (s) => s.addStatus == MarketplaceItemAddStatus.added,
    );
    expect(added.addition?.quantityInCart, 3);
    expect(cart.lines.single.quantity, 3);
    await bloc.close();
  });

  test('an item the view has no row for is unavailable', () async {
    final bloc = buildBloc()..add(const MarketplaceItemFetched('i-missing'));

    final state = await loaded(bloc);
    expect(state.status, MarketplaceItemLoadStatus.unavailable);
    expect(state.item, isNull);
    await bloc.close();
  });

  test('a failed load keeps the id for retry', () async {
    repository.itemResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const MarketplaceItemFetched('i-steel'));

    final state = await loaded(bloc);
    expect(state.status, MarketplaceItemLoadStatus.failure);
    expect(state.failure, isA<NetworkFailure>());
    expect(state.itemId, 'i-steel');
    await bloc.close();
  });

  test('a failed add says why and keeps the item', () async {
    cart.saveResult = const Failed(UnknownFailure());
    final bloc = buildBloc()..add(const MarketplaceItemFetched('i-steel'));
    await loaded(bloc);

    bloc.add(const MarketplaceItemAddedToCart());
    final failed = await bloc.stream.firstWhere(
      (s) => s.addStatus == MarketplaceItemAddStatus.failed,
    );
    expect(failed.addFailure, isA<UnknownFailure>());
    expect(failed.item?.id, 'i-steel');
    await bloc.close();
  });
}
