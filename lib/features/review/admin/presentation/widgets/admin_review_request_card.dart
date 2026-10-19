import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_review_time_ago.dart';

/// One pending license: who sent it and when, tap to see the files, and the
/// two decisions.
class AdminReviewRequestCard extends StatelessWidget {
  const AdminReviewRequestCard({
    required this.request,
    required this.now,
    required this.isBusy,
    required this.onOpen,
    required this.onApprove,
    required this.onReject,
    super.key,
  });

  final AdminReviewRequest request;
  final DateTime now;

  /// A decision on this request is being sent.
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final requestedAt = request.requestedAt;
    final sender = requestedAt == null
        ? request.companyName
        : '${request.companyName} · '
              '${AdminReviewTimeAgo.format(context, requestedAt, now)}';
    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('review.license_document'),
                  style: AppTextStyles.label,
                ),
              ),
              AppStatusBadge(
                label: context.tr('review.for_contractor'),
                tone: AppTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(sender, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: context.tr('review.approve'),
                  variant: AppButtonVariant.dark,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onApprove,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: context.tr('review.reject'),
                  variant: AppButtonVariant.secondary,
                  onPressed: isBusy ? null : onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
