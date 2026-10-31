import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/marketplace_page.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_item_card.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_marketplace_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeMarketplaceRepository repository;

  setUp(() {
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeMarketplaceRepository();
    registerFakeMarketplace(repository);
  });

  tearDown(getIt.reset);

  Future<GoRouter> open(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(MarketplaceRoutes.marketplaceName);
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'marketplace opens active listings with price, rating, and badge',
    (tester) async {
      final router = await open(tester);

      expect(currentPath(router), MarketplaceRoutes.marketplacePath);
      expect(find.byType(MarketplacePage), findsOneWidget);
      expect(find.byType(MarketplaceItemCard), findsNWidgets(3));
      expect(find.text('أسمنت أبيض ٥٠ كجم'), findsOneWidget);
      expect(find.text('٤٥ ر.س'), findsOneWidget);
      expect(find.text('٤٫٨ (١٢ تقييمًا)'), findsWidgets);
      expect(find.text('لا تقييمات بعد'), findsOneWidget);
      // Out-of-stock badge «نفد».
      expect(find.text('نفد'), findsOneWidget);
    },
  );

  testWidgets('category chip, search, and sort update the grid', (
    tester,
  ) async {
    await open(tester);

    // Filter by category «حديد ومعادن».
    await tester.tap(find.text('حديد ومعادن'));
    await tester.pumpAndSettle();
    expect(find.byType(MarketplaceItemCard), findsOneWidget);
    expect(find.text('حديد تسليح ١٢ مم'), findsOneWidget);

    // Back to «الكل» and search by item name.
    await tester.tap(find.text('الكل'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'دهان');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byType(MarketplaceItemCard), findsOneWidget);
    expect(find.text('دهان داخلي أبيض'), findsOneWidget);

    // Clear search and change sort to price low to high.
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('marketplace_sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('السعر: من الأقل إلى الأعلى').last);
    await tester.pumpAndSettle();
    expect(find.byType(MarketplaceItemCard), findsNWidgets(3));
  });

  testWidgets('the marketplace fits large bold text at 200%', (tester) async {
    await open(tester, textScale: largeTextScale, boldText: true);

    expect(find.byType(MarketplacePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
