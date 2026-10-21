import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/inputs/app_upload_zone.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_deed_bloc.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_project_title.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_projects_skeleton.dart';

/// A new ownership deed for a project whose deed was rejected (GRA-24, with
/// GRA-22's deed rules): why it was rejected, the new file, and «إرسال
/// الصك», which sends it back to review. The project stays a draft, hidden
/// from contractors, until an admin verifies it.
class ClientProjectDeedPage extends StatelessWidget {
  const ClientProjectDeedPage({
    required this.projectId,
    this.onPickDeed,
    super.key,
  });

  final String projectId;

  /// Picks the file; the phone's file picker by default (tests pass one).
  final Future<({String path, String name})?> Function()? onPickDeed;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientProjectDeedBloc, ClientProjectDeedState>(
      listenWhen: (previous, current) =>
          (current.isSent && !previous.isSent) ||
          (current.errorKey != null && current.errorKey != previous.errorKey),
      listener: (context, state) {
        if (state.isSent) {
          context.showSuccessSnackBar(context.tr('projects.client.deed_sent'));
          context.pop(true);
        } else if (state.errorKey case final key?) {
          context.showErrorSnackBar(context.tr(key));
        }
      },
      builder: (context, state) {
        final project = state.project;
        final canSend =
            project?.deedStatus == ClientDeedVerificationStatus.rejected &&
            state.filePath != null &&
            !state.isSending;
        return Scaffold(
          appBar: AppTopBar(
            title: context.tr('projects.client.deed_title'),
            onBack: () => context.pop(),
          ),
          body: AnimatedSwitcher(
            duration: AppMotion.enter,
            reverseDuration: AppMotion.exit,
            switchInCurve: AppMotion.enterCurve,
            switchOutCurve: AppMotion.exitCurve,
            child: KeyedSubtree(
              key: ValueKey(state.status),
              child: _body(context, state),
            ),
          ),
          bottomNavigationBar: project == null
              ? null
              : AppActionBar(
                  primary: AppButton(
                    key: const Key('client_project_deed_send'),
                    label: context.tr('projects.client.deed_send'),
                    isLoading: state.isSending,
                    onPressed: canSend
                        ? () => context.read<ClientProjectDeedBloc>().add(
                            const ClientProjectDeedSubmitted(),
                          )
                        : null,
                  ),
                ),
        );
      },
    );
  }

  Widget _body(BuildContext context, ClientProjectDeedState state) {
    final project = state.project;
    if (project == null) {
      if (state.status == ClientProjectDeedStatus.failure) {
        return AppErrorView(
          message: context.tr(state.failure!.messageKey),
          onRetry: () => context.read<ClientProjectDeedBloc>().add(
            ClientProjectDeedFetched(projectId),
          ),
        );
      }
      return const ClientProjectsSkeleton();
    }
    final rejected =
        project.deedStatus == ClientDeedVerificationStatus.rejected;
    final fileName = state.fileName;
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Text(
          ClientProjectTitle.of(context, project.title),
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: AppSpacing.md),
        if (rejected) ...[
          AppStatusCard(
            tone: AppTone.danger,
            title: context.tr('projects.client.status_deed_rejected'),
            reasonTitle: context.tr('projects.client.deed_reason_title'),
            reasonText:
                project.deedRejectionReason ??
                context.tr('projects.client.deed_rejected_no_reason'),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr('projects.client.deed_subtitle'),
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          AppUploadZone(
            key: const Key('client_project_deed_pick'),
            label: fileName == null
                ? context.tr('projects.client.pick_deed_files')
                : context.tr(
                    'projects.client.deed_selected_pending_title',
                    args: [fileName],
                  ),
            onTap: state.isSending ? null : () => _pick(context),
          ),
        ] else
          // Opened from an old link: the deed is under review or verified.
          AppStatusCard(
            tone: AppTone.neutral,
            title: context.tr('projects.client.deed_not_rejected'),
          ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final bloc = context.read<ClientProjectDeedBloc>();
    final picked = await (onPickDeed ?? _pickWithFilePicker)();
    if (picked != null) {
      bloc.add(
        ClientProjectDeedPicked(filePath: picked.path, fileName: picked.name),
      );
    }
  }

  /// A PDF or a photo, as the `project-deeds` bucket accepts.
  static Future<({String path, String name})?> _pickWithFilePicker() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final path = file?.path;
    if (file == null || path == null) return null;
    return (path: path, name: file.name);
  }
}
