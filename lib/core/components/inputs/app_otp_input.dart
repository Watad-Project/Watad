import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as m_ui;
import 'package:pinput/pinput.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// A PIN / OTP input box row with auto-advance, backspace and paste support.
///
/// Wraps the third-party [Pinput] package (docs/APP_PACKAGES.md §3).
/// Features must not import `pinput` directly; they use this component.
class AppOtpInput extends StatelessWidget {
  const AppOtpInput({
    super.key,
    this.length = defaultLength,
    this.controller,
    this.focusNode,
    this.onCompleted,
    this.onChanged,
    this.validator,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
  });

  /// Supabase sends 6-digit email codes (its setting allows 6 to 10, never
  /// fewer), so 6 boxes unless a screen says otherwise.
  static const int defaultLength = 6;

  /// The number of boxes.
  final int length;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: AppSizes.controlHeight,
      height: AppSizes.controlHeight,
      textStyle: AppTextStyles.mono.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderStrong, width: 1.5),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.primary, width: 2),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: AppColors.errorLight,
        border: Border.all(color: AppColors.error, width: 1.5),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
    );

    Widget pinput = m_ui.Material(
      type: m_ui.MaterialType.transparency,
      child: Pinput(
        length: length,
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        autofocus: autofocus,
        defaultPinTheme: defaultPinTheme,
        focusedPinTheme: focusedPinTheme,
        submittedPinTheme: submittedPinTheme,
        errorPinTheme: errorPinTheme,
        forceErrorState: errorText != null,
        errorText: errorText,
        errorTextStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        validator: validator,
        onCompleted: onCompleted,
        onChanged: onChanged,
      ),
    );

    final ambientLocale =
        Localizations.maybeLocaleOf(context) ?? const Locale('en');
    if (Localizations.of<m_ui.MaterialLocalizations>(
          context,
          m_ui.MaterialLocalizations,
        ) ==
        null) {
      pinput = Localizations.override(
        context: context,
        locale: ambientLocale,
        delegates: const [_OtpMaterialLocalizationsDelegate()],
        child: pinput,
      );
    }

    return pinput;
  }
}

class _OtpMaterialLocalizationsDelegate
    extends LocalizationsDelegate<m_ui.MaterialLocalizations> {
  const _OtpMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<m_ui.MaterialLocalizations> load(Locale locale) =>
      m_ui.DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(_OtpMaterialLocalizationsDelegate old) => false;
}
