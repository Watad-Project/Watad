import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The listings while they load: shimmering cards shaped like
/// AdminMarketplaceItemTile.
class AdminMarketplaceSkeleton extends StatelessWidget {
  const AdminMarketplaceSkeleton({super.key});

  static const int _rows = 5;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _rows; i++) ...[
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppSkeletonBox(height: 14, width: 150),
                      Spacer(),
                      AppSkeletonBox(
                        height: 24,
                        width: 64,
                        radius: AppRadius.pill,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  AppSkeletonBox(height: 12, width: 110),
                  SizedBox(height: AppSpacing.xs),
                  AppSkeletonBox(height: 12, width: 170),
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
