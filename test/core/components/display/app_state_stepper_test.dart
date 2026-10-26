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

  Color? colorOf(WidgetTester tester, String label) =>
      tester.widget<Text>(find.text(label)).style?.color;

  testWidgets('without animateFrom, the lines stay gray', (tester) async {
    await pumpComponent(
      tester,
      const AppStateStepper(labels: labels, currentIndex: 3),
    );

    expect(find.byType(FractionallySizedBox), findsNothing);
  });

  testWidgets('with animateFrom, the states fill in after it shows', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const AppStateStepper(labels: labels, currentIndex: 2, animateFrom: 0),
    );

    // It starts from animateFrom…
    expect(colorOf(tester, 'مقترحة'), AppColors.primaryDark);
    expect(colorOf(tester, 'منجزة'), AppColors.textSecondary);

    // …and fills up to the current state, the line between them too.
    await tester.pumpAndSettle();
    expect(colorOf(tester, 'مقبولة'), AppColors.primaryDark);
    expect(colorOf(tester, 'منجزة'), AppColors.primaryDark);
    expect(colorOf(tester, 'معتمدة'), AppColors.textSecondary);
    final filled = tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .map((line) => line.widthFactor);
    // Four half lines from the first state to the third, then gray ones.
    expect(filled.take(4), everyElement(1.0));
    expect(filled.skip(4), everyElement(0.0));
  });

  testWidgets('with animateFrom, a new current state fills on from there', (
    tester,
  ) async {
    var index = 1;
    late StateSetter setIndex;
    await pumpComponent(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          setIndex = setState;
          return AppStateStepper(
            labels: labels,
            currentIndex: index,
            animateFrom: 0,
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(colorOf(tester, 'منجزة'), AppColors.textSecondary);

    setIndex(() => index = 2);
    await tester.pump();
    expect(colorOf(tester, 'منجزة'), AppColors.textSecondary);
    await tester.pumpAndSettle();
    expect(colorOf(tester, 'منجزة'), AppColors.primaryDark);
  });

  testWidgets('with reduce motion, it shows the states at once', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: const AppStateStepper(
            labels: labels,
            currentIndex: 2,
            animateFrom: 0,
          ),
        ),
      ),
    );

    expect(colorOf(tester, 'منجزة'), AppColors.primaryDark);
    expect(colorOf(tester, 'معتمدة'), AppColors.textSecondary);
  });
}
