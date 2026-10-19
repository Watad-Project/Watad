import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_earnings.dart';

class ContractorDashboardEarningsCard extends StatelessWidget {
  const ContractorDashboardEarningsCard({super.key, required this.earnings});

  final ContractorDashboardEarnings earnings;

  @override
  Widget build(BuildContext context) {
    final currency = context.tr('dashboard.contractor.currency');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: AppCard(
        color: AppColors.ink,
        borderColor: AppColors.ink,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('dashboard.contractor.earnings_this_month'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${earnings.thisMonthEarnings.toJson()} $currency',
                    style: AppTextStyles.h1.copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),
            Container(
              height: 48,
              width: 1,
              color: AppColors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr(
                      'dashboard.contractor.earnings_pending_transfers',
                    ),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${earnings.pendingTransfers.toJson()} $currency',
                    style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
