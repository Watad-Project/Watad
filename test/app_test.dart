import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/app.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';
import 'package:watad/features/splash/shared/presentation/pages/splash_page.dart';

import 'helpers/pump_component.dart';

class FakeSplashRepository implements SplashRepository {
  const FakeSplashRepository(this.result);

  final Result<SplashDestination> result;

  @override
  Future<Result<SplashDestination>> determineInitialDestination() async =>
      result;
}

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

  testWidgets('the app starts in Arabic, right to left on the splash page', (
    tester,
  ) async {
    // The same setup as main.dart, reading the translation files from disk.
    await tester.pumpWidget(
      AppLocalization.scope(
        assetLoader: const TestAssetLoader(),
        saveLocale: false,
        child: const WatadApp(),
      ),
    );
    await tester.pumpAndSettle();

    final page = tester.element(find.byType(Scaffold));
    expect(page.locale, AppLocalization.arabic);
    expect(Directionality.of(page), TextDirection.rtl);
    expect(find.byType(SplashPage), findsOneWidget);
  });
}
