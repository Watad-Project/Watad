import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';
import 'package:watad/features/notifications/shared/presentation/widgets/notification_time_ago.dart';

/// One notification in the list: an orange dot while unread, its title,
/// text and how long ago it came.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.notification,
    required this.now,
    required this.onTap,
    super.key,
  });

  final UserNotification notification;
  final DateTime now;
  final VoidCallback onTap;

  static const double _dotSize = 8;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return Semantics(
      label: unread ? context.tr('notifications.unread') : null,
      child: Material(
        color: unread ? AppColors.surfaceMuted : AppColors.surface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 6),
                  child: Container(
                    width: _dotSize,
                    height: _dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unread ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.title, style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(notification.body, style: AppTextStyles.body),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        NotificationTimeAgo.format(
                          context,
                          notification.createdAt,
                          now,
                        ),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
