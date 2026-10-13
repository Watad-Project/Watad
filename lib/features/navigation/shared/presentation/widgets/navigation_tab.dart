import 'package:flutter/material.dart';

/// One tab of a role's bottom navigation: what the bar shows, and which
/// feature's screen opens in it.
class NavigationTab {
  const NavigationTab({
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
    this.routeName,
  });

  /// A tab no feature has taken yet: «قريبًا» in the bar, and a placeholder
  /// screen. A feature replaces it with its own tab.
  const NavigationTab.placeholder()
    : labelKey = 'navigation.coming_soon',
      icon = Icons.circle_outlined,
      selectedIcon = Icons.circle,
      routeName = null;

  /// The translation key of the tab's label.
  final String labelKey;

  final IconData icon;

  /// Shown while the tab is selected, e.g. the filled form of [icon].
  final IconData selectedIcon;

  /// The route name of the tab's first page, from its names file in
  /// lib/core/router/routes/. The tab's feature registers that page in getIt
  /// under this name, in its injection file. Null: the tab shows a
  /// placeholder.
  final String? routeName;
}
