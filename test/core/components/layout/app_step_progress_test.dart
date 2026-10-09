import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/layout/app_step_progress.dart';
import 'package:watad/core/theme/app_colors.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the label and one orange bar per done step', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const AppStepProgress(current: 2, total: 4, label: 'الخطوة ٢ من ٤'),
    );

    expect(find.text('الخطوة ٢ من ٤'), findsOneWidget);
    final colors = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(Expanded),
            matching: find.byType(Container),
          ),
        )
        .map((c) => (c.decoration! as BoxDecoration).color)
        .toList();
    expect(colors, [
      AppColors.primary,
      AppColors.primary,
      AppColors.track,
      AppColors.track,
    ]);
  });
}
