import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_motion.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('sweeps over its boxes and says it is loading', (tester) async {
    await pumpComponent(
      tester,
      const AppShimmer(child: AppSkeletonBox(height: 16, width: 120)),
    );

    expect(find.byType(ShaderMask), findsOneWidget);
    expect(find.bySemanticsLabel('جارٍ التحميل'), findsOneWidget);
    // It keeps going while it is on screen.
    await tester.pump(AppMotion.shimmer * 1.5);
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('stays still with reduce motion', (tester) async {
    await pumpComponent(
      tester,
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: AppShimmer(child: AppSkeletonBox(height: 16)),
      ),
    );

    expect(find.byType(ShaderMask), findsNothing);
    expect(find.byType(AppSkeletonBox), findsOneWidget);
  });

  testWidgets('a box without a width takes the whole line', (tester) async {
    await pumpComponent(
      tester,
      const AppShimmer(child: AppSkeletonBox(height: 16)),
    );

    expect(tester.getSize(find.byType(AppSkeletonBox)).width, greaterThan(500));
  });
}
