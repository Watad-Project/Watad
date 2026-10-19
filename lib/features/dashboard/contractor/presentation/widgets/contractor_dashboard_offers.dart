import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_offer.dart';

class ContractorDashboardOffers extends StatelessWidget {
  const ContractorDashboardOffers({
    super.key,
    required this.offers,
    this.onAllOffersTap,
    this.onOfferTap,
  });

  final List<ContractorDashboardOffer> offers;
  final VoidCallback? onAllOffersTap;
  final ValueChanged<String>? onOfferTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSectionHeader(
          title: context.tr('dashboard.contractor.my_offers_title'),
          actionLabel: context.tr('dashboard.contractor.see_all'),
          onAction: onAllOffersTap,
        ),
        if (offers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Text(
              context.tr('dashboard.contractor.no_offers'),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: offers.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final offer = offers[index];
              final currency = context.tr('dashboard.contractor.currency');
              final (statusKey, tone) = switch (offer.status) {
                OfferStatus.pending => (
                  'dashboard.contractor.offer_status_pending',
                  AppTone.attention,
                ),
                OfferStatus.rejected => (
                  'dashboard.contractor.offer_status_rejected',
                  AppTone.danger,
                ),
                OfferStatus.accepted => (
                  'dashboard.contractor.offer_status_accepted',
                  AppTone.success,
                ),
                OfferStatus.withdrawn => (
                  'dashboard.contractor.offer_status_withdrawn',
                  AppTone.neutral,
                ),
              };

              return AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                onTap: () => onOfferTap?.call(offer.id),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            offer.projectTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.h2,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            context.tr(
                              'dashboard.contractor.your_offer',
                              namedArgs: {
                                'amount': '${offer.amount.toJson()}',
                                'currency': currency,
                              },
                            ),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppStatusBadge(label: context.tr(statusKey), tone: tone),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
