import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_image_placeholder.dart';
import 'package:watad/core/components/display/app_network_image.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';

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

  testWidgets('shimmers while the image loads, stripes when it fails', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const AppNetworkImage(
        url: 'https://example.com/photo.jpg',
        width: 100,
        height: 60,
      ),
    );

    // Until its first frame, the image shows the shimmer.
    final image = tester.widget<Image>(find.byType(Image));
    final context = tester.element(find.byType(Image));
    const decoded = SizedBox(key: Key('decoded'));
    expect(
      image.frameBuilder!(context, decoded, null, false),
      isA<AppShimmer>(),
    );
    expect(image.frameBuilder!(context, decoded, 0, false), same(decoded));

    // Tests have no network, so the image fails: the stripes show.
    await tester.pump();
    expect(find.byType(AppImagePlaceholder), findsOneWidget);
  });
}
