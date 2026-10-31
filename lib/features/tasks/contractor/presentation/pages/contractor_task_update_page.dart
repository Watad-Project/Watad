import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_step_cubit.dart';
import 'package:watad/features/tasks/contractor/presentation/widgets/contractor_task_update_step_one.dart';

/// Step 1 of `/contractor/tasks/:projectId/updates/new` (GRA-41):
/// lets the contractor choose an open task to update.
class ContractorTaskUpdatePage extends StatelessWidget {
  const ContractorTaskUpdatePage({
    required this.projectId,
    this.now,
    super.key,
  });

  final String projectId;

  /// Optional reference timestamp for deterministic relative-time rendering.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ContractorTaskUpdateBloc, ContractorTaskUpdateState>(
      listenWhen: (previous, current) => previous.tasks != current.tasks,
      listener: (context, state) {
        context.read<ContractorTaskUpdateStepCubit>().syncTasks(state.tasks);
      },
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
                      } else if (GoRouter.maybeOf(context)?.canPop() ?? false) {
                        context.pop();
                      }
                    },
                  ),
                  body: AnimatedSwitcher(
                    duration: AppMotion.enter,
                    reverseDuration: AppMotion.exit,
                    switchInCurve: AppMotion.enterCurve,
                    switchOutCurve: AppMotion.exitCurve,
                    child: _body(context, state, stepState),
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

  Widget _body(
    BuildContext context,
    ContractorTaskUpdateState state,
    ContractorTaskUpdateStepState stepState,
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
    return AppActionBar(
      primary: AppButton(
        key: const Key('contractor_task_update_next'),
        label: context.tr('tasks.contractor.update_next_button'),
        onPressed: selectedTask != null ? cubit.proceedToStepTwo : null,
      ),
    );
  }
}
