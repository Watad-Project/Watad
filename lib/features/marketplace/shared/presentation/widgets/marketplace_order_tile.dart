import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_role.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_order_labels.dart';

/// One order in «طلباتي» or «مبيعاتي»: the other party, the order number,
/// units and date, the total and the status. A tap opens the order; when
/// [onPartyTap] is given, tapping the other party's name opens their
/// public profile.
class MarketplaceOrderTile extends StatelessWidget {
  const MarketplaceOrderTile({
    required this.order,
    required this.onTap,
    this.onPartyTap,
    super.key,
  });

  final MarketplaceOrder order;
  final VoidCallback onTap;

  /// Opens the other party's public profile (`ProfileRoutes.publicProfileName`).
  final VoidCallback? onPartyTap;

  @override
  Widget build(BuildContext context) {
    final isSeller = order.myRole == OrderRole.seller;
    final partyName = isSeller ? order.buyerName : order.sellerName;
    final partyAvatarUrl = isSeller
        ? order.buyerAvatarUrl
        : order.sellerAvatarUrl;
    final nameText = Text(
      partyName,
      style: AppTextStyles.label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    return AppCard(
      key: Key('order_${order.id}'),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(url: partyAvatarUrl, size: 40, semanticLabel: partyName),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onPartyTap case final onPartyTap?)
                  InkWell(
                    key: Key('order_party_${order.id}'),
                    onTap: onPartyTap,
                    child: nameText,
                  )
                else
                  nameText,
                const SizedBox(height: AppSpacing.xxs),
                // One line each, so a long number never splits «٥ قطع».
                Text(
                  MarketplaceOrderLabels.number(context, order),
                  style: AppTextStyles.caption,
                ),
                Text(
                  MarketplaceOrderLabels.units(context, order),
                  style: AppTextStyles.caption,
                ),
                Text(
                  MarketplaceOrderLabels.day(context, order.createdAt),
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppStatusBadge(
                  label: MarketplaceOrderLabels.status(context, order.status),
                  tone: MarketplaceOrderLabels.tone(order.status),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: AppMoneyText(order.total, style: AppTextStyles.label),
          ),
        ],
      ),
    );
  }
}
