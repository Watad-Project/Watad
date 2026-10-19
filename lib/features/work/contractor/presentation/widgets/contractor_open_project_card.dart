import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';

class ContractorOpenProjectCard extends StatelessWidget {
  const ContractorOpenProjectCard({
    required this.project,
    this.onSubmitOfferTap,
    this.onPendingOfferTap,
    super.key,
  });

  final ContractorOpenProject project;
  final VoidCallback? onSubmitOfferTap;
  final VoidCallback? onPendingOfferTap;

  @override
  Widget build(BuildContext context) {
    final currency = context.tr('work.contractor.currency');
    final district = project.district?.trim();
    final locationText = district != null && district.isNotEmpty
        ? context.tr(
            'work.contractor.location_with_district',
            namedArgs: {'city': project.city, 'district': district},
          )
        : project.city;

    final budget = project.budget;
    final budgetText = budget != null
        ? context.tr(
            'work.contractor.budget_label',
            namedArgs: {'amount': '${budget.toJson()}', 'currency': currency},
          )
        : context.tr('work.contractor.budget_unspecified');

    final offerCountText = context.plural(
      'work.contractor.offer_count',
      project.offerCount,
      namedArgs: {'count': '${project.offerCount}'},
    );

    final cardTap = project.hasMyOffer
        ? (onPendingOfferTap ?? onSubmitOfferTap)
        : onSubmitOfferTap;

    return AppCard(
      onTap: cardTap,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            project.title,
            style: AppTextStyles.h2,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  locationText,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  budgetText,
                  style: AppTextStyles.label.copyWith(color: AppColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                offerCountText,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (project.hasMyOffer)
            _SubmittedOfferBanner(project: project, currency: currency)
          else
            AppButton(
              label: context.tr('work.contractor.submit_offer'),
              onPressed: onSubmitOfferTap,
            ),
        ],
      ),
    );
  }
}

class _SubmittedOfferBanner extends StatelessWidget {
  const _SubmittedOfferBanner({required this.project, required this.currency});

  final ContractorOpenProject project;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final offerAmount = project.myOfferAmount;
    final offerLabel = offerAmount != null
        ? context.tr(
            'work.contractor.your_offer',
            namedArgs: {
              'amount': '${offerAmount.toJson()}',
              'currency': currency,
            },
          )
        : context.tr('work.contractor.your_offer_no_amount');

    final status = project.myOfferStatus ?? OfferStatus.pending;
    final (statusKey, tone) = switch (status) {
      OfferStatus.pending => (
        'work.contractor.offer_status_pending',
        AppTone.attention,
      ),
      OfferStatus.accepted => (
        'work.contractor.offer_status_accepted',
        AppTone.success,
      ),
      OfferStatus.rejected => (
        'work.contractor.offer_status_rejected',
        AppTone.danger,
      ),
      OfferStatus.withdrawn => (
        'work.contractor.offer_status_withdrawn',
        AppTone.neutral,
      ),
    };

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              offerLabel,
              style: AppTextStyles.label.copyWith(color: AppColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppStatusBadge(label: context.tr(statusKey), tone: tone),
          if (project.isMyOfferPending) ...[
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}
