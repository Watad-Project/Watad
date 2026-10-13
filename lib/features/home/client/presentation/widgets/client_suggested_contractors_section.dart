import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_business_mini_card.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/home/client/domain/entities/client_suggested_contractor.dart';

class ClientSuggestedContractorsSection extends StatelessWidget {
  const ClientSuggestedContractorsSection({
    required this.contractors,
    this.onSeeAllTap,
    this.onContractorTap,
    super.key,
  });

  final List<ClientSuggestedContractor> contractors;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<ClientSuggestedContractor>? onContractorTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('home.client.suggested_contractors'),
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            GestureDetector(
              onTap: onSeeAllTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                child: Text(
                  context.tr('home.client.see_all'),
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (contractors.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.md),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              context.tr('home.client.empty_contractors'),
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          SizedBox(
            height: 165,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: contractors.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final contractor = contractors[index];
                return SizedBox(
                  width: 160,
                  child: AppBusinessMiniCard(
                    name: contractor.companyName,
                    ratingLabel: contractor.ratingLabel,
                    projectsLabel: contractor.projectsLabel,
                    isVerified: contractor.isVerified,
                    imageUrl: contractor.avatarPath,
                    onTap: onContractorTap == null
                        ? null
                        : () => onContractorTap!(contractor),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
