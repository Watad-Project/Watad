import 'package:watad/core/enums/marketplace_category.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_sort.dart';

/// One page of the «السوق» browse grid: narrowed by [category] and [search],
/// ordered by [sort].
final class MarketplaceQuery {
  const MarketplaceQuery({
    this.search = '',
    this.category,
    this.sort = MarketplaceSort.newest,
    this.offset = 0,
    this.limit = 20,
  });

  /// Trimmed item name search; empty means all items.
  final String search;

  /// Null means all categories («الكل»).
  final MarketplaceCategory? category;

  final MarketplaceSort sort;
  final int offset;
  final int limit;
}
