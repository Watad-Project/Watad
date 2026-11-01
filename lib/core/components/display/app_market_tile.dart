import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_icon_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_network_image.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';

/// A product in the market grid: photo with its condition (new, surplus,
/// used, out of stock), name, seller (with optional verified check and
/// rating), price per unit and an optional add button.
///
/// The price and unit arrive formatted (the price through `Money`).
class AppMarketTile extends StatelessWidget {
  const AppMarketTile({
    super.key,
    required this.title,
    required this.seller,
    required this.priceLabel,
    this.sellerIsVerified = false,
    this.ratingLabel,
    this.unitLabel,
    this.conditionLabel,
    this.conditionTone = AppTone.success,
    this.imageUrl,
    this.onTap,
    this.onAdd,
    this.addTooltip,
    this.showAddButton = true,
  });

  final String title;
  final String seller;
  final String priceLabel;
  final bool sellerIsVerified;
  final String? ratingLabel;

  /// E.g. "/ ton".
  final String? unitLabel;
  final String? conditionLabel;
  final AppTone conditionTone;
  final String? imageUrl;
  final VoidCallback? onTap;

  /// Adds the product to the cart. Null disables the button.
  final VoidCallback? onAdd;

  /// What screen readers say for the add button. Defaults to "Add".
  final String? addTooltip;

  /// Whether to show the add-to-cart icon button next to the price.
  final bool showAddButton;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 110,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(url: imageUrl),
                if (conditionLabel != null)
                  PositionedDirectional(
                    top: AppSpacing.xs,
                    start: AppSpacing.xs,
                    child: AppStatusBadge(
                      label: conditionLabel!,
                      tone: conditionTone,
                      onImage: true,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppSpacing.sm,
              AppSpacing.sm,
              showAddButton ? AppSpacing.xxs : AppSpacing.sm,
              showAddButton ? AppSpacing.xxs : AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label,
                ),
                if (sellerIsVerified)
                  AppVerifiedName(name: seller, style: AppTextStyles.caption)
                else
                  Text(
                    seller,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                if (ratingLabel != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          ratingLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            priceLabel,
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (unitLabel != null)
                            Text(unitLabel!, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    if (showAddButton)
                      AppIconButton(
                        icon: Icons.add,
                        tooltip: addTooltip ?? context.tr('common.add'),
                        onPressed: onAdd,
                        variant: AppIconButtonVariant.filled,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
