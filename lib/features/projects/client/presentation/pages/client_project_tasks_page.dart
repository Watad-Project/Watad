import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/buttons/app_icon_button.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_timeline.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/chat_routes.dart';
import 'package:watad/core/router/routes/client_payments_routes.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_task.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_tasks_bloc.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_project_tasks_skeleton.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_project_title.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_task_date.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_task_labels.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_task_tag.dart';

/// The tasks of a project the contractor works on (GRA-47), as a timeline:
/// each task's name, amount, dates and status, with «التفاصيل» beside it.
/// Approving and rejecting happen on the task's own screen; «الدفع للمقاول»
/// at the bottom starts a payment.
class ClientProjectTasksPage extends StatelessWidget {
  const ClientProjectTasksPage({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientProjectTasksBloc, ClientProjectTasksState>(
      // A refresh that fails while the tasks are on screen keeps them, and
      // says so.
      listenWhen: (previous, current) =>
          current.status == ClientProjectTasksStatus.failure &&
          previous.status != ClientProjectTasksStatus.failure &&
          current.project != null,
      listener: (context, state) => context.showErrorSnackBar(
        context.tr(state.failure!.messageKey),
        onRetry: () => context.read<ClientProjectTasksBloc>().add(
          ClientProjectTasksFetched(projectId),
        ),
      ),
      builder: (context, state) {
        final project = state.project;
        return Scaffold(
          appBar: AppTopBar(
            title: project == null
                ? ''
                : ClientProjectTitle.of(context, project.title),
            onBack: () => context.pop(),
            actions: [
              if (project?.takerId case final takerId?)
                AppIconButton(
                  key: const Key('client_project_tasks_message'),
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: context.tr('projects.client.message_contractor'),
                  onPressed: () => context.pushNamed(
                    ChatRoutes.chatStartName,
                    pathParameters: {'userId': takerId},
                    queryParameters: {'project': projectId},
                  ),
                ),
            ],
          ),
          // Loading, the tasks and errors fade into each other.
          body: AnimatedSwitcher(
            duration: AppMotion.enter,
            reverseDuration: AppMotion.exit,
            switchInCurve: AppMotion.enterCurve,
            switchOutCurve: AppMotion.exitCurve,
            child: _body(context, state),
          ),
          bottomNavigationBar: state.canPay
              ? AppActionBar(
                  primary: AppButton(
                    key: const Key('client_project_tasks_pay'),
                    label: context.tr('projects.client.pay_contractor'),
                    onPressed: () => _pay(context),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _body(BuildContext context, ClientProjectTasksState state) {
    final bloc = context.read<ClientProjectTasksBloc>();
    final project = state.project;
    if (project == null) {
      if (state.status == ClientProjectTasksStatus.failure) {
        return AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(state.failure!.messageKey),
          onRetry: () => bloc.add(ClientProjectTasksFetched(projectId)),
        );
      }
      return const ClientProjectTasksSkeleton(key: ValueKey('loading'));
    }
    final contractor = project.contractorName;
    return RefreshIndicator(
      key: const ValueKey('tasks'),
      onRefresh: () async => bloc.add(ClientProjectTasksFetched(projectId)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          Text(
            context.tr('projects.client.tasks_title'),
            style: AppTextStyles.h1,
          ),
          if (contractor != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            AppVerifiedName(name: contractor, style: AppTextStyles.label),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (state.tasks.isEmpty)
            AppEmptyView(
              message: context.tr('projects.client.tasks_empty'),
              icon: Icons.checklist_outlined,
            )
          else
            AppTimeline(
              items: [for (final task in state.tasks) _item(context, task)],
            ),
        ],
      ),
    );
  }

  AppTimelineItem _item(BuildContext context, ClientProjectTask task) {
    final amount = task.amount;
    return AppTimelineItem(
      title: task.title,
      state: ClientTaskLabels.timelineState(task.status),
      subtitle: ClientTaskDate.days(context, task.startDate, task.finishDate),
      trailing: amount == null
          ? context.tr('projects.client.task_no_amount')
          : AppMoneyText.format(context, amount),
      tag: ClientTaskTag(task: task, onDetails: () => _openTask(context, task)),
    );
  }

  /// A task with updates opens its latest one, where the client decides; the
  /// others (proposed, accepted without updates, rejected) open the task.
  Future<void> _openTask(BuildContext context, ClientProjectTask task) async {
    final bloc = context.read<ClientProjectTasksBloc>();
    final updateId = task.lastUpdateId;
    if (updateId == null) {
      await context.pushNamed(
        ClientProjectsRoutes.taskDetailsName,
        pathParameters: {'projectId': projectId, 'taskId': task.id},
      );
    } else {
      await context.pushNamed(
        ClientProjectsRoutes.taskUpdateName,
        pathParameters: {'projectId': projectId, 'updateId': updateId},
      );
    }
    // A decision there changes the tasks.
    bloc.add(ClientProjectTasksFetched(projectId));
  }

  /// «الدفع للمقاول»: choosing the tasks to pay, then the bank transfer.
  Future<void> _pay(BuildContext context) async {
    final bloc = context.read<ClientProjectTasksBloc>();
    await context.pushNamed(
      ClientPaymentsRoutes.newPaymentName,
      pathParameters: {'projectId': projectId},
    );
    // A receipt sent changes the tasks' payments.
    bloc.add(ClientProjectTasksFetched(projectId));
  }
}
