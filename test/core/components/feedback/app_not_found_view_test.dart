import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_not_found_view.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('says the page is missing and goes back to the start', (
    tester,
  ) async {
    var backs = 0;
    await pumpComponent(tester, AppNotFoundView(onBackToStart: () => backs++));

    expect(find.text('لم نجد هذه الصفحة.'), findsOneWidget);
    await tester.tap(find.text('العودة إلى البداية'));
    expect(backs, 1);
  });
}
