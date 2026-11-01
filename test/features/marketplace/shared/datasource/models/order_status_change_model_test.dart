import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/order_status.dart';
import 'package:watad/features/marketplace/shared/datasource/models/order_status_change_model.dart';

void main() {
  test('fromJson maps a v_order_status_history row', () {
    final change = OrderStatusChangeModel.fromJson(const {
      'old_status': 'pending_payment',
      'new_status': 'paid',
      'changed_at': '2026-11-01T10:15:00+00:00',
    });

    expect(change.oldStatus, OrderStatus.pendingPayment);
    expect(change.newStatus, OrderStatus.paid);
    expect(change.changedAt, DateTime.utc(2026, 11, 1, 10, 15));
  });

  test('the first row, when the order was created, has no old status', () {
    final change = OrderStatusChangeModel.fromJson(const {
      'old_status': null,
      'new_status': 'pending_payment',
      'changed_at': '2026-11-01T09:00:00+00:00',
    });

    expect(change.oldStatus, isNull);
    expect(change.newStatus, OrderStatus.pendingPayment);
  });
}
