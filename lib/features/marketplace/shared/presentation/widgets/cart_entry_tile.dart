import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_cart_line.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/inputs/app_quantity_stepper.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_entry.dart';

/// One cart line: photo, name, unit price, what changed since it was added,
/// its amount, and under it «إزالة» and the quantity (1 to the stock). An
/// unavailable line has «إزالة» only.
class CartEntryTile extends StatelessWidget {
  const CartEntryTile({
    required this.entry,
    required this.onRemove,
    this.onQuantityChanged,
    super.key,
  });

  final CartEntry entry;
  final VoidCallback onRemove;
  final ValueChanged<int>? onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final line = entry.line;
    final previousPrice = entry.previousPrice;
    final notes = [
      if (item != null && entry.isAvailable)
        context.tr(
          'marketplace.cart.unit_price',
          args: [AppMoneyText.format(context, item.price)],
        )
      else
        context.tr('marketplace.cart.unavailable_note'),
      if (entry.isAvailable && previousPrice != null)
        context.tr(
          'marketplace.cart.price_changed',
          args: [AppMoneyText.format(context, previousPrice)],
        ),
      if (entry.isAvailable && entry.quantityLowered)
        context.tr(
          'marketplace.cart.quantity_lowered',
          args: [context.formatNumber(line.quantity)],
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCartLine(
          title: item?.name ?? context.tr('marketplace.cart.gone_title'),
          subtitle: notes.join('\n'),
          priceLabel: entry.isAvailable
              ? AppMoneyText.format(context, entry.subtotal)
              : '',
          imageUrl: item?.firstPhotoUrl,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              AppButton(
                key: ValueKey('cart_remove_${line.itemId}'),
                label: context.tr('marketplace.cart.remove'),
                icon: Icons.delete_outline,
                variant: AppButtonVariant.link,
                onPressed: onRemove,
              ),
              const Spacer(),
              if (item != null &&
                  entry.isAvailable &&
                  onQuantityChanged != null)
                AppQuantityStepper(
                  key: ValueKey('cart_quantity_${line.itemId}'),
                  value: line.quantity,
                  min: 1,
                  max: item.stockQuantity,
                  valueLabel: context.formatNumber(line.quantity),
                  onChanged: onQuantityChanged,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
