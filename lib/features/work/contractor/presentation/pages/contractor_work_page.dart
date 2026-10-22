import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/buttons/app_icon_button.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/inputs/app_segmented_tabs.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/router/routes/contractor_work_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_filter.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_overview.dart';
import 'package:watad/features/work/contractor/presentation/bloc/contractor_work_bloc.dart';
import 'package:watad/features/work/contractor/presentation/widgets/contractor_contract_card.dart';
import 'package:watad/features/work/contractor/presentation/widgets/contractor_open_project_card.dart';
import 'package:watad/features/work/contractor/presentation/widgets/contractor_work_filter_sheet.dart';

class ContractorWorkPage extends StatefulWidget {
  const ContractorWorkPage({
    this.onSubmitOffer,
    this.onPendingOfferTap,
    this.onContractTap,
    super.key,
  });

  final ValueChanged<ContractorOpenProject>? onSubmitOffer;
  final ValueChanged<ContractorOpenProject>? onPendingOfferTap;
  final ValueChanged<ContractorContractProject>? onContractTap;

  @override
  State<ContractorWorkPage> createState() => _ContractorWorkPageState();
}

class _ContractorWorkPageState extends State<ContractorWorkPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  Future<void> _openFilterSheet(
    BuildContext context,
    ContractorWorkFilter currentFilter,
  ) async {
    final updatedFilter = await ContractorWorkFilterSheet.show(
      context,
      initialFilter: currentFilter,
    );
    if (updatedFilter != null && context.mounted) {
      context.read<ContractorWorkBloc>().add(
        ContractorWorkFilterUpdated(updatedFilter),
      );
    }
  }

  void _resetSearchAndFilter(BuildContext context) {
    _searchController.clear();
    context.read<ContractorWorkBloc>().add(const ContractorWorkFilterReset());
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
                :final filter,
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
                    filter: filter,
                    searchController: _searchController,
                    onSearchChanged: (query) => context
                        .read<ContractorWorkBloc>()
                        .add(ContractorWorkSearchQueryChanged(query)),
                    onOpenFilterSheet: () => _openFilterSheet(context, filter),
                    onResetFilter: () => _resetSearchAndFilter(context),
                    onSubmitOffer:
                        widget.onSubmitOffer ??
                        (project) => _openBidScreen(context, project),
                    onPendingOfferTap:
                        widget.onPendingOfferTap ??
                        (project) => _openBidScreen(context, project),
                    onContractTap: widget.onContractTap,
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
    required this.filter,
    required this.searchController,
    required this.onSearchChanged,
    required this.onOpenFilterSheet,
    required this.onResetFilter,
    this.onSubmitOffer,
    this.onPendingOfferTap,
    this.onContractTap,
  });

  final ContractorWorkOverview overview;
  final int selectedTabIndex;
  final int selectedContractFilterIndex;
  final List<ContractorContractProject> filteredContracts;
  final ContractorWorkFilter filter;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilterSheet;
  final VoidCallback onResetFilter;
  final ValueChanged<ContractorOpenProject>? onSubmitOffer;
  final ValueChanged<ContractorOpenProject>? onPendingOfferTap;
  final ValueChanged<ContractorContractProject>? onContractTap;

  int get _projectTypeChipIndex => switch (filter.projectType) {
    null => 0,
    ContractorWorkType.foundation => 1,
    ContractorWorkType.building => 2,
    ContractorWorkType.renovation => 3,
    ContractorWorkType.repairs => 4,
  };

  void _onProjectTypeSelected(BuildContext context, int index) {
    final selectedType = switch (index) {
      1 => ContractorWorkType.foundation,
      2 => ContractorWorkType.building,
      3 => ContractorWorkType.renovation,
      4 => ContractorWorkType.repairs,
      _ => null,
    };
    context.read<ContractorWorkBloc>().add(
      ContractorWorkFilterUpdated(
        filter.copyWith(
          projectType: selectedType,
          clearProjectType: selectedType == null,
        ),
      ),
    );
  }

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
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: searchController,
                  hint: context.tr('work.contractor.search_hint'),
                  textInputAction: TextInputAction.search,
                  onChanged: onSearchChanged,
                  onSubmitted: onSearchChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppIconButton(
                icon: Icons.tune,
                variant: AppIconButtonVariant.filled,
                tooltip: context.tr('work.contractor.filter_title'),
                onPressed: onOpenFilterSheet,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppFilterChips(
            labels: [
              context.tr('work.contractor.filter_type_all'),
              context.tr('work.contractor.filter_type_foundation'),
              context.tr('work.contractor.filter_type_building'),
              context.tr('work.contractor.filter_type_renovation'),
              context.tr('work.contractor.filter_type_repairs'),
            ],
            selectedIndex: _projectTypeChipIndex,
            onSelected: (index) => _onProjectTypeSelected(context, index),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('work.contractor.deed_hint'),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (overview.openProjects.isEmpty) ...[
            AppEmptyView(
              message: context.tr('work.contractor.empty_opportunities'),
              icon: Icons.work_outline,
            ),
            if (filter.hasActiveFilters ||
                filter.searchQuery.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: context.tr('work.contractor.filter_reset_button'),
                variant: AppButtonVariant.secondary,
                onPressed: onResetFilter,
              ),
            ],
          ] else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: overview.openProjects.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                mainAxisExtent:
                    320 *
                    MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.4),
              ),
              itemBuilder: (context, index) {
                final project = overview.openProjects[index];
                return ContractorOpenProjectCard(
                  project: project,
                  onSubmitOfferTap: () => onSubmitOffer?.call(project),
                  onPendingOfferTap: () => onPendingOfferTap?.call(project),
                );
              },
            ),
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
