import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/core/router/routes/profile_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/marketplace/shared/domain/entities/my_orders.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_sales_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_order_labels.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_order_tile.dart';

/// «مبيعاتي» (`/marketplace/sales`, GRA-71): the orders I received as a
/// seller, newest first, with a chip per status and how many it holds.
class MarketplaceSalesPage extends StatelessWidget {
  const MarketplaceSalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MarketplaceSalesBloc>();
    return BlocListener<MarketplaceSalesBloc, MarketplaceSalesState>(
      listenWhen: (previous, current) =>
          current.refreshFailure != null &&
          previous.refreshFailure != current.refreshFailure,
      listener: (context, state) => context.showErrorSnackBar(
        context.tr(state.refreshFailure!.messageKey),
      ),
      child: Scaffold(
        appBar: AppTopBar(
          title: context.tr('marketplace.my_sales.title'),
          onBack: () => context.pop(),
        ),
        body: BlocBuilder<MarketplaceSalesBloc, MarketplaceSalesState>(
          builder: (context, state) {
            if (!state.hasLoaded) {
              return switch (state.status) {
                MarketplaceSalesStatus.failure => AppErrorView(
                  message: context.tr(state.failure!.messageKey),
                  onRetry: () => bloc.add(const MarketplaceSalesFetched()),
                ),
                _ => const AppLoadingIndicator(),
              };
            }
            if (state.orders.isEmpty) return const _NoSales();
            return RefreshIndicator(
              onRefresh: () async => bloc.add(const MarketplaceSalesFetched()),
              child: _SalesList(state: state, bloc: bloc),
            );
          },
        ),
      ),
    );
  }
}

class _SalesList extends StatelessWidget {
  const _SalesList({required this.state, required this.bloc});

  final MarketplaceSalesState state;
  final MarketplaceSalesBloc bloc;

  @override
  Widget build(BuildContext context) {
    final orders = state.orders;
    final shown = orders.of(state.filter);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.md),
      children: [
        AppFilterChips(
          key: const Key('sales_filters'),
          labels: [
            for (final status in MyOrders.filters)
              context.tr(
                'marketplace.my_orders.filter',
                args: [
                  if (status == null)
                    context.tr('marketplace.my_orders.all')
                  else
                    MarketplaceOrderLabels.status(context, status),
                  context.formatNumber(orders.countOf(status)),
                ],
              ),
          ],
          selectedIndex: MyOrders.filters.indexOf(state.filter),
          onSelected: (index) =>
              bloc.add(MarketplaceSalesFilterSelected(MyOrders.filters[index])),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: AppEmptyView(
              key: const Key('sales_filter_empty'),
              message: context.tr('marketplace.my_sales.empty_filter'),
              icon: Icons.filter_list_off,
            ),
          ),
        for (final order in shown)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: MarketplaceOrderTile(
              order: order,
              onPartyTap: () => context.pushNamed(
                ProfileRoutes.publicProfileName,
                pathParameters: {'userId': order.buyerId},
              ),
              onTap: () async {
                await context.pushNamed(
                  MarketplaceRoutes.marketplaceOrderDetailsName,
                  pathParameters: {'orderId': order.id},
                );
                bloc.add(const MarketplaceSalesFetched());
              },
            ),
          ),
      ],
    );
  }
}

/// No sales yet, and the way to my items.
class _NoSales extends StatelessWidget {
  const _NoSales();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        AppEmptyView(
          key: const Key('sales_empty'),
          message: context.tr('marketplace.my_sales.empty'),
          icon: Icons.sell_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          key: const Key('sales_my_items'),
          label: context.tr('marketplace.my_sales.my_items'),
          onPressed: () => context.pushNamed(MarketplaceRoutes.myItemsName),
        ),
      ],
    );
  }
}
