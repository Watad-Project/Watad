import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/components/display/app_stat_tile.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/dashboard/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:watad/features/dashboard/admin/presentation/bloc/admin_dashboard_bloc.dart';
import 'package:watad/features/dashboard/admin/presentation/widgets/admin_dashboard_shortcut.dart';
import 'package:watad/features/dashboard/admin/presentation/widgets/admin_dashboard_skeleton.dart';
import 'package:watad/features/dashboard/admin/presentation/widgets/admin_dashboard_tile_grid.dart';

/// «الرئيسية» — the admin's home: what waits for review, the platform's
/// users, projects and market in numbers, and the management screens.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({this.onReviewTap, this.bell, super.key});

  /// Opens the «التوثيق» tab, from the pending licenses and deeds.
  final VoidCallback? onReviewTap;

  /// The notifications bell, lent by that feature (AppSlots.notificationsBell).
  final Widget? bell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('dashboard.admin.title'),
        actions: [?bell],
      ),
      body: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
        // Loading, the numbers and errors fade into each other.
        builder: (context, state) => AnimatedSwitcher(
          duration: AppMotion.enter,
          reverseDuration: AppMotion.exit,
          switchInCurve: AppMotion.enterCurve,
          switchOutCurve: AppMotion.exitCurve,
          child: _body(context, state),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AdminDashboardState state) {
    final bloc = context.read<AdminDashboardBloc>();
    final stats = state.stats;
    if (stats == null) {
      if (state.status == AdminDashboardStatus.failure) {
        return AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(state.failure!.messageKey),
          onRetry: () => bloc.add(const AdminDashboardFetched()),
        );
      }
      return const AdminDashboardSkeleton(key: ValueKey('loading'));
    }
    return RefreshIndicator(
      key: const ValueKey('stats'),
      onRefresh: () async => bloc.add(const AdminDashboardFetched()),
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          const _Section(titleKey: 'dashboard.admin.waiting'),
          _Waiting(stats: stats, onReviewTap: onReviewTap),
          const _Section(titleKey: 'dashboard.admin.users'),
          _Users(stats: stats),
          const _Section(titleKey: 'dashboard.admin.projects'),
          _Projects(stats: stats),
          const _Section(titleKey: 'dashboard.admin.market'),
          _Market(stats: stats),
          const _Section(titleKey: 'dashboard.admin.manage'),
          AdminDashboardShortcut(
            label: context.tr('dashboard.admin.manage_users'),
            icon: Icons.people_alt_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          AdminDashboardShortcut(
            label: context.tr('dashboard.admin.manage_market'),
            icon: Icons.storefront_outlined,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.titleKey});

  final String titleKey;

  @override
  Widget build(BuildContext context) => AppSectionHeader(
    title: context.tr(titleKey),
    padding: const EdgeInsetsDirectional.only(
      top: AppSpacing.lg,
      bottom: AppSpacing.xs,
    ),
  );
}

/// The licenses and deeds waiting in «التوثيق».
class _Waiting extends StatelessWidget {
  const _Waiting({required this.stats, required this.onReviewTap});

  final AdminDashboardStats stats;
  final VoidCallback? onReviewTap;

  @override
  Widget build(BuildContext context) {
    return AdminDashboardTileGrid(
      children: [
        AppStatTile(
          label: context.tr('dashboard.admin.pending_licenses'),
          value: context.formatNumber(stats.pendingLicenses),
          icon: Icons.badge_outlined,
          isHighlighted: stats.pendingLicenses > 0,
          onTap: onReviewTap,
        ),
        AppStatTile(
          label: context.tr('dashboard.admin.pending_deeds'),
          value: context.formatNumber(stats.pendingDeeds),
          icon: Icons.description_outlined,
          isHighlighted: stats.pendingDeeds > 0,
          onTap: onReviewTap,
        ),
      ],
    );
  }
}

class _Users extends StatelessWidget {
  const _Users({required this.stats});

  final AdminDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return AdminDashboardTileGrid(
      children: [
        AppStatTile(
          label: context.tr('dashboard.admin.active_users'),
          value: context.formatNumber(stats.activeUsers),
          icon: Icons.person_outline,
        ),
        AppStatTile(
          label: context.tr('dashboard.admin.clients'),
          value: context.formatNumber(stats.clients),
          icon: Icons.home_outlined,
        ),
        AppStatTile(
          label: context.tr('dashboard.admin.businesses'),
          value: context.formatNumber(stats.businesses),
          caption: context.tr(
            'dashboard.admin.verified_count',
            args: [context.formatNumber(stats.verifiedBusinesses)],
          ),
          icon: Icons.business_outlined,
        ),
      ],
    );
  }
}

class _Projects extends StatelessWidget {
  const _Projects({required this.stats});

  final AdminDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    String count(int value) => context.formatNumber(value);
    return AdminDashboardTileGrid(
      children: [
        AppStatTile(
          label: context.tr('dashboard.admin.projects_total'),
          value: count(stats.projects),
          icon: Icons.assignment_outlined,
        ),
        AppStatTile(
          label: context.tr('dashboard.admin.status_draft'),
          value: count(stats.draftProjects),
        ),
        AppStatTile(
          label: context.tr('dashboard.admin.status_open'),
          value: count(stats.openProjects),
        ),
        AppStatTile(
          label: context.tr('dashboard.admin.status_in_progress'),
          value: count(stats.inProgressProjects),
        ),
        AppStatTile(
          label: context.tr('dashboard.admin.status_completed'),
          value: count(stats.completedProjects),
        ),
        AppStatTile(
          label: context.tr('dashboard.admin.status_cancelled'),
          value: count(stats.cancelledProjects),
        ),
      ],
    );
  }
}

class _Market extends StatelessWidget {
  const _Market({required this.stats});

  final AdminDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return AdminDashboardTileGrid(
      children: [
        AppStatTile(
          label: context.tr('dashboard.admin.market_items'),
          value: context.formatNumber(stats.marketItems),
          icon: Icons.inventory_2_outlined,
        ),
        AppStatTile(
          label: context.tr('dashboard.admin.market_items_live'),
          value: context.formatNumber(stats.liveMarketItems),
          icon: Icons.storefront_outlined,
        ),
      ],
    );
  }
}
