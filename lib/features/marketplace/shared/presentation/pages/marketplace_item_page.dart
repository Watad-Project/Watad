import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/core/router/routes/splash_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_item_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_item_buy_bar.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_item_details.dart';

/// One listing (`/marketplace/items/:itemId`, GRA-67): photos, details, the
/// seller, and «أضف للسلة»; «تعديل» on my own item; «المنتج غير متاح»
/// for a hidden, deleted or removed listing opened from a link.
class MarketplaceItemPage extends StatelessWidget {
  const MarketplaceItemPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MarketplaceItemBloc>();
    return BlocConsumer<MarketplaceItemBloc, MarketplaceItemState>(
      listenWhen: (previous, current) =>
          previous.addStatus != current.addStatus,
      listener: _onAddStatus,
      builder: (context, state) {
        final item = state.item;
        return Scaffold(
          appBar: AppTopBar(
            title: context.tr('marketplace.item_details.title'),
            onBack: () => context.pop(),
          ),
          body: switch (state.status) {
            MarketplaceItemLoadStatus.initial ||
            MarketplaceItemLoadStatus.loading => const AppLoadingIndicator(),
            MarketplaceItemLoadStatus.failure => AppErrorView(
              message: context.tr(state.failure!.messageKey),
              onRetry: () => bloc.add(MarketplaceItemFetched(state.itemId)),
            ),
            MarketplaceItemLoadStatus.unavailable => const _Unavailable(),
            MarketplaceItemLoadStatus.success => MarketplaceItemDetails(
              item: item!,
            ),
          },
          bottomNavigationBar:
              state.status == MarketplaceItemLoadStatus.success && item != null
              ? MarketplaceItemBuyBar(
                  item: item,
                  quantity: state.quantity,
                  isAdding: state.addStatus == MarketplaceItemAddStatus.adding,
                  onQuantityChanged: (quantity) =>
                      bloc.add(MarketplaceItemQuantityChanged(quantity)),
                  onAdd: () => bloc.add(const MarketplaceItemAddedToCart()),
                  onEdit: () async {
                    await context.pushNamed(
                      MarketplaceRoutes.editMyItemName,
                      pathParameters: {'itemId': item.id},
                    );
                    bloc.add(MarketplaceItemFetched(item.id));
                  },
                )
              : null,
        );
      },
    );
  }

  void _onAddStatus(BuildContext context, MarketplaceItemState state) {
    switch (state.addStatus) {
      case MarketplaceItemAddStatus.added:
        final addition = state.addition!;
        context.showSnackBar(
          addition.isCapped
              ? context.tr(
                  'marketplace.item_details.added_capped',
                  args: [context.formatNumber(addition.quantityInCart)],
                )
              : context.tr('marketplace.item_details.added'),
          tone: AppTone.success,
          actionLabel: context.tr('marketplace.item_details.view_cart'),
          onAction: () =>
              context.pushNamed(MarketplaceRoutes.marketplaceCartName),
        );
      case MarketplaceItemAddStatus.failed:
        context.showErrorSnackBar(context.tr(state.addFailure!.messageKey));
      case MarketplaceItemAddStatus.idle || MarketplaceItemAddStatus.adding:
        break;
    }
  }
}

/// «المنتج غير متاح», and the way back to the market.
class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        AppEmptyView(
          key: const Key('marketplace_item_unavailable'),
          message: context.tr('marketplace.item_details.unavailable'),
          icon: Icons.remove_shopping_cart_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: context.tr('marketplace.item_details.back_to_market'),
          variant: AppButtonVariant.secondary,
          // Opened from a link with nothing behind it: the splash sends the
          // user to their own role's navigation.
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(SplashRoutes.splashName),
        ),
      ],
    );
  }
}
