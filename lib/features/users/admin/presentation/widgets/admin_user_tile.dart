import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';
import 'package:watad/features/users/admin/presentation/widgets/admin_users_labels.dart';

/// One user in the list: photo, name, client / business (its company, with
/// the verified check) / admin, member since, last seen or «متصل الآن»,
/// and «موقوف» or «حساب مغلق». A tap opens their page.
class AdminUserTile extends StatelessWidget {
  const AdminUserTile({
    required this.user,
    required this.now,
    required this.onTap,
    super.key,
  });

  final AdminUser user;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final company = user.companyName;
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(url: user.avatarUrl, semanticLabel: user.name),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: AppTextStyles.label),
                if (user.isBusiness && company != null)
                  user.isVerifiedBusiness
                      ? AppVerifiedName(
                          name: company,
                          style: AppTextStyles.caption,
                        )
                      : Text(company, style: AppTextStyles.caption),
                Text(
                  context.tr(
                    'users.joined',
                    args: [
                      AdminUsersLabels.kind(context, user),
                      AdminUsersLabels.memberSince(context, user),
                    ],
                  ),
                  style: AppTextStyles.caption,
                ),
                Text(
                  AdminUsersLabels.presence(context, user, now),
                  style: AppTextStyles.caption.copyWith(
                    color: user.isOnline ? AppColors.success : null,
                  ),
                ),
                if (user.isSuspended || user.isDeleted) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    children: [
                      if (user.isSuspended)
                        AppStatusBadge(
                          label: context.tr('users.suspended'),
                          tone: AppTone.danger,
                        ),
                      if (user.isDeleted)
                        AppStatusBadge(label: context.tr('users.closed')),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
