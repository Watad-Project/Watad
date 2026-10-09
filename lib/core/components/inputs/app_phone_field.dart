import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// A Saudi mobile number input: the fixed +966 code and 9 digits, grouped
/// as "5x xxx xxxx" while typing.
///
/// Arabic-Indic digits are turned into 0-9. The controller holds the grouped
/// text; [fullNumber] turns it into "+9665xxxxxxxx".
class AppPhoneField extends StatelessWidget {
  const AppPhoneField({
    super.key,
    this.label,
    this.requiredLabel,
    this.controller,
    this.hint,
    this.helperText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.enabled = true,
  });

  static const String countryCode = '+966';

  /// The number in international form, or null when it does not have
  /// 9 digits starting with 5.
  static String? fullNumber(String text) {
    final digits = _latinDigits(text);
    if (!RegExp(r'^5\d{8}$').hasMatch(digits)) return null;
    return '$countryCode$digits';
  }

  final String? label;
  final String? requiredLabel;
  final TextEditingController? controller;

  /// A sample number, e.g. "5x xxx xxxx".
  final String? hint;
  final String? helperText;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final code = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          if (isRtl) const _Divider(),
          if (isRtl) const SizedBox(width: AppSpacing.sm),
          Text(
            countryCode,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.mono.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (!isRtl) const SizedBox(width: AppSpacing.sm),
          if (!isRtl) const _Divider(),
        ],
      ),
    );
    // The number is always typed left to right, at the left of the field.
    // The country code is the field's prefix, which follows the screen's
    // direction: on the right in Arabic (as in the design), on the left in
    // English.
    final field = TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      inputFormatters: [_SaudiMobileFormatter()],
      validator: validator,
      onChanged: onChanged,
      style: AppTextStyles.mono,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        hintText: hint,
        hintTextDirection: TextDirection.ltr,
        hintStyle: AppTextStyles.mono.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        helperText: helperText,
        errorText: errorText,
        prefixIcon: code,
      ),
    );
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFieldLabel(label: label!, requiredLabel: requiredLabel),
        const SizedBox(height: AppSpacing.xs),
        field,
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 24,
      child: VerticalDivider(width: 1, color: AppColors.borderStrong),
    );
  }
}

/// Turns Arabic-Indic and Persian digits into 0-9 and drops everything else.
String _latinDigits(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    if (rune >= 0x30 && rune <= 0x39) {
      buffer.writeCharCode(rune);
    } else if (rune >= 0x660 && rune <= 0x669) {
      buffer.writeCharCode(rune - 0x660 + 0x30);
    } else if (rune >= 0x6F0 && rune <= 0x6F9) {
      buffer.writeCharCode(rune - 0x6F0 + 0x30);
    }
  }
  return buffer.toString();
}

class _SaudiMobileFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = _latinDigits(newValue.text);
    if (digits.length > 9) digits = digits.substring(0, 9);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
