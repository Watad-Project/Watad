import 'package:flutter/material.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// Shimmering timeline steps while a project's tasks load.
class ClientProjectTasksSkeleton extends StatelessWidget {
  const ClientProjectTasksSkeleton({super.key});

  static const int _steps = 4;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          const AppSkeletonBox(height: 22, width: 160),
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
                        width: 96,
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
