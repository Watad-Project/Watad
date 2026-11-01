import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_cart_group.dart';
import 'package:watad/core/components/display/app_icon_tag.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/core/router/routes/splash_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/cart_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/cart_entry_tile.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/cart_seller_section.dart';

/// «السلة» (`/marketplace/cart`, GRA-68): the cart grouped by seller, with
/// the prices and stock read again from the server, and one checkout per
/// seller.
class MarketplaceCartPage extends StatelessWidget {
  const MarketplaceCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CartBloc>();
    return MultiBlocListener(
      listeners: [
        BlocListener<CartBloc, CartState>(
          listenWhen: (previous, current) =>
              current.lastRemoved != null &&
              previous.lastRemoved != current.lastRemoved,
          listener: (context, state) => context.showSnackBar(
            context.tr('marketplace.cart.removed'),
            actionLabel: context.tr('marketplace.cart.undo'),
            onAction: () => bloc.add(const CartLineRestored()),
            duration: const Duration(seconds: 6),
          ),
        ),
        BlocListener<CartBloc, CartState>(
          listenWhen: (previous, current) =>
              current.actionFailure != null &&
              previous.actionFailure != current.actionFailure,
          listener: (context, state) => context.showErrorSnackBar(
            context.tr(state.actionFailure!.messageKey),
          ),
        ),
      ],
      child: Scaffold(
        appBar: AppTopBar(
          title: context.tr('marketplace.cart.title'),
          onBack: () => context.pop(),
        ),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (!state.hasLoaded) {
              return switch (state.status) {
                CartStatus.failure => AppErrorView(
                  message: context.tr(state.failure!.messageKey),
                  onRetry: () => bloc.add(const CartFetched()),
                ),
                _ => const AppLoadingIndicator(),
              };
            }
            if (state.cart.isEmpty) return const _EmptyCart();
            return RefreshIndicator(
              onRefresh: () async => bloc.add(const CartFetched()),
              child: _CartList(state: state, bloc: bloc),
            );
          },
        ),
      ),
    );
  }
}

class _CartList extends StatelessWidget {
  const _CartList({required this.state, required this.bloc});

  final CartState state;
  final CartBloc bloc;

  @override
  Widget build(BuildContext context) {
    final cart = state.cart;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        if (cart.hasChanges) ...[
          AppIconTag(
            key: const Key('cart_changed_note'),
            label: context.tr('marketplace.cart.changed_note'),
            icon: Icons.info_outline,
            tone: AppTone.attention,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final group in cart.groups) ...[
          CartSellerSection(
            group: group,
            onQuantityChanged: (itemId, quantity) =>
                bloc.add(CartQuantityChanged(itemId, quantity)),
            onRemove: (itemId) => bloc.add(CartLineRemoved(itemId)),
            onCheckout: () async {
              await context.pushNamed(
                MarketplaceRoutes.marketplaceCheckoutName,
                pathParameters: {'sellerId': group.sellerId},
              );
              bloc.add(const CartFetched());
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (cart.unavailable.isNotEmpty)
          AppCartGroup(
            key: const Key('cart_unavailable'),
            title: context.tr('marketplace.cart.unavailable_title'),
            children: [
              for (final entry in cart.unavailable)
                CartEntryTile(
                  entry: entry,
                  onRemove: () => bloc.add(CartLineRemoved(entry.line.itemId)),
                ),
            ],
          ),
      ],
    );
  }
}

/// An empty cart, and the way back to the market.
class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        AppEmptyView(
          key: const Key('cart_empty'),
          message: context.tr('marketplace.cart.empty'),
          icon: Icons.shopping_cart_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: context.tr('marketplace.cart.browse'),
          variant: AppButtonVariant.secondary,
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(SplashRoutes.splashName),
        ),
      ],
    );
  }
}
