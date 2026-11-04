import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_menu_row.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_actions.dart';

/// The seller's part of the order page (GRA-71): mark as shipped, message
/// the buyer; review and report come later (GRA-61, GRA-63).
/// Each button shows only when the order allows it ([OrderActions]).
class MarketplaceOrderSellerActions extends StatelessWidget {
  const MarketplaceOrderSellerActions({
    required this.actions,
    required this.isBusy,
    required this.isShipping,
    required this.onShip,
    required this.onMessage,
    super.key,
  });

  final OrderActions actions;

  /// An action is being sent: the others wait.
  final bool isBusy;
  final bool isShipping;
  final VoidCallback onShip;
  final VoidCallback onMessage;

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
        const SizedBox(height: AppSpacing.md),
        if (actions.canReview)
          AppMenuRow(
            key: const Key('order_review'),
            icon: Icons.star_outline,
            label: context.tr('marketplace.order_details.review_buyer'),
            tag: context.tr('marketplace.item_details.coming_soon'),
            isMuted: true,
            onTap: () => context.showSnackBar(
              context.tr('marketplace.order_details.review_coming_soon'),
            ),
          ),
        AppMenuRow(
          key: const Key('order_report'),
          icon: Icons.flag_outlined,
          label: context.tr('marketplace.order_details.report'),
          tag: context.tr('marketplace.item_details.coming_soon'),
          isMuted: true,
          onTap: () => context.showSnackBar(
            context.tr('marketplace.item_details.report_coming_soon'),
          ),
        ),
      ],
    );
  }
}
