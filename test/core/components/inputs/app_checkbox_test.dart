import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/inputs/app_checkbox.dart';

import '../../../helpers/pump_component.dart';

void main() {
  const label = 'أوافق على الشروط وسياسة الخصوصية';

  testWidgets('toggles from the box and from the label', (tester) async {
    final values = <bool>[];
    await pumpComponent(
      tester,
      AppCheckbox(value: false, label: label, onChanged: values.add),
    );

    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.text(label));
    expect(values, [true, true]);
  });

  testWidgets('ignores taps when disabled', (tester) async {
    await pumpComponent(
      tester,
      const AppCheckbox(value: false, label: label, onChanged: null),
    );

    await tester.tap(find.text(label));
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.onChanged, isNull);
  });
}
