import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_lottie.dart';

import '../../../helpers/pump_component.dart';

const String _asset = 'assets/animations/onboarding_all_in_one.json';

void main() {
  testWidgets('shows the animation at its size, hidden from screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpComponent(
      tester,
      const AppLottie(asset: _asset, width: 120, height: 120),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppLottie)), const Size(120, 120));
    expect(
      tester.getSemantics(find.byType(AppLottie)),
      isNot(matchesSemantics(isImage: true)),
    );
    semantics.dispose();
  });

  testWidgets('reads its label to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpComponent(
      tester,
      const AppLottie(
        asset: _asset,
        width: 120,
        height: 120,
        semanticLabel: 'Watad',
      ),
    );

    expect(find.bySemanticsLabel('Watad'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('loops by default, and stops at the end without repeat', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const AppLottie(asset: _asset, width: 120, height: 120),
    );
    // The file is 4 s long; after 10 s a looping animation still runs.
    await tester.pump(const Duration(seconds: 10));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await pumpComponent(
      tester,
      const AppLottie(asset: _asset, width: 120, height: 120, repeat: false),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
