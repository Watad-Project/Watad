import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_task.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_task_labels.dart';

/// Under a task on the timeline: its status tags and «التفاصيل», which
/// opens the task's screen. They wrap onto a new line when the text is
/// large.
class ClientTaskTag extends StatelessWidget {
  const ClientTaskTag({required this.task, required this.onDetails, super.key});

  final ClientProjectTask task;

  /// Opens the task's screen; null while it can't open.
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final label in ClientTaskLabels.of(task))
          AppStatusBadge(label: context.tr(label.key), tone: label.tone),
        AppButton(
          key: ValueKey('client_task_details_${task.id}'),
          label: context.tr('common.details'),
          variant: AppButtonVariant.link,
          trailingIcon: Icons.chevron_right,
          onPressed: onDetails,
        ),
      ],
    );
  }
}
