import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/layout/app_page_dots.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('one dot per page, the current one a wide orange pill', (
    tester,
  ) async {
    await pumpComponent(tester, const AppPageDots(count: 3, currentIndex: 1));
    await tester.pumpAndSettle();

    final dots = find.byType(AnimatedContainer);
    final colors = tester
        .widgetList<AnimatedContainer>(dots)
        .map((dot) => (dot.decoration! as BoxDecoration).color)
        .toList();
    expect(colors, [AppColors.track, AppColors.primary, AppColors.track]);
    expect(tester.getSize(dots.at(0)), const Size(8, 8));
    expect(tester.getSize(dots.at(1)), const Size(24, 8));
  });

  testWidgets('the first page is on the right in Arabic', (tester) async {
    await pumpComponent(tester, const AppPageDots(count: 3, currentIndex: 0));

    final dots = find.byType(AnimatedContainer);
    expect(
      tester.getCenter(dots.first).dx,
      greaterThan(tester.getCenter(dots.last).dx),
    );
  });

  testWidgets('the first page is on the left in English', (tester) async {
    await pumpComponent(
      tester,
      const AppPageDots(count: 3, currentIndex: 0),
      locale: AppLocalization.english,
    );

    final dots = find.byType(AnimatedContainer);
    expect(
      tester.getCenter(dots.first).dx,
      lessThan(tester.getCenter(dots.last).dx),
    );
  });

  testWidgets('reads its label to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpComponent(
      tester,
      const AppPageDots(count: 3, currentIndex: 1, semanticLabel: '2 / 3'),
    );

    expect(find.bySemanticsLabel('2 / 3'), findsOneWidget);
    semantics.dispose();
  });
}
