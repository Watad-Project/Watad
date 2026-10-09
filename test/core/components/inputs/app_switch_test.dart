import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/inputs/app_switch.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('toggles when the switch is tapped', (tester) async {
    bool? value;
    await pumpComponent(
      tester,
      AppSwitch(value: false, onChanged: (v) => value = v),
    );

    await tester.tap(find.byType(Switch));
    expect(value, isTrue);
  });

  testWidgets('toggles when the label is tapped', (tester) async {
    bool? value;
    await pumpComponent(
      tester,
      AppSwitch(value: true, label: 'الإشعارات', onChanged: (v) => value = v),
    );

    await tester.tap(find.text('الإشعارات'));
    expect(value, isFalse);
  });
}
