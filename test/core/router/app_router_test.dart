import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_not_found_view.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/app_router.dart';

import '../../helpers/fake_splash_repository.dart';
import '../../helpers/pump_router.dart';

// Each role folder tests its own routes in
// test/features/<feature>/<role>/presentation/ (APP_ARCHITECTURE.md §11).
void main() {
  // The splash fake never answers, so the app stays at its start path.
  setUp(() => registerFakeSplashBloc(FakeSplashRepository()));

  tearDown(getIt.reset);

  testWidgets('starts at the start path', (tester) async {
    final router = await pumpAppRouter(tester);

    expect(currentPath(router), appStartPath);
  });

  testWidgets('an unknown address shows the not-found page', (tester) async {
    final router = await pumpAppRouter(tester);

    router.go('/no-such-page');
    await tester.pumpAndSettle();
    expect(find.byType(AppNotFoundView), findsOneWidget);

    await tester.tap(find.text('العودة إلى البداية'));
    await tester.pumpAndSettle();
    expect(currentPath(router), appStartPath);
  });
}
