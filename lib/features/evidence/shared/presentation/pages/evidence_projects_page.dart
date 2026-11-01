import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/evidence_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_project.dart';
import 'package:watad/features/evidence/shared/presentation/bloc/evidence_projects_bloc.dart';
import 'package:watad/features/evidence/shared/presentation/widgets/evidence_labels.dart';

/// «تصدير سجل مشروع»: my contracted projects, newest first; tapping one
/// exports it.
class EvidenceProjectsPage extends StatelessWidget {
  const EvidenceProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('evidence.projects_title'),
        onBack: () => context.pop(),
      ),
      body: BlocBuilder<EvidenceProjectsBloc, EvidenceProjectsState>(
        builder: (context, state) => switch (state) {
          EvidenceProjectsInitial() ||
          EvidenceProjectsLoadInProgress() => const AppLoadingIndicator(),
          EvidenceProjectsLoadFailure(:final failure) => AppErrorView(
            message: context.tr(failure.messageKey),
            onRetry: () => context.read<EvidenceProjectsBloc>().add(
              const EvidenceProjectsFetched(),
            ),
          ),
          EvidenceProjectsLoadSuccess(:final projects) when projects.isEmpty =>
            AppEmptyView(
              message: context.tr('evidence.projects_empty'),
              icon: Icons.description_outlined,
            ),
          EvidenceProjectsLoadSuccess(:final projects) => RefreshIndicator(
            onRefresh: () async => context.read<EvidenceProjectsBloc>().add(
              const EvidenceProjectsFetched(),
            ),
            child: ListView.separated(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              itemCount: projects.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => index == 0
                  ? Text(
                      context.tr('evidence.projects_hint'),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textBody,
                      ),
                    )
                  : _ProjectRow(project: projects[index - 1]),
            ),
          ),
        },
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project});

  final EvidenceProject project;

  @override
  Widget build(BuildContext context) {
    final otherParty = project.otherParty;
    final amount = project.agreedAmount;
    return AppCard(
      onTap: () => context.pushNamed(
        EvidenceRoutes.evidenceExportName,
        pathParameters: {'projectId': project.id},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(project.title, style: AppTextStyles.label)),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: AppStatusBadge(
                  label: context.tr(
                    EvidenceLabels.projectStatusKey(project.status),
                  ),
                  tone: EvidenceLabels.projectStatusTone(project.status),
                ),
              ),
            ],
          ),
          if (otherParty != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              otherParty,
              style: AppTextStyles.body.copyWith(color: AppColors.textBody),
            ),
          ],
          if (amount != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppMoneyText(amount, style: AppTextStyles.label),
          ],
        ],
      ),
    );
  }
}
