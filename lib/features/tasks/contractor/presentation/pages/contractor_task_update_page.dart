import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/contractor_tasks_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_submit_task_update_params.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_evidence_photo.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_step_cubit.dart';
import 'package:watad/features/tasks/contractor/presentation/widgets/contractor_task_update_step_one.dart';
import 'package:watad/features/tasks/contractor/presentation/widgets/contractor_task_update_step_two.dart';

/// Two-step flow for `/contractor/tasks/:projectId/updates/new`:
/// - Step 1 (GRA-41): choose an open task to update.
/// - Step 2 (GRA-42): select the new state («قيد التنفيذ» or «منجزة»),
///   attach up to 3 evidence photos, write a note, and submit.
class ContractorTaskUpdatePage extends StatelessWidget {
  const ContractorTaskUpdatePage({
    required this.projectId,
    this.onPickPhoto,
    this.now,
    super.key,
  });

  final String projectId;

  /// Optional photo-picker hook for deterministic widget tests.
  final Future<ContractorTaskEvidencePhoto?> Function(ImageSource source)?
  onPickPhoto;

  /// Optional reference timestamp for deterministic relative-time rendering.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ContractorTaskUpdateBloc, ContractorTaskUpdateState>(
          listenWhen: (previous, current) => previous.tasks != current.tasks,
          listener: (context, state) {
            context.read<ContractorTaskUpdateStepCubit>().syncTasks(
              state.tasks,
            );
          },
        ),
        BlocListener<ContractorTaskUpdateBloc, ContractorTaskUpdateState>(
          listenWhen: (previous, current) =>
              current.submittedUpdateId != null &&
              previous.submittedUpdateId != current.submittedUpdateId,
          listener: (context, state) {
            context.showSuccessSnackBar(
              context.tr('tasks.contractor.update_submitted_success'),
            );
            _openSubmittedUpdate(context, state.submittedUpdateId!);
          },
        ),
        BlocListener<ContractorTaskUpdateBloc, ContractorTaskUpdateState>(
          listenWhen: (previous, current) =>
              current.submissionFailure != null &&
              previous.submissionFailure != current.submissionFailure,
          listener: (context, state) {
            context.showErrorSnackBar(
              context.tr(state.submissionFailure!.messageKey),
            );
          },
        ),
      ],
      child: BlocBuilder<ContractorTaskUpdateBloc, ContractorTaskUpdateState>(
        builder: (context, state) {
          return BlocBuilder<
            ContractorTaskUpdateStepCubit,
            ContractorTaskUpdateStepState
          >(
            builder: (context, stepState) {
              final cubit = context.read<ContractorTaskUpdateStepCubit>();
              final selectedTask = stepState.selectedTaskFrom(state.tasks);
              final isStepTwo =
                  stepState.step == ContractorTaskUpdateStep.stateAndEvidence &&
                  selectedTask != null;

              return PopScope(
                canPop: !isStepTwo,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop && isStepTwo) {
                    cubit.backToStepOne();
                  }
                },
                child: Scaffold(
                  appBar: AppTopBar(
                    title: context.tr('tasks.contractor.update_title'),
                    onBack: () {
                      if (isStepTwo) {
                        cubit.backToStepOne();
                      } else {
                        _popIfPossible(context);
                      }
                    },
                  ),
                  body: AnimatedSwitcher(
                    duration: AppMotion.enter,
                    reverseDuration: AppMotion.exit,
                    switchInCurve: AppMotion.enterCurve,
                    switchOutCurve: AppMotion.exitCurve,
                    child: _body(context, state, stepState, selectedTask),
                  ),
                  bottomNavigationBar: _bottomBar(
                    context,
                    state,
                    stepState,
                    selectedTask,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _popIfPossible(BuildContext context, [bool? result]) {
    if (GoRouter.maybeOf(context)?.canPop() ?? false) {
      context.pop(result);
    }
  }

  void _openSubmittedUpdate(BuildContext context, String updateId) {
    if (GoRouter.maybeOf(context) != null) {
      context.pushReplacementNamed(
        ContractorTasksRoutes.taskUpdateStatusName,
        pathParameters: {'projectId': projectId, 'updateId': updateId},
      );
    }
  }

  Widget _body(
    BuildContext context,
    ContractorTaskUpdateState state,
    ContractorTaskUpdateStepState stepState,
    ContractorProjectTask? selectedTask,
  ) {
    final bloc = context.read<ContractorTaskUpdateBloc>();
    final cubit = context.read<ContractorTaskUpdateStepCubit>();

    if (state.status == ContractorTaskUpdateStatus.initial ||
        state.status == ContractorTaskUpdateStatus.loading) {
      return const AppLoadingIndicator(key: ValueKey('loading'));
    }

    if (state.status == ContractorTaskUpdateStatus.failure) {
      return AppErrorView(
        key: const ValueKey('error'),
        message: context.tr(state.failure!.messageKey),
        onRetry: () => bloc.add(ContractorTaskUpdateFetched(projectId)),
      );
    }

    if (stepState.step == ContractorTaskUpdateStep.stateAndEvidence &&
        selectedTask != null) {
      return ContractorTaskUpdateStepTwo(
        key: const ValueKey('step2'),
        task: selectedTask,
        stepState: stepState,
        onBackToStepOne: cubit.backToStepOne,
        onProposedStateChanged: cubit.setProposedState,
        onCameraTap: () => _handlePickPhoto(context, ImageSource.camera),
        onGalleryTap: () => _handlePickPhoto(context, ImageSource.gallery),
        onRemovePhoto: cubit.removePhotoAt,
        onNoteChanged: cubit.setNote,
      );
    }

    return ContractorTaskUpdateStepOne(
      key: const ValueKey('step1'),
      tasks: state.tasks,
      selectedTaskId: stepState.selectedTaskId,
      onSelectTask: cubit.selectTask,
      now: now,
    );
  }

  Widget? _bottomBar(
    BuildContext context,
    ContractorTaskUpdateState state,
    ContractorTaskUpdateStepState stepState,
    ContractorProjectTask? selectedTask,
  ) {
    if (state.status != ContractorTaskUpdateStatus.success ||
        state.tasks.isEmpty) {
      return null;
    }

    final cubit = context.read<ContractorTaskUpdateStepCubit>();
    final isStepTwo =
        stepState.step == ContractorTaskUpdateStep.stateAndEvidence &&
        selectedTask != null;

    if (isStepTwo) {
      return AppActionBar(
        primary: AppButton(
          key: const Key('contractor_task_update_submit'),
          label: context.tr('tasks.contractor.update_submit_button'),
          isLoading: state.isSubmitting,
          onPressed: state.isSubmitting
              ? null
              : () => _submit(context, selectedTask, stepState),
        ),
      );
    }

    return AppActionBar(
      primary: AppButton(
        key: const Key('contractor_task_update_next'),
        label: context.tr('tasks.contractor.update_next_button'),
        onPressed: selectedTask != null ? cubit.proceedToStepTwo : null,
      ),
    );
  }

  Future<void> _handlePickPhoto(
    BuildContext context,
    ImageSource source,
  ) async {
    final cubit = context.read<ContractorTaskUpdateStepCubit>();
    if (!cubit.state.canAddPhoto) return;

    try {
      final ContractorTaskEvidencePhoto? picked;
      if (onPickPhoto != null) {
        picked = await onPickPhoto!(source);
      } else {
        final file = await ImagePicker().pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        if (file == null) return;
        final bytes = await file.readAsBytes();
        picked = ContractorTaskEvidencePhoto(bytes: bytes, fileName: file.name);
      }
      if (picked != null && context.mounted) {
        cubit.addPhoto(picked);
      }
    } catch (_) {
      if (context.mounted) {
        context.showErrorSnackBar(context.tr('errors.unknown'));
      }
    }
  }

  void _submit(
    BuildContext context,
    ContractorProjectTask task,
    ContractorTaskUpdateStepState stepState,
  ) {
    context.read<ContractorTaskUpdateBloc>().add(
      ContractorTaskUpdateSubmitted(
        ContractorSubmitTaskUpdateParams(
          taskId: task.id,
          proposedState: stepState.proposedState,
          photos: stepState.photos,
          note: stepState.note,
          taskStartDate: task.startDate,
        ),
      ),
    );
  }
}
