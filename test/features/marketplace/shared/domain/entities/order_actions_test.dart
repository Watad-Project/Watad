import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/features/marketplace/shared/domain/entities/my_orders.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_actions.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_role.dart';

import '../../../../../helpers/fake_orders_repository.dart';

void main() {
  group('the buyer', () {
    OrderActions of(OrderStatus status, {bool canReview = false}) =>
        OrderActions.of(fakeOrder(status: status, canReview: canReview));

    test('pays or cancels an unpaid order', () {
      final actions = of(OrderStatus.pendingPayment);
      expect(actions.canPay, isTrue);
      expect(actions.canCancel, isTrue);
      expect(actions.canConfirmDelivery, isFalse);
      expect(actions.canReview, isFalse);
    });

    test('confirms a paid or shipped order, and cannot cancel it', () {
      for (final status in [OrderStatus.paid, OrderStatus.shipped]) {
        final actions = of(status);
        expect(actions.canConfirmDelivery, isTrue, reason: status.value);
        expect(actions.canCancel, isFalse, reason: status.value);
        expect(actions.canPay, isFalse, reason: status.value);
      }
    });

    test('reviews a delivered order only when not reviewed yet', () {
      expect(of(OrderStatus.delivered, canReview: true).canReview, isTrue);
      expect(of(OrderStatus.delivered).canReview, isFalse);
      expect(of(OrderStatus.delivered).canConfirmDelivery, isFalse);
    });

    test('does nothing with a cancelled or refunded order', () {
      for (final status in [OrderStatus.cancelled, OrderStatus.refunded]) {
        final actions = of(status);
        expect(
          [
            actions.canPay,
            actions.canCancel,
            actions.canConfirmDelivery,
            actions.canReview,
          ],
          everyElement(isFalse),
          reason: status.value,
        );
      }
    });

    test('cannot pay a bank transfer here, but can cancel it', () {
      final actions = OrderActions.of(
        fakeOrder(method: PaymentMethod.bankTransfer),
      );
      expect(actions.canPay, isFalse);
      expect(actions.canCancel, isTrue);
    });
  });

  test('the seller has none of the buyer actions', () {
    for (final status in OrderStatus.values) {
      final actions = OrderActions.of(
        fakeOrder(status: status, role: OrderRole.seller, canReview: true),
      );
      expect(
        [
          actions.canPay,
          actions.canCancel,
          actions.canConfirmDelivery,
          actions.canReview,
        ],
        everyElement(isFalse),
        reason: status.value,
      );
    }
  });

  test('the filter chips count each status, and «الكل» all of them', () {
    final orders = MyOrders([
      fakeOrder(id: 'a'),
      fakeOrder(id: 'b'),
      fakeOrder(id: 'c', status: OrderStatus.paid),
      fakeOrder(id: 'd', status: OrderStatus.delivered),
    ]);

    expect(MyOrders.filters.first, isNull);
    expect(MyOrders.filters, hasLength(7));
    expect(orders.countOf(null), 4);
    expect(orders.countOf(OrderStatus.pendingPayment), 2);
    expect(orders.countOf(OrderStatus.paid), 1);
    expect(orders.countOf(OrderStatus.cancelled), 0);
    expect(orders.of(OrderStatus.delivered).single.id, 'd');
  });
}
