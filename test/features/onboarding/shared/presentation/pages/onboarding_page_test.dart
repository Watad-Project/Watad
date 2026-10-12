import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/features/onboarding/shared/domain/repositories/onboarding_repository.dart';
import 'package:watad/features/onboarding/shared/domain/usecases/mark_onboarding_seen_use_case.dart';
import 'package:watad/features/onboarding/shared/presentation/bloc/onboarding_bloc.dart';
import 'package:watad/features/onboarding/shared/presentation/pages/onboarding_page.dart';

import '../../../../../helpers/pump_component.dart';

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository([this.result = const Success<void>(null)]);

  final Result<void> result;

  int calls = 0;

  @override
  Future<Result<void>> markOnboardingSeen() async {
    calls++;
    return result;
  }
}

void main() {
  late FakeOnboardingRepository repository;
  late int finishedCount;

  Future<void> pumpPage(
    WidgetTester tester, {
    Locale locale = AppLocalization.arabic,
  }) async {
    await pumpLocalizedApp(
      tester,
      BlocProvider(
        create: (_) => OnboardingBloc(MarkOnboardingSeenUseCase(repository)),
        child: OnboardingPage(onFinished: (_) => finishedCount++),
      ),
      locale: locale,
    );
  }

  // Not pumpAndSettle: the slide animation loops.
  Future<void> tapAndWait(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  setUp(() {
    repository = FakeOnboardingRepository();
    finishedCount = 0;
  });

  testWidgets('starts on the first slide, right to left, with next and skip', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('كل مشروعك في مكان واحد'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
    expect(find.text('تخطّي').hitTestable(), findsOneWidget);
    final page = tester.element(find.byType(OnboardingPage));
    expect(Directionality.of(page), TextDirection.rtl);
  });

  testWidgets('next moves to the next slide', (tester) async {
    await pumpPage(tester);

    await tapAndWait(tester, 'التالي');

    expect(find.text('عقود موثّقة لا تتغيّر'), findsOneWidget);
    expect(repository.calls, 0);
    expect(finishedCount, 0);
  });

  testWidgets('the last slide says get started, hides skip and finishes', (
    tester,
  ) async {
    await pumpPage(tester);
    await tapAndWait(tester, 'التالي');
    await tapAndWait(tester, 'التالي');

    expect(find.text('دفعات واضحة على مراحل'), findsOneWidget);
    expect(find.text('التالي'), findsNothing);
    expect(find.text('تخطّي').hitTestable(), findsNothing);

    await tapAndWait(tester, 'ابدأ الآن');

    expect(repository.calls, 1);
    expect(finishedCount, 1);
  });

  testWidgets('skip marks the onboarding as seen and finishes', (tester) async {
    await pumpPage(tester);

    await tapAndWait(tester, 'تخطّي');

    expect(repository.calls, 1);
    expect(finishedCount, 1);
  });

  testWidgets('a failed save shows the error and still finishes', (
    tester,
  ) async {
    repository = FakeOnboardingRepository(const Failed<void>(UnknownFailure()));
    await pumpPage(tester);

    await tapAndWait(tester, 'تخطّي');

    expect(find.text('حدث خطأ ما. حاول مرة أخرى.'), findsOneWidget);
    expect(finishedCount, 1);
  });

  testWidgets('shows the English text left to right', (tester) async {
    await pumpPage(tester, locale: AppLocalization.english);

    expect(find.text('Your whole project in one place'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    final page = tester.element(find.byType(OnboardingPage));
    expect(Directionality.of(page), TextDirection.ltr);
  });
}
