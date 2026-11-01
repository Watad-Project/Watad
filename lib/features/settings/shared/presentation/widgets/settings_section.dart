import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// A title, then its rows in one card, with a line between them.
class SettingsSection extends StatelessWidget {
  const SettingsSection({required this.title, required this.rows, super.key});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: title,
          padding: const EdgeInsetsDirectional.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.xs,
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
