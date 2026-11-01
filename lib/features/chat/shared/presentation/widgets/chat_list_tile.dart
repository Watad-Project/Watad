import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_summary.dart';
import 'package:watad/features/chat/shared/presentation/widgets/chat_time.dart';

/// One chat in «المحادثات»: their photo with an online dot, their name, the
/// project, the last message, its time and how many wait unread.
class ChatListTile extends StatelessWidget {
  const ChatListTile({
    required this.chat,
    required this.now,
    this.onTap,
    super.key,
  });

  final ChatSummary chat;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final other = chat.other;
    final unread = chat.unreadCount > 0;
    final project = chat.projectTitle;
    final message = chat.lastMessage;
    final at = chat.lastMessageAt;
    final secondary = AppTextStyles.caption.copyWith(
      color: AppColors.textSecondary,
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppAvatar(url: other?.avatarUrl, semanticLabel: other?.name),
                if (other?.isOnline ?? false)
                  PositionedDirectional(
                    bottom: 0,
                    end: 0,
                    child: Semantics(
                      label: context.tr('chat.online'),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          other?.name ?? context.tr('chat.closed_account'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label,
                        ),
                      ),
                      if (at != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          ChatTime.sameDay(at, now)
                              ? ChatTime.time(context, at)
                              : ChatTime.day(context, at, now),
                          style: secondary,
                        ),
                      ],
                    ],
                  ),
                  if (project != null)
                    Text(
                      context.tr('chat.project', args: [project]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: secondary,
                    ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          switch (message) {
                            null => context.tr('chat.no_messages_yet'),
                            _ when chat.lastMessageIsMine => context.tr(
                              'chat.you',
                              args: [message],
                            ),
                            _ => message,
                          },
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: unread
                              ? AppTextStyles.body.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                )
                              : AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          key: const Key('chat_list_unread'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.all(
                              Radius.circular(AppRadius.pill),
                            ),
                          ),
                          child: Text(
                            context.formatNumber(chat.unreadCount),
                            semanticsLabel: context.tr(
                              'chat.unread',
                              args: [context.formatNumber(chat.unreadCount)],
                            ),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
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
