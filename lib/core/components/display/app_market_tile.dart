import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_icon_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_network_image.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';

/// A product in the market grid: photo with its condition (new, surplus,
/// used), name, seller, price per unit and an add button.
///
/// The price and unit arrive formatted (the price through `Money`).
class AppMarketTile extends StatelessWidget {
  const AppMarketTile({
    super.key,
    required this.title,
    required this.seller,
    required this.priceLabel,
    required this.addTooltip,
    this.unitLabel,
    this.conditionLabel,
    this.conditionTone = AppTone.success,
    this.imageUrl,
    this.onTap,
    this.onAdd,
  });

  final String title;
  final String seller;
  final String priceLabel;

  /// E.g. "/ ton".
  final String? unitLabel;
  final String? conditionLabel;
  final AppTone conditionTone;
  final String? imageUrl;
  final VoidCallback? onTap;

  /// Adds the product to the cart. Null disables the button.
  final VoidCallback? onAdd;

  /// What screen readers say for the add button.
  final String addTooltip;

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
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xxs,
              AppSpacing.xxs,
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
                Text(
                  seller,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
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
                    AppIconButton(
                      icon: Icons.add,
                      tooltip: addTooltip,
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
