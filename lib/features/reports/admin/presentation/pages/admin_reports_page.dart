import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/inputs/app_segmented_tabs.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/admin_reports_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_closure.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_decision.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_reports_status_filter.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_reports_type_filter.dart';
import 'package:watad/features/reports/admin/presentation/bloc/admin_reports_bloc.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_report_card.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_reports_skeleton.dart';

/// «البلاغات» — every ticket users sent, filtered by status and type, with
/// quick actions; a tap opens a ticket's details. The admin dashboard opens
/// it.
class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('reports.tab'),
        onBack: () => context.pop(),
      ),
      body: BlocConsumer<AdminReportsBloc, AdminReportsState>(
        listenWhen: (previous, current) =>
            current.message != null && previous.message != current.message,
        listener: (context, state) {
          final message = state.message!;
          if (message.isError) {
            context.showErrorSnackBar(context.tr(message.key));
          } else {
            context.showSuccessSnackBar(context.tr(message.key));
          }
        },
        builder: (context, state) {
          final bloc = context.read<AdminReportsBloc>();
          return RefreshIndicator(
            onRefresh: () async => bloc.add(const AdminReportsFetched()),
            child: ListView(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              children: [
                if (state.reports.isNotEmpty) ...[
                  _Filters(state: state, bloc: bloc),
                  const SizedBox(height: AppSpacing.md),
                ],
                // Loading, the tickets and errors fade into each other.
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
    AdminReportsBloc bloc,
    AdminReportsState state,
  ) {
    if (state.reports.isEmpty) {
      return switch (state.status) {
        AdminReportsStatus.failure => AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(state.failure!.messageKey),
          onRetry: () => bloc.add(const AdminReportsFetched()),
        ),
        AdminReportsStatus.success => AppEmptyView(
          key: const ValueKey('empty'),
          message: context.tr('reports.empty'),
          icon: Icons.flag_outlined,
        ),
        _ => const AdminReportsSkeleton(key: ValueKey('loading')),
      };
    }
    final visible = state.visibleReports;
    if (visible.isEmpty) {
      return AppEmptyView(
        key: ValueKey('empty ${state.statusFilter} ${state.typeFilter}'),
        message: context.tr('reports.empty_filter'),
        icon: Icons.flag_outlined,
      );
    }
    final now = DateTime.now();
    return Column(
      key: ValueKey('reports ${state.statusFilter} ${state.typeFilter}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final report in visible) ...[
          AdminReportCard(
            report: report,
            now: now,
            isBusy: state.busyReportId == report.id,
            onTap: () async {
              await context.pushNamed(
                AdminReportsRoutes.reportDetailsName,
                pathParameters: {'reportId': report.id},
              );
              // What the admin did there shows here too.
              bloc.add(const AdminReportsFetched());
            },
            onAssign: () => bloc.add(AdminReportAssigned(report.id)),
            onRemoveListing: (itemId) async {
              final reason = await AppConfirmDialog.show(
                context,
                title: context.tr('reports.remove_title'),
                message: context.tr('reports.remove_message'),
                confirmLabel: context.tr('reports.remove_listing'),
                reasonLabel: context.tr('common.reason'),
              );
              if (reason == null) return;
              bloc.add(
                AdminReportListingRemoved(
                  AdminReportDecision(
                    reportId: report.id,
                    subjectId: itemId,
                    reason: reason,
                  ),
                ),
              );
            },
            onSuspendUser: (userId) async {
              final reason = await AppConfirmDialog.show(
                context,
                title: context.tr('reports.suspend_title'),
                message: context.tr('reports.suspend_message'),
                confirmLabel: context.tr('reports.suspend_user'),
                reasonLabel: context.tr('common.reason'),
              );
              if (reason == null) return;
              bloc.add(
                AdminReportUserSuspended(
                  AdminReportDecision(
                    reportId: report.id,
                    subjectId: userId,
                    reason: reason,
                  ),
                ),
              );
            },
            onClose: () => _close(context, bloc, report, ReportStatus.resolved),
            onDismiss: () =>
                _close(context, bloc, report, ReportStatus.dismissed),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  /// Asks for the answer the user reads, then closes the ticket.
  Future<void> _close(
    BuildContext context,
    AdminReportsBloc bloc,
    AdminReport report,
    ReportStatus status,
  ) async {
    final isDismissed = status == ReportStatus.dismissed;
    final note = await AppConfirmDialog.show(
      context,
      title: context.tr(
        isDismissed ? 'reports.dismiss_title' : 'reports.close_title',
      ),
      message: context.tr('reports.note_hint'),
      confirmLabel: context.tr(
        isDismissed ? 'reports.dismiss' : 'reports.close',
      ),
      reasonLabel: context.tr('reports.note_label'),
    );
    if (note == null) return;
    bloc.add(
      AdminReportClosed(
        AdminReportClosure(reportId: report.id, status: status, note: note),
      ),
    );
  }
}

/// The status chips, each with its count, and the type tabs.
class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.bloc});

  final AdminReportsState state;
  final AdminReportsBloc bloc;

  static String _statusKey(AdminReportsStatusFilter filter) => switch (filter) {
    AdminReportsStatusFilter.open => 'reports.filter_open',
    AdminReportsStatusFilter.inReview => 'reports.filter_in_review',
    AdminReportsStatusFilter.assignedToMe => 'reports.filter_mine',
    AdminReportsStatusFilter.closed => 'reports.filter_closed',
  };

  static String _typeKey(AdminReportsTypeFilter filter) => switch (filter) {
    AdminReportsTypeFilter.all => 'reports.type_all',
    AdminReportsTypeFilter.support => 'reports.type_support',
    AdminReportsTypeFilter.moderation => 'reports.type_moderation',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSegmentedTabs(
          key: const Key('admin_reports_type'),
          labels: [
            for (final filter in AdminReportsTypeFilter.values)
              context.tr(_typeKey(filter)),
          ],
          selectedIndex: state.typeFilter.index,
          onChanged: (index) => bloc.add(
            AdminReportsTypeFilterChanged(AdminReportsTypeFilter.values[index]),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppFilterChips(
          key: const Key('admin_reports_status'),
          labels: [
            for (final filter in AdminReportsStatusFilter.values)
              '${context.tr(_statusKey(filter))} '
                  '${context.formatNumber(state.countOf(filter))}',
          ],
          selectedIndex: state.statusFilter.index,
          onSelected: (index) => bloc.add(
            AdminReportsStatusFilterChanged(
              AdminReportsStatusFilter.values[index],
            ),
          ),
        ),
      ],
    );
  }
}
