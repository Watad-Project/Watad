import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_update.dart';

/// Where an update stands when the client has nothing to decide: a progress
/// update, which needs no decision; approved; rejected, with the client's
/// reason; or waiting while the project is no longer in progress. Nothing
/// while it waits for the client's decision: the buttons are below.
class ClientTaskUpdateDecision extends StatelessWidget {
  const ClientTaskUpdateDecision({required this.update, super.key});

  final ClientTaskUpdate update;

  @override
  Widget build(BuildContext context) {
    return switch ((update.proposedState, update.decision)) {
      (TaskUpdateState.inProgress, _) => AppStatusCard(
        tone: AppTone.neutral,
        title: context.tr('projects.client.update_progress_title'),
        subtitle: context.tr('projects.client.update_progress_subtitle'),
      ),
      (TaskUpdateState.done, TaskUpdateDecision.accepted) => AppStatusCard(
        tone: AppTone.success,
        title: context.tr('projects.client.update_decision_accepted'),
      ),
      (TaskUpdateState.done, TaskUpdateDecision.rejected) => AppStatusCard(
        tone: AppTone.danger,
        title: context.tr('projects.client.update_decision_rejected'),
        reasonTitle: context.tr('common.reason'),
        reasonText: [
          update.rejectionReason,
          update.rejectionDetails,
        ].nonNulls.join('\n'),
      ),
      (TaskUpdateState.done, TaskUpdateDecision.pending)
          when !update.canDecide =>
        AppStatusCard(
          tone: AppTone.neutral,
          title: context.tr('projects.client.update_cannot_decide'),
          subtitle: context.tr(
            'projects.client.update_project_not_in_progress',
          ),
        ),
      (TaskUpdateState.done, TaskUpdateDecision.pending) =>
        const SizedBox.shrink(),
    };
  }
}
