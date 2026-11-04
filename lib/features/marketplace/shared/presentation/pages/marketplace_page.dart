import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_icon_button.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_dropdown.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/enums/marketplace_category.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_sort.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/cart_count_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_item_card.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_skeleton.dart';

/// «السوق»: the shared marketplace browse screen for clients and contractors.
///
/// Displays active listings in a 2-column grid with search by item name,
/// category filter chips, sorting, pagination on scroll, pull-to-refresh,
/// and a cart button with item count in the top bar.
class MarketplacePage extends StatelessWidget {
  const MarketplacePage({this.onCartTap, this.onItemTap, super.key});

  /// Called when the user taps the cart icon in the top bar.
  final VoidCallback? onCartTap;

  /// Called when the user taps a marketplace item card; by default it opens
  /// the item's page.
  final ValueChanged<MarketplaceItem>? onItemTap;

  /// Opens [item]'s page, then refreshes the cart badge: the page may have
  /// added it to the cart.
  static Future<void> _openItem(
    BuildContext context,
    MarketplaceItem item,
  ) async {
    final cartCount = context.read<CartCountBloc>();
    await context.pushNamed(
      MarketplaceRoutes.marketplaceItemName,
      pathParameters: {'itemId': item.id},
    );
    cartCount.add(const CartCountRefreshed());
  }

  /// Opens the cart, then refreshes the badge: lines may have been removed
  /// or ordered.
  static Future<void> _openCart(BuildContext context) async {
    final cartCount = context.read<CartCountBloc>();
    await context.pushNamed(MarketplaceRoutes.marketplaceCartName);
    cartCount.add(const CartCountRefreshed());
  }

  static String _sortKey(MarketplaceSort sort) => switch (sort) {
    MarketplaceSort.newest => 'marketplace.sort_newest',
    MarketplaceSort.priceLowToHigh => 'marketplace.sort_price_low_to_high',
    MarketplaceSort.priceHighToLow => 'marketplace.sort_price_high_to_low',
  };

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MarketplaceBloc>();
    final cartCount = context.read<CartCountBloc>();
    final openItem = onItemTap ?? (item) => _openItem(context, item);
    return BlocListener<CartCountBloc, CartCountState>(
      listenWhen: (previous, current) =>
          current.failure != null && previous.failure != current.failure,
      listener: (context, state) =>
          context.showErrorSnackBar(context.tr(state.failure!.messageKey)),
      child: Scaffold(
        appBar: AppTopBar(
          title: context.tr('marketplace.browse_title'),
          actions: [
            AppIconButton(
              key: const Key('marketplace_my_items_button'),
              icon: Icons.inventory_2_outlined,
              tooltip: context.tr('marketplace.my_items_title'),
              onPressed: () async {
                await context.pushNamed(MarketplaceRoutes.myItemsName);
                bloc.add(const MarketplaceFetched());
              },
            ),
            BlocBuilder<CartCountBloc, CartCountState>(
              builder: (context, cart) => IconButton(
                key: const Key('marketplace_cart_button'),
                tooltip: context.tr('marketplace.cart_tooltip'),
                onPressed: onCartTap ?? () => _openCart(context),
                icon: Badge(
                  isLabelVisible: cart.count > 0,
                  backgroundColor: AppColors.primary,
                  label: Text(context.formatNumber(cart.count)),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: BlocBuilder<MarketplaceBloc, MarketplaceState>(
          builder: (context, state) => NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              final metrics = notification.metrics;
              if (metrics.axis == Axis.vertical && metrics.extentAfter < 400) {
                bloc.add(const MarketplaceMoreRequested());
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: () async {
                bloc.add(const MarketplaceFetched());
                cartCount.add(const CartCountRefreshed());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                children: [
                  AppTextField(
                    key: const Key('marketplace_search'),
                    hint: context.tr('marketplace.browse_search_hint'),
                    textInputAction: TextInputAction.search,
                    onChanged: (text) =>
                        bloc.add(MarketplaceSearchChanged(text)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppFilterChips(
                    key: const Key('marketplace_categories'),
                    labels: [
                      context.tr('marketplace.categories.all'),
                      for (final category in MarketplaceCategory.values)
                        context.tr('marketplace.categories.${category.value}'),
                    ],
                    selectedIndex: state.category == null
                        ? 0
                        : state.category!.index + 1,
                    onSelected: (index) => bloc.add(
                      MarketplaceCategoryChanged(
                        index == 0
                            ? null
                            : MarketplaceCategory.values[index - 1],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppDropdown<MarketplaceSort>(
                    key: const Key('marketplace_sort'),
                    floating: true,
                    value: state.sort,
                    options: [
                      for (final sort in MarketplaceSort.values)
                        AppDropdownOption(
                          value: sort,
                          title: context.tr(_sortKey(sort)),
                        ),
                    ],
                    onChanged: (sort) => bloc.add(MarketplaceSortChanged(sort)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ..._body(context, bloc, state, openItem),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    MarketplaceBloc bloc,
    MarketplaceState state,
    ValueChanged<MarketplaceItem> onItemTap,
  ) {
    if (state.items.isEmpty) {
      return [
        switch (state.status) {
          MarketplaceStatus.failure => AppErrorView(
            message: context.tr(state.failure!.messageKey),
            onRetry: () => bloc.add(const MarketplaceFetched()),
          ),
          MarketplaceStatus.success => AppEmptyView(
            message: context.tr(
              state.search.isEmpty && state.category == null
                  ? 'marketplace.browse_empty'
                  : 'marketplace.browse_empty_search',
            ),
            icon: Icons.storefront_outlined,
          ),
          _ => const MarketplaceSkeleton(),
        },
      ];
    }
    return [
      for (var i = 0; i < state.items.length; i += 2) ...[
        if (i > 0) const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MarketplaceItemCard(
                key: ValueKey(state.items[i].id),
                item: state.items[i],
                onTap: () => onItemTap(state.items[i]),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: i + 1 < state.items.length
                  ? MarketplaceItemCard(
                      key: ValueKey(state.items[i + 1].id),
                      item: state.items[i + 1],
                      onTap: () => onItemTap(state.items[i + 1]),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
      if (state.isLoadingMore)
        const Padding(
          padding: EdgeInsetsDirectional.all(AppSpacing.md),
          child: AppLoadingIndicator(),
        ),
    ];
  }
}
