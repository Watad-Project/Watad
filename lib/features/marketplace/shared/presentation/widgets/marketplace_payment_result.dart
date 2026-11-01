import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';

/// How the payment ended: paid (the order number, the amount and
/// «عرض الطلب»), declined, or another failure («حاول مرة أخرى»).
class MarketplacePaymentResult extends StatelessWidget {
  const MarketplacePaymentResult({
    required this.order,
    required this.isSuccess,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onBack,
    super.key,
  });

  final MarketplaceOrder order;
  final bool isSuccess;
  final String title;
  final String message;
  final String primaryLabel;

  /// Null keeps the button off.
  final VoidCallback? onPrimary;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.lg),
        Icon(
          isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 72,
          color: isSuccess ? AppColors.success : AppColors.error,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: AppTextStyles.h1, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        AppKeyValueList(
          rows: [
            AppKeyValueRow(
              label: context.tr('marketplace.payment.order_number'),
              value: order.number,
              isMonospace: true,
            ),
            AppKeyValueRow(
              label: context.tr('marketplace.payment.amount'),
              value: AppMoneyText.format(context, order.total),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          key: const Key('payment_result_primary'),
          label: primaryLabel,
          onPressed: onPrimary,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          key: const Key('payment_result_back'),
          label: context.tr('marketplace.payment.back'),
          variant: AppButtonVariant.secondary,
          onPressed: onBack,
        ),
      ],
    );
  }
}
