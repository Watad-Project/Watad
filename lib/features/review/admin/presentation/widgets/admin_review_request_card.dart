import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_review_time_ago.dart';

/// One request in the queue's grid: what to check, who sent it and when, and
/// «التفاصيل», which opens everything the admin decides on. The card itself
/// isn't tappable.
class AdminReviewRequestCard extends StatelessWidget {
  const AdminReviewRequestCard({
    required this.request,
    required this.now,
    required this.onDetails,
    super.key,
  });

  final AdminReviewRequest request;
  final DateTime now;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final isDeed = request.kind == AdminReviewKind.deed;
    final requestedAt = request.requestedAt;
    return AppCard(
      // In a grid row the cards share the taller one's height: the button
      // stays at the bottom.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  isDeed ? 'review.deed_document' : 'review.license_document',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppStatusBadge(
                label: context.tr(
                  isDeed ? 'review.for_client' : 'review.for_contractor',
                ),
                tone: AppTone.neutral,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  AppAvatar(
                    url: request.requesterAvatarUrl,
                    size: 32,
                    semanticLabel: request.requesterName,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      request.requesterName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
              if (requestedAt != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  AdminReviewTimeAgo.format(context, requestedAt, now),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: context.tr('review.details'),
            variant: AppButtonVariant.secondary,
            onPressed: onDetails,
          ),
        ],
      ),
    );
  }
}
