import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/display/app_cart_group.dart';
import 'package:watad/core/components/display/app_cart_line.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/display/app_summary_rows.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/chat_routes.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/core/router/routes/profile_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_details.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_role.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_order_details_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_order_buyer_actions.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_order_labels.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_order_party_card.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_order_seller_actions.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_order_timeline.dart';

/// «تفاصيل الطلب» (`/marketplace/orders/:orderId`, GRA-69), for the buyer
/// and the seller of the order: its products, payment, address and
/// timeline, the other side, and the actions of my side (`my_role`).
class MarketplaceOrderDetailsPage extends StatelessWidget {
  const MarketplaceOrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MarketplaceOrderDetailsBloc>();
    return MultiBlocListener(
      listeners: [
        BlocListener<MarketplaceOrderDetailsBloc, MarketplaceOrderDetailsState>(
          listenWhen: (previous, current) =>
              current.doneAction != null &&
              previous.doneAction != current.doneAction,
          listener: (context, state) => context.showSuccessSnackBar(
            context.tr(switch (state.doneAction!) {
              OrderDetailsAction.cancel =>
                'marketplace.order_details.cancelled',
              OrderDetailsAction.confirmDelivery =>
                'marketplace.order_details.delivered',
              OrderDetailsAction.ship => 'marketplace.order_details.shipped',
            }),
          ),
        ),
        BlocListener<MarketplaceOrderDetailsBloc, MarketplaceOrderDetailsState>(
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
          title: context.tr('marketplace.order_details.title'),
          onBack: () => context.pop(),
        ),
        body:
            BlocBuilder<
              MarketplaceOrderDetailsBloc,
              MarketplaceOrderDetailsState
            >(
              builder: (context, state) {
                final details = state.details;
                if (details == null) {
                  return switch (state.status) {
                    MarketplaceOrderDetailsStatus.failure => AppErrorView(
                      message: context.tr(state.failure!.messageKey),
                      onRetry: () =>
                          bloc.add(const MarketplaceOrderDetailsFetched()),
                    ),
                    _ => const AppLoadingIndicator(),
                  };
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      bloc.add(const MarketplaceOrderDetailsFetched()),
                  child: _OrderView(details: details, state: state, bloc: bloc),
                );
              },
            ),
      ),
    );
  }
}

class _OrderView extends StatelessWidget {
  const _OrderView({
    required this.details,
    required this.state,
    required this.bloc,
  });

  final OrderDetails details;
  final MarketplaceOrderDetailsState state;
  final MarketplaceOrderDetailsBloc bloc;

