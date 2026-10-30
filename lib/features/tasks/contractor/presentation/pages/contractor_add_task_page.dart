import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_date_field.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_add_task_bloc.dart';

/// Screen where the contractor proposes a new task on a contract
/// (`/contractor/tasks/:projectId/new`, GRA-38).
class ContractorAddTaskPage extends StatefulWidget {
  const ContractorAddTaskPage({required this.projectId, super.key});

  final String projectId;

  @override
  State<ContractorAddTaskPage> createState() => _ContractorAddTaskPageState();
}

class _ContractorAddTaskPageState extends State<ContractorAddTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    context.read<ContractorAddTaskBloc>().add(
      ContractorAddTaskSubmitted(
        projectId: widget.projectId,
        title: _titleController.text,
        description: _descriptionController.text,
        rawAmount: _amountController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContractorAddTaskBloc, ContractorAddTaskState>(
      listenWhen: (previous, current) =>
          (current.isSubmitted && !previous.isSubmitted) ||
          (current.submissionFailure != null &&
              current.submissionFailure != previous.submissionFailure),
      listener: (context, state) {
        if (state.isSubmitted) {
          context.showSuccessSnackBar(context.tr('tasks.contractor.add_saved'));
          context.pop(true);
          return;
        }
        final failure = state.submissionFailure;
        if (failure != null) {
          context.showErrorSnackBar(
            context.tr(failure.messageKey),
            onRetry: failure is NetworkFailure ? () => _submit(context) : null,
          );
        }
      },
      builder: (context, state) {
        final project = state.project;
        return Scaffold(
          appBar: AppTopBar(
            title: project == null ? '' : project.displayTitle,
            onBack: () => context.pop(),
          ),
          body: AnimatedSwitcher(
            duration: AppMotion.enter,
            reverseDuration: AppMotion.exit,
            switchInCurve: AppMotion.enterCurve,
            switchOutCurve: AppMotion.exitCurve,
            child: _body(context, state),
          ),
          bottomNavigationBar: project == null
              ? null
              : AppActionBar(
                  primary: AppButton(
                    key: const Key('contractor_add_task_submit'),
                    label: context.tr('tasks.contractor.add_submit'),
                    isLoading: state.isSubmitting,
                    onPressed: state.isSubmitting
                        ? null
                        : () => _submit(context),
                  ),
                ),
        );
      },
    );
  }

  Widget _body(BuildContext context, ContractorAddTaskState state) {
    final bloc = context.read<ContractorAddTaskBloc>();
    if (state.project == null) {
      if (state.status == ContractorAddTaskStatus.failure) {
        return AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(state.loadFailure!.messageKey),
          onRetry: () => bloc.add(ContractorAddTaskStarted(widget.projectId)),
        );
      }
      return const AppLoadingIndicator(key: ValueKey('loading'));
    }

    final isLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final amountField = _buildAmountField(context, state);
    final startDateField = _buildStartDateField(context, state);

    return ListView(
      key: const ValueKey('form'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Text(context.tr('tasks.contractor.add_title'), style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('tasks.contractor.add_subtitle'),
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          key: const Key('contractor_add_task_title'),
          label: context.tr('tasks.contractor.add_field_title'),
          isRequired: true,
          controller: _titleController,
          hint: context.tr('tasks.contractor.add_hint_title'),
          errorText: state.titleErrorKey == null
              ? null
              : context.tr(state.titleErrorKey!),
          enabled: !state.isSubmitting,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const Key('contractor_add_task_description'),
          label: context.tr('tasks.contractor.add_field_description'),
          isRequired: true,
          controller: _descriptionController,
          hint: context.tr('tasks.contractor.add_hint_description'),
          minLines: 3,
          maxLines: 5,
          errorText: state.descriptionErrorKey == null
              ? null
              : context.tr(state.descriptionErrorKey!),
          enabled: !state.isSubmitting,
        ),
        const SizedBox(height: AppSpacing.md),
        if (isLargeText) ...[
          amountField,
          const SizedBox(height: AppSpacing.md),
          startDateField,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: amountField),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: startDateField),
            ],
          ),
      ],
    );
  }

  Widget _buildAmountField(BuildContext context, ContractorAddTaskState state) {
    final remaining = state.amountLeft;
    final helperText = remaining == null
        ? context.tr('tasks.contractor.add_amount_helper')
        : context.tr(
            'tasks.contractor.add_amount_helper_remaining',
            args: [AppMoneyText.format(context, remaining)],
          );

    final errorKey = state.amountErrorKey;
    final String? errorText;
    if (errorKey == null) {
      errorText = null;
    } else if (errorKey ==
            'tasks.contractor.add_error_amount_exceeds_remaining' &&
        remaining != null) {
      errorText = context.tr(
        errorKey,
        args: [AppMoneyText.format(context, remaining)],
      );
    } else {
      errorText = context.tr(errorKey);
    }

    return AppTextField(
      key: const Key('contractor_add_task_amount'),
      label: context.tr('tasks.contractor.add_field_amount'),
      controller: _amountController,
      hint: context.tr('tasks.contractor.add_hint_amount'),
      helperText: helperText,
      errorText: errorText,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      enabled: !state.isSubmitting,
    );
  }

  Widget _buildStartDateField(
    BuildContext context,
    ContractorAddTaskState state,
  ) {
    return AppDateField(
      key: const Key('contractor_add_task_start_date'),
      label: context.tr('tasks.contractor.add_field_start_date'),
      hint: context.tr('tasks.contractor.add_hint_start_date'),
      helperText: context.tr('tasks.contractor.add_start_date_helper'),
      value: state.startDate,
      enabled: !state.isSubmitting,
      onChanged: (date) => context.read<ContractorAddTaskBloc>().add(
        ContractorAddTaskStartDateChanged(date),
      ),
    );
  }
}
