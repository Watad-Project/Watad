import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/datasource/models/cart_line_model.dart';

void main() {
  test('fromJson maps a stored cart line', () {
    final line = CartLineModel.fromJson(const {
      'item_id': '5f0c7a52-3d1e-4c8b-9b7a-1e2d3c4b5a69',
      'quantity': 3,
      'price_halalas': 250050,
    });

    expect(line.itemId, '5f0c7a52-3d1e-4c8b-9b7a-1e2d3c4b5a69');
    expect(line.quantity, 3);
    expect(line.priceWhenAdded, const Money.halalas(250050));
  });
}
