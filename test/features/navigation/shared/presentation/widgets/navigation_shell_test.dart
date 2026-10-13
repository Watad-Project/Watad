import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/layout/app_bottom_nav.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/features/navigation/shared/presentation/widgets/navigation_placeholder.dart';
import 'package:watad/features/navigation/shared/presentation/widgets/navigation_shell.dart';
import 'package:watad/features/navigation/shared/presentation/widgets/navigation_tab.dart';

import '../../../../../helpers/pump_component.dart';

/// A tab screen with its own state: a counter.
class _CounterScreen extends StatefulWidget {
  const _CounterScreen(this.name);

  final String name;

  @override
  State<_CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<_CounterScreen> {
  var _count = 0;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('${widget.name} $_count'),
      TextButton(
        onPressed: () => setState(() => _count++),
        child: Text('add ${widget.name}'),
      ),
      TextButton(
        onPressed: () => context.pushNamed('details'),
        child: Text('open ${widget.name}'),
      ),
    ],
  );
}

const _tabs = [
  NavigationTab(
    labelKey: 'navigation.home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    routeName: 'tab-a',
  ),
  NavigationTab(
    labelKey: 'navigation.my_projects',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment,
    routeName: 'tab-b',
  ),
  NavigationTab(
    labelKey: 'navigation.market',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront,
  ),
];

void main() {
  late int aBuilds;
  late int bBuilds;
  late ValueNotifier<String?> selected;

  setUp(() {
    aBuilds = 0;
    bBuilds = 0;
    selected = ValueNotifier(null);
  });

  // Every rebuild passes new closures, like the route builder does.
  Future<void> pumpShell(WidgetTester tester) async {
    await pumpLocalizedApp(
      tester,
      ValueListenableBuilder<String?>(
        valueListenable: selected,
        builder: (context, value, _) => NavigationShell(
          tabs: _tabs,
          selectedRouteName: value,
          screens: [
            () {
              aBuilds++;
              return const _CounterScreen('a');
            },
            () {
              bBuilds++;
              return const _CounterScreen('b');
            },
            null,
          ],
        ),
      ),
    );
  }

  Future<void> tapTab(WidgetTester tester, IconData icon) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.byIcon(icon),
      ),
    );
    await tester.pump();
  }

  testWidgets('opens the first tab, with every tab in the bar', (tester) async {
    await pumpShell(tester);

    expect(find.text('a 0'), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('مشاريعي'), findsOneWidget);
    expect(find.text('السوق'), findsOneWidget);
  });

  testWidgets('switching tabs keeps each screen as it was', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('add a'));
    await tester.pump();
    await tapTab(tester, Icons.assignment_outlined);
    expect(find.text('b 0'), findsOneWidget);

    await tapTab(tester, Icons.home_outlined);
    expect(find.text('a 1'), findsOneWidget);
  });

  testWidgets('builds each screen once, when its tab first opens', (
    tester,
  ) async {
    await pumpShell(tester);
    expect((aBuilds, bBuilds), (1, 0));

    await tapTab(tester, Icons.assignment_outlined);
    expect((aBuilds, bBuilds), (1, 1));

    // The route rebuilds the page with new closures: nothing is rebuilt.
    selected.value = 'tab-b';
    await tester.pump();
    selected.value = null;
    await tester.pump();
    expect((aBuilds, bBuilds), (1, 1));
  });

  testWidgets('a tab whose feature is not built shows the placeholder', (
    tester,
  ) async {
    await pumpShell(tester);

    await tapTab(tester, Icons.storefront_outlined);
    expect(find.byType(NavigationPlaceholder), findsOneWidget);
    expect(find.text('قريبًا'), findsOneWidget);
  });

  testWidgets('selectedRouteName opens its tab, also after the start', (
    tester,
  ) async {
    selected.value = 'tab-b';
    await pumpShell(tester);
    expect(find.text('b 0'), findsOneWidget);
    expect(aBuilds, 0);

    selected.value = 'tab-a';
    await tester.pump();
    expect(find.text('a 0'), findsOneWidget);
  });

  group('in the router', () {
    // Like a role's navigation route: the builder runs again on every
    // navigation, and reads the `tab` parameter.
    Future<GoRouter> pumpRouter(WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/navigation',
        routes: [
          GoRoute(
            name: 'navigation',
            path: '/navigation',
            builder: (context, state) => NavigationShell(
              tabs: _tabs,
              selectedRouteName: state.uri.queryParameters['tab'],
              screens: [
                () {
                  aBuilds++;
                  return const _CounterScreen('a');
                },
                () {
                  bBuilds++;
                  return const _CounterScreen('b');
                },
                null,
              ],
            ),
          ),
          GoRoute(
            name: 'details',
            path: '/details',
            builder: (context, state) => const Scaffold(body: Text('details')),
          ),
        ],
      );
      addTearDown(router.dispose);
      EasyLocalization.logger.enableLevels = [];
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: AppLocalization.supportedLocales,
          path: AppLocalization.path,
          fallbackLocale: AppLocalization.fallbackLocale,
          startLocale: AppLocalization.arabic,
          saveLocale: false,
          assetLoader: const TestAssetLoader(),
          child: Builder(
            builder: (context) => MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('a page pushed from a tab covers the bar; back keeps the tab', (
      tester,
    ) async {
      final router = await pumpRouter(tester);
      await tester.tap(find.text('add a'));
      await tester.pump();

      await tester.tap(find.text('open a'));
      await tester.pumpAndSettle();
      expect(find.text('details'), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('a 1'), findsOneWidget);
      expect(aBuilds, 1);
    });

    testWidgets('the tab parameter opens a tab and keeps the others', (
      tester,
    ) async {
      final router = await pumpRouter(tester);
      await tester.tap(find.text('add a'));
      await tester.pump();

      router.goNamed('navigation', queryParameters: {'tab': 'tab-b'});
      await tester.pumpAndSettle();
      expect(find.text('b 0'), findsOneWidget);

      // Also from a page on top of the navigation.
      await tester.tap(find.text('open b'));
      await tester.pumpAndSettle();
      router.goNamed('navigation', queryParameters: {'tab': 'tab-a'});
      await tester.pumpAndSettle();
      expect(find.text('a 1'), findsOneWidget);
      expect((aBuilds, bBuilds), (1, 1));
    });
  });
}
