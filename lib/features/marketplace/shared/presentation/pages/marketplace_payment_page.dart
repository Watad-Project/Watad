import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_popup.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/payment_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_card_form.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_demo_note.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_payment_result.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_wallet_sheet.dart';

/// «الدفع» (`/marketplace/orders/:orderId/pay`, GRA-68). DEMO ONLY: no real
/// money moves (ARCHITECTURE.md §15). A card form for mada and credit
/// cards, a confirmation sheet for Apple Pay and STC Pay, about 2 seconds
/// of processing, then success or failure.
class MarketplacePaymentPage extends StatelessWidget {
  const MarketplacePaymentPage({this.returnsToOrder = false, super.key});

  /// Opened from the order page: «عرض الطلب» goes back to it, which loads
  /// the order again. From checkout, the order page takes this one's place.
  final bool returnsToOrder;

  void _viewOrder(BuildContext context, String orderId) {
    if (returnsToOrder) {
      context.pop();
    } else {
      context.pushReplacementNamed(
        MarketplaceRoutes.marketplaceOrderDetailsName,
        pathParameters: {'orderId': orderId},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PaymentBloc>();
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        final isProcessing = state.status == PaymentPageStatus.processing;
        return PopScope(
          // A payment being sent finishes before the page can close.
          canPop: !isProcessing,
          child: Scaffold(
            appBar: AppTopBar(
              title: context.tr('marketplace.payment.title'),
              onBack: isProcessing ? null : () => context.pop(),
            ),
            body: _body(context, bloc, state),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, PaymentBloc bloc, PaymentState state) {
    final order = state.order;
    void retry() => bloc.add(const PaymentRetried());
    return switch (state.status) {
      PaymentPageStatus.initial ||
      PaymentPageStatus.loading => const AppLoadingIndicator(),
      PaymentPageStatus.loadFailure => AppErrorView(
        message: context.tr(state.failure!.messageKey),
        onRetry: retry,
      ),
      PaymentPageStatus.processing => const _Processing(),
      _ when order == null => const AppLoadingIndicator(),
      PaymentPageStatus.notPayable => _NotPayable(
        order: order,
        onViewOrder: () => _viewOrder(context, order.id),
      ),
      PaymentPageStatus.ready => _PaymentForm(
        order: order,
        state: state,
        bloc: bloc,
      ),
      PaymentPageStatus.paid => MarketplacePaymentResult(
        key: const Key('payment_success'),
        order: order,
        isSuccess: true,
        title: context.tr('marketplace.payment.success_title'),
        message: context.tr('marketplace.payment.success_message'),
        primaryLabel: context.tr('marketplace.payment.view_order'),
        onPrimary: () => _viewOrder(context, order.id),
        onBack: () => context.pop(),
      ),
      PaymentPageStatus.declined => MarketplacePaymentResult(
        key: const Key('payment_declined'),
        order: order,
        isSuccess: false,
        title: context.tr('marketplace.payment.declined_title'),
        message: context.tr('marketplace.payment.declined_message'),
        primaryLabel: context.tr('marketplace.payment.try_again'),
        onPrimary: retry,
        onBack: () => context.pop(),
      ),
      PaymentPageStatus.payFailure => MarketplacePaymentResult(
        key: const Key('payment_failure'),
        order: order,
        isSuccess: false,
        title: context.tr('marketplace.payment.failure_title'),
        message: context.tr(state.failure!.messageKey),
        primaryLabel: context.tr('marketplace.payment.try_again'),
        onPrimary: retry,
        onBack: () => context.pop(),
      ),
    };
  }
}

class _PaymentForm extends StatelessWidget {
  const _PaymentForm({
    required this.order,
    required this.state,
    required this.bloc,
  });

  final MarketplaceOrder order;
  final PaymentState state;
  final PaymentBloc bloc;

  @override
  Widget build(BuildContext context) {
    final methodLabel = context.tr(
      'marketplace.payment_methods.${order.paymentMethod.value}',
    );
    final amount = AppMoneyText.format(context, order.total);
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        const MarketplaceDemoNote(),
        const SizedBox(height: AppSpacing.md),
        AppKeyValueList(
          rows: [
            AppKeyValueRow(
              label: context.tr('marketplace.payment.order_number'),
              value: order.number,
              isMonospace: true,
            ),
            AppKeyValueRow(
              label: context.tr('marketplace.payment.seller'),
              value: order.sellerName,
            ),
            AppKeyValueRow(
              label: context.tr('marketplace.payment.method'),
              value: methodLabel,
            ),
            AppKeyValueRow(
              label: context.tr('marketplace.payment.amount'),
              value: amount,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (order.isCardMethod)
          MarketplaceCardForm(
            method: order.paymentMethod,
            payLabel: context.tr('marketplace.payment.pay', args: [amount]),
            check: state.cardCheck,
            onSubmit:
                ({
                  required number,
                  required expiry,
                  required cvv,
                  required name,
                }) => bloc.add(
                  PaymentCardSubmitted(
                    number: number,
                    expiry: expiry,
                    cvv: cvv,
                    name: name,
                  ),
                ),
          )
        else
          AppButton(
            key: const Key('payment_wallet_button'),
            label: context.tr(
              'marketplace.payment.pay_with',
              args: [methodLabel],
            ),
            icon: Icons.account_balance_wallet_outlined,
            onPressed: () async {
              final confirmed = await AppPopup.sheet<bool>(
                context,
                builder: (_) => MarketplaceWalletSheet(
                  method: order.paymentMethod,
                  amount: order.total,
                ),
              );
              if (confirmed ?? false) bloc.add(const PaymentWalletConfirmed());
            },
          ),
      ],
    );
  }
}

/// The 2 seconds while the demo "bank" answers.
class _Processing extends StatelessWidget {
  const _Processing();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('payment_processing'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.xxl),
        const AppLoadingIndicator(),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.tr('marketplace.payment.processing'),
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        const MarketplaceDemoNote(),
      ],
    );
  }
}

/// The order can't be paid here: paid already, cancelled, someone else's,
/// or a bank transfer.
class _NotPayable extends StatelessWidget {
  const _NotPayable({required this.order, required this.onViewOrder});

  final MarketplaceOrder order;
  final VoidCallback onViewOrder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        AppStatusCard(
          key: const Key('payment_not_payable'),
          tone: AppTone.neutral,
          title: context.tr('marketplace.payment.not_payable'),
          subtitle: context.tr(
            'marketplace.order_status.${order.status.value}',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          key: const Key('payment_view_order'),
          label: context.tr('marketplace.payment.view_order'),
          variant: AppButtonVariant.secondary,
          onPressed: onViewOrder,
        ),
      ],
    );
  }
}
