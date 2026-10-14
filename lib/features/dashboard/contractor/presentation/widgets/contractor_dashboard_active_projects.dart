import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_project_card.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_project.dart';

class ContractorDashboardActiveProjects extends StatelessWidget {
  const ContractorDashboardActiveProjects({
    super.key,
    required this.projects,
    this.onAllProjectsTap,
    this.onProjectTap,
  });

  final List<ContractorDashboardProject> projects;
  final VoidCallback? onAllProjectsTap;
  final ValueChanged<String>? onProjectTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSectionHeader(
          title: context.tr('dashboard.contractor.active_projects_title'),
          actionLabel: context.tr('dashboard.contractor.see_all'),
          onAction: onAllProjectsTap,
        ),
        if (projects.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Text(
              context.tr('dashboard.contractor.no_active_projects'),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final project = projects[index];
              final currency = context.tr('dashboard.contractor.currency');
              final budget = project.budget != null
                  ? '${project.budget!.toJson()} $currency'
                  : '';
              final date =
                  '${project.createdAt.year}/${project.createdAt.month.toString().padLeft(2, '0')}/${project.createdAt.day.toString().padLeft(2, '0')}';

              return AppProjectCard(
                title: project.title,
                subtitle: context.tr(
                  'dashboard.contractor.client_name',
                  namedArgs: {'name': project.clientName},
                ),
                statusLabel: context.tr(
                  'dashboard.contractor.project_status_waiting',
                ),
                statusTone: AppTone.attention,
                progress: project.progress,
                progressLabel: context.tr(
                  'dashboard.contractor.tasks_progress',
                  namedArgs: {
                    'approved': '${project.approvedTasksCount}',
                    'total': '${project.totalTasksCount}',
                  },
                ),
                percentLabel: '${(project.progress * 100).toInt()}%',
                dateLabel: date,
                amountLabel: budget,
                onTap: () => onProjectTap?.call(project.id),
              );
            },
          ),
      ],
    );
  }
}
