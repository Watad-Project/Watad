import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_image_placeholder.dart';
import 'package:watad/core/components/display/app_network_image.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the placeholder without a URL', (tester) async {
    await pumpComponent(
      tester,
      const AppNetworkImage(url: null, width: 100, height: 60),
    );

    expect(find.byType(AppImagePlaceholder), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows the placeholder while the image loads', (tester) async {
    await pumpComponent(
      tester,
      const AppNetworkImage(
        url: 'https://example.com/photo.jpg',
        width: 100,
        height: 60,
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(AppImagePlaceholder), findsOneWidget);
  });
}
