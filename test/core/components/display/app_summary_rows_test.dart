import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_summary_rows.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the rows and the total under a divider', (tester) async {
    await pumpComponent(
      tester,
      const AppSummaryRows(
        rows: [
          AppSummaryRow(label: 'المجموع الفرعي', value: '٥٨٬٥٠٠ ر.س'),
          AppSummaryRow(label: 'ضريبة القيمة المضافة ١٥٪', value: '٨٬٨٢٠ ر.س'),
        ],
        total: AppSummaryRow(label: 'الإجمالي', value: '٦٧٬٦٢٠ ر.س'),
      ),
    );

    for (final text in [
      'المجموع الفرعي',
      '٨٬٨٢٠ ر.س',
      'الإجمالي',
      '٦٧٬٦٢٠ ر.س',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('has no divider without a total', (tester) async {
    await pumpComponent(
      tester,
      const AppSummaryRows(
        rows: [AppSummaryRow(label: 'المجموع', value: '١ ر.س')],
      ),
    );

    expect(find.byType(Divider), findsNothing);
  });
}
