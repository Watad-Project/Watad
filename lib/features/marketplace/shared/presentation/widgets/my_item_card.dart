import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_network_image.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item_status.dart';

/// Displays one of the seller's listings on `/marketplace/my-items`.
///
/// Listings removed by an admin (`item.isRemoved`) show the admin's removal
/// reason and have no edit, hide/show, or delete actions.
class MyItemCard extends StatelessWidget {
  const MyItemCard({
    required this.item,
    this.isBusy = false,
    this.onTap,
    this.onEdit,
    this.onToggleVisibility,
    this.onDelete,
    super.key,
  });

  final MarketplaceItem item;
  final bool isBusy;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onDelete;

  static String statusKey(MarketplaceItemStatus status) => switch (status) {
    MarketplaceItemStatus.live => 'marketplace.status_live',
    MarketplaceItemStatus.hidden => 'marketplace.status_hidden',
    MarketplaceItemStatus.removed => 'marketplace.status_removed',
    MarketplaceItemStatus.outOfStock => 'marketplace.status_out_of_stock',
  };

  static AppTone statusTone(MarketplaceItemStatus status) => switch (status) {
    MarketplaceItemStatus.live => AppTone.success,
    MarketplaceItemStatus.hidden => AppTone.neutral,
    MarketplaceItemStatus.removed => AppTone.danger,
    MarketplaceItemStatus.outOfStock => AppTone.attention,
  };

  @override
  Widget build(BuildContext context) {
    final stockLabel = context.tr(
      'marketplace.stock',
      args: [context.formatNumber(item.stockQuantity)],
    );
    final priceAndStock = context.tr(
      'marketplace.price_and_stock',
      args: [
        context.tr(
          'marketplace.per_unit',
          args: [AppMoneyText.format(context, item.price)],
        ),
        stockLabel,
      ],
    );

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNetworkImage(
                url: item.firstPhotoUrl,
                width: 64,
                height: 64,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.md),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: AppStatusBadge(
                            label: context.tr(statusKey(item.status)),
                            tone: statusTone(item.status),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      context.tr(
                        'marketplace.categories.${item.category.value}',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(priceAndStock, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          if (item.isRemoved) ...[
            const SizedBox(height: AppSpacing.sm),
            AppStatusCard(
              tone: AppTone.danger,
              title: context.tr('marketplace.status_removed'),
              subtitle: context.tr('marketplace.my_items_removed_readonly'),
              reasonTitle: context.tr('common.reason'),
              reasonText: item.removalReason,
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.end,
              children: [
                if (onEdit != null)
                  AppButton(
                    key: ValueKey('my_item_edit_${item.id}'),
                    label: context.tr('marketplace.my_items_edit'),
                    variant: AppButtonVariant.link,
                    onPressed: isBusy ? null : onEdit,
                  ),
                if (onToggleVisibility != null)
                  AppButton(
                    key: ValueKey('my_item_toggle_${item.id}'),
                    label: context.tr(
                      item.isActive
                          ? 'marketplace.my_items_hide'
                          : 'marketplace.my_items_show',
                    ),
                    variant: AppButtonVariant.link,
                    onPressed: isBusy ? null : onToggleVisibility,
                  ),
                if (onDelete != null)
                  AppButton(
                    key: ValueKey('my_item_delete_${item.id}'),
                    label: context.tr('common.delete'),
                    variant: AppButtonVariant.link,
                    onPressed: isBusy ? null : onDelete,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
