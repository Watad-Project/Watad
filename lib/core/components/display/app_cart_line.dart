import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_network_image.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// One product line of a cart, an order or a refund: thumbnail, name,
/// quantity and price. Usually inside an `AppCartGroup`.
///
/// The quantity and price arrive formatted (the price through `Money`).
class AppCartLine extends StatelessWidget {
  const AppCartLine({
    super.key,
    required this.title,
    required this.priceLabel,
    this.subtitle,
    this.imageUrl,
    this.trailing,
    this.onTap,
  });

  final String title;

  /// E.g. the quantity, "20 tons".
  final String? subtitle;
  final String priceLabel;
  final String? imageUrl;

  /// Shown under the price, e.g. an `AppQuantityStepper` in the cart.
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            AppNetworkImage(
              url: imageUrl,
              width: 52,
              height: 52,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.sm),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label,
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  priceLabel,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  trailing!,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
