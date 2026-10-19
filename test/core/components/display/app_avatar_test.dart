import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_image_placeholder.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('without a photo it shows the default avatar', (tester) async {
    await pumpComponent(
      tester,
      const AppAvatar(size: 64, semanticLabel: 'البناء المتين'),
    );

    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.byType(AppImagePlaceholder), findsNothing);
    expect(tester.getSize(find.byType(ClipOval)), const Size(64, 64));
    expect(find.bySemanticsLabel('البناء المتين'), findsOneWidget);
  });

  testWidgets('a photo that fails to load falls back to the default', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const AppAvatar(url: 'https://example.com/avatar.jpg'),
    );
    // Tests have no network, so the photo fails.
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });
}
