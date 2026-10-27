import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';

/// One offer: the contractor (with the verified check), their rating, the
/// price and their note. While it can be accepted: «قبول العرض» and
/// «مراسلة»; otherwise its status.
class ClientOfferCard extends StatelessWidget {
  const ClientOfferCard({
    required this.offer,
    required this.canAccept,
    required this.isAccepting,
    required this.onAccept,
    this.onMessage,
    super.key,
  });

  final ClientProjectOffer offer;
  final bool canAccept;

  /// This offer is being accepted.
  final bool isAccepting;
  final VoidCallback? onAccept;

  /// Opens the chat with the contractor about this project.
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final rating = offer.providerRatingAvg;
    final message = offer.message;
    final nameStyle = AppTextStyles.label.copyWith(fontSize: 15);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: offer.isProviderVerified
                    ? AppVerifiedName(
                        name: offer.providerName,
                        style: nameStyle,
                      )
                    : Text(offer.providerName, style: nameStyle),
              ),
              if (rating != null) ...[
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.star_rounded, size: 18, color: AppColors.ink),
                Text(
                  context.formatNumber(rating, decimals: 1),
                  style: AppTextStyles.label,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppMoneyText(offer.amount),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(message, style: AppTextStyles.body),
          ],
          const SizedBox(height: AppSpacing.md),
          if (canAccept)
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: context.tr('projects.client.accept_offer'),
                    isLoading: isAccepting,
                    onPressed: onAccept,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: context.tr('projects.client.message_contractor'),
                    variant: AppButtonVariant.secondary,
                    onPressed: onMessage,
                  ),
                ),
              ],
            )
          else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _OfferStatusBadge(status: offer.status),
            ),
        ],
      ),
    );
  }
}

class _OfferStatusBadge extends StatelessWidget {
  const _OfferStatusBadge({required this.status});

  final OfferStatus status;

  @override
  Widget build(BuildContext context) {
    final (key, tone) = switch (status) {
      OfferStatus.pending => (
        'projects.client.offer_pending',
        AppTone.attention,
      ),
      OfferStatus.accepted => (
        'projects.client.offer_accepted_status',
        AppTone.success,
      ),
      OfferStatus.rejected => (
        'projects.client.offer_rejected',
        AppTone.neutral,
      ),
      OfferStatus.withdrawn => (
        'projects.client.offer_withdrawn',
        AppTone.neutral,
      ),
    };
    return AppStatusBadge(label: context.tr(key), tone: tone);
  }
}
