import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_image_placeholder.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('fills its parent and shows the label', (tester) async {
    await pumpComponent(
      tester,
      const SizedBox(
        width: 120,
        height: 80,
        child: AppImagePlaceholder(label: '1'),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(
      tester.getSize(find.byType(AppImagePlaceholder)),
      const Size(120, 80),
    );
  });
}
