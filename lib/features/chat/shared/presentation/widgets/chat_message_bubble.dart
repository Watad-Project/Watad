import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_image_viewer.dart';
import 'package:watad/core/components/display/app_network_image.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_message.dart';
import 'package:watad/features/chat/shared/presentation/widgets/chat_time.dart';

/// One message: mine at the end of the line in orange, theirs at the start
/// in white. A photo shows as a thumbnail that opens full screen; my
/// messages carry a read tick.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({required this.message, super.key});

  final ChatMessage message;

  /// The thumbnail's side: a photo, not text, so a fixed size is fine.
  static const double photoSize = 220;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    final content = message.content;
    final photoUrl = message.photoUrl;
    final foreground = mine ? AppColors.white : AppColors.ink;
    return ChatBubbleFrame(
      isMine: mine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.hasPhoto)
            Semantics(
              button: photoUrl != null,
              label: context.tr('chat.photo'),
              child: GestureDetector(
                onTap: photoUrl == null
                    ? null
                    : () => AppImageViewer.show(context, url: photoUrl),
                child: AppNetworkImage(
                  url: photoUrl,
                  width: photoSize,
                  height: photoSize,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadius.md),
                  ),
                  semanticLabel: context.tr('chat.photo'),
                ),
              ),
            ),
          if (content != null) ...[
            if (message.hasPhoto) const SizedBox(height: AppSpacing.xs),
            Text(
              content,
              style: AppTextStyles.body.copyWith(color: foreground),
            ),
          ],
          const SizedBox(height: AppSpacing.xxs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  ChatTime.time(context, message.createdAt),
                  style: AppTextStyles.caption.copyWith(
                    color: mine
                        ? AppColors.primaryLight
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (mine) ...[
                const SizedBox(width: AppSpacing.xxs),
                Icon(
                  message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                  size: 16,
                  color: AppColors.primaryLight,
                  semanticLabel: context.tr(
                    message.isRead ? 'chat.read' : 'chat.sent',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The bubble around a message: its side, color and width.
class ChatBubbleFrame extends StatelessWidget {
  const ChatBubbleFrame({required this.isMine, required this.child, super.key});

  final bool isMine;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isMine ? AppColors.primary : AppColors.surface,
            border: isMine ? null : Border.all(color: AppColors.border),
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
          ),
          child: child,
        ),
      ),
    );
  }
}
