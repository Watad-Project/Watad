import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// A calendar-day picker field styled like `AppTextField`, with a label above
/// it, a hint, a helper line, an error line, and an optional clear button when
/// a date is chosen.
///
/// The chosen date is normalized to UTC midnight (`DateTime.utc(y, m, d)`) so
/// time-zone conversions never shift the calendar day.
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    this.label,
    this.isRequired = false,
    this.value,
    this.valueLabel,
    this.hint,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.onChanged,
  });

  final String? label;
  final bool isRequired;
  final DateTime? value;

  /// Optional pre-formatted text for [value]. When omitted, [value] is
  /// formatted with `DateFormat.yMMMd` in the current app locale.
  final String? valueLabel;

  final String? hint;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;
  final ValueChanged<DateTime?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final canInteract = enabled && onChanged != null;
    final hasValue = value != null;
    final displayText = hasValue
        ? (valueLabel ?? _formatDate(context, value!))
        : (hint ?? '');

    final field = Semantics(
      button: true,
      enabled: canInteract,
      child: InkWell(
        onTap: canInteract ? () => _pickDate(context) : null,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: InputDecorator(
            isEmpty: !hasValue && (hint == null || hint!.isEmpty),
            decoration: InputDecoration(
              helperText: helperText,
              helperMaxLines: 3,
              errorText: errorText,
              errorMaxLines: 3,
              enabled: enabled,
              suffixIcon: hasValue && canInteract
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: context.tr('common.delete'),
                      onPressed: () => onChanged?.call(null),
                    )
                  : const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
            ),
            child: Text(
              displayText,
              style: AppTextStyles.body.copyWith(
                color: hasValue ? AppColors.ink : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );

    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFieldLabel(label: label!, isRequired: isRequired),
        const SizedBox(height: AppSpacing.xs),
        field,
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final minDate = firstDate ?? DateTime(now.year - 5, 1, 1);
    final maxDate = lastDate ?? DateTime(now.year + 10, 12, 31);
    final rawInitial = value ?? initialDate ?? now;
    var effectiveInitial = DateTime(
      rawInitial.year,
      rawInitial.month,
      rawInitial.day,
    );
    if (effectiveInitial.isBefore(minDate)) {
      effectiveInitial = minDate;
    } else if (effectiveInitial.isAfter(maxDate)) {
      effectiveInitial = maxDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: effectiveInitial,
      firstDate: minDate,
      lastDate: maxDate,
    );
    if (picked != null) {
      onChanged?.call(DateTime.utc(picked.year, picked.month, picked.day));
    }
  }

  static String _formatDate(BuildContext context, DateTime date) {
    final locale = context.isArabic
        ? AppLocalization.arabic.languageCode
        : AppLocalization.english.languageCode;
    return DateFormat.yMMMd(locale).format(date);
  }
}
