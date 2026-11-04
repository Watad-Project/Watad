import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_logo.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_demo_note.dart';

/// The Apple Pay / STC Pay confirmation, in Watad's own design (never a copy
/// of their screens or logos): the amount, the method, «تأكيد الدفع».
/// Returns true when confirmed.
class MarketplaceWalletSheet extends StatelessWidget {
  const MarketplaceWalletSheet({
    required this.method,
    required this.amount,
    super.key,
  });

  final PaymentMethod method;
  final Money amount;

  @override
  Widget build(BuildContext context) {
    final methodLabel = context.tr(
      'marketplace.payment_methods.${method.value}',
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: AppLogo(height: 40)),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.tr(
                'marketplace.payment.wallet_title',
                args: [methodLabel],
              ),
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(child: AppMoneyText(amount, style: AppTextStyles.h1)),
            const SizedBox(height: AppSpacing.md),
            const MarketplaceDemoNote(),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const Key('payment_wallet_confirm'),
              label: context.tr('marketplace.payment.wallet_confirm'),
              icon: Icons.lock_outline,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: context.tr('common.cancel'),
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
