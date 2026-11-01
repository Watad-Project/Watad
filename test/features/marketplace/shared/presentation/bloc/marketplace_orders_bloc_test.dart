import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_role.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_my_orders_use_case.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_orders_bloc.dart';

import '../../../../../helpers/fake_orders_repository.dart';

void main() {
  late FakeOrdersRepository orders;

  MarketplaceOrdersBloc buildBloc() =>
      MarketplaceOrdersBloc(GetMyOrdersUseCase(orders));

  Future<MarketplaceOrdersState> loaded(MarketplaceOrdersBloc bloc) =>
      bloc.stream.firstWhere(
        (s) =>
            s.status == MarketplaceOrdersStatus.success ||
            s.status == MarketplaceOrdersStatus.failure,
      );

  setUp(() {
    orders = FakeOrdersRepository();
    orders.orders
      ..['old'] = fakeOrder(
        id: 'old',
        status: OrderStatus.delivered,
        createdAt: DateTime.utc(2026, 10, 20),
      )
      ..['new'] = fakeOrder(id: 'new', createdAt: DateTime.utc(2026, 11, 1))
      ..['sold'] = fakeOrder(id: 'sold', role: OrderRole.seller);
  });

  test('loads the orders I bought, newest first', () async {
    final bloc = buildBloc()..add(const MarketplaceOrdersFetched());

    final state = await loaded(bloc);
    expect(state.orders.orders.map((o) => o.id), ['new', 'old']);
    expect(state.filter, isNull);
    await bloc.close();
  });

  test('a chip filters the list, and «الكل» shows it all again', () async {
    final bloc = buildBloc()..add(const MarketplaceOrdersFetched());
    await loaded(bloc);

    bloc.add(const MarketplaceOrdersFilterSelected(OrderStatus.delivered));
    var state = await bloc.stream.first;
    expect(state.orders.of(state.filter).map((o) => o.id), ['old']);

    bloc.add(const MarketplaceOrdersFilterSelected(null));
    state = await bloc.stream.first;
    expect(state.orders.of(state.filter), hasLength(2));
    await bloc.close();
  });

  test('a first load that fails shows the error', () async {
    orders.purchasesResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const MarketplaceOrdersFetched());

    final state = await loaded(bloc);
    expect(state.status, MarketplaceOrdersStatus.failure);
    expect(state.failure, isA<NetworkFailure>());
    await bloc.close();
  });

  test('a failed refresh keeps the list and says why', () async {
    final bloc = buildBloc()..add(const MarketplaceOrdersFetched());
    await loaded(bloc);

    orders.purchasesResult = const Failed(NetworkFailure());
    bloc.add(const MarketplaceOrdersFetched());
    final state = await bloc.stream.firstWhere((s) => s.refreshFailure != null);
    expect(state.status, MarketplaceOrdersStatus.success);
    expect(state.orders.orders, hasLength(2));
    await bloc.close();
  });
}
