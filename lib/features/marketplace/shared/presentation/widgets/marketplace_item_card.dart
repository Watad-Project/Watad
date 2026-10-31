import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_market_tile.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';

/// A single marketplace listing card in the browse grid: first photo, item
/// name, price through `Money`, seller with verified check and rating, and
/// «نفد» badge when out of stock.
class MarketplaceItemCard extends StatelessWidget {
  const MarketplaceItemCard({required this.item, this.onTap, super.key});

  final MarketplaceItem item;
  final VoidCallback? onTap;

  /// «٤٫٨ (١٢ تقييمًا)», or «لا تقييمات بعد».
  static String ratingLabel(BuildContext context, MarketplaceItem item) {
    final average = item.sellerRatingAvg;
    if (average == null || item.sellerRatingCount == 0) {
      return context.tr('marketplace.no_ratings');
    }
    return context.tr(
      'marketplace.rating',
      args: [
        context.formatNumber(average, decimals: 1),
        context.plural(
          'marketplace.ratings',
          item.sellerRatingCount,
          args: [context.formatNumber(item.sellerRatingCount)],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppMarketTile(
      title: item.name,
      seller: item.sellerName,
      sellerIsVerified: item.sellerIsVerifiedBusiness,
      ratingLabel: ratingLabel(context, item),
      priceLabel: AppMoneyText.format(context, item.price),
      imageUrl: item.firstPhotoUrl,
      conditionLabel: item.inStock
          ? null
          : context.tr('marketplace.out_of_stock_badge'),
      conditionTone: AppTone.danger,
      showAddButton: false,
      onTap: onTap,
    );
  }
}
