import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_icon_tag.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_menu_row.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/chat_routes.dart';
import 'package:watad/core/router/routes/profile_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_item_gallery.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_item_seller_card.dart';

/// Everything on the item page above the bottom bar: photos, name,
/// category, price, stock, description, the seller and «إبلاغ».
class MarketplaceItemDetails extends StatelessWidget {
  const MarketplaceItemDetails({required this.item, super.key});

  final MarketplaceItem item;

  @override
  Widget build(BuildContext context) {
    final description = item.description?.trim() ?? '';
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        MarketplaceItemGallery(photoUrls: item.photoUrls),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            AppStatusBadge(
              label: context.tr(
                'marketplace.categories.${item.category.value}',
              ),
            ),
            if (!item.inStock)
              AppStatusBadge(
                label: context.tr('marketplace.item_details.out_of_stock'),
                tone: AppTone.danger,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(item.name, style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.xs),
        AppMoneyText(
          item.price,
          style: AppTextStyles.h1.copyWith(color: AppColors.primary),
        ),
        Text(
          context.tr('marketplace.item_details.per_unit'),
          style: AppTextStyles.caption,
        ),
        if (item.inStock) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr(
              'marketplace.item_details.stock',
              args: [context.formatNumber(item.stockQuantity)],
            ),
            style: AppTextStyles.body,
          ),
        ],
        if (item.isMine) ...[
          const SizedBox(height: AppSpacing.sm),
          AppIconTag(
            key: const Key('marketplace_item_mine'),
            label: context.tr(
              item.isActive
                  ? 'marketplace.item_details.mine_note'
                  : 'marketplace.item_details.mine_hidden_note',
            ),
            icon: Icons.info_outline,
            tone: item.isActive ? AppTone.neutral : AppTone.attention,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppSectionHeader(
          title: context.tr('marketplace.item_details.description_title'),
        ),
        Text(
          description.isEmpty
              ? context.tr('marketplace.item_details.no_description')
              : description,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionHeader(
          title: context.tr('marketplace.item_details.seller_title'),
        ),
        MarketplaceItemSellerCard(
          item: item,
          onTap: () => context.pushNamed(
            ProfileRoutes.publicProfileName,
            pathParameters: {'userId': item.sellerId},
          ),
        ),
        if (!item.isMine) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const Key('marketplace_item_message_seller'),
            label: context.tr('marketplace.item_details.message_seller'),
            icon: Icons.chat_bubble_outline_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.pushNamed(
              ChatRoutes.chatStartName,
              pathParameters: {'userId': item.sellerId},
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Help and support (GRA-63) turns this row on.
          AppMenuRow(
            key: const Key('marketplace_item_report'),
            icon: Icons.flag_outlined,
            label: context.tr('marketplace.item_details.report'),
            tag: context.tr('marketplace.item_details.coming_soon'),
            isMuted: true,
            onTap: () => context.showSnackBar(
              context.tr('marketplace.item_details.report_coming_soon'),
            ),
          ),
        ],
      ],
    );
  }
}
