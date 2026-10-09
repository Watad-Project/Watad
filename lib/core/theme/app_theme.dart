import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// The Material theme of the app, built from the tokens in this folder.
///
/// The design sheet has no dark palette yet, so there is only [light].
abstract final class AppTheme {
  static final ThemeData light = _buildLight();

  static ThemeData _buildLight() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.ink,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.neutralLight,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.success,
      onTertiary: AppColors.white,
      tertiaryContainer: AppColors.successLight,
      onTertiaryContainer: AppColors.successDark,
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.textBody,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.surfaceMuted,
      surfaceContainer: AppColors.surfaceMuted,
      surfaceContainerHigh: AppColors.neutralLight,
      surfaceContainerHighest: AppColors.neutralLight,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.border,
      shadow: AppColors.ink,
      scrim: AppColors.ink,
      inverseSurface: AppColors.ink,
      onInverseSurface: AppColors.white,
      inversePrimary: AppColors.primaryLight,
      surfaceTint: Colors.transparent,
    );

    final textTheme = TextTheme(
      headlineSmall: AppTextStyles.h1,
      titleLarge: AppTextStyles.h1,
      titleMedium: AppTextStyles.h2,
      titleSmall: AppTextStyles.label,
      // bodyLarge is what text fields type in: ink, without the paragraph
      // line height.
      bodyLarge: AppTextStyles.body.copyWith(color: AppColors.ink, height: 1.4),
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.label,
      labelMedium: AppTextStyles.label.copyWith(fontSize: 14),
      labelSmall: AppTextStyles.labelSmall,
    );

    const controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
    );
    const controlSize = Size(AppSizes.minTapTarget, AppSizes.controlHeight);
    const controlPadding = EdgeInsets.symmetric(horizontal: AppSpacing.xl);

    OutlineInputBorder fieldBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.surface,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarThemeData(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.body.copyWith(height: 1.4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primaryDisabled,
          disabledForegroundColor: AppColors.white,
          minimumSize: controlSize,
          padding: controlPadding,
          shape: controlShape,
          textStyle: AppTextStyles.label,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.ink,
          disabledForegroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.borderStrong),
          minimumSize: controlSize,
          padding: controlPadding,
          shape: controlShape,
          textStyle: AppTextStyles.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.square(AppSizes.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          textStyle: AppTextStyles.label,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        hintStyle: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        helperStyle: AppTextStyles.caption,
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        border: fieldBorder(AppColors.borderStrong),
        enabledBorder: fieldBorder(AppColors.borderStrong),
        disabledBorder: fieldBorder(AppColors.border),
        focusedBorder: fieldBorder(AppColors.ink, 1.5),
        errorBorder: fieldBorder(AppColors.error),
        focusedErrorBorder: fieldBorder(AppColors.error, 1.5),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.ink
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.white),
        side: const BorderSide(color: AppColors.controlBorder, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xs)),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.controlBorder,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.controlOff,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.label,
        unselectedLabelStyle: AppTextStyles.label.copyWith(
          fontWeight: FontWeight.w400,
        ),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.border,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.track,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w400,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTextStyles.body.copyWith(
          color: AppColors.white,
          height: 1.5,
        ),
        actionTextColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
        ),
        titleTextStyle: AppTextStyles.h2,
        contentTextStyle: AppTextStyles.body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.track,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
    );
  }
}
