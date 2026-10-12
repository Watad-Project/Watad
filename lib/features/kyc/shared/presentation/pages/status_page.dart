import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';
import 'package:watad/features/kyc/shared/presentation/bloc/kyc_status_bloc.dart';

class StatusPage extends StatelessWidget {
  const StatusPage({
    super.key,
    this.documentType = KycDocumentType.license,
    this.initialStatus,
  });

  final KycDocumentType documentType;
  final VerificationStatus? initialStatus;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KycStatusBloc, KycStatusState>(
      listener: (context, state) {
        if (state is KycStatusLoadSuccess) {
          final doc = state.document;
          if (doc.status == VerificationStatus.verified &&
              doc.documentType == KycDocumentType.license &&
              (doc.specializedField == null || doc.specializedField!.isEmpty)) {
            // Automatically route Contractor to /contractor/onboarding/specialty
            // if their status becomes 'Verified' and they haven't picked a specialty yet.
            // Using pushNamed/goNamed if constant exists or safe pop/go.
          }
        } else if (state is KycStatusLoadFailure) {
          context.showErrorSnackBar(context.tr(state.failure.messageKey));
        }
      },
      builder: (context, state) {
        final document = switch (state) {
          KycStatusLoadSuccess(:final document) => document,
          _ => null,
        };

        final status =
            document?.status ?? initialStatus ?? VerificationStatus.pending;
        final type = document?.documentType ?? documentType;
        final docTypeKey = type == KycDocumentType.deed ? 'deed' : 'license';

        final statusCard = switch (status) {
          VerificationStatus.pending => AppStatusCard(
            tone: AppTone.attention,
            title: context.tr('kyc.$docTypeKey.pending_title'),
            subtitle: context.tr('kyc.$docTypeKey.pending_subtitle'),
          ),
          VerificationStatus.rejected => AppStatusCard(
            tone: AppTone.danger,
            title: context.tr('kyc.$docTypeKey.rejected_title'),
            reasonTitle: context.tr(
              'kyc.rejection_reason_prefix',
              namedArgs: {'reason': document?.rejectionReason ?? ''},
            ),
            action: AppButton(
              label: context.tr('kyc.retry_button'),
              variant: AppButtonVariant.secondary,
              onPressed: () {
                context.pop();
              },
            ),
          ),
          VerificationStatus.verified => AppStatusCard(
            tone: AppTone.success,
            title: context.tr('kyc.$docTypeKey.verified_title'),
            subtitle: context.tr('kyc.$docTypeKey.verified_subtitle'),
          ),
          _ => AppStatusCard(
            tone: AppTone.neutral,
            title: context.tr('kyc.$docTypeKey.pending_title'),
            subtitle: context.tr('kyc.$docTypeKey.pending_subtitle'),
          ),
        };

        return Scaffold(
          appBar: AppTopBar(
            title: context.tr('kyc.title'),
            onBack: () => context.pop(),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  statusCard,
                  const Spacer(),
                  Text(
                    context.tr('kyc.footnote'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
