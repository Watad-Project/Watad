import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/inputs/app_radio_row.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_address.dart';

/// «عنوان التوصيل»: one of the buyer's saved addresses, or a new one from
/// the map. No address means no checkout.
class CheckoutAddressSection extends StatelessWidget {
  const CheckoutAddressSection({
    required this.addresses,
    required this.selectedId,
    required this.onSelected,
    required this.onAdd,
    super.key,
  });

  final List<MarketplaceAddress> addresses;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: context.tr('marketplace.checkout.address_title'),
        ),
        if (addresses.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
            child: Text(
              context.tr('marketplace.checkout.no_address'),
              style: AppTextStyles.body,
            ),
          ),
        for (final address in addresses) ...[
          AppRadioRow(
            key: ValueKey('checkout_address_${address.id}'),
            title: address.name,
            subtitle: address.formattedAddress,
            selected: address.id == selectedId,
            onTap: () => onSelected(address.id),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        AppButton(
          key: const Key('checkout_add_address'),
          label: context.tr('marketplace.checkout.add_address'),
          icon: Icons.add_location_alt_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: onAdd,
        ),
      ],
    );
  }
}
