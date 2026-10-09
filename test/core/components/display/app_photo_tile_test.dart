import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_image_placeholder.dart';
import 'package:watad/core/components/display/app_photo_tile.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows a numbered placeholder and reports taps', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppPhotoTile(placeholderLabel: '2', onTap: () => taps++),
    );

    expect(find.byType(AppImagePlaceholder), findsOneWidget);
    await tester.tap(find.text('2'));
    expect(taps, 1);
  });
}
