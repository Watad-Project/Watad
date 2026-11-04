import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/inputs/app_quantity_stepper.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';

/// The item page's bottom bar: the quantity and «أضف للسلة»; a disabled
/// «نفدت الكمية» when nothing is left; «تعديل» on my own item.
class MarketplaceItemBuyBar extends StatelessWidget {
  const MarketplaceItemBuyBar({
    required this.item,
    required this.quantity,
    required this.isAdding,
    required this.onQuantityChanged,
    required this.onAdd,
    required this.onEdit,
    super.key,
  });

  final MarketplaceItem item;
  final int quantity;
  final bool isAdding;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAdd;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _children(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _children(BuildContext context) {
    if (item.isMine) {
      return [
        AppButton(
          key: const Key('marketplace_item_edit'),
          label: context.tr('marketplace.item_details.edit'),
          icon: Icons.edit_outlined,
          onPressed: onEdit,
        ),
      ];
    }
    if (!item.inStock) {
      return [
        AppButton(
          key: const Key('marketplace_item_add'),
          label: context.tr('marketplace.item_details.out_of_stock'),
          onPressed: null,
        ),
      ];
    }
    return [
      Row(
        children: [
          Expanded(
            child: Text(
              context.tr('marketplace.item_details.quantity_label'),
              style: AppTextStyles.label,
            ),
          ),
          AppQuantityStepper(
            key: const Key('marketplace_item_quantity'),
            value: quantity,
            min: 1,
            max: item.stockQuantity,
            valueLabel: context.formatNumber(quantity),
            onChanged: isAdding ? null : onQuantityChanged,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      AppButton(
        key: const Key('marketplace_item_add'),
        label: context.tr('marketplace.item_details.add_to_cart'),
        icon: Icons.add_shopping_cart_outlined,
        isLoading: isAdding,
        onPressed: onAdd,
      ),
    ];
  }
}
