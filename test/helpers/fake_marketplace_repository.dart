import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/marketplace_category.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item_draft.dart';
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
  isMine: true,
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
  isMine: true,
);

/// Hidden seller listing (`isActive: false`).
final MarketplaceItem fakeHiddenWoodItem = MarketplaceItem(
  id: 'i-wood-hidden',
  name: 'أخشاب موسكي',
  description: 'أخشاب للبناء',
  price: const Money.halalas(15000),
  stockQuantity: 15,
  inStock: true,
  isActive: false,
  category: MarketplaceCategory.wood,
  createdAt: DateTime.utc(2026, 10, 17, 9),
  updatedAt: DateTime.utc(2026, 10, 17, 9),
  sellerId: 'u-business',
  sellerName: 'مقاولات الخبر',
  sellerIsVerifiedBusiness: true,
  isMine: true,
);

/// Admin-removed seller listing (`removedAt != null`, with `removalReason`).
final MarketplaceItem fakeRemovedItem = MarketplaceItem(
  id: 'i-removed',
  name: 'سقالات مستعملة',
  description: 'سقالات حديد',
  price: const Money.halalas(80000),
  stockQuantity: 4,
  inStock: true,
  isActive: false,
  category: MarketplaceCategory.toolsEquipment,
  createdAt: DateTime.utc(2026, 10, 16, 9),
  updatedAt: DateTime.utc(2026, 10, 16, 9),
  sellerId: 'u-business',
  sellerName: 'مقاولات الخبر',
  sellerIsVerifiedBusiness: true,
  isMine: true,
  removedAt: DateTime.utc(2026, 10, 22, 12),
  removalReason: 'صور غير مطابقة للمنتج المعروض',
);

/// A hand-written [MarketplaceRepository]: it filters, searches, sorts, and
/// pages [items] like `v_marketplace_items` would (APP_ARCHITECTURE.md §16).
class FakeMarketplaceRepository implements MarketplaceRepository {
  List<MarketplaceItem> items = [
    fakeCementItem,
    fakeSteelItem,
    fakePaintOutOfStockItem,
  ];

  List<MarketplaceItem> myItems = [
    fakeCementItem,
    fakePaintOutOfStockItem,
    fakeHiddenWoodItem,
    fakeRemovedItem,
  ];

  /// Answers [getItems] instead, when set.
  Result<List<MarketplaceItem>>? itemsResult;

  /// Answers [getMyItems] instead, when set.
  Result<List<MarketplaceItem>>? myItemsResult;

  /// Answers [getMyItem] instead, when set.
  Result<MarketplaceItem>? myItemResult;

  /// Answers [createItem] or [updateItem] instead, when set.
  Result<MarketplaceItem>? saveResult;

  /// Answers [setItemActive] or [deleteItem] instead, when set.
  Result<void>? actionResult;

  final List<MarketplaceQuery> queries = [];

  @override
  Future<Result<List<MarketplaceItem>>> getItems(MarketplaceQuery query) async {
    queries.add(query);
    if (itemsResult case final result?) return result;
    final matching = [
      for (final item in items)
        if (item.isActive &&
            !item.isRemoved &&
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

  @override
  Future<Result<List<MarketplaceItem>>> getMyItems() async {
    if (myItemsResult case final result?) return result;
    return Success(List<MarketplaceItem>.unmodifiable(myItems));
  }

  @override
  Future<Result<MarketplaceItem>> getMyItem(String itemId) async {
    if (myItemResult case final result?) return result;
    for (final item in myItems) {
      if (item.id == itemId) return Success(item);
    }
    return const Failed(NotFoundFailure());
  }

  @override
  Future<Result<MarketplaceItem>> createItem(MarketplaceItemDraft draft) async {
    if (saveResult case final result?) return result;
    final created = MarketplaceItem(
      id: 'i-created-${myItems.length + 1}',
      name: draft.name,
      description: draft.description,
      price: draft.price,
      stockQuantity: draft.stockQuantity,
      inStock: draft.stockQuantity > 0,
      isActive: draft.isActive,
      category: draft.category,
      createdAt: DateTime.utc(2026, 10, 25, 10),
      updatedAt: DateTime.utc(2026, 10, 25, 10),
      sellerId: 'u-business',
      sellerName: 'مقاولات الخبر',
      sellerIsVerifiedBusiness: true,
      isMine: true,
      photoPaths: draft.photos,
    );
    myItems = [created, ...myItems];
    items = [created, ...items];
    return Success(created);
  }

  @override
  Future<Result<MarketplaceItem>> updateItem(
    String itemId,
    MarketplaceItemDraft draft,
  ) async {
    if (saveResult case final result?) return result;
    final index = myItems.indexWhere((item) => item.id == itemId);
    if (index == -1) return const Failed(NotFoundFailure());
    final existing = myItems[index];
    if (existing.isRemoved) return const Failed(ServerFailure());
    final updated = MarketplaceItem(
      id: existing.id,
      name: draft.name,
      description: draft.description,
      price: draft.price,
      stockQuantity: draft.stockQuantity,
      inStock: draft.stockQuantity > 0,
      isActive: draft.isActive,
      category: draft.category,
      createdAt: existing.createdAt,
      updatedAt: DateTime.utc(2026, 10, 25, 11),
      sellerId: existing.sellerId,
      sellerName: existing.sellerName,
      sellerIsVerifiedBusiness: existing.sellerIsVerifiedBusiness,
      sellerRatingAvg: existing.sellerRatingAvg,
      sellerRatingCount: existing.sellerRatingCount,
      isMine: true,
      photoPaths: draft.photos,
    );
    myItems = [
      for (final item in myItems)
        if (item.id == itemId) updated else item,
    ];
    items = [
      for (final item in items)
        if (item.id == itemId) updated else item,
    ];
    return Success(updated);
  }

  @override
  Future<Result<void>> setItemActive(
    String itemId, {
    required bool isActive,
  }) async {
    if (actionResult case final result?) return result;
    final index = myItems.indexWhere((item) => item.id == itemId);
    if (index == -1) return const Failed(NotFoundFailure());
    final existing = myItems[index];
    if (existing.isRemoved) return const Failed(ServerFailure());
    final updated = MarketplaceItem(
      id: existing.id,
      name: existing.name,
      description: existing.description,
      price: existing.price,
      stockQuantity: existing.stockQuantity,
      inStock: existing.inStock,
      isActive: isActive,
      category: existing.category,
      createdAt: existing.createdAt,
      updatedAt: existing.updatedAt,
      sellerId: existing.sellerId,
      sellerName: existing.sellerName,
      sellerIsVerifiedBusiness: existing.sellerIsVerifiedBusiness,
      sellerRatingAvg: existing.sellerRatingAvg,
      sellerRatingCount: existing.sellerRatingCount,
      isMine: existing.isMine,
      photoPaths: existing.photoPaths,
    );
    myItems = [
      for (final item in myItems)
        if (item.id == itemId) updated else item,
    ];
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteItem(String itemId) async {
    if (actionResult case final result?) return result;
    final index = myItems.indexWhere((item) => item.id == itemId);
    if (index == -1) return const Failed(NotFoundFailure());
    if (myItems[index].isRemoved) return const Failed(ServerFailure());
    myItems = [
      for (final item in myItems)
        if (item.id != itemId) item,
    ];
    items = [
      for (final item in items)
        if (item.id != itemId) item,
    ];
    return const Success(null);
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
