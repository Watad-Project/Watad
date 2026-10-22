import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item.dart';
import 'package:watad/features/marketplace/admin/presentation/widgets/admin_marketplace_labels.dart';

/// One listing: its name and status, the seller (with the verified check
/// for a verified business), the price per unit and the stock. Listings
/// have no photos. A tap opens its page.
class AdminMarketplaceItemTile extends StatelessWidget {
  const AdminMarketplaceItemTile({
    required this.item,
    required this.onTap,
    super.key,
  });

  final AdminMarketplaceItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(item.name, style: AppTextStyles.label)),
              const SizedBox(width: AppSpacing.xs),
              AppStatusBadge(
                label: context.tr(
                  AdminMarketplaceLabels.statusKey(item.status),
                ),
                tone: AdminMarketplaceLabels.statusTone(item.status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          if (item.sellerIsVerified)
            AppVerifiedName(name: item.sellerName, style: AppTextStyles.caption)
          else
            Text(item.sellerName, style: AppTextStyles.caption),
          Text(
            context.tr(
              'marketplace.price_and_stock',
              args: [
                context.tr(
                  'marketplace.per_unit',
                  args: [AppMoneyText.format(context, item.price)],
                ),
                AdminMarketplaceLabels.stock(context, item),
              ],
            ),
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
