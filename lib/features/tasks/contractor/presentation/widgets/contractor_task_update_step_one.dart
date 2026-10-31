import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/presentation/widgets/contractor_task_choice_tile.dart';

/// Step 1 of `/contractor/tasks/:projectId/updates/new` (GRA-41):
/// lists the contract's open tasks so the contractor can pick which one to
/// update.
class ContractorTaskUpdateStepOne extends StatelessWidget {
  const ContractorTaskUpdateStepOne({
    required this.tasks,
    required this.selectedTaskId,
    required this.onSelectTask,
    this.now,
    super.key,
  });

  final List<ContractorProjectTask> tasks;
  final String? selectedTaskId;
  final ValueChanged<String> onSelectTask;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return AppEmptyView(
        message: context.tr('tasks.contractor.update_no_open_tasks'),
        icon: Icons.task_alt_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Text(
          context.tr('tasks.contractor.update_step1_heading'),
          style: AppTextStyles.h1,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('tasks.contractor.update_step1_subtitle'),
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < tasks.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          ContractorTaskChoiceTile(
            key: Key('contractor_task_choice_${tasks[i].id}'),
            task: tasks[i],
            selected: tasks[i].id == selectedTaskId,
            onTap: () => onSelectTask(tasks[i].id),
            now: now,
          ),
        ],
      ],
    );
  }
}
