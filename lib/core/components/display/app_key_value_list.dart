// intl (re-exported by easy_localization) has its own TextDirection.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// One line of an [AppKeyValueList].
class AppKeyValueRow {
  const AppKeyValueRow({
    required this.label,
    required this.value,
    this.isMonospace = false,
    this.isCopyable = false,
    this.copyValue,
  });

  final String label;
  final String value;

  /// For values read digit by digit (IBAN, phone): mono, left to right.
  final bool isMonospace;

  /// Shows "Copy" at the end of the line.
  final bool isCopyable;

  /// What is copied, when it differs from [value] (e.g. without spaces).
  final String? copyValue;
}

/// Label-value lines in a quiet panel, e.g. the bank transfer details:
/// beneficiary, IBAN (with copy), amount.
class AppKeyValueList extends StatelessWidget {
  const AppKeyValueList({super.key, required this.rows, this.onCopied});

  final List<AppKeyValueRow> rows;

  /// Called after a value was copied, e.g. to show a snack bar.
  final ValueChanged<String>? onCopied;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(),
            _line(context, rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _line(BuildContext context, AppKeyValueRow row) {
    final showCopy = row.isCopyable;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.md,
          end: showCopy ? AppSpacing.xxs : AppSpacing.md,
        ),
        child: Row(
          children: [
            Text(row.label, style: AppTextStyles.caption),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: row.isMonospace
                    // An IBAN stays on one line: it shrinks rather than wraps.
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          row.value,
                          maxLines: 1,
                          textDirection: TextDirection.ltr,
                          style: AppTextStyles.mono.copyWith(fontSize: 14),
                        ),
                      )
                    : Text(
                        row.value,
                        textAlign: TextAlign.end,
                        style: AppTextStyles.label.copyWith(fontSize: 15),
                      ),
              ),
            ),
            if (showCopy)
              TextButton(
                onPressed: () => _copy(row),
                style: TextButton.styleFrom(
                  textStyle: AppTextStyles.label.copyWith(fontSize: 14),
                ),
                child: Text(context.tr('common.copy')),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(AppKeyValueRow row) async {
    final text = row.copyValue ?? row.value;
    await Clipboard.setData(ClipboardData(text: text));
    onCopied?.call(text);
  }
}
