import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/admin_marketplace_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_filter.dart';
import 'package:watad/features/marketplace/admin/presentation/bloc/admin_marketplace_bloc.dart';
import 'package:watad/features/marketplace/admin/presentation/widgets/admin_marketplace_item_tile.dart';
import 'package:watad/features/marketplace/admin/presentation/widgets/admin_marketplace_skeleton.dart';

/// «منتجات السوق»: every listing, newest first, hidden and removed ones
/// included, searched by item or seller name and narrowed by chips with
/// their counts. A page loads as the list reaches its end; a tap opens the
/// listing.
class AdminMarketplacePage extends StatelessWidget {
  const AdminMarketplacePage({super.key});

  static String _filterKey(AdminMarketplaceFilter filter) => switch (filter) {
    AdminMarketplaceFilter.all => 'marketplace.filter_all',
    AdminMarketplaceFilter.live => 'marketplace.filter_live',
    AdminMarketplaceFilter.hidden => 'marketplace.filter_hidden',
    AdminMarketplaceFilter.removed => 'marketplace.filter_removed',
    AdminMarketplaceFilter.outOfStock => 'marketplace.filter_out_of_stock',
  };

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AdminMarketplaceBloc>();
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('marketplace.title'),
        onBack: () => context.pop(),
      ),
      body: BlocBuilder<AdminMarketplaceBloc, AdminMarketplaceState>(
        builder: (context, state) => NotificationListener<ScrollNotification>(
          // Near the end of the list: the next page.
          onNotification: (notification) {
            final metrics = notification.metrics;
            if (metrics.axis == Axis.vertical && metrics.extentAfter < 400) {
              bloc.add(const AdminMarketplaceMoreRequested());
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async => bloc.add(const AdminMarketplaceFetched()),
            child: ListView(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              children: [
                AppTextField(
                  key: const Key('admin_marketplace_search'),
                  hint: context.tr('marketplace.search_hint'),
                  textInputAction: TextInputAction.search,
                  onChanged: (text) =>
                      bloc.add(AdminMarketplaceSearchChanged(text)),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppFilterChips(
                  key: const Key('admin_marketplace_filter'),
                  isWrapped: true,
                  labels: [
                    for (final filter in AdminMarketplaceFilter.values)
                      switch (state.counts) {
                        final counts? =>
                          '${context.tr(_filterKey(filter))} '
                              '${context.formatNumber(counts.of(filter))}',
                        null => context.tr(_filterKey(filter)),
                      },
                  ],
                  selectedIndex: state.filter.index,
                  onSelected: (index) => bloc.add(
                    AdminMarketplaceFilterChanged(
                      AdminMarketplaceFilter.values[index],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ..._body(context, bloc, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AdminMarketplaceBloc bloc,
    AdminMarketplaceState state,
  ) {
    if (state.items.isEmpty) {
      return [
        switch (state.status) {
          AdminMarketplaceStatus.failure => AppErrorView(
            message: context.tr(state.failure!.messageKey),
            onRetry: () => bloc.add(const AdminMarketplaceFetched()),
          ),
          AdminMarketplaceStatus.success => AppEmptyView(
            message: context.tr(
              state.search.isEmpty
                  ? 'marketplace.empty'
                  : 'marketplace.empty_search',
            ),
            icon: Icons.storefront_outlined,
          ),
          _ => const AdminMarketplaceSkeleton(),
        },
      ];
    }
    return [
      for (final item in state.items) ...[
        AdminMarketplaceItemTile(
          key: ValueKey(item.id),
          item: item,
          onTap: () async {
            await context.pushNamed(
              AdminMarketplaceRoutes.marketplaceItemName,
              pathParameters: {'itemId': item.id},
            );
            // What the admin did there shows here too.
            bloc.add(const AdminMarketplaceFetched());
          },
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (state.isLoadingMore)
        const Padding(
          padding: EdgeInsetsDirectional.all(AppSpacing.md),
          child: AppLoadingIndicator(),
        ),
    ];
  }
}
