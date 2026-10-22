part of 'admin_users_bloc.dart';

enum AdminUsersStatus { initial, loading, success, failure }

final class AdminUsersState {
  const AdminUsersState({
    this.status = AdminUsersStatus.initial,
    this.users = const [],
    this.filter = AdminUsersFilter.all,
    this.search = '',
    this.counts,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.failure,
  });

  final AdminUsersStatus status;

  /// The pages loaded so far, newest first.
  final List<AdminUser> users;

  final AdminUsersFilter filter;

  /// The trimmed search text.
  final String search;

  /// Each chip's number for [search]; null until read.
  final AdminUserCounts? counts;

  /// Another page may follow, and it is loading.
  final bool hasMore;
  final bool isLoadingMore;

  /// Why the first page couldn't load.
  final Failure? failure;

  AdminUsersState copyWith({
    AdminUsersStatus? status,
    List<AdminUser>? users,
    AdminUsersFilter? filter,
    String? search,
    AdminUserCounts? Function()? counts,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? Function()? failure,
  }) {
    return AdminUsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      filter: filter ?? this.filter,
      search: search ?? this.search,
      counts: counts == null ? this.counts : counts(),
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: failure == null ? this.failure : failure(),
    );
  }
}
