import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/presentation/bloc/admin_report_details_bloc.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_report_close_form.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_report_labels.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_report_overview.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_reports_skeleton.dart';

/// «تفاصيل البلاغ»: one ticket, and what an admin does on it: take it,
/// act on the reported listing or user, and close it with an answer. A
/// closed ticket is read-only.
class AdminReportDetailsPage extends StatelessWidget {
  const AdminReportDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('reports.details_title'),
        onBack: () => context.pop(),
      ),
      body: BlocConsumer<AdminReportDetailsBloc, AdminReportDetailsState>(
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
        // Loading, the ticket and errors fade into each other.
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

  Widget _body(BuildContext context, AdminReportDetailsState state) {
    final bloc = context.read<AdminReportDetailsBloc>();
    final report = state.report;
    if (report == null) {
      return switch (state.failure) {
        NotFoundFailure() => AppEmptyView(
          key: const ValueKey('not_found'),
          message: context.tr('reports.not_found'),
          icon: Icons.search_off_rounded,
        ),
        final failure? => AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(failure.messageKey),
          onRetry: () {
            if (state.reportId case final id?) {
              bloc.add(AdminReportDetailsFetched(id));
            }
          },
        ),
        null => const Padding(
          key: ValueKey('loading'),
          padding: EdgeInsetsDirectional.all(AppSpacing.md),
          child: AdminReportsSkeleton(),
        ),
      };
    }
    return ListView(
      key: const ValueKey('report'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        AdminReportOverview(report: report),
        const SizedBox(height: AppSpacing.lg),
        if (report.isClosed)
          AppStatusCard(
            tone: AdminReportLabels.statusTone(report.status),
            title: context.tr(AdminReportLabels.statusKey(report.status)),
            subtitle: context.tr('reports.read_only'),
            reasonTitle: context.tr('reports.note_label'),
            reasonText: report.resolutionNote,
          )
        else
          _Actions(report: report, isBusy: state.isBusy, bloc: bloc),
      ],
    );
  }
}

/// What an admin can still do on an open or in-review ticket.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.report,
    required this.isBusy,
    required this.bloc,
  });

  final AdminReport report;
  final bool isBusy;
  final AdminReportDetailsBloc bloc;

  @override
  Widget build(BuildContext context) {
    final listingId = report.listingId;
    final userId = report.targetUserId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!report.isAssignedToMe) ...[
          AppButton(
            label: context.tr('reports.assign'),
            variant: AppButtonVariant.secondary,
            onPressed: isBusy
                ? null
                : () => bloc.add(const AdminReportDetailsAssigned()),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (listingId != null) ...[
          AppButton(
            label: context.tr('reports.remove_listing'),
            variant: AppButtonVariant.secondary,
            onPressed: isBusy ? null : () => _removeListing(context, listingId),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (userId != null) ...[
          AppButton(
            label: context.tr('reports.suspend_user'),
            variant: AppButtonVariant.secondary,
            onPressed: isBusy ? null : () => _suspendUser(context, userId),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppSectionHeader(
          title: context.tr('reports.close_section'),
          padding: const EdgeInsetsDirectional.only(
            top: AppSpacing.md,
            bottom: AppSpacing.xs,
          ),
        ),
        AdminReportCloseForm(
          isBusy: isBusy,
          onSubmit: (status, note) =>
              bloc.add(AdminReportDetailsClosed(status: status, note: note)),
        ),
      ],
    );
  }

  Future<void> _removeListing(BuildContext context, String itemId) async {
    final reason = await AppConfirmDialog.show(
      context,
      title: context.tr('reports.remove_title'),
      message: context.tr('reports.remove_message'),
      confirmLabel: context.tr('reports.remove_listing'),
      reasonLabel: context.tr('common.reason'),
    );
    if (reason == null) return;
    bloc.add(AdminReportDetailsListingRemoved(itemId: itemId, reason: reason));
  }

  Future<void> _suspendUser(BuildContext context, String userId) async {
    final reason = await AppConfirmDialog.show(
      context,
      title: context.tr('reports.suspend_title'),
      message: context.tr('reports.suspend_message'),
      confirmLabel: context.tr('reports.suspend_user'),
      reasonLabel: context.tr('common.reason'),
    );
    if (reason == null) return;
    bloc.add(AdminReportDetailsUserSuspended(userId: userId, reason: reason));
  }
}
