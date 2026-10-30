import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_menu_row.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The rows of the account tab (GRA-59), in three groups: the account, the
/// marketplace, and help and settings.
///
/// A row whose screen isn't built yet is grayed out with «قريبًا», and a
/// tap says so. The issue that builds the screen turns its row on: my
/// public profile (GRA-58), my orders (GRA-69), my listings (GRA-70), my
/// sales (GRA-71), help and support (GRA-63) and settings (GRA-62). Saved
/// addresses has no issue yet: GRA-19 built only the map picker.
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({required this.isSuspended, this.onEditProfile, super.key});

  /// A suspended account can't edit its profile, so that row says why.
  final bool isSuspended;

  /// Opens the edit profile page (GRA-60); null until it's built.
  final VoidCallback? onEditProfile;

  @override
  Widget build(BuildContext context) {
    final onEditProfile = this.onEditProfile;
    final comingSoon = context.tr('profile.coming_soon');
    void showComingSoon() =>
        context.showSnackBar(context.tr('profile.coming_soon_message'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileMenuSection(
          title: context.tr('profile.menu.account'),
          rows: [
            if (isSuspended)
              AppMenuRow(
                key: const Key('profile_menu_edit'),
                icon: Icons.edit_outlined,
                label: context.tr('profile.menu.edit_profile'),
                subtitle: context.tr('profile.suspended_edit_note'),
                isMuted: true,
              )
            else
              AppMenuRow(
                key: const Key('profile_menu_edit'),
                icon: Icons.edit_outlined,
                label: context.tr('profile.menu.edit_profile'),
                tag: onEditProfile == null ? comingSoon : null,
                isMuted: onEditProfile == null,
                onTap: onEditProfile ?? showComingSoon,
              ),
            AppMenuRow(
              key: const Key('profile_menu_public_profile'),
              icon: Icons.badge_outlined,
              label: context.tr('profile.menu.public_profile'),
              tag: comingSoon,
              isMuted: true,
              onTap: showComingSoon,
            ),
            AppMenuRow(
              key: const Key('profile_menu_addresses'),
              icon: Icons.location_on_outlined,
              label: context.tr('profile.menu.addresses'),
              tag: comingSoon,
              isMuted: true,
              onTap: showComingSoon,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ProfileMenuSection(
          title: context.tr('profile.menu.marketplace'),
          rows: [
            AppMenuRow(
              key: const Key('profile_menu_orders'),
              icon: Icons.shopping_bag_outlined,
              label: context.tr('profile.menu.orders'),
              tag: comingSoon,
              isMuted: true,
              onTap: showComingSoon,
            ),
            AppMenuRow(
              key: const Key('profile_menu_listings'),
              icon: Icons.inventory_2_outlined,
              label: context.tr('profile.menu.listings'),
              tag: comingSoon,
              isMuted: true,
              onTap: showComingSoon,
            ),
            AppMenuRow(
              key: const Key('profile_menu_sales'),
              icon: Icons.sell_outlined,
              label: context.tr('profile.menu.sales'),
              tag: comingSoon,
              isMuted: true,
              onTap: showComingSoon,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ProfileMenuSection(
          title: context.tr('profile.menu.more'),
          rows: [
            AppMenuRow(
              key: const Key('profile_menu_help'),
              icon: Icons.support_agent_outlined,
              label: context.tr('profile.menu.help'),
              tag: comingSoon,
              isMuted: true,
              onTap: showComingSoon,
            ),
            AppMenuRow(
              key: const Key('profile_menu_settings'),
              icon: Icons.settings_outlined,
              label: context.tr('profile.menu.settings'),
              tag: comingSoon,
              isMuted: true,
              onTap: showComingSoon,
            ),
          ],
        ),
      ],
    );
  }
}

/// A title, then its rows in one card, with a line between them.
class _ProfileMenuSection extends StatelessWidget {
  const _ProfileMenuSection({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: title,
          padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, row) in rows.indexed) ...[
                if (index > 0) const Divider(height: 1),
                row,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
