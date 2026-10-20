import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_project_card.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_project_status.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_project_title.dart';

/// One of the client's projects, on the shared `AppProjectCard`: its first
/// photo (the striped placeholder without one) with the status, title and
/// place, the approved share of its tasks («قيد التخطيط» before there are
/// any), and the amount. The bottom line says what matters now: why the
/// deed was rejected, the offers waiting, or the contractor at work. A tap
/// opens its offers, or a new deed's upload when the deed was rejected.
class ClientProjectCard extends StatelessWidget {
  const ClientProjectCard({required this.project, this.onTap, super.key});

  final ClientProject project;

  /// Null: the card isn't tappable (a project in progress or done, whose
  /// screens come with later features).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final district = project.district;
    final status = ClientProjectStatus.of(project);
    final progress = project.progress;
    final amount = project.agreedAmount ?? project.budget;
    return AppProjectCard(
      title: ClientProjectTitle.of(context, project.title),
      subtitle: district == null || district.isEmpty
          ? project.city
          : '${project.city} — $district',
      statusLabel: context.tr(status.key),
      statusTone: status.tone,
      imageUrl: project.photoUrl,
      progress: progress,
      progressLabel: progress == null
          ? context.tr('projects.client.tasks_planning')
          : context.tr(
              'projects.client.tasks_progress',
              args: [
                context.formatNumber(project.approvedTaskCount),
                context.formatNumber(project.taskCount),
              ],
            ),
      percentLabel: context.tr(
        'projects.client.tasks_percent',
        args: [context.formatNumber(((progress ?? 0) * 100).round())],
      ),
      dateLabel: _whatMattersNow(context),
      amountLabel: amount == null
          ? context.tr('projects.client.no_budget')
          : AppMoneyText.format(context, amount),
      onTap: onTap,
    );
  }

  String _whatMattersNow(BuildContext context) {
    if (project.deedStatus == ClientDeedVerificationStatus.rejected) {
      return context.tr(
        'projects.client.deed_rejected_reason',
        args: [
          project.deedRejectionReason ??
              context.tr('projects.client.deed_rejected_no_reason'),
        ],
      );
    }
    final offers = project.pendingOfferCount;
    return switch (project.status) {
      ProjectStatus.open when offers == 0 => context.tr(
        'projects.client.no_offers_yet',
      ),
      ProjectStatus.open => context.plural(
        'projects.client.offers_count',
        offers,
        args: [context.formatNumber(offers)],
      ),
      _ => project.contractorName ?? '',
    };
  }
}
