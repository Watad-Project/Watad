import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/features/auth/shared/presentation/bloc/role_bloc.dart';
import 'package:watad/features/auth/shared/presentation/pages/role_page.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';

import '../../../../helpers/pump_router.dart';

class FakeSplashRepository implements SplashRepository {
  const FakeSplashRepository(this.result);

  final Result<SplashDestination> result;

  @override
  Future<Result<SplashDestination>> determineInitialDestination() async =>
      result;
}

void main() {
  testWidgets('every auth route opens its page at its path', (tester) async {
    getIt
      ..registerFactory(() {
        return RoleBloc();
      })
      ..registerFactory(
        () => SplashBloc(
          const GetInitialDestinationUseCase(
            FakeSplashRepository(Success(SplashDestination.login)),
          ),
        ),
      );
    addTearDown(getIt.reset);

    final router = await pumpAppRouter(tester);

    router.goNamed(AuthRoutes.roleName);
    await tester.pumpAndSettle();
    expect(currentPath(router), AuthRoutes.rolePath);
    expect(find.byType(RolePage), findsOneWidget);
  });
}
