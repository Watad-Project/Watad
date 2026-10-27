import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/presentation/widgets/contractor_task_labels.dart';
import 'package:watad/features/tasks/contractor/presentation/widgets/contractor_task_update_time_ago.dart';

/// A selectable radio card representing an open task on Step 1 of the
/// contractor's task update flow (GRA-41).
class ContractorTaskChoiceTile extends StatelessWidget {
  const ContractorTaskChoiceTile({
    required this.task,
    required this.selected,
    required this.onTap,
    this.now,
    super.key,
  });

  final ContractorProjectTask task;
  final bool selected;
  final VoidCallback onTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final fill = selected ? AppColors.primaryLight : AppColors.surface;
    final borderColor = selected ? AppColors.primary : AppColors.border;

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: fill,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(task.title, style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _amountAndStatusLine(context),
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ContractorTaskUpdateTimeAgo.formatLastUpdate(
                          context,
                          task.lastUpdateAt,
                          now: now,
                        ),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.primary : AppColors.surface,
                    border: selected
                        ? null
                        : Border.all(color: AppColors.controlBorder, width: 2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _amountAndStatusLine(BuildContext context) {
    final statusText = context.tr(ContractorTaskLabels.tagOf(task).key);
    final amount = task.amount;
    if (amount == null) {
      return statusText;
    }
    return context.tr(
      'tasks.contractor.update_task_amount_and_status',
      args: [AppMoneyText.format(context, amount), statusText],
    );
  }
}
