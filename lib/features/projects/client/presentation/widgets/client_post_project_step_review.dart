import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/display/app_photo_tile.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';
import 'package:watad/core/components/layout/app_step_progress.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_post_project_bloc.dart';

/// The final review and publish step of the post-project flow.
/// Displays summary data, photos, deed verification state, and allows publishing.
class ClientPostProjectStepReview extends StatelessWidget {
  const ClientPostProjectStepReview({super.key, required this.state});

  final ClientPostProjectState state;

  String _deedStatusText(BuildContext context) {
    if (!state.requiresDeed) {
      return context.tr('projects.client.review_deed_not_required');
    }
    return switch (state.deedStatus) {
      ClientDeedVerificationStatus.verified => context.tr(
        'projects.client.review_deed_verified',
      ),
      ClientDeedVerificationStatus.underReview => context.tr(
        'projects.client.review_deed_under_review',
      ),
      ClientDeedVerificationStatus.none => context.tr(
        'projects.client.review_deed_none',
      ),
      ClientDeedVerificationStatus.rejected =>
        state.deedRejectionReason ??
            context.tr('projects.client.deed_status_rejected_default_title'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final typeName = state.projectType != null
        ? context.tr(state.projectType!.titleKey)
        : '';
    final hasBudget =
        (state.minBudget != null && state.minBudget!.halalas > 0) ||
        (state.maxBudget != null && state.maxBudget!.halalas > 0);
    final budgetText = hasBudget
        ? context.tr(
            'projects.client.review_budget_range',
            args: [
              '${state.minBudget?.sar.toInt() ?? 0}',
              '${state.maxBudget?.sar.toInt() ?? 0}',
            ],
          )
        : context.tr('projects.client.budget_unspecified');

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppStepProgress(current: state.currentStep, total: state.totalSteps),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('projects.client.review_title'),
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('projects.client.review_subtitle'),
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppKeyValueList(
            rows: [
              AppKeyValueRow(
                label: context.tr('projects.client.review_project_type'),
                value: typeName,
              ),
              AppKeyValueRow(
                label: context.tr('projects.client.review_scope'),
                value: state.scopeOfWork,
              ),
              AppKeyValueRow(
                label: context.tr('projects.client.review_budget'),
                value: budgetText,
              ),
              AppKeyValueRow(
                label: context.tr('projects.client.review_location'),
                value: state.locationAddress ?? '',
              ),
              AppKeyValueRow(
                label: context.tr('projects.client.review_deed_status'),
                value: _deedStatusText(context),
              ),
            ],
          ),
          if (state.photos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            AppFieldLabel(label: context.tr('projects.client.photos_label')),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.photos.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return AppPhotoTile(placeholderLabel: '${index + 1}');
                },
              ),
            ),
          ],
          if (state.requiresDeed &&
              state.deedStatus == ClientDeedVerificationStatus.underReview) ...[
            const SizedBox(height: AppSpacing.lg),
            AppStatusCard(
              tone: AppTone.attention,
              title: context.tr(
                'projects.client.deed_status_under_review_title',
              ),
              subtitle: context.tr(
                'projects.client.deed_status_under_review_desc',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
