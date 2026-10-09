import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/inputs/app_upload_zone.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the label and reports taps', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppUploadZone(label: 'صورة أو PDF', onTap: () => taps++),
    );

    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    await tester.tap(find.text('صورة أو PDF'));
    expect(taps, 1);
  });
}
