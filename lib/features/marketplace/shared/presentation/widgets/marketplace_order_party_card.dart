import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// The other side of the order: the seller for the buyer, the buyer for
/// the seller. A tap opens their public profile.
class MarketplaceOrderPartyCard extends StatelessWidget {
  const MarketplaceOrderPartyCard({
    required this.role,
    required this.name,
    required this.avatarUrl,
    required this.onTap,
    super.key,
  });

  /// «البائع» or «المشتري».
  final String role;
  final String name;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const Key('order_party'),
      onTap: onTap,
      child: Row(
        children: [
          AppAvatar(url: avatarUrl, semanticLabel: name),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  name,
                  style: AppTextStyles.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
