import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// A text input with a label above it, a hint, a helper line and an error.
///
/// Validation works with a `Form` through [validator], or by passing
/// [errorText] directly. Set [isMonospace] for values people read digit by
/// digit (commercial registration, IBAN): they are typed left to right in
/// IBM Plex Mono, also in Arabic.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.isRequired = false,
    this.controller,
    this.initialValue,
    this.hint,
    this.helperText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.minLines,
    this.maxLines = 1,
    this.isMonospace = false,
    this.enabled = true,
    this.obscureText = false,
    this.focusNode,
  });

  final String? label;

  /// Shows "Required" at the end of the label.
  final bool isRequired;

  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;

  /// A short note under the field, e.g. "10 digits".
  final String? helperText;

  final String? errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? minLines;
  final int? maxLines;
  final bool isMonospace;
  final bool enabled;
  final bool obscureText;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // A left-to-right value sits at the start of the field in either
    // language: on the right in Arabic, on the left in English.
    final monoAlign = isRtl ? TextAlign.end : TextAlign.start;
    final field = TextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      minLines: minLines,
      maxLines: obscureText ? 1 : maxLines,
      validator: validator,
      onChanged: onChanged,
      style: isMonospace ? AppTextStyles.mono : null,
      textDirection: isMonospace ? TextDirection.ltr : null,
      textAlign: isMonospace ? monoAlign : TextAlign.start,
      decoration: InputDecoration(
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        hintStyle: isMonospace
            ? AppTextStyles.mono.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              )
            : null,
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
}
