import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/edit_my_item_page.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/marketplace_cart_page.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/marketplace_checkout_page.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/marketplace_item_page.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/marketplace_page.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/marketplace_payment_page.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/my_items_page.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/new_my_item_page.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_item_card.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/my_item_card.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_cart_repository.dart';
import '../../../../helpers/fake_marketplace_repository.dart';
import '../../../../helpers/fake_orders_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeMarketplaceRepository repository;
  late FakeCartRepository cart;
  late FakeOrdersRepository orders;

  setUp(() {
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeMarketplaceRepository();
    cart = FakeCartRepository();
    orders = FakeOrdersRepository();
    registerFakeMarketplace(repository, cart, orders);
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

  group('item page', () {
    Future<GoRouter> openItem(
      WidgetTester tester,
      String itemId, {
      double textScale = 1,
      bool boldText = false,
    }) => open(
      tester,
      routeName: MarketplaceRoutes.marketplaceItemName,
      pathParameters: {'itemId': itemId},
      textScale: textScale,
      boldText: boldText,
    );

    testWidgets("someone else's item: seller, messaging and add to cart", (
      tester,
    ) async {
      final router = await openItem(tester, 'i-steel');

      expect(currentPath(router), '/marketplace/items/i-steel');
      expect(find.byType(MarketplaceItemPage), findsOneWidget);
      expect(find.text('حديد تسليح ١٢ مم'), findsOneWidget);
      expect(find.text('حديد ومعادن'), findsOneWidget);
      expect(
        find.text('الكمية المتوفرة: ١٠', skipOffstage: false),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('marketplace_item_report')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('سارة العتيبي'), findsOneWidget);
      expect(find.text('لا تقييمات بعد'), findsOneWidget);
      expect(
        find.byKey(const Key('marketplace_item_message_seller')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('marketplace_item_edit')), findsNothing);

      await tester.tap(find.byTooltip('زيادة'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('marketplace_item_add')));
      await tester.pumpAndSettle();

      expect(cart.lines.single.itemId, 'i-steel');
      expect(cart.lines.single.quantity, 2);
      expect(find.text('أُضيف المنتج إلى السلة'), findsOneWidget);
    });

    testWidgets('my own item shows «تعديل» instead of the cart', (
      tester,
    ) async {
      await openItem(tester, 'i-cement');

      expect(find.text('هذا منتجك', skipOffstage: false), findsOneWidget);
      expect(find.byKey(const Key('marketplace_item_edit')), findsOneWidget);
      expect(find.byKey(const Key('marketplace_item_add')), findsNothing);
      expect(
        find.byKey(const Key('marketplace_item_message_seller')),
        findsNothing,
      );
    });

    testWidgets('a removed or missing item is «المنتج غير متاح»', (
      tester,
    ) async {
      await openItem(tester, 'i-removed');
      expect(
        find.byKey(const Key('marketplace_item_unavailable')),
        findsOneWidget,
      );

      await openItem(tester, 'i-does-not-exist');
      expect(
        find.byKey(const Key('marketplace_item_unavailable')),
        findsOneWidget,
      );
    });

    for (final (label, itemId) in [
      ('not mine', 'i-steel'),
      ('mine', 'i-cement'),
      ('unavailable', 'i-removed'),
    ]) {
      testWidgets('item page ($label) fits large bold text at 200%', (
        tester,
      ) async {
        await openItem(
          tester,
          itemId,
          textScale: largeTextScale,
          boldText: true,
        );

        expect(find.byType(MarketplaceItemPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('a grid item opens its page, and the badge counts the cart', (
    tester,
  ) async {
    cart.lines = [
      const CartLine(
        itemId: 'i-other',
        quantity: 1,
        priceWhenAdded: Money.halalas(100),
      ),
    ];
    final router = await open(tester);
    Finder badge(String count) => find.descendant(
      of: find.byKey(const Key('marketplace_cart_button')),
      matching: find.text(count),
    );
    expect(badge('١'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('i-steel')));
    await tester.pumpAndSettle();
    expect(find.byType(MarketplaceItemPage), findsOneWidget);
    await tester.tap(find.byKey(const Key('marketplace_item_add')));
    await tester.pumpAndSettle();

    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(MarketplacePage), findsOneWidget);
    expect(badge('٢'), findsOneWidget);

    // The cart icon opens the cart.
    await tester.tap(find.byKey(const Key('marketplace_cart_button')));
    await tester.pumpAndSettle();
    expect(find.byType(MarketplaceCartPage), findsOneWidget);
  });

  group('cart', () {
    setUp(() {
      repository.items = [...repository.items, fakeTilesItem];
      cart.lines = [
        const CartLine(
          itemId: 'i-steel',
          quantity: 1,
          priceWhenAdded: Money.halalas(250000),
        ),
        const CartLine(
          itemId: 'i-tiles',
          quantity: 2,
          priceWhenAdded: Money.halalas(6500),
        ),
      ];
    });

    testWidgets('groups by seller; a line is removed and comes back', (
      tester,
    ) async {
      final router = await open(
        tester,
        routeName: MarketplaceRoutes.marketplaceCartName,
      );

      expect(currentPath(router), MarketplaceRoutes.marketplaceCartPath);
      expect(find.byKey(const ValueKey('cart_group_u-seller')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cart_group_u-tiles'), skipOffstage: false),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('cart_remove_i-steel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('cart_group_u-seller')), findsNothing);
      expect(find.text('أُزيل المنتج من السلة'), findsOneWidget);

      await tester.tap(find.text('تراجع'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('cart_group_u-seller')), findsOneWidget);
      expect(cart.lines, hasLength(2));
    });

    testWidgets('an empty cart says so', (tester) async {
      cart.lines = [];
      await open(tester, routeName: MarketplaceRoutes.marketplaceCartName);

      expect(find.byKey(const Key('cart_empty')), findsOneWidget);
    });

    for (final (label, empty) in [('full', false), ('empty', true)]) {
      testWidgets('cart ($label) fits large bold text at 200%', (tester) async {
        if (empty) cart.lines = [];
        await open(
          tester,
          routeName: MarketplaceRoutes.marketplaceCartName,
          textScale: largeTextScale,
          boldText: true,
        );

        expect(find.byType(MarketplaceCartPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('checkout', () {
    setUp(() {
      cart.lines = [
        const CartLine(
          itemId: 'i-steel',
          quantity: 2,
          priceWhenAdded: Money.halalas(250000),
        ),
      ];
    });

    Future<GoRouter> openCheckout(
      WidgetTester tester, {
      double textScale = 1,
      bool boldText = false,
    }) => open(
      tester,
      routeName: MarketplaceRoutes.marketplaceCheckoutName,
      pathParameters: {'sellerId': 'u-seller'},
      textScale: textScale,
      boldText: boldText,
    );

    testWidgets('confirming opens the payment page in its place', (
      tester,
    ) async {
      final router = await openCheckout(tester);
      expect(find.byType(MarketplaceCheckoutPage), findsOneWidget);
      expect(currentPath(router), '/marketplace/checkout/u-seller');

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('checkout_method_mada')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('checkout_method_mada')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('checkout_confirm')));
      await tester.pumpAndSettle();

      expect(orders.checkouts.single.addressId, 'a-home');
      expect(orders.checkouts.single.method, PaymentMethod.mada);
      expect(find.byType(MarketplacePaymentPage), findsOneWidget);
      expect(
        currentPath(router),
        '/marketplace/orders/${orders.nextOrderId}/pay',
      );
      expect(cart.lines, isEmpty);
    });

    testWidgets('5 unpaid orders show why and keep confirm off', (
      tester,
    ) async {
      orders.unpaidCount = 5;
      await openCheckout(tester);

      expect(find.byKey(const Key('checkout_problem')), findsOneWidget);
      final confirm = tester.widget<AppButton>(
        find.byKey(const Key('checkout_confirm')),
      );
      expect(confirm.onPressed, isNull);
    });

    testWidgets('checkout fits large bold text at 200%', (tester) async {
      await openCheckout(tester, textScale: largeTextScale, boldText: true);

      expect(find.byType(MarketplaceCheckoutPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('payment', () {
    final orderId = fakeOrder().id;

    setUp(() => orders.orders[orderId] = fakeOrder());

    Future<GoRouter> openPayment(
      WidgetTester tester, {
      double textScale = 1,
      bool boldText = false,
    }) => open(
      tester,
      routeName: MarketplaceRoutes.marketplacePaymentName,
      pathParameters: {'orderId': orderId},
      textScale: textScale,
      boldText: boldText,
    );

    Finder field(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(EditableText),
    );

    /// Fills the card form and taps «ادفع»; the page is then processing.
    Future<void> payWith(WidgetTester tester, String number) async {
      await tester.enterText(field('payment_card_number'), number);
      await tester.scrollUntilVisible(
        find.byKey(const Key('payment_card_submit')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(field('payment_card_expiry'), '1228');
      await tester.enterText(field('payment_card_cvv'), '737');
      await tester.enterText(field('payment_card_name'), 'KHALID ALMUTAIRI');
      // Typing scrolls each field into view; bring «ادفع» back.
      await tester.ensureVisible(find.byKey(const Key('payment_card_submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('payment_card_submit')));
      await tester.pump();
      await tester.pump();
    }

    /// The 2 seconds of processing, then the result.
    Future<void> finishProcessing(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }

    testWidgets('a good card: the demo line, processing, then success', (
      tester,
    ) async {
      final router = await openPayment(tester);

      expect(currentPath(router), '/marketplace/orders/$orderId/pay');
      expect(find.byKey(const Key('payment_demo_note')), findsOneWidget);
      expect(find.text('وضع تجريبي — لا يتم خصم أي مبلغ'), findsOneWidget);

      await tester.enterText(field('payment_card_number'), '4111111111111111');
      await tester.pump();
      expect(find.text('4111 1111 1111 1111'), findsOneWidget);
      expect(find.text('Visa'), findsOneWidget);

      await payWith(tester, '4111111111111111');
      expect(find.byKey(const Key('payment_processing')), findsOneWidget);

      await finishProcessing(tester);
      expect(find.byKey(const Key('payment_success')), findsOneWidget);
      expect(find.text('تم الدفع بنجاح'), findsOneWidget);
      expect(find.text('7C9E6679'), findsOneWidget);
      expect(orders.payments.single.payment.last4, '1111');
      expect(orders.orders[orderId]?.status, OrderStatus.paid);
    });

    testWidgets('4000 0000 0000 0002 fails, and «حاول مرة أخرى» returns', (
      tester,
    ) async {
      await openPayment(tester);

      await payWith(tester, '4000000000000002');
      await finishProcessing(tester);
      expect(find.byKey(const Key('payment_declined')), findsOneWidget);
      expect(orders.orders[orderId]?.status, OrderStatus.pendingPayment);

      await tester.tap(find.byKey(const Key('payment_result_primary')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('payment_card_number')), findsOneWidget);
    });

    testWidgets('Apple Pay confirms on its own sheet', (tester) async {
      orders.orders[orderId] = fakeOrder(method: PaymentMethod.applePay);
      await openPayment(tester);

      await tester.tap(find.byKey(const Key('payment_wallet_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('payment_wallet_confirm')));
      await tester.pump();
      await tester.pump();
      await finishProcessing(tester);

      expect(find.byKey(const Key('payment_success')), findsOneWidget);
      expect(orders.payments.single.payment.last4, '0000');
    });

    testWidgets('a paid order is not payable', (tester) async {
      orders.orders[orderId] = fakeOrder(status: OrderStatus.paid);
      await openPayment(tester);

      expect(find.byKey(const Key('payment_not_payable')), findsOneWidget);
    });

    testWidgets('payment form fits large bold text at 200%', (tester) async {
      await openPayment(tester, textScale: largeTextScale, boldText: true);

      expect(find.byType(MarketplacePaymentPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final (label, number, key) in [
      ('success', '4111111111111111', 'payment_success'),
      ('failure', '4000000000000002', 'payment_declined'),
    ]) {
      testWidgets('payment processing and $label fit large bold text at 200%', (
        tester,
      ) async {
        await openPayment(tester, textScale: largeTextScale, boldText: true);

        await payWith(tester, number);
        expect(find.byKey(const Key('payment_processing')), findsOneWidget);
        expect(tester.takeException(), isNull);

        await finishProcessing(tester);
        expect(find.byKey(Key(key)), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
