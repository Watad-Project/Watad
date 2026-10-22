import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_stat_tile.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the label, the number and the line under it', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const AppStatTile(label: 'المنشآت', value: '٢٦٠', caption: '٢١٢ موثّقة'),
    );

    expect(find.text('المنشآت'), findsOneWidget);
    expect(find.text('٢٦٠'), findsOneWidget);
    expect(find.text('٢١٢ موثّقة'), findsOneWidget);
    // Nothing to open: no arrow.
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('with onTap it shows an arrow and opens', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppStatTile(
        label: 'رخص بانتظار التوثيق',
        value: '٧',
        isHighlighted: true,
        onTap: () => taps++,
      ),
    );

    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    await tester.tap(find.byType(AppStatTile));
    expect(taps, 1);
  });

  testWidgets('fits large bold text', (tester) async {
    await pumpLocalizedApp(
      tester,
      // Half a phone's width, in a page that scrolls, as on the dashboard.
      const Scaffold(
        body: SingleChildScrollView(
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              width: 170,
              child: AppStatTile(
                label: 'المستخدمون النشطون',
                value: '١٬٢٤٠',
                caption: '٢١٢ موثّقة',
                icon: Icons.person_outline,
                onTap: _noop,
              ),
            ),
          ),
        ),
      ),
      textScale: largeTextScale,
      boldText: true,
    );

    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
