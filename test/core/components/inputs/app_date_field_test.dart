import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/inputs/app_date_field.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('renders label, hint, helper, and formatted date value', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      AppDateField(
        label: 'تاريخ البدء',
        hint: 'اختر التاريخ',
        helperText: 'اختياري',
        value: DateTime.utc(2026, 10, 15),
        onChanged: (_) {},
      ),
    );

    expect(find.text('تاريخ البدء'), findsOneWidget);
    expect(find.text('اختياري'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('clears selected date when clear button is tapped', (
    tester,
  ) async {
    DateTime? current = DateTime.utc(2026, 10, 15);
    await pumpComponent(
      tester,
      AppDateField(
        label: 'تاريخ البدء',
        value: current,
        onChanged: (next) => current = next,
      ),
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(current, isNull);
  });

  testWidgets('opens date picker dialog when tapped', (tester) async {
    DateTime? selected;
    await pumpComponent(
      tester,
      AppDateField(
        label: 'تاريخ البدء',
        hint: 'اختر التاريخ',
        initialDate: DateTime.utc(2026, 10, 15),
        firstDate: DateTime(2026, 1, 1),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (next) => selected = next,
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    // Confirm the default initial date in the dialog.
    final okButton = find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.byType(TextButton),
    );
    await tester.tap(okButton.last);
    await tester.pumpAndSettle();

    expect(selected, DateTime.utc(2026, 10, 15));
  });
}
