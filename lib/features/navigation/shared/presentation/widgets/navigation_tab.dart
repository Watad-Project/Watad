import 'package:flutter/widgets.dart';

/// One tab of a role's bottom navigation: what the bar shows, and which
/// feature's screen opens in it.
class NavigationTab {
  const NavigationTab({
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
    this.routeName,
  });

  /// The translation key of the tab's label, e.g. `navigation.home`.
  final String labelKey;

  final IconData icon;

  /// Shown while the tab is selected, e.g. the filled form of [icon].
  final IconData selectedIcon;

  /// The route name of the tab's first page, from its names file in
  /// lib/core/router/routes/. The tab's feature registers that page in getIt
  /// under this name, in its injection file. Null while the feature isn't
  /// built: the tab shows a placeholder.
  final String? routeName;
}
