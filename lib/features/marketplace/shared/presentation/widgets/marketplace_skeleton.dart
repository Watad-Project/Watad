import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// Shimmering 2-column grid rows while marketplace listings load.
class MarketplaceSkeleton extends StatelessWidget {
  const MarketplaceSkeleton({super.key});

  static const int _rows = 2;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _rows; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _SkeletonCard()),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: _SkeletonCard()),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      padding: EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeletonBox(height: 120, radius: AppRadius.md),
          SizedBox(height: AppSpacing.sm),
          AppSkeletonBox(height: 12, width: 80),
          SizedBox(height: AppSpacing.xxs),
          AppSkeletonBox(height: 14, width: 120),
          SizedBox(height: AppSpacing.xs),
          AppSkeletonBox(height: 16, width: 90),
        ],
      ),
    );
  }
}
