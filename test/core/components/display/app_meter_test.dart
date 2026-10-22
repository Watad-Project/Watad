import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_meter.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the share in words and fills the bar that far', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const AppMeter(
        label: 'معروضة الآن',
        valueLabel: '٥٨٨ من ٦٤٠، ٩٢٪',
        fraction: 0.92,
      ),
    );

    expect(find.text('معروضة الآن'), findsOneWidget);
    expect(find.text('٥٨٨ من ٦٤٠، ٩٢٪'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.92);
  });

  testWidgets('keeps the bar between empty and full', (tester) async {
    await pumpComponent(
      tester,
      const AppMeter(label: 'x', valueLabel: 'y', fraction: 1.4),
    );

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 1);
  });

  testWidgets('fits large bold text', (tester) async {
    await pumpLocalizedApp(
      tester,
      const Scaffold(
        body: AppMeter(
          label: 'المنشآت الموثّقة',
          valueLabel: '٢١٢ من ٢٦٠',
          fraction: 0.8,
        ),
      ),
      textScale: largeTextScale,
      boldText: true,
    );

    expect(tester.takeException(), isNull);
  });
}
