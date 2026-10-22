import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/admin_marketplace_routes.dart';
import 'package:watad/core/router/routes/admin_navigation_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/marketplace/admin/presentation/pages/admin_marketplace_item_page.dart';
import 'package:watad/features/marketplace/admin/presentation/pages/admin_marketplace_page.dart';
import 'package:watad/features/marketplace/admin/presentation/widgets/admin_marketplace_item_tile.dart';
import 'package:watad/features/users/admin/presentation/pages/admin_user_details_page.dart';

import '../../../../helpers/fake_admin_dashboard_repository.dart';
import '../../../../helpers/fake_admin_marketplace_repository.dart';
import '../../../../helpers/fake_admin_users_repository.dart';
import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeAdminMarketplaceRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeAdminMarketplaceRepository();
    registerFakeAdminMarketplace(repository);
  });

  tearDown(getIt.reset);

  Future<GoRouter> open(
    WidgetTester tester,
    String name, {
    Map<String, String> pathParameters = const {},
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(name, pathParameters: pathParameters);
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(
      finder,
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AppConfirmDialog),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('admin-marketplace opens the listings at its path', (
    tester,
  ) async {
    final router = await open(tester, AdminMarketplaceRoutes.marketplaceName);

    expect(currentPath(router), AdminMarketplaceRoutes.marketplacePath);
    expect(find.byType(AdminMarketplacePage), findsOneWidget);
    expect(find.text('الكل ٤'), findsOneWidget);
    expect(find.text('محذوفة من الإدارة ١'), findsOneWidget);
    expect(find.text('أسمنت أبيض ٥٠ كجم'), findsOneWidget);
    // The price per unit, through Money, and the stock.
    expect(find.text('٤٥ ر.س للوحدة، المخزون: ١٢٠'), findsOneWidget);
  });

  testWidgets('a chip and a search narrow the list', (tester) async {
    await open(tester, AdminMarketplaceRoutes.marketplaceName);

    await tester.tap(find.text('مخفية ١'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminMarketplaceItemTile), findsOneWidget);
    expect(find.text('بلاط سيراميك'), findsOneWidget);

    await tester.tap(find.text('الكل ٤'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'دهان');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byType(AdminMarketplaceItemTile), findsOneWidget);
    expect(find.text('نفد المخزون ١'), findsOneWidget);
  });

  testWidgets('a tap opens the listing, and back reloads the list', (
    tester,
  ) async {
    await open(tester, AdminMarketplaceRoutes.marketplaceName);
    final queries = repository.queries.length;

    await tester.tap(find.text('أسمنت أبيض ٥٠ كجم'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminMarketplaceItemPage), findsOneWidget);
    expect(find.text('كيس أسمنت أبيض للتشطيبات'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(repository.queries.length, queries + 1);
  });

  testWidgets('admin-marketplace-item opens at its path; removing asks why', (
    tester,
  ) async {
    final router = await open(
      tester,
      AdminMarketplaceRoutes.marketplaceItemName,
      pathParameters: {'itemId': 'i-live'},
    );
    expect(currentPath(router), '/admin/marketplace/i-live');

    await scrollTo(tester, find.text('إزالة المنتج'));
    await tester.tap(find.text('إزالة المنتج'));
    await tester.pumpAndSettle();
    expect(find.byType(AppConfirmDialog), findsOneWidget);
    expect(find.textContaining('تُلغى طلباته'), findsOneWidget);
    await confirm(tester, 'إزالة المنتج');
    // Without a reason nothing is sent.
    expect(repository.calls, isEmpty);

    await tester.enterText(
      find.descendant(
        of: find.byType(AppConfirmDialog),
        matching: find.byType(TextField),
      ),
      'سعر مضلل',
    );
    await confirm(tester, 'إزالة المنتج');
    expect(repository.calls, ['remove i-live: سعر مضلل']);
  });

  testWidgets('a removed listing shows when, by whom and why', (tester) async {
    await open(
      tester,
      AdminMarketplaceRoutes.marketplaceItemName,
      pathParameters: {'itemId': 'i-removed'},
    );

    await scrollTo(tester, find.byType(AppStatusCard));
    expect(find.text('سعر مضلل'), findsOneWidget);
    expect(find.textContaining('عمر ملا'), findsOneWidget);
    expect(find.text('إزالة المنتج'), findsNothing);
  });

  testWidgets('the seller opens in user management', (tester) async {
    registerFakeAdminUsers(FakeAdminUsersRepository());
    await open(
      tester,
      AdminMarketplaceRoutes.marketplaceItemName,
      pathParameters: {'itemId': 'i-live'},
    );

    await scrollTo(tester, find.text('مقاولات الخبر'));
    await tester.tap(find.text('مقاولات الخبر'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminUserDetailsPage), findsOneWidget);
  });

  testWidgets('a listing that does not exist says so', (tester) async {
    await open(
      tester,
      AdminMarketplaceRoutes.marketplaceItemName,
      pathParameters: {'itemId': 'i-none'},
    );

    expect(find.text('لم نجد هذا المنتج'), findsOneWidget);
  });

  testWidgets('the dashboard opens it from «إدارة منتجات السوق»', (
    tester,
  ) async {
    registerFakeAdminDashboard(FakeAdminDashboardRepository());
    // Its «الرئيسية» tab, which connects the button.
    await open(tester, AdminNavigationRoutes.navigationName);

    await scrollTo(tester, find.text('إدارة منتجات السوق'));
    await tester.tap(find.text('إدارة منتجات السوق'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminMarketplacePage), findsOneWidget);
  });

  testWidgets('the listings fit large bold text', (tester) async {
    await open(
      tester,
      AdminMarketplaceRoutes.marketplaceName,
      textScale: largeTextScale,
      boldText: true,
    );

    expect(find.byType(AdminMarketplacePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a listing fits large bold text', (tester) async {
    for (final id in ['i-live', 'i-removed']) {
      await open(
        tester,
        AdminMarketplaceRoutes.marketplaceItemName,
        pathParameters: {'itemId': id},
        textScale: largeTextScale,
        boldText: true,
      );
      expect(find.byType(AdminMarketplaceItemPage), findsOneWidget);
      expect(tester.takeException(), isNull, reason: id);
    }
  });
}
