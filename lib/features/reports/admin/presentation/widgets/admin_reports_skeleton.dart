import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The reports while they load: shimmering cards shaped like
/// AdminReportCard.
class AdminReportsSkeleton extends StatelessWidget {
  const AdminReportsSkeleton({super.key});

  static const int _cards = 3;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                        width: 64,
                        radius: AppRadius.pill,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  AppSkeletonBox(height: 12, width: 170),
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
