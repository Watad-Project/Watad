import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/enums/user_role.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user_role_change.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user_suspension.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_get_user_use_case.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_set_user_role_use_case.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_suspend_user_use_case.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_unsuspend_user_use_case.dart';

part 'admin_user_details_event.dart';
part 'admin_user_details_state.dart';

/// One user and the actions on them. After every action the user is read
/// again, so the page shows what the server saved.
class AdminUserDetailsBloc
    extends Bloc<AdminUserDetailsEvent, AdminUserDetailsState> {
  AdminUserDetailsBloc(
    this._getUser,
    this._suspend,
    this._unsuspend,
    this._setRole,
  ) : super(const AdminUserDetailsState()) {
    on<AdminUserDetailsFetched>(_onFetched);
    on<AdminUserSuspended>(
      (event, emit) => _act(
        emit,
        action: (user) =>
            _suspend(AdminUserSuspension(user: user, reason: event.reason)),
        successKey: 'users.suspended_done',
      ),
    );
    on<AdminUserUnsuspended>(
      (event, emit) => _act(
        emit,
        action: _unsuspend.call,
        successKey: 'users.unsuspended_done',
      ),
    );
    on<AdminUserRoleChanged>(
      (event, emit) => _act(
        emit,
        action: (user) =>
            _setRole(AdminUserRoleChange(user: user, role: event.role)),
        successKey: event.role == UserRole.admin
            ? 'users.made_admin_done'
            : 'users.removed_admin_done',
      ),
    );
  }

  final AdminGetUserUseCase _getUser;
  final AdminSuspendUserUseCase _suspend;
  final AdminUnsuspendUserUseCase _unsuspend;
  final AdminSetUserRoleUseCase _setRole;

  Future<void> _onFetched(
    AdminUserDetailsFetched event,
    Emitter<AdminUserDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdminUserDetailsStatus.loading,
        userId: event.userId,
      ),
    );
    final result = await _getUser(event.userId);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: AdminUserDetailsStatus.success,
            user: () => data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: AdminUserDetailsStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  /// Runs one action on the user, then reads them again.
  Future<void> _act(
    Emitter<AdminUserDetailsState> emit, {
    required Future<Result<void>> Function(AdminUser user) action,
    required String successKey,
  }) async {
    final user = state.user;
    if (user == null || state.isBusy) return;
    emit(state.copyWith(isBusy: true));
    final result = await action(user);
    // Also after a failure: e.g. another admin changed them meanwhile.
    final fresh = await _getUser(user.id);
    emit(
      state.copyWith(
        user: fresh is Success<AdminUser> ? () => fresh.data : null,
        isBusy: false,
        message: () => switch (result) {
          Success() => AdminUserDetailsMessage(successKey, isError: false),
          Failed(:final failure) => AdminUserDetailsMessage(
            failure.messageKey,
            isError: true,
          ),
        },
      ),
    );
  }
}
