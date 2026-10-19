import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/components/display/app_logo.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_closure.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_decision.dart';
import 'package:watad/features/reports/admin/presentation/bloc/admin_reports_bloc.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_report_card.dart';

/// «الإدارة» — the reports users sent, newest first, and the actions on
/// them.
class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<AdminReportsBloc, AdminReportsState>(
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
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppLogo(height: 48),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(context.tr('reports.title'), style: AppTextStyles.h1),
                  const SizedBox(height: AppSpacing.md),
                  ..._body(context, bloc, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AdminReportsBloc bloc,
    AdminReportsState state,
  ) {
    if (state.reports.isEmpty) {
      return [
        switch (state.status) {
          AdminReportsStatus.failure => AppErrorView(
            message: context.tr(state.failure!.messageKey),
            onRetry: () => bloc.add(const AdminReportsFetched()),
          ),
          AdminReportsStatus.success => AppEmptyView(
            message: context.tr('reports.empty'),
            icon: Icons.flag_outlined,
          ),
          _ => const AppLoadingIndicator(),
        },
      ];
    }
    final now = DateTime.now();
    return [
      for (final report in state.reports) ...[
        AdminReportCard(
          report: report,
          now: now,
          isBusy: state.busyReportId == report.id,
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
          onClose: () => bloc.add(
            AdminReportClosed(
              AdminReportClosure(
                reportId: report.id,
                status: ReportStatus.resolved,
              ),
            ),
          ),
          onDismiss: () => bloc.add(
            AdminReportClosed(
              AdminReportClosure(
                reportId: report.id,
                status: ReportStatus.dismissed,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    ];
  }
}
