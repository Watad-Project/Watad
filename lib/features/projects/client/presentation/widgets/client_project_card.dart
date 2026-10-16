import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';

class ClientProjectCard extends StatelessWidget {
  const ClientProjectCard({required this.project, this.onTap, super.key});

  final ClientProject project;
  final VoidCallback? onTap;

  (String, AppTone) _statusInfo(ProjectStatus status) => switch (status) {
    ProjectStatus.open => ('projects.client.status_open', AppTone.attention),
    ProjectStatus.inProgress => (
      'projects.client.status_in_progress',
      AppTone.attention,
    ),
    ProjectStatus.completed => (
      'projects.client.status_completed',
      AppTone.success,
    ),
    ProjectStatus.cancelled => (
      'projects.client.status_cancelled',
      AppTone.danger,
    ),
    ProjectStatus.draft => ('projects.client.status_draft', AppTone.neutral),
  };

  @override
  Widget build(BuildContext context) {
    final (statusKey, statusTone) = _statusInfo(project.status);
    final location = project.district != null
        ? '${project.city} - ${project.district}'
        : project.city;
    final dateString =
        '${project.createdAt.year}/${project.createdAt.month.toString().padLeft(2, '0')}/${project.createdAt.day.toString().padLeft(2, '0')}';

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: AppTextStyles.h2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppStatusBadge(label: statusKey.tr(), tone: statusTone),
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
                  location,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(dateString, style: AppTextStyles.caption),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (project.budget != null)
                Expanded(
                  child: Text(
                    'projects.client.budget_amount'.tr(
                      namedArgs: {
                        'amount': (project.budget!.halalas / 100)
                            .toStringAsFixed(2),
                      },
                    ),
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Expanded(
                  child: Text(
                    'projects.client.budget_unspecified'.tr(),
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.neutralLight,
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppRadius.pill),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_offer_outlined,
                      size: 14,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      'projects.client.offers_count'.tr(
                        namedArgs: {'count': '${project.pendingOfferCount}'},
                      ),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
