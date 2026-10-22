import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_project_card.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';

class ContractorContractCard extends StatelessWidget {
  const ContractorContractCard({required this.contract, this.onTap, super.key});

  final ContractorContractProject contract;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final currency = context.tr('work.contractor.currency');

    final (statusKey, statusTone) = switch ((
      contract.isCompleted,
      contract.hasTaskWaitingForClient,
    )) {
      (true, _) => (
        'work.contractor.contract_status_completed',
        AppTone.success,
      ),
      (false, true) => (
        'work.contractor.contract_status_waiting_client',
        AppTone.attention,
      ),
      (false, false) => (
        'work.contractor.contract_status_in_progress',
        AppTone.success,
      ),
    };

    final agreedOrBudget = contract.contractMoney;
    final contractAmountText = agreedOrBudget != null
        ? context.tr(
            'work.contractor.contract_amount_label',
            namedArgs: {
              'amount': '${agreedOrBudget.toJson()}',
              'currency': currency,
            },
          )
        : context.tr('work.contractor.budget_unspecified');

    final receivedAmountText = context.tr(
      'work.contractor.received_amount_label',
      namedArgs: {
        'amount': '${contract.totalPaid.toJson()}',
        'currency': currency,
      },
    );

    return AppProjectCard(
      title: contract.title,
      subtitle: context.tr(
        'work.contractor.client_label',
        namedArgs: {'name': contract.ownerName},
      ),
      statusLabel: context.tr(statusKey),
      statusTone: statusTone,
      progress: contract.progress,
      progressLabel: context.tr(
        'work.contractor.contract_tasks_progress',
        namedArgs: {
          'approved': '${contract.approvedTasksCount}',
          'total': '${contract.totalTasksCount}',
        },
      ),
      percentLabel: '${contract.progressPercent}%',
      dateLabel: receivedAmountText,
      amountLabel: contractAmountText,
      onTap: onTap,
    );
  }
}
