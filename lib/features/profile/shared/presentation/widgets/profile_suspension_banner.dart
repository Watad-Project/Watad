import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/theme/app_tone.dart';

/// The top of the account tab while an admin has suspended the account
/// (GRA-59): what it means, and the admin's reason.
class ProfileSuspensionBanner extends StatelessWidget {
  const ProfileSuspensionBanner({this.reason, super.key});

  /// The admin's reason; null when there is none to show.
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final reason = this.reason;
    return AppStatusCard(
      tone: AppTone.danger,
      title: context.tr('profile.suspended_title'),
      subtitle: context.tr('profile.suspended_message'),
      reasonTitle: reason == null
          ? null
          : context.tr('profile.suspended_reason'),
      reasonText: reason,
    );
  }
}
