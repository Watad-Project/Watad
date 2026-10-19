import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_image_viewer.dart';

import '../../../helpers/pump_component.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    await pumpLocalizedApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => AppImageViewer.show(
              context,
              url: 'https://example.supabase.co/license.jpeg',
              title: 'السجل التجاري',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  double scale(WidgetTester tester) => tester
      .widget<InteractiveViewer>(find.byType(InteractiveViewer))
      .transformationController!
      .value
      .getMaxScaleOnAxis();

  testWidgets('shows the image full screen with its title', (tester) async {
    await open(tester);

    expect(find.byType(AppImageViewer), findsOneWidget);
    expect(find.text('السجل التجاري'), findsOneWidget);
    expect(find.byTooltip('إغلاق'), findsOneWidget);
  });

  testWidgets('a double tap zooms in, a second one zooms back out', (
    tester,
  ) async {
    await open(tester);
    final center = tester.getCenter(find.byType(InteractiveViewer));

    await tester.tapAt(center);
    await tester.pump(kDoubleTapMinTime);
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(scale(tester), greaterThan(1));

    await tester.tapAt(center);
    await tester.pump(kDoubleTapMinTime);
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(scale(tester), 1);
  });

  testWidgets('× closes it', (tester) async {
    await open(tester);

    await tester.tap(find.byTooltip('إغلاق'));
    await tester.pumpAndSettle();
    expect(find.byType(AppImageViewer), findsNothing);
  });
}
