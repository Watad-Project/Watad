import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/edit_my_item_page.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/marketplace_page.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/my_items_page.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/new_my_item_page.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_item_card.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/my_item_card.dart';

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
    String routeName = MarketplaceRoutes.marketplaceName,
    Map<String, String> pathParameters = const {},
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(routeName, pathParameters: pathParameters);
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

  testWidgets(
    'my-items filters by status chips, shows removal reason, hides, and deletes',
    (tester) async {
      final router = await open(
        tester,
        routeName: MarketplaceRoutes.myItemsName,
      );

      expect(currentPath(router), MarketplaceRoutes.myItemsPath);
      expect(find.byType(MyItemsPage), findsOneWidget);
      expect(find.text('أسمنت أبيض ٥٠ كجم'), findsOneWidget);

      // Filter by «محذوفة من الإدارة» and verify the admin removal reason.
      await tester.tap(find.text('محذوفة من الإدارة'));
      await tester.pumpAndSettle();
      expect(find.byType(MyItemCard), findsOneWidget);
      expect(find.text('سقالات مستعملة'), findsOneWidget);
      expect(find.text('صور غير مطابقة للمنتج المعروض'), findsOneWidget);

      // Filter by «معروضة» and hide the live item.
      await tester.tap(find.text('معروضة'));
      await tester.pumpAndSettle();
      expect(find.byType(MyItemCard), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('my_item_toggle_i-cement')));
      await tester.pumpAndSettle();
      expect(find.byType(MyItemCard), findsNothing);

      // Switch to «مخفية» and delete an item after confirming.
      await tester.tap(find.text('مخفية'));
      await tester.pumpAndSettle();
      expect(find.byType(MyItemCard), findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('my_item_delete_i-cement')));
      await tester.pumpAndSettle();
      expect(find.text('حذف المنتج؟'), findsOneWidget);
      await tester.tap(find.text('حذف').last);
      await tester.pumpAndSettle();
      expect(find.byType(MyItemCard), findsOneWidget);
    },
  );

  testWidgets('new-my-item shows price note and creates a new listing', (
    tester,
  ) async {
    final router = await open(
      tester,
      routeName: MarketplaceRoutes.newMyItemName,
    );

    expect(currentPath(router), MarketplaceRoutes.newMyItemPath);
    expect(find.byType(NewMyItemPage), findsOneWidget);
    expect(find.text('تغيير السعر لا يؤثر في الطلبات القائمة'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('my_item_name_field')),
      'بلاط سيراميك ٦٠×٦٠',
    );
    await tester.tap(find.byKey(const Key('my_item_category_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مواد بناء').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('my_item_price_field')), '65');
    await tester.enterText(find.byKey(const Key('my_item_stock_field')), '80');
    await tester.tap(find.byKey(const Key('my_item_form_submit')));
    await tester.pumpAndSettle();

    expect(
      repository.myItems.any((i) => i.name == 'بلاط سيراميك ٦٠×٦٠'),
      isTrue,
    );
  });

  testWidgets(
    'edit-my-item updates an active listing and keeps a removed listing read-only',
    (tester) async {
      await open(
        tester,
        routeName: MarketplaceRoutes.editMyItemName,
        pathParameters: {'itemId': 'i-cement'},
      );

      expect(find.byType(EditMyItemPage), findsOneWidget);
      expect(find.text('أسمنت أبيض ٥٠ كجم'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('my_item_price_field')),
        '55',
      );
      await tester.tap(find.byKey(const Key('my_item_form_submit')));
      await tester.pumpAndSettle();

      final updated = repository.myItems.firstWhere((i) => i.id == 'i-cement');
      expect(updated.price.halalas, 5500);

      // Now open a removed listing in edit mode: read-only with removal reason.
      await open(
        tester,
        routeName: MarketplaceRoutes.editMyItemName,
        pathParameters: {'itemId': 'i-removed'},
      );
      expect(find.text('صور غير مطابقة للمنتج المعروض'), findsOneWidget);
      expect(find.byKey(const Key('my_item_form_submit')), findsNothing);
    },
  );

  testWidgets('my-items page fits large bold text at 200%', (tester) async {
    await open(
      tester,
      routeName: MarketplaceRoutes.myItemsName,
      textScale: largeTextScale,
      boldText: true,
    );

    expect(find.byType(MyItemsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new-my-item page fits large bold text at 200%', (tester) async {
    await open(
      tester,
      routeName: MarketplaceRoutes.newMyItemName,
      textScale: largeTextScale,
      boldText: true,
    );

    expect(find.byType(NewMyItemPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit-my-item page fits large bold text at 200%', (tester) async {
    await open(
      tester,
      routeName: MarketplaceRoutes.editMyItemName,
      pathParameters: {'itemId': 'i-removed'},
      textScale: largeTextScale,
      boldText: true,
    );

    expect(find.byType(EditMyItemPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
