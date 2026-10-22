part of 'admin_marketplace_bloc.dart';

enum AdminMarketplaceStatus { initial, loading, success, failure }

final class AdminMarketplaceState {
  const AdminMarketplaceState({
    this.status = AdminMarketplaceStatus.initial,
    this.items = const [],
    this.filter = AdminMarketplaceFilter.all,
    this.search = '',
    this.counts,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.failure,
  });

  final AdminMarketplaceStatus status;

  /// The pages loaded so far, newest first.
  final List<AdminMarketplaceItem> items;

  final AdminMarketplaceFilter filter;

  /// The trimmed search text.
  final String search;

  /// Each chip's number for [search]; null until read.
  final AdminMarketplaceCounts? counts;

  /// Another page may follow, and it is loading.
  final bool hasMore;
  final bool isLoadingMore;

  /// Why the first page couldn't load.
  final Failure? failure;

  AdminMarketplaceState copyWith({
    AdminMarketplaceStatus? status,
    List<AdminMarketplaceItem>? items,
    AdminMarketplaceFilter? filter,
    String? search,
    AdminMarketplaceCounts? Function()? counts,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? Function()? failure,
  }) {
    return AdminMarketplaceState(
      status: status ?? this.status,
      items: items ?? this.items,
      filter: filter ?? this.filter,
      search: search ?? this.search,
      counts: counts == null ? this.counts : counts(),
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: failure == null ? this.failure : failure(),
    );
  }
}
