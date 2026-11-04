import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/support_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/support/shared/presentation/bloc/support_reports_bloc.dart';
import 'package:watad/features/support/shared/presentation/widgets/support_report_card.dart';

/// «المساعدة والدعم» (GRA-63): my reports, newest first, and «بلاغ جديد».
class SupportReportsPage extends StatelessWidget {
  const SupportReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SupportReportsBloc>();
    void reload() => bloc.add(const SupportReportsFetched());
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('support.title'),
        onBack: () => context.pop(),
      ),
      body: BlocBuilder<SupportReportsBloc, SupportReportsState>(
        builder: (context, state) => switch (state) {
          SupportReportsInitial() ||
          SupportReportsLoadInProgress() => const AppLoadingIndicator(),
          SupportReportsLoadFailure(:final failure) => AppErrorView(
            message: context.tr(failure.messageKey),
            onRetry: reload,
          ),
          SupportReportsLoadSuccess(:final reports) when reports.isEmpty =>
            AppEmptyView(
              message: context.tr('support.empty'),
              icon: Icons.support_agent_outlined,
            ),
          SupportReportsLoadSuccess(:final reports) => RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView.separated(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              itemCount: reports.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => SupportReportCard(
                key: ValueKey(reports[index].id),
                report: reports[index],
              ),
            ),
          ),
        },
      ),
      bottomNavigationBar: AppActionBar(
        primary: AppButton(
          key: const Key('support_new_report'),
          label: context.tr('support.new_report'),
          icon: Icons.add_rounded,
          onPressed: () async {
            final sent = await context.pushNamed<bool>(
              SupportRoutes.supportNewReportName,
            );
            if (sent ?? false) reload();
          },
        ),
      ),
    );
  }
}
