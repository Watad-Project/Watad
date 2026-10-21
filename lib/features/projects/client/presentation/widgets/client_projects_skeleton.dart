import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// Shimmering cards while projects or offers load.
class ClientProjectsSkeleton extends StatelessWidget {
  const ClientProjectsSkeleton({super.key});

  static const int _cards = 3;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          for (var i = 0; i < _cards; i++) ...[
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  AppSkeletonBox(height: 12, width: 120),
                  SizedBox(height: AppSpacing.md),
                  AppSkeletonBox(height: 20, width: 110),
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
