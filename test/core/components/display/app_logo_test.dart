import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_logo.dart';

import '../../../helpers/pump_component.dart';

void main() {
  String assetOf(WidgetTester tester) =>
      (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName;

  testWidgets('uses the light logo by default', (tester) async {
    await pumpComponent(tester, const AppLogo());

    expect(assetOf(tester), AppLogo.lightAsset);
  });

  testWidgets('uses the white logo on dark surfaces', (tester) async {
    await pumpComponent(tester, const AppLogo(onDark: true));

    expect(assetOf(tester), AppLogo.darkAsset);
  });

  testWidgets('is announced only with a semantic label', (tester) async {
    await pumpComponent(tester, const AppLogo(semanticLabel: 'وتد'));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.semanticLabel, 'وتد');
    expect(image.excludeFromSemantics, isFalse);
  });
}
