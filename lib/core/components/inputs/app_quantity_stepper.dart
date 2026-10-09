import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// A number with − and + buttons, e.g. a quantity in the cart.
///
/// The buttons stop at [min] and [max].
class AppQuantityStepper extends StatelessWidget {
  const AppQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.decreaseTooltip,
    this.increaseTooltip,
    this.min = 0,
    this.max,
    this.step = 1,
    this.valueLabel,
  });

  final int value;

  /// Null disables both buttons.
  final ValueChanged<int>? onChanged;

  /// What screen readers say for −. Defaults to "Decrease".
  final String? decreaseTooltip;

  /// What screen readers say for +. Defaults to "Increase".
  final String? increaseTooltip;
  final int min;
  final int? max;
  final int step;

  /// Shown instead of [value], e.g. the number in Arabic-Indic digits.
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    final canDecrease = onChanged != null && value - step >= min;
    final canIncrease =
        onChanged != null && (max == null || value + step <= max!);
    return Container(
      height: AppSizes.controlHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(
            Icons.add,
            increaseTooltip ?? context.tr('common.increase'),
            canIncrease ? () => onChanged!(value + step) : null,
          ),
          const VerticalDivider(width: 1, color: AppColors.borderStrong),
          SizedBox(
            width: 64,
            child: Text(
              valueLabel ?? '$value',
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(fontSize: 18),
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.borderStrong),
          _button(
            Icons.remove,
            decreaseTooltip ?? context.tr('common.decrease'),
            canDecrease ? () => onChanged!(value - step) : null,
          ),
        ],
      ),
    );
  }

  Widget _button(IconData icon, String tooltip, VoidCallback? onPressed) {
    return SizedBox.square(
      dimension: AppSizes.controlHeight - 2,
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        color: AppColors.ink,
        disabledColor: AppColors.controlBorder,
        onPressed: onPressed,
      ),
    );
  }
}
