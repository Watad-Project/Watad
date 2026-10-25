import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_donut_chart.dart';
import 'package:watad/core/components/display/app_meter.dart';
import 'package:watad/core/components/display/app_stat_tile.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/dashboard/admin/domain/entities/admin_dashboard_section.dart';
import 'package:watad/features/dashboard/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:watad/features/dashboard/admin/presentation/bloc/admin_dashboard_bloc.dart';
import 'package:watad/features/dashboard/admin/presentation/widgets/admin_dashboard_shortcut.dart';
import 'package:watad/features/dashboard/admin/presentation/widgets/admin_dashboard_skeleton.dart';
import 'package:watad/features/dashboard/admin/presentation/widgets/admin_dashboard_tile_grid.dart';

/// «الرئيسية» — the admin's home. Chips switch between what waits for
/// review, the users, the projects and the market, each as numbers and a
/// chart; the management screens are under them.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({
    this.onReviewTap,
    this.onUsersTap,
    this.onMarketTap,
    this.onReportsTap,
    this.bell,
    super.key,
  });

  /// Opens the «التوثيق» tab, from the pending licenses and deeds.
  final VoidCallback? onReviewTap;

  /// Opens «إدارة المستخدمين».
  final VoidCallback? onUsersTap;

  /// Opens «إدارة منتجات السوق».
  final VoidCallback? onMarketTap;

  /// Opens the tickets («البلاغات»), from the open tickets.
  final VoidCallback? onReportsTap;

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

  static String _sectionKey(AdminDashboardSection section) => switch (section) {
    AdminDashboardSection.waiting => 'dashboard.admin.waiting',
    AdminDashboardSection.users => 'dashboard.admin.users',
    AdminDashboardSection.projects => 'dashboard.admin.projects',
    AdminDashboardSection.market => 'dashboard.admin.market',
  };

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
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          AppFilterChips(
            key: const Key('admin_dashboard_sections'),
            // All four in view, on two lines when they don't fit on one.
            isWrapped: true,
            labels: [
              for (final section in AdminDashboardSection.values)
                context.tr(_sectionKey(section)),
            ],
            selectedIndex: state.section.index,
            onSelected: (index) => bloc.add(
              AdminDashboardSectionChanged(AdminDashboardSection.values[index]),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: AppMotion.enter,
            reverseDuration: AppMotion.exit,
            switchInCurve: AppMotion.enterCurve,
            switchOutCurve: AppMotion.exitCurve,
            layoutBuilder: (current, previous) => Stack(
              alignment: AlignmentDirectional.topCenter,
              children: [...previous, ?current],
            ),
            child: KeyedSubtree(
              key: ValueKey(state.section),
              child: switch (state.section) {
                AdminDashboardSection.waiting => _Waiting(
                  stats: stats,
                  onReviewTap: onReviewTap,
                  onReportsTap: onReportsTap,
                ),
                AdminDashboardSection.users => _Users(stats: stats),
                AdminDashboardSection.projects => _Projects(stats: stats),
                AdminDashboardSection.market => _Market(stats: stats),
              },
            ),
          ),
          AppSectionHeader(
            title: context.tr('dashboard.admin.manage'),
            padding: const EdgeInsetsDirectional.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.xs,
            ),
          ),
          AdminDashboardShortcut(
            label: context.tr('dashboard.admin.manage_users'),
            icon: Icons.people_alt_outlined,
            onTap: onUsersTap,
          ),
          const SizedBox(height: AppSpacing.sm),
          AdminDashboardShortcut(
            label: context.tr('dashboard.admin.manage_market'),
            icon: Icons.storefront_outlined,
            onTap: onMarketTap,
          ),
        ],
      ),
    );
  }
}

/// «٥٧، ١٤٪»: a count and its share of [total], in the app's digits.
String _countAndShare(BuildContext context, int count, int total) {
  final share = total == 0 ? 0 : (count * 100 / total).round();
  return context.tr(
    'dashboard.admin.count_share',
    args: [
      context.formatNumber(count),
      context.tr(
        'dashboard.admin.percent',
        args: [context.formatNumber(share)],
      ),
    ],
  );
}

