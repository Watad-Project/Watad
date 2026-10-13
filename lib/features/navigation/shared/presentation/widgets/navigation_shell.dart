import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/layout/app_bottom_nav.dart';
import 'package:watad/features/navigation/shared/presentation/widgets/navigation_placeholder.dart';
import 'package:watad/features/navigation/shared/presentation/widgets/navigation_tab.dart';

/// The bottom navigation of every role: the selected tab's screen, with the
/// floating [AppBottomNav] under it.
///
/// - Each tab's screen is built once, the first time the tab opens, and then
///   stays alive: leaving a tab and coming back keeps it as it was (scroll
///   position, bloc state, …), also when the route rebuilds.
/// - Pages a tab opens with `context.pushNamed` cover the whole screen, bar
///   included. Back returns to the tab.
/// - [selectedRouteName] selects a tab from outside, e.g. a link on one tab
///   that opens another.
class NavigationShell extends StatefulWidget {
  const NavigationShell({
    required this.tabs,
    required this.screens,
    this.selectedRouteName,
    super.key,
  }) : assert(tabs.length == screens.length, 'One screen per tab');

  final List<NavigationTab> tabs;

  /// Builds the screen of each tab, in the same order as [tabs]. Each one is
  /// called once, when its tab first opens. Null shows the placeholder of a
  /// tab whose feature isn't built yet.
  final List<Widget Function()?> screens;

  /// The [NavigationTab.routeName] of the tab to select. Null keeps the
  /// current tab (the first one at the start).
  final String? selectedRouteName;

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  late var _currentIndex = _indexOf(widget.selectedRouteName) ?? 0;

  /// The screens built so far, by tab index.
  final _built = <int, Widget>{};

  int? _indexOf(String? routeName) {
    if (routeName == null) return null;
    final index = widget.tabs.indexWhere((tab) => tab.routeName == routeName);
    return index < 0 ? null : index;
  }

  @override
  void didUpdateWidget(NavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRouteName != oldWidget.selectedRouteName) {
      final index = _indexOf(widget.selectedRouteName);
      if (index != null) _currentIndex = index;
    }
  }

  Widget _screenAt(BuildContext context, int index) {
    final build = widget.screens[index];
    if (build == null) {
      return NavigationPlaceholder(
        title: context.tr(widget.tabs[index].labelKey),
      );
    }
    return _built.putIfAbsent(index, build);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var index = 0; index < widget.tabs.length; index++)
            // A tab that never opened isn't built yet.
            if (index == _currentIndex || _built.containsKey(index))
              _screenAt(context, index)
            else
              const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          for (final tab in widget.tabs)
            AppBottomNavItem(
              icon: tab.icon,
              activeIcon: tab.selectedIcon,
              label: context.tr(tab.labelKey),
            ),
        ],
      ),
    );
  }
}
