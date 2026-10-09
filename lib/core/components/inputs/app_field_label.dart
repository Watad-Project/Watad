import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// The label above a field, with an optional red "required" mark at the end.
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel({super.key, required this.label, this.requiredLabel});

  final String label;

  /// The translated word for "required". Shown only when not null.
  final String? requiredLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.label.copyWith(fontSize: 14)),
        ),
        if (requiredLabel != null)
          Text(
            requiredLabel!,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
          ),
      ],
    );
  }
}
