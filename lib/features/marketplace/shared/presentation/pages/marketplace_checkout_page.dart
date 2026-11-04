import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_icon_tag.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/location_routes.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_review.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/checkout_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/checkout_address_section.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/checkout_lines.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/checkout_method_section.dart';

/// «إتمام الطلب» (`/marketplace/checkout/:sellerId`, GRA-68): one seller's
/// group re-checked against the server, the delivery address, the payment
/// method, and «تأكيد الطلب». The new order opens its payment page in this
/// page's place, so «back» never returns to an order already made.
class MarketplaceCheckoutPage extends StatelessWidget {
  const MarketplaceCheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CheckoutBloc>();
    return BlocConsumer<CheckoutBloc, CheckoutState>(
      listenWhen: (previous, current) =>
          previous.submitStatus != current.submitStatus,
      listener: _onSubmitStatus,
      builder: (context, state) {
        final review = state.review;
        return Scaffold(
          appBar: AppTopBar(
            title: context.tr('marketplace.checkout.title'),
            onBack: () => context.pop(),
          ),
          body: review == null
              ? switch (state.status) {
                  CheckoutStatus.failure => AppErrorView(
                    message: context.tr(state.failure!.messageKey),
                    onRetry: () => bloc.add(CheckoutStarted(state.sellerId)),
                  ),
                  _ => const AppLoadingIndicator(),
                }
              : _CheckoutForm(state: state, review: review, bloc: bloc),
          bottomNavigationBar: review == null
              ? null
              : DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                      child: AppButton(
                        key: const Key('checkout_confirm'),
                        label: context.tr('marketplace.checkout.confirm'),
                        isLoading:
                            state.submitStatus ==
                            CheckoutSubmitStatus.submitting,
                        onPressed: state.canSubmit
                            ? () => bloc.add(const CheckoutSubmitted())
                            : null,
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  void _onSubmitStatus(BuildContext context, CheckoutState state) {
    switch (state.submitStatus) {
      case CheckoutSubmitStatus.placed:
        final placed = state.placed!;
        if (!placed.cartCleared) {
          context.showErrorSnackBar(
            context.tr('marketplace.checkout.cart_not_cleared'),
          );
        }
        context.pushReplacementNamed(
          MarketplaceRoutes.marketplacePaymentName,
          pathParameters: {'orderId': placed.orderId},
        );
      case CheckoutSubmitStatus.failed:
        context.showErrorSnackBar(context.tr(state.submitFailure!.messageKey));
      case CheckoutSubmitStatus.idle || CheckoutSubmitStatus.submitting:
        break;
    }
  }
}

class _CheckoutForm extends StatelessWidget {
  const _CheckoutForm({
    required this.state,
    required this.review,
    required this.bloc,
  });

  final CheckoutState state;
  final CheckoutReview review;
  final CheckoutBloc bloc;

  @override
  Widget build(BuildContext context) {
    final problem = review.problem;
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        if (problem != null) ...[
          AppStatusCard(
            key: const Key('checkout_problem'),
            tone: AppTone.danger,
            title: context.tr(problem.messageKey),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (review.hasChanges) ...[
          AppIconTag(
            key: const Key('checkout_changed_note'),
            label: context.tr('marketplace.checkout.changed_note'),
            icon: Icons.info_outline,
            tone: AppTone.attention,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (review.entries.isNotEmpty) ...[
          CheckoutLines(review: review),
          const SizedBox(height: AppSpacing.lg),
        ],
        CheckoutAddressSection(
          addresses: review.addresses,
          selectedId: state.addressId,
          onSelected: (id) => bloc.add(CheckoutAddressSelected(id)),
          onAdd: () => _addAddress(context),
        ),
        const SizedBox(height: AppSpacing.lg),
        CheckoutMethodSection(
          methods: CheckoutState.methods,
          selected: state.method,
          onSelected: (method) => bloc.add(CheckoutMethodSelected(method)),
        ),
      ],
    );
  }

  /// The map picker always saves the address and returns its id, like the
  /// project form does; the page reloads the addresses and picks it.
  Future<void> _addAddress(BuildContext context) async {
    final addressId = await context.pushNamed<String>(
      LocationRoutes.locationName,
      queryParameters: const {'save': 'required'},
    );
    if (addressId == null || addressId.isEmpty) return;
    bloc.add(CheckoutAddressAdded(addressId));
  }
}
