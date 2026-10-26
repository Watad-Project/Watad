import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_task_details_bloc.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_task_date.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_task_labels.dart';

/// A task without updates (GRA-49): proposed, accepted and not started, or
/// rejected. While it's proposed and the project in progress, the client
/// accepts it, or rejects it after confirming; then the page goes back to
/// the timeline, which reads the tasks again. Otherwise it only reads.
class ClientTaskDetailsPage extends StatelessWidget {
  const ClientTaskDetailsPage({
    required this.projectId,
    required this.taskId,
    super.key,
  });

  final String projectId;
  final String taskId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientTaskDetailsBloc, ClientTaskDetailsState>(
      listenWhen: (previous, current) =>
          (current.answered != null && previous.answered == null) ||
          (current.errorKey != null && current.errorKey != previous.errorKey),
      listener: (context, state) {
        if (state.answered case final answer?) {
          context.showSuccessSnackBar(
            context.tr(
              answer == TaskStatus.accepted
                  ? 'projects.client.task_accepted'
                  : 'projects.client.task_rejected',
            ),
          );
          // Back to the timeline, which opened this page and reloads.
          context.pop(true);
        } else if (state.errorKey case final key?) {
          context.showErrorSnackBar(context.tr(key));
        }
      },
      builder: (context, state) {
        final bloc = context.read<ClientTaskDetailsBloc>();
        final answering = state.answering;
        return Scaffold(
          appBar: AppTopBar(
            title: context.tr('projects.client.task_details_title'),
            onBack: () => context.pop(),
          ),
          body: AnimatedSwitcher(
            duration: AppMotion.enter,
            reverseDuration: AppMotion.exit,
            switchInCurve: AppMotion.enterCurve,
            switchOutCurve: AppMotion.exitCurve,
            child: _body(context, state),
          ),
          bottomNavigationBar: state.canAnswer
              ? AppActionBar(
                  primary: AppButton(
                    key: const Key('client_task_accept'),
                    label: context.tr('projects.client.task_accept'),
                    isLoading: answering == TaskStatus.accepted,
                    onPressed: answering == null
                        ? () => bloc.add(
                            const ClientTaskDetailsAnswered(
                              TaskStatus.accepted,
                            ),
                          )
                        : null,
                  ),
                  secondary: AppButton(
                    key: const Key('client_task_reject'),
                    label: context.tr('projects.client.task_reject_short'),
                    variant: AppButtonVariant.secondary,
                    isLoading: answering == TaskStatus.rejected,
                    onPressed: answering == null
                        ? () => _confirmReject(context, bloc)
                        : null,
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _body(BuildContext context, ClientTaskDetailsState state) {
    final task = state.task;
    if (task == null) {
      if (state.status == ClientTaskDetailsStatus.failure) {
        return AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(state.failure!.messageKey),
          onRetry: () => context.read<ClientTaskDetailsBloc>().add(
            ClientTaskDetailsFetched(projectId: projectId, taskId: taskId),
          ),
        );
      }
      return const AppLoadingIndicator(key: ValueKey('loading'));
    }
    final amount = task.amount;
    return ListView(
      key: const ValueKey('task'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Text(task.title, style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            for (final label in ClientTaskLabels.of(task))
              AppStatusBadge(label: context.tr(label.key), tone: label.tone),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(task.description, style: AppTextStyles.body),
        const SizedBox(height: AppSpacing.md),
        AppKeyValueList(
          rows: [
            AppKeyValueRow(
              label: context.tr('projects.client.task_amount'),
              value: amount == null
                  ? context.tr('projects.client.task_no_amount')
                  : AppMoneyText.format(context, amount),
            ),
            AppKeyValueRow(
              label: context.tr('projects.client.task_dates_label'),
              value: ClientTaskDate.days(
                context,
                task.startDate,
                task.finishDate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmReject(
    BuildContext context,
    ClientTaskDetailsBloc bloc,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: context.tr('projects.client.task_reject_title'),
      message: context.tr('projects.client.task_reject_message'),
      confirmLabel: context.tr('projects.client.task_reject'),
    );
    if (confirmed != null) {
      bloc.add(const ClientTaskDetailsAnswered(TaskStatus.rejected));
    }
  }
}
