import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/inputs/app_camera_tile.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the translated label and reports taps', (tester) async {
    var taps = 0;
    await pumpComponent(tester, AppCameraTile(onTap: () => taps++));

    await tester.tap(find.text('الكاميرا'));
    expect(taps, 1);
    expect(tester.getSize(find.byType(AppCameraTile)).width, 72);
  });
}
