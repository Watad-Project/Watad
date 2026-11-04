import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/confirm_order_delivered_use_case.dart';

import '../../../../../helpers/fake_orders_repository.dart';

void main() {
  late FakeOrdersRepository orders;
  late ConfirmOrderDeliveredUseCase confirm;

  setUp(() {
    orders = FakeOrdersRepository();
    confirm = ConfirmOrderDeliveredUseCase(orders);
  });

  test('confirms a paid or a shipped order', () async {
    for (final status in [OrderStatus.paid, OrderStatus.shipped]) {
      final order = fakeOrder(id: 'o-${status.value}', status: status);
      orders.orders[order.id] = order;

      expect(await confirm(order), isA<Success<void>>());
      expect(orders.orders[order.id]?.status, OrderStatus.delivered);
    }
    expect(orders.confirmed, ['o-paid', 'o-shipped']);
  });

  test('an unpaid order is refused before confirm_order_delivered()', () async {
    final result = await confirm(fakeOrder());

    expect(
      result,
      isA<Failed<void>>().having(
        (f) => f.failure.messageKey,
        'messageKey',
        'marketplace.order_details.error_cannot_confirm',
      ),
    );
    expect(orders.confirmed, isEmpty);
  });
}
