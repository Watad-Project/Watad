import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_market_tile.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_market_item.dart';

/// «منتجاته في السوق» (GRA-58): the user's items on sale, two per row, or
/// a line saying there are none.
class PublicProfileItems extends StatelessWidget {
  const PublicProfileItems({
    required this.items,
    required this.sellerName,
    this.onItemTap,
    super.key,
  });

  final List<ProfileMarketItem> items;
  final String sellerName;

  /// Opens an item; null while there's no item screen to open.
  final ValueChanged<ProfileMarketItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        context.tr('profile.public.no_items'),
        style: AppTextStyles.body.copyWith(color: AppColors.textBody),
      );
    }
    Widget tile(ProfileMarketItem item) => AppMarketTile(
      key: ValueKey(item.id),
      title: item.name,
      seller: sellerName,
      priceLabel: AppMoneyText.format(context, item.price),
      imageUrl: item.photoUrl,
      conditionLabel: item.inStock
          ? null
          : context.tr('profile.public.out_of_stock'),
      conditionTone: AppTone.danger,
      showAddButton: false,
      onTap: onItemTap == null ? null : () => onItemTap!(item),
    );
    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tile(items[i])),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: i + 1 < items.length
                    ? tile(items[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
