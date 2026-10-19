import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The queue while it loads: shimmering cards in two columns, shaped like
/// AdminReviewRequestCard.
class AdminReviewSkeleton extends StatelessWidget {
  const AdminReviewSkeleton({super.key});

  static const int _rows = 2;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          const Row(
            children: [
              AppSkeletonBox(height: 36, width: 72, radius: AppRadius.pill),
              SizedBox(width: AppSpacing.xs),
              AppSkeletonBox(height: 36, width: 72, radius: AppRadius.pill),
              SizedBox(width: AppSpacing.xs),
              AppSkeletonBox(height: 36, width: 72, radius: AppRadius.pill),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < _rows; i++) ...[
            const Row(
              children: [
                Expanded(child: _CardSkeleton()),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: _CardSkeleton()),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeletonBox(height: 16, width: 96),
          SizedBox(height: AppSpacing.xs),
          AppSkeletonBox(height: 24, width: 56, radius: AppRadius.pill),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              AppSkeletonBox(height: 32, width: 32, radius: AppRadius.pill),
              SizedBox(width: AppSpacing.xs),
              Expanded(child: AppSkeletonBox(height: 12)),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          AppSkeletonBox(
            height: AppSizes.controlHeight,
            radius: AppRadius.pill,
          ),
        ],
      ),
    );
  }
}
