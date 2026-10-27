import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chat_conversation_bloc.dart';
import 'package:watad/features/chat/shared/presentation/widgets/chat_message_bubble.dart';

/// A message of mine on its way: «جارٍ الإرسال», or, when it failed,
/// «إعادة المحاولة» and «حذف».
class ChatPendingBubble extends StatelessWidget {
  const ChatPendingBubble({
    required this.message,
    required this.onRetry,
    required this.onDiscard,
    super.key,
  });

  final ChatPendingMessage message;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final photo = message.photo;
    final text = message.text;
    final status = AppTextStyles.caption.copyWith(color: AppColors.white);
    return Opacity(
      opacity: message.hasFailed ? 1 : 0.7,
      child: ChatBubbleFrame(
        isMine: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photo != null)
              ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.md),
                ),
                child: Image.memory(
                  Uint8List.fromList(photo.bytes),
                  width: ChatMessageBubble.photoSize,
                  height: ChatMessageBubble.photoSize,
                  fit: BoxFit.cover,
                  semanticLabel: context.tr('chat.photo'),
                ),
              ),
            if (text != null) ...[
              if (photo != null) const SizedBox(height: AppSpacing.xs),
              Text(
                text,
                style: AppTextStyles.body.copyWith(color: AppColors.white),
              ),
            ],
            const SizedBox(height: AppSpacing.xxs),
            if (message.hasFailed)
              Wrap(
                spacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppColors.white,
                  ),
                  Text(context.tr('chat.not_sent'), style: status),
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.white,
                    ),
                    child: Text(context.tr('common.retry')),
                  ),
                  TextButton(
                    onPressed: onDiscard,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.white,
                    ),
                    child: Text(context.tr('chat.discard')),
                  ),
                ],
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(
                    dimension: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(context.tr('chat.sending'), style: status),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
