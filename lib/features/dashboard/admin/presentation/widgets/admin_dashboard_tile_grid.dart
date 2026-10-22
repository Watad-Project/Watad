import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// Number tiles two by two. Each row is as tall as its taller tile, so
/// large text grows the row instead of overflowing; an odd last tile keeps
/// half the width.
class AdminDashboardTileGrid extends StatelessWidget {
  const AdminDashboardTileGrid({required this.children, super.key});

  final List<Widget> children;

  static const int _columns = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i += _columns) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = i; j < i + _columns; j++) ...[
                  if (j > i) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: j < children.length
                        ? children[j]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
