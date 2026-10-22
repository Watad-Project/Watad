import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item.dart';
import 'package:watad/features/marketplace/admin/presentation/widgets/admin_marketplace_labels.dart';

/// Everything about one listing: name and status, price, stock, when it was
/// listed and last changed, its orders and reports, the description, and
/// the seller, whose page in user management opens on a tap.
class AdminMarketplaceItemOverview extends StatelessWidget {
  const AdminMarketplaceItemOverview({
    required this.item,
    required this.onSellerTap,
    super.key,
  });

  final AdminMarketplaceItem item;
  final VoidCallback onSellerTap;

  static const EdgeInsetsGeometry _sectionPadding = EdgeInsetsDirectional.only(
    top: AppSpacing.lg,
    bottom: AppSpacing.xs,
  );

  @override
  Widget build(BuildContext context) {
    final description = item.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(item.name, style: AppTextStyles.h2)),
            const SizedBox(width: AppSpacing.xs),
            AppStatusBadge(
              label: context.tr(AdminMarketplaceLabels.statusKey(item.status)),
              tone: AdminMarketplaceLabels.statusTone(item.status),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppKeyValueList(
          rows: [
            AppKeyValueRow(
              label: context.tr('marketplace.price'),
              value: AppMoneyText.format(context, item.price),
            ),
            AppKeyValueRow(
              label: context.tr('marketplace.stock_label'),
              value: context.formatNumber(item.stock),
            ),
            AppKeyValueRow(
              label: context.tr('marketplace.listed_at'),
              value: AdminMarketplaceLabels.date(context, item.createdAt),
            ),
            AppKeyValueRow(
              label: context.tr('marketplace.updated_at'),
              value: AdminMarketplaceLabels.date(context, item.updatedAt),
            ),
            AppKeyValueRow(
              label: context.tr('marketplace.orders'),
              value: context.formatNumber(item.orderCount),
            ),
            AppKeyValueRow(
              label: context.tr('marketplace.open_reports'),
              value: context.formatNumber(item.openReportCount),
            ),
          ],
        ),
        if (description != null && description.trim().isNotEmpty) ...[
          AppSectionHeader(
            title: context.tr('marketplace.description'),
            padding: _sectionPadding,
          ),
          Text(description, style: AppTextStyles.body),
        ],
        AppSectionHeader(
          title: context.tr('marketplace.seller'),
          padding: _sectionPadding,
        ),
        AppCard(
          onTap: onSellerTap,
          child: Row(
            children: [
              AppAvatar(
                url: item.sellerAvatarUrl,
                semanticLabel: item.sellerName,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.sellerIsVerified)
                      AppVerifiedName(
                        name: item.sellerName,
                        style: AppTextStyles.label,
                      )
                    else
                      Text(item.sellerName, style: AppTextStyles.label),
                    Text(
                      AdminMarketplaceLabels.rating(context, item),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              // Points to the end of the line; it flips in RTL by itself.
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