  @override
  Widget build(BuildContext context) {
    final order = details.order;
    final isBuyer = order.myRole == OrderRole.buyer;
    final otherId = isBuyer ? order.sellerId : order.buyerId;
    final address = order.deliveryAddress;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Text(
          MarketplaceOrderLabels.number(context, order),
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          MarketplaceOrderLabels.dateTime(context, order.createdAt),
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppStatusBadge(
            key: const Key('order_status'),
            label: MarketplaceOrderLabels.status(context, order.status),
            tone: MarketplaceOrderLabels.tone(order.status),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        MarketplaceOrderPartyCard(
          role: context.tr(
            isBuyer
                ? 'marketplace.order_details.seller'
                : 'marketplace.order_details.buyer',
          ),
          name: isBuyer ? order.sellerName : order.buyerName,
          avatarUrl: isBuyer ? order.sellerAvatarUrl : order.buyerAvatarUrl,
          onTap: () => context.pushNamed(
            ProfileRoutes.publicProfileName,
            pathParameters: {'userId': otherId},
          ),
        ),
        AppSectionHeader(title: context.tr('marketplace.order_details.items')),
        AppCartGroup(
          key: const Key('order_lines'),
          title: isBuyer ? order.sellerName : order.buyerName,
          children: [
            for (final line in details.lines)
              AppCartLine(
                title: line.name,
                subtitle: context.tr(
                  'marketplace.checkout.line_quantity',
                  args: [
                    context.formatNumber(line.quantity),
                    AppMoneyText.format(context, line.price),
                  ],
                ),
                priceLabel: AppMoneyText.format(context, line.subtotal),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: AppSummaryRows(
                rows: [
                  AppSummaryRow(
                    label: context.tr('marketplace.cart.units'),
                    value: context.formatNumber(order.unitCount),
                  ),
                ],
                total: AppSummaryRow(
                  label: context.tr('marketplace.checkout.total'),
                  value: AppMoneyText.format(context, order.total),
                ),
              ),
            ),
          ],
        ),
        AppSectionHeader(
          title: context.tr('marketplace.order_details.payment'),
        ),
        AppKeyValueList(
          key: const Key('order_payment'),
          rows: [
            AppKeyValueRow(
              label: context.tr('marketplace.payment.method'),
              value: MarketplaceOrderLabels.method(context, order),
            ),
            AppKeyValueRow(
              label: context.tr('marketplace.order_details.paid_with'),
              value: MarketplaceOrderLabels.payment(context, order),
              isMonospace: order.isCardMethod && order.cardLast4 != null,
            ),
            if (order.paidAt case final paidAt?)
              AppKeyValueRow(
                label: context.tr('marketplace.order_details.paid_at'),
                value: MarketplaceOrderLabels.dateTime(context, paidAt),
              ),
          ],
        ),
        AppSectionHeader(
          title: context.tr('marketplace.checkout.address_title'),
        ),
        AppKeyValueList(
          key: const Key('order_address'),
          rows: [
            if (address?.name case final name? when name.isNotEmpty)
              AppKeyValueRow(
                label: context.tr('marketplace.order_details.address_name'),
                value: name,
              ),
            AppKeyValueRow(
              label: context.tr('marketplace.order_details.address'),
              value: switch (address?.formattedAddress) {
                final text? when text.isNotEmpty => text,
                _ => '—',
              },
            ),
          ],
        ),
        AppSectionHeader(
          title: context.tr('marketplace.order_details.timeline'),
        ),
        MarketplaceOrderTimeline(
          status: order.status,
          history: details.history,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (isBuyer)
          MarketplaceOrderBuyerActions(
            actions: details.actions,
            isBusy: state.pendingAction != null,
            isCancelling: state.pendingAction == OrderDetailsAction.cancel,
            isConfirming:
                state.pendingAction == OrderDetailsAction.confirmDelivery,
            onPay: () async {
              await context.pushNamed(
                MarketplaceRoutes.marketplacePaymentName,
                pathParameters: {'orderId': order.id},
                queryParameters: {'from': 'order'},
              );
              bloc.add(const MarketplaceOrderDetailsFetched());
            },
            onConfirmDelivery: () async {
              final confirmed = await AppConfirmDialog.show(
                context,
                title: context.tr('marketplace.order_details.confirm_title'),
                message: context.tr(
                  'marketplace.order_details.confirm_message',
                ),
                confirmLabel: context.tr(
                  'marketplace.order_details.confirm_delivery',
                ),
              );
              if (confirmed != null) {
                bloc.add(const MarketplaceOrderDeliveryConfirmed());
              }
            },
            onCancel: () async {
              final confirmed = await AppConfirmDialog.show(
                context,
                title: context.tr('marketplace.order_details.cancel_title'),
                message: context.tr('marketplace.order_details.cancel_message'),
                confirmLabel: context.tr('marketplace.order_details.cancel'),
              );
              if (confirmed != null) {
                bloc.add(const MarketplaceOrderCancelled());
              }
            },
            onMessage: () => context.pushNamed(
              ChatRoutes.chatStartName,
              pathParameters: {'userId': otherId},
            ),
          )
        else
          MarketplaceOrderSellerActions(
            actions: details.actions,
            isBusy: state.pendingAction != null,
            isShipping: state.pendingAction == OrderDetailsAction.ship,
            onShip: () async {
              final confirmed = await AppConfirmDialog.show(
                context,
                title: context.tr('marketplace.order_details.ship_title'),
                message: context.tr('marketplace.order_details.ship_message'),
                confirmLabel: context.tr('marketplace.order_details.ship'),
              );
              if (confirmed != null) {
                bloc.add(const MarketplaceOrderShipped());
              }
            },
            onMessage: () => context.pushNamed(
              ChatRoutes.chatStartName,
              pathParameters: {'userId': otherId},
            ),
          ),
      ],
    );
  }
}
