import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_order_labels.dart';

/// One order in «طلباتي»: the seller, the order number, units and date,
/// the total and the status. A tap opens the order.
class MarketplaceOrderTile extends StatelessWidget {
  const MarketplaceOrderTile({
    required this.order,
    required this.onTap,
    super.key,
  });

  final MarketplaceOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: Key('order_${order.id}'),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            url: order.sellerAvatarUrl,
            size: 40,
            semanticLabel: order.sellerName,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.sellerName,
                  style: AppTextStyles.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
