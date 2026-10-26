import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_state_stepper.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_update.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_task_date.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_task_update_decision.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_task_update_photos.dart';

/// What an update says (GRA-49): the task, who sent it and when, the state
/// it moves the task to (filling in as it shows, and on to «معتمدة» once
/// the client approves), the note, the evidence photos, the amount approving
/// it releases, and where it stands.
class ClientTaskUpdateDetails extends StatelessWidget {
  const ClientTaskUpdateDetails({required this.update, super.key});

  final ClientTaskUpdate update;

  /// Where the update puts the task: in progress, done, or done and
  /// approved.
  static int stepOf(ClientTaskUpdate update) =>
      switch ((update.proposedState, update.decision)) {
        (TaskUpdateState.inProgress, _) => 0,
        (TaskUpdateState.done, TaskUpdateDecision.accepted) => 2,
        (TaskUpdateState.done, _) => 1,
      };

  @override
  Widget build(BuildContext context) {
    final name = update.contractorName;
    final amount = update.taskAmount;
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Text(update.taskTitle, style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            AppAvatar(url: update.contractorAvatarUrl, size: 44),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name != null)
                    AppVerifiedName(name: name, style: AppTextStyles.label),
                  Text(
                    context.tr(
                      'projects.client.update_sent_at',
                      args: [ClientTaskDate.moment(context, update.createdAt)],
                    ),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppStateStepper(
          labels: [
            context.tr('projects.client.update_state_in_progress'),
            context.tr('projects.client.update_state_done'),
            context.tr('projects.client.update_state_approved'),
          ],
          currentIndex: stepOf(update),
          animateFrom: 0,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.tr('projects.client.update_note'),
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          update.note ?? context.tr('projects.client.update_no_note'),
          style: AppTextStyles.body,
        ),
        if (update.photoUrls.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('projects.client.update_photos'),
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: AppSpacing.xs),
          ClientTaskUpdatePhotos(urls: update.photoUrls),
        ],
        if (amount != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AppKeyValueList(
            rows: [
              AppKeyValueRow(
                label: context.tr('projects.client.update_amount'),
                value: AppMoneyText.format(context, amount),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ClientTaskUpdateDecision(update: update),
      ],
    );
  }
}
