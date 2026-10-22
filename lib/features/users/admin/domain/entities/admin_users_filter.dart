import 'package:watad/core/enums/user_role.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';

/// The chips of the users list: «الكل», «العملاء», «المقاولون», «المشرفون»
/// and «موقوفون».
enum AdminUsersFilter {
  all,
  clients,
  contractors,
  admins,
  suspended;

  bool matches(AdminUser user) => switch (this) {
    all => true,
    clients => user.role == UserRole.user && !user.isBusiness,
    contractors => user.isBusiness,
    admins => user.isAdmin,
    suspended => user.isSuspended,
  };
}
