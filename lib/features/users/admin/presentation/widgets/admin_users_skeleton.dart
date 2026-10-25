import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The users while they load: shimmering rows shaped like AdminUserTile.
class AdminUsersSkeleton extends StatelessWidget {
  const AdminUsersSkeleton({super.key});

  static const int _rows = 5;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        AppSkeletonBox(height: 12, width: 190),
                      ],
                    ),
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
