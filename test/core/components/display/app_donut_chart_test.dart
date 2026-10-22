import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_donut_chart.dart';
import 'package:watad/core/theme/app_colors.dart';

import '../../../helpers/pump_component.dart';

void main() {
  const slices = [
    AppDonutSlice(label: 'مسودة', value: 31, valueLabel: '٣١، ٧٪'),
    AppDonutSlice(label: 'مفتوح', value: 57, valueLabel: '٥٧، ١٤٪'),
    AppDonutSlice(label: 'ملغي', value: 0, valueLabel: '٠، ٠٪'),
  ];

  testWidgets('names every slice with its number, and the total', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const AppDonutChart(
        slices: slices,
        centerValue: '٨٨',
        centerLabel: 'المشاريع',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('٨٨'), findsOneWidget);
    expect(find.text('المشاريع'), findsOneWidget);
    for (final slice in slices) {
      expect(find.text(slice.label), findsOneWidget);
      expect(find.text(slice.valueLabel), findsOneWidget);
    }
  });

  testWidgets('each legend square wears its slice color, in order', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const AppDonutChart(slices: slices, centerValue: '٨٨', centerLabel: ''),
    );
    await tester.pumpAndSettle();

    final squares = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .map((decoration) => decoration.color)
        .where(AppChartColors.series.contains)
        .toList();
    expect(squares, AppChartColors.series.take(slices.length).toList());
  });

  testWidgets('a whole of zero still draws, and fits large bold text', (
    tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      const Scaffold(
        body: SingleChildScrollView(
          child: AppDonutChart(
            slices: [
              AppDonutSlice(label: 'العملاء', value: 0, valueLabel: '٠، ٠٪'),
              AppDonutSlice(label: 'المنشآت', value: 0, valueLabel: '٠، ٠٪'),
            ],
            centerValue: '٠',
            centerLabel: 'المستخدمون',
          ),
        ),
      ),
      textScale: largeTextScale,
      boldText: true,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
