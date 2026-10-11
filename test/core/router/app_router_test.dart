import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_not_found_view.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/app_router.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';

import '../../helpers/pump_router.dart';

class FakeSplashRepository implements SplashRepository {
  const FakeSplashRepository(this.result);

  final Result<SplashDestination> result;

  @override
  Future<Result<SplashDestination>> determineInitialDestination() async =>
      result;
}

// Each role folder tests its own routes in
// test/features/<feature>/<role>/presentation/ (APP_ARCHITECTURE.md §11).
void main() {
  setUp(() {
    getIt.registerFactory(
      () => SplashBloc(
        const GetInitialDestinationUseCase(
          FakeSplashRepository(Success(SplashDestination.login)),
        ),
      ),
    );
  });

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
