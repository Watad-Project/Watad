import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user_counts.dart';
import 'package:watad/features/users/admin/domain/entities/admin_users_filter.dart';
import 'package:watad/features/users/admin/domain/entities/admin_users_query.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_count_users_use_case.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_get_users_use_case.dart';

part 'admin_users_event.dart';
part 'admin_users_state.dart';

/// Every user, newest first, a page at a time, narrowed by a chip and a
/// search (a name, or a company name), with each chip's count.
class AdminUsersBloc extends Bloc<AdminUsersEvent, AdminUsersState> {
  AdminUsersBloc(
    this._getUsers,
    this._countUsers, {
    this.searchDelay = const Duration(milliseconds: 350),
  }) : super(const AdminUsersState()) {
    on<AdminUsersFetched>((event, emit) => _reload(emit));
    on<AdminUsersFilterChanged>((event, emit) {
      if (event.filter == state.filter) return null;
      // The new chip never shows the old chip's users as loaded.
      emit(
        state.copyWith(
          filter: event.filter,
          status: AdminUsersStatus.loading,
          users: const [],
        ),
      );
      return _loadFirstPage(emit);
    });
    on<AdminUsersSearchChanged>(_onSearchChanged);
    on<AdminUsersMoreRequested>(_onMoreRequested);
  }

  final AdminGetUsersUseCase _getUsers;
  final AdminCountUsersUseCase _countUsers;

  /// One search per pause in typing, not one per letter.
  final Duration searchDelay;

  /// Users per page.
  static const int pageSize = 20;

  Future<void> _reload(Emitter<AdminUsersState> emit) =>
      Future.wait([_loadFirstPage(emit), _loadCounts(emit)]);

  Future<void> _onSearchChanged(
    AdminUsersSearchChanged event,
    Emitter<AdminUsersState> emit,
  ) async {
    final search = event.search.trim();
    if (search == state.search) return;
    emit(state.copyWith(search: search));
    await Future<void>.delayed(searchDelay);
    // A newer letter replaced this search.
    if (emit.isDone || state.search != search) return;
    await _reload(emit);
  }

  Future<void> _loadFirstPage(Emitter<AdminUsersState> emit) async {
    final (filter, search) = (state.filter, state.search);
    emit(
      state.copyWith(
        status: AdminUsersStatus.loading,
        users: const [],
        hasMore: true,
        isLoadingMore: false,
      ),
    );
    final result = await _getUsers(
      AdminUsersQuery(
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
            status: AdminUsersStatus.success,
            users: data,
            hasMore: data.length == pageSize,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: AdminUsersStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  /// The chips' numbers. Without them the chips show their names alone.
  Future<void> _loadCounts(Emitter<AdminUsersState> emit) async {
    final search = state.search;
    final result = await _countUsers(search);
    if (emit.isDone || state.search != search) return;
    if (result case Success(:final data)) {
      emit(state.copyWith(counts: () => data));
    }
  }

  Future<void> _onMoreRequested(
    AdminUsersMoreRequested event,
    Emitter<AdminUsersState> emit,
  ) async {
    if (state.status != AdminUsersStatus.success ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    final (filter, search) = (state.filter, state.search);
    emit(state.copyWith(isLoadingMore: true));
    final result = await _getUsers(
      AdminUsersQuery(
        filter: filter,
        search: search,
        offset: state.users.length,
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
            users: [...state.users, ...data],
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
