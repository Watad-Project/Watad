import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/marketplace_category.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_sort.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_marketplace_items_use_case.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_bloc.dart';

import '../../../../../helpers/fake_marketplace_repository.dart';

void main() {
  late FakeMarketplaceRepository repository;

  MarketplaceBloc buildBloc() => MarketplaceBloc(
    GetMarketplaceItemsUseCase(repository),
    searchDelay: Duration.zero,
  );

  Future<MarketplaceState> settled(MarketplaceBloc bloc) =>
      bloc.stream.firstWhere((s) => s.status == MarketplaceStatus.success);

  setUp(() => repository = FakeMarketplaceRepository());

  test('loads the first page sorted newest first', () async {
    final bloc = buildBloc()..add(const MarketplaceFetched());

    final state = await settled(bloc);
    expect(state.items, [
      fakeCementItem,
      fakeSteelItem,
      fakePaintOutOfStockItem,
    ]);
    await bloc.close();
  });

  test('category filter, search, and sort narrow and reorder items', () async {
    final bloc = buildBloc()..add(const MarketplaceFetched());
    await settled(bloc);

    bloc.add(const MarketplaceCategoryChanged(MarketplaceCategory.steelMetals));
    var state = await bloc.stream.firstWhere(
      (s) =>
          s.status == MarketplaceStatus.success &&
          s.category == MarketplaceCategory.steelMetals,
    );
    expect(state.items, [fakeSteelItem]);

    bloc
      ..add(const MarketplaceCategoryChanged(null))
      ..add(const MarketplaceSortChanged(MarketplaceSort.priceHighToLow));
    state = await bloc.stream.firstWhere(
      (s) =>
          s.status == MarketplaceStatus.success &&
          s.category == null &&
          s.sort == MarketplaceSort.priceHighToLow,
    );
    expect(state.items, [
      fakeSteelItem,
      fakePaintOutOfStockItem,
      fakeCementItem,
    ]);

    bloc.add(const MarketplaceSearchChanged('دهان'));
    state = await bloc.stream.firstWhere(
      (s) =>
          s.status == MarketplaceStatus.success &&
          s.search == 'دهان' &&
          s.items.length == 1,
    );
    expect(state.items, [fakePaintOutOfStockItem]);
    await bloc.close();
  });

  test('a failed first page emits failure', () async {
    repository.itemsResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const MarketplaceFetched());

    final state = await bloc.stream.firstWhere(
      (s) => s.status == MarketplaceStatus.failure,
    );
    expect(state.failure, isA<NetworkFailure>());
    await bloc.close();
  });
}
