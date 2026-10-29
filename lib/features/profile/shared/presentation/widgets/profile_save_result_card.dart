import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_save_outcome.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_save_part.dart';

/// After a save that stored only part of the changes (GRA-60): which part
/// the server stored, and which it didn't, and why.
class ProfileSaveResultCard extends StatelessWidget {
  const ProfileSaveResultCard({
    required this.outcome,
    this.businessReasonKey,
    super.key,
  });

  final ProfileSaveOutcome outcome;

  /// Why the business part failed, when the page knows better than the
  /// failure (e.g. the CR number is taken).
  final String? businessReasonKey;

  @override
  Widget build(BuildContext context) {
    final lines = [
      ?_line(context, outcome.user, 'profile.edit.part_account', null),
      ?_line(
        context,
        outcome.business,
        'profile.edit.part_business',
        businessReasonKey,
      ),
    ];
    return AppStatusCard(
      tone: AppTone.attention,
      title: context.tr('profile.edit.partial_title'),
      subtitle: lines.join('\n'),
    );
  }

  static String? _line(
    BuildContext context,
    ProfileSavePart part,
    String nameKey,
    String? reasonKey,
  ) => switch (part) {
    ProfileSavePartUnchanged() => null,
    ProfileSavePartSaved() => context.tr(
      'profile.edit.part_saved',
      args: [context.tr(nameKey)],
    ),
    ProfileSavePartFailed(:final failure) => context.tr(
      'profile.edit.part_failed',
      args: [context.tr(nameKey), context.tr(reasonKey ?? failure.messageKey)],
    ),
  };
}
