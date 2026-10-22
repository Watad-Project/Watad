import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:watad/core/components/display/app_google_map.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('renders AppGoogleMap widget', (tester) async {
    await pumpComponent(
      tester,
      const SizedBox(
        height: 300,
        child: AppGoogleMap(
          initialLatitude: 24.7136,
          initialLongitude: 46.6753,
        ),
      ),
    );

    expect(find.byType(AppGoogleMap), findsOneWidget);
    expect(find.byType(GoogleMap), findsOneWidget);
  });

  testWidgets('a camera can be passed, swapped and disposed', (tester) async {
    final first = AppMapCamera();
    final second = AppMapCamera();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    Widget map(AppMapCamera camera) =>
        SizedBox(height: 300, child: AppGoogleMap(camera: camera));

    await pumpComponent(tester, map(first));
    // Before the map is ready there is nothing to move: no error.
    first.show(latitude: 21.5433, longitude: 39.1728);
    await pumpComponent(tester, map(second));
    second.show(
      latitude: 24.4672,
      longitude: 39.6111,
      area: (south: 24.3, west: 39.4, north: 24.6, east: 39.8),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  test('showing a place tells the map', () {
    final camera = AppMapCamera();
    addTearDown(camera.dispose);
    var told = 0;
    camera
      ..addListener(() => told++)
      ..show(latitude: 21.5433, longitude: 39.1728);

    expect(told, 1);
  });
}
