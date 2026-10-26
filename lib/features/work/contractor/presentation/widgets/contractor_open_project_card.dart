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

  (String, AppTone) _offerStatusMeta(OfferStatus status) => switch (status) {
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

    final imageUrl = project.imageUrl?.trim();

    final statusMeta = project.hasMyOffer
        ? _offerStatusMeta(project.myOfferStatus ?? OfferStatus.pending)
        : null;

    return AppCard(
      onTap: cardTap,
      padding: EdgeInsets.zero,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 96,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.lg),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: AppColors.primarySoft,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.home_work_rounded,
                                  size: 36,
                                  color: AppColors.primary,
                                ),
                              ),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppRadius.lg),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.home_work_rounded,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                    if (statusMeta case (final statusKey, final tone))
                      PositionedDirectional(
                        top: AppSpacing.xs,
                        start: AppSpacing.xs,
                        child: AppStatusBadge(
                          label: context.tr(statusKey),
                          tone: tone,
                          onImage: true,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      project.title,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
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
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      budgetText,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offerCountText,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.sm,
              0,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: project.hasMyOffer
                ? _SubmittedOfferBanner(project: project, currency: currency)
                : AppButton(
                    label: context.tr('work.contractor.submit_offer'),
                    onPressed: onSubmitOfferTap,
                  ),
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

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
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
              style: AppTextStyles.caption.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (project.isMyOfferPending) ...[
            const SizedBox(width: AppSpacing.xxs),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}
