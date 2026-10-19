import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_business_mini_card.dart';
import 'package:watad/core/components/display/app_image_placeholder.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows a verified business and reports taps', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      SizedBox(
        width: 180,
        child: AppBusinessMiniCard(
          name: 'البناء المتين',
          ratingLabel: '٤٫٨',
          projectsLabel: '٦٤ مشروعاً',
          isVerified: true,
          onTap: () => taps++,
        ),
      ),
    );

    expect(find.text('البناء المتين'), findsOneWidget);
    expect(find.text('٤٫٨ · ٦٤ مشروعاً'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.tap(find.text('البناء المتين'));
    expect(taps, 1);
  });

  testWidgets('has no check when not verified', (tester) async {
    await pumpComponent(
      tester,
      const SizedBox(
        width: 180,
        child: AppBusinessMiniCard(
          name: 'إتقان للتشييد',
          ratingLabel: '٤٫٧',
          projectsLabel: '٤١ مشروعاً',
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('without a photo it shows the default avatar, not stripes', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const SizedBox(
        width: 180,
        child: AppBusinessMiniCard(
          name: 'إتقان للتشييد',
          ratingLabel: '٤٫٧',
          projectsLabel: '٤١ مشروعاً',
        ),
      ),
    );

    expect(find.byType(AppAvatar), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.byType(AppImagePlaceholder), findsNothing);
  });

  testWidgets('heightOf leaves room for large, bold text', (tester) async {
    await pumpComponent(
      tester,
      Builder(
        builder: (context) => SizedBox(
          width: 180,
          height: AppBusinessMiniCard.heightOf(context),
          child: const AppBusinessMiniCard(
            name: 'مؤسسة البناء المتين للمقاولات العامة',
            ratingLabel: '٤٫٨',
            projectsLabel: '٦٤ مشروعًا',
            isVerified: true,
          ),
        ),
      ),
      textScale: largeTextScale,
      boldText: true,
    );

    expect(tester.takeException(), isNull);
  });
}
