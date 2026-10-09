import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_state_stepper.dart';
import 'package:watad/core/theme/app_colors.dart';

import '../../../helpers/pump_component.dart';

void main() {
  const labels = ['مقترحة', 'مقبولة', 'منجزة', 'معتمدة', 'مدفوعة'];

  testWidgets('colors the reached states orange', (tester) async {
    await pumpComponent(
      tester,
      const AppStateStepper(labels: labels, currentIndex: 1),
    );

    Color? colorOf(String label) =>
        tester.widget<Text>(find.text(label)).style?.color;
    expect(colorOf('مقترحة'), AppColors.primaryDark);
    expect(colorOf('مقبولة'), AppColors.primaryDark);
    expect(colorOf('منجزة'), AppColors.textSecondary);
    expect(colorOf('مدفوعة'), AppColors.textSecondary);
  });

  testWidgets('marks the current state as selected', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpComponent(
      tester,
      const AppStateStepper(labels: labels, currentIndex: 1),
    );

    expect(
      tester.getSemantics(find.text('مقبولة')),
      matchesSemantics(
        label: 'مقبولة',
        isSelected: true,
        hasSelectedState: true,
      ),
    );
    handle.dispose();
  });
}
