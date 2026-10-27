import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/buttons/app_icon_button.dart';
import 'package:watad/core/components/display/app_icon_tag.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_network_image.dart';
import 'package:watad/core/components/display/app_timeline.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/chat_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_project_tasks_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/widgets/contractor_project_tasks_skeleton.dart';
import 'package:watad/features/tasks/contractor/presentation/widgets/contractor_task_date.dart';
import 'package:watad/features/tasks/contractor/presentation/widgets/contractor_task_labels.dart';

/// Contractor's project schedule screen (`/contractor/tasks/:projectId`,
/// GRA-37): displays the contract header, photo, task timeline, summary counts,
/// and bottom actions to add or update tasks.
class ContractorProjectTasksPage extends StatelessWidget {
  const ContractorProjectTasksPage({
    required this.projectId,
    this.onAddTask,
    this.onUpdateTask,
    this.onTaskTap,
    this.today,
    super.key,
  });

  final String projectId;
  final Future<void> Function(BuildContext context, String projectId)?
  onAddTask;
  final Future<void> Function(BuildContext context, String projectId)?
  onUpdateTask;
  final Future<void> Function(BuildContext context, ContractorProjectTask task)?
  onTaskTap;

  /// Optional reference date for deterministic date formatting in tests.
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<
      ContractorProjectTasksBloc,
      ContractorProjectTasksState
    >(
      listenWhen: (previous, current) =>
          current.status == ContractorProjectTasksStatus.failure &&
          previous.status != ContractorProjectTasksStatus.failure &&
          current.project != null,
      listener: (context, state) => context.showErrorSnackBar(
        context.tr(state.failure!.messageKey),
        onRetry: () => context.read<ContractorProjectTasksBloc>().add(
          ContractorProjectTasksFetched(projectId),
        ),
      ),
      builder: (context, state) {
        final project = state.project;
        return Scaffold(
          appBar: AppTopBar(
            title: project == null ? '' : project.displayTitle,
            onBack: () => context.pop(),
            actions: [
              if (project?.ownerId case final ownerId?)
                AppIconButton(
                  key: const Key('contractor_project_tasks_message'),
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: context.tr('tasks.contractor.message_client'),
                  onPressed: () => context.pushNamed(
                    ChatRoutes.chatStartName,
                    pathParameters: {'userId': ownerId},
                    queryParameters: {'project': project!.id},
                  ),
                ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: AppMotion.enter,
            reverseDuration: AppMotion.exit,
            switchInCurve: AppMotion.enterCurve,
            switchOutCurve: AppMotion.exitCurve,
            child: _body(context, state),
          ),
          bottomNavigationBar: state.canAddTask
              ? _bottomBar(context, state)
              : null,
        );
      },
    );
  }

  Widget _body(BuildContext context, ContractorProjectTasksState state) {
    final bloc = context.read<ContractorProjectTasksBloc>();
    final project = state.project;
    if (project == null) {
      if (state.status == ContractorProjectTasksStatus.failure) {
        return AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(state.failure!.messageKey),
          onRetry: () => bloc.add(ContractorProjectTasksFetched(projectId)),
        );
      }
      return const ContractorProjectTasksSkeleton(key: ValueKey('loading'));
    }

    return RefreshIndicator(
      key: const ValueKey('tasks'),
      onRefresh: () async => bloc.add(ContractorProjectTasksFetched(projectId)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          AppNetworkImage(
            key: const Key('contractor_project_tasks_photo'),
            url: project.photoUrl,
            height: 180,
            width: double.infinity,
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(project.displayTitle, style: AppTextStyles.h1),
          const SizedBox(height: AppSpacing.xxs),
          Text(_subtitle(context, project), style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.lg),
          if (state.tasks.isEmpty)
            AppEmptyView(
              message: context.tr('tasks.contractor.empty_tasks'),
              icon: Icons.checklist_outlined,
            )
          else
            AppTimeline(
              items: [
                for (final task in state.tasks) _timelineItem(context, task),
              ],
            ),
        ],
      ),
    );
  }

  String _subtitle(BuildContext context, ContractorTaskProject project) {
    final amount = project.contractAmount;
    if (amount == null) {
      return context.tr(
        'tasks.contractor.client_only',
        args: [project.ownerName],
      );
    }
    return context.tr(
      'tasks.contractor.client_and_amount',
      args: [project.ownerName, AppMoneyText.format(context, amount)],
    );
  }

  AppTimelineItem _timelineItem(
    BuildContext context,
    ContractorProjectTask task,
  ) {
    final amount = task.amount;
    final tagInfo = ContractorTaskLabels.tagOf(task);
    final Widget tag = AppIconTag(
      label: context.tr(tagInfo.key),
      icon: tagInfo.icon,
      tone: tagInfo.tone,
    );

    return AppTimelineItem(
      title: task.title,
      state: ContractorTaskLabels.timelineState(task.status),
      subtitle: ContractorTaskDate.subtitle(context, task, today: today),
      trailing: amount == null ? null : AppMoneyText.format(context, amount),
      tag: task.hasLatestUpdate
          ? Semantics(
              button: true,
              child: InkWell(
                key: Key('contractor_task_update_${task.id}'),
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.md),
                ),
                onTap: () => _openTaskUpdate(context, task),
                child: tag,
              ),
            )
          : tag,
    );
  }

  Widget _bottomBar(BuildContext context, ContractorProjectTasksState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.hasSummary)
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Text(
                _summaryText(context, state),
                key: const Key('contractor_project_tasks_summary'),
                style: AppTextStyles.caption,
              ),
            ),
          ),
        AppActionBar(
          primary: AppButton(
            key: const Key('contractor_project_tasks_add'),
            label: context.tr('tasks.contractor.add_task'),
            onPressed: () => _handleAddTask(context),
          ),
          secondary: AppButton(
            key: const Key('contractor_project_tasks_update'),
            label: context.tr('tasks.contractor.update_task'),
            variant: AppButtonVariant.secondary,
            onPressed: state.canUpdateTask
                ? () => _handleUpdateTask(context)
                : null,
          ),
        ),
      ],
    );
  }

  String _summaryText(BuildContext context, ContractorProjectTasksState state) {
    final parts = <String>[
      if (state.doneCount > 0)
        context.plural(
          'tasks.contractor.summary_done',
          state.doneCount,
          args: [context.formatNumber(state.doneCount)],
        ),
      if (state.proposedCount > 0)
        context.plural(
          'tasks.contractor.summary_proposed',
          state.proposedCount,
          args: [context.formatNumber(state.proposedCount)],
        ),
    ];
    return parts.join(' · ');
  }

  Future<void> _handleAddTask(BuildContext context) async {
    final callback = onAddTask;
    if (callback == null) return;
    final bloc = context.read<ContractorProjectTasksBloc>();
    await callback(context, projectId);
    if (context.mounted) {
      bloc.add(ContractorProjectTasksFetched(projectId));
    }
  }

  Future<void> _handleUpdateTask(BuildContext context) async {
    final callback = onUpdateTask;
    if (callback == null) return;
    final bloc = context.read<ContractorProjectTasksBloc>();
    await callback(context, projectId);
    if (context.mounted) {
      bloc.add(ContractorProjectTasksFetched(projectId));
    }
  }

  Future<void> _openTaskUpdate(
    BuildContext context,
    ContractorProjectTask task,
  ) async {
    final callback = onTaskTap;
    if (callback == null) return;
    final bloc = context.read<ContractorProjectTasksBloc>();
    await callback(context, task);
    if (context.mounted) {
      bloc.add(ContractorProjectTasksFetched(projectId));
    }
  }
}
