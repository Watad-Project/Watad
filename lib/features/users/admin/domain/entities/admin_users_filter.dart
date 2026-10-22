import 'package:watad/core/enums/user_role.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';

/// The chips of the users list: «الكل», «العملاء», «المنشآت», «المشرفون»
/// and «موقوفون».
enum AdminUsersFilter {
  all,
  clients,
  businesses,
  admins,
  suspended;

  bool matches(AdminUser user) => switch (this) {
    all => true,
    clients => user.role == UserRole.user && !user.isBusiness,
    businesses => user.isBusiness,
    admins => user.isAdmin,
    suspended => user.isSuspended,
  };
}
