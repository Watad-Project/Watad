import 'package:flutter/material.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The list while it loads: shimmering rows shaped like NotificationTile.
class NotificationsSkeleton extends StatelessWidget {
  const NotificationsSkeleton({super.key});

  static const int _rows = 5;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < _rows; i++)
            const Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeletonBox(height: 16, width: 160),
                  SizedBox(height: AppSpacing.xxs),
                  AppSkeletonBox(height: 12),
                  SizedBox(height: AppSpacing.xxs),
                  AppSkeletonBox(height: 12, width: 64),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
