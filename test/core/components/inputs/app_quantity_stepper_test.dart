import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/inputs/app_quantity_stepper.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('increases and decreases by the step, with translated tooltips', (
    tester,
  ) async {
    final values = <int>[];
    await pumpComponent(
      tester,
      AppQuantityStepper(value: 20, step: 5, onChanged: values.add),
    );

    expect(find.text('20'), findsOneWidget);
    await tester.tap(find.byTooltip('زيادة'));
    await tester.tap(find.byTooltip('إنقاص'));
    expect(values, [25, 15]);
  });

  testWidgets('stops at min and max', (tester) async {
    final values = <int>[];
    await pumpComponent(
      tester,
      AppQuantityStepper(value: 1, min: 1, max: 1, onChanged: values.add),
    );

    await tester.tap(find.byTooltip('زيادة'));
    await tester.tap(find.byTooltip('إنقاص'));
    expect(values, isEmpty);
  });

  testWidgets('shows valueLabel instead of the number', (tester) async {
    await pumpComponent(
      tester,
      AppQuantityStepper(value: 20, valueLabel: '٢٠', onChanged: (_) {}),
    );

    expect(find.text('٢٠'), findsOneWidget);
  });
}
