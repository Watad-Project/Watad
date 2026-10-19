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
}
