import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/home/client/presentation/bloc/client_contractors_bloc.dart';
import 'package:watad/features/home/client/presentation/widgets/client_contractor_card.dart';
import 'package:watad/features/home/client/presentation/widgets/client_contractors_filters.dart';
import 'package:watad/features/home/client/presentation/widgets/client_contractors_skeleton.dart';

/// «المقاولون»: every verified contractor as cards, two per row, best rated
/// first, with filters. It opens from «الكل» on the home screen.
class ClientContractorsPage extends StatelessWidget {
  const ClientContractorsPage({super.key});

  /// Load the next page this close to the end of the list.
  static const double _loadMoreBefore = 400;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ClientContractorsBloc>();
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('home.contractors_title'),
        onBack: () => context.pop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: BlocBuilder<ClientContractorsBloc, ClientContractorsState>(
              buildWhen: (previous, current) =>
                  previous.filter != current.filter ||
                  previous.cities != current.cities,
              builder: (context, state) => ClientContractorsFilters(
                filter: state.filter,
                cities: state.cities,
                onChanged: (filter) =>
                    bloc.add(ClientContractorsFilterChanged(filter)),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ClientContractorsBloc, ClientContractorsState>(
              // Loading, the list and errors fade into each other.
              builder: (context, state) => AnimatedSwitcher(
                duration: AppMotion.enter,
                reverseDuration: AppMotion.exit,
                switchInCurve: AppMotion.enterCurve,
                switchOutCurve: AppMotion.exitCurve,
                child: _list(context, state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, ClientContractorsState state) {
    final bloc = context.read<ClientContractorsBloc>();
    switch (state.status) {
      case ClientContractorsStatus.initial || ClientContractorsStatus.loading:
        return const ClientContractorsSkeleton(key: ValueKey('loading'));
      case ClientContractorsStatus.failure:
        return AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(state.failure!.messageKey),
          onRetry: () => bloc.add(const ClientContractorsFetched()),
        );
      case ClientContractorsStatus.success when state.contractors.isEmpty:
        return AppEmptyView(
          key: const ValueKey('empty'),
          message: context.tr('home.no_matching_contractors'),
          icon: Icons.engineering_outlined,
        );
      case ClientContractorsStatus.success:
        final contractors = state.contractors;
        return NotificationListener<ScrollNotification>(
          key: const ValueKey('grid'),
          onNotification: (notification) {
            if (notification.metrics.extentAfter < _loadMoreBefore) {
              bloc.add(const ClientContractorsMoreRequested());
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async => bloc.add(const ClientContractorsFetched()),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  // Two cards per row.
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisExtent: ClientContractorCard.height,
                        ),
                    itemCount: contractors.length,
                    itemBuilder: (context, index) =>
                        ClientContractorCard(contractor: contractors[index]),
                  ),
                ),
                if (state.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        bottom: AppSpacing.md,
                      ),
                      child: AppLoadingIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        );
    }
  }
}
