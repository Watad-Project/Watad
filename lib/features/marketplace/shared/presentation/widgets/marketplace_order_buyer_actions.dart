import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_menu_row.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_actions.dart';

/// The buyer's part of the order page: pay, confirm delivery, cancel,
/// message the seller; review and report come later (GRA-61, GRA-63).
/// Each button shows only when the order allows it ([OrderActions]).
class MarketplaceOrderBuyerActions extends StatelessWidget {
  const MarketplaceOrderBuyerActions({
    required this.actions,
    required this.isBusy,
    required this.isCancelling,
    required this.isConfirming,
    required this.onPay,
    required this.onConfirmDelivery,
    required this.onCancel,
    required this.onMessage,
    super.key,
  });

  final OrderActions actions;

  /// An action is being sent: the others wait.
  final bool isBusy;
  final bool isCancelling;
  final bool isConfirming;
  final VoidCallback onPay;
  final VoidCallback onConfirmDelivery;
  final VoidCallback onCancel;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('order_buyer_actions'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (actions.canPay) ...[
          AppButton(
            key: const Key('order_pay'),
            label: context.tr('marketplace.order_details.pay_now'),
            icon: Icons.payment_outlined,
            onPressed: isBusy ? null : onPay,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (actions.canConfirmDelivery) ...[
          AppButton(
            key: const Key('order_confirm_delivery'),
            label: context.tr('marketplace.order_details.confirm_delivery'),
            icon: Icons.inventory_outlined,
            isLoading: isConfirming,
            onPressed: isBusy ? null : onConfirmDelivery,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppButton(
          key: const Key('order_message'),
          label: context.tr('marketplace.order_details.message_seller'),
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
            label: context.tr('marketplace.order_details.review'),
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
