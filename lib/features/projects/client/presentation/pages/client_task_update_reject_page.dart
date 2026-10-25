import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_reject_reason_form.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_task_update_reject_bloc.dart';

/// Rejecting a contractor's update (GRA-51): one of five reasons and the
/// details, both required before «إرسال الرفض للمقاول» turns on. The reason
/// is sent in the words the client reads it in. Once sent, this page and the
/// update's page close, and the timeline reads the tasks again.
class ClientTaskUpdateRejectPage extends StatelessWidget {
  const ClientTaskUpdateRejectPage({
    required this.projectId,
    required this.updateId,
    super.key,
  });

  final String projectId;
  final String updateId;

  /// The reasons, in their order on screen.
  static const List<String> _reasonKeys = [
    'projects.client.reject_reason_evidence',
    'projects.client.reject_reason_incomplete',
    'projects.client.reject_reason_quality',
    'projects.client.reject_reason_status',
    'projects.client.reject_reason_other',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<
      ClientTaskUpdateRejectBloc,
      ClientTaskUpdateRejectState
    >(
      listenWhen: (previous, current) =>
          (current.isSent && !previous.isSent) ||
          (current.errorKey != null && current.errorKey != previous.errorKey),
      listener: (context, state) {
        if (state.isSent) {
          context.showSuccessSnackBar(
            context.tr('projects.client.reject_sent'),
          );
          // The update's page, which opened this one, closes too.
          context.pop(true);
        } else if (state.errorKey case final key?) {
          context.showErrorSnackBar(context.tr(key));
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppTopBar(
          title: context.tr('projects.client.reject_title'),
          onBack: () => context.pop(),
        ),
        body: ListView(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          children: [
            Text(
              context.tr('projects.client.reject_subtitle'),
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppRejectReasonForm(
              reasons: [for (final key in _reasonKeys) context.tr(key)],
              detailsHint: context.tr('projects.client.reject_details_hint'),
              submitLabel: context.tr('projects.client.reject_send'),
              disableUntilFilled: true,
              isSubmitting: state.isSending,
              onSubmit: (index, details) =>
                  context.read<ClientTaskUpdateRejectBloc>().add(
                    ClientTaskUpdateRejectSubmitted(
                      updateId: updateId,
                      reason: context.tr(_reasonKeys[index]),
                      details: details,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
