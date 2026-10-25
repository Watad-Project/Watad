import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_filter.dart';
import 'package:watad/features/marketplace/admin/domain/usecases/admin_count_marketplace_items_use_case.dart';
import 'package:watad/features/marketplace/admin/domain/usecases/admin_get_marketplace_items_use_case.dart';
import 'package:watad/features/marketplace/admin/presentation/bloc/admin_marketplace_bloc.dart';

import '../../../../../helpers/fake_admin_marketplace_repository.dart';

void main() {
  late FakeAdminMarketplaceRepository repository;

  AdminMarketplaceBloc buildBloc() => AdminMarketplaceBloc(
    AdminGetMarketplaceItemsUseCase(repository),
    AdminCountMarketplaceItemsUseCase(repository),
    searchDelay: Duration.zero,
  );

  Future<AdminMarketplaceState> settled(AdminMarketplaceBloc bloc) =>
      bloc.stream.firstWhere(
        (s) => s.status == AdminMarketplaceStatus.success && s.counts != null,
      );

  setUp(() => repository = FakeAdminMarketplaceRepository());

  test('loads the first page and the counts', () async {
    final bloc = buildBloc()..add(const AdminMarketplaceFetched());

    final state = await settled(bloc);
    expect(state.items, hasLength(4));
    expect(state.counts!.of(AdminMarketplaceFilter.all), 4);
    expect(state.counts!.of(AdminMarketplaceFilter.live), 1);
    expect(state.counts!.of(AdminMarketplaceFilter.hidden), 1);
    expect(state.counts!.of(AdminMarketplaceFilter.removed), 1);
    expect(state.counts!.of(AdminMarketplaceFilter.outOfStock), 1);
    await bloc.close();
  });

  test('a chip and a seller search narrow the list', () async {
    final bloc = buildBloc()..add(const AdminMarketplaceFetched());
    await settled(bloc);

    bloc.add(
      const AdminMarketplaceFilterChanged(AdminMarketplaceFilter.removed),
    );
    var state = await bloc.stream.firstWhere(
      (s) =>
          s.status == AdminMarketplaceStatus.success &&
          s.filter == AdminMarketplaceFilter.removed,
    );
    expect(state.items, [fakeRemovedItem]);

    bloc
      ..add(const AdminMarketplaceFilterChanged(AdminMarketplaceFilter.all))
      ..add(const AdminMarketplaceSearchChanged('مقاولات'));
    state = await bloc.stream.firstWhere(
      (s) =>
          s.status == AdminMarketplaceStatus.success &&
          s.search == 'مقاولات' &&
          s.items.length == 2,
    );
    expect(state.items, [fakeLiveItem, fakeOutOfStockItem]);
    await bloc.close();
  });

  test('a failed first page says why', () async {
    repository.itemsResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const AdminMarketplaceFetched());

    final state = await bloc.stream.firstWhere(
      (s) => s.status == AdminMarketplaceStatus.failure,
    );
    expect(state.failure, isA<NetworkFailure>());
    await bloc.close();
  });
}
