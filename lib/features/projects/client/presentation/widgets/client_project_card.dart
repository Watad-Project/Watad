import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_number_formatter.dart';

/// Card showing one client project in the "My projects" list.
class ClientProjectCard extends StatelessWidget {
  const ClientProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.onReuploadDeed,
  });

  final ClientProject project;
  final VoidCallback? onTap;
  final VoidCallback? onReuploadDeed;

  bool get _isRejected =>
      project.status == ProjectStatus.cancelled ||
      project.deedStatus == 'rejected';

  bool get _isOpen => project.status == ProjectStatus.open;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final (statusLabel, statusTone) = _resolveStatus(context);

    final locationText =
        project.district != null && project.district!.isNotEmpty
        ? '${project.city} · ${project.district}'
        : project.city;

    final budgetText = _resolveBudgetText(context, isArabic: isArabic);

    return AppCard(
      onTap: _isOpen ? onTap : (_isRejected ? onReuploadDeed : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: AppTextStyles.h2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppStatusBadge(label: statusLabel, tone: statusTone),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  locationText,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (budgetText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    budgetText,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          if (_isOpen)
            InkWell(
              onTap: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_offer_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        project.pendingOfferCount > 0
                            ? context.tr(
                                'projects.client.offers_count',
                                namedArgs: {
                                  'count': ClientNumberFormatter.formatCount(
                                    project.pendingOfferCount,
                                    isArabic: isArabic,
                                  ),
                                },
                              )
                            : context.tr('projects.client.no_offers_yet'),
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ),
            )
          else if (_isRejected)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.rejectionReason ??
                        context.tr('projects.client.deed_rejected_hint'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  height: 36,
                  width: 130,
                  child: AppButton(
                    label: context.tr('projects.client.reupload_deed'),
                    onPressed: onReuploadDeed,
                    variant: AppButtonVariant.secondary,
                  ),
                ),
              ],
            )
          else
            Text(
              context.tr('projects.client.under_review_desc'),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  (String, AppTone) _resolveStatus(BuildContext context) {
    if (_isRejected) {
      return (context.tr('projects.client.status_rejected'), AppTone.danger);
    }
    if (_isOpen) {
      return (context.tr('projects.client.status_verified'), AppTone.success);
    }
    return (
      context.tr('projects.client.status_under_review'),
      AppTone.attention,
    );
  }

  String? _resolveBudgetText(BuildContext context, {required bool isArabic}) {
    if (project.budgetMin != null && project.budgetMax != null) {
      return context.tr(
        'projects.client.budget_range_format',
        namedArgs: {
          'min': ClientNumberFormatter.formatAmount(
            project.budgetMin!,
            isArabic: isArabic,
          ),
          'max': ClientNumberFormatter.formatAmount(
            project.budgetMax!,
            isArabic: isArabic,
          ),
        },
      );
    }
    if (project.budget != null) {
      return context.tr(
        'projects.client.budget_single_format',
        namedArgs: {
          'amount': ClientNumberFormatter.formatAmount(
            project.budget!,
            isArabic: isArabic,
          ),
        },
      );
    }
    return null;
  }
}
