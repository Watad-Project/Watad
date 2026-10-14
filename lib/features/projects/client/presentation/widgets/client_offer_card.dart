import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_number_formatter.dart';

/// Card displaying one contractor's incoming offer on a project.
class ClientOfferCard extends StatelessWidget {
  const ClientOfferCard({
    super.key,
    required this.offer,
    this.onAccept,
    this.onMessage,
    this.isAccepted = false,
  });

  final ClientProjectOffer offer;
  final VoidCallback? onAccept;
  final VoidCallback? onMessage;
  final bool isAccepted;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final priceStr = ClientNumberFormatter.formatAmount(
      offer.amount,
      isArabic: isArabic,
    );
    final durationStr = ClientNumberFormatter.formatCount(
      offer.durationMonths,
      isArabic: isArabic,
    );
    final ratingStr = ClientNumberFormatter.formatRating(
      offer.contractorRating,
      isArabic: isArabic,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              const SizedBox(width: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16, color: AppColors.ink),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    ratingStr,
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                context.tr(
                  'projects.client.price_sar_format',
                  namedArgs: {'amount': priceStr},
                ),
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                context.tr(
                  'projects.client.duration_months',
                  namedArgs: {'count': durationStr},
                ),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (offer.message != null && offer.message!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              offer.message!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (isAccepted)
            Center(
              child: AppStatusBadge(
                label: context.tr('projects.client.offer_accepted'),
                tone: AppTone.success,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: AppButton(
                    label: context.tr('projects.client.accept_offer'),
                    onPressed: onAccept,
                    variant: AppButtonVariant.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 3,
                  child: AppButton(
                    label: context.tr('projects.client.message_contractor'),
                    onPressed: onMessage,
                    variant: AppButtonVariant.secondary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
