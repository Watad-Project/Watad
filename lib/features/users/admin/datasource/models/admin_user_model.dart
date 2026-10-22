import 'package:watad/core/enums/user_role.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';

class AdminUserModel extends AdminUser {
  const AdminUserModel({
    required super.id,
    required super.name,
    required super.role,
    required super.memberSince,
    super.avatarUrl,
    super.isDeleted,
    super.isMe,
    super.lastSeenAt,
    super.isOnline,
    super.isBusiness,
    super.companyName,
    super.specialty,
    super.businessCity,
    super.verificationStatus,
    super.isSuspended,
    super.suspensionReason,
    super.suspendedAt,
    super.suspendedByName,
    super.clientProjectCount,
    super.contractorProjectCount,
    super.listingCount,
    super.openReportCount,
  });

  /// Maps the `v_admin_users` columns selected in
  /// AdminUsersRemoteDataSourceImpl, plus `avatar_url`, the public URL of
  /// `avatar_path` that the data source adds.
  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    DateTime? time(String column) => switch (json[column]) {
      final String value => DateTime.parse(value),
      _ => null,
    };
    int count(String column) => (json[column] as num?)?.toInt() ?? 0;
    final status = json['verification_status'] as String?;
    return AdminUserModel(
      id: json['id'] as String,
      name: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.fromJson(json['role'] as String),
      memberSince: DateTime.parse(json['member_since'] as String),
      isDeleted: json['is_deleted'] as bool? ?? false,
      isMe: json['is_me'] as bool? ?? false,
      lastSeenAt: time('last_seen_at'),
      isOnline: json['is_online'] as bool? ?? false,
      isBusiness: json['is_business'] as bool? ?? false,
      companyName: json['company_name'] as String?,
      specialty: json['specialized_field'] as String?,
      businessCity: json['business_city'] as String?,
      verificationStatus: status == null
          ? null
          : VerificationStatus.fromJson(status),
      isSuspended: json['is_suspended'] as bool? ?? false,
      suspensionReason: json['suspension_reason'] as String?,
      suspendedAt: time('suspended_at'),
      suspendedByName: json['suspended_by_name'] as String?,
      clientProjectCount: count('client_project_count'),
      contractorProjectCount: count('contractor_project_count'),
      listingCount: count('listing_count'),
      openReportCount: count('open_report_count'),
    );
  }
}
