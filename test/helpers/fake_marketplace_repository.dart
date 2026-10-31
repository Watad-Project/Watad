import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/marketplace_category.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_query.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_sort.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';
import 'package:watad/features/marketplace/shared/marketplace_injection.dart';

/// In stock, from a verified business, with ratings.
final MarketplaceItem fakeCementItem = MarketplaceItem(
  id: 'i-cement',
  name: 'أسمنت أبيض ٥٠ كجم',
  description: 'كيس أسمنت أبيض للتشطيبات',
  price: const Money.halalas(4500),
  stockQuantity: 120,
  inStock: true,
  isActive: true,
  category: MarketplaceCategory.buildingMaterials,
  createdAt: DateTime.utc(2026, 10, 20, 9),
  updatedAt: DateTime.utc(2026, 10, 21, 9),
  sellerId: 'u-business',
  sellerName: 'مقاولات الخبر',
  sellerIsVerifiedBusiness: true,
  sellerRatingAvg: 4.8,
  sellerRatingCount: 12,
);

/// In stock, steel category, higher price.
final MarketplaceItem fakeSteelItem = MarketplaceItem(
  id: 'i-steel',
  name: 'حديد تسليح ١٢ مم',
  description: 'طن حديد تسليح',
  price: const Money.halalas(250000),
  stockQuantity: 10,
  inStock: true,
  isActive: true,
  category: MarketplaceCategory.steelMetals,
  createdAt: DateTime.utc(2026, 10, 19, 9),
  updatedAt: DateTime.utc(2026, 10, 19, 9),
  sellerId: 'u-seller',
  sellerName: 'سارة العتيبي',
);

/// Out of stock, paints category.
final MarketplaceItem fakePaintOutOfStockItem = MarketplaceItem(
  id: 'i-paint',
  name: 'دهان داخلي أبيض',
  price: const Money.halalas(9900),
  stockQuantity: 0,
  inStock: false,
  isActive: true,
  category: MarketplaceCategory.paints,
  createdAt: DateTime.utc(2026, 10, 18, 9),
  updatedAt: DateTime.utc(2026, 10, 18, 9),
  sellerId: 'u-business',
  sellerName: 'مقاولات الخبر',
  sellerIsVerifiedBusiness: true,
  sellerRatingAvg: 4.8,
  sellerRatingCount: 12,
);

/// A hand-written [MarketplaceRepository]: it filters, searches, sorts, and
/// pages [items] like `v_marketplace_items` would (APP_ARCHITECTURE.md §16).
class FakeMarketplaceRepository implements MarketplaceRepository {
  List<MarketplaceItem> items = [
    fakeCementItem,
    fakeSteelItem,
    fakePaintOutOfStockItem,
  ];

  /// Answers [getItems] instead, when set.
  Result<List<MarketplaceItem>>? itemsResult;

  final List<MarketplaceQuery> queries = [];

  @override
  Future<Result<List<MarketplaceItem>>> getItems(MarketplaceQuery query) async {
    queries.add(query);
    if (itemsResult case final result?) return result;
    final matching = [
      for (final item in items)
        if (item.isActive &&
            (query.category == null || item.category == query.category) &&
            (query.search.isEmpty ||
                item.name.toLowerCase().contains(query.search.toLowerCase())))
          item,
    ];
    matching.sort((a, b) {
      final primary = switch (query.sort) {
        MarketplaceSort.newest => b.createdAt.compareTo(a.createdAt),
        MarketplaceSort.priceLowToHigh => a.price.halalas.compareTo(
          b.price.halalas,
        ),
        MarketplaceSort.priceHighToLow => b.price.halalas.compareTo(
          a.price.halalas,
        ),
      };
      return primary != 0 ? primary : a.id.compareTo(b.id);
    });
    return Success(matching.skip(query.offset).take(query.limit).toList());
  }
}

/// For tests that open the marketplace route or client/contractor navigation
/// tabs: the real registrations, with [repository] in place of Supabase.
/// Reset getIt after the test.
void registerFakeMarketplace([FakeMarketplaceRepository? repository]) {
  registerMarketplaceDependencies(getIt);
  getIt
    ..unregister<MarketplaceRepository>()
    ..registerSingleton<MarketplaceRepository>(
      repository ?? FakeMarketplaceRepository(),
    );
}
