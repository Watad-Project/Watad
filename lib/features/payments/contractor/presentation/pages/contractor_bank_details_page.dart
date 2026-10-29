import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details_draft.dart';
import 'package:watad/features/payments/contractor/presentation/bloc/contractor_bank_details_bloc.dart';
import 'package:watad/features/payments/contractor/presentation/widgets/contractor_bank_details_form.dart';
import 'package:watad/features/payments/contractor/presentation/widgets/contractor_bank_details_summary.dart';
import 'package:watad/features/payments/shared/presentation/widgets/payment_format.dart';

/// «الحساب البنكي» (GRA-64): the account clients transfer their payments to.
/// On first use an empty form; once saved, the details with «تعديل», which
/// opens the form on them. «حفظ» stays off until the three fields are right
/// and something changed; afterwards the page shows what the server stored.
///
/// The `bank_details_missing` notification opens it.
class ContractorBankDetailsPage extends StatefulWidget {
  const ContractorBankDetailsPage({super.key});

  @override
  State<ContractorBankDetailsPage> createState() =>
      _ContractorBankDetailsPageState();
}

class _ContractorBankDetailsPageState extends State<ContractorBankDetailsPage> {
  final TextEditingController _beneficiaryName = TextEditingController();
  final TextEditingController _bankName = TextEditingController();
  final TextEditingController _iban = TextEditingController();

  @override
  void dispose() {
    _beneficiaryName.dispose();
    _bankName.dispose();
    _iban.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // The form opened: empty on first use, else on the saved details.
        BlocListener<ContractorBankDetailsBloc, ContractorBankDetailsState>(
          listenWhen: (previous, current) =>
              current.showsForm && !previous.showsForm,
          listener: (context, state) => _fill(state.saved),
        ),
        BlocListener<ContractorBankDetailsBloc, ContractorBankDetailsState>(
          listenWhen: (previous, current) =>
              current.message != null && current.message != previous.message,
          listener: _showMessage,
        ),
      ],
      child: BlocBuilder<ContractorBankDetailsBloc, ContractorBankDetailsState>(
        builder: (context, state) {
          final bloc = context.read<ContractorBankDetailsBloc>();
          final save = state.canSave
              ? () => bloc.add(const ContractorBankDetailsSubmitted())
              : null;
          return Scaffold(
            appBar: AppTopBar(
              title: context.tr('payments.contractor.bank_details_title'),
              onBack: () => context.pop(),
            ),
            body: AnimatedSwitcher(
              duration: AppMotion.enter,
              reverseDuration: AppMotion.exit,
              switchInCurve: AppMotion.enterCurve,
              switchOutCurve: AppMotion.exitCurve,
              child: switch (state) {
                ContractorBankDetailsState(
                  status: ContractorBankDetailsStatus.failure,
                  :final failure?,
                ) =>
                  AppErrorView(
                    key: const ValueKey('error'),
                    message: context.tr(failure.messageKey),
                    onRetry: () =>
                        bloc.add(const ContractorBankDetailsFetched()),
                  ),
                ContractorBankDetailsState(showsForm: true) =>
                  ContractorBankDetailsForm(
                    key: const ValueKey('form'),
                    beneficiaryNameController: _beneficiaryName,
                    bankNameController: _bankName,
                    ibanController: _iban,
                    onChanged: _onTyped,
                    beneficiaryNameError: state.beneficiaryNameError,
                    bankNameError: state.bankNameError,
                    ibanError: state.ibanError,
                    enabled: !state.isSaving,
                    onSubmitted: save,
                  ),
                ContractorBankDetailsState(
                  status: ContractorBankDetailsStatus.success,
                  :final saved?,
                ) =>
                  ContractorBankDetailsSummary(
                    key: const ValueKey('summary'),
                    details: saved,
                  ),
                _ => const AppLoadingIndicator(key: ValueKey('loading')),
              },
            ),
            bottomNavigationBar: switch (state) {
              ContractorBankDetailsState(showsForm: true) => AppActionBar(
                primary: AppButton(
                  key: const Key('contractor_bank_details_save'),
                  label: context.tr('payments.contractor.save'),
                  isLoading: state.isSaving,
                  onPressed: save,
                ),
                // Nothing to go back to on first use: the back arrow leaves.
                secondary: state.saved == null
                    ? null
                    : AppButton(
                        key: const Key('contractor_bank_details_cancel'),
                        label: context.tr('common.cancel'),
                        variant: AppButtonVariant.secondary,
                        onPressed: state.isSaving
                            ? null
                            : () => bloc.add(
                                const ContractorBankDetailsEditCancelled(),
                              ),
                      ),
              ),
              ContractorBankDetailsState(
                status: ContractorBankDetailsStatus.success,
                saved: != null,
              ) =>
                AppActionBar(
                  primary: AppButton(
                    key: const Key('contractor_bank_details_edit'),
                    label: context.tr('payments.contractor.edit'),
                    icon: Icons.edit_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () =>
                        bloc.add(const ContractorBankDetailsEditStarted()),
                  ),
                ),
              _ => null,
            },
          );
        },
      ),
    );
  }

  void _fill(ContractorBankDetails? saved) {
    _beneficiaryName.text = saved?.beneficiaryName ?? '';
    _bankName.text = saved?.bankName ?? '';
    _iban.text = saved == null ? '' : PaymentFormat.iban(saved.iban);
  }

  void _onTyped() => context.read<ContractorBankDetailsBloc>().add(
    ContractorBankDetailsChanged(
      ContractorBankDetailsDraft(
        beneficiaryName: _beneficiaryName.text,
        bankName: _bankName.text,
        iban: _iban.text,
      ),
    ),
  );

  void _showMessage(BuildContext context, ContractorBankDetailsState state) {
    final message = state.message;
    if (message == null) return;
    final text = context.tr(message.key);
    switch (message.kind) {
      case ContractorBankDetailsMessageKind.success:
        context.showSuccessSnackBar(text);
      case ContractorBankDetailsMessageKind.info:
        context.showSnackBar(text);
      case ContractorBankDetailsMessageKind.error:
        context.showErrorSnackBar(text);
    }
  }
}
