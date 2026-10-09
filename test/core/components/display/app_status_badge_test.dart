import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_tone.dart';

import '../../../helpers/pump_component.dart';

void main() {
  BoxDecoration decorationOf(WidgetTester tester) =>
      tester.widget<Container>(find.byType(Container)).decoration!
          as BoxDecoration;

  testWidgets('uses the colors of its tone', (tester) async {
    await pumpComponent(
      tester,
      const AppStatusBadge(label: 'بانتظار الاعتماد', tone: AppTone.attention),
    );

    expect(decorationOf(tester).color, AppColors.primarySoft);
    final text = tester.widget<Text>(find.text('بانتظار الاعتماد'));
    expect(text.style?.color, AppColors.primaryDark);
  });

  testWidgets('is white on a photo', (tester) async {
    await pumpComponent(
      tester,
      const AppStatusBadge(label: 'نشط', tone: AppTone.success, onImage: true),
    );

    expect(decorationOf(tester).color, AppColors.surface);
  });
}
