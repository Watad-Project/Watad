import 'package:flutter/material.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// Shimmering header and timeline steps while a contract's schedule loads.
class ContractorProjectTasksSkeleton extends StatelessWidget {
  const ContractorProjectTasksSkeleton({super.key});

  static const int _steps = 4;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          const AppSkeletonBox(
            height: 180,
            width: double.infinity,
            radius: AppRadius.md,
          ),
          const SizedBox(height: AppSpacing.md),
          const AppSkeletonBox(height: 22, width: 200),
          const SizedBox(height: AppSpacing.xs),
          const AppSkeletonBox(height: 14, width: 150),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < _steps; i++) ...[
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeletonBox(height: 26, width: 26, radius: AppRadius.pill),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeletonBox(height: 16, width: 170),
                      SizedBox(height: AppSpacing.xs),
                      AppSkeletonBox(height: 12, width: 120),
                      SizedBox(height: AppSpacing.xs),
                      AppSkeletonBox(
                        height: 24,
                        width: 110,
                        radius: AppRadius.pill,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}
