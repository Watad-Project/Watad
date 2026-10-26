import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_task_update_bloc.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_task_update_details.dart';

/// An update the contractor sent on a task (GRA-49). While it waits for the
/// client, «قبول» approves the task and «رفض» opens the rejection screen;
/// otherwise the page only reads.
class ClientTaskUpdatePage extends StatelessWidget {
  const ClientTaskUpdatePage({
    required this.projectId,
    required this.updateId,
    super.key,
  });

  final String projectId;
  final String updateId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientTaskUpdateBloc, ClientTaskUpdateState>(
      listenWhen: (previous, current) =>
          current.message != null && previous.message != current.message,
      listener: (context, state) {
        final message = state.message!;
        if (message.isError) {
          context.showErrorSnackBar(context.tr(message.key));
        } else {
          context.showSuccessSnackBar(context.tr(message.key));
        }
      },
      builder: (context, state) {
        final bloc = context.read<ClientTaskUpdateBloc>();
        final update = state.update;
        return Scaffold(
          appBar: AppTopBar(
            title: context.tr('projects.client.update_title'),
            onBack: () => context.pop(),
          ),
          body: AnimatedSwitcher(
            duration: AppMotion.enter,
            reverseDuration: AppMotion.exit,
            switchInCurve: AppMotion.enterCurve,
            switchOutCurve: AppMotion.exitCurve,
            child: update != null
                // The same key across reloads keeps the status stepper, so
                // it fills on to «معتمدة» after «قبول».
                ? ClientTaskUpdateDetails(
                    key: const ValueKey('update'),
                    update: update,
                  )
                : state.status == ClientTaskUpdateStatus.failure
                ? AppErrorView(
                    key: const ValueKey('error'),
                    message: context.tr(state.failure!.messageKey),
                    onRetry: () => bloc.add(ClientTaskUpdateFetched(updateId)),
                  )
                : const AppLoadingIndicator(key: ValueKey('loading')),
          ),
          bottomNavigationBar: update != null && update.canDecide
              ? AppActionBar(
                  primary: AppButton(
                    key: const Key('client_task_update_accept'),
                    label: context.tr('projects.client.update_accept'),
                    isLoading: state.isAccepting,
                    onPressed: () => bloc.add(const ClientTaskUpdateAccepted()),
                  ),
                  secondary: AppButton(
                    key: const Key('client_task_update_reject'),
                    label: context.tr('projects.client.update_reject'),
                    variant: AppButtonVariant.secondary,
                    onPressed: state.isAccepting
                        ? null
                        : () => _reject(context),
                  ),
                )
              : null,
        );
      },
    );
  }

  /// «رفض»: the rejection screen. Once it sent the rejection, this page
  /// closes too, back to the timeline, which reads the tasks again.
  Future<void> _reject(BuildContext context) async {
    final rejected = await context.pushNamed<bool>(
      ClientProjectsRoutes.taskUpdateRejectName,
      pathParameters: {'projectId': projectId, 'updateId': updateId},
    );
    if (rejected == true && context.mounted) context.pop(true);
  }
}
