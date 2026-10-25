import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_popup.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_selection.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt.dart';
import 'package:watad/features/payments/client/presentation/bloc/client_bank_transfer_bloc.dart';
import 'package:watad/features/payments/client/presentation/widgets/client_bank_transfer_details.dart';
import 'package:watad/features/payments/client/presentation/widgets/client_receipt_source_sheet.dart';

/// «تحويل بنكي» (GRA-52): the client pays the contractor from their own bank
/// app, then sends the receipt here: a PDF, or a photo (JPEG or PNG).
/// «إرسال الإيصال للمقاول» sends it for each selected task's payment stage.
/// Once it went for all of them, this page and the task selection close,
/// back to the timeline.
class ClientBankTransferPage extends StatelessWidget {
  const ClientBankTransferPage({required this.selection, super.key});

  final ClientPaymentSelection selection;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientBankTransferBloc, ClientBankTransferState>(
      listenWhen: (previous, current) =>
          (current.isSent && !previous.isSent) ||
          (current.message != null && current.message != previous.message),
      listener: (context, state) {
        if (state.isSent) {
          context.showSuccessSnackBar(context.tr('payments.client.sent'));
          // The task selection, which opened this page, closes too.
          context.pop(true);
        } else if (state.message case final message?) {
          if (message.isError) {
            context.showErrorSnackBar(context.tr(message.key));
          } else {
            context.showSnackBar(context.tr(message.key));
          }
        }
      },
      builder: (context, state) {
        final bloc = context.read<ClientBankTransferBloc>();
        final transfer = state.transfer;
        final canPay =
            transfer != null &&
            transfer.tasks.isNotEmpty &&
            transfer.bankDetails != null;
        return Scaffold(
          appBar: AppTopBar(
            title: context.tr('payments.client.transfer_title'),
            onBack: () => context.pop(),
          ),
          body: AnimatedSwitcher(
            duration: AppMotion.enter,
            reverseDuration: AppMotion.exit,
            switchInCurve: AppMotion.enterCurve,
            switchOutCurve: AppMotion.exitCurve,
            child: transfer != null
                ? ClientBankTransferDetails(
                    key: const ValueKey('transfer'),
                    transfer: transfer,
                    receipt: state.receipt,
                    outcome: state.outcome,
                    onPickReceipt: state.isSending
                        ? null
                        : () => _chooseReceipt(context),
                  )
                : state.status == ClientBankTransferStatus.failure
                ? AppErrorView(
                    key: const ValueKey('error'),
                    message: context.tr(state.failure!.messageKey),
                    onRetry: () =>
                        bloc.add(ClientBankTransferFetched(selection)),
                  )
                : const AppLoadingIndicator(key: ValueKey('loading')),
          ),
          bottomNavigationBar: canPay
              ? AppActionBar(
                  primary: AppButton(
                    key: const Key('client_bank_transfer_send'),
                    label: context.tr(
                      state.outcome == null
                          ? 'payments.client.send'
                          : 'payments.client.send_rest',
                    ),
                    isLoading: state.isSending,
                    onPressed: state.canSend
                        ? () => bloc.add(const ClientBankTransferSubmitted())
                        : null,
                  ),
                )
              : null,
        );
      },
    );
  }

  /// The receipt box: a file or a photo, chosen in the app's sheet.
  void _chooseReceipt(BuildContext context) {
    final bloc = context.read<ClientBankTransferBloc>();
    Future<void> pick(Future<ClientReceipt?> Function() picker) async {
      final ClientReceipt? receipt;
      try {
        receipt = await picker();
      } on Exception {
        // E.g. the phone refused access to the photos.
        if (context.mounted) {
          context.showErrorSnackBar(context.tr('errors.unknown'));
        }
        return;
      }
      if (receipt != null) bloc.add(ClientBankTransferReceiptPicked(receipt));
    }

    AppPopup.sheet<void>(
      context,
      builder: (_) => ClientReceiptSourceSheet(
        onPickFile: () => pick(_pickFile),
        onPickPhoto: () => pick(_pickPhoto),
      ),
    );
  }

  /// A PDF, JPEG or PNG file, as the `bank-transfer-receipts` bucket takes.
  static Future<ClientReceipt?> _pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ClientReceipt.extensions,
    );
    if (file == null) return null;
    return ClientReceipt(bytes: await file.readAsBytes(), name: file.name);
  }

  /// A photo from the gallery, e.g. a screenshot of the bank app. With a
  /// quality set, the picker saves it again: JPEG and PNG stay as they are,
  /// and an iPhone's HEIC photo becomes a JPEG. Anything else (a GIF) is
  /// refused with a clear message when it's attached.
  static Future<ClientReceipt?> _pickPhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (photo == null) return null;
    return ClientReceipt(bytes: await photo.readAsBytes(), name: photo.name);
  }
}
