import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/inputs/app_checkbox.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/entities/client_task_payability.dart';

/// One task on «الدفع للمقاول» (GRA-50): a checkbox with the task's name and
/// amount. A task that can't be paid is greyed and can't be ticked, with
/// why under its name.
class ClientPaymentTaskRow extends StatelessWidget {
  const ClientPaymentTaskRow({
    required this.task,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final ClientPaymentTask task;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final payability = task.payability;
    final payable = payability == ClientTaskPayability.payable;
    final amount = task.amount;
    final reason = _reasonKey(payability);
    final style = AppTextStyles.label.copyWith(
      color: payable ? AppColors.ink : AppColors.textSecondary,
    );
    return AppCheckbox(
      value: selected,
      onChanged: payable ? onChanged : null,
      labelWidget: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(task.title, style: style)),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    amount == null
                        ? context.tr('payments.client.no_amount')
                        : AppMoneyText.format(context, amount),
                    textAlign: TextAlign.end,
                    style: style,
                  ),
                ),
              ],
            ),
            if (reason != null)
              Text(context.tr(reason), style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  static String? _reasonKey(
    ClientTaskPayability payability,
  ) => switch (payability) {
    ClientTaskPayability.payable => null,
    ClientTaskPayability.paid => 'payments.client.reason_paid',
    ClientTaskPayability.awaitingConfirmation =>
      'payments.client.reason_awaiting_contractor',
    ClientTaskPayability.notApproved => 'payments.client.reason_not_approved',
    ClientTaskPayability.noAmount => 'payments.client.reason_no_amount',
    ClientTaskPayability.unavailable => 'payments.client.reason_unavailable',
  };
}
