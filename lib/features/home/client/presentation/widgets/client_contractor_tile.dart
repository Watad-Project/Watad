import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor.dart';

/// One contractor in the «الكل» list: photo (or the default avatar), name
/// with the verified check, and rating.
class ClientContractorTile extends StatelessWidget {
  const ClientContractorTile({required this.contractor, super.key});

  final ClientContractor contractor;

  @override
  Widget build(BuildContext context) {
    final rating = contractor.ratingAvg;
    final count = contractor.ratingCount;
    return AppCard(
      child: Row(
        children: [
          AppAvatar(
            url: contractor.avatarUrl,
            semanticLabel: contractor.companyName,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppVerifiedName(
              name: contractor.companyName,
              style: AppTextStyles.label.copyWith(fontSize: 15),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (rating != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.ink,
                    ),
                    Text(
                      context.formatNumber(rating, decimals: 1),
                      style: AppTextStyles.label,
                    ),
                  ],
                ),
              Text(
                count == 0
                    ? context.tr('home.no_ratings')
                    : context.plural(
                        'home.ratings_count',
                        count,
                        args: [context.formatNumber(count)],
                      ),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
