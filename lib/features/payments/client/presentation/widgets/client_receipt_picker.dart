import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';
import 'package:watad/core/components/inputs/app_upload_zone.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt.dart';

/// The receipt on the bank transfer screen (GRA-52): «إيصال التحويل»,
/// required, and a dashed box that opens the choice of a file or a photo.
/// Once picked, the box shows its name, and a tap changes it.
class ClientReceiptPicker extends StatelessWidget {
  const ClientReceiptPicker({
    required this.receipt,
    required this.onPick,
    super.key,
  });

  final ClientReceipt? receipt;

  /// Opens the choice; null while the receipt is being sent.
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final receipt = this.receipt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(
          label: context.tr('payments.client.receipt_label'),
          isRequired: true,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppUploadZone(
          key: const Key('client_bank_transfer_receipt'),
          label: receipt == null
              ? context.tr('payments.client.receipt_pick')
              : context.tr(
                  'payments.client.receipt_selected',
                  args: [receipt.name],
                ),
          subtitle: receipt == null
              ? context.tr('payments.client.receipt_hint')
              : context.tr('payments.client.receipt_change'),
          icon: receipt == null
              ? Icons.arrow_upward
              : Icons.receipt_long_outlined,
          onTap: onPick,
        ),
      ],
    );
  }
}
