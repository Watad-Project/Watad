import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_theme.dart';

void main() {
  final theme = AppTheme.light;

  test('the color scheme uses the colors of the design sheet', () {
    final scheme = theme.colorScheme;
    expect(scheme.brightness, Brightness.light);
    expect(scheme.primary, const Color(0xFFE8722C));
    expect(scheme.onSurface, const Color(0xFF1C1A18));
    expect(scheme.onSurfaceVariant, const Color(0xFF6B645E));
    expect(scheme.primaryContainer, const Color(0xFFFFF6F0));
    expect(scheme.tertiaryContainer, const Color(0xFFF4F7F5));
    expect(scheme.errorContainer, const Color(0xFFFDF3F2));
    expect(theme.scaffoldBackgroundColor, AppColors.surface);
  });

  test('the type scale is the design sheet scaled by 4/3', () {
    expect(AppTextStyles.h1.fontSize, 24);
    expect(AppTextStyles.h1.fontWeight, FontWeight.w700);
    expect(AppTextStyles.h2.fontSize, 18);
    expect(AppTextStyles.h2.fontWeight, FontWeight.w600);
    expect(AppTextStyles.body.fontSize, 16);
    expect(AppTextStyles.body.height, 1.7);
    expect(AppTextStyles.caption.fontSize, 14);
    expect(AppTextStyles.mono.fontFamily, AppTextStyles.monoFontFamily);
  });

  test('every text theme style uses IBM Plex Sans Arabic', () {
    final textTheme = theme.textTheme;
    final styles = [
      textTheme.displayLarge,
      textTheme.headlineSmall,
      textTheme.titleMedium,
      textTheme.bodyLarge,
      textTheme.bodyMedium,
      textTheme.bodySmall,
      textTheme.labelLarge,
    ];
    for (final style in styles) {
      expect(style?.fontFamily, AppTextStyles.fontFamily);
    }
    expect(textTheme.headlineSmall?.fontSize, AppTextStyles.h1.fontSize);
    expect(textTheme.bodyMedium?.color, AppColors.textBody);
  });

  testWidgets('a filled button is orange and as tall as a control', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: FilledButton(onPressed: () {}, child: const Text('OK')),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(FilledButton)).height,
      AppSizes.controlHeight,
    );
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.primary);
  });

  testWidgets('a disabled filled button uses the disabled orange', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Center(child: FilledButton(onPressed: null, child: Text('OK'))),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.primaryDisabled);
  });
}
