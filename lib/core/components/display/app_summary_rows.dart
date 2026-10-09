import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// One line of an [AppSummaryRows].
class AppSummaryRow {
  const AppSummaryRow({required this.label, required this.value});

  final String label;

  /// Formatted, e.g. an amount through `Money`.
  final String value;
}

/// Label-value lines of a bill (subtotal, VAT 15%) and, under a divider, the
/// total in bold. Used in the cart, checkout, refunds and stage payments.
class AppSummaryRows extends StatelessWidget {
  const AppSummaryRows({super.key, required this.rows, this.total});

  final List<AppSummaryRow> rows;
  final AppSummaryRow? total;

  @override
  Widget build(BuildContext context) {
    final rowStyle = AppTextStyles.body.copyWith(height: 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              children: [
                Expanded(child: Text(row.label, style: rowStyle)),
                Text(row.value, style: rowStyle),
              ],
            ),
          ),
        if (total != null) ...[
          const Divider(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: Text(total!.label, style: AppTextStyles.h2)),
              Text(
                total!.value,
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
