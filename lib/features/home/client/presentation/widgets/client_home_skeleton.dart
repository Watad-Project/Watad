import 'package:flutter/material.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The home screen while it loads: shimmering shapes of the greeting, the
/// search field and the «انشر مشروعاً» card.
class ClientHomeSkeleton extends StatelessWidget {
  const ClientHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeletonBox(height: 12, width: 80),
            SizedBox(height: AppSpacing.xs),
            AppSkeletonBox(height: 24, width: 180),
            SizedBox(height: AppSpacing.lg),
            AppSkeletonBox(
              height: AppSizes.controlHeight,
              radius: AppRadius.lg,
            ),
            SizedBox(height: AppSpacing.lg),
            AppSkeletonBox(height: 170, radius: AppRadius.xl),
          ],
        ),
      ),
    );
  }
}
