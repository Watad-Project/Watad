import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_project_status_badge.dart';

/// One of the client's projects: title, place, budget, status and, while
/// it's open, how many offers wait. A tap opens its offers.
class ClientProjectCard extends StatelessWidget {
  const ClientProjectCard({
    required this.project,
    required this.onTap,
    super.key,
  });

  final ClientProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final district = project.district;
    final budget = project.budget;
    final offers = project.pendingOfferCount;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(project.title, style: AppTextStyles.label)),
              const SizedBox(width: AppSpacing.xs),
              ClientProjectStatusBadge(status: project.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            district == null || district.isEmpty
                ? project.city
                : '${project.city} — $district',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: budget == null
                    ? Text(
                        context.tr('projects.no_budget'),
                        style: AppTextStyles.caption,
                      )
                    : AppMoneyText(budget, style: AppTextStyles.label),
              ),
              if (project.status == ProjectStatus.open)
                Text(
                  offers == 0
                      ? context.tr('projects.no_offers_yet')
                      : context.plural(
                          'projects.offers_count',
                          offers,
                          args: [context.formatNumber(offers)],
                        ),
                  style: AppTextStyles.label.copyWith(
                    color: offers == 0
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
