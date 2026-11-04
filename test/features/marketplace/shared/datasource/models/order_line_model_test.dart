import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/datasource/models/order_line_model.dart';

void main() {
  test('fromJson maps a v_order_items row', () {
    final line = OrderLineModel.fromJson(const {
      'item_id': '9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d',
      'item_name': 'حديد تسليح ١٢ مم',
      'quantity': 3,
      'price_at_purchase': 2500.5,
      'subtotal': 7501.5,
    });

    expect(line.itemId, '9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d');
    expect(line.name, 'حديد تسليح ١٢ مم');
    expect(line.quantity, 3);
    expect(line.price, const Money.halalas(250050));
    expect(line.subtotal, const Money.halalas(750150));
  });

  test('a line whose listing is gone keeps its name and price', () {
    final line = OrderLineModel.fromJson(const {
      'item_id': null,
      'item_name': 'بلاط',
      'quantity': 1,
      'price_at_purchase': 32,
      'subtotal': 32,
    });

    expect(line.itemId, isNull);
    expect(line.subtotal, const Money.halalas(3200));
  });
}
