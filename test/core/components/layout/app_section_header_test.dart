import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/theme/app_theme.dart';

void main() {
  Future<void> pumpHeader(WidgetTester tester, AppSectionHeader header) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: header),
        ),
      ),
    );
  }

  testWidgets('shows title without action when action is omitted', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      const AppSectionHeader(title: 'المشاريع قيد التنفيذ'),
    );

    expect(find.text('المشاريع قيد التنفيذ'), findsOneWidget);
    expect(find.byType(AppButton), findsNothing);
  });

  testWidgets(
    'shows action button and triggers onAction callback when tapped',
    (tester) async {
      var tapped = false;
      await pumpHeader(
        tester,
        AppSectionHeader(
          title: 'عروضي المقدّمة',
          actionLabel: 'الكل',
          onAction: () => tapped = true,
        ),
      );

      expect(find.text('عروضي المقدّمة'), findsOneWidget);
      expect(find.text('الكل'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);

      await tester.tap(find.text('الكل'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    },
  );
}
