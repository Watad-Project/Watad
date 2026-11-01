import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/profile/shared/datasource/models/profile_market_item_model.dart';

void main() {
  test('fromJson maps a v_marketplace_items row', () {
    final item = ProfileMarketItemModel.fromJson(const {
      'id': 'b1c2d3e4-0000-4000-8000-000000000001',
      'item_name': 'حديد تسليح ١٢ مم',
      'price': 2850.5,
      'in_stock': false,
      'photo_paths': ['items/a.jpg'],
      'photo_url':
          'https://x.supabase.co/storage/v1/object/public/images/a.jpg',
    });

    expect(item.id, 'b1c2d3e4-0000-4000-8000-000000000001');
    expect(item.name, 'حديد تسليح ١٢ مم');
    expect(item.price, const Money.halalas(285050));
    expect(item.inStock, isFalse);
    expect(item.photoUrl, endsWith('images/a.jpg'));
  });
}
