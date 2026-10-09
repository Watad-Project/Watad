import 'package:flutter/material.dart';

/// Underlined tabs of equal width, e.g. "Overview · Work history · Reviews"
/// on a business profile.
///
/// It uses [controller], or the nearest `DefaultTabController`. Fits in
/// `AppBar.bottom`.
class AppTabBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTabBar({
    super.key,
    required this.labels,
    this.controller,
    this.onTap,
  });

  final List<String> labels;
  final TabController? controller;
  final ValueChanged<int>? onTap;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      onTap: onTap,
      tabs: [for (final label in labels) Tab(text: label)],
    );
  }
}
