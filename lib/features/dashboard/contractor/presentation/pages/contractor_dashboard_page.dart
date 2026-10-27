import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/router/routes/contractor_navigation_routes.dart';
import 'package:watad/core/router/routes/contractor_tasks_routes.dart';
import 'package:watad/core/router/routes/kyc_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/dashboard/contractor/presentation/bloc/contractor_dashboard_bloc.dart';
import 'package:watad/features/dashboard/contractor/presentation/widgets/contractor_dashboard_active_projects.dart';
import 'package:watad/features/dashboard/contractor/presentation/widgets/contractor_dashboard_earnings_card.dart';
import 'package:watad/features/dashboard/contractor/presentation/widgets/contractor_dashboard_header.dart';
import 'package:watad/features/dashboard/contractor/presentation/widgets/contractor_dashboard_offers.dart';
import 'package:watad/features/dashboard/contractor/presentation/widgets/contractor_dashboard_opportunities_banner.dart';

class ContractorDashboardPage extends StatelessWidget {
  const ContractorDashboardPage({
    super.key,
    this.onVerificationStatusTap,
    this.onBrowseOpportunities,
    this.onAllProjectsTap,
    this.onAllOffersTap,
    this.onProjectTap,
    this.onOfferTap,
    this.bell,
  });

  final VoidCallback? onVerificationStatusTap;
  final VoidCallback? onBrowseOpportunities;
  final VoidCallback? onAllProjectsTap;
  final VoidCallback? onAllOffersTap;
  final ValueChanged<String>? onProjectTap;
  final ValueChanged<String>? onOfferTap;

  /// The notifications bell, for the header.
  final Widget? bell;

  Future<void> _openProjectSchedule(
    BuildContext context,
    String projectId,
  ) async {
    await context.pushNamed<void>(
      ContractorTasksRoutes.projectTasksName,
      pathParameters: {'projectId': projectId},
    );
    if (context.mounted) {
      context.read<ContractorDashboardBloc>().add(
        const ContractorDashboardRefreshed(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocBuilder<ContractorDashboardBloc, ContractorDashboardState>(
          builder: (context, state) {
            return switch (state) {
              ContractorDashboardInitial() ||
              ContractorDashboardLoadInProgress() => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              ContractorDashboardLoadFailure(:final failure) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr(failure.messageKey),
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: 140,
                        child: AppButton(
                          label: context.tr('common.retry'),
                          onPressed: () => context
                              .read<ContractorDashboardBloc>()
                              .add(const ContractorDashboardFetched()),
                          variant: AppButtonVariant.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ContractorDashboardLoadSuccess(:final data) => RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  final bloc = context.read<ContractorDashboardBloc>();
                  bloc.add(const ContractorDashboardRefreshed());
                  await bloc.stream.firstWhere(
                    (s) => s is! ContractorDashboardLoadInProgress,
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ContractorDashboardHeader(
                        profile: data.profile,
                        bell: bell,
                        onVerificationStatusTap:
                            onVerificationStatusTap ??
                            () => context.pushNamed(KycRoutes.statusName),
                      ),
                      ContractorDashboardEarningsCard(earnings: data.earnings),
                      const SizedBox(height: AppSpacing.sm),
                      ContractorDashboardOpportunitiesBanner(
                        opportunitiesCount: data.opportunitiesCount,
                        onBrowse:
                            onBrowseOpportunities ??
                            () => context.goNamed(
                              ContractorNavigationRoutes.navigationName,
                              queryParameters: {'tab': 'contractor-work'},
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ContractorDashboardActiveProjects(
                        projects: data.activeProjects,
                        onAllProjectsTap:
                            onAllProjectsTap ??
                            () => context.goNamed(
                              ContractorNavigationRoutes.navigationName,
                              queryParameters: {'tab': 'contractor-work'},
                            ),
                        onProjectTap:
                            onProjectTap ??
                            (projectId) =>
                                _openProjectSchedule(context, projectId),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ContractorDashboardOffers(
                        offers: data.myOffers,
                        onAllOffersTap:
                            onAllOffersTap ??
                            () => context.goNamed(
                              ContractorNavigationRoutes.navigationName,
                              queryParameters: {'tab': 'contractor-work'},
                            ),
                        onOfferTap: onOfferTap,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            };
          },
        ),
      ),
    );
  }
}
