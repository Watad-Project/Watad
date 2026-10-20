import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// A request while it loads: the requester, their data and a file.
class AdminReviewDetailsSkeleton extends StatelessWidget {
  const AdminReviewDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      // A list, so a short screen clips it instead of overflowing.
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: const [
          AppSkeletonBox(height: 16, width: 96),
          SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Row(
              children: [
                AppSkeletonBox(height: 56, width: 56, radius: AppRadius.pill),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: AppSkeletonBox(height: 16)),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          AppSkeletonBox(height: 160, radius: AppRadius.md),
          SizedBox(height: AppSpacing.lg),
          AppSkeletonBox(height: 240, radius: AppRadius.lg),
        ],
      ),
    );
  }
}
