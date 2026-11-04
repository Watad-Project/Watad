import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_cart_group.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_summary_rows.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_seller_group.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/cart_entry_tile.dart';

/// One seller's lines in the cart, the seller's total, and the checkout of
/// that group alone (an order has one seller).
class CartSellerSection extends StatelessWidget {
  const CartSellerSection({
    required this.group,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onCheckout,
    super.key,
  });

  final CartSellerGroup group;
  final void Function(String itemId, int quantity) onQuantityChanged;
  final ValueChanged<String> onRemove;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final units = group.entries.fold(0, (sum, e) => sum + e.line.quantity);
    return AppCartGroup(
      key: ValueKey('cart_group_${group.sellerId}'),
      title: group.sellerName,
      children: [
        for (final entry in group.entries)
          CartEntryTile(
            entry: entry,
            onRemove: () => onRemove(entry.line.itemId),
            onQuantityChanged: (quantity) =>
                onQuantityChanged(entry.line.itemId, quantity),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSummaryRows(
                rows: [
                  AppSummaryRow(
                    label: context.tr('marketplace.cart.units'),
                    value: context.formatNumber(units),
                  ),
                ],
                total: AppSummaryRow(
                  label: context.tr('marketplace.cart.seller_total'),
                  value: AppMoneyText.format(context, group.total),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                key: ValueKey('cart_checkout_${group.sellerId}'),
                label: context.tr('marketplace.cart.checkout'),
                onPressed: onCheckout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
