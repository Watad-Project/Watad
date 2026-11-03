import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_image_viewer.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_photo_tile.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/contractor_tasks_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_update.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_status_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/widgets/contractor_task_date.dart';

/// Task update status screen (`/contractor/tasks/:projectId/updates/:updateId`,
/// GRA-39): shows what happened to an update the contractor sent about a task
/// (pending client review, rejected with reason and retry action, or accepted
/// with the payment it created) and updates live via Supabase Realtime.
class ContractorTaskUpdateStatusPage extends StatelessWidget {
  const ContractorTaskUpdateStatusPage({
    required this.projectId,
    required this.updateId,
    this.onSendNewUpdate,
    this.now,
    super.key,
  });

  final String projectId;
  final String updateId;

  /// Optional override for «إرسال تحديث جديد» in widget tests.
  final Future<void> Function(
    BuildContext context,
    ContractorTaskUpdate update,
  )?
  onSendNewUpdate;

  /// Optional reference timestamp for deterministic date formatting in tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      ContractorTaskUpdateStatusBloc,
      ContractorTaskUpdateStatusState
    >(
      builder: (context, state) {
        final update = state.update;
        return Scaffold(
          appBar: AppTopBar(
            title: update == null ? '' : update.displayProjectTitle,
            onBack: () => _popIfPossible(context),
          ),
          body: AnimatedSwitcher(
            duration: AppMotion.enter,
            reverseDuration: AppMotion.exit,
            switchInCurve: AppMotion.enterCurve,
            switchOutCurve: AppMotion.exitCurve,
            child: _body(context, state),
          ),
        );
      },
    );
  }

  void _popIfPossible(BuildContext context) {
    if (GoRouter.maybeOf(context)?.canPop() ?? false) {
      context.pop();
    }
  }

  Widget _body(BuildContext context, ContractorTaskUpdateStatusState state) {
    final bloc = context.read<ContractorTaskUpdateStatusBloc>();
    final update = state.update;

    if (update == null) {
      if (state.status == ContractorTaskUpdateStatusStatus.failure) {
        return AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(state.failure!.messageKey),
          onRetry: () =>
              bloc.add(ContractorTaskUpdateStatusRefreshed(updateId)),
        );
      }
      return const AppLoadingIndicator(key: ValueKey('loading'));
    }

    return RefreshIndicator(
      key: ValueKey('status_${update.decision.name}'),
      onRefresh: () async =>
          bloc.add(ContractorTaskUpdateStatusRefreshed(updateId)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          Text(update.taskTitle, style: AppTextStyles.h1),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            _metaLine(context, update),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _statusCard(context, update),
          if (update.rejectionPhotoUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (var i = 0; i < update.rejectionPhotoUrls.length; i++)
                  AppPhotoTile(
                    key: ValueKey('contractor_task_update_rejection_photo_$i'),
                    image: NetworkImage(update.rejectionPhotoUrls[i]),
                    size: 96,
                    semanticLabel: context.formatNumber(i + 1),
                    onTap: () => AppImageViewer.show(
                      context,
                      url: update.rejectionPhotoUrls[i],
                      title: update.rejectionReason ?? update.taskTitle,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _metaLine(BuildContext context, ContractorTaskUpdate update) {
    final sentWhen = ContractorTaskDate.sentAt(
      context,
      update.createdAt,
      now: now,
    );
    final proposedLabel = switch (update.proposedState) {
      TaskUpdateState.inProgress => context.tr(
        'tasks.contractor.state_in_progress',
      ),
      TaskUpdateState.done => context.tr('tasks.contractor.state_done'),
    };
    return context.tr(
      'tasks.contractor.update_status_sent_meta',
      args: [sentWhen, proposedLabel],
    );
  }

  Widget _statusCard(BuildContext context, ContractorTaskUpdate update) {
    return switch (update.decision) {
      TaskUpdateDecision.pending => AppStatusCard(
        key: const Key('contractor_task_update_status_card_pending'),
        tone: AppTone.attention,
        title: context.tr('tasks.contractor.update_status_pending_title'),
        subtitle: context.tr('tasks.contractor.update_status_pending_subtitle'),
      ),
      TaskUpdateDecision.rejected => AppStatusCard(
        key: const Key('contractor_task_update_status_card_rejected'),
        tone: AppTone.danger,
        title: context.tr('tasks.contractor.update_status_rejected_title'),
        reasonTitle: update.rejectionReason,
        reasonText: update.rejectionDetails,
        action: update.canSendNewUpdate
            ? AppButton(
                key: const Key('contractor_task_update_status_retry'),
                label: context.tr('tasks.contractor.update_status_send_new'),
                onPressed: () => _handleSendNewUpdate(context, update),
              )
            : null,
      ),
      TaskUpdateDecision.accepted => switch (update.proposedState) {
        TaskUpdateState.done => _acceptedDoneCard(context, update),
        TaskUpdateState.inProgress => AppStatusCard(
          key: const Key('contractor_task_update_status_card_accepted'),
          tone: AppTone.success,
          title: context.tr('tasks.contractor.update_status_in_progress_title'),
          subtitle: context.tr(
            'tasks.contractor.update_status_in_progress_subtitle',
          ),
        ),
      },
    };
  }

  Widget _acceptedDoneCard(BuildContext context, ContractorTaskUpdate update) {
    final amount = update.createdPaymentAmount;
    return AppStatusCard(
      key: const Key('contractor_task_update_status_card_accepted'),
      tone: AppTone.success,
      title: context.tr('tasks.contractor.update_status_accepted_title'),
      subtitle: amount == null
          ? context.tr('tasks.contractor.update_status_accepted_no_payment')
          : context.tr(
              'tasks.contractor.update_status_accepted_with_payment',
              args: [AppMoneyText.format(context, amount)],
            ),
    );
  }

  Future<void> _handleSendNewUpdate(
    BuildContext context,
    ContractorTaskUpdate update,
  ) async {
    final callback = onSendNewUpdate;
    if (callback != null) {
      await callback(context, update);
      return;
    }
    if (GoRouter.maybeOf(context) != null) {
      await context.pushNamed<bool>(
        ContractorTasksRoutes.taskUpdateName,
        pathParameters: {'projectId': projectId},
        queryParameters: {'taskId': update.taskId},
      );
    }
  }
}
