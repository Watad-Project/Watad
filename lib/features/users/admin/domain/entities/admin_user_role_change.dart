import 'package:watad/core/enums/user_role.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';

/// «تعيين كمشرف» ([UserRole.admin]) or «إزالة صلاحية المشرف»
/// ([UserRole.user]).
class AdminUserRoleChange {
  const AdminUserRoleChange({required this.user, required this.role});

  final AdminUser user;
  final UserRole role;
}
