import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_counts.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_filter.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_query.dart';
import 'package:watad/features/marketplace/admin/domain/usecases/admin_count_marketplace_items_use_case.dart';
import 'package:watad/features/marketplace/admin/domain/usecases/admin_get_marketplace_items_use_case.dart';

part 'admin_marketplace_event.dart';
part 'admin_marketplace_state.dart';

/// Every listing, newest first, a page at a time, narrowed by a chip and a
/// search (an item or a seller name), with each chip's count.
class AdminMarketplaceBloc
    extends Bloc<AdminMarketplaceEvent, AdminMarketplaceState> {
  AdminMarketplaceBloc(
    this._getItems,
    this._countItems, {
    this.searchDelay = const Duration(milliseconds: 350),
  }) : super(const AdminMarketplaceState()) {
    on<AdminMarketplaceFetched>((event, emit) => _reload(emit));
    on<AdminMarketplaceFilterChanged>((event, emit) {
      if (event.filter == state.filter) return null;
      // The new chip never shows the old chip's listings as loaded.
      emit(
        state.copyWith(
          filter: event.filter,
          status: AdminMarketplaceStatus.loading,
          items: const [],
        ),
      );
      return _loadFirstPage(emit);
    });
    on<AdminMarketplaceSearchChanged>(_onSearchChanged);
    on<AdminMarketplaceMoreRequested>(_onMoreRequested);
  }

  final AdminGetMarketplaceItemsUseCase _getItems;
  final AdminCountMarketplaceItemsUseCase _countItems;

  /// One search per pause in typing, not one per letter.
  final Duration searchDelay;

  /// Listings per page.
  static const int pageSize = 20;

  Future<void> _reload(Emitter<AdminMarketplaceState> emit) =>
      Future.wait([_loadFirstPage(emit), _loadCounts(emit)]);

  Future<void> _onSearchChanged(
    AdminMarketplaceSearchChanged event,
    Emitter<AdminMarketplaceState> emit,
  ) async {
    final search = event.search.trim();
    if (search == state.search) return;
    emit(state.copyWith(search: search));
    await Future<void>.delayed(searchDelay);
    // A newer letter replaced this search.
    if (emit.isDone || state.search != search) return;
    await _reload(emit);
  }

  Future<void> _loadFirstPage(Emitter<AdminMarketplaceState> emit) async {
    final (filter, search) = (state.filter, state.search);
    emit(
      state.copyWith(
        status: AdminMarketplaceStatus.loading,
        items: const [],
        hasMore: true,
        isLoadingMore: false,
      ),
    );
    final result = await _getItems(
      AdminMarketplaceQuery(
        filter: filter,
        search: search,
        offset: 0,
        limit: pageSize,
      ),
    );
    // A newer chip or search replaced this one while it loaded.
    if (emit.isDone || state.filter != filter || state.search != search) {
      return;
    }
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: AdminMarketplaceStatus.success,
            items: data,
            hasMore: data.length == pageSize,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: AdminMarketplaceStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  /// The chips' numbers. Without them the chips show their names alone.
  Future<void> _loadCounts(Emitter<AdminMarketplaceState> emit) async {
    final search = state.search;
    final result = await _countItems(search);
    if (emit.isDone || state.search != search) return;
    if (result case Success(:final data)) {
      emit(state.copyWith(counts: () => data));
    }
  }

  Future<void> _onMoreRequested(
    AdminMarketplaceMoreRequested event,
    Emitter<AdminMarketplaceState> emit,
  ) async {
    if (state.status != AdminMarketplaceStatus.success ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    final (filter, search) = (state.filter, state.search);
    emit(state.copyWith(isLoadingMore: true));
    final result = await _getItems(
      AdminMarketplaceQuery(
        filter: filter,
        search: search,
        offset: state.items.length,
        limit: pageSize,
      ),
    );
    if (emit.isDone || state.filter != filter || state.search != search) {
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
