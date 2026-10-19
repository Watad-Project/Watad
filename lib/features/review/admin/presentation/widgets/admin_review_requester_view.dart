import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_details.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_review_time_ago.dart';

/// «مقدّم الطلب»: who asked for the verification, from their account.
class AdminReviewRequesterView extends StatelessWidget {
  const AdminReviewRequesterView({
    required this.details,
    required this.now,
    super.key,
  });

  final AdminReviewDetails details;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final requester = details.requester;
    final memberSince = requester.memberSince;
    final requestedAt = details.requestedAt;
    final isDeed = details.target.kind == AdminReviewKind.deed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: context.tr('review.requester_title'),
          padding: EdgeInsetsDirectional.zero,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          child: Row(
            children: [
              AppAvatar(
                url: requester.avatarUrl,
                size: 56,
                semanticLabel: requester.name,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(requester.name, style: AppTextStyles.label),
                    const SizedBox(height: AppSpacing.xxs),
                    AppStatusBadge(
                      label: context.tr(
                        isDeed ? 'review.for_client' : 'review.for_contractor',
                      ),
                      tone: AppTone.neutral,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (memberSince != null || requestedAt != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppKeyValueList(
            rows: [
              if (requestedAt != null)
                AppKeyValueRow(
                  label: context.tr('review.field_requested_at'),
                  value: AdminReviewTimeAgo.format(context, requestedAt, now),
                ),
              if (memberSince != null)
                AppKeyValueRow(
                  label: context.tr('review.field_member_since'),
                  value: AdminReviewTimeAgo.format(context, memberSince, now),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
