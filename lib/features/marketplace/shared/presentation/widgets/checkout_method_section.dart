import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/inputs/app_radio_row.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// «طريقة الدفع»: mada, credit card, Apple Pay or STC Pay. Bank transfer
/// isn't offered for marketplace orders.
class CheckoutMethodSection extends StatelessWidget {
  const CheckoutMethodSection({
    required this.methods,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<PaymentMethod> methods;
  final PaymentMethod? selected;
  final ValueChanged<PaymentMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: context.tr('marketplace.checkout.method_title'),
        ),
        for (final method in methods) ...[
          AppRadioRow(
            key: ValueKey('checkout_method_${method.value}'),
            title: context.tr('marketplace.payment_methods.${method.value}'),
            selected: method == selected,
            onTap: () => onSelected(method),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}
