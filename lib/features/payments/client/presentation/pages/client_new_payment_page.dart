import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_summary_rows.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/client_payments_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/presentation/bloc/client_new_payment_bloc.dart';
import 'package:watad/features/payments/client/presentation/widgets/client_payment_task_row.dart';

/// «الدفع للمقاول», step one (GRA-50): the project's tasks. The finished,
/// approved and unpaid ones can be ticked; the others are greyed, with why.
/// The total follows the selection, and «متابعة» opens the bank transfer
/// for the selected tasks.
class ClientNewPaymentPage extends StatelessWidget {
  const ClientNewPaymentPage({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientNewPaymentBloc, ClientNewPaymentState>(
      // A refresh that fails while the tasks are on screen keeps them, and
      // says so.
      listenWhen: (previous, current) =>
          current.status == ClientNewPaymentStatus.failure &&
          previous.status != ClientNewPaymentStatus.failure &&
          current.tasks.isNotEmpty,
      listener: (context, state) => context.showErrorSnackBar(
        context.tr(state.failure!.messageKey),
        onRetry: () => context.read<ClientNewPaymentBloc>().add(
          ClientNewPaymentFetched(projectId),
        ),
      ),
      builder: (context, state) {
        final loaded =
            state.status == ClientNewPaymentStatus.success ||
            state.tasks.isNotEmpty;
        return Scaffold(
          appBar: AppTopBar(
            title: context.tr('payments.client.new_title'),
            onBack: () => context.pop(),
          ),
          body: AnimatedSwitcher(
            duration: AppMotion.enter,
            reverseDuration: AppMotion.exit,
            switchInCurve: AppMotion.enterCurve,
            switchOutCurve: AppMotion.exitCurve,
            child: loaded ? _tasks(context, state) : _waiting(context, state),
          ),
          bottomNavigationBar: loaded
              ? AppActionBar(
                  primary: AppButton(
                    key: const Key('client_new_payment_continue'),
                    label: context.tr('payments.client.continue'),
                    onPressed: state.canContinue
                        ? () => _continue(context, state)
                        : null,
                  ),
                )
              : null,
        );
      },
    );
  }

  /// «متابعة»: the bank transfer for the selected tasks, passed as their ids.
  /// Once the receipt went, this page closes too, back to the timeline,
  /// which reloads; back without sending, the tasks are read again.
  Future<void> _continue(
    BuildContext context,
    ClientNewPaymentState state,
  ) async {
    final bloc = context.read<ClientNewPaymentBloc>();
    final sent = await context.pushNamed<bool>(
      ClientPaymentsRoutes.bankTransferName,
      pathParameters: {'projectId': projectId},
      queryParameters: {
        'taskIds': [for (final task in state.selectedTasks) task.id].join(','),
      },
    );
    if (!context.mounted) return;
    if (sent == true) {
      context.pop(true);
    } else {
      bloc.add(ClientNewPaymentFetched(projectId));
    }
  }

  /// Loading, or why it couldn't load.
  Widget _waiting(BuildContext context, ClientNewPaymentState state) {
    if (state.status == ClientNewPaymentStatus.failure) {
      return AppErrorView(
        key: const ValueKey('error'),
        message: context.tr(state.failure!.messageKey),
        onRetry: () => context.read<ClientNewPaymentBloc>().add(
          ClientNewPaymentFetched(projectId),
        ),
      );
    }
    return const AppLoadingIndicator(key: ValueKey('loading'));
  }

  Widget _tasks(BuildContext context, ClientNewPaymentState state) {
    final bloc = context.read<ClientNewPaymentBloc>();
    final tasks = state.tasks;
    return RefreshIndicator(
      key: const ValueKey('tasks'),
      onRefresh: () async => bloc.add(ClientNewPaymentFetched(projectId)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          Text(
            context.tr('payments.client.new_subtitle'),
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          if (!state.hasPayable)
            AppEmptyView(
              message: context.tr('payments.client.empty'),
              icon: Icons.payments_outlined,
            ),
          if (tasks.isNotEmpty)
            AppCard(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < tasks.length; i++) ...[
                    if (i > 0) const Divider(),
                    ClientPaymentTaskRow(
                      key: ValueKey('client_payment_task_${tasks[i].id}'),
                      task: tasks[i],
                      selected: state.selectedIds.contains(tasks[i].id),
                      onChanged: (_) =>
                          bloc.add(ClientNewPaymentTaskToggled(tasks[i].id)),
                    ),
                  ],
                ],
              ),
            ),
          if (state.hasPayable) ...[
            const SizedBox(height: AppSpacing.lg),
            AppSummaryRows(
              rows: [
                for (final task in state.selectedTasks)
                  AppSummaryRow(
                    label: task.title,
                    value: AppMoneyText.format(
                      context,
                      task.amount ?? const Money.zero(),
                    ),
                  ),
              ],
              total: AppSummaryRow(
                label: context.tr('payments.client.total'),
                value: AppMoneyText.format(context, state.total),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
