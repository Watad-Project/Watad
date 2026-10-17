import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_project_card.dart';
import 'package:watad/core/enums/project_status.dart';
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
    final amountString = project.budget != null
        ? 'projects.client.budget_amount'.tr(
            namedArgs: {
              'amount': (project.budget!.halalas / 100).toStringAsFixed(2),
            },
          )
        : 'projects.client.budget_unspecified'.tr();
    final progress = project.status == ProjectStatus.completed ? 1.0 : 0.0;
    final percentLabel = project.status == ProjectStatus.completed
        ? '100%'
        : '0%';

    return AppProjectCard(
      title: project.title,
      subtitle: location,
      statusLabel: statusKey.tr(),
      statusTone: statusTone,
      progress: progress,
      progressLabel: 'projects.client.offers_count'.tr(
        namedArgs: {'count': '${project.pendingOfferCount}'},
      ),
      percentLabel: percentLabel,
      dateLabel: dateString,
      amountLabel: amountString,
      onTap: onTap,
    );
  }
}
