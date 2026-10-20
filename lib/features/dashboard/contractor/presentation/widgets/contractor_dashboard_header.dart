import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_profile.dart';

class ContractorDashboardHeader extends StatelessWidget {
  const ContractorDashboardHeader({
    this.bell,
    super.key,
    required this.profile,
    this.onVerificationStatusTap,
  });

  final ContractorDashboardProfile profile;
  final VoidCallback? onVerificationStatusTap;

  /// The notifications bell, lent by that feature (AppSlots.notificationsBell).
  final Widget? bell;

  @override
  Widget build(BuildContext context) {
    final company = profile.companyName.trim().isNotEmpty
        ? profile.companyName
        : context.tr('dashboard.contractor.default_company');

    final (labelKey, tone, canTap) = switch (profile.verificationStatus) {
      VerificationStatus.verified => (
        'dashboard.contractor.verification_verified',
        AppTone.success,
        false,
      ),
      VerificationStatus.pending => (
        'dashboard.contractor.verification_pending',
        AppTone.attention,
        true,
      ),
      VerificationStatus.rejected => (
        'dashboard.contractor.verification_rejected',
        AppTone.danger,
        true,
      ),
      VerificationStatus.unverified || VerificationStatus.suspended => (
        'dashboard.contractor.verification_unverified',
        AppTone.neutral,
        true,
      ),
    };

    final badge = AppStatusBadge(label: context.tr(labelKey), tone: tone);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  context.tr('dashboard.contractor.title'),
                  style: AppTextStyles.h1,
                ),
              ],
            ),
          ),
          if (canTap && onVerificationStatusTap != null)
            GestureDetector(onTap: onVerificationStatusTap, child: badge)
          else
            badge,
          ?bell,
        ],
      ),
    );
  }
}
