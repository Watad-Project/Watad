import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_item_card.dart';

/// The seller on the item page: photo, name (with the green check when the
/// seller is a verified business) and rating. A tap opens their public
/// profile.
class MarketplaceItemSellerCard extends StatelessWidget {
  const MarketplaceItemSellerCard({
    required this.item,
    required this.onTap,
    super.key,
  });

  final MarketplaceItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const Key('marketplace_item_seller'),
      onTap: onTap,
      child: Row(
        children: [
          AppAvatar(url: item.sellerAvatarUrl, semanticLabel: item.sellerName),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.sellerIsVerifiedBusiness)
                  AppVerifiedName(
                    name: item.sellerName,
                    style: AppTextStyles.label,
                  )
                else
                  Text(item.sellerName, style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  MarketplaceItemCard.ratingLabel(context, item),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
