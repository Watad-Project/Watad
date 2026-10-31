import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/marketplace_category.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/datasource/models/marketplace_item_model.dart';

void main() {
  test('fromJson maps an active listing from v_marketplace_items', () {
    final model = MarketplaceItemModel.fromJson(const {
      'id': '5f0c7a52-3d1e-4c8b-9b7a-1e2d3c4b5a69',
      'item_name': 'حديد تسليح ١٢ مم',
      'description': 'طن حديد تسليح',
      'price': 2500.5,
      'stock_quantity': 10,
      'in_stock': true,
      'is_active': true,
      'category': 'steel_metals',
      'photo_paths': ['u-1/marketplace/i-1/1.jpg', 'u-1/marketplace/i-1/2.jpg'],
      'photo_urls': [
        'https://example.supabase.co/storage/v1/object/public/images/u-1/marketplace/i-1/1.jpg',
        'https://example.supabase.co/storage/v1/object/public/images/u-1/marketplace/i-1/2.jpg',
      ],
      'created_at': '2026-10-18T09:00:00+00:00',
      'updated_at': '2026-10-22T08:00:00+00:00',
      'seller_id': 'u-1',
      'seller_name': 'مقاولات الخبر',
      'seller_avatar_path': 'u-1/avatar.jpg',
      'seller_avatar_url': 'https://example.supabase.co/storage/v1/object/public/avatars/u-1/avatar.jpg',
      'seller_is_verified_business': true,
      'seller_rating_avg': 4.75,
      'seller_rating_count': 12,
      'is_mine': false,
      'removed_at': null,
      'removal_reason': null,
    });

    expect(model.name, 'حديد تسليح ١٢ مم');
    expect(model.description, 'طن حديد تسليح');
    expect(model.price, const Money.halalas(250050));
    expect(model.stockQuantity, 10);
    expect(model.inStock, isTrue);
    expect(model.isActive, isTrue);
    expect(model.category, MarketplaceCategory.steelMetals);
    expect(model.photoUrls, hasLength(2));
    expect(model.firstPhotoUrl, endsWith('1.jpg'));
    expect(model.sellerIsVerifiedBusiness, isTrue);
    expect(model.sellerRatingAvg, 4.75);
    expect(model.sellerRatingCount, 12);
    expect(model.sellerAvatarUrl, endsWith('u-1/avatar.jpg'));
    expect(model.isMine, isFalse);
  });

  test('an out-of-stock listing without description, photos, or rating', () {
    final model = MarketplaceItemModel.fromJson(const {
      'id': 'i-2',
      'item_name': 'بلاط',
      'description': null,
      'price': 32,
      'stock_quantity': 0,
      'in_stock': false,
      'is_active': true,
      'category': 'flooring_tiles',
      'photo_paths': <String>[],
      'created_at': '2026-10-18T09:00:00+00:00',
      'updated_at': '2026-10-18T09:00:00+00:00',
      'seller_id': 'u-2',
      'seller_name': 'سارة',
      'seller_avatar_url': null,
      'seller_is_verified_business': false,
      'seller_rating_avg': null,
      'seller_rating_count': 0,
      'is_mine': true,
    });

    expect(model.inStock, isFalse);
    expect(model.price, const Money.halalas(3200));
    expect(model.category, MarketplaceCategory.flooringTiles);
    expect(model.description, isNull);
    expect(model.photoUrls, isEmpty);
    expect(model.firstPhotoUrl, isNull);
    expect(model.sellerRatingAvg, isNull);
    expect(model.isMine, isTrue);
  });
}
