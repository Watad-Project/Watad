import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/my_items_filter.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/delete_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_my_marketplace_items_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/set_marketplace_item_active_use_case.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/my_items_bloc.dart';

import '../../../../../helpers/fake_marketplace_repository.dart';

void main() {
  late FakeMarketplaceRepository repository;
  late MyItemsBloc bloc;

  setUp(() {
    repository = FakeMarketplaceRepository();
    bloc = MyItemsBloc(
      GetMyMarketplaceItemsUseCase(repository),
      SetMarketplaceItemActiveUseCase(repository),
      DeleteMarketplaceItemUseCase(repository),
    );
  });

  tearDown(() => bloc.close());

  test('loads seller listings and filters by status chip', () async {
    bloc.add(const MyItemsFetched());
    await pumpEventQueue();

    expect(bloc.state.status, MyItemsStatus.success);
    expect(bloc.state.items, hasLength(4));
    expect(bloc.state.visibleItems, hasLength(4));

    bloc.add(const MyItemsFilterChanged(MyItemsFilter.live));
    await pumpEventQueue();
    expect(bloc.state.visibleItems.map((i) => i.id), ['i-cement']);

    bloc.add(const MyItemsFilterChanged(MyItemsFilter.hidden));
    await pumpEventQueue();
    expect(bloc.state.visibleItems.map((i) => i.id), ['i-wood-hidden']);

    bloc.add(const MyItemsFilterChanged(MyItemsFilter.removed));
    await pumpEventQueue();
    expect(bloc.state.visibleItems.map((i) => i.id), ['i-removed']);

    bloc.add(const MyItemsFilterChanged(MyItemsFilter.outOfStock));
    await pumpEventQueue();
    expect(bloc.state.visibleItems.map((i) => i.id), ['i-paint']);
  });

  test('emits failure when fetching seller listings fails', () async {
    repository.myItemsResult = const Failed(NetworkFailure());
    bloc.add(const MyItemsFetched());
    await pumpEventQueue();

    expect(bloc.state.status, MyItemsStatus.failure);
    expect(bloc.state.failure, isA<NetworkFailure>());
  });

  test('toggles item visibility and soft-deletes an item', () async {
    bloc.add(const MyItemsFetched());
    await pumpEventQueue();

    // Hide a live item.
    bloc.add(
      const MyItemVisibilityToggled(itemId: 'i-cement', isActive: false),
    );
    await pumpEventQueue();

    final hiddenCement = bloc.state.items.firstWhere((i) => i.id == 'i-cement');
    expect(hiddenCement.isActive, isFalse);
    expect(bloc.state.actionDoneKey, 'marketplace.my_items_hidden_done');

    // Soft-delete the item.
    bloc.add(const MyItemDeleted('i-cement'));
    await pumpEventQueue();

    expect(bloc.state.items.any((i) => i.id == 'i-cement'), isFalse);
    expect(bloc.state.actionDoneKey, 'marketplace.my_items_deleted_done');
  });

  test('reports actionFailure when hide/show or delete fails', () async {
    bloc.add(const MyItemsFetched());
    await pumpEventQueue();

    repository.actionResult = const Failed(ServerFailure());
    bloc.add(
      const MyItemVisibilityToggled(itemId: 'i-cement', isActive: false),
    );
    await pumpEventQueue();

    expect(bloc.state.actionFailure, isA<ServerFailure>());
  });
}
