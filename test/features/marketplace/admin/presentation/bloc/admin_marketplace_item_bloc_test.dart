import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/admin/domain/usecases/admin_get_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/admin/domain/usecases/admin_remove_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/admin/presentation/bloc/admin_marketplace_item_bloc.dart';

import '../../../../../helpers/fake_admin_marketplace_repository.dart';

void main() {
  late FakeAdminMarketplaceRepository repository;

  AdminMarketplaceItemBloc buildBloc() => AdminMarketplaceItemBloc(
    AdminGetMarketplaceItemUseCase(repository),
    AdminRemoveMarketplaceItemUseCase(repository),
  );

  Future<AdminMarketplaceItemBloc> loaded(String itemId) async {
    final bloc = buildBloc()..add(AdminMarketplaceItemFetched(itemId));
    await bloc.stream.firstWhere(
      (s) => s.status == AdminMarketplaceItemLoadStatus.success,
    );
    return bloc;
  }

  setUp(() => repository = FakeAdminMarketplaceRepository());

  test('loads the listing', () async {
    final bloc = await loaded('i-live');
    expect(bloc.state.item, fakeLiveItem);
    await bloc.close();
  });

  test('a listing that does not exist is not found', () async {
    final bloc = buildBloc()..add(const AdminMarketplaceItemFetched('i-none'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == AdminMarketplaceItemLoadStatus.failure,
    );
    expect(state.failure, isA<NotFoundFailure>());
    await bloc.close();
  });

  test('removing sends the reason and reads the listing again', () async {
    final bloc = await loaded('i-live');
    final reads = repository.itemReads;

    bloc.add(const AdminMarketplaceItemRemoved('سعر مضلل'));
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(repository.calls, ['remove i-live: سعر مضلل']);
    expect(repository.itemReads, reads + 1);
    expect(state.isBusy, isFalse);
    expect(state.message?.key, 'marketplace.removed_done');
    await bloc.close();
  });

  test('a removed listing is refused with its own message', () async {
    final bloc = await loaded('i-removed');

    bloc.add(const AdminMarketplaceItemRemoved('سبب'));
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(state.message?.key, 'marketplace.error_already_removed');
    expect(repository.calls, isEmpty);
    await bloc.close();
  });

  test('a listing gone meanwhile says so', () async {
    final bloc = await loaded('i-live');
    repository.removeResult = const Failed(NotFoundFailure());

    bloc.add(const AdminMarketplaceItemRemoved('سبب'));
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(state.message?.key, 'marketplace.error_not_found');
    expect(state.message?.isError, isTrue);
    await bloc.close();
  });
}
