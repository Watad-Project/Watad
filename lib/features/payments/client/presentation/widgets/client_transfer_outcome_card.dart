import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_transfer_outcome.dart';

/// After a sending that stopped part way (GRA-52): the tasks the receipt
/// went for, and the ones it didn't, one per line. Sending again sends only
/// the rest.
class ClientTransferOutcomeCard extends StatelessWidget {
  const ClientTransferOutcomeCard({required this.outcome, super.key});

  final ClientBankTransferOutcome outcome;

  @override
  Widget build(BuildContext context) {
    return AppStatusCard(
      tone: AppTone.danger,
      title: context.tr('payments.client.partial_title'),
      subtitle: [
        if (outcome.sent.isNotEmpty) ...[
          context.tr('payments.client.partial_sent'),
          for (final task in outcome.sent) task.title,
        ],
        context.tr('payments.client.partial_not_sent'),
        for (final task in outcome.notSent) task.title,
      ].join('\n'),
    );
  }
}
