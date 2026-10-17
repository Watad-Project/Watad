import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
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

  static String _toArabicDigits(String input) {
    final codeUnits = input.codeUnits.map((cp) {
      if (cp >= 0x30 && cp <= 0x39) {
        return cp - 0x30 + 0x0660;
      }
      return cp;
    }).toList();
    return String.fromCharCodes(codeUnits);
  }

  String _formatNumber(int value, {bool isArabic = false}) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(s[i]);
    }
    var res = buffer.toString();
    if (isArabic) {
      res = _toArabicDigits(res);
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final wholeAmount = offer.amount.halalas ~/ 100;
    final amountFormatted = _formatNumber(wholeAmount, isArabic: isArabic);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
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
              if (offer.contractorRating != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: AppColors.ink),
                    const SizedBox(width: 4),
                    Text(
                      isArabic
                          ? _toArabicDigits(
                              offer.contractorRating!.toStringAsFixed(1),
                            ).replaceAll('.', ',')
                          : offer.contractorRating!.toStringAsFixed(1),
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    amountFormatted,
                    style: AppTextStyles.h1.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    'projects.client.currency_sar'.tr(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (offer.durationMonths != null)
                Text(
                  'projects.client.duration_months'.tr(
                    namedArgs: {
                      'count': isArabic
                          ? _toArabicDigits('${offer.durationMonths}')
                          : '${offer.durationMonths}',
                    },
                  ),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (offer.message != null && offer.message!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              offer.message!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AppButton(
                  label: 'projects.client.accept_offer'.tr(),
                  variant: AppButtonVariant.primary,
                  isLoading: isAccepting,
                  onPressed: onAccept,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: 'projects.client.message_contractor'.tr(),
                  variant: AppButtonVariant.secondary,
                  onPressed: onChat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
