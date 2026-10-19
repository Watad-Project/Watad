import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// Shimmering contractor rows while the «الكل» list loads.
class ClientContractorsSkeleton extends StatelessWidget {
  const ClientContractorsSkeleton({super.key});

  static const int _rows = 6;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
        ),
        children: [
          for (var i = 0; i < _rows; i++) ...[
            const AppCard(
              child: Row(
                children: [
                  AppSkeletonBox(height: 48, width: 48, radius: AppRadius.pill),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeletonBox(height: 14, width: 140),
                        SizedBox(height: AppSpacing.xs),
                        AppSkeletonBox(height: 12, width: 90),
                      ],
                    ),
                  ),
                  AppSkeletonBox(height: 14, width: 40),
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
