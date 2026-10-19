import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/utils/money.dart';

/// An amount in SAR, written for the app's language: «٤٦٥٬٠٠٠ ر.س» in
/// Arabic, "465,000 SAR" in English. Halalas show only when there are any.
///
/// The number is in [style] and the currency smaller after it. Inside other
/// text, use [AppMoneyText.format].
class AppMoneyText extends StatelessWidget {
  const AppMoneyText(this.money, {this.style, super.key});

  final Money money;

  /// The number's style; [AppTextStyles.h2] by default.
  final TextStyle? style;

  /// [money] as one string, e.g. for «الميزانية المعلنة ٤٥٠٬٠٠٠ ر.س».
  static String format(BuildContext context, Money money) =>
      context.tr('common.sar_amount', args: [_number(context, money)]);

  static String _number(BuildContext context, Money money) => context
      .formatNumber(money.sar, decimals: money.halalas % 100 == 0 ? 0 : 2);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: _number(context, money),
            style: style ?? AppTextStyles.h2,
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: context.tr('common.sar'),
            style: AppTextStyles.caption.copyWith(color: AppColors.textBody),
          ),
        ],
      ),
      semanticsLabel: format(context, money),
    );
  }
}
