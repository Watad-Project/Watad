import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/dashboard/admin/presentation/widgets/admin_dashboard_tile_grid.dart';

/// The dashboard while its numbers load: shimmering tiles shaped like
/// AppStatTile.
class AdminDashboardSkeleton extends StatelessWidget {
  const AdminDashboardSkeleton({super.key});

  static const int _tiles = 6;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: AppShimmer(
        child: AdminDashboardTileGrid(
          children: List.filled(
            _tiles,
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeletonBox(height: 12, width: 90),
                  SizedBox(height: AppSpacing.sm),
                  AppSkeletonBox(height: 28, width: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
