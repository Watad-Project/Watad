import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

class ContractorDashboardOpportunitiesBanner extends StatelessWidget {
  const ContractorDashboardOpportunitiesBanner({
    super.key,
    required this.opportunitiesCount,
    this.onBrowse,
  });

  final int opportunitiesCount;
  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: AppCard(
        color: AppColors.primaryLight,
        borderColor: AppColors.primaryBorder,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                context.tr(
                  'dashboard.contractor.opportunities_banner',
                  namedArgs: {'count': '$opportunitiesCount'},
                ),
                style: AppTextStyles.label.copyWith(color: AppColors.ink),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 100,
              child: AppButton(
                label: context.tr('dashboard.contractor.browse_opportunities'),
                onPressed: onBrowse ?? () {},
                variant: AppButtonVariant.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
