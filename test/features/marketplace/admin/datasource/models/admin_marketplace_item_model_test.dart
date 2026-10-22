import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/admin/datasource/models/admin_marketplace_item_model.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item_status.dart';

void main() {
  test('fromJson maps a removed listing from v_admin_marketplace_items', () {
    final model = AdminMarketplaceItemModel.fromJson(const {
      'id': '5f0c7a52-3d1e-4c8b-9b7a-1e2d3c4b5a69',
      'item_name': 'حديد تسليح ١٢ مم',
      'description': 'طن حديد تسليح',
      'price': 2500.5,
      'stock_quantity': 10,
      'status': 'removed',
      'created_at': '2026-10-18T09:00:00+00:00',
      'updated_at': '2026-10-22T08:00:00+00:00',
      'seller_id': 'u-1',
      'seller_name': 'مقاولات الخبر',
      'seller_avatar_path': 'u-1/avatar.jpg',
      'seller_avatar_url': 'https://example.supabase.co/storage/v1/object/public/avatars/u-1/avatar.jpg',
      'seller_is_verified_business': true,
      'seller_rating_avg': 4.75,
      'seller_rating_count': 12,
      'removed_at': '2026-10-22T08:00:00+00:00',
      'removal_reason': 'سعر مضلل',
      'removed_by_name': 'عمر ملا',
      'order_count': 3,
      'open_report_count': 1,
    });

    expect(model.name, 'حديد تسليح ١٢ مم');
    expect(model.price, const Money.halalas(250050));
    expect(model.stock, 10);
    expect(model.status, AdminMarketplaceItemStatus.removed);
    expect(model.isRemoved, isTrue);
    expect(model.sellerIsVerified, isTrue);
    expect(model.sellerRatingAvg, 4.75);
    expect(model.sellerRatingCount, 12);
    expect(model.sellerAvatarUrl, endsWith('u-1/avatar.jpg'));
    expect(model.removedAt, DateTime.utc(2026, 10, 22, 8));
    expect(model.removalReason, 'سعر مضلل');
    expect(model.removedByName, 'عمر ملا');
    expect(model.orderCount, 3);
    expect(model.openReportCount, 1);
  });

  test('a live listing without a description, rating or removal', () {
    final model = AdminMarketplaceItemModel.fromJson(const {
      'id': 'i-2',
      'item_name': 'بلاط',
      'description': null,
      'price': 32,
      'stock_quantity': 0,
      'status': 'out_of_stock',
      'created_at': '2026-10-18T09:00:00+00:00',
      'updated_at': '2026-10-18T09:00:00+00:00',
      'seller_id': 'u-2',
      'seller_name': 'سارة',
      'seller_avatar_url': null,
      'seller_is_verified_business': false,
      'seller_rating_avg': null,
      'seller_rating_count': 0,
      'removed_at': null,
      'order_count': 0,
      'open_report_count': 0,
    });

    expect(model.status, AdminMarketplaceItemStatus.outOfStock);
    expect(model.price, const Money.halalas(3200));
    expect(model.description, isNull);
    expect(model.sellerRatingAvg, isNull);
    expect(model.removedAt, isNull);
    expect(model.isRemoved, isFalse);
  });

  test('every status reads back as itself', () {
    for (final status in AdminMarketplaceItemStatus.values) {
      expect(
        AdminMarketplaceItemModel.statusOf(
          AdminMarketplaceItemModel.valueOf(status),
        ),
        status,
      );
    }
  });
}
