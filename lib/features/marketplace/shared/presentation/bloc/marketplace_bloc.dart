import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/enums/marketplace_category.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_query.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_sort.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_marketplace_items_use_case.dart';

part 'marketplace_event.dart';
part 'marketplace_state.dart';

/// Active marketplace listings, a page at a time, narrowed by category chip
/// and search text, and ordered by the chosen sort.
class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  MarketplaceBloc(
    this._getItems, {
    this.searchDelay = const Duration(milliseconds: 350),
  }) : super(const MarketplaceState()) {
    on<MarketplaceFetched>((event, emit) => _loadFirstPage(emit));
    on<MarketplaceCategoryChanged>(_onCategoryChanged);
    on<MarketplaceSortChanged>(_onSortChanged);
    on<MarketplaceSearchChanged>(_onSearchChanged);
    on<MarketplaceMoreRequested>(_onMoreRequested);
  }

  final GetMarketplaceItemsUseCase _getItems;

  /// One search per pause in typing, not one per letter.
  final Duration searchDelay;

  /// Listings per page.
  static const int pageSize = 20;

  Future<void> _onCategoryChanged(
    MarketplaceCategoryChanged event,
    Emitter<MarketplaceState> emit,
  ) {
    if (event.category == state.category) return Future.value();
    emit(
      state.copyWith(
        category: () => event.category,
        status: MarketplaceStatus.loading,
        items: const [],
      ),
    );
    return _loadFirstPage(emit);
  }

  Future<void> _onSortChanged(
    MarketplaceSortChanged event,
    Emitter<MarketplaceState> emit,
  ) {
    if (event.sort == state.sort) return Future.value();
    emit(
      state.copyWith(
        sort: event.sort,
        status: MarketplaceStatus.loading,
        items: const [],
      ),
    );
    return _loadFirstPage(emit);
  }

  Future<void> _onSearchChanged(
    MarketplaceSearchChanged event,
    Emitter<MarketplaceState> emit,
  ) async {
    final search = event.search.trim();
    if (search == state.search) return;
    emit(state.copyWith(search: search));
    await Future<void>.delayed(searchDelay);
    // A newer letter replaced this search.
    if (emit.isDone || state.search != search) return;
    await _loadFirstPage(emit);
  }

  Future<void> _loadFirstPage(Emitter<MarketplaceState> emit) async {
    final (category, sort, search) = (state.category, state.sort, state.search);
    emit(
      state.copyWith(
        status: MarketplaceStatus.loading,
        items: const [],
        hasMore: true,
        isLoadingMore: false,
      ),
    );
    final result = await _getItems(
      MarketplaceQuery(
        category: category,
        sort: sort,
        search: search,
        offset: 0,
        limit: pageSize,
      ),
    );
    // A newer filter, sort, or search replaced this one while it loaded.
    if (emit.isDone ||
        state.category != category ||
        state.sort != sort ||
        state.search != search) {
      return;
    }
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: MarketplaceStatus.success,
            items: data,
            hasMore: data.length == pageSize,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MarketplaceStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  Future<void> _onMoreRequested(
    MarketplaceMoreRequested event,
    Emitter<MarketplaceState> emit,
  ) async {
    if (state.status != MarketplaceStatus.success ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    final (category, sort, search) = (state.category, state.sort, state.search);
    emit(state.copyWith(isLoadingMore: true));
    final result = await _getItems(
      MarketplaceQuery(
        category: category,
        sort: sort,
        search: search,
        offset: state.items.length,
        limit: pageSize,
      ),
    );
    if (emit.isDone ||
        state.category != category ||
        state.sort != sort ||
        state.search != search) {
      return;
    }
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            items: [...state.items, ...data],
            hasMore: data.length == pageSize,
            isLoadingMore: false,
          ),
        );
      case Failed():
        // The list stays; scrolling to the end again retries.
        emit(state.copyWith(isLoadingMore: false));
    }
  }
}
