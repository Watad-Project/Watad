import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_role.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/cancel_order_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/confirm_order_delivered_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_order_details_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/mark_order_shipped_use_case.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_order_details_bloc.dart';

import '../../../../../helpers/fake_orders_repository.dart';

void main() {
  late FakeOrdersRepository orders;
  final orderId = fakeOrder().id;

  MarketplaceOrderDetailsBloc buildBloc() => MarketplaceOrderDetailsBloc(
    GetOrderDetailsUseCase(orders),
    CancelOrderUseCase(orders),
    ConfirmOrderDeliveredUseCase(orders),
    MarkOrderShippedUseCase(orders),
  );

  Future<MarketplaceOrderDetailsState> loaded(
    MarketplaceOrderDetailsBloc bloc,
  ) => bloc.stream.firstWhere(
    (s) =>
        s.status == MarketplaceOrderDetailsStatus.success ||
        s.status == MarketplaceOrderDetailsStatus.failure,
  );

  setUp(() => orders = FakeOrdersRepository()..orders[orderId] = fakeOrder());

  test('loads the order', () async {
    final bloc = buildBloc()..add(MarketplaceOrderDetailsFetched(orderId));

    final state = await loaded(bloc);
    expect(state.details?.order.id, orderId);
    expect(state.details?.lines, fakeOrderLines);
    await bloc.close();
  });

  test('cancel: the order is cancelled, reloaded, and says so', () async {
    final bloc = buildBloc()..add(MarketplaceOrderDetailsFetched(orderId));
    await loaded(bloc);

    final states = <MarketplaceOrderDetailsState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const MarketplaceOrderCancelled());
    final state = await bloc.stream.firstWhere(
      (s) => s.details?.order.status == OrderStatus.cancelled,
    );
    await sub.cancel();

    expect(states.first.pendingAction, OrderDetailsAction.cancel);
    expect(state.doneAction, OrderDetailsAction.cancel);
    expect(state.pendingAction, isNull);
    expect(state.details?.history.last.newStatus, OrderStatus.cancelled);
    expect(orders.cancelled, [orderId]);
    await bloc.close();
  });

  test('«تم الاستلام» on a paid order delivers it', () async {
    orders.orders[orderId] = fakeOrder(status: OrderStatus.paid);
    final bloc = buildBloc()..add(MarketplaceOrderDetailsFetched(orderId));
    await loaded(bloc);

    bloc.add(const MarketplaceOrderDeliveryConfirmed());
    final state = await bloc.stream.firstWhere(
      (s) => s.details?.order.status == OrderStatus.delivered,
    );
    expect(state.doneAction, OrderDetailsAction.confirmDelivery);
    expect(state.details?.actions.canReview, isTrue);
    await bloc.close();
  });

  test('«تم الشحن» on a paid seller order marks it shipped', () async {
    orders.orders[orderId] = fakeOrder(
      status: OrderStatus.paid,
      role: OrderRole.seller,
    );
    final bloc = buildBloc()..add(MarketplaceOrderDetailsFetched(orderId));
    await loaded(bloc);

    bloc.add(const MarketplaceOrderShipped());
    final state = await bloc.stream.firstWhere(
      (s) => s.details?.order.status == OrderStatus.shipped,
    );
    expect(state.doneAction, OrderDetailsAction.ship);
    expect(state.details?.actions.canShip, isFalse);
    expect(orders.shipped, [orderId]);
    await bloc.close();
  });

  test('a refused action says why and shows the server state', () async {
    orders.cancelResult = const Failed(ServerFailure());
    final bloc = buildBloc()..add(MarketplaceOrderDetailsFetched(orderId));
    await loaded(bloc);

    bloc.add(const MarketplaceOrderCancelled());
    final state = await bloc.stream.firstWhere(
      (s) => s.actionFailure != null && s.pendingAction == null,
    );
    expect(state.actionFailure, isA<ServerFailure>());
    expect(state.doneAction, isNull);
    expect(state.details?.order.status, OrderStatus.pendingPayment);
    await bloc.close();
  });

  test('an order I cannot see is a failure', () async {
    final bloc = buildBloc()
      ..add(const MarketplaceOrderDetailsFetched('missing'));

    final state = await loaded(bloc);
    expect(state.status, MarketplaceOrderDetailsStatus.failure);
    expect(state.failure, isA<NotFoundFailure>());
    await bloc.close();
  });

  test('retry reloads the same order', () async {
    orders.orderResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(MarketplaceOrderDetailsFetched(orderId));
    await loaded(bloc);

    orders.orderResult = null;
    bloc.add(const MarketplaceOrderDetailsFetched());
    final state = await bloc.stream.firstWhere((s) => s.details != null);
    expect(state.details?.order.id, orderId);
    await bloc.close();
  });
}
