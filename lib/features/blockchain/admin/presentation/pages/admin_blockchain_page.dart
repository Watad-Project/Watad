import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/admin_blockchain_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_filter.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_overall.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_overview.dart';
import 'package:watad/features/blockchain/admin/presentation/bloc/admin_blockchain_bloc.dart';
import 'package:watad/features/blockchain/admin/presentation/widgets/admin_blockchain_labels.dart';
import 'package:watad/features/blockchain/admin/presentation/widgets/admin_blockchain_ledger_section.dart';
import 'package:watad/features/blockchain/admin/presentation/widgets/admin_blockchain_project_card.dart';
import 'package:watad/features/blockchain/admin/presentation/widgets/admin_blockchain_skeleton.dart';
import 'package:watad/features/blockchain/admin/presentation/widgets/admin_blockchain_summary_section.dart';

/// «البلوك تشين» — the blockchain side of Watad: whether the ledger
/// answers, how the sync stands and every contracted project, those that
/// need attention first; a tap opens a project's sync. It is the admin's
/// «البلوك تشين» tab, and a page of its own at /admin/blockchain.
class AdminBlockchainPage extends StatelessWidget {
  const AdminBlockchainPage({this.isTab = false, this.bell, super.key});

  /// Shown as the admin's tab: no back arrow.
  final bool isTab;

  /// The notifications bell, lent by that feature (AppSlots.notificationsBell).
  final Widget? bell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('blockchain.admin.tab'),
        onBack: isTab ? null : () => context.pop(),
        actions: [?bell],
      ),
      body: BlocBuilder<AdminBlockchainBloc, AdminBlockchainState>(
        builder: (context, state) {
          final bloc = context.read<AdminBlockchainBloc>();
          return RefreshIndicator(
            onRefresh: () async => bloc.add(const AdminBlockchainFetched()),
            child: ListView(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              children: [
                // Loading, the monitor and errors fade into each other.
                AnimatedSwitcher(
                  duration: AppMotion.enter,
                  reverseDuration: AppMotion.exit,
                  switchInCurve: AppMotion.enterCurve,
                  switchOutCurve: AppMotion.exitCurve,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: AlignmentDirectional.topCenter,
                    children: [...previous, ?current],
                  ),
                  child: _body(context, bloc, state),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AdminBlockchainBloc bloc,
    AdminBlockchainState state,
  ) {
    final overview = state.overview;
    final overall = state.overall;
    if (overview == null || overall == null) {
      if (state.status == AdminBlockchainStatus.failure) {
        return AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(state.failure!.messageKey),
          onRetry: () => bloc.add(const AdminBlockchainFetched()),
        );
      }
      return const AdminBlockchainSkeleton(key: ValueKey('loading'));
    }
    return Column(
      key: const ValueKey('monitor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OverallCard(overall: overall, overview: overview, state: state),
        AppSectionHeader(
          title: context.tr('blockchain.admin.ledger'),
          padding: const EdgeInsetsDirectional.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.xs,
          ),
        ),
        AdminBlockchainLedgerSection(
          health: state.health,
          failure: state.healthFailure,
          isChecking:
              state.healthStatus == AdminBlockchainHealthStatus.checking,
          onCheck: () => bloc.add(const AdminBlockchainHealthChecked()),
        ),
        AdminBlockchainSummarySection(summary: overview.summary),
        AppSectionHeader(
          title: context.tr('blockchain.admin.projects'),
          padding: const EdgeInsetsDirectional.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.xs,
          ),
        ),
        if (overview.projects.isEmpty)
          AppEmptyView(
            message: context.tr('blockchain.admin.empty'),
            icon: Icons.link_off_rounded,
          )
        else
          _Projects(state: state, bloc: bloc),
      ],
    );
  }
}

/// Green when the ledger answers and nothing failed, orange while projects
/// wait or retry, red when the ledger doesn't answer or a project needs
/// attention.
class _OverallCard extends StatelessWidget {
  const _OverallCard({
    required this.overall,
    required this.overview,
    required this.state,
  });

  final AdminBlockchainOverall overall;
  final AdminBlockchainOverview overview;
  final AdminBlockchainState state;

  @override
  Widget build(BuildContext context) {
    final summary = overview.summary;
    final pending = summary.waiting + summary.retrying;
    final lines = [
      if (state.health?.isReachable == false)
        context.tr('blockchain.admin.ledger_down'),
      if (summary.failed > 0)
        context.tr(
          'blockchain.admin.attention_count',
          args: [context.formatNumber(summary.failed)],
        ),
      if (pending > 0)
        context.tr(
          'blockchain.admin.waiting_count',
          args: [context.formatNumber(pending)],
        ),
    ];
    return AppStatusCard(
      key: const Key('admin_blockchain_overall'),
      tone: AdminBlockchainLabels.overallTone(overall),
      title: context.tr(AdminBlockchainLabels.overallKey(overall)),
      subtitle: lines.isEmpty
          ? null
          : lines.reduce(
              (a, b) => context.tr('blockchain.admin.meta_join', args: [a, b]),
            ),
    );
  }
}

/// The chips with their counts, then the projects of the selected one.
class _Projects extends StatelessWidget {
  const _Projects({required this.state, required this.bloc});

  final AdminBlockchainState state;
  final AdminBlockchainBloc bloc;

  @override
  Widget build(BuildContext context) {
    final visible = state.visibleProjects;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFilterChips(
          key: const Key('admin_blockchain_filter'),
          // All five in view, on two lines when they don't fit on one.
          isWrapped: true,
          labels: [
            for (final filter in AdminBlockchainFilter.values)
              '${context.tr(AdminBlockchainLabels.filterKey(filter))} '
                  '${context.formatNumber(state.countOf(filter))}',
          ],
          selectedIndex: state.filter.index,
          onSelected: (index) => bloc.add(
            AdminBlockchainFilterChanged(AdminBlockchainFilter.values[index]),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (visible.isEmpty)
          AppEmptyView(
            message: context.tr('blockchain.admin.empty_filter'),
            icon: Icons.link_rounded,
          )
        else
          for (final project in visible) ...[
            AdminBlockchainProjectCard(
              project: project,
              onTap: () async {
                await context.pushNamed(
                  AdminBlockchainRoutes.blockchainProjectName,
                  pathParameters: {'projectId': project.projectId},
                );
                // A resync there shows here too.
                bloc.add(const AdminBlockchainFetched());
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}
