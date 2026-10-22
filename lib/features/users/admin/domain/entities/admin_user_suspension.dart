import 'package:watad/features/users/admin/domain/entities/admin_user.dart';

/// «إيقاف المستخدم»: the user, and the reason they will read.
class AdminUserSuspension {
  const AdminUserSuspension({required this.user, required this.reason});

  /// The most the database keeps of a reason.
  static const int maxReasonLength = 1000;

  final AdminUser user;
  final String reason;
}
