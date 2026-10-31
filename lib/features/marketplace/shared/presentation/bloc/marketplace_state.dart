part of 'marketplace_bloc.dart';

enum MarketplaceStatus { initial, loading, success, failure }

final class MarketplaceState {
  const MarketplaceState({
    this.status = MarketplaceStatus.initial,
    this.items = const [],
    this.category,
    this.sort = MarketplaceSort.newest,
    this.search = '',
    this.hasMore = true,
    this.isLoadingMore = false,
    this.failure,
  });

  final MarketplaceStatus status;

  /// The pages loaded so far.
  final List<MarketplaceItem> items;

  /// Selected category chip; `null` means "All".
  final MarketplaceCategory? category;

  /// Selected sort order.
  final MarketplaceSort sort;

  /// The trimmed search text.
  final String search;

  /// Another page may follow, and it is loading.
  final bool hasMore;
  final bool isLoadingMore;

  /// Why the first page couldn't load.
  final Failure? failure;

  MarketplaceState copyWith({
    MarketplaceStatus? status,
    List<MarketplaceItem>? items,
    MarketplaceCategory? Function()? category,
    MarketplaceSort? sort,
    String? search,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? Function()? failure,
  }) {
    return MarketplaceState(
      status: status ?? this.status,
      items: items ?? this.items,
      category: category == null ? this.category : category(),
      sort: sort ?? this.sort,
      search: search ?? this.search,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: failure == null ? this.failure : failure(),
    );
  }
}
