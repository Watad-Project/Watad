part of 'admin_user_details_bloc.dart';

sealed class AdminUserDetailsEvent {
  const AdminUserDetailsEvent();
}

/// Load the user: when the page opens, and on retry.
final class AdminUserDetailsFetched extends AdminUserDetailsEvent {
  const AdminUserDetailsFetched(this.userId);

  final String userId;
}

/// «إيقاف المستخدم», after the admin confirmed and gave the reason.
final class AdminUserSuspended extends AdminUserDetailsEvent {
  const AdminUserSuspended(this.reason);

  final String reason;
}

/// «رفع الإيقاف», after the admin confirmed.
final class AdminUserUnsuspended extends AdminUserDetailsEvent {
  const AdminUserUnsuspended();
}

/// «تعيين كمشرف» ([UserRole.admin]) or «إزالة صلاحية المشرف»
/// ([UserRole.user]), after the admin confirmed.
final class AdminUserRoleChanged extends AdminUserDetailsEvent {
  const AdminUserRoleChanged(this.role);

  final UserRole role;
}
