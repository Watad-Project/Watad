import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';
import 'package:watad/features/payments/shared/presentation/widgets/payment_format.dart';

/// The saved bank account (GRA-64), as clients see it on their transfer
/// screen (GRA-52): the beneficiary, the bank, and the IBAN in groups of
/// four, which «نسخ» copies without the spaces.
class ContractorBankDetailsSummary extends StatelessWidget {
  const ContractorBankDetailsSummary({required this.details, super.key});

  final ContractorBankDetails details;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Text(
          context.tr('payments.contractor.view_intro'),
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppKeyValueList(
          rows: [
            AppKeyValueRow(
              label: context.tr('payments.contractor.beneficiary'),
              value: details.beneficiaryName,
            ),
            AppKeyValueRow(
              label: context.tr('payments.contractor.bank'),
              value: details.bankName,
            ),
            AppKeyValueRow(
              label: context.tr('payments.contractor.iban'),
              value: PaymentFormat.iban(details.iban),
              isMonospace: true,
              isCopyable: true,
              copyValue: details.iban,
            ),
          ],
          onCopied: (_) =>
              context.showSnackBar(context.tr('payments.contractor.copied')),
        ),
      ],
    );
  }
}
