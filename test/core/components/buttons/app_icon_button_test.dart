import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_icon_button.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('has its tooltip and calls onPressed', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppIconButton(icon: Icons.add, tooltip: 'إضافة', onPressed: () => taps++),
    );

    expect(find.byTooltip('إضافة'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    expect(taps, 1);
  });

  testWidgets('keeps a 48 tap target in the filled variant', (tester) async {
    await pumpComponent(
      tester,
      Center(
        child: AppIconButton(
          icon: Icons.add,
          tooltip: 'إضافة',
          onPressed: () {},
          variant: AppIconButtonVariant.filled,
        ),
      ),
    );

    final size = tester.getSize(find.byType(IconButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });
}
