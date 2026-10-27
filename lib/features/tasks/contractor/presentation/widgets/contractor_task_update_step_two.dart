import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_photo_tile.dart';
import 'package:watad/core/components/inputs/app_camera_tile.dart';
import 'package:watad/core/components/inputs/app_radio_row.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_submit_task_update_params.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_step_cubit.dart';
import 'package:watad/features/tasks/contractor/presentation/widgets/contractor_task_labels.dart';

/// Step 2 of `/contractor/tasks/:projectId/updates/new` (GRA-42):
/// shows the chosen task summary, the new state radio choices («قيد التنفيذ»
/// vs «منجزة»), the camera + 3 evidence photo tiles, and the note field.
class ContractorTaskUpdateStepTwo extends StatefulWidget {
  const ContractorTaskUpdateStepTwo({
    required this.task,
    required this.stepState,
    required this.onBackToStepOne,
    required this.onProposedStateChanged,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onRemovePhoto,
    required this.onNoteChanged,
    super.key,
  });

  final ContractorProjectTask task;
  final ContractorTaskUpdateStepState stepState;
  final VoidCallback onBackToStepOne;
  final ValueChanged<TaskUpdateState> onProposedStateChanged;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final ValueChanged<int> onRemovePhoto;
  final ValueChanged<String> onNoteChanged;

  @override
  State<ContractorTaskUpdateStepTwo> createState() =>
      _ContractorTaskUpdateStepTwoState();
}

class _ContractorTaskUpdateStepTwoState
    extends State<ContractorTaskUpdateStepTwo> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.stepState.note);
  }

  @override
  void didUpdateWidget(covariant ContractorTaskUpdateStepTwo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stepState.note != _noteController.text) {
      _noteController.text = widget.stepState.note;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final stepState = widget.stepState;

    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            button: true,
            child: InkWell(
              key: const Key('contractor_task_update_back_to_step1'),
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.md),
              ),
              onTap: widget.onBackToStepOne,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: AppSpacing.xxs,
                  horizontal: AppSpacing.xxs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      context.tr('tasks.contractor.update_back_to_step1'),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          key: const Key('contractor_task_update_selected_card'),
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                _currentStateSubtitle(context, task),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.tr('tasks.contractor.update_new_state_section'),
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppRadioRow(
          key: const Key('contractor_task_update_state_in_progress'),
          title: context.tr('tasks.contractor.state_in_progress'),
          selected: stepState.proposedState == TaskUpdateState.inProgress,
          onTap: () =>
              widget.onProposedStateChanged(TaskUpdateState.inProgress),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppRadioRow(
          key: const Key('contractor_task_update_state_done'),
          title: context.tr('tasks.contractor.state_done'),
          selected: stepState.proposedState == TaskUpdateState.done,
          onTap: () => widget.onProposedStateChanged(TaskUpdateState.done),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          task.amount != null
              ? context.tr('tasks.contractor.update_done_hint_priced')
              : context.tr('tasks.contractor.update_done_hint_unpriced'),
          key: const Key('contractor_task_update_done_hint'),
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.tr('tasks.contractor.update_evidence_section'),
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AppCameraTile(
                key: const Key('contractor_task_update_camera_tile'),
                onTap: stepState.canAddPhoto ? widget.onCameraTap : null,
              ),
              for (
                var i = 0;
                i < ContractorSubmitTaskUpdateParams.maxPhotos;
                i++
              ) ...[
                const SizedBox(width: AppSpacing.sm),
                _EvidencePhotoSlot(
                  index: i,
                  stepState: stepState,
                  onAddTap: stepState.canAddPhoto ? widget.onGalleryTap : null,
                  onRemoveTap: () => widget.onRemovePhoto(i),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          stepState.proposedState == TaskUpdateState.done
              ? context.tr('tasks.contractor.update_evidence_hint_done')
              : context.tr('tasks.contractor.update_evidence_hint_in_progress'),
          key: const Key('contractor_task_update_evidence_hint'),
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.tr('tasks.contractor.update_note_section'),
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: const Key('contractor_task_update_note_field'),
          controller: _noteController,
          maxLines: 4,
          hint: context.tr('tasks.contractor.update_note_hint'),
          onChanged: widget.onNoteChanged,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  String _currentStateSubtitle(
    BuildContext context,
    ContractorProjectTask task,
  ) {
    final statusText = context.tr(ContractorTaskLabels.tagOf(task).key);
    final amount = task.amount;
    if (amount == null) {
      return context.tr(
        'tasks.contractor.update_current_state_only',
        args: [statusText],
      );
    }
    return context.tr(
      'tasks.contractor.update_current_state_with_amount',
      args: [AppMoneyText.format(context, amount), statusText],
    );
  }
}

class _EvidencePhotoSlot extends StatelessWidget {
  const _EvidencePhotoSlot({
    required this.index,
    required this.stepState,
    required this.onAddTap,
    required this.onRemoveTap,
  });

  final int index;
  final ContractorTaskUpdateStepState stepState;
  final VoidCallback? onAddTap;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = index < stepState.photos.length;
    final photo = hasPhoto ? stepState.photos[index] : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppPhotoTile(
          key: Key('contractor_task_update_photo_slot_$index'),
          placeholderLabel: context.formatNumber(index + 1),
          image: photo == null ? null : MemoryImage(photo.bytes),
          onTap: hasPhoto ? onRemoveTap : onAddTap,
        ),
        if (hasPhoto)
          PositionedDirectional(
            top: 4,
            end: 4,
            child: IgnorePointer(
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 13,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
