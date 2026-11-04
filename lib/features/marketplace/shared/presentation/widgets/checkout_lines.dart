import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_cart_group.dart';
import 'package:watad/core/components/display/app_cart_line.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_summary_rows.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_review.dart';

/// What the order will hold: each line at its current price, and the
/// total.
class CheckoutLines extends StatelessWidget {
  const CheckoutLines({required this.review, super.key});

  final CheckoutReview review;

  @override
  Widget build(BuildContext context) {
    return AppCartGroup(
      title: review.sellerName,
      children: [
        for (final entry in review.entries)
          AppCartLine(
            title: entry.item?.name ?? '',
            subtitle: [
              context.tr(
                'marketplace.checkout.line_quantity',
                args: [
                  context.formatNumber(entry.line.quantity),
                  AppMoneyText.format(context, entry.line.priceWhenAdded),
                ],
              ),
              if (entry.previousPrice case final previous?)
                context.tr(
                  'marketplace.cart.price_changed',
                  args: [AppMoneyText.format(context, previous)],
                ),
              if (entry.quantityLowered)
                context.tr(
                  'marketplace.cart.quantity_lowered',
                  args: [context.formatNumber(entry.line.quantity)],
                ),
            ].join('\n'),
            priceLabel: AppMoneyText.format(context, entry.subtotal),
            imageUrl: entry.item?.firstPhotoUrl,
          ),
        Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: AppSummaryRows(
            rows: [
              AppSummaryRow(
                label: context.tr('marketplace.cart.units'),
                value: context.formatNumber(
                  review.entries.fold(0, (sum, e) => sum + e.line.quantity),
                ),
              ),
            ],
            total: AppSummaryRow(
              label: context.tr('marketplace.checkout.total'),
              value: AppMoneyText.format(context, review.total),
            ),
          ),
        ),
      ],
    );
  }
}
