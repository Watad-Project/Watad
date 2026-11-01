import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';

/// The seller's part of the order page. For now only «مراسلة المشتري»; the
/// seller's own actions («تم الشحن») come here with «مبيعاتي» (GRA-71).
class MarketplaceOrderSellerActions extends StatelessWidget {
  const MarketplaceOrderSellerActions({required this.onMessage, super.key});

  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('order_seller_actions'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          key: const Key('order_message'),
          label: context.tr('marketplace.order_details.message_buyer'),
          icon: Icons.chat_bubble_outline,
          variant: AppButtonVariant.secondary,
          onPressed: onMessage,
        ),
      ],
    );
  }
}
