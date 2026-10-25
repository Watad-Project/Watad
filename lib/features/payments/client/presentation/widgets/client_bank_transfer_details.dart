import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/display/app_summary_rows.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_transfer.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_transfer_outcome.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt.dart';
import 'package:watad/features/payments/client/presentation/widgets/client_payment_format.dart';
import 'package:watad/features/payments/client/presentation/widgets/client_receipt_picker.dart';
import 'package:watad/features/payments/client/presentation/widgets/client_transfer_outcome_card.dart';

/// The bank transfer screen once it loaded (GRA-52): what to do, where to
/// send the money (the IBAN and the amount copy), the tasks it pays and
/// their total, the tasks that no longer need paying, and the receipt.
/// Without the contractor's bank details, only why the client can't
/// transfer yet.
class ClientBankTransferDetails extends StatelessWidget {
  const ClientBankTransferDetails({
    required this.transfer,
    required this.receipt,
    required this.outcome,
    required this.onPickReceipt,
    super.key,
  });

  final ClientBankTransfer transfer;
  final ClientReceipt? receipt;

  /// The last sending, when it stopped part way.
  final ClientBankTransferOutcome? outcome;
  final VoidCallback? onPickReceipt;

  @override
  Widget build(BuildContext context) {
    final bankDetails = transfer.bankDetails;
    final outcome = this.outcome;
    final canPay = transfer.tasks.isNotEmpty && bankDetails != null;
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Text(
          context.tr('payments.client.transfer_heading'),
          style: AppTextStyles.h1,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('payments.client.transfer_subtitle'),
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (outcome != null) ...[
          ClientTransferOutcomeCard(outcome: outcome),
          const SizedBox(height: AppSpacing.md),
        ],
        if (transfer.tasks.isEmpty)
          AppStatusCard(
            tone: AppTone.neutral,
            title: context.tr('payments.client.nothing_to_pay'),
          )
        else if (bankDetails == null)
          AppStatusCard(
            tone: AppTone.attention,
            title: context.tr('payments.client.no_bank_details_title'),
            subtitle: context.tr('payments.client.no_bank_details_subtitle'),
          )
        else
          AppKeyValueList(
            rows: [
              AppKeyValueRow(
                label: context.tr('payments.client.beneficiary'),
                value: bankDetails.beneficiaryName,
              ),
              AppKeyValueRow(
                label: context.tr('payments.client.bank'),
                value: bankDetails.bankName,
              ),
              AppKeyValueRow(
                label: context.tr('payments.client.iban'),
                value: ClientPaymentFormat.iban(bankDetails.iban),
                isMonospace: true,
                isCopyable: true,
                copyValue: bankDetails.iban,
              ),
              AppKeyValueRow(
                label: context.tr('payments.client.amount'),
                value: AppMoneyText.format(context, transfer.total),
                isCopyable: true,
                copyValue: ClientPaymentFormat.plainAmount(transfer.total),
              ),
            ],
            onCopied: (_) =>
                context.showSnackBar(context.tr('payments.client.copied')),
          ),
        if (transfer.tasks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('payments.client.covered_tasks'),
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppSummaryRows(
            rows: [
              for (final task in transfer.tasks)
                AppSummaryRow(
                  label: task.title,
                  value: AppMoneyText.format(
                    context,
                    task.amount ?? const Money.zero(),
                  ),
                ),
            ],
            total: AppSummaryRow(
              label: context.tr('payments.client.total'),
              value: AppMoneyText.format(context, transfer.total),
            ),
          ),
        ],
        if (transfer.skippedTasks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppStatusCard(
            tone: AppTone.neutral,
            title: context.tr('payments.client.skipped_title'),
            subtitle: [for (final task in transfer.skippedTasks) task.title]
                .join('\n'),
          ),
        ],
        if (canPay) ...[
          const SizedBox(height: AppSpacing.lg),
          ClientReceiptPicker(receipt: receipt, onPick: onPickReceipt),
        ],
      ],
    );
  }
}
