import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item_status.dart';

/// How a listing's status, stock, seller rating and dates read, in the list
/// and on its page.
abstract final class AdminMarketplaceLabels {
  static String statusKey(AdminMarketplaceItemStatus status) =>
      switch (status) {
        AdminMarketplaceItemStatus.live => 'marketplace.status_live',
        AdminMarketplaceItemStatus.hidden => 'marketplace.status_hidden',
        AdminMarketplaceItemStatus.removed => 'marketplace.status_removed',
        AdminMarketplaceItemStatus.outOfStock =>
          'marketplace.status_out_of_stock',
      };

  static AppTone statusTone(AdminMarketplaceItemStatus status) =>
      switch (status) {
        AdminMarketplaceItemStatus.live => AppTone.success,
        AdminMarketplaceItemStatus.hidden => AppTone.neutral,
        AdminMarketplaceItemStatus.removed => AppTone.danger,
        AdminMarketplaceItemStatus.outOfStock => AppTone.attention,
      };

  /// «المخزون: ١٢».
  static String stock(BuildContext context, AdminMarketplaceItem item) =>
      context.tr('marketplace.stock', args: [context.formatNumber(item.stock)]);

  /// «٤٫٨ (١٢ تقييمًا)», or «لا تقييمات بعد».
  static String rating(BuildContext context, AdminMarketplaceItem item) {
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

  /// «٢٢ أكتوبر ٢٠٢٦ ٤:٠٥ م», on the phone's clock, in the app's language.
  static String date(BuildContext context, DateTime time) {
    final locale = context.isArabic
        ? AppLocalization.arabic.languageCode
        : AppLocalization.english.languageCode;
    return DateFormat.yMMMd(locale).add_jm().format(time.toLocal());
  }
}
