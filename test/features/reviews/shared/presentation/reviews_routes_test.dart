import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/reviews_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/reviews/shared/domain/entities/my_review.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_draft.dart';
import 'package:watad/features/reviews/shared/presentation/pages/write_review_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_reviews_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeReviewsRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeReviewsRepository();
    registerFakeReviews(repository);
  });

  tearDown(getIt.reset);

  /// Opens the sheet over the splash page, as other screens open it.
  Future<(GoRouter, Future<bool?>)> openSheet(
    WidgetTester tester, {
    Map<String, String> query = const {'user': 'u-2', 'order': 'o-1'},
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
      textScale: textScale,
      boldText: boldText,
    );
    final result = router.pushNamed<bool>(
      ReviewsRoutes.writeReviewName,
      queryParameters: query,
    );
    await tester.pumpAndSettle();
    return (router, result);
  }

  testWidgets('write-review opens at its path with whom I rate', (
    tester,
  ) async {
    final (router, _) = await openSheet(tester);

    final top = router.routerDelegate.currentConfiguration.last;
    expect(top.matchedLocation, '/reviews/write');
    expect(find.byType(WriteReviewPage), findsOneWidget);
    expect(find.text('تقييم مؤسسة البناء المتين'), findsOneWidget);
    expect(find.text('عن تعاملك معه في هذا الطلب'), findsOneWidget);
    expect(repository.drafts.single.orderId, 'o-1');
    expect(repository.drafts.single.targetUserId, 'u-2');
  });

  testWidgets('stars and a comment are saved, and the sheet closes', (
    tester,
  ) async {
    final (_, result) = await openSheet(tester);

    await tester.tap(find.byKey(const Key('review_star_4')));
    await tester.enterText(find.byType(TextField), 'منتج مطابق للوصف');
    await tester.tap(find.byKey(const Key('review_save')));
    await tester.pumpAndSettle();

    final saved = repository.saved.single;
    expect(saved.rating, 4);
    expect(saved.comment, 'منتج مطابق للوصف');
    expect(saved.subject.orderId, 'o-1');
    expect(await result, isTrue);
    expect(find.byType(WriteReviewPage), findsNothing);
  });

  testWidgets('nothing is saved without stars', (tester) async {
    await openSheet(tester);

    await tester.tap(find.byKey(const Key('review_save')));
    await tester.pumpAndSettle();

    expect(find.text('اختر عدد النجوم'), findsOneWidget);
    expect(repository.saved, isEmpty);
  });

  testWidgets('my earlier review opens for editing', (tester) async {
    repository.draftResult = const Success(
      ReviewDraft(
        targetName: 'سارة العتيبي',
        existing: MyReview(id: 'r-9', rating: 3, comment: 'تأخر يومين'),
      ),
    );
    await openSheet(tester, query: const {'user': 'u-3', 'project': 'p-1'});

    expect(find.text('تعديل تقييمك لـسارة العتيبي'), findsOneWidget);
    expect(find.text('عن تعاملك معه في هذا المشروع'), findsOneWidget);
    expect(find.text('تأخر يومين'), findsOneWidget);

    await tester.tap(find.byKey(const Key('review_save')));
    await tester.pumpAndSettle();
    expect(repository.saved.single.existingId, 'r-9');
    expect(repository.saved.single.rating, 3);
  });

  testWidgets('a sheet that fails to load offers a retry', (tester) async {
    repository.draftResult = const Failed(NetworkFailure());
    await openSheet(tester);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(repository.drafts, hasLength(2));
  });

  testWidgets('fits large bold text', (tester) async {
    await openSheet(tester, textScale: largeTextScale, boldText: true);

    expect(find.byType(WriteReviewPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
