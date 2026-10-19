import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/inputs/app_segmented_tabs.dart';
import 'package:watad/core/router/routes/contractor_work_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_overview.dart';
import 'package:watad/features/work/contractor/presentation/bloc/contractor_work_bloc.dart';
import 'package:watad/features/work/contractor/presentation/widgets/contractor_contract_card.dart';
import 'package:watad/features/work/contractor/presentation/widgets/contractor_open_project_card.dart';

class ContractorWorkPage extends StatelessWidget {
  const ContractorWorkPage({
    this.onSubmitOffer,
    this.onPendingOfferTap,
    this.onContractTap,
    super.key,
  });

  final ValueChanged<ContractorOpenProject>? onSubmitOffer;
  final ValueChanged<ContractorOpenProject>? onPendingOfferTap;
  final ValueChanged<ContractorContractProject>? onContractTap;

  Future<void> _openBidScreen(
    BuildContext context,
    ContractorOpenProject project,
  ) async {
    final changed = await context.pushNamed<bool>(
      ContractorWorkRoutes.bidName,
      pathParameters: {'projectId': project.id},
    );
    if ((changed ?? false) && context.mounted) {
      context.read<ContractorWorkBloc>().add(const ContractorWorkRefreshed());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocBuilder<ContractorWorkBloc, ContractorWorkState>(
          builder: (context, state) {
            return switch (state) {
              ContractorWorkInitial() ||
              ContractorWorkLoadInProgress() => const AppLoadingIndicator(),
              ContractorWorkLoadFailure(:final failure) => AppErrorView(
                message: context.tr(failure.messageKey),
                onRetry: () => context.read<ContractorWorkBloc>().add(
                  const ContractorWorkStarted(),
                ),
              ),
              ContractorWorkLoadSuccess(
                :final overview,
                :final selectedTabIndex,
                :final selectedContractFilterIndex,
                :final filteredContracts,
              ) =>
                RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    final bloc = context.read<ContractorWorkBloc>();
                    bloc.add(const ContractorWorkRefreshed());
                    await bloc.stream.firstWhere(
                      (s) => s is! ContractorWorkLoadInProgress,
                    );
                  },
                  child: _WorkContent(
                    overview: overview,
                    selectedTabIndex: selectedTabIndex,
                    selectedContractFilterIndex: selectedContractFilterIndex,
                    filteredContracts: filteredContracts,
                    onSubmitOffer:
                        onSubmitOffer ??
                        (project) => _openBidScreen(context, project),
                    onPendingOfferTap:
                        onPendingOfferTap ??
                        (project) => _openBidScreen(context, project),
                    onContractTap: onContractTap,
                  ),
                ),
            };
          },
        ),
      ),
    );
  }
}

class _WorkContent extends StatelessWidget {
  const _WorkContent({
    required this.overview,
    required this.selectedTabIndex,
    required this.selectedContractFilterIndex,
    required this.filteredContracts,
    this.onSubmitOffer,
    this.onPendingOfferTap,
    this.onContractTap,
  });

  final ContractorWorkOverview overview;
  final int selectedTabIndex;
  final int selectedContractFilterIndex;
  final List<ContractorContractProject> filteredContracts;
  final ValueChanged<ContractorOpenProject>? onSubmitOffer;
  final ValueChanged<ContractorOpenProject>? onPendingOfferTap;
  final ValueChanged<ContractorContractProject>? onContractTap;

  @override
  Widget build(BuildContext context) {
    final opportunitiesTabLabel = context.tr(
      'work.contractor.new_opportunities_tab',
      namedArgs: {'count': '${overview.opportunitiesCount}'},
    );
    final contractsTabLabel = context.tr(
      'work.contractor.my_contracts_tab',
      namedArgs: {'count': '${overview.contractsCount}'},
    );

    final inProgressFilterLabel = context.tr(
      'work.contractor.contracts_filter_in_progress',
      namedArgs: {'count': '${overview.inProgressContractsCount}'},
    );
    final completedFilterLabel = context.tr(
      'work.contractor.contracts_filter_completed',
      namedArgs: {'count': '${overview.completedContractsCount}'},
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        Text(context.tr('work.contractor.title'), style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.md),
        AppSegmentedTabs(
          labels: [opportunitiesTabLabel, contractsTabLabel],
          selectedIndex: selectedTabIndex,
          onChanged: (index) => context.read<ContractorWorkBloc>().add(
            ContractorWorkTabChanged(index),
          ),
        ),
        if (selectedTabIndex == 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('work.contractor.deed_hint'),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (overview.openProjects.isEmpty)
            AppEmptyView(
              message: context.tr('work.contractor.empty_opportunities'),
              icon: Icons.work_outline,
            )
          else
            for (
              var index = 0;
              index < overview.openProjects.length;
              index++
            ) ...[
              if (index > 0) const SizedBox(height: AppSpacing.md),
              ContractorOpenProjectCard(
                project: overview.openProjects[index],
                onSubmitOfferTap: () =>
                    onSubmitOffer?.call(overview.openProjects[index]),
                onPendingOfferTap: () =>
                    onPendingOfferTap?.call(overview.openProjects[index]),
              ),
            ],
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          AppFilterChips(
            labels: [inProgressFilterLabel, completedFilterLabel],
            selectedIndex: selectedContractFilterIndex,
            onSelected: (index) => context.read<ContractorWorkBloc>().add(
              ContractorWorkContractFilterChanged(index),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (filteredContracts.isEmpty) ...[
            AppEmptyView(
              message: context.tr('work.contractor.empty_contracts'),
              icon: Icons.assignment_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: context.tr('work.contractor.browse_opportunities_action'),
              variant: AppButtonVariant.secondary,
              onPressed: () => context.read<ContractorWorkBloc>().add(
                const ContractorWorkTabChanged(0),
              ),
            ),
          ] else
            for (var index = 0; index < filteredContracts.length; index++) ...[
              if (index > 0) const SizedBox(height: AppSpacing.md),
              ContractorContractCard(
                contract: filteredContracts[index],
                onTap: onContractTap != null
                    ? () => onContractTap!(filteredContracts[index])
                    : null,
              ),
            ],
        ],
      ],
    );
  }
}
