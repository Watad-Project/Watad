import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/layout/app_menu_row.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_actions.dart';

/// The seller's part of the order page (GRA-71): mark as shipped, cancel
/// while unpaid, message the buyer, rate them (GRA-61) and report the order
/// (GRA-63). Each button shows only when the order allows it
/// ([OrderActions]).
class MarketplaceOrderSellerActions extends StatelessWidget {
  const MarketplaceOrderSellerActions({
    required this.actions,
    required this.isBusy,
    required this.isShipping,
    required this.isCancelling,
    required this.onShip,
    required this.onCancel,
    required this.onMessage,
    required this.onReview,
    required this.onReport,
    super.key,
  });

  final OrderActions actions;

  /// An action is being sent: the others wait.
  final bool isBusy;
  final bool isShipping;
  final bool isCancelling;
  final VoidCallback onShip;
  final VoidCallback onCancel;
  final VoidCallback onMessage;

  /// Rate the buyer (GRA-61).
  final VoidCallback onReview;

  /// A new report about this order (GRA-63).
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('order_seller_actions'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (actions.canShip) ...[
          AppButton(
            key: const Key('order_ship'),
            label: context.tr('marketplace.order_details.ship'),
            icon: Icons.local_shipping_outlined,
            isLoading: isShipping,
            onPressed: isBusy ? null : onShip,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppButton(
          key: const Key('order_message'),
          label: context.tr('marketplace.order_details.message_buyer'),
          icon: Icons.chat_bubble_outline,
          variant: AppButtonVariant.secondary,
          onPressed: onMessage,
        ),
        if (actions.canCancel) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const Key('order_cancel'),
            label: context.tr('marketplace.order_details.cancel'),
            variant: AppButtonVariant.link,
            isLoading: isCancelling,
            onPressed: isBusy ? null : onCancel,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (actions.canReview)
          AppMenuRow(
            key: const Key('order_review'),
            icon: Icons.star_outline,
            label: context.tr('marketplace.order_details.review_buyer'),
            onTap: onReview,
          ),
        AppMenuRow(
          key: const Key('order_report'),
          icon: Icons.flag_outlined,
          label: context.tr('marketplace.order_details.report'),
          onTap: onReport,
        ),
      ],
    );
  }
}
