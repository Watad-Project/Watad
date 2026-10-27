import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_conversation.dart';
import 'package:watad/features/chat/shared/presentation/widgets/chat_time.dart';

/// Under the top bar: their photo, online now or when they were last seen,
/// and the chat's project, which opens it when it's mine.
class ChatHeader extends StatelessWidget {
  const ChatHeader({
    required this.conversation,
    required this.now,
    this.onProjectTap,
    super.key,
  });

  final ChatConversation conversation;
  final DateTime now;
  final VoidCallback? onProjectTap;

  @override
  Widget build(BuildContext context) {
    final other = conversation.other;
    final lastSeenAt = other?.lastSeenAt;
    final presence = switch (other) {
      null => context.tr('chat.closed_account'),
      _ when other.isOnline => context.tr('chat.online'),
      _ when lastSeenAt != null => ChatTime.lastSeen(context, lastSeenAt, now),
      _ => null,
    };
    final projectTitle = conversation.projectTitle;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            AppAvatar(
              url: other?.avatarUrl,
              size: 40,
              semanticLabel: other?.name,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (presence != null)
                    Row(
                      children: [
                        if (other?.isOnline ?? false) ...[
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox.square(dimension: 8),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                        ],
                        Expanded(
                          child: Text(
                            presence,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (projectTitle != null)
                    InkWell(
                      onTap: onProjectTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xxs,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.tr(
                                  'chat.project',
                                  args: [projectTitle],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.label.copyWith(
                                  color: onProjectTap == null
                                      ? AppColors.textBody
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ),
                            if (onProjectTap != null)
                              // Points to the end of the line; it flips in
                              // RTL by itself.
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: AppColors.primaryDark,
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
