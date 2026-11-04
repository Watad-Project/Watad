import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_role.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/mark_order_shipped_use_case.dart';

import '../../../../../helpers/fake_orders_repository.dart';

void main() {
  late FakeOrdersRepository orders;
  late MarkOrderShippedUseCase ship;

  setUp(() {
    orders = FakeOrdersRepository();
    ship = MarkOrderShippedUseCase(orders);
  });

  test('marks a paid seller order as shipped', () async {
    final order = fakeOrder(
      id: 'o-paid',
      status: OrderStatus.paid,
      role: OrderRole.seller,
    );
    orders.orders[order.id] = order;

    expect(await ship(order), isA<Success<void>>());
    expect(orders.orders[order.id]?.status, OrderStatus.shipped);
    expect(orders.shipped, ['o-paid']);
  });

  test(
    'an unpaid or buyer order is refused before mark_order_shipped()',
    () async {
      for (final order in [
        fakeOrder(role: OrderRole.seller),
        fakeOrder(status: OrderStatus.paid),
        fakeOrder(status: OrderStatus.shipped, role: OrderRole.seller),
      ]) {
        final result = await ship(order);
        expect(
          result,
          isA<Failed<void>>().having(
            (f) => f.failure.messageKey,
            'messageKey',
            'marketplace.order_details.error_cannot_ship',
          ),
        );
      }
      expect(orders.shipped, isEmpty);
    },
  );
}
