import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/admin/admin_marketplace_injection.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_counts.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_filter.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item_status.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_query.dart';
import 'package:watad/features/marketplace/admin/domain/repositories/admin_marketplace_repository.dart';

/// On the market, from a verified business.
final AdminMarketplaceItem fakeLiveItem = AdminMarketplaceItem(
  id: 'i-live',
  name: 'أسمنت أبيض ٥٠ كجم',
  description: 'كيس أسمنت أبيض للتشطيبات',
  price: const Money.halalas(4500),
  stock: 120,
  status: AdminMarketplaceItemStatus.live,
  createdAt: DateTime.utc(2026, 10, 20, 9),
  updatedAt: DateTime.utc(2026, 10, 21, 9),
  sellerId: 'u-business',
  sellerName: 'مقاولات الخبر',
  sellerIsVerified: true,
  sellerRatingAvg: 4.8,
  sellerRatingCount: 12,
  orderCount: 3,
);

/// Hidden by its seller.
final AdminMarketplaceItem fakeHiddenItem = AdminMarketplaceItem(
  id: 'i-hidden',
  name: 'بلاط سيراميك',
  price: const Money.halalas(3250),
  stock: 40,
  status: AdminMarketplaceItemStatus.hidden,
  createdAt: DateTime.utc(2026, 10, 19),
  updatedAt: DateTime.utc(2026, 10, 19),
  sellerId: 'u-seller',
  sellerName: 'سارة العتيبي',
);

/// Removed by an admin.
final AdminMarketplaceItem fakeRemovedItem = AdminMarketplaceItem(
  id: 'i-removed',
  name: 'حديد تسليح',
  price: const Money.halalas(250000),
  stock: 10,
  status: AdminMarketplaceItemStatus.removed,
  createdAt: DateTime.utc(2026, 10, 18),
  updatedAt: DateTime.utc(2026, 10, 22),
  sellerId: 'u-seller',
  sellerName: 'سارة العتيبي',
  removedAt: DateTime.utc(2026, 10, 22, 8),
  removalReason: 'سعر مضلل',
  removedByName: 'عمر ملا',
  openReportCount: 1,
);

/// Out of stock.
final AdminMarketplaceItem fakeOutOfStockItem = AdminMarketplaceItem(
  id: 'i-empty',
  name: 'دهان داخلي',
  price: const Money.halalas(9900),
  stock: 0,
  status: AdminMarketplaceItemStatus.outOfStock,
  createdAt: DateTime.utc(2026, 10, 17),
  updatedAt: DateTime.utc(2026, 10, 17),
  sellerId: 'u-business',
  sellerName: 'مقاولات الخبر',
  sellerIsVerified: true,
);

/// A hand-written [AdminMarketplaceRepository]: it pages, filters and
/// searches [items] like the view would, and records every removal
/// (APP_ARCHITECTURE.md §16).
class FakeAdminMarketplaceRepository implements AdminMarketplaceRepository {
  List<AdminMarketplaceItem> items = [
    fakeLiveItem,
    fakeHiddenItem,
    fakeRemovedItem,
    fakeOutOfStockItem,
  ];

  /// Answers [getItems] instead, when set.
  Result<List<AdminMarketplaceItem>>? itemsResult;
  Result<void> removeResult = const Success(null);

  final List<AdminMarketplaceQuery> queries = [];

  /// Every removal, e.g. `remove i-live: سعر مضلل`.
  final List<String> calls = [];
  int itemReads = 0;

  List<AdminMarketplaceItem> _matching(
    AdminMarketplaceFilter filter,
    String search,
  ) => [
    for (final item in items)
      if (filter.matches(item) &&
          (search.isEmpty ||
              item.name.contains(search) ||
              item.sellerName.contains(search)))
        item,
  ];

  @override
  Future<Result<List<AdminMarketplaceItem>>> getItems(
    AdminMarketplaceQuery query,
  ) async {
    queries.add(query);
    if (itemsResult case final result?) return result;
    return Success(
      _matching(
        query.filter,
        query.search,
      ).skip(query.offset).take(query.limit).toList(),
    );
  }

  @override
  Future<Result<AdminMarketplaceCounts>> countItems(String search) async =>
      Success(
        AdminMarketplaceCounts({
          for (final filter in AdminMarketplaceFilter.values)
            filter: _matching(filter, search).length,
        }),
      );

  @override
  Future<Result<AdminMarketplaceItem>> getItem(String itemId) async {
    itemReads++;
    for (final item in items) {
      if (item.id == itemId) return Success(item);
    }
    return const Failed(NotFoundFailure());
  }

  @override
  Future<Result<void>> removeItem(String itemId, String reason) async {
    calls.add('remove $itemId: $reason');
    return removeResult;
  }
}

/// For tests that open the marketplace routes, or the dashboard button to
/// them: the real registrations, with [repository] in place of Supabase.
/// Reset getIt after the test.
void registerFakeAdminMarketplace(FakeAdminMarketplaceRepository repository) {
  registerAdminMarketplaceDependencies(getIt);
  getIt
    ..unregister<AdminMarketplaceRepository>()
    ..registerSingleton<AdminMarketplaceRepository>(repository);
}
