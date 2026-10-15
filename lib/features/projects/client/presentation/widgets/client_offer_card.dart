import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';

class ClientOfferCard extends StatelessWidget {
  const ClientOfferCard({
    required this.offer,
    this.onAccept,
    this.onChat,
    this.isAccepting = false,
    super.key,
  });

  final ClientProjectOffer offer;
  final VoidCallback? onAccept;
  final VoidCallback? onChat;
  final bool isAccepting;

  @override
  Widget build(BuildContext context) {
    final amountString = (offer.amount.halalas / 100).toStringAsFixed(2);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: offer.isContractorVerified
                    ? AppVerifiedName(
                        name: offer.contractorName,
                        style: AppTextStyles.h2,
                      )
                    : Text(
                        offer.contractorName,
                        style: AppTextStyles.h2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              if (offer.status != OfferStatus.pending)
                AppStatusBadge(
                  label: switch (offer.status) {
                    OfferStatus.accepted =>
                      'projects.client.offer_status_accepted'.tr(),
                    OfferStatus.rejected =>
                      'projects.client.offer_status_rejected'.tr(),
                    OfferStatus.withdrawn =>
                      'projects.client.offer_status_withdrawn'.tr(),
                    OfferStatus.pending => '',
                  },
                  tone: switch (offer.status) {
                    OfferStatus.accepted => AppTone.success,
                    OfferStatus.rejected => AppTone.danger,
                    OfferStatus.withdrawn => AppTone.neutral,
                    OfferStatus.pending => AppTone.attention,
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              if (offer.contractorRating != null) ...[
                const Icon(Icons.star, size: 16, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  offer.contractorRating!.toStringAsFixed(1),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (offer.durationMonths != null) ...[
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  'projects.client.duration_months'.tr(
                    namedArgs: {'count': '${offer.durationMonths}'},
                  ),
                  style: AppTextStyles.caption,
                ),
              ],
            ],
          ),
          if (offer.message != null && offer.message!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.neutralLight,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
              ),
              child: Text(offer.message!, style: AppTextStyles.body),
            ),
          ],
          const Divider(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'projects.client.offer_price_label'.tr(),
                style: AppTextStyles.caption,
              ),
              Text(
                'projects.client.offer_amount'.tr(
                  namedArgs: {'amount': amountString},
                ),
                style: AppTextStyles.h2.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          if (offer.status == OfferStatus.pending) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'projects.client.accept_offer'.tr(),
                    variant: AppButtonVariant.primary,
                    isLoading: isAccepting,
                    onPressed: onAccept,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'projects.client.message_contractor'.tr(),
                    variant: AppButtonVariant.secondary,
                    icon: Icons.chat_bubble_outline,
                    onPressed: onChat,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