/// A chart in a card, under its title.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// The licenses and deeds waiting in «التوثيق», and the tickets nobody
/// took yet: single numbers that open their screens, so tiles rather than
/// a chart.
class _Waiting extends StatelessWidget {
  const _Waiting({
    required this.stats,
    required this.onReviewTap,
    required this.onReportsTap,
  });

  final AdminDashboardStats stats;
  final VoidCallback? onReviewTap;
  final VoidCallback? onReportsTap;

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
        AppStatTile(
          label: context.tr('dashboard.admin.open_reports'),
          value: context.formatNumber(stats.openReports),
          icon: Icons.flag_outlined,
          isHighlighted: stats.openReports > 0,
          onTap: onReportsTap,
        ),
      ],
    );
  }
}

/// Who is online now and who can sign in, clients and businesses as parts
/// of the users, then how many businesses are verified.
class _Users extends StatelessWidget {
  const _Users({required this.stats});

  final AdminDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.clients + stats.businesses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminDashboardTileGrid(
          children: [
            AppStatTile(
              label: context.tr('dashboard.admin.online_users'),
              value: context.formatNumber(stats.onlineUsers),
              icon: Icons.wifi_tethering,
            ),
            AppStatTile(
              label: context.tr('dashboard.admin.active_users'),
              value: context.formatNumber(stats.activeUsers),
              icon: Icons.person_outline,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChartCard(
          title: context.tr('dashboard.admin.users_chart'),
          child: AppDonutChart(
            centerValue: context.formatNumber(total),
            centerLabel: context.tr('dashboard.admin.users'),
            slices: [
              AppDonutSlice(
                label: context.tr('dashboard.admin.clients'),
                value: stats.clients,
                valueLabel: _countAndShare(context, stats.clients, total),
              ),
              AppDonutSlice(
                label: context.tr('dashboard.admin.businesses'),
                value: stats.businesses,
                valueLabel: _countAndShare(context, stats.businesses, total),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: AppMeter(
            label: context.tr('dashboard.admin.verified_businesses'),
            valueLabel: context.tr(
              'dashboard.admin.of_total',
              args: [
                context.formatNumber(stats.verifiedBusinesses),
                context.formatNumber(stats.businesses),
              ],
            ),
            fraction: stats.businesses == 0
                ? 0
                : stats.verifiedBusinesses / stats.businesses,
          ),
        ),
      ],
    );
  }
}

/// The projects by status, as parts of all of them.
class _Projects extends StatelessWidget {
  const _Projects({required this.stats});

  final AdminDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.projects;
    AppDonutSlice slice(String key, int count) => AppDonutSlice(
      label: context.tr(key),
      value: count,
      valueLabel: _countAndShare(context, count, total),
    );
    return _ChartCard(
      title: context.tr('dashboard.admin.projects_chart'),
      child: AppDonutChart(
        centerValue: context.formatNumber(total),
        centerLabel: context.tr('dashboard.admin.projects'),
        // Slice order follows a project's life: the colors stay with the
        // status, whatever the numbers.
        slices: [
          slice('dashboard.admin.status_draft', stats.draftProjects),
          slice('dashboard.admin.status_open', stats.openProjects),
          slice('dashboard.admin.status_in_progress', stats.inProgressProjects),
          slice('dashboard.admin.status_completed', stats.completedProjects),
          slice('dashboard.admin.status_cancelled', stats.cancelledProjects),
        ],
      ),
    );
  }
}

/// The listed items, and the share of them on the market now.
class _Market extends StatelessWidget {
  const _Market({required this.stats});

  final AdminDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final listed = stats.marketItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminDashboardTileGrid(
          children: [
            AppStatTile(
              label: context.tr('dashboard.admin.market_items'),
              value: context.formatNumber(listed),
              icon: Icons.inventory_2_outlined,
            ),
            AppStatTile(
              label: context.tr('dashboard.admin.market_items_hidden'),
              value: context.formatNumber(listed - stats.liveMarketItems),
              icon: Icons.visibility_off_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: AppMeter(
            label: context.tr('dashboard.admin.market_items_live'),
            valueLabel: _countAndShare(context, stats.liveMarketItems, listed),
            fraction: listed == 0 ? 0 : stats.liveMarketItems / listed,
          ),
        ),
      ],
    );
  }
}
