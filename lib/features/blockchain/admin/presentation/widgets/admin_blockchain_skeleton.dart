import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The monitor while it loads: a status card and project cards, shimmering.
class AdminBlockchainSkeleton extends StatelessWidget {
  const AdminBlockchainSkeleton({super.key});

  static const int _cards = 3;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSkeletonBox(height: 88, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < _cards; i++) ...[
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AppSkeletonBox(height: 16, width: 150),
                      Spacer(),
                      AppSkeletonBox(
                        height: 24,
                        width: 72,
                        radius: AppRadius.pill,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  AppSkeletonBox(height: 12, width: 190),
                  SizedBox(height: AppSpacing.xs),
                  AppSkeletonBox(height: 12, width: 120),
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
