import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// The bank details form (GRA-64): why clients need it, then the
/// beneficiary, the bank and the IBAN. A field's problem shows under it.
/// The IBAN is typed left to right, in mono, and takes what people paste:
/// spaces, dashes and Arabic digits are cleaned when it's checked.
class ContractorBankDetailsForm extends StatelessWidget {
  const ContractorBankDetailsForm({
    required this.beneficiaryNameController,
    required this.bankNameController,
    required this.ibanController,
    required this.onChanged,
    this.beneficiaryNameError,
    this.bankNameError,
    this.ibanError,
    this.enabled = true,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController beneficiaryNameController;
  final TextEditingController bankNameController;
  final TextEditingController ibanController;

  /// Any of the three fields changed.
  final VoidCallback onChanged;

  /// `validation.*` keys; null when the field is fine.
  final String? beneficiaryNameError;
  final String? bankNameError;
  final String? ibanError;
  final bool enabled;

  /// The keyboard's done key on the IBAN; null while «حفظ» is off.
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    String? errorOf(String? key) => key == null ? null : context.tr(key);
    final onSubmitted = this.onSubmitted;
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Text(
          context.tr('payments.contractor.form_intro'),
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          key: const Key('contractor_bank_details_beneficiary'),
          label: context.tr('payments.contractor.beneficiary'),
          isRequired: true,
          controller: beneficiaryNameController,
          hint: context.tr('payments.contractor.beneficiary_hint'),
          errorText: errorOf(beneficiaryNameError),
          textInputAction: TextInputAction.next,
          enabled: enabled,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const Key('contractor_bank_details_bank'),
          label: context.tr('payments.contractor.bank'),
          isRequired: true,
          controller: bankNameController,
          hint: context.tr('payments.contractor.bank_hint'),
          errorText: errorOf(bankNameError),
          textInputAction: TextInputAction.next,
          enabled: enabled,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const Key('contractor_bank_details_iban'),
          label: context.tr('payments.contractor.iban'),
          isRequired: true,
          controller: ibanController,
          hint: context.tr('payments.contractor.iban_hint'),
          helperText: context.tr('payments.contractor.iban_helper'),
          errorText: errorOf(ibanError),
          isMonospace: true,
          textInputAction: TextInputAction.done,
          enabled: enabled,
          onChanged: (_) => onChanged(),
          onSubmitted: onSubmitted == null ? null : (_) => onSubmitted(),
        ),
      ],
    );
  }
}
