import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/inputs/app_upload_zone.dart';
import 'package:watad/core/components/layout/app_step_progress.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_post_project_bloc.dart';

/// Step 3 of the client post-project flow: Ownership deed upload and review states.
/// Only applicable for projects requiring an ownership deed (New House & Renovation).
class ClientPostProjectStep3 extends StatelessWidget {
  const ClientPostProjectStep3({
    super.key,
    required this.state,
    required this.onUploadDeed,
    required this.onRetryDeed,
  });

  final ClientPostProjectState state;
  final VoidCallback onUploadDeed;
  final VoidCallback onRetryDeed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppStepProgress(current: 3, total: state.totalSteps),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('projects.client.deed_title'),
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('projects.client.deed_subtitle'),
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (state.deedFileName != null || state.deedFilePath != null) ...[
            AppStatusCard(
              key: const Key('client_post_project_deed_pending_notice'),
              tone: AppTone.attention,
              title: context.tr(
                'projects.client.deed_selected_pending_title',
                args: [
                  state.deedFileName ??
                      state.deedFilePath?.split(RegExp(r'[\\/]')).last ??
                      '',
                ],
              ),
              subtitle: context.tr(
                'projects.client.deed_selected_pending_desc',
              ),
              action: AppButton(
                key: const Key('client_post_project_deed_retry_button'),
                label: context.tr('projects.client.deed_reupload'),
                onPressed: onRetryDeed,
              ),
            ),
          ] else ...[
            switch (state.deedStatus) {
              ClientDeedVerificationStatus.none => AppUploadZone(
                key: const Key('client_post_project_deed_upload_zone'),
                label: context.tr('projects.client.deed_upload_label'),
                onTap: onUploadDeed,
              ),
              ClientDeedVerificationStatus.underReview => AppStatusCard(
                key: const Key('client_post_project_deed_under_review'),
                tone: AppTone.attention,
                title: context.tr(
                  'projects.client.deed_status_under_review_title',
                ),
                subtitle: context.tr(
                  'projects.client.deed_status_under_review_desc',
                ),
              ),
              ClientDeedVerificationStatus.verified => AppStatusCard(
                key: const Key('client_post_project_deed_verified'),
                tone: AppTone.success,
                title: context.tr('projects.client.deed_status_verified_title'),
                subtitle: context.tr(
                  'projects.client.deed_status_verified_desc',
                ),
              ),
              ClientDeedVerificationStatus.rejected => AppStatusCard(
                key: const Key('client_post_project_deed_rejected'),
                tone: AppTone.danger,
                title:
                    state.deedRejectionReason ??
                    context.tr(
                      'projects.client.deed_status_rejected_default_title',
                    ),
                action: AppButton(
                  key: const Key('client_post_project_deed_retry_button'),
                  label: context.tr('projects.client.deed_reupload'),
                  onPressed: onRetryDeed,
                ),
              ),
            },
          ],
        ],
      ),
    );
  }
}
