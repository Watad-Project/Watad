import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The queue while it loads: shimmering cards shaped like
/// AdminReviewRequestCard.
class AdminReviewSkeleton extends StatelessWidget {
  const AdminReviewSkeleton({super.key});

  static const int _cards = 3;

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
          for (var i = 0; i < _cards; i++) ...[
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AppSkeletonBox(height: 16, width: 120),
                      Spacer(),
                      AppSkeletonBox(
                        height: 24,
                        width: 56,
                        radius: AppRadius.pill,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  AppSkeletonBox(height: 12, width: 180),
                  SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppSkeletonBox(
                          height: AppSizes.controlHeight,
                          radius: AppRadius.pill,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppSkeletonBox(
                          height: AppSizes.controlHeight,
                          radius: AppRadius.pill,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
