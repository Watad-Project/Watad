import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_role.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/cancel_order_use_case.dart';

import '../../../../../helpers/fake_orders_repository.dart';

void main() {
  late FakeOrdersRepository orders;
  late CancelOrderUseCase cancel;

  setUp(() {
    orders = FakeOrdersRepository();
    cancel = CancelOrderUseCase(orders);
  });

  String? errorOf(Result<void> result) => switch (result) {
    Failed(:final failure) => failure.messageKey,
    Success() => null,
  };

  test('cancels an unpaid order of mine', () async {
    final order = fakeOrder();
    orders.orders[order.id] = order;

    expect(await cancel(order), isA<Success<void>>());
    expect(orders.cancelled, [order.id]);
    expect(orders.orders[order.id]?.status, OrderStatus.cancelled);
  });

  test('a paid order is refused before cancel_order()', () async {
    final result = await cancel(fakeOrder(status: OrderStatus.paid));

    expect(errorOf(result), 'marketplace.order_details.error_cannot_cancel');
    expect(orders.cancelled, isEmpty);
  });

  test('the seller cancels an unpaid sale too (GRA-71)', () async {
    final order = fakeOrder(role: OrderRole.seller);
    orders.orders[order.id] = order;

    expect(await cancel(order), isA<Success<void>>());
    expect(orders.cancelled, [order.id]);
  });

  test('the seller cannot cancel a paid sale', () async {
    final result = await cancel(
      fakeOrder(role: OrderRole.seller, status: OrderStatus.paid),
    );

    expect(errorOf(result), 'marketplace.order_details.error_cannot_cancel');
    expect(orders.cancelled, isEmpty);
  });
}
