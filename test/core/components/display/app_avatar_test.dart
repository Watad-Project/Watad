import 'dart:typed_data';

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

  testWidgets('a photo not uploaded yet shows instead of the URL', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      AppAvatar(
        url: 'https://example.com/avatar.jpg',
        image: MemoryImage(Uint8List.fromList(_transparentPng)),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
  });
}

/// A transparent PNG, one pixel wide.
const List<int> _transparentPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
];
